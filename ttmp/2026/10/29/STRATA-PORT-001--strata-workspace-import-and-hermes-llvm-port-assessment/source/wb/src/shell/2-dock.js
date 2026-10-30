/* Part 2: the dock (tiles, tabs, splits, drag, layouts) and the header bar. */
let tileSeq = 0;
const T = (views, active) => ({ t: 'tile', id: 't' + (++tileSeq), views: views.slice(), active: active || views[0] });
const SP = (dir, kids, sizes) => ({ t: 'split', dir, kids, sizes });
const LEFT = ['notes', 'code', 'agent', 'docs', 'book', 'reference'];
const LOWER = ['ir', 'facts', 'plan', 'machine', 'events', 'laws', 'experiments'];
const LAYOUTS = {
  'Code beside the stage': { about: 'notes, code and agent on the left; the sheet over the program views', make: () => SP('row', [T(LEFT, 'notes'), SP('col', [T(['stage']), T(LOWER, 'ir')], [0.6, 0.4])], [0.38, 0.62]) },
  'The program: IR and stage': { about: 'three columns: code, the IR and facts, the sheet over the machine', make: () => SP('row', [T(['code', 'notes', 'agent', 'docs', 'book', 'reference'], 'code'), T(['ir', 'facts', 'plan'], 'ir'), SP('col', [T(['stage']), T(['machine', 'events', 'laws', 'experiments'], 'machine')], [0.6, 0.4])], [0.3, 0.32, 0.38]) },
  'Reading the book': { about: 'the book on the left half, the sheet and the program on the right', make: () => SP('row', [T(['book', 'notes', 'docs', 'reference', 'code', 'agent'], 'book'), SP('col', [T(['stage']), T(LOWER, 'ir')], [0.6, 0.4])], [0.5, 0.5]) },
  'Experiments and laws': { about: 'code on the left; experiments and laws over the sheet and the rest', make: () => SP('row', [T(LEFT, 'code'), SP('col', [T(['experiments', 'laws'], 'experiments'), T(['stage', 'ir', 'facts', 'plan', 'machine', 'events'], 'stage')], [0.5, 0.5])], [0.36, 0.64]) },
  'Everything in one tile': { about: 'all fourteen views as tabs, Stage in front', make: () => T(['stage', ...VIEW_ORDER.filter(v => v !== 'stage')], 'stage') },
};
const DEFAULT_LAYOUT = 'Code beside the stage';
const NEAR = { code: ['notes', 'agent'], agent: ['code', 'notes'], notes: ['code', 'docs'], docs: ['notes', 'book'], book: ['docs', 'notes'], reference: ['docs', 'book'], stage: ['ir', 'facts'], ir: ['facts', 'plan', 'stage'], facts: ['ir', 'plan'], plan: ['facts', 'ir'], machine: ['events', 'ir'], events: ['machine', 'laws'], laws: ['experiments', 'events'], experiments: ['laws', 'events'] };

function normalize(node, seen, keepEmpty) {
  seen = seen || new Set();
  if (!node || typeof node !== 'object') return null;
  if (node.t === 'tile') {
    const views = (Array.isArray(node.views) ? node.views : []).filter(v => VIEWS[v] && !seen.has(v) && (seen.add(v), true));
    if (!views.length && !keepEmpty) return null;
    return { t: 'tile', id: node.id && !/^t\d+$/.test(node.id) ? node.id : 't' + (++tileSeq), views, active: views.includes(node.active) ? node.active : (views[0] || null) };
  }
  if (node.t === 'split') {
    const kids = [], sizes = [];
    (node.kids || []).forEach((k, i) => {
      const n = normalize(k, seen, keepEmpty); if (!n) return;
      const s = (node.sizes && node.sizes[i] > 0) ? node.sizes[i] : 1;
      if (n.t === 'split' && n.dir === node.dir) n.kids.forEach((kk, j) => { kids.push(kk); sizes.push(s * n.sizes[j]); });
      else { kids.push(n); sizes.push(s); }
    });
    if (!kids.length) return null;
    if (kids.length === 1) return kids[0];
    const tot = sizes.reduce((a, b) => a + b, 0);
    return { t: 'split', dir: node.dir === 'col' ? 'col' : 'row', kids, sizes: sizes.map(s => s / tot) };
  }
  return null;
}

const Views = {}; // name → { mount(el), update(what), unmount() }

const Dock = {
  tree: null, el: null, narrow: false, narrowActive: 'stage', mounted: new Map(), plusFor: null,
  init(el) {
    this.el = el;
    const saved = store.get('layout', null);
    this.tree = (saved && normalize(saved)) || LAYOUTS[DEFAULT_LAYOUT].make();
    this.layoutName = store.get('layoutName', saved ? null : DEFAULT_LAYOUT);
    this.narrow = W.innerWidth < 640;
    W.addEventListener('resize', debounce(() => { const n = W.innerWidth < 640; if (n !== this.narrow) { this.narrow = n; this.render(); } host.emit('resize'); }, 120));
    this.bindDrag();
  },
  save() { if (!this.narrow) { store.set('layout', this.tree); store.set('layoutName', this.layoutName); } },
  apply(name) { const L = LAYOUTS[name]; if (!L) return; this.tree = L.make(); this.layoutName = name; this.save(); this.render(); host.emit('layout'); },
  tiles(node, out) { node = node || this.effective(); out = out || []; if (node.t === 'tile') out.push(node); else node.kids.forEach(k => this.tiles(k, out)); return out; },
  tileOf(view) { return this.tiles().find(t => t.views.includes(view)) || null; },
  effective() {
    if (!this.narrow) return this.tree;
    if (!this._narrowTile) this._narrowTile = { t: 'tile', id: 'narrow', views: ['stage', ...VIEW_ORDER.filter(v => v !== 'stage')], active: 'stage' };
    this._narrowTile.active = this.narrowActive;
    return this._narrowTile;
  },
  visible(view) { return this.mounted.has(view); },
  focusView(view) {
    if (this.narrow) { this.narrowActive = view; this.render(); return; }
    let t = this.tileOf(view);
    if (!t) {
      t = (NEAR[view] || []).map(v => this.tileOf(v)).find(Boolean) || this.tiles()[0];
      t.views.push(view);
    }
    if (t.active !== view) { t.active = view; this.save(); this.renderTile(t); }
  },
  findParent(target, node, parent) {
    node = node || this.tree;
    if (node === target) return parent || null;
    if (node.t === 'split') for (const k of node.kids) { const r = this.findParent(target, k, node); if (r !== undefined) return r; }
    return undefined;
  },
  closeView(tile, view) {
    tile.views = tile.views.filter(v => v !== view);
    if (tile.active === view) tile.active = tile.views[0] || null;
    this.save(); this.render();
  },
  openIn(tile, view) {
    const cur = this.tileOf(view);
    if (cur && cur !== tile) { cur.views = cur.views.filter(v => v !== view); if (cur.active === view) cur.active = cur.views[0] || null; }
    if (!tile.views.includes(view)) tile.views.push(view);
    tile.active = view; this.plusFor = null;
    this.tree = normalize(this.tree, new Set(), true) || LAYOUTS[DEFAULT_LAYOUT].make();
    this.save(); this.render();
  },
  moveView(view, target, where) {
    if (this.narrow) return;
    const src = this.tileOf(view); if (!src) return;
    if (src === target && (where === 'tab' || src.views.length === 1)) { target.active = view; this.save(); this.render(); return; }
    src.views = src.views.filter(v => v !== view); if (src.active === view) src.active = src.views[0] || null;
    if (where === 'tab') { target.views.push(view); target.active = view; }
    else {
      const fresh = T([view], view);
      const dir = (where === 'left' || where === 'right') ? 'row' : 'col';
      const kids = (where === 'left' || where === 'top') ? [fresh, target] : [target, fresh];
      const split = SP(dir, kids, [0.5, 0.5]);
      const parent = this.findParent(target);
      if (!parent) this.tree = split;
      else { const i = parent.kids.indexOf(target); parent.kids[i] = split; }
    }
    this.tree = normalize(this.tree) || LAYOUTS[DEFAULT_LAYOUT].make();
    this.layoutName = null; this.save(); this.render(); host.emit('layout');
  },
  render() {
    for (const [name] of this.mounted) safe(() => Views[name] && Views[name].unmount && Views[name].unmount());
    this.mounted.clear();
    this.el.innerHTML = '';
    this.el.appendChild(this.build(this.effective()));
  },
  build(node) {
    if (node.t === 'tile') {
      const sec = document.createElement('section'); sec.className = 'tile'; sec.dataset.tile = node.id;
      sec.__node = node; this.fillTile(sec, node); return sec;
    }
    const d = document.createElement('div'); d.className = 'dsplit ' + node.dir; d.__node = node;
    node.kids.forEach((k, i) => {
      if (i) { const g = document.createElement('div'); g.className = 'gutter ' + node.dir; g.tabIndex = 0; g.setAttribute('role', 'separator'); g.dataset.i = i; g.__split = node; d.appendChild(g); }
      const c = document.createElement('div'); c.className = 'dcell'; c.style.flex = `${node.sizes[i]} 1 0`; c.appendChild(this.build(k)); d.appendChild(c);
    });
    return d;
  },
  fillTile(sec, node) {
    const closed = VIEW_ORDER.filter(v => !this.tileOf(v));
    const tabs = node.views.map(v => {
      const badge = Views[v] && Views[v].badge ? safe(() => Views[v].badge(), '') : '';
      return `<div class="dtab${v === node.active ? ' on' : ''}" data-view="${v}"><button class="lbl" role="tab" aria-selected="${v === node.active}" data-view="${v}">${VIEWS[v].title}${badge}</button><button class="x" aria-label="Close ${VIEWS[v].title}" data-close="${v}">×</button></div>`;
    }).join('');
    const plusMenu = this.plusFor === node.id ? `<div class="menu right floating-in" style="right:0;left:auto">${closed.length ? closed.map(v => `<button data-open="${v}"><span class="t">${VIEWS[v].title}</span><small>${VIEWS[v].about}</small></button>`).join('') : '<p class="note">Every view is open. Drag a tab here to move it.</p>'}</div>` : '';
    sec.innerHTML = `<div class="dstrip"><div class="dtabs" role="tablist">${tabs}</div><div class="rel"><button class="tabact plus" title="Open a view in this tile" data-plus="1">+</button>${plusMenu}</div></div><div class="tilebody"></div>`;
    const body = sec.querySelector('.tilebody');
    if (!node.active) {
      body.innerHTML = `<div class="picker"><p class="lead">An empty tile. Open a view:</p><div class="pgrid">${(closed.length ? closed : []).map(v => `<button data-open="${v}"><b>${VIEWS[v].title}</b><small>${VIEWS[v].about}</small></button>`).join('')}</div>${closed.length ? '' : '<p class="lead">Every view is open. Drag a tab here to move it.</p>'}</div>`;
    } else this.mountView(node.active, body);
    sec.onclick = ev => {
      const x = ev.target.closest('[data-close]'); if (x) { ev.stopPropagation(); this.closeView(node, x.dataset.close); return; }
      const o = ev.target.closest('[data-open]'); if (o) { this.openIn(node, o.dataset.open); return; }
      const p = ev.target.closest('[data-plus]'); if (p) { this.plusFor = this.plusFor === node.id ? null : node.id; this.renderTile(node); return; }
    };
  },
  mountView(name, body) {
    const V = Views[name];
    const host_ = document.createElement('div'); host_.className = 'viewroot'; host_.style.cssText = 'flex:1;min-height:0;display:flex;flex-direction:column;min-width:0';
    body.appendChild(host_);
    this.mounted.set(name, host_);
    if (!V) { host_.innerHTML = `<p class="empty padded">This view is not built yet.</p>`; return; }
    try { V.mount(host_); } catch (e) { console.error(e); host_.innerHTML = `<div class="fail padded"><b>${esc(VIEWS[name].title)} does not render:</b> ${esc(e.message)}</div>`; }
  },
  renderTile(node) {
    const sec = this.el.querySelector(`section.tile[data-tile="${node.id}"]`);
    if (!sec) { this.render(); return; }
    for (const v of node.views.concat(VIEW_ORDER)) if (this.mounted.has(v) && sec.contains(this.mounted.get(v))) { safe(() => Views[v].unmount && Views[v].unmount()); this.mounted.delete(v); }
    this.fillTile(sec, node);
  },
  refreshTabs() { // badges only
    for (const t of this.tiles()) {
      const sec = this.el.querySelector(`section.tile[data-tile="${t.id}"]`); if (!sec) continue;
      for (const v of t.views) { const b = sec.querySelector(`.dtab[data-view="${v}"] .lbl`); if (b && Views[v] && Views[v].badge) b.innerHTML = VIEWS[v].title + safe(() => Views[v].badge(), ''); }
    }
  },
  update(what) {
    for (const [name] of this.mounted) { const V = Views[name]; if (V && V.update) { try { V.update(what); } catch (e) { console.error(name, e); } } }
    this.refreshTabs();
  },
  bindDrag() {
    const el = this.el;
    let drag = null;
    el.addEventListener('pointerdown', ev => {
      const g = ev.target.closest('.gutter');
      if (g && ev.button === 0) {
        ev.preventDefault();
        const split = g.__split, i = +g.dataset.i, box = g.parentElement.getBoundingClientRect();
        const dir = split.dir;
        document.body.classList.add(dir === 'row' ? 'resizing-x' : 'resizing-y');
        const move = e => {
          const total = dir === 'row' ? box.width : box.height;
          const before = split.sizes.slice(0, i - 1).reduce((a, b) => a + b, 0);
          const pos = ((dir === 'row' ? e.clientX - box.left : e.clientY - box.top) / total);
          const pair = split.sizes[i - 1] + split.sizes[i];
          let a = Math.min(pair - 0.06, Math.max(0.06, pos - before));
          split.sizes[i - 1] = a; split.sizes[i] = pair - a;
          const cells = [...g.parentElement.children].filter(c => c.classList.contains('dcell'));
          cells[i - 1].style.flex = `${split.sizes[i - 1]} 1 0`; cells[i].style.flex = `${split.sizes[i]} 1 0`;
        };
        const up = () => { document.removeEventListener('pointermove', move); document.removeEventListener('pointerup', up); document.body.classList.remove('resizing-x', 'resizing-y'); this.save(); host.emit('resize'); };
        document.addEventListener('pointermove', move); document.addEventListener('pointerup', up);
        return;
      }
      const lbl = ev.target.closest('.dtab .lbl');
      if (!lbl || ev.button !== 0 || this.narrow) return;
      const view = lbl.dataset.view, tileEl = lbl.closest('section.tile'), node = tileEl.__node;
      drag = { view, node, x: ev.clientX, y: ev.clientY, started: false };
      const move = e => {
        if (!drag) return;
        if (!drag.started && Math.hypot(e.clientX - drag.x, e.clientY - drag.y) < 4) return;
        if (!drag.started) {
          drag.started = true; document.body.classList.add('dragging-view');
          drag.ghost = document.createElement('div'); drag.ghost.className = 'drag-ghost'; drag.ghost.innerHTML = `${VIEWS[view].title} <small>drop on a tile's tabs or edge</small>`; document.body.appendChild(drag.ghost);
          drag.hint = document.createElement('div'); drag.hint.className = 'drop-hint'; drag.hint.innerHTML = '<span></span>'; document.body.appendChild(drag.hint);
        }
        drag.ghost.style.left = (e.clientX + 12) + 'px'; drag.ghost.style.top = (e.clientY + 10) + 'px';
        const under = document.elementFromPoint(e.clientX, e.clientY);
        const tEl = under && under.closest('section.tile');
        drag.target = null;
        if (!tEl) { drag.hint.style.display = 'none'; return; }
        const r = tEl.getBoundingClientRect(), strip = tEl.querySelector('.dstrip').getBoundingClientRect();
        let where = 'tab';
        if (e.clientY > strip.bottom) {
          const fx = (e.clientX - r.left) / r.width, fy = (e.clientY - strip.bottom) / (r.bottom - strip.bottom);
          const m = Math.min(fx, 1 - fx, fy, 1 - fy);
          if (m < 0.22) where = m === fx ? 'left' : m === 1 - fx ? 'right' : m === fy ? 'top' : 'bottom';
        }
        drag.target = { node: tEl.__node, where };
        const box = { left: r.left, top: r.top, width: r.width, height: r.height };
        if (where === 'left') box.width = r.width / 2; else if (where === 'right') { box.left = r.left + r.width / 2; box.width = r.width / 2; }
        else if (where === 'top') { box.height = r.height / 2; } else if (where === 'bottom') { box.top = r.top + r.height / 2; box.height = r.height / 2; }
        Object.assign(drag.hint.style, { display: 'grid', left: box.left + 'px', top: box.top + 'px', width: box.width + 'px', height: box.height + 'px' });
        drag.hint.querySelector('span').textContent = where === 'tab' ? 'add as a tab' : `split: ${where}`;
      };
      const up = () => {
        document.removeEventListener('pointermove', move); document.removeEventListener('pointerup', up);
        const d = drag; drag = null;
        if (!d) return;
        if (d.ghost) d.ghost.remove(); if (d.hint) d.hint.remove(); document.body.classList.remove('dragging-view');
        if (!d.started) { if (d.node.active !== d.view) { d.node.active = d.view; this.save(); this.renderTile(d.node); } return; }
        if (d.target) this.moveView(d.view, d.target.node, d.target.where);
      };
      document.addEventListener('pointermove', move); document.addEventListener('pointerup', up);
    });
  },
};

/* ---------- the header bar ---------- */
const THEME_ICON = {
  system: '<svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.4"><circle cx="8" cy="8" r="6"/><path d="M8 2a6 6 0 0 1 0 12z" fill="currentColor"/></svg>',
  light: '<svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.4"><circle cx="8" cy="8" r="3"/><path d="M8 1v2M8 13v2M1 8h2M13 8h2M3 3l1.4 1.4M11.6 11.6L13 13M3 13l1.4-1.4M11.6 4.4L13 3"/></svg>',
  dark: '<svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.4"><path d="M13 9.5A5.5 5.5 0 0 1 6.5 3a5.5 5.5 0 1 0 6.5 6.5z"/></svg>',
};
const Theme = {
  mq: W.matchMedia ? W.matchMedia('(prefers-color-scheme: dark)') : null,
  apply() {
    const t = host.ui.theme;
    const resolved = t === 'system' ? (this.mq && this.mq.matches ? 'dark' : 'light') : t;
    document.documentElement.setAttribute('data-theme', resolved);
  },
  cycle() { const order = ['system', 'light', 'dark']; host.ui.theme = order[(order.indexOf(host.ui.theme) + 1) % 3]; store.set('theme', host.ui.theme); this.apply(); Header.render(); host.emit('theme'); },
  init() { this.apply(); if (this.mq && this.mq.addEventListener) this.mq.addEventListener('change', () => { if (host.ui.theme === 'system') { this.apply(); host.emit('theme'); } }); },
};

const Header = {
  el: null,
  init(el) {
    this.el = el;
    el.addEventListener('click', ev => this.click(ev));
    el.addEventListener('change', ev => {
      if (ev.target.matches('select.fnsel')) host.setFn(ev.target.value);
    });
    el.addEventListener('keydown', ev => {
      if (ev.target.matches('.newfile input') && ev.key === 'Enter') { ev.preventDefault(); this.saveAs(); }
    });
    el.addEventListener('input', ev => { if (ev.target.matches('.newfile input')) host.ui.saveTitle = ev.target.value; });
    document.addEventListener('pointerdown', ev => {
      if (host.ui.menu && !ev.target.closest('.menu') && !ev.target.closest('[data-menu]')) { host.ui.menu = null; this.render(); }
      if (Dock.plusFor && !ev.target.closest('.dstrip .rel')) { const t = Dock.tiles().find(x => x.id === Dock.plusFor); Dock.plusFor = null; if (t) Dock.renderTile(t); }
    });
  },
  async saveAs() {
    const title = (host.ui.saveTitle || '').trim();
    host.ui.menu = null; host.ui.saveTitle = '';
    try { await host.saveAs(title); } catch (e) { host.toast('Save failed: ' + e.message, true); }
    this.render();
  },
  click(ev) {
    const b = ev.target.closest('[data-act]'); if (!b) return;
    const a = b.dataset.act, arg = b.dataset.arg;
    if (a === 'menu') { host.ui.menu = host.ui.menu === arg ? null : arg; this.render(); const inp = this.el.querySelector('.newfile input'); if (inp && arg === 'presets') { /* keep focus free */ } return; }
    if (a === 'preset') { host.ui.menu = null; host.loadPreset(arg); return; }
    if (a === 'build') { host.build(); return; }
    if (a === 'mode') { host.setMode(arg); return; }
    if (a === 'gc') { host.setGC(arg); return; }
    if (a === 'theme') { Theme.cycle(); return; }
    if (a === 'layout') { host.ui.menu = null; Dock.apply(arg); this.render(); return; }
    if (a === 'saveas') { this.saveAs(); return; }
    if (a === 'saveown') { host.ui.menu = null; host.saveOwn().catch(e => host.toast('Save failed: ' + e.message, true)); return; }
    if (a === 'revert') { host.ui.menu = null; host.revertAll(); return; }
    if (a === 'delete') { host.ui.menu = null; const id = host.preset && host.preset.id; Presets.remove(id).then(() => { host.toast(`Removed ${id}`); host.loadPreset((Presets.builtins[0] || {}).id); }).catch(e => host.toast(e.message, true)); return; }
    if (a === 'pill') { host.focus(arg); return; }
  },
  presetMenu() {
    const all = Presets.all(), cur = host.preset && host.preset.id;
    let h = '<div class="menu presets">';
    for (const g of GROUP_ORDER) {
      const ps = all.filter(p => groupOf(p) === g);
      if (!ps.length) continue;
      h += `<div class="grp">${esc(GROUPS[g])}</div>`;
      for (const p of ps) h += `<button class="${p.id === cur ? 'on' : ''}" data-act="preset" data-arg="${esc(p.id)}"><span class="code">${esc(p.id)}</span><span class="t">${esc(p.title)}</span><small>${esc(p.about || '')}</small></button>`;
    }
    if (!all.length) h += '<p class="note">No presets are loaded. Build the content with tools/build-content.js.</p>';
    h += '<hr>';
    const own = cur && Presets.isOwn(cur);
    h += `<div class="newfile"><input placeholder="save as my preset: title" value="${esc(host.ui.saveTitle || '')}" aria-label="Title for the new preset"><button class="btn sm" data-act="saveas">Save as</button></div>`;
    if (own) h += `<button data-act="saveown"${host.edited() ? '' : ' disabled'}><span class="t">Save changes to ${esc(cur)}</span><small>writes the files and notes to ${esc(Presets.where())}</small></button>`;
    h += `<button data-act="revert"${host.edited() ? '' : ' disabled'}><span class="t">Revert all edits</span><small>back to ${esc(cur || 'the preset')} as ${own ? 'last saved' : 'published'}</small></button>`;
    if (own) h += `<button class="danger" data-act="delete"><span class="t">Delete ${esc(cur)}</span><small>removes your saved preset</small></button>`;
    h += `<p class="store-note">Your own presets (U-…) are kept in ${Presets.dbState === 'on' ? 'the shared store of this page' : Presets.dbState === 'pending' ? 'this browser until the shared store answers' : 'this browser: the shared store is not available here'}.</p>`;
    return h + '</div>';
  },
  layoutMenu() {
    let h = '<div class="menu right layouts">';
    for (const [name, L] of Object.entries(LAYOUTS)) h += `<button data-act="layout" data-arg="${esc(name)}"><span class="t"><i class="radio${Dock.layoutName === name ? ' on' : ''}" style="display:inline-block;margin-right:8px"></i>${esc(name)}</span></button>`;
    return h + '<p class="note">Drag a tab to move it; drop it on a tile\'s edge to split. The layout is kept in this browser.</p></div>';
  },
  render() {
    if (!this.el) return;
    const p = host.preset || {};
    const bi = host.buildInfo;
    const fns = host.program ? safe(() => host.program.functions(), []) : [];
    const sm = host.program ? safe(() => host.program.summary(), null) : null;
    const c = sm && sm.counts;
    let pillB = 'none', pillS = 'main.js has not run', bad = false;
    if (host.busy) { pillB = 'running'; pillS = 'main.js'; }
    else if (bi && !bi.ok) { pillB = 'fails'; pillS = cut(bi.message || '', 60); bad = true; }
    else if (bi && bi.ok) {
      const errs = host.diagList().filter(d => d.severity === 'error').length;
      if (errs) { pillB = plural(errs, 'error'); bad = true; pillS = c ? `${plural(c.functions, 'function')} · ${plural(c.blocks, 'block')}` : bi.kind; }
      else { pillB = 'ok'; pillS = c ? `${plural(c.functions, 'function')} · ${plural(c.blocks, 'block')} · ${plural(c.ops, 'op')}` : `returned ${bi.kind}`; }
    }
    const r = host.run;
    let outB = '—', outS = 'no run', outBad = false;
    if (r && r.outcome) {
      const k = r.outcome.kind, v = r.outcome.value;
      outB = k + (v !== undefined && k !== 'error' ? ' ' + cut(yaml1(v), 18) : '');
      outBad = k === 'throw' || k === 'error' || (r.events || []).some(e => e.type === 'stale');
      outS = `${r.mode || host.mode} · ${fmtInt(r.steps)} steps${(r.metrics || {}).collections ? ' · ' + plural(r.metrics.collections, 'collection') : ''}`;
    }
    const m = host.ui.menu;
    this.el.innerHTML = `
<div class="brand">Strata <i>workbench</i></div>
<div class="proj rel"><button class="projbtn" data-act="menu" data-arg="presets" data-menu="1" title="Open another preset"><span class="pcode">${esc(p.id || '')}</span><span class="ptitle">${esc(p.title || 'No preset')}</span>${host.edited() ? '<span class="pcode">edited</span>' : ''}<span class="caret">▾</span></button>${m === 'presets' ? this.presetMenu() : ''}</div>
<button class="btn${host.edited() ? ' primary' : ''}" data-act="build" title="Run main.js again (Ctrl+Enter)">Run<span class="long"> <kbd>⌘↵</kbd></span></button>
<div class="runset modeset"><span class="ctl-l">Mode</span><div class="seg sm" role="group" aria-label="Run mode">${['spec', 'plan', 'wasm'].map(x => `<button class="${host.mode === x ? 'on' : ''}" aria-pressed="${host.mode === x}" data-act="mode" data-arg="${x}" title="${{ spec: 'the reference interpreter on L1', plan: 'the L3 executor with the simulated moving collector', wasm: 'WebAssembly for the functions the backend accepts' }[x]}">${{ spec: 'Spec', plan: 'Plan', wasm: 'Wasm' }[x]}</button>`).join('')}</div></div>
<div class="runset gcset"><span class="ctl-l">GC</span><div class="seg sm" role="group" aria-label="Garbage collection">${['off', 'alloc', 'stress'].map(x => `<button class="${host.gc === x ? 'on' : ''}" aria-pressed="${host.gc === x}" data-act="gc" data-arg="${x}" title="${{ off: 'never collect', alloc: 'collect when allocation passes a budget (Plan mode)', stress: 'collect at every safepoint (Plan mode)' }[x]}">${{ off: 'Off', alloc: 'Alloc', stress: 'Stress' }[x]}</button>`).join('')}</div></div>
${fns.length ? `<select class="fnsel" aria-label="Function on the stage" title="The function on the stage">${fns.map(f => `<option${f === host.fn ? ' selected' : ''}>${esc(f)}</option>`).join('')}</select>` : ''}
<span class="sp"></span>
<button class="pill${bad ? ' bad' : ''}${host.busy ? ' busy' : ''}" data-act="pill" data-arg="${bad ? 'code' : 'events'}" title="${esc('Build status: ' + pillB + (pillS ? ' · ' + pillS : ''))}"><b>${esc(pillB)}</b><span>${esc(pillS)}</span></button>
<button class="pill out${outBad ? ' bad' : ''}" data-act="pill" data-arg="machine" title="The last run of the program"><b>${esc(outB)}</b><span>${esc(outS)}</span></button>
<div class="rel laymenu"><button class="btn" data-act="menu" data-arg="layout" data-menu="1">Layout ▾</button>${m === 'layout' ? this.layoutMenu() : ''}</div>
<button class="ibtn themebtn" data-act="theme" title="Theme: ${host.ui.theme} (click for ${{ system: 'light', light: 'dark', dark: 'system' }[host.ui.theme]})">${THEME_ICON[host.ui.theme]}</button>`;
    const inp = this.el.querySelector('.newfile input');
    if (inp && m === 'presets' && host.ui.saveTitle) { inp.focus(); inp.setSelectionRange(inp.value.length, inp.value.length); }
  },
};
const cut = (s, n) => (s = String(s == null ? '' : s), s.length > n ? s.slice(0, n - 1) + '…' : s);
