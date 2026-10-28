// Linux target-faithful execution harness. The guest is RV32 ELF, not x86 code.
// This small RV32IM interpreter is NOT QEMU, a full ESP32-P4 simulator, or a
// security-grade sandbox. No libc is linked into the guest; host uses libc++.
#include "pico_abi.h"
#include <algorithm>
#include <array>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <deque>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <memory>
#include <sstream>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

using u8=uint8_t; using u16=uint16_t; using u32=uint32_t; using i32=int32_t;
static constexpr u32 kReturnPC = 0xffff0000u;
static constexpr u32 kStateAddress = PICO_STATE_ADDR;
static constexpr u32 kStackAddress = PICO_STACK_BASE;
static constexpr size_t kStackSize = PICO_STACK_SIZE;
static constexpr u32 kSlotA=0x00100000u, kSlotB=0x00200000u;
static_assert(sizeof(PicoState)==16,"PicoState must be 16 bytes");

static void require(bool x, const std::string& m){if(!x) throw std::runtime_error(m);}
static std::vector<u8> readFile(const std::string &path){
  std::ifstream f(path,std::ios::binary);require(bool(f),"cannot open "+path);
  return std::vector<u8>((std::istreambuf_iterator<char>(f)),std::istreambuf_iterator<char>());
}
static u16 rd16(const std::vector<u8>& b,size_t p){require(p<=b.size()&&b.size()-p>=2,"truncated ELF");return u16(b[p])|(u16(b[p+1])<<8);}
static u32 rd32(const std::vector<u8>& b,size_t p){require(p<=b.size()&&b.size()-p>=4,"truncated ELF");return u32(b[p])|(u32(b[p+1])<<8)|(u32(b[p+2])<<16)|(u32(b[p+3])<<24);}
static i32 sext(u32 value, unsigned bits){const u32 mask=1u<<(bits-1);return i32((value^mask)-mask);}
static std::string hex(u32 x){std::ostringstream s;s<<"0x"<<std::hex<<x;return s.str();}
struct Segment {u32 base;int flags;std::vector<u8> bytes;};

struct Module {
  std::string path;
  u32 base=0, step=0, migrate=0;
  std::vector<Segment> segments;
  static Module load(const std::string& path){
    Module m;m.path=path;
    const auto b=readFile(path);
    require(b.size()>=52 && b[0]==0x7f && b[1]=='E' && b[2]=='L' && b[3]=='F',"not ELF");
    require(b[4]==1 && b[5]==1,"require little-endian ELF32");
    require(rd16(b,16)==2 && rd16(b,18)==243,"require RISC-V ET_EXEC (no dynamic loader)");
    require((rd32(b,36)&1u)==0,"RVC compressed instructions unsupported in host PoC");
    const u32 e_entry=rd32(b,24), phoff=rd32(b,28), shoff=rd32(b,32);
    const u16 phsz=rd16(b,42), phcnt=rd16(b,44), shsz=rd16(b,46), shcnt=rd16(b,48);
    require(phsz==32 && phcnt>0 && phcnt<=10,"invalid program headers");
    require(shsz==40 && shcnt<=200,"invalid section headers");
    require(uint64_t(phoff)+uint64_t(phsz)*phcnt<=b.size(),"truncated program table");
    require(uint64_t(shoff)+uint64_t(shsz)*shcnt<=b.size(),"truncated section table");
    require(e_entry>=kSlotA && e_entry<kSlotB+0x10000u,"unexpected entry address");
    m.base = (e_entry<kSlotB)?kSlotA:kSlotB;
    for(unsigned i=0;i<phcnt;i++){
      const size_t p=size_t(phoff)+i*phsz;
      if(rd32(b,p)!=1) continue;
      const u32 off=rd32(b,p+4),addr=rd32(b,p+8),filesz=rd32(b,p+16),memsz=rd32(b,p+20),flags=rd32(b,p+24);
      require(addr>=m.base && uint64_t(addr)+memsz <= uint64_t(m.base)+0x10000u,"PT_LOAD not in code slot");
      require(memsz>=filesz && uint64_t(off)+filesz<=b.size(),"invalid PT_LOAD lengths");
      require(!(flags&2 && flags&1),"W+X segment refused");
      Segment seg{addr,int(flags),std::vector<u8>(memsz,0)};
      std::copy(b.begin()+off,b.begin()+off+filesz,seg.bytes.begin());
      m.segments.push_back(std::move(seg));
    }
    require(!m.segments.empty(),"no loadable segments");
    bool entryExecutable=false;
    for(const auto&seg:m.segments) if(seg.flags&1 && e_entry>=seg.base && uint64_t(e_entry)<uint64_t(seg.base)+seg.bytes.size()) entryExecutable=true;
    require(entryExecutable,"entry is not executable");
    bool seenSymbolTable=false;
    for(unsigned i=0;i<shcnt;i++){
      const size_t p=size_t(shoff)+i*shsz;
      if(rd32(b,p+4)!=2)continue; // SHT_SYMTAB
      seenSymbolTable=true;
      const u32 symoff=rd32(b,p+16),size=rd32(b,p+20),link=rd32(b,p+24),entsz=rd32(b,p+36);
      require(link<shcnt && entsz==16 && size%16==0 && uint64_t(symoff)+size<=b.size(),"bad symtab");
      const size_t sp=size_t(shoff)+link*shsz;
      const u32 strOff=rd32(b,sp+16),strSize=rd32(b,sp+20);
      require(uint64_t(strOff)+strSize<=b.size(),"bad strtab");
      for(u32 pos=0;pos<size;pos+=16){
        const size_t s=size_t(symoff)+pos;const u32 name=rd32(b,s),value=rd32(b,s+4);const u16 shndx=rd16(b,s+14);
        if(shndx==0 || name>=strSize)continue;
        const size_t a=size_t(strOff)+name,limit=size_t(strOff)+strSize;
        size_t end=a;while(end<limit && b[end])end++;
        const std::string key(reinterpret_cast<const char*>(b.data()+a),end-a);
        if(key=="pico_world_step")m.step=value;
        if(key=="pico_world_migrate")m.migrate=value;
      }
    }
    require(seenSymbolTable && m.step && m.migrate,"missing world ABI exports");
    return m;
  }
};

struct Fault : std::runtime_error {using std::runtime_error::runtime_error;};
struct Effect {u32 kind; std::array<i32,5> data;};
struct Machine {
  std::array<u32,32> r{};
  u32 pc=0;
  uint64_t steps=0, fuel=0;
  bool migrating=false, allowEmit=false, allowDisplay=false;
  std::vector<Effect> staged;
  std::vector<Segment> mem;
  Machine(const Module &mod, const PicoState &state, u32 entry, bool migration, bool emit, bool display, uint64_t instructionBudget)
    :pc(entry),fuel(instructionBudget),migrating(migration),allowEmit(emit),allowDisplay(display){
    mem=mod.segments;
    Segment st{kStateAddress,6,std::vector<u8>(sizeof(state))};
    std::memcpy(st.bytes.data(),&state,sizeof(state));mem.push_back(std::move(st));
    mem.push_back(Segment{kStackAddress,6,std::vector<u8>(kStackSize,0)});
    r[1]=kReturnPC;
    r[2]=kStackAddress+u32(kStackSize)-16;
    r[10]=kStateAddress;
  }
  u8 *access(u32 addr,size_t size,int requireFlags){
    for(auto &s:mem){
      if((s.flags&requireFlags)!=requireFlags || addr<s.base)continue;
      const u32 rel=addr-s.base;
      if(rel<=s.bytes.size() && size<=s.bytes.size()-rel)return s.bytes.data()+rel;
    }
    throw Fault("memory access denied: "+hex(addr)+" size "+std::to_string(size));
  }
  u32 load(u32 addr,int bytes,bool sign=false){
    if(bytes>1 && addr%unsigned(bytes))throw Fault("misaligned load at "+hex(addr));
    u8 *p=access(addr,bytes,4);u32 val=0;
    for(int i=0;i<bytes;i++)val|=u32(p[i])<<(8*i);
    return sign && bytes<4?u32(sext(val,bytes*8)):val;
  }
  void store(u32 addr,int bytes,u32 val){
    if(bytes>1 && addr%unsigned(bytes))throw Fault("misaligned store at "+hex(addr));
    u8 *p=access(addr,bytes,2);for(int i=0;i<bytes;i++)p[i]=u8(val>>(i*8));
  }
  u32 fetch(){
    if(pc%4)throw Fault("misaligned pc "+hex(pc));
    auto*p=access(pc,4,1);return u32(p[0])|u32(p[1])<<8|u32(p[2])<<16|u32(p[3])<<24;
  }
  static u32 signedDiv(u32 x,u32 y){if(y==0)return ~0u;if(x==0x80000000u&&y==0xffffffffu)return x;return u32(i32(x)/i32(y));}
  static u32 signedRem(u32 x,u32 y){if(y==0)return x;if(x==0x80000000u&&y==0xffffffffu)return 0;return u32(i32(x)%i32(y));}
  void run(){
    while(pc!=kReturnPC){
      if(steps>=fuel)throw Fault("instruction fuel exhausted");
      const u32 ins=fetch();steps++;
      if(std::getenv("PICO_TRACE") && steps<=80)std::cerr<<"TRACE "<<steps<<" pc="<<hex(pc)<<" ins="<<hex(ins)<<" ra="<<hex(r[1])<<" sp="<<hex(r[2])<<" a0="<<hex(r[10])<<"\n";
      require((ins&3)==3,"non-RV32I/compressed opcode");
      const u32 op=ins&0x7f, rd=(ins>>7)&31,f3=(ins>>12)&7,rs1=(ins>>15)&31,rs2=(ins>>20)&31,f7=ins>>25;
      const u32 a=r[rs1],b=r[rs2],next=pc+4;
      const i32 immI=sext(ins>>20,12), immS=sext(((ins>>25)<<5)|((ins>>7)&31),12);
      u32 out=0;bool writes=false;
      switch(op){
        case 0x37:out=ins&0xfffff000u;writes=true;pc=next;break; // LUI
        case 0x17:out=pc+(ins&0xfffff000u);writes=true;pc=next;break; // AUIPC
        case 0x6f:{ // JAL
          u32 imm=((ins>>31)<<20)|(((ins>>12)&255)<<12)|(((ins>>20)&1)<<11)|(((ins>>21)&1023)<<1);
          out=next;writes=true;pc+=sext(imm,21);break;
        }
        case 0x67:{ // JALR
          if(f3)throw Fault("bad JALR");
          out=next;writes=true;pc=(a+u32(immI))&~1u;break;
        }
        case 0x63:{ // BRANCH
          const u32 imm=((ins>>31)<<12)|(((ins>>7)&1)<<11)|(((ins>>25)&63)<<5)|(((ins>>8)&15)<<1);
          bool yes=false;
          switch(f3){case 0:yes=a==b;break;case 1:yes=a!=b;break;case 4:yes=i32(a)<i32(b);break;case 5:yes=i32(a)>=i32(b);break;case 6:yes=a<b;break;case 7:yes=a>=b;break;default:throw Fault("bad branch");}
          pc=yes?pc+sext(imm,13):next;break;
        }
        case 0x03:{ // LOAD
          int bytes=0;bool sign=false;
          switch(f3){case 0:bytes=1;sign=true;break;case 1:bytes=2;sign=true;break;case 2:bytes=4;break;case 4:bytes=1;break;case 5:bytes=2;break;default:throw Fault("unsupported load");}
          out=load(a+u32(immI),bytes,sign);writes=true;pc=next;break;
        }
        case 0x23:{ // STORE
          int bytes=(f3==0?1:f3==1?2:f3==2?4:0);if(!bytes)throw Fault("unsupported store");
          store(a+u32(immS),bytes,b);pc=next;break;
        }
        case 0x13:{ // OP-IMM
          switch(f3){case 0:out=a+u32(immI);break;case 2:out=i32(a)<immI;break;case 3:out=a<u32(immI);break;
            case 4:out=a^u32(immI);break;case 6:out=a|u32(immI);break;case 7:out=a&u32(immI);break;
            case 1:if(f7)throw Fault("bad slli");out=a<<((ins>>20)&31);break;
            case 5:if(f7==0)out=a>>((ins>>20)&31);else if(f7==32)out=u32(i32(a)>>((ins>>20)&31));else throw Fault("bad shift");break;
            default:throw Fault("bad op imm");}
          writes=true;pc=next;break;
        }
        case 0x33:{ // OP, M extension
          if(f7==1){
            switch(f3){
              case 0:out=a*b;break;
              case 1:out=u32((int64_t(i32(a))*int64_t(i32(b)))>>32);break;
              case 2:out=u32((int64_t(i32(a))*int64_t(uint64_t(b)))>>32);break;
              case 3:out=u32((uint64_t(a)*uint64_t(b))>>32);break;
              case 4:out=signedDiv(a,b);break;case 5:out=b? a/b:~0u;break;
              case 6:out=signedRem(a,b);break;case 7:out=b?a%b:a;break;
              default:throw Fault("bad RV32M");}
          }else{
            switch(f3){case 0:if(f7==0)out=a+b;else if(f7==32)out=a-b;else throw Fault("bad add/sub");break;
              case 1:out=a<<(b&31);break;case 2:out=i32(a)<i32(b);break;case 3:out=a<b;break;
              case 4:out=a^b;break;case 5:out=f7==32?u32(i32(a)>>(b&31)):a>>(b&31);break;
              case 6:out=a|b;break;case 7:out=a&b;break;default:throw Fault("bad arithmetic");}
            if(f3!=0&&f3!=5&&f7)throw Fault("unexpected arithmetic extension");
          }
          writes=true;pc=next;break;
        }
        case 0x0f:pc=next;break; // FENCE / FENCE.I (single-core simulator)
        case 0x73:{
          if(ins!=0x00000073u)throw Fault("unsupported CSR/privileged instruction");
          const u32 cap=r[17];
          if(cap==PICO_CAP_EMIT){
            if(migrating)throw Fault("effects forbidden during migration");
            if(!allowEmit)throw Fault("capability denied: emit");
            staged.push_back(Effect{PICO_CAP_EMIT,{i32(r[10]),0,0,0,0}});r[10]=0;
          }else if(cap==PICO_CAP_RECT){
            if(migrating)throw Fault("effects forbidden during migration");
            if(!allowDisplay)throw Fault("capability denied: display");
            const i32 x=i32(r[10]),y=i32(r[11]),w=i32(r[12]),h=i32(r[13]);
            if(x<0 || y<0 || w<0 || h<0 || x>int(PICO_PANEL_WIDTH) || y>int(PICO_PANEL_HEIGHT) ||
               w>int(PICO_PANEL_WIDTH)-x || h>int(PICO_PANEL_HEIGHT)-y)
              throw Fault("invalid display rectangle");
            staged.push_back(Effect{PICO_CAP_RECT,{x,y,w,h,i32(r[14])}});
            r[10]=0;
          }else if(cap==PICO_CAP_ABORT){throw Fault("world abort "+std::to_string(i32(r[10])));}
          else throw Fault("unknown capability "+std::to_string(cap));
          pc=next;break;
        }
        default:throw Fault("unsupported RV32 instruction "+hex(ins)+" at "+hex(pc));
      }
      if(writes && rd)r[rd]=out;
      r[0]=0;
    }
  }
  PicoState state(){PicoState s{};std::memcpy(&s,access(kStateAddress,sizeof(s),4),sizeof(s));return s;}
};

struct Envelope {u32 epoch,event; i32 arg;};
class World {
  std::unique_ptr<Module> active;
  PicoState saved{1,0,0,0};
  std::deque<Envelope> pending;
  bool emitAllowed=false,displayAllowed=false;
  std::vector<u16> panel=std::vector<u16>(PICO_PANEL_WIDTH*PICO_PANEL_HEIGHT,0xffff);
  uint64_t fuel=15000;
  u32 epoch=1,abiSchema=1;
  static void printState(const char* kind,const PicoState& s,u32 epoch,bool ok,const std::string& details=""){
    std::cout<<"{\"event\":\""<<kind<<"\",\"ok\":"<<(ok?"true":"false")
     <<",\"epoch\":"<<epoch<<",\"schema\":"<<s.schema<<",\"score\":"<<s.score<<",\"ticks\":"<<s.ticks
     <<",\"flags\":"<<s.flags<<details<<"}\n";
  }
 public:
  World(Module mod,u32 schema,bool emit,bool display,uint64_t budget):active(std::make_unique<Module>(std::move(mod))),emitAllowed(emit),displayAllowed(display),fuel(budget),abiSchema(schema){saved.schema=schema;}
  bool dispatch(u32 event,i32 arg){
    Machine m(*active,saved,active->step,false,emitAllowed,displayAllowed,fuel);
    m.r[11]=event;m.r[12]=u32(arg);
    try{m.run();const PicoState staged=m.state();
      require(staged.schema==abiSchema,"schema unexpectedly changed during turn");
      saved=staged;
      unsigned drawn=0;std::vector<i32> emitted;
      for(const auto &e:m.staged){
        if(e.kind==PICO_CAP_EMIT)emitted.push_back(e.data[0]);
        if(e.kind==PICO_CAP_RECT){
          const i32 x=e.data[0],y=e.data[1],w=e.data[2],h=e.data[3];
          for(i32 yy=y;yy<y+h;yy++)for(i32 xx=x;xx<x+w;xx++)panel[size_t(yy)*PICO_PANEL_WIDTH+size_t(xx)]=u16(e.data[4]);
          drawn+=unsigned(w*h);
        }
      }
      std::ostringstream info;info<<",\"steps\":"<<m.steps<<",\"effects\":[";
      for(size_t i=0;i<emitted.size();i++){if(i)info<<",";info<<emitted[i];}info<<"],\"pixels\":"<<drawn;
      printState("dispatch",saved,epoch,true,info.str());return true;
    }catch(const std::exception& e){
      std::ostringstream info;info<<",\"steps\":"<<m.steps<<",\"reason\":\""<<e.what()<<"\",\"discarded_effects\":"<<m.staged.size();
      printState("fault",saved,epoch,false,info.str());return false;
    }
  }
  bool reload(const std::string &path,u32 schema){
    if(schema<1||schema>1000){printState("reload",saved,epoch,false,",\"reason\":\"invalid schema\"");return false;}
    try{
      Module candidate=Module::load(path);
      require(candidate.base!=active->base,"hot reload must use inactive code slot");
      PicoState staged=saved;
      Machine m(candidate,staged,candidate.migrate,true,false,false,fuel);
      m.r[11]=saved.schema;m.run();staged=m.state();
      require(m.r[10]==0,"migration returned error");
      require(staged.schema==schema,"migration schema mismatch");
      saved=staged;active=std::make_unique<Module>(std::move(candidate));abiSchema=schema;++epoch;
      std::ostringstream info;info<<",\"migration_steps\":"<<m.steps<<",\"code_slot\":\""<<hex(active->base)<<"\"";
      printState("reload",saved,epoch,true,info.str());return true;
    }catch(const std::exception&e){
      printState("reload",saved,epoch,false,",\"reason\":\""+std::string(e.what())+"\"");return false;
    }
  }
  void queue(u32 event,i32 arg){pending.push_back({epoch,event,arg});std::cout<<"{\"event\":\"queue\",\"epoch\":"<<epoch<<"}\n";}
  void drain(){while(!pending.empty()){auto x=pending.front();pending.pop_front();
    if(x.epoch!=epoch){std::cout<<"{\"event\":\"stale\",\"queued_epoch\":"<<x.epoch<<",\"current_epoch\":"<<epoch<<"}\n";continue;}
    dispatch(x.event,x.arg);
  }}
  void status(){printState("status",saved,epoch,true,",\"code_slot\":\""+hex(active->base)+"\"");}
  void capture(const std::string& path){
    std::ofstream f(path,std::ios::binary);require(bool(f),"cannot write "+path);
    f<<"P6\n"<<PICO_PANEL_WIDTH<<" "<<PICO_PANEL_HEIGHT<<"\n255\n";
    for(const u16 v:panel){
      const char rgb[3]={char(((v>>11)&31)*255/31),char(((v>>5)&63)*255/63),char((v&31)*255/31)};
      f.write(rgb,3);
    }
    require(bool(f),"capture write failed");
    std::cout<<"{\"event\":\"capture\",\"path\":\""<<path<<"\",\"bytes\":"<<PICO_PANEL_WIDTH*PICO_PANEL_HEIGHT*3<<"}\n";
  }
  void expect(const std::string& what,int value){
    int got=0;if(what=="score")got=saved.score;else if(what=="ticks")got=saved.ticks;
    else if(what=="schema")got=int(saved.schema);else if(what=="flags")got=saved.flags;
    else if(what=="epoch")got=int(epoch);else throw std::runtime_error("unknown expected key "+what);
    if(got!=value)throw std::runtime_error("expect "+what+"="+std::to_string(value)+" got "+std::to_string(got));
    std::cout<<"{\"event\":\"expect\",\"key\":\""<<what<<"\",\"value\":"<<value<<",\"ok\":true}\n";
  }
};
int main(int argc,char**argv){
  std::cout.setf(std::ios::unitbuf); // interactive development commands appear immediately
  try{
    std::string elf,script="-";u32 schema=1;bool allowEmit=false,allowDisplay=false;uint64_t fuel=15000;
    for(int i=1;i<argc;i++){
      const std::string a=argv[i];
      if(a=="--module"&&i+1<argc)elf=argv[++i];
      else if(a=="--script"&&i+1<argc)script=argv[++i];
      else if(a=="--schema"&&i+1<argc)schema=std::stoul(argv[++i]);
      else if(a=="--fuel"&&i+1<argc)fuel=std::stoull(argv[++i]);
      else if(a=="--cap"&&i+1<argc){const std::string cap=argv[++i];require(cap=="emit" || cap=="display","unknown capability");
        if(cap=="emit")allowEmit=true;else allowDisplay=true;}
      else throw std::runtime_error("bad option "+a);
    }
    require(!elf.empty(),"usage: pico-sim --module NAME.elf --schema 1 [--cap emit] [--script FILE|-]");
    World world(Module::load(elf),schema,allowEmit,allowDisplay,fuel);
    std::ifstream f;std::istream*in=&std::cin;
    if(script!="-"){f.open(script);require(bool(f),"cannot read scenario "+script);in=&f;}
    std::string line;
    while(std::getline(*in,line)){
      const auto comment=line.find('#');if(comment!=std::string::npos)line.resize(comment);
      std::istringstream s(line);std::string cmd;s>>cmd;if(cmd.empty())continue;
      if(cmd=="dispatch"){unsigned event;int arg;require(bool(s>>event>>arg),"dispatch EVENT ARG");world.dispatch(event,arg);}
      else if(cmd=="queue"){unsigned event;int arg;require(bool(s>>event>>arg),"queue EVENT ARG");world.queue(event,arg);}
      else if(cmd=="drain")world.drain();
      else if(cmd=="reload"){std::string path;unsigned ver;require(bool(s>>path>>ver),"reload PATH SCHEMA");world.reload(path,ver);}
      else if(cmd=="status")world.status();
      else if(cmd=="capture"){std::string file;require(bool(s>>file),"capture PATH");world.capture(file);}
      else if(cmd=="expect"){std::string key;int val;require(bool(s>>key>>val),"expect KEY VALUE");world.expect(key,val);}
      else if(cmd=="quit")break;
      else throw std::runtime_error("unknown command "+cmd);
    }
  }catch(const std::exception& e){std::cerr<<"pico-sim: "<<e.what()<<'\n';return 1;}
  return 0;
}
