/* Part 4: boot. */
function boot() {
  Theme.init();
  const app = document.getElementById('app') || document.body.appendChild(Object.assign(document.createElement('div'), { id: 'app' }));
  app.innerHTML = '<header class="bar"></header><div class="dock"></div>';
  Header.init(app.querySelector('.bar'));
  Presets.init();
  Dock.init(app.querySelector('.dock'));
  host.on(what => { Header.render(); Dock.update(what); });
  if (W.StrataAgent && W.StrataAgent.init) safe(() => W.StrataAgent.init(host));
  Header.render();
  Dock.render();
  // lab: links in any view that does not bind its own (those call preventDefault first)
  document.addEventListener('click', ev => {
    if (ev.defaultPrevented) return;
    const a = ev.target.closest && ev.target.closest('a.lablink'); if (!a) return;
    ev.preventDefault(); host.link(a.dataset.lab);
  });
  document.addEventListener('keydown', ev => {
    if ((ev.ctrlKey || ev.metaKey) && ev.key === 'Enter') { ev.preventDefault(); host.build(); }
  });
  const fromHash = () => { const m = (W.location.hash || '').match(/^#([A-Z]-\d{2,3})$/); return m && Presets.get(m[1]) ? m[1] : null; };
  W.addEventListener('hashchange', () => { const id = fromHash(); if (id && (!host.preset || host.preset.id !== id)) host.loadPreset(id); });
  const want = fromHash() || store.get('preset', null);
  const first = want && Presets.get(want) ? want : (Presets.builtins[0] && Presets.builtins[0].id);
  if (first) host.loadPreset(first, { noFocus: true });
  else { host.emit('preset'); }
  // one of your own presets kept in the shared store arrives after boot: open it once it does
  if (want && /^U-/.test(want) && !Presets.get(want)) {
    const stop = host.on(what => {
      if (what !== 'presets') return;
      if (Presets.get(want)) { stop(); if (!host.preset || (host.preset.id === first && !host.edited())) host.loadPreset(want, { noFocus: true }); }
      else if (Presets.dbState !== 'pending') stop();
    });
  }
  if (!hasEngine()) host.build();
}
W.StrataShell = { host, Presets, Dock, Header, Views, VIEWS, LAYOUTS, yaml, store };
if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot); else boot();
})();
