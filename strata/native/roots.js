"use strict";
// Native homes remain authoritative between safepoints. Interference therefore
// covers every program point, every edge transfer, and every helper's output.
const variable = (x) => typeof x === "string";
const uses = (xs) => xs.filter(variable);
function edges(term) {
  return term.kind === "jump"
    ? [term.to]
    : term.kind === "branch"
      ? [term.t, term.f]
      : [];
}
function termUses(term) {
  return term.kind === "branch"
    ? uses([term.cond])
    : ["return", "throw"].includes(term.kind)
      ? uses([term.value])
      : [];
}
function requirements(fn) {
  const liveIn = new Map(fn.blocks.map((b) => [b.name, new Set()]));
  const same = (a, b) => a.size === b.size && [...a].every((x) => b.has(x));
  function edgeLive(e) {
    const target = fn.block(e.block),
      live = liveIn.get(e.block),
      out = new Set(live);
    target.params.forEach((p) => out.delete(p.id));
    target.params.forEach((p, i) => {
      if (live.has(p.id) && variable(e.args[i])) out.add(e.args[i]);
    });
    return out;
  }
  function handler(b) {
    if (!b.onThrow || b.onThrow === "unwind") return new Set();
    const target = fn.block(b.onThrow),
      out = new Set(liveIn.get(b.onThrow));
    target.params.forEach((p) => out.delete(p.id));
    for (const a of uses(b.throwArgs || [])) out.add(a);
    return out;
  }
  function walk(b, record) {
    const exceptional = handler(b);
    let live = new Set([...termUses(b.term), ...exceptional]);
    for (const e of edges(b.term)) for (const x of edgeLive(e)) live.add(x);
    // Edge operands are read before parallel writes, even unused parameters.
    for (const e of edges(b.term)) for (const a of uses(e.args)) live.add(a);
    if (record) record([...live]);
    for (let i = b.ops.length - 1; i >= 0; i--) {
      const o = b.ops[i];
      for (const x of exceptional) live.add(x);
      if (record)
        record([...live, ...uses(o.args), ...(o.result ? [o.result] : [])]);
      if (o.result) live.delete(o.result);
      for (const x of uses(o.args)) live.add(x);
    }
    if (record) record([...live, ...b.params.map((p) => p.id)]);
    return live;
  }
  let changed = true,
    rounds = 0;
  while (changed) {
    changed = false;
    rounds++;
    for (const b of [...fn.blocks].reverse()) {
      const next = walk(b);
      if (!same(next, liveIn.get(b.name))) {
        liveIn.set(b.name, next);
        changed = true;
      }
    }
  }
  const sets = [];
  for (const b of fn.blocks) walk(b, (s) => sets.push([...new Set(s)]));
  sets.push([
    ...new Set([...liveIn.get(fn.entry), ...fn.params.map((p) => p.id)]),
  ]);
  return { sets, rounds };
}
function check(fn, slotOf) {
  const { sets } = requirements(fn);
  for (const values of sets) {
    const occupied = new Map();
    for (const v of values) {
      const slot = slotOf[v];
      if (!Number.isInteger(slot) || slot < 0)
        throw new Error(`Missing native root home: ${v}`);
      if (occupied.has(slot) && occupied.get(slot) !== v)
        throw new Error(
          `Native home collision: ${v} and ${occupied.get(slot)} at slot ${slot}`,
        );
      occupied.set(slot, v);
    }
  }
  return true;
}
function allocate(fn, strategy) {
  const values = fn.values();
  const { sets, rounds } = requirements(fn);
  const neighbors = new Map(values.map((v) => [v, new Set()]));
  for (const group of sets)
    for (const a of group)
      for (const b of group)
        if (a !== b) {
          if (!neighbors.has(a) || !neighbors.has(b))
            throw new Error("Unknown value in liveness");
          neighbors.get(a).add(b);
        }
  const slotOf = {};
  let count = 0;
  for (const v of values) {
    let slot = count;
    if (strategy === "reuse") {
      const forbidden = new Set(
        [...neighbors.get(v)]
          .map((n) => slotOf[n])
          .filter((n) => n !== undefined),
      );
      slot = 0;
      while (forbidden.has(slot)) slot++;
    }
    slotOf[v] = slot;
    count = Math.max(count, slot + 1);
  }
  check(fn, slotOf);
  return { slotOf, count, rounds, values: values.length };
}
module.exports = { allocate, check, requirements };
