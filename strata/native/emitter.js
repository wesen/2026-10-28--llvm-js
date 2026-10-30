'use strict';
const {compile, strata} = require('./frontend');
const abi = require('./abi');
const {Lit} = strata.internals;
const isLit = x => x instanceof Lit;
const literalKey = x => JSON.stringify(new Lit(x));
const binary = {add:'ADD',sub:'SUB',mul:'MUL',div:'DIV',mod:'MOD',lt:'LT',le:'LE',gt:'GT',ge:'GE',strict_eq:'STRICT_EQ',strict_ne:'STRICT_NE',eq:'STRICT_EQ',ne:'STRICT_NE'};
function hashString(s) {
  let h=0;
  for(let i=0;i<s.length;i++){h=(h+s.charCodeAt(i))>>>0;h=(h+(h<<10))>>>0;h=(h^(h>>>6))>>>0;}
  return h;
}
class ModuleEmitter {
  constructor(module, options) {
    this.module=module;this.options=options;this.used=new Set();this.strings=new Map();
    this.functions=[module.fn(module.main), ...[...module.functions.values()].filter(f=>f.name!==module.main)];
    this.ids=new Map(this.functions.map((f,i)=>[f.name,i])); this.plans=[];
    this.functions.forEach(f=>this.string(f.name));
  }
  string(s){if(!this.strings.has(s))this.strings.set(s,this.strings.size);return this.strings.get(s);}
  declaration(n) {
    const s=abi.signatures.get(n); if(!s)throw new Error(`Unknown ABI helper ${n}`);
    return `declare ${s.result} @${n}(${s.args.join(', ')})${n==='_setjmp'?' returns_twice':''}`;
  }
  data() {
    const ascii=[],utf16=[],triples=[];
    for(const s of this.strings.keys()) {
      const narrow=[...s].every(c=>c.charCodeAt(0)<128), pool=narrow?ascii:utf16;
      triples.push((pool.length+(narrow?0:0x80000000))>>>0,s.length,hashString(s));
      for(let i=0;i<s.length;i++)pool.push(s.charCodeAt(i)); pool.push(0);
    }
    const array=(name,type,values)=>`@${name} = private constant [${values.length} x ${type}] [${values.map(x=>`${type} ${x}`).join(', ')}]`;
    const out=[array('ascii','i8',ascii.length?ascii:[0]),array('utf16','i16',utf16.length?utf16:[0]),array('strings','i32',triples),
      '@unit_index = internal global i32 0, align 4','@unit_name = private constant [7 x i8] c"strata\\00"',
      '%FunctionInfo = type { i32, i32, i32, i32 }',
      `@functions = private constant [${this.functions.length} x %FunctionInfo] [${this.functions.map(f=>`%FunctionInfo { i32 ${this.string(f.name)}, i32 ${f.meta.jsParams||0}, i32 0, i32 ${f.meta.kind==='arrow'?2:0} }`).join(', ')}]`];
    return out.join('\n');
  }
  emit() {
    const bodies=this.functions.map(f=>new FunctionEmitter(this,f).emit());
    this.used.add('shllvm_create_unit');this.used.add('shllvm_run');
    return ['; Strata frontend and IR -> LLVM -> Hermes runtime. No Hermes frontend invocation.',this.data(),
      ...[...this.used].sort().map(n=>this.declaration(n)),...bodies,
      `define ptr @sh_export_${this.options.unitName}() {\nentry:\n  %u = call ptr @shllvm_create_unit(ptr @unit_index, i32 ${this.strings.size}, ptr @ascii, ptr @utf16, ptr @strings, i32 ${this.functions.length}, ptr @functions, ptr @f0, ptr @unit_name)\n  ret ptr %u\n}`,
      `define i32 @main(i32 %argc, ptr %argv) {\nentry:\n  %r = call i32 @shllvm_run(i32 %argc, ptr %argv, ptr @sh_export_${this.options.unitName})\n  ret i32 %r\n}\n`].join('\n\n');
  }
}
class FunctionEmitter {
  constructor(module,fn){
    this.m=module;this.fn=fn;this.lines=[];this.seq=0;this.homes=new Map();this.constants=new Map();this.maxArgs=1;this.edges=[];
    this.blocks=new Map(fn.blocks.map((b,i)=>[b.name,`b${i}`]));
    this.handlers=[...new Set(fn.blocks.map(b=>b.onThrow).filter(n=>n&&n!=='unwind'))];
    for(const v of fn.values())this.home(v);
    this.scratch=Array.from({length:6},(_,i)=>this.home(`$scratch${i}`));
    this.undefined=this.literal(undefined);this.global=this.home('$global');
  }
  line(s){this.lines.push('  '+s);}
  label(s){this.lines.push(s+':');}
  temp(){return `%t${++this.seq}`;}
  home(v){if(!this.homes.has(v))this.homes.set(v,`%s${this.homes.size}`);return this.homes.get(v);}
  literal(v){const k=literalKey(v);if(!this.constants.has(k))this.constants.set(k,{value:v,ptr:this.home('$literal'+this.constants.size)});return this.constants.get(k).ptr;}
  ptr(v){if(isLit(v))return this.literal(v.lit);if(!this.homes.has(v))throw new Error(`${this.fn.name}: undefined IR value ${v}`);return this.homes.get(v);}
  call(name,args){
    const s=abi.signatures.get(name);if(!s||s.args.length!==args.length)throw new Error(`ABI mismatch ${name}: ${args.length} arguments`);
    this.m.used.add(name);const lhs=s.result==='void'?'':this.temp();
    this.line(`${lhs?lhs+' = ':''}call ${s.result} @${name}(${args.map((a,i)=>`${s.args[i]} ${a}`).join(', ')})${name==='_setjmp'?' returns_twice':''}`);return lhs;
  }
  load(p){const v=this.temp();this.line(`${v} = load i64, ptr ${p}, align 8`);return v;}
  copy(dst,src){this.line(`store i64 ${this.load(src)}, ptr ${dst}, align 8`);}
  globalGet(out,name){this.call('shllvm_get_id',[out,'%shr','%unit',this.global,this.m.string(name),1]);}
  invoke(out,callee,self,args,newTarget='null') {
    this.maxArgs=Math.max(this.maxArgs,args.length);
    args.forEach((p,i)=>{const q=this.temp();this.line(`${q} = getelementptr i64, ptr %argv, i32 ${i}`);this.copy(q,p);});
    this.call('shllvm_call',[out,'%shr','%frame',callee,self,newTarget,args.length,'%argv']);
  }
  op(o){
    const out=o.result?this.ptr(o.result):this.scratch[5], a=o.args.map(x=>this.ptr(x));
    const [set,name]=o.op.split('.');
    if((set==='js'||set==='num')&&binary[name]){this.call('shllvm_binary',[out,'%shr',abi.codes['SHLLVM_'+binary[name]],...a]);return;}
    if(o.op==='core.copy'){this.copy(out,a[0]);return;}
    if(o.op==='core.ref_eq'){this.call('shllvm_binary',[out,'%shr',abi.codes.SHLLVM_STRICT_EQ,...a]);return;}
    if(['js.neg','num.neg','js.not','bool.not','js.typeof'].includes(o.op)){this.call('shllvm_unary',[out,'%shr',abi.codes['SHLLVM_'+({neg:'NEG',not:'NOT',typeof:'TYPEOF'}[name])],a[0]]);return;}
    if(o.op==='js.truthy'){this.call('shllvm_boolean',[out,this.call('shllvm_truthy',[a[0]])]);return;}
    if(o.op==='bool.or'||o.op==='bool.and'){
      const x=this.call('shllvm_truthy',[a[0]]),y=this.call('shllvm_truthy',[a[1]]),v=this.temp();
      this.line(`${v} = ${name==='or'?'or':'and'} i32 ${x}, ${y}`);this.call('shllvm_boolean',[out,v]);return;
    }
    if(o.op==='obj.new'){this.call('shllvm_object',[out,'%shr']);return;}
    if(o.op==='arr.new'){this.call('shllvm_array',[out,'%shr',a.length]);a.forEach((p,i)=>this.call('shllvm_define_index',['%shr',out,i,p]));return;}
    if(o.op==='js.get'){this.call('shllvm_get',[out,'%shr',...a]);return;}
    if(o.op==='js.put'){this.call('shllvm_set',['%shr',...a,0]);return;}
    if(o.op==='js.define'){this.call('shllvm_define',['%shr',...a,1]);return;}
    if(o.op==='js.define_getter'||o.op==='js.define_setter'){
      this.call('shllvm_define_accessor',['%shr',a[0],a[1],name==='define_getter'?a[2]:this.undefined,name==='define_setter'?a[2]:this.undefined,1]);return;
    }
    if(o.op==='js.global_get'){
      if(!isLit(o.args[0])||typeof o.args[0].lit!=='string')throw new Error('Global names must be literal strings');
      this.globalGet(out,o.args[0].lit);return;
    }
    if(o.op==='js.global_put'){this.call('shllvm_set',['%shr',this.global,a[0],a[1],0]);return;}
    if(o.op==='cell.new'){
      this.call('shllvm_env_create',[out,'%shr','null',1]);
      if(a.length)this.call('shllvm_env_store',['%shr',out,a[0],0]);
      else {this.call('shllvm_constant',[this.scratch[0],5,0]);this.call('shllvm_env_store',['%shr',out,this.scratch[0],0]);}return;
    }
    if(o.op==='cell.store'){this.call('shllvm_env_store',['%shr',...a,0]);return;}
    if(o.op==='cell.load'||o.op==='cell.load_checked'){
      this.call('shllvm_env_load',[out,a[0],0]);if(o.op==='cell.load_checked')this.call('shllvm_check_tdz',['%shr',out,3]);return;
    }
    if(o.op==='js.closure'){
      const id=this.m.ids.get(o.attrs.callee);if(id===undefined)throw new Error('Unknown callee '+o.attrs.callee);
      this.call('shllvm_env_create',[this.scratch[0],'%shr','null',a.length]);
      a.forEach((v,i)=>this.call('shllvm_env_store',['%shr',this.scratch[0],v,i]));
      this.call('shllvm_closure',[out,'%shr',this.scratch[0],'%unit',`@f${id}`,id]);return;
    }
    if(o.op==='js.call'){this.invoke(out,a[0],a[1],a.slice(2));return;}
    if(o.op==='js.call_method'){
      this.call('shllvm_get',[this.scratch[0],'%shr',a[0],a[1]]);
      this.invoke(out,this.scratch[0],a[0],a.slice(2));return;
    }
    if(['host.print','job.enqueue','timer.set'].includes(o.op)){
      this.globalGet(this.scratch[0],{'host.print':'print','job.enqueue':'queueMicrotask','timer.set':'setTimeout'}[o.op]);
      this.invoke(out,this.scratch[0],this.undefined,a);return;
    }
    if(o.op==='promise.resolve'){
      this.globalGet(this.scratch[0],'Promise');this.call('shllvm_get_id',[this.scratch[1],'%shr','%unit',this.scratch[0],this.m.string('resolve'),0]);
      this.invoke(out,this.scratch[1],this.scratch[0],a);return;
    }
    if(o.op==='js.new_error'){
      this.globalGet(this.scratch[0],o.attrs.kind||'Error');this.invoke(out,this.scratch[0],this.undefined,a);return;
    }
    if(o.op==='js.type_error'){this.call('shllvm_throw_type_error',['%shr',a[0]]);return;}
    if(['completion.normal','completion.return','completion.throw'].includes(o.op)){
      this.call('shllvm_env_create',[out,'%shr','null',2]);
      this.call('shllvm_env_store',['%shr',out,this.literal({normal:0,return:1,throw:2}[name]),0]);
      this.call('shllvm_env_store',['%shr',out,a[0]||this.undefined,1]);return;
    }
    if(o.op==='completion.value'){this.call('shllvm_env_load',[out,a[0],1]);return;}
    if(o.op==='completion.is'){
      this.call('shllvm_env_load',[this.scratch[0],a[0],0]);
      this.call('shllvm_binary',[out,'%shr',abi.codes.SHLLVM_STRICT_EQ,this.scratch[0],this.literal({normal:0,return:1,throw:2}[o.attrs.kind])]);return;
    }
    throw new Error(`${this.fn.name}: unsupported native operation ${o.op}`);
  }
  edge(e){const label=`edge${this.edges.length}`;this.edges.push({label,e});return label;}
  term(t){
    if(t.kind==='jump'){this.line(`br label %${this.edge(t.to)}`);return;}
    if(t.kind==='branch'){
      const v=this.call('shllvm_truthy',[this.ptr(t.cond)]),b=this.temp();this.line(`${b} = icmp ne i32 ${v}, 0`);
      this.line(`br i1 ${b}, label %${this.edge(t.t)}, label %${this.edge(t.f)}`);return;
    }
    if(t.kind==='return'){
      const v=this.load(this.ptr(t.value));
      if(this.handlers.length)this.call('shllvm_try_end',['%shr','%try_storage']);
      this.call('shllvm_leave',['%shr','%storage','%frame']);this.line(`ret i64 ${v}`);return;
    }
    if(t.kind==='throw'){this.call('shllvm_throw',['%shr',this.ptr(t.value)]);this.line('unreachable');return;}
    if(t.kind==='unreachable'){this.line('unreachable');return;}
    throw new Error(`Unsupported native terminator ${t.kind}`);
  }
  emit(){
    for(const b of this.fn.blocks){
      this.label(this.blocks.get(b.name));
      if(this.handlers.length)this.line(`store volatile i32 ${this.handlers.indexOf(b.onThrow)+1}, ptr %try_state, align 4`);
      b.ops.forEach(o=>this.op(o));this.term(b.term);
    }
    for(const {label,e} of this.edges){
      this.label(label);const values=e.args.map(a=>this.load(this.ptr(a))),params=this.fn.block(e.block).params;
      if(params.length!==values.length)throw new Error('Block argument count mismatch');
      values.forEach((v,i)=>this.line(`store i64 ${v}, ptr ${this.ptr(params[i].id)}, align 8`));
      this.line(`br label %${this.blocks.get(e.block)}`);
    }
    if(this.handlers.length){
      this.label('catch_dispatch');this.call('shllvm_catch_prepare',['%shr','%storage','%frame',this.maxArgs]);
      const state=this.temp();this.line(`${state} = load volatile i32, ptr %try_state, align 4`);
      this.line(`switch i32 ${state}, label %rethrow [ ${this.handlers.map((_,i)=>`i32 ${i+1}, label %catch${i}`).join(' ')} ]`);
      this.handlers.forEach((h,i)=>{this.label(`catch${i}`);const b=this.fn.block(h);if(b.params.length!==1)throw new Error('Native handler requires one exception parameter');this.call('shllvm_catch_value',[this.ptr(b.params[0].id),'%shr']);this.line(`br label %${this.blocks.get(h)}`);});
      this.label('rethrow');this.call('shllvm_try_end',['%shr','%try_storage']);this.call('shllvm_rethrow',['%shr']);this.line('unreachable');
    }
    const body=this.lines;this.lines=[];
    this.call('_sh_check_native_stack_overflow',['%shr']);
    const count=this.homes.size;
    if(count+this.maxArgs>1024)throw new Error(`${this.fn.name}: native frame admission ${count} roots + ${this.maxArgs} arguments exceeds 1024`);
    const size=this.call('shllvm_frame_size',[count]);this.line(`%storage = alloca i8, i64 ${size}, align 16`);
    this.line(`%argv = alloca [${this.maxArgs} x i64], align 8`);this.line('%unit_id = load i32, ptr @unit_index, align 4');
    const frame=this.call('shllvm_enter',['%shr','%storage',count,this.maxArgs,'%unit_id']);this.line(`%frame = getelementptr i8, ptr ${frame}, i64 0`);
    const roots=this.call('shllvm_roots',['%storage']),unit=this.call('shllvm_get_unit',['%shr','%unit_id']);this.line(`%unit = getelementptr i8, ptr ${unit}, i64 0`);
    [...this.homes.values()].forEach((v,i)=>this.line(`${v} = getelementptr i64, ptr ${roots}, i32 ${i}`));
    this.call('shllvm_global',[this.global,'%shr']);
    const caps=(this.fn.meta.captures||[]).length;
    if(caps)this.call('shllvm_env_from_frame',[this.scratch[0],'%shr','%frame']);
    this.fn.params.forEach((p,i)=>{if(i<caps)this.call('shllvm_env_load',[this.ptr(p.id),this.scratch[0],i]);else this.call('shllvm_param',[this.ptr(p.id),'%frame',i-caps]);});
    for(const {value:v,ptr:p} of this.constants.values()){
      if(typeof v==='string')this.call('shllvm_symbol',[p,'%shr','%unit',this.m.string(v)]);
      else if(typeof v==='number'){const bytes=Buffer.alloc(8);bytes.writeDoubleLE(v);this.call('shllvm_constant',[p,3,bytes.readBigUInt64LE().toString()]);}
      else if(typeof v==='boolean')this.call('shllvm_constant',[p,2,v?1:0]);
      else if(v===null||v===undefined)this.call('shllvm_constant',[p,v===null?1:0,0]);
      else throw new Error('Unsupported literal '+String(v));
    }
    if(this.handlers.length){
      const s=this.call('shllvm_try_size',[]);this.line(`%try_storage = alloca i8, i64 ${s}, align 16`);this.line('%try_state = alloca i32, align 4');this.line('store volatile i32 0, ptr %try_state, align 4');
      const buf=this.call('shllvm_try_begin',['%shr','%try_storage']),status=this.call('_setjmp',[buf]),cond=this.temp();this.line(`${cond} = icmp ne i32 ${status}, 0`);this.line(`br i1 ${cond}, label %catch_dispatch, label %${this.blocks.get(this.fn.entry)}`);
    }else this.line(`br label %${this.blocks.get(this.fn.entry)}`);
    this.m.plans.push({name:this.fn.name,rootSlots:count,argumentSlots:this.maxArgs,homes:Object.fromEntries(this.homes)});
    return `define internal i64 @f${this.m.ids.get(this.fn.name)}(ptr %shr) {\nentry:\n${[...this.lines,...body].join('\n')}\n}`;
  }
}
function compileNative(source,options={}){
  options={filename:'program.js',unitName:'strata',roots:'distinct',...options};
  if(!/^[A-Za-z_][A-Za-z0-9_]*$/.test(options.unitName))throw new Error('Invalid unit name');
  if(options.roots!=='distinct')throw new Error('Only distinct root storage is currently available');
  const module=compile(source,options.filename),emitter=new ModuleEmitter(module,options),llvm=emitter.emit();
  return {llvm,metadata:{abiHeaderSHA256:abi.sha256,roots:options.roots,functions:emitter.plans},ir:module.toString()};
}
module.exports={compileNative};
