/* Part 3b: Stage, IR, Facts, Plan, Machine, Events, Laws, Experiments. */
const opById = (cfg, id) => {
  if (!cfg || !id) return null;
  for (const b of cfg.blocks || []) {
    if (`${cfg.name}/${b.name}` === id) return { kind: 'block', b };
    for (let i = 0; i < b.ops.length; i++) if ((b.ops[i].id || `${cfg.name}/${b.name}/${i}`) === id) return { kind: 'op', b, op: b.ops[i], i };
    const tid = (b.term && b.term.id) || `${cfg.name}/${b.name}/term`;
    if (tid === id) return { kind: 'term', b, op: b.term };
  }
  return null;
};
const recLine = r => r ? (typeof r.op === 'string' && r.op.includes('/') ? r.op : typeof r.op === 'number' ? `${r.fn}/${r.block}/${r.op}` : null) : null;
const valList = vs => (vs && vs.length) ? `<span class="refs">${vs.map(v => `<code class="nid dim">${esc(v)}</code>`).join(' ')}</span>` : '<span class="dim">none</span>';
const permWord = v => v === true ? 'yes' : v === false ? 'no' : String(v);

/* ---------- Stage ---------- */
view('stage', {
  zoom: store.get('zoom', 1), auto: store.get('zoomAuto', true), fitKey: null, menu: false, whyOpen: false,
  mount(el) {
    this.el = el; this.build();
    el.addEventListener('click', ev => {
      const b = ev.target.closest('[data-act]'); if (!b) return;
      const a = b.dataset.act, arg = b.dataset.arg;
      if (a === 'level') host.setLevel(arg);
      else if (a === 'show') { this.menu = !this.menu; this.renderBar(); }
      else if (a === 'ov') { host.toggleOverlay(arg); }
      else if (a === 'fit') this.fit();
      else if (a === 'why') { this.whyOpen = !this.whyOpen; this.renderSide(); }
      else if (a === 'lab') host.link(arg);
      else if (a === 'clear') host.select(null);
    });
    el.addEventListener('input', ev => { if (ev.target.matches('input[data-zoom]')) { this.zoom = +ev.target.value; this.auto = false; store.set('zoom', this.zoom); store.set('zoomAuto', false); this.draw(); } });
    bindFn(el); bindLab(el);
    document.addEventListener('pointerdown', this._outside = ev => { if (this.menu && !ev.target.closest('.stage-view .rel')) { this.menu = false; this.renderBar(); } });
    // pan by dragging the paper
    const wrap = el.querySelector('.sheetwrap');
    wrap.addEventListener('pointerdown', ev => {
      if (ev.button !== 0 || ev.target.closest('.ln') || ev.target.closest('.chip')) return;
      const sx = ev.clientX, sy = ev.clientY, l = wrap.scrollLeft, t = wrap.scrollTop; let moved = false;
      const move = e => { if (!moved && Math.hypot(e.clientX - sx, e.clientY - sy) < 4) return; moved = true; wrap.classList.add('panning'); wrap.scrollLeft = l - (e.clientX - sx); wrap.scrollTop = t - (e.clientY - sy); };
      const up = () => { document.removeEventListener('pointermove', move); document.removeEventListener('pointerup', up); wrap.classList.remove('panning'); if (moved) { wrap.__justPanned = true; setTimeout(() => { wrap.__justPanned = false; }, 0); } };
      document.addEventListener('pointermove', move); document.addEventListener('pointerup', up);
    });
  },
  unmount() { document.removeEventListener('pointerdown', this._outside); },
  update(w) {
    if (w === 'resize' || w === 'layout') { this.fitKey = null; this.draw(); return; }
    if (['preset', 'build', 'run', 'fn', 'level', 'overlays', 'select', 'step', 'analysis', 'theme'].includes(w)) { this.renderBar(); this.draw(); this.renderSide(); }
  },
  build() {
    this.fitKey = null;
    this.el.innerHTML = `<div class="tabbody col stage-view"><div class="toolbar"></div><div class="page"><div class="stagewrap"><div class="sheetwrap" data-scroll="sheet"><div class="chip-row"></div><div class="sheet-host"></div></div><div class="hint"><b>Click an op</b><span>to inspect it · drag the paper to pan · Show ▾ toggles overlays · Facts ‹ › steps the fixed point on the sheet</span></div></div><aside class="side"></aside></div></div>`;
    this.renderBar(); this.draw(); this.renderSide();
  },
  renderBar() {
    const bar = this.el.querySelector('.toolbar'); if (!bar) return;
    const ovs = (W.StrataStage && W.StrataStage.OVERLAYS) || [];
    const menu = this.menu ? `<div class="menu overlays">${ovs.map(o => `<button data-act="ov" data-arg="${o.name}"><i class="box${host.overlays.has(o.name) ? ' on' : ''}"></i><span class="t">${esc(o.label)}</span><small>${esc(o.about)}</small></button>`).join('')}<p class="note">Each overlay keeps one hue on the sheet: blue live values and the path, amber safepoints, violet roots, teal throw edges, red stale uses, pale blue the iteration.</p></div>` : '';
    const lbl = { L1: 'Core IR: one box per block, edges carry arguments; dashed edges are taken by a throw.', L2: 'Runtime IR: each op bound to its provider helper.', L3: 'Execution plan: spills and reloads of root slots around safepoints.' }[host.level] || '';
    bar.innerHTML = `<div class="seg" role="group" aria-label="Level">${['L1', 'L2', 'L3'].map(l => `<button class="${host.level === l ? 'on' : ''}" aria-pressed="${host.level === l}" data-act="level" data-arg="${l}">${l}</button>`).join('')}</div>${fnSelect()}<div class="rel"><button class="btn" data-act="show" data-menu="1">Show <span class="dim">${host.overlays.size}</span> ▾</button>${menu}</div><span class="lbl">Zoom</span><input type="range" data-zoom="1" min="0.4" max="2" step="0.05" value="${this.zoom}" aria-label="Zoom"><button class="btn sm" data-act="fit" title="Show the whole sheet in the tile">Fit</button><span class="lbl">${esc(lbl)}</span>`;
  },
  draw() {
    const hostEl = this.el.querySelector('.sheet-host'), chips = this.el.querySelector('.chip-row'); if (!hostEl) return;
    const P = host.program;
    if (!P || !host.fn) { hostEl.innerHTML = `<div class="sheet-empty">${noProgram()}</div>`; chips.innerHTML = ''; return; }
    let cfg, facts, plan;
    try { cfg = P.cfg(host.fn, host.level); } catch (e) { hostEl.innerHTML = failRow(`The ${host.level} graph of ${host.fn} does not render`, e); return; }
    facts = safe(() => P.facts(host.fn), null);
    plan = (host.overlays.has('roots') || host.overlays.has('stale')) ? safe(() => normPlan(P.plan(host.fn)), null) : null;
    const step = host.overlays.has('iteration') ? safe(() => host.steps(), null) : null;
    let current = null;
    if (host.machineN != null && host.run && host.run.records) { const r = host.run.records.find(x => x.n === host.machineN); current = recLine(r); }
    try {
      this.size = W.StrataStage.draw(hostEl, {
        cfg, facts, plan, run: host.run, step, overlays: host.overlays, selection: host.selection, zoom: this.zoom,
        level: host.level, title: host.preset ? host.preset.id : '', upto: host.machineN, current,
        onSelect: (id) => { const wrap = this.el.querySelector('.sheetwrap'); if (wrap && wrap.__justPanned) return; host.select(id); },
      });
    } catch (e) { hostEl.innerHTML = failRow('The sheet does not render', e); return; }
    const r = host.run;
    this.autoFit();
    chips.innerHTML = `<span class="chip on">${esc(host.level)}</span><span class="chip">${esc((r && r.mode || host.mode).toUpperCase())}</span>${host.gc !== 'off' ? `<span class="chip">GC ${esc(host.gc.toUpperCase())}</span>` : ''}${host.machineN != null ? `<span class="chip">STEP ${esc(host.machineN)}</span>` : ''}${r && (r.events || []).some(e => e.type === 'stale') ? '<span class="chip rec">STALE</span>' : ''}${step ? `<span class="chip">ITERATION ${esc(step.i != null ? step.i : host.analysis.i + 1)}</span>` : ''}`;
  },
  fitZoom() {
    const wrap = this.el.querySelector('.sheetwrap'); if (!wrap || !this.size || !this.size.width || !wrap.clientWidth) return null;
    const nw = this.size.width / (this.zoom || 1), nh = this.size.height / (this.zoom || 1);
    // fit the width, never above 1; shrink for the height only down to 0.8, so labels stay readable (pan for the rest)
    const zw = (wrap.clientWidth - 12) / nw, zh = (wrap.clientHeight - 44) / nh;
    return Math.max(0.4, Math.floor(Math.min(1, zw, Math.max(zh, 0.8)) * 20) / 20);
  },
  // a new function or level is shown whole (never above 1) until you set the zoom yourself; Fit returns to that
  autoFit() {
    if (!this.auto) return;
    const key = [host.preset && host.preset.id, host.fn, host.level].join('|');
    if (key === this.fitKey) return;
    const z = this.fitZoom(); if (z == null) return;
    this.fitKey = key;
    if (Math.abs(z - this.zoom) > 0.01) { this.zoom = z; store.set('zoom', z); this.renderBar(); this.draw(); }
  },
  fit() {
    const z = this.fitZoom(); if (z == null) return;
    this.zoom = z; this.auto = true; this.fitKey = [host.preset && host.preset.id, host.fn, host.level].join('|');
    store.set('zoom', z); store.set('zoomAuto', true); this.renderBar(); this.draw();
  },
  renderSide() {
    const side = this.el.querySelector('aside.side'); if (!side) return;
    const P = host.program, id = host.selection;
    if (!P || !host.fn) { side.innerHTML = '<div class="block"><header><h2>Inspector</h2></header><p class="note">The inspector shows the selected op or block once a program is loaded.</p></div>'; return; }
    const cfg = safe(() => P.cfg(host.fn, host.level), null);
    const hit = opById(cfg, id);
    if (!hit) {
      const sm = safe(() => P.summary(), {}) || {};
      side.innerHTML = `<div class="block"><header><h2>${esc(host.fn)}</h2><span class="sub">function · ${esc(host.level)}</span></header><p class="note">Click an op or a block header on the sheet. The inspector shows its contract, the permissions derived from it, the facts at that point and its root slot.</p>${cfg ? `<dl class="kv"><dt>blocks</dt><dd>${cfg.blocks.length}</dd><dt>ops</dt><dd>${cfg.blocks.reduce((s, b) => s + b.ops.length + 1, 0)}</dd><dt>entry</dt><dd>${esc(cfg.entry)}</dd></dl>` : ''}</div>${sm.strategies ? `<div class="block"><header><h2>Pipeline</h2><span class="sub">resolved choices</span></header><pre class="src">${esc(yaml(sm.strategies))}</pre></div>` : ''}`;
      return;
    }
    const facts = safe(() => P.facts(host.fn), {}) || {};
    if (hit.kind === 'block') {
      const b = hit.b, live = facts.live || {}, types = facts.types || {};
      const visits = host.run ? (W.StrataStage.pathInfo(cfg, host.run, host.machineN).visits.get(b.name) || 0) : 0;
      side.innerHTML = `<div class="block"><header><h2><code>${esc(id)}</code></h2><span class="sub">block${b.name === cfg.entry ? ' · entry' : ''}</span></header>
<dl class="kv"><dt>params</dt><dd>${esc((b.params || []).map(p => p.id + (p.type ? ': ' + p.type : '')).join(', ') || 'none')}</dd><dt>ops</dt><dd>${b.ops.length} + terminator</dd><dt>immediate dominator</dt><dd>${esc((facts.idom || {})[b.name] || '—')}</dd><dt>visits in the last run</dt><dd>${visits}</dd></dl></div>
<div class="block"><header><h2>Live</h2><span class="sub">liveness facts</span></header><div class="refs"><span class="lbl">in</span>${valList((live.in || {})[b.name])}</div><div class="refs"><span class="lbl">out</span>${valList((live.out || {})[b.name])}</div>${(b.params || []).some(p => types[p.id]) ? `<div class="refs"><span class="lbl">types</span>${(b.params || []).map(p => `<code class="nid dim">${esc(p.id)}: ${esc(types[p.id] || '?')}</code>`).join(' ')}</div>` : ''}</div>
<div class="actions"><button class="link" data-act="lab" data-arg="lab:show?view=ir">show in IR</button> <button class="link" data-act="clear">clear the selection</button></div>`;
      return;
    }
    const op = hit.op || {};
    const perm = safe(() => P.perm(id), e => ({ _err: e.message }));
    const live = ((facts.live || {}).across || {})[id];
    const sp = (facts.safepoints || []).includes(id);
    const plan = safe(() => normPlan(P.plan(host.fn)), null);
    const at = plan && (plan.safepoints || []).find(p => p.op === id);
    const slotOf = new Map(); if (plan) for (const s of plan.slots || []) for (const v of s.values || []) slotOf.set(v, s.slot);
    const PERMS = ['erase', 'merge', 'move', 'duplicate', 'hoist', 'speculate'];
    const permRows = perm && !perm._err ? PERMS.map(k => {
      const v = perm[k], cls = v === true ? '' : v === false ? 'no' : 'cond';
      const why = (perm.because && perm.because[k]) || [];
      return `<tr><td>${k}</td><td class="${cls}">${esc(permWord(v))}${why.length ? `<small>${esc([].concat(why).join('; '))}</small>` : ''}</td></tr>`;
    }).join('') : '';
    const contract = perm && perm.contract;
    const why = this.whyOpen ? safe(() => yaml(P.why(id)), e => 'why() failed: ' + e.message) : null;
    side.innerHTML = `<div class="block"><header><h2><code>${esc(id)}</code></h2><span class="sub">${esc(hit.kind === 'term' ? (op.kind === 'invoke' ? 'invoke · terminator' : 'terminator · ' + (op.kind || '')) : 'op · ' + (op.op || ''))}</span></header><code class="exprtxt">${esc(op.text || '')}</code>
${op.mayThrow || op.invoke || op.kind === 'invoke' ? '<p class="note">May throw: the exceptional edge receives the thrown value and the state after any effects already performed.</p>' : ''}</div>
${contract ? `<div class="block"><header><h2>Contract</h2><span class="sub">${esc(op.op || '')}</span></header><dl class="kv keys"><dt>behaviour</dt><dd>${esc(typeof contract.behaviour === 'string' ? contract.behaviour : yaml1(contract.behaviour))}</dd><dt>obligations</dt><dd>${esc(typeof contract.obligations === 'string' ? contract.obligations : Array.isArray(contract.obligations) ? (contract.obligations.length ? contract.obligations.map(o => typeof o === 'string' ? o : yaml1(o)).join(', ') : 'none') : yaml1(contract.obligations))}</dd></dl></div>` : ''}
<div class="block"><header><h2>Permissions</h2><span class="sub">derived from the contract and the facts</span></header>${perm && perm._err ? `<div class="fail">${esc(perm._err)}</div>` : `<table class="rt permt"><tbody>${permRows}</tbody></table>`}</div>
<div class="block"><header><h2>Facts</h2><span class="sub">at this op</span></header><div class="refs"><span class="lbl">live after</span>${valList(live)}</div>${(op.results || []).length ? `<div class="refs"><span class="lbl">types</span>${op.results.map(r => `<code class="nid dim">${esc(r)}: ${esc(((facts.types || {})[r]) || '?')}</code>`).join(' ')}</div>` : ''}<dl class="kv"><dt>safepoint (may collect)</dt><dd>${sp ? 'yes' : 'no'}</dd></dl></div>
${plan ? `<div class="block"><header><h2>Plan</h2><span class="sub">${esc(plan.strategy || '')}</span></header>${at ? `<div class="refs"><span class="lbl">rooted</span>${(at.rooted || []).length ? at.rooted.map(v => `<code class="nid dim">${esc(v)} → s${esc(slotOf.has(v) ? slotOf.get(v) : '?')}</code>`).join(' ') : '<span class="dim">none</span>'}</div>${(at.missing || []).length ? `<div class="refs"><span class="lbl bad">missing</span>${at.missing.map(v => `<code class="nid bad">${esc(v)}</code>`).join(' ')}</div>` : ''}` : '<p class="note">Not a safepoint in the plan: nothing is rooted here.</p>'}</div>` : ''}
<div class="block"><header><h2>Why</h2><span class="sub">program.why</span></header>${why != null ? `<pre class="src why">${esc(why)}</pre>` : ''}<button class="link strong" data-act="why">${why != null ? 'hide the explanation' : 'explain this op across levels'}</button></div>
<div class="actions"><button class="link" data-act="lab" data-arg="lab:show?view=ir">show in IR</button> <button class="link" data-act="lab" data-arg="lab:show?view=facts">facts</button> <button class="link" data-act="lab" data-arg="lab:show?view=plan">plan</button> <button class="link" data-act="clear">clear the selection</button></div>`;
  },
});

/* ---------- IR ---------- */
const IR_LEVELS = ['L0', 'L1', 'L2', 'L3', 'LLVM', 'WAT'];
const IR_ABOUT = {
  L0: 'The source as main.js handed it to the pipeline.',
  L1: 'Core IR: blocks with parameters and one terminator each; an invoke has a normal and a throw edge.',
  L2: "Runtime IR: each operation bound to its provider's helper, with the obligations that come with it.",
  L3: 'The execution plan: root slots, spills and reloads around safepoints, unwind checkpoints.',
  LLVM: 'LLVM IR text in the shape of the existing Hermes backend. Shown here, not run.',
  WAT: 'WebAssembly text for the functions the Wasm backend accepts; Wasm mode runs the binary.',
};
view('ir', {
  mount(el) {
    this.el = el; this.render();
    el.addEventListener('click', ev => {
      const b = ev.target.closest('[data-act]'); if (!b) return;
      const a = b.dataset.act, arg = b.dataset.arg;
      if (a === 'irl') { host.irLevel = arg; if (/^L[1-3]$/.test(arg)) host.level = arg; host.emit('level'); }
      else if (a === 'fmt') { host.irFormat = arg; this.render(); }
      else if (a === 'all') { host.irAll = !host.irAll; this.render(); }
      else if (a === 'copy') copyText(this.text || '', host.irLevel);
    });
    bindFn(el);
  },
  update(w) { if (['preset', 'build', 'fn', 'level', 'select', 'run'].includes(w)) this.render(); },
  render() {
    const el = this.el, P = host.program;
    const bar = `<div class="toolbar"><div class="seg" role="group" aria-label="Level">${IR_LEVELS.map(l => `<button class="${host.irLevel === l ? 'on' : ''}" aria-pressed="${host.irLevel === l}" data-act="irl" data-arg="${l}">${l}</button>`).join('')}</div>${fnSelect()}<button class="tog${host.irAll ? ' on' : ''}" data-act="all">All functions</button><div class="seg sm" role="group" aria-label="Format">${['text', 'json'].map(f => `<button class="${host.irFormat === f ? 'on' : ''}" data-act="fmt" data-arg="${f}">${f === 'text' ? 'Text' : 'JSON'}</button>`).join('')}</div><button class="btn sm" data-act="copy">Copy</button><span class="lbl">${esc(IR_ABOUT[host.irLevel] || '')}</span></div>`;
    if (!P) { el.innerHTML = `<div class="tabbody col">${bar}<div class="scroll">${noProgram()}</div></div>`; return; }
    let text;
    try {
      const fns = host.irAll || host.irLevel === 'L0' ? [null] : [host.fn];
      text = fns.map(fn => P.ir(host.irLevel, fn ? { fn, format: host.irFormat } : { format: host.irFormat })).join('\n\n');
    } catch (e) { el.innerHTML = `<div class="tabbody col">${bar}<div class="scroll">${failRow(`${host.irLevel} does not print`, e)}</div></div>`; return; }
    this.text = text;
    const cfg = safe(() => P.cfg(host.fn, /^L[1-3]$/.test(host.irLevel) ? host.irLevel : 'L1'), null);
    const hit = opById(cfg, host.selection);
    const needle = hit && hit.op && hit.op.text ? hit.op.text.trim() : null;
    const lang = host.irLevel === 'L0' ? 'js' : host.irFormat === 'json' ? 'text' : 'ir';
    const lines = MD.highlightLines(String(text), lang);
    const raw = String(text).split('\n');
    keepScroll(el, () => {
      el.innerHTML = `<div class="tabbody col">${bar}<div class="scroll" data-scroll="ir"><pre class="irtext">${lines.map((l, i) => `<div class="${needle && raw[i] && raw[i].includes(needle) ? 'hl' : ''}">${l || ' '}</div>`).join('')}</pre></div></div>`;
    });
  },
});

/* ---------- Facts ---------- */
const ANALYSES = [['liveness', 'Liveness'], ['types', 'Types'], ['dominators', 'Dominators']];
view('facts', {
  mount(el) {
    this.el = el; this.render();
    el.addEventListener('click', ev => {
      const b = ev.target.closest('[data-act]'); if (!b) return;
      const a = b.dataset.act, arg = b.dataset.arg;
      if (a === 'an') { host.analysis = { name: arg, i: null }; host.emit('analysis'); }
      else if (a === 'prev' || a === 'next' || a === 'first') {
        const n = this.steps().length; if (!n) return;
        let i = host.analysis.i;
        if (a === 'first') i = 0; else if (i == null) i = a === 'next' ? 0 : n - 1; else i = Math.max(0, Math.min(n - 1, i + (a === 'next' ? 1 : -1)));
        host.analysis = { name: host.analysis.name, i }; host.emit('analysis');
      } else if (a === 'clear') { host.analysis = { name: host.analysis.name, i: null }; host.emit('analysis'); }
      else if (a === 'sel') host.select(arg);
    });
    bindFn(el);
  },
  update(w) { if (['preset', 'build', 'fn', 'analysis', 'select'].includes(w)) this.render(); },
  steps() { const P = host.program; if (!P || !host.fn || host.analysis.name === 'dominators') return []; return safe(() => P.steps(host.fn, host.analysis.name) || [], []); },
  render() {
    const el = this.el, P = host.program, an = host.analysis.name;
    const steps = this.steps(), i = host.analysis.i;
    const stepper = an === 'dominators' ? '' : `<div class="stepbar"><button class="ibtn" data-act="prev" title="Previous iteration"${steps.length ? '' : ' disabled'}>‹</button><button class="ibtn" data-act="next" title="Next iteration"${steps.length ? '' : ' disabled'}>›</button><span class="lbl">${steps.length ? (i == null ? `${plural(steps.length, 'iteration')} to the fixed point` : `iteration ${i + 1} of ${steps.length}`) : 'no recorded iterations'}</span>${i != null ? '<button class="btn sm" data-act="clear">Clear</button>' : ''}</div>`;
    const bar = `<div class="toolbar"><div class="seg" role="group" aria-label="Analysis">${ANALYSES.map(([k, t]) => `<button class="${an === k ? 'on' : ''}" aria-pressed="${an === k}" data-act="an" data-arg="${k}">${t}</button>`).join('')}</div>${fnSelect()}${stepper}<span class="lbl">${an === 'liveness' ? 'Backward over blocks: a value is live where a later use may need it. Block arguments and throw edges count as uses.' : an === 'types' ? 'Forward over blocks: each value gets the join of the types that reach it.' : 'The immediate dominator of each block: every path from the entry passes through it.'}</span></div>`;
    if (!P || !host.fn) { el.innerHTML = `<div class="tabbody col facts">${bar}<div class="scroll">${noProgram()}</div></div>`; return; }
    let f; try { f = P.facts(host.fn) || {}; } catch (e) { el.innerHTML = `<div class="tabbody col facts">${bar}<div class="scroll">${failRow('facts() failed', e)}</div></div>`; return; }
    const st = i != null ? steps[i] : null;
    const set = s => { const L = Array.isArray(s) ? s.map(String) : (s && typeof s === 'object') ? Object.keys(s).map(k => `${k}:${typeof s[k] === 'string' ? s[k] : yaml1(s[k])}`) : []; return L.length ? L.map(v => `<code>${esc(v)}</code>`).join(' ') : '<span class="dim">∅</span>'; };
    let body = '';
    if (st) body += `<div class="stepnow">Iteration ${i + 1}: block <b>${esc(st.block)}</b>${st.before && st.after ? ` · in ${set(st.before.in)} → ${set(st.after.in)} · out ${set(st.before.out)} → ${set(st.after.out)}` : ''} · ${st.changed ? '<b class="bad">changed</b>' : 'unchanged'}${i === steps.length - 1 ? ' · the worklist is empty: this is the fixed point' : ''}</div>`;
    const blocks = safe(() => P.cfg(host.fn, 'L1').blocks.map(b => b.name), Object.keys((f.live || {}).in || {}));
    if (an === 'liveness') {
      const live = f.live || {};
      const inS = st && st.after ? null : live.in, outS = st && st.after ? null : live.out;
      // while stepping, show the sets as of that iteration
      const asOf = {};
      if (st) { for (const b of blocks) asOf[b] = { in: [], out: [] }; for (let k = 0; k <= i; k++) { const s = steps[k]; if (s && s.after) asOf[s.block] = s.after; } }
      body += `<div class="tblock"><h3>Live in and out<small>${st ? 'as of iteration ' + (i + 1) : plural(f.iterations && f.iterations.liveness || 0, 'iteration')}</small></h3><table class="rt"><thead><tr><th>block</th><th>live in</th><th>live out</th></tr></thead><tbody>${blocks.map(b => `<tr class="clickable${st && st.block === b ? ' hl' : ''}" data-act="sel" data-arg="${esc(host.fn + '/' + b)}"><td class="nm"><code>${esc(b)}</code></td><td>${set(st ? asOf[b].in : (inS || {})[b])}</td><td>${set(st ? asOf[b].out : (outS || {})[b])}</td></tr>`).join('')}</tbody></table></div>`;
      const across = live.across || {}, sp = new Set(f.safepoints || []);
      const cfg = safe(() => P.cfg(host.fn, 'L1'), null);
      const rows = [];
      if (cfg) for (const b of cfg.blocks) { b.ops.forEach((o, k) => rows.push([o.id || `${host.fn}/${b.name}/${k}`, o.text])); rows.push([(b.term && b.term.id) || `${host.fn}/${b.name}/term`, b.term && b.term.text]); }
      body += `<div class="tblock"><h3>Live after each op<small>a safepoint must root every managed value live after it</small></h3><table class="rt"><thead><tr><th>op</th><th>text</th><th>live after</th><th>safepoint</th></tr></thead><tbody>${rows.map(([id, t]) => `<tr class="clickable${host.selection === id ? ' hl' : ''}" data-act="sel" data-arg="${esc(id)}"><td class="code">${esc(id.split('/').slice(1).join('/'))}</td><td class="code">${esc(cut(t || '', 48))}</td><td>${set(across[id])}</td><td>${sp.has(id) ? '<b>gc</b>' : ''}</td></tr>`).join('')}</tbody></table></div>`;
    } else if (an === 'types') {
      const ty = f.types || {};
      const ks = Object.keys(ty);
      body += `<div class="tblock"><h3>Type facts<small>${plural(ks.length, 'value')}</small></h3>${ks.length ? `<table class="rt"><thead><tr><th>value</th><th>type</th></tr></thead><tbody>${ks.map(k => `<tr><td class="code">${esc(k)}</td><td><b>${esc(ty[k])}</b></td></tr>`).join('')}</tbody></table>` : '<p class="empty">No type facts for this function.</p>'}</div>`;
    } else {
      const idom = f.idom || {};
      body += `<div class="tblock"><h3>Immediate dominators</h3><table class="rt"><thead><tr><th>block</th><th>immediate dominator</th></tr></thead><tbody>${blocks.map(b => `<tr class="clickable" data-act="sel" data-arg="${esc(host.fn + '/' + b)}"><td class="code">${esc(b)}</td><td class="code">${esc(idom[b] || '—')}</td></tr>`).join('')}</tbody></table></div>`;
    }
    keepScroll(el, () => { el.innerHTML = `<div class="tabbody col facts">${bar}<div class="scroll" data-scroll="facts">${body}</div></div>`; });
  },
});

/* ---------- Plan ---------- */
function planChart(plan) {
  const sps = plan.safepoints || [], slots = (plan.slots || []).slice().sort((a, b) => a.slot - b.slot);
  if (!sps.length || !slots.length) return '<p class="empty">No safepoints with rooted values in this function.</p>';
  const slotOf = new Map(); for (const s of slots) for (const v of s.values || []) slotOf.set(v, s.slot);
  const hasMissing = sps.some(p => (p.missing || []).length);
  const cw = 70, rh = 18, lx = 62, top = 64;
  const rows = slots.length + (hasMissing ? 1 : 0);
  const w = lx + cw * sps.length + 16, h = top + rh * rows + 26;
  const p = [];
  p.push(`<svg class="chart sheet" xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}" role="img" aria-label="Root slots at each safepoint">`);
  p.push(`<rect class="f-bg" x="0" y="0" width="${w}" height="${h}"/>`);
  sps.forEach((sp, j) => {
    const x = lx + j * cw + cw / 2;
    const short = String(sp.op).split('/').slice(1).join('/');
    p.push(`<text class="lbl8 t-mut" transform="translate(${x - 4},${top - 6}) rotate(-38)">${esc(cut(short, 18))}</text>`);
    p.push(`<line class="s-major" x1="${lx + j * cw}" x2="${lx + j * cw}" y1="${top}" y2="${top + rh * rows}" stroke-width="0.6"/>`);
  });
  p.push(`<line class="s-major" x1="${lx + cw * sps.length}" x2="${lx + cw * sps.length}" y1="${top}" y2="${top + rh * rows}" stroke-width="0.6"/>`);
  slots.forEach((s, r) => {
    const y = top + r * rh;
    p.push(`<line class="s-major" x1="${lx}" x2="${lx + cw * sps.length}" y1="${y}" y2="${y}" stroke-width="0.6"/><text class="lbl8 t-ink" x="8" y="${y + 12}">SLOT ${esc(s.slot)}</text>`);
    sps.forEach((sp, j) => {
      const vals = (sp.rooted || []).filter(v => slotOf.get(v) === s.slot);
      if (!vals.length) return;
      p.push(`<rect fill="none" class="s-violet" x="${lx + j * cw + 2}" y="${y + 2}" width="${cw - 4}" height="${rh - 4}" stroke-width="1"/><text class="lbl8 t-violet" x="${lx + j * cw + 6}" y="${y + 12}">${esc(cut(vals.join(' '), 11))}</text>`);
    });
  });
  if (hasMissing) {
    const y = top + slots.length * rh;
    p.push(`<line class="s-major" x1="${lx}" x2="${lx + cw * sps.length}" y1="${y}" y2="${y}" stroke-width="0.6"/><text class="lbl8 t-rec" x="8" y="${y + 12}">MISSING</text>`);
    sps.forEach((sp, j) => { if ((sp.missing || []).length) p.push(`<text class="lbl8 t-rec" x="${lx + j * cw + 6}" y="${y + 12}">${esc(cut(sp.missing.join(' '), 11))}</text>`); });
  }
  p.push(`<line class="s-major" x1="${lx}" x2="${lx + cw * sps.length}" y1="${top + rh * rows}" y2="${top + rh * rows}" stroke-width="0.6"/>`);
  p.push(`<text class="lbl8 t-mut" x="8" y="${h - 8}">COLUMNS: SAFEPOINTS IN PROGRAM ORDER · ROWS: ROOT SLOTS · A BOX: A LIVE MANAGED VALUE ROOTED THERE</text>`);
  return p.join('') + '</svg>';
}
view('plan', {
  mount(el) { this.el = el; this.render(); el.addEventListener('click', ev => { const b = ev.target.closest('[data-act]'); if (b && b.dataset.act === 'lab') host.link(b.dataset.arg); if (b && b.dataset.act === 'sel') host.select(b.dataset.arg); }); bindFn(el); },
  update(w) { if (['preset', 'build', 'fn', 'run'].includes(w)) this.render(); },
  render() {
    const el = this.el, P = host.program;
    const bar = `<div class="toolbar">${fnSelect()}<button class="btn sm" data-act="lab" data-arg="lab:run?mode=plan&amp;gc=stress">Run in Plan mode, GC stress</button><span class="lbl">Rows are root slots, columns the safepoints in program order; a box holds a live managed value. Stress collects at every safepoint, so a missing root shows up as a stale use.</span></div>`;
    if (!P || !host.fn) { el.innerHTML = `<div class="tabbody col plan">${bar}<div class="scroll">${noProgram()}</div></div>`; return; }
    let plan; try { plan = normPlan(P.plan(host.fn)) || {}; } catch (e) { el.innerHTML = `<div class="tabbody col plan">${bar}<div class="scroll">${failRow('plan() failed', e)}</div></div>`; return; }
    const kv = [['strategy', plan.strategy], ['root slots', plan.rootSlots], ['fixed slots', plan.fixedSlots], ['argument slots', plan.argSlots], ['frame', plan.frameBytes != null ? `${plan.frameBytes} B` : '—'], ['peak live', plan.peakLive]];
    const reps = plan.reps || {}, unwind = plan.unwind || [];
    const missing = (plan.safepoints || []).reduce((s, p) => s + (p.missing || []).length, 0);
    const body = `<div class="tblock"><h3>Frame<small>${esc(host.fn)}</small></h3><dl class="kv">${kv.map(([k, v]) => `<dt>${esc(k)}</dt><dd>${esc(v == null ? '—' : v)}</dd>`).join('')}</dl>${missing ? `<div class="fail" style="margin-top:8px"><b>${plural(missing, 'missing root')}.</b> A value live across a collecting op has no slot. Run in Plan mode with GC stress to see the stale use.</div>` : ''}</div>
<div class="tblock"><h3>Slots at safepoints</h3><div class="chartwrap">${planChart(plan)}</div></div>
<div class="tblock"><h3>Representations<small>how each value is stored</small></h3>${Object.keys(reps).length ? `<table class="rt"><thead><tr><th>value</th><th>representation</th></tr></thead><tbody>${Object.entries(reps).map(([k, v]) => `<tr><td class="code">${esc(k)}</td><td>${esc(v)}</td></tr>`).join('')}</tbody></table>` : '<p class="empty">No representation choices recorded.</p>'}</div>
<div class="tblock"><h3>Unwinding<small>what each exceptional edge restores</small></h3>${unwind.length ? `<table class="rt"><thead><tr><th>op</th><th>handler</th><th>strategy</th><th>restores</th></tr></thead><tbody>${unwind.map(u => `<tr class="clickable" data-act="sel" data-arg="${esc(u.op)}"><td class="code">${esc(String(u.op).split('/').slice(1).join('/'))}</td><td class="code">${esc(u.handler || '—')}</td><td>${esc(u.strategy || '')}</td><td>${esc([].concat(u.restores || []).join(', '))}</td></tr>`).join('')}</tbody></table>` : '<p class="empty">No exceptional edges in this function.</p>'}</div>`;
    keepScroll(el, () => { el.innerHTML = `<div class="tabbody col plan">${bar}<div class="scroll" data-scroll="plan">${body}</div></div>`; });
  },
});

/* ---------- Machine ---------- */
view('machine', {
  mount(el) {
    this.el = el; this.render();
    el.addEventListener('click', ev => {
      const b = ev.target.closest('[data-act]'); if (!b) return;
      const a = b.dataset.act, arg = b.dataset.arg;
      if (a === 'mode') host.setMode(arg);
      else if (a === 'gc') host.setGC(arg);
      else if (a === 'rerun') host.exec();
      else if (a === 'rec') { host.machineN = +arg; host.emit('step'); }
      else if (a === 'sprev' || a === 'snext') { const recs = (host.run && host.run.records) || []; if (!recs.length) return; let k = recs.findIndex(r => r.n === host.machineN); if (k < 0) k = a === 'snext' ? -1 : recs.length; k = Math.max(0, Math.min(recs.length - 1, k + (a === 'snext' ? 1 : -1))); host.machineN = recs[k].n; host.emit('step'); }
      else if (a === 'send') { host.machineN = null; host.emit('step'); }
    });
    el.addEventListener('input', ev => { if (ev.target.matches('input[data-scrub]')) { const recs = (host.run && host.run.records) || []; const r = recs[+ev.target.value]; if (r) { host.machineN = r.n; host.emit('step'); } } });
  },
  update(w) { if (['preset', 'build', 'run', 'step'].includes(w)) this.render(); },
  badge() { const r = host.run; const n = r ? (r.events || []).filter(e => e.type === 'stale').length : 0; return n ? ` <span class="count bad">${n}</span>` : ''; },
  render() {
    const el = this.el, r = host.run;
    const recs = (r && r.records) || [];
    let k = host.machineN == null ? recs.length - 1 : recs.findIndex(x => x.n === host.machineN);
    if (k < 0) k = recs.length - 1;
    const bar = `<div class="toolbar"><div class="seg sm" role="group" aria-label="Run mode">${['spec', 'plan', 'wasm'].map(x => `<button class="${host.mode === x ? 'on' : ''}" data-act="mode" data-arg="${x}">${{ spec: 'Spec', plan: 'Plan', wasm: 'Wasm' }[x]}</button>`).join('')}</div><div class="seg sm" role="group" aria-label="GC">${['off', 'alloc', 'stress'].map(x => `<button class="${host.gc === x ? 'on' : ''}" data-act="gc" data-arg="${x}">${{ off: 'GC off', alloc: 'Alloc', stress: 'Stress' }[x]}</button>`).join('')}</div><button class="btn sm" data-act="rerun"${host.program ? '' : ' disabled'}>Run again</button>
<div class="scrub"><button class="ibtn" data-act="sprev" title="Previous step"${recs.length ? '' : ' disabled'}>‹</button><input type="range" data-scrub="1" min="0" max="${Math.max(0, recs.length - 1)}" value="${Math.max(0, k)}" aria-label="Step"${recs.length ? '' : ' disabled'}><button class="ibtn" data-act="snext" title="Next step"${recs.length ? '' : ' disabled'}>›</button><span class="now">${recs.length ? `step ${fmtInt(recs[k] ? recs[k].n : 0)} of ${fmtInt(r.steps != null ? r.steps : recs.length)}` : 'no steps recorded'}</span>${host.machineN != null ? '<button class="btn sm" data-act="send">End</button>' : ''}</div></div>`;
    if (!r) { el.innerHTML = `<div class="tabbody col machine">${bar}<div class="scroll">${host.program ? '<p class="empty padded">The program has not run yet. Press Run again.</p>' : noProgram()}</div></div>`; return; }
    const m = r.metrics || {}, o = r.outcome || {};
    const kv = [['outcome', o.kind], ['value', o.value === undefined ? '—' : yaml1(o.value)], ['steps', fmtInt(r.steps)], ['calls', fmtInt(m.calls)], ['collections', fmtInt(m.collections)], ['objects moved', fmtInt(m.moved)], ['peak root slots', fmtInt(m.peakRootSlots)], ['root bytes', m.rootBytes != null ? `${fmtInt(m.rootBytes)} B` : '—'], ['jobs', fmtInt(m.jobs)], ['max depth', fmtInt(m.maxDepth)]];
    const lo = Math.max(0, k - 100), hi = Math.min(recs.length, lo + 200);
    const stale = (r.events || []).filter(e => e.type === 'stale');
    const body = `<div class="tblock"><h3>Outcome<small>${esc(r.mode || host.mode)} · GC ${esc(host.gc)}</small></h3>${r.error ? `<div class="fail"><b>The run stopped:</b> ${esc(r.error.message || '')}${r.error.at ? ' at ' + esc(typeof r.error.at === 'string' ? r.error.at : yaml1(r.error.at)) : ''}</div>` : ''}${stale.length ? `<div class="fail"><b>${plural(stale.length, 'stale use')}:</b> a value was used after the collector moved its object, because the plan gave it no root. ${esc(stale.slice(0, 3).map(e => (e.value || e.id || '') + (e.at ? ' at ' + (typeof e.at === 'string' ? e.at : yaml1(e.at)) : '')).join('; '))}</div>` : ''}<dl class="kv">${kv.map(([a, b]) => `<dt>${esc(a)}</dt><dd>${esc(b == null ? '—' : b)}</dd>`).join('')}</dl></div>
<div class="tblock"><h3>Output<small>${plural((r.output || []).length, 'line')}</small></h3>${(r.output || []).length ? `<pre class="out">${esc(r.output.join('\n'))}</pre>` : '<p class="empty">No output.</p>'}</div>
<div class="tblock" style="padding-left:0;padding-right:0"><h3 style="padding:0 14px">Steps<small>${recs.length ? `records ${fmtInt(lo + 1)}–${fmtInt(hi)} of ${fmtInt(recs.length)}${r.steps > recs.length ? ` (the first ${fmtInt(recs.length)} steps are recorded)` : ''}` : 'none recorded'}</small></h3>${recs.slice(lo, hi).map((x, j) => `<div class="rec${lo + j === k && host.machineN != null ? ' sel' : ''}" data-act="rec" data-arg="${x.n}"><span class="t">${fmtInt(x.n)}</span><span class="w">${esc(x.fn + '/' + x.block)}</span><span>${esc('  '.repeat(Math.min(6, x.depth || 0)) + (x.text || ''))}</span><span class="v">${x.value === undefined ? '' : esc(cut(yaml1(x.value), 40))}</span></div>`).join('')}</div>`;
    keepScroll(el, () => { el.innerHTML = `<div class="tabbody col machine">${bar}<div class="scroll" data-scroll="machine">${body}</div></div>`; });
    if (host.machineN != null) { const s = el.querySelector('.rec.sel'); if (s && s.scrollIntoView) s.scrollIntoView({ block: 'nearest' }); }
  },
});

/* ---------- Events ---------- */
const where = at => !at ? '' : typeof at === 'string' ? at : at.file ? `${at.file}${at.line ? ':' + at.line : ''}` : at.fn ? `${at.fn}${at.block ? '/' + at.block : ''}${at.op != null ? '/' + at.op : ''}` : yaml1(at);
view('events', {
  off: new Set(), q: '', open: new Set(),
  mount(el) {
    this.el = el; this.render();
    el.addEventListener('click', ev => {
      const b = ev.target.closest('[data-act]'); if (!b) return;
      const a = b.dataset.act, arg = b.dataset.arg;
      if (a === 'type') { if (this.off.has(arg)) this.off.delete(arg); else this.off.add(arg); this.render(); }
      else if (a === 'ev') { if (this.open.has(arg)) this.open.delete(arg); else this.open.add(arg); this.render(); }
      else if (a === 'goto') { const e = this.list().find(x => x.key === arg); if (e && e.at) { if (e.at.file) host.openFile_(e.at.file, { line: e.at.line }); else if (typeof e.at === 'string' && e.at.includes('/')) { host.select(e.at); host.focus('stage'); } else if (e.at.fn) { host.select(e.at.op != null ? `${e.at.fn}/${e.at.block}/${e.at.op}` : e.at.block ? `${e.at.fn}/${e.at.block}` : e.at.fn); host.focus('stage'); } } }
    });
    el.addEventListener('input', ev => { if (ev.target.matches('.evsearch')) { this.q = ev.target.value; this.renderList(); } });
  },
  update(w) { if (['preset', 'build', 'run'].includes(w)) { this.open.clear(); this.render(); } },
  list() {
    const out = []; let k = 0;
    const push = e => { e.key = 'e' + (k++); out.push(e); };
    if (host.buildInfo && !host.buildInfo.ok) push({ type: 'error', bad: true, at: { file: 'main.js', line: host.buildInfo.line }, what: host.buildInfo.message });
    for (const l of host.logs || []) push({ type: 'log', what: l });
    if (host.hasOther) push({ type: 'value', what: yaml1(host.other).slice(0, 200), detail: yaml(host.other) });
    const P = host.program;
    if (P) {
      for (const d of safe(() => P.diagnostics || [], [])) push({ type: 'diagnostic', bad: d.severity === 'error', at: d.at, what: `${d.severity}${d.kind ? ' ' + d.kind : ''}: ${d.message}`, detail: yaml(d) });
      for (const d of safe(() => P.decisions || [], [])) push({ type: 'decision', at: d.at, what: `${d.by || ''} ${d.fired ? 'fired' : 'did not fire'}${d.because ? ': ' + [].concat(d.because).join('; ') : ''}`, detail: yaml(d), dim: !d.fired });
      for (const t of safe(() => P.trace || [], [])) push({ type: 'pass', at: t.level, what: `${t.pass} · ${t.ms != null ? (Math.round(t.ms * 100) / 100) + ' ms' : ''}${t.note ? ' · ' + t.note : ''}`, dim: true });
    }
    const r = host.run;
    if (r) for (const e of r.events || []) {
      const { n, type, at, ...rest } = e;
      push({ n, type: type || 'event', at, bad: type === 'stale' || type === 'error' || type === 'throw', what: Object.keys(rest).length ? yaml1(rest) : '', detail: yaml(e) });
    }
    return out;
  },
  renderList() {
    const box = this.el.querySelector('.evlist'); if (!box) return;
    const q = this.q.toLowerCase();
    const L = this.list().filter(e => !this.off.has(e.type) && (!q || (e.type + ' ' + where(e.at) + ' ' + e.what).toLowerCase().includes(q)));
    box.innerHTML = L.length ? L.map(e => `<div class="ev${e.bad ? ' bad' : ''}${e.dim ? ' dimrow' : ''}" data-act="ev" data-arg="${e.key}"><span class="t">${e.n != null ? fmtInt(e.n) : ''}</span><span class="kd">${esc(e.type)}</span><span class="what">${e.at ? `<button class="link w" data-act="goto" data-arg="${e.key}">${esc(where(e.at))}</button> ` : ''}${esc(e.what)}</span></div>${this.open.has(e.key) && e.detail ? `<pre class="src evdetail">${esc(e.detail)}</pre>` : ''}`).join('') : '<p class="empty padded">No events. Output, run events, diagnostics, decisions and pass timings appear here after Run.</p>';
  },
  render() {
    const L = this.list(); const counts = {};
    for (const e of L) counts[e.type] = (counts[e.type] || 0) + 1;
    const types = Object.keys(counts);
    this.el.innerHTML = `<div class="tabbody col events"><div class="toolbar"><div class="chips evchips">${types.map(t => `<button class="${this.off.has(t) ? '' : 'on'}" data-act="type" data-arg="${esc(t)}">${esc(t)} <small>${counts[t]}</small></button>`).join('')}</div><input class="evsearch" placeholder="filter lines" value="${esc(this.q)}" aria-label="Filter events"></div><div class="evlist" data-scroll="ev"></div></div>`;
    this.renderList();
  },
});

/* ---------- Laws ---------- */
view('laws', {
  mount(el) { this.el = el; this.render(); el.addEventListener('click', ev => { const b = ev.target.closest('[data-act]'); if (b && b.dataset.act === 'rerun') host.build(); }); },
  update(w) { if (['preset', 'build'].includes(w)) this.render(); },
  badge() { const L = host.laws && host.laws.laws; const n = L ? L.filter(l => !l.ok).length : 0; return n ? ` <span class="count bad">${n}</span>` : ''; },
  render() {
    const el = this.el, R = host.laws, L = R && Array.isArray(R.laws) ? R.laws : null;
    const bad = L ? L.filter(l => !l.ok).length : 0;
    const bar = `<div class="toolbar"><button class="btn sm" data-act="rerun">Run the laws again</button><span class="lbl">${L ? `${plural(L.length, 'law')} · ${L.length - bad} hold · ${bad} failed` : 'Laws are properties checked on generated inputs; a failure comes with a minimized counterexample.'}</span></div>`;
    if (!L) { el.innerHTML = `<div class="tabbody col">${bar}<p class="empty padded">This preset reports no laws. A main.js that returns a LawReport fills this view, for example <code>return g.laws([g.law.join(g.fx), g.law.monotone(g.analysis.liveness)]).run()</code>.</p></div>`; return; }
    el.innerHTML = `<div class="tabbody col">${bar}<div class="scroll" data-scroll="laws">${L.map(l => `<div class="lawrow${l.ok ? '' : ' bad'}"><header><b>${esc(l.name)}</b><span class="verdict">${l.ok ? 'holds' : 'fails'}</span>${l.samples != null ? `<span class="sub">${plural(l.samples, 'sample')}</span>` : ''}${l.note ? `<span class="sub">${esc(l.note)}</span>` : ''}</header>${!l.ok && l.counterexample !== undefined ? `<span class="sub">counterexample</span><pre class="src">${esc(typeof l.counterexample === 'string' ? l.counterexample : yaml(l.counterexample))}</pre>` : ''}${!l.ok && l.minimized !== undefined ? `<span class="sub">minimized</span><pre class="src">${esc(typeof l.minimized === 'string' ? l.minimized : yaml(l.minimized))}</pre>` : ''}</div>`).join('')}</div></div>`;
  },
});

/* ---------- Experiments ---------- */
view('experiments', {
  mount(el) { this.el = el; this.render(); el.addEventListener('click', ev => { const b = ev.target.closest('[data-act]'); if (b && b.dataset.act === 'rerun') host.build(); }); },
  update(w) { if (['preset', 'build'].includes(w)) this.render(); },
  table(R) {
    const cols = R.columns && R.columns.length ? R.columns : Object.keys((R.rows || [])[0] || {}).map(k => ({ key: k, label: k }));
    const fmt = v => v == null ? '—' : typeof v === 'number' ? (Math.abs(v) >= 1000 ? fmtInt(v) : String(Math.round(v * 1000) / 1000)) : typeof v === 'object' ? yaml1(v) : String(v);
    const numCol = c => (R.rows || []).some(r => typeof r[c.key] === 'number') && (R.rows || []).every(r => r[c.key] == null || typeof r[c.key] === 'number');
    const isBest = row => R.best && (R.best === row || (R.best.point && row.point && JSON.stringify(R.best.point) === JSON.stringify(row.point)) || (R.best.id != null && R.best.id === row.id));
    return `<div class="reshd"><b>${esc(R.title || 'Results')}</b>${R.note ? `<span class="sub">${esc(R.note)}</span>` : ''}</div><div class="expres"><div class="tablewrap-x" style="overflow-x:auto"><table class="rt"><thead><tr>${cols.map(c => `<th${numCol(c) ? ' class="num"' : ''}>${esc(c.label || c.key)}${c.unit ? ` <span class="dim">(${esc(c.unit)})</span>` : ''}</th>`).join('')}</tr></thead><tbody>${(R.rows || []).map(row => `<tr class="${isBest(row) ? 'best' : ''}${row.feasible === false ? ' infeasible' : ''}">${cols.map(c => `<td${numCol(c) ? ' class="num"' : ''}>${esc(fmt(row[c.key]))}</td>`).join('')}</tr>`).join('')}</tbody></table></div></div>`;
  },
  render() {
    const el = this.el; const R = host.results;
    const list = !R ? [] : Array.isArray(R) ? R : [R];
    const bar = `<div class="toolbar"><button class="btn sm" data-act="rerun">Run again</button><span class="lbl">Each experiment compiles and runs many variants of a pipeline; the best feasible row is marked. Timings are observations from this browser.</span></div>`;
    if (!list.length) { el.innerHTML = `<div class="tabbody col">${bar}<p class="empty padded">This preset reports no experiments. A main.js that returns a Results table fills this view, for example the result of <code>g.search.grid(design, { corpus, objective })</code> or <code>g.table(rows)</code>.</p></div>`; return; }
    el.innerHTML = `<div class="tabbody col">${bar}<div class="scroll" data-scroll="exp">${list.map(r => { try { return this.table(r); } catch (e) { return failRow('This table does not render', e); } }).join('')}</div></div>`;
  },
});
