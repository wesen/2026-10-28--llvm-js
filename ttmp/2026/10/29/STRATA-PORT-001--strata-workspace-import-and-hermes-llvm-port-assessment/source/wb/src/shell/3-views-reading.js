/* Part 3a: shared view helpers, Notes, Code, Docs, Book, Reference, Agent (mount point). */
const view = (name, def) => { Views[name] = def; return def; };
const keepScroll = (el, fn) => {
  const sc = [...el.querySelectorAll('[data-scroll]')].map(s => [s.dataset.scroll, s.scrollTop, s.scrollLeft]);
  fn();
  for (const [k, t, l] of sc) { const s = el.querySelector(`[data-scroll="${k}"]`); if (s) { s.scrollTop = t; s.scrollLeft = l; } }
};
const scrollToAnchor = (el, id) => {
  if (!id) return false;
  let t = null;
  try { t = el.querySelector('#' + CSS.escape(id)); } catch (e) { t = null; }
  if (!t) t = [...el.querySelectorAll('[id]')].find(x => x.id.endsWith('-' + id) || x.id === id);
  if (t) { t.scrollIntoView({ block: 'start' }); return true; }
  return false;
};
const bindLab = el => el.addEventListener('click', ev => {
  const a = ev.target.closest('a.lablink'); if (a) { ev.preventDefault(); host.link(a.dataset.lab); return; }
  const an = ev.target.closest('a[data-anchor]'); if (an) { ev.preventDefault(); scrollToAnchor(el, an.dataset.anchor); }
});
const failRow = (what, e) => `<div class="fail viewfail"><b>${esc(what)}:</b> ${esc(e && e.message || String(e))}</div>`;
const noProgram = () => {
  if (host.buildInfo && !host.buildInfo.ok) return `<div class="padded"><div class="fail"><b>main.js does not run:</b> ${esc(host.buildInfo.message || '')}${host.buildInfo.line ? ` (line ${host.buildInfo.line})` : ''}. Fix it in Code and press Run.</div></div>`;
  if (host.program) {
    const errs = safe(() => (host.program.diagnostics || []).filter(d => d.severity === 'error'), []);
    return `<div class="padded"><div class="fail"><b>The program has no functions.</b> ${errs.length ? `Compiling stopped at ${plural(errs.length, 'error')}: ${esc(cut(errs[0].message || '', 220))}` : 'main.js returned a program without any function to show.'} <a href="#" class="lablink" data-lab="lab:show?view=events">See Events</a></div></div>`;
  }
  if (host.buildInfo && host.buildInfo.ok) return `<p class="empty padded">main.js returned ${esc(host.buildInfo.kind || 'nothing')}, not a program, so there is no graph to show. Return one with <code>return g.compile(g.pipeline(), source())</code>, or an object <code>{ program, … }</code>.</p>`;
  return `<p class="empty padded">No program yet. A preset's main.js returns one, for example <code>return g.compile(g.pipeline(), source())</code>. Press Run.</p>`;
};
const fnSelect = () => {
  const fns = host.program ? safe(() => host.program.functions(), []) : [];
  return fns.length ? `<select class="fnsel" data-fn="1" aria-label="Function">${fns.map(f => `<option${f === host.fn ? ' selected' : ''}>${esc(f)}</option>`).join('')}</select>` : '';
};
const bindFn = el => el.addEventListener('change', ev => { if (ev.target.matches('select[data-fn]')) host.setFn(ev.target.value); });
const chapterLabel = n => /^\d+$/.test(String(n)) ? `Chapter ${n}` : String(n) === 'P' ? 'Front matter' : `Appendix ${n}`;
async function copyText(text, what) {
  try { await navigator.clipboard.writeText(text); host.toast('Copied' + (what ? ' ' + what : '')); }
  catch (e) { host.toast('Copying is not available here: the clipboard refused it', true); }
}

/* ---------- Notes ---------- */
view('notes', {
  editing: false,
  mount(el) {
    this.el = el; this.render();
    el.addEventListener('click', ev => {
      const b = ev.target.closest('[data-act]'); if (!b) return;
      const a = b.dataset.act;
      if (a === 'edit') { this.editing = !this.editing; this.render(); }
      else if (a === 'save') { const ta = el.querySelector('textarea[data-notes]'); host.setNotes(ta.value); this.editing = false; this.render(); host.toast('Saved the notes in this browser'); }
      else if (a === 'cancel') { this.editing = false; this.render(); }
    });
    bindLab(el);
  },
  update(w) { if (!this.editing && (w === 'preset' || w === 'notes')) this.render(); },
  unmount() { /* keep edit state */ },
  related(p) {
    const B = C.book || { chapters: [] }, D = C.docs || [];
    const chs = (p.chapters || []).map(n => B.chapters.find(c => String(c.n) === String(n))).filter(Boolean);
    const ds = (p.docs || []).map(id => D.find(d => d.id === id)).filter(Boolean);
    if (!chs.length && !ds.length) return '';
    return `<div class="doc related"><h4>Further reading</h4><ul>${chs.map(c => `<li><a href="#" class="lablink" data-lab="lab:book?ch=${esc(c.n)}">${esc(chapterLabel(c.n))} ${esc(c.title)}</a></li>`).join('')}${ds.map(d => `<li><a href="#" class="lablink" data-lab="lab:doc?id=${esc(d.id)}">${esc(d.title)}</a> <span class="dim">${esc(d.about || '')}</span></li>`).join('')}</ul></div>`;
  },
  render() {
    const p = host.preset, el = this.el;
    if (!p) { el.innerHTML = '<p class="empty padded">No preset is loaded. Open one from the preset menu in the header.</p>'; return; }
    const tb = `<div class="toolbar"><span class="ntitle"><span class="pcode">${esc(p.id)}</span> <b>${esc(p.title)}</b> · ${esc(p.group || GROUPS[groupOf(p)])}</span><span class="sp"></span><button class="tog${this.editing ? ' on' : ''}" data-act="edit" title="Edit the notes as Markdown">Edit</button></div>`;
    if (this.editing) {
      el.innerHTML = `<div class="tabbody col notes">${tb}<div class="notes-edit"><textarea data-notes spellcheck="true" aria-label="Notes as Markdown">${esc(host.notes)}</textarea><div class="ed-foot"><span>Markdown, rendered like the book. Saved edits are kept in this browser until you save the preset.</span><span class="sp"></span><button class="btn sm primary" data-act="save">Save notes</button><button class="btn sm" data-act="cancel">Cancel</button></div></div></div>`;
      return;
    }
    keepScroll(el, () => {
      el.innerHTML = `<div class="tabbody col notes">${tb}<div class="scroll" data-scroll="notes">${host.notes && host.notes.trim() ? `<div class="doc">${MD.render(host.notes, { prefix: 'n-', toc: true })}</div>` : '<p class="empty padded">This preset has no notes yet. Press Edit to write them.</p>'}${this.related(p)}</div></div>`;
    });
  },
});

/* ---------- Code ---------- */
view('code', {
  typing: false, menu: false,
  mount(el) {
    this.el = el;
    el.innerHTML = `<div class="tabbody col codeview"><div class="toolbar filebar"></div><div class="ed"><div class="egutter"><div class="gutter-in"></div></div><div class="code"><pre aria-hidden="true"></pre><textarea spellcheck="false" autocapitalize="off" autocomplete="off" autocorrect="off" wrap="off" aria-label="File contents"></textarea></div></div><div class="ed-foot"></div><div class="diags" hidden></div></div>`;
    const ta = el.querySelector('textarea'), pre = el.querySelector('.code pre'), gut = el.querySelector('.gutter-in');
    this.ta = ta; this.pre = pre; this.gut = gut;
    ta.addEventListener('input', () => {
      this.typing = true;
      const f = host.openFile;
      host.files[f] = ta.value; host.saveEdits(); this.paint(); Header.render();
      host.emit('typing');
    });
    ta.addEventListener('blur', () => { this.typing = false; });
    ta.addEventListener('scroll', () => this.sync());
    ta.addEventListener('keydown', ev => {
      if (ev.key === 'Tab' && !ev.shiftKey && !ev.ctrlKey && !ev.metaKey) {
        ev.preventDefault();
        const s = ta.selectionStart, e = ta.selectionEnd;
        ta.setRangeText('  ', s, e, 'end'); ta.dispatchEvent(new Event('input'));
      }
    });
    el.addEventListener('click', ev => {
      const b = ev.target.closest('[data-act]'); if (!b) return;
      const a = b.dataset.act, arg = b.dataset.arg;
      if (a === 'file') { host.openFile = arg; this.menu = false; this.render(); }
      else if (a === 'run') host.build();
      else if (a === 'files') { this.menu = !this.menu; this.renderBar(); }
      else if (a === 'newfile') this.newFile();
      else if (a === 'delfile') { try { host.deleteFile(arg); this.menu = false; this.render(); host.toast(`Deleted ${arg} (Revert all edits brings it back)`); } catch (e) { host.toast(e.message, true); } }
      else if (a === 'jump') this.jump(+arg);
      else if (a === 'diag') { const d = host.diagList()[+arg]; if (!d || !d.at) return; if (d.at.file) host.openFile_(d.at.file, { line: d.at.line }); else if (d.at.fn) { host.select(d.at.op != null ? `${d.at.fn}/${d.at.block}/${d.at.op}` : d.at.block ? `${d.at.fn}/${d.at.block}` : d.at.fn); host.focus('stage'); } }
    });
    el.addEventListener('keydown', ev => { if (ev.target.matches('.newfile input') && ev.key === 'Enter') { ev.preventDefault(); this.newFile(); } });
    document.addEventListener('pointerdown', this._outside = ev => { if (this.menu && !ev.target.closest('.codeview .rel')) { this.menu = false; this.renderBar(); } });
    this.render();
  },
  unmount() { document.removeEventListener('pointerdown', this._outside); },
  newFile() {
    const inp = this.el.querySelector('.newfile input'); const name = (inp && inp.value || '').trim();
    if (!name) return;
    if (host.files[name] != null) { host.toast(`${name} exists already`, true); return; }
    try { host.setFile(name, ''); host.openFile = name; this.menu = false; this.render(); this.ta.focus(); } catch (e) { host.toast(e.message, true); }
  },
  update(w) {
    if (w === 'open' || w === 'preset') { this.render(); return; }
    if (w === 'files' && !this.typing) { this.render(); return; }
    if (w === 'build' || w === 'busy' || w === 'typing' || w === 'files' || w === 'presets') { this.renderBar(); this.renderFoot(); if (w === 'build') this.paint(); }
  },
  badge() { const n = host.diagList().filter(d => d.severity === 'error').length; return n ? ` <span class="count bad">${n}</span>` : ''; },
  order() { const fs = Object.keys(host.files); return ['main.js'].concat(fs.filter(f => f !== 'main.js').sort()); },
  renderBar() {
    const bar = this.el.querySelector('.filebar'); if (!bar) return;
    const cur = host.openFile;
    const tabs = this.order().map(f => `<span class="ftab${f === cur ? ' on' : ''}"><button data-act="file" data-arg="${esc(f)}" title="${esc(f)}">${esc(f)}${host.isDirty(f) ? ' •' : ''}</button></span>`).join('');
    const menu = this.menu ? `<div class="menu right files">${this.order().map(f => `<button data-act="file" data-arg="${esc(f)}"><span class="t">${esc(f)}</span><small>${(host.files[f] || '').split('\n').length} lines${host.isDirty(f) ? ' · edited' : ''}</small></button>`).join('')}<hr><div class="newfile"><input placeholder="new file, e.g. helper.js" aria-label="New file name"><button class="btn sm" data-act="newfile">Add</button></div>${cur !== 'main.js' ? `<button class="danger" data-act="delfile" data-arg="${esc(cur)}"><span class="t">Delete ${esc(cur)}</span><small>removes it from this preset's files</small></button>` : ''}</div>` : '';
    bar.innerHTML = `<div class="filetabs">${tabs}</div><span class="sp"></span><div class="rel"><button class="btn sm" data-act="files" data-menu="1">Files ▾</button>${menu}</div><button class="btn sm${host.edited() ? ' primary' : ''}" data-act="run" title="Run main.js again (Ctrl+Enter)">Run</button>`;
  },
  paint() {
    const f = host.openFile, src = host.files[f] == null ? '' : host.files[f];
    const lang = /\.js$/.test(f) ? 'js' : /\.(ir|core)$/.test(f) ? 'ir' : 'text';
    const lines = MD.highlightLines(src, lang);
    const bi = host.buildInfo;
    const errLine = bi && !bi.ok && bi.line && f === 'main.js' ? bi.line : null;
    const diagLines = new Set(host.diagList().filter(d => d.at && d.at.file === f && d.at.line).map(d => d.at.line));
    this.pre.innerHTML = lines.map((l, i) => `<div>${(i + 1 === errLine || diagLines.has(i + 1)) ? `<span class="ln-err">${l || ' '}</span>` : (l || ' ')}</div>`).join('');
    this.gut.innerHTML = lines.map((l, i) => `<div class="${i + 1 === errLine || diagLines.has(i + 1) ? 'err' : ''}">${i + 1}</div>`).join('');
    this.sync();
  },
  sync() { const ta = this.ta; this.pre.style.transform = `translate(${-ta.scrollLeft}px, ${-ta.scrollTop}px)`; this.gut.style.transform = `translateY(${-ta.scrollTop}px)`; },
  renderFoot() {
    const foot = this.el.querySelector('.ed-foot'), dg = this.el.querySelector('.diags');
    const bi = host.buildInfo;
    let h;
    if (host.busy) h = 'running main.js…';
    else if (!bi) h = 'main.js runs with <b>g</b>, the units, <b>files</b> and <b>source()</b> in scope. Press Run (Ctrl+Enter).';
    else if (!bi.ok) h = `<span class="bad">main.js does not run:</span> ${esc(bi.message || '')}${bi.line ? ` <button class="link bad" data-act="jump" data-arg="${bi.line}">line ${bi.line}</button>` : ''}. Fix it and press Run.`;
    else h = `ran in <b>${bi.ms != null ? (Math.round(bi.ms * 10) / 10) + ' ms' : '—'}</b> · returned <b>${esc(bi.kind)}</b>${host.logs.length ? ` · ${plural(host.logs.length, 'log line')} in Events` : ''}`;
    foot.innerHTML = h;
    const ds = host.diagList();
    if (!ds.length || (ds.length === 1 && bi && !bi.ok)) { dg.hidden = true; dg.innerHTML = ''; return; }
    dg.hidden = false;
    dg.innerHTML = ds.map((d, i) => {
      const at = d.at || {}, where = at.file ? `${at.file}${at.line ? ':' + at.line : ''}` : at.fn ? `${at.fn}${at.block ? '/' + at.block : ''}${at.op != null ? '/' + at.op : ''}` : '';
      return `<button class="diag${d.severity === 'error' ? ' bad' : ''}" data-act="diag" data-arg="${i}"><b>${d.severity === 'error' ? '×' : d.severity === 'warning' ? '!' : 'i'}</b><span class="ln">${esc(where)}</span><span>${esc(d.message)}</span></button>`;
    }).join('');
  },
  jump(line) {
    const ta = this.ta, L = ta.value.split('\n'); line = Math.max(1, Math.min(L.length, line || 1));
    const pos = L.slice(0, line - 1).reduce((s, l) => s + l.length + 1, 0);
    ta.focus(); ta.setSelectionRange(pos, pos + (L[line - 1] || '').length);
    ta.scrollTop = Math.max(0, (line - 4) * 18);
    this.sync();
  },
  render() {
    if (host.files[host.openFile] == null) host.openFile = 'main.js';
    this.renderBar();
    const src = host.files[host.openFile] == null ? '' : host.files[host.openFile];
    if (this.ta.value !== src) this.ta.value = src;
    this.paint(); this.renderFoot();
    if (host.codeJump && host.codeJump.file === host.openFile) { const l = host.codeJump.line; host.codeJump = null; setTimeout(() => this.jump(l), 0); }
  },
});

/* ---------- Docs ---------- */
view('docs', {
  q: '',
  mount(el) {
    this.el = el; this.render();
    el.addEventListener('click', ev => { const b = ev.target.closest('[data-doc]'); if (b) { host.docId = b.dataset.doc; host.docAt = null; this.render(); const sc = el.querySelector('[data-scroll="doc"]'); if (sc) sc.scrollTop = 0; } });
    el.addEventListener('input', ev => { if (ev.target.matches('.shelf .filter')) { this.q = ev.target.value; this.renderShelf(); } });
    bindLab(el);
  },
  update(w) { if (w === 'doc') this.render(); },
  list() {
    const D = (C.docs || []).slice().sort((a, b) => (+a.order || 0) - (+b.order || 0));
    if (!this.q) return D;
    const q = this.q.toLowerCase();
    return D.filter(d => (d.title + ' ' + (d.about || '') + ' ' + MD.plainText(d.md)).toLowerCase().includes(q));
  },
  renderShelf() {
    const sh = this.el.querySelector('.shelf .items'); if (!sh) return;
    const D = this.list(); const groups = [];
    for (const d of D) { const g = d.group || 'Topics'; if (!groups.includes(g)) groups.push(g); }
    sh.innerHTML = D.length ? groups.map(g => `<div class="grp">${esc(g)}</div>` + D.filter(d => (d.group || 'Topics') === g).map(d => `<button class="${d.id === host.docId ? 'on' : ''}" data-doc="${esc(d.id)}"><b>${esc(d.title)}</b><small>${esc(d.about || '')}</small></button>`).join('')).join('') : '<p class="empty padded">Nothing on the shelf matches.</p>';
  },
  render() {
    const el = this.el, D = (C.docs || []);
    if (!D.length) { el.innerHTML = '<p class="empty padded">The shelf is empty. Docs come from content-src/docs, built with tools/build-content.js.</p>'; return; }
    if (!host.docId || !D.find(d => d.id === host.docId)) host.docId = (D.slice().sort((a, b) => (+a.order || 0) - (+b.order || 0))[0] || {}).id;
    const d = D.find(x => x.id === host.docId);
    el.innerHTML = `<div class="tabbody col"><div class="docsview"><nav class="shelf"><input class="filter" placeholder="search the shelf" value="${esc(this.q)}" aria-label="Search the shelf"><div class="items"></div></nav><div class="scroll" data-scroll="doc"><div class="doc">${MD.render(d.md, { prefix: 'd-', toc: true })}</div></div></div></div>`;
    this.renderShelf();
    if (host.docAt) { const at = host.docAt; host.docAt = null; setTimeout(() => scrollToAnchor(el, 'd-' + at) || scrollToAnchor(el, at), 0); }
  },
});

/* ---------- Book ---------- */
view('book', {
  q: '', open: false, menu: false,
  mount(el) {
    this.el = el; this.render();
    el.addEventListener('click', ev => {
      const ch = ev.target.closest('[data-ch]'); if (ch) { host.bookCh = ch.dataset.ch; host.bookAt = ch.dataset.at || null; this.open = false; this.render(true); return; }
      const b = ev.target.closest('[data-act]'); if (!b) return;
      const a = b.dataset.act;
      if (a === 'contents') { this.open = !this.open; this.render(); }
      else if (a === 'scrim') { this.open = false; this.render(); }
      else if (a === 'prev' || a === 'next') { const chs = this.chapters(), i = chs.findIndex(c => String(c.n) === String(host.bookCh)); const j = i + (a === 'prev' ? -1 : 1); if (chs[j]) { host.bookCh = String(chs[j].n); host.bookAt = null; this.render(true); } }
      else if (a === 'export') { this.menu = !this.menu; this.render(); }
      else if (a === 'copych') { this.menu = false; const c = this.current(); if (c) copyText(c.md, chapterLabel(c.n).toLowerCase() + ' as Markdown'); this.render(); }
      else if (a === 'copybook') { this.menu = false; copyText(this.chapters().map(c => c.md).join('\n\n---\n\n'), 'the book as Markdown'); this.render(); }
    });
    el.addEventListener('input', ev => { if (ev.target.matches('.bcontents .filter')) { this.q = ev.target.value; this.renderContents(); } });
    document.addEventListener('pointerdown', this._outside = ev => { if (this.menu && !ev.target.closest('.bmain .rel')) { this.menu = false; this.render(); } });
    bindLab(el);
  },
  unmount() { document.removeEventListener('pointerdown', this._outside); },
  update(w) { if (w === 'book') this.render(true); },
  chapters() { return ((C.book && C.book.chapters) || []); },
  current() { const chs = this.chapters(); return chs.find(c => String(c.n) === String(host.bookCh)) || chs[0] || null; },
  renderContents() {
    const box = this.el.querySelector('.bcontents .items'); if (!box) return;
    const B = C.book || {}, chs = this.chapters(), cur = this.current();
    if (this.q.trim().length > 1) {
      const q = this.q.toLowerCase();
      const hits = chs.map(c => { const t = MD.plainText(c.md); const low = t.toLowerCase(); const n = low.split(q).length - 1; const i = low.indexOf(q); return { c, n, snip: i < 0 ? '' : t.slice(Math.max(0, i - 50), i + 70).replace(/\s+/g, ' ') }; }).filter(x => x.n).sort((a, b) => b.n - a.n);
      box.innerHTML = `<div class="bresults">${hits.length ? hits.map(h => `<button data-ch="${esc(h.c.n)}"><span class="bn">${esc(h.c.n)}</span><span><span class="bt">${esc(h.c.title)}</span><em>${plural(h.n, 'hit')}</em><small>…${esc(h.snip)}…</small></span></button>`).join('') : '<p class="empty">No chapter mentions that.</p>'}</div>`;
      return;
    }
    const parts = B.parts || [];
    let h = '';
    const seen = new Set();
    for (const c of chs) {
      if (c.part && !seen.has(c.part)) { seen.add(c.part); const p = parts.find(x => x.id === c.part); h += `<div class="grp">${p ? esc(`${p.id} ${p.title}`) : esc(c.part)}</div>`; }
      else if (!c.part && !seen.has('_front')) { seen.add('_front'); h += '<div class="grp">Front matter</div>'; }
      const written = c.md && c.md.trim();
      h += `<button class="${cur && c.n === cur.n ? 'on' : ''}${written ? '' : ' draft'}" data-ch="${esc(c.n)}"><span class="bn">${esc(c.n)}</span><span class="bt">${esc(c.title)}</span></button>`;
    }
    box.innerHTML = h;
  },
  render(toTop) {
    const el = this.el, B = C.book, chs = this.chapters();
    if (!B || !chs.length) { el.innerHTML = '<p class="empty padded">The book is not loaded. Chapters come from content-src/book, built with tools/build-content.js.</p>'; return; }
    const cur = this.current(); host.bookCh = String(cur.n);
    const i = chs.indexOf(cur), prev = chs[i - 1], next = chs[i + 1];
    const parts = B.parts || [];
    const part = cur.part && parts.find(p => p.id === cur.part);
    const firstOfPart = part && (i === 0 || chs[i - 1].part !== cur.part);
    const written = cur.md && cur.md.trim();
    const menu = this.menu ? `<div class="menu right bexport"><button data-act="copych"><span class="t">Copy this chapter</span><small>its Markdown, to paste elsewhere</small></button><button data-act="copybook"><span class="t">Copy the whole book</span><small>every chapter as one Markdown text</small></button><p class="note">Links that drive the workbench become plain text outside it.</p></div>` : '';
    const html = `<div class="tabbody col"><div class="bookview">
<nav class="bcontents${this.open ? ' open' : ''}"><div class="btitle"><b>${esc(B.title || 'Compilers from First Principles')}</b>${B.subtitle ? `<small>${esc(B.subtitle)}</small>` : ''}</div><input class="filter" placeholder="search the book" value="${esc(this.q)}" aria-label="Search the book"><div class="items"></div></nav>
${this.open ? '<div class="bscrim" data-act="scrim"></div>' : ''}
<div class="bmain"><div class="toolbar"><button class="btn sm bcbtn" data-act="contents">Contents</button><span class="ntitle"><span class="pcode">${esc(chapterLabel(cur.n))}</span> <b>${esc(cur.title)}</b></span><span class="sp"></span><button class="ibtn" data-act="prev" title="Previous chapter"${prev ? '' : ' disabled'}>‹</button><button class="ibtn" data-act="next" title="Next chapter"${next ? '' : ' disabled'}>›</button><div class="rel"><button class="btn sm" data-act="export" data-menu="1">Export ▾</button>${menu}</div></div>
<div class="scroll" data-scroll="book">
${firstOfPart ? `<div class="doc bpartopen"><span class="lbl">Part ${esc(part.id)}</span><h2>${esc(part.title)}</h2>${part.about ? `<p>${MD.inline(part.about)}</p>` : ''}</div>` : ''}
<div class="doc bchlabel">${esc(chapterLabel(cur.n))}${cur.about ? '' : ''}</div>
<div class="doc">${written ? MD.render(cur.md, { prefix: 'b-', toc: true }) : `<h1>${esc(cur.title)}</h1><p class="empty">This chapter is not written yet.${cur.about ? ' It will cover: ' + esc(cur.about) : ''}</p>`}</div>
<div class="doc bnav">${prev ? `<button data-ch="${esc(prev.n)}"><small>‹ ${esc(chapterLabel(prev.n))}</small><b>${esc(prev.title)}</b></button>` : '<span></span>'}${next ? `<button class="nx" data-ch="${esc(next.n)}"><small>${esc(chapterLabel(next.n))} ›</small><b>${esc(next.title)}</b></button>` : ''}</div>
</div></div></div></div>`;
    if (toTop) { el.innerHTML = html; } else keepScroll(el, () => { el.innerHTML = html; });
    this.renderContents();
    const sc = el.querySelector('[data-scroll="book"]');
    if (toTop && sc) sc.scrollTop = 0;
    if (host.bookAt) { const at = host.bookAt; host.bookAt = null; setTimeout(() => scrollToAnchor(el, 'b-' + at) || scrollToAnchor(el, at), 0); }
  },
});

/* ---------- Reference ---------- */
view('reference', {
  mount(el) {
    this.el = el;
    const md = C.reference;
    el.innerHTML = `<div class="tabbody col"><div class="toolbar"><span class="lbl">The engine's API on one page. The agent receives this same text with its instructions.</span></div><div class="scroll" data-scroll="ref">${md && md.trim() ? `<div class="doc">${MD.render(md, { prefix: 'r-', toc: true })}</div>` : '<p class="empty padded">The Reference is not loaded. It comes from content-src/reference.md, built with tools/build-content.js.</p>'}</div></div>`;
    bindLab(el);
  },
});

/* ---------- Agent (the panel lives in js/agent.js) ---------- */
view('agent', {
  mount(el) { if (W.StrataAgent && W.StrataAgent.mount) W.StrataAgent.mount(el, host); else el.innerHTML = '<p class="empty padded">The agent did not load (js/agent.js).</p>'; },
  update(w) { if (W.StrataAgent && W.StrataAgent.update) W.StrataAgent.update(w); },
  unmount() { if (W.StrataAgent && W.StrataAgent.unmount) W.StrataAgent.unmount(); },
});
