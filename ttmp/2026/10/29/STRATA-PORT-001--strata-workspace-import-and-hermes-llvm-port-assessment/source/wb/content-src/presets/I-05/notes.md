# Dominators

A block A **dominates** a block B when every path from the entry to B passes through A. SSA rests on this relation: a value defined in A may be used in B only if A dominates B, and when it does not, a block parameter has to carry the value. This preset computes the dominators of a small loop with a diamond inside, draws the dominator tree, and works out the dominance frontiers that tell promotion where parameters go.

> **Try it.** [Show parity on the Stage](lab:fn?name=parity) and [the table](lab:show?view=experiments) side by side. Every block but `entry` has an immediate dominator; `merge` is dominated by `test`, not by `yes` or `no`.

## The function

`parity(n)` counts the odd numbers below `n`; `parity(7)` is 3. Its loop header `head` carries `i` and the count `odd`; the body tests `i % 2` and goes through `yes` (count one more) or `no`, then meets at `merge`, which increments `i` and jumps back.

## Immediate dominators and the tree

Every block other than the entry has an **immediate dominator**: the strict dominator closest to it. Drawing an edge from each block's idom to the block gives the **dominator tree**:

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 230">
  <defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto"><path d="M0,0 L10,5 L0,10 z" class="f-ink"/></marker></defs>
  <text x="20" y="18" font-size="10" class="lbl">control flow</text>
  <g font-size="11">
    <rect x="70" y="28" width="70" height="22" fill="none" stroke="currentColor" class="ink"/><text x="84" y="43">entry</text>
    <rect x="70" y="72" width="70" height="22" fill="none" stroke="currentColor" class="ink"/><text x="86" y="87">head</text>
    <rect x="20" y="116" width="70" height="22" fill="none" stroke="currentColor" class="ink"/><text x="38" y="131">test</text>
    <rect x="120" y="116" width="70" height="22" fill="none" stroke="currentColor" class="ink"/><text x="140" y="131">exit</text>
    <rect x="0" y="160" width="50" height="22" fill="none" stroke="currentColor" class="ink"/><text x="14" y="175">yes</text>
    <rect x="60" y="160" width="50" height="22" fill="none" stroke="currentColor" class="ink"/><text x="76" y="175">no</text>
    <rect x="20" y="200" width="70" height="22" fill="none" stroke="currentColor" class="acc"/><text x="32" y="215">merge</text>
  </g>
  <g fill="none" stroke="currentColor" class="ink" stroke-width="1">
    <line x1="105" y1="50" x2="105" y2="72" marker-end="url(#arrow)"/>
    <line x1="95" y1="94" x2="60" y2="116" marker-end="url(#arrow)"/>
    <line x1="115" y1="94" x2="150" y2="116" marker-end="url(#arrow)"/>
    <line x1="45" y1="138" x2="28" y2="160" marker-end="url(#arrow)"/>
    <line x1="65" y1="138" x2="82" y2="160" marker-end="url(#arrow)"/>
    <line x1="25" y1="182" x2="45" y2="200" marker-end="url(#arrow)"/>
    <line x1="85" y1="182" x2="65" y2="200" marker-end="url(#arrow)"/>
    <path d="M90,211 L210,211 L210,83 L140,83" class="dash" marker-end="url(#arrow)"/>
  </g>
  <text x="216" y="150" font-size="10" class="lbl mut">back edge</text>
  <text x="360" y="18" font-size="10" class="lbl">dominator tree</text>
  <g font-size="11">
    <rect x="430" y="28" width="70" height="22" fill="none" stroke="currentColor" class="ink"/><text x="444" y="43">entry</text>
    <rect x="430" y="80" width="70" height="22" fill="none" stroke="currentColor" class="ink"/><text x="446" y="95">head</text>
    <rect x="370" y="132" width="70" height="22" fill="none" stroke="currentColor" class="ink"/><text x="388" y="147">test</text>
    <rect x="490" y="132" width="70" height="22" fill="none" stroke="currentColor" class="ink"/><text x="510" y="147">exit</text>
    <rect x="320" y="190" width="50" height="22" fill="none" stroke="currentColor" class="ink"/><text x="334" y="205">yes</text>
    <rect x="380" y="190" width="50" height="22" fill="none" stroke="currentColor" class="ink"/><text x="396" y="205">no</text>
    <rect x="440" y="190" width="70" height="22" fill="none" stroke="currentColor" class="acc"/><text x="452" y="205">merge</text>
  </g>
  <g fill="none" stroke="currentColor" class="mut" stroke-width="1">
    <line x1="465" y1="50" x2="465" y2="80"/>
    <line x1="455" y1="102" x2="410" y2="132"/>
    <line x1="475" y1="102" x2="520" y2="132"/>
    <line x1="395" y1="154" x2="348" y2="190"/>
    <line x1="405" y1="154" x2="405" y2="190"/>
    <line x1="415" y1="154" x2="470" y2="190"/>
  </g>
</svg>
```

**Figure 1.** Left, the control flow of `parity`, with the back edge dashed. Right, its dominator tree: each block hangs from its immediate dominator. `merge` hangs from `test`, because neither arm of the diamond is on every path to it.

The tree is what [g.dominators](lab:show?view=experiments) returns as `idom`. Its `dominates(a, b)` walks up from `b`: `dominates('head', 'merge')` is true and `dominates('yes', 'merge')` is false, as [Events](lab:show?view=events) prints. The workbench computes it with the iterative algorithm of Cooper, Harvey and Kennedy, which settles here in 2 rounds.

## Where values may be used

A value defined in `test`, such as `half`, may be used in `yes`, `no` and `merge`, all below `test` in the tree. `odd1`, defined in `yes`, may not be used in `merge`: `no` reaches `merge` without passing `yes`. That is why `merge` has a parameter `o` and each arm passes its own count. [Select merge](lab:node?id=parity/merge).

## Dominance frontiers

The **dominance frontier** of a block A is the set of blocks where A's dominance stops: blocks B with a predecessor that A dominates, while A does not strictly dominate B itself. They are exactly the places where a value defined in A may meet a value from elsewhere, so they are where promotion must put block parameters. main.js computes them with the method of Cytron and colleagues (1991): for each block with two or more predecessors, walk up the tree from each predecessor until reaching that block's idom, adding the block to every frontier on the way.

| block | idom | frontier |
|---|---|---|
| `yes`, `no` | `test` | `merge` |
| `merge` | `test` | `head` |
| `test`, `head` | `head`, `entry` | `head` |

An assignment in `yes` needs a parameter at `merge`; that parameter is itself an assignment in `merge`, which needs one at `head`. This is the iterated frontier that [I-07](lab:preset?id=I-07) watches promotion place.

> **Exercise.** Add an edge from `no` straight to `exit` (make `no` branch on `num.gt(i, 100)`), rerun, and read the new table. Which idoms change? Which frontiers grow, and why does `exit` now need to know which count to return?

## Where next

[Chapter 3](lab:book?ch=3) states the dominance rule of the verifier, and [Chapter 4](lab:book?ch=4) uses frontiers to build SSA. [I-04](lab:preset?id=I-04) shows the verifier's counter-path when the rule is broken.
