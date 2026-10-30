# Test fixture: a loop

A fixture for the shell tests. The loop in `total` allocates twice per turn, so $v_6$ is live across a safepoint.

> **Try it.** [Select the second allocation](lab:node?id=total/body/3), [show live values](lab:overlay?name=live&on=1), then [run with GC stress](lab:run?mode=plan&gc=stress). Open [program.js at line 4](lab:open?file=program.js&line=4) or [ask the agent](lab:ask?q=Why%20is%20v8%20not%20erased%3F).

## What to look at

| level | what changes |
|---|---|
| L1 | cells become block parameters |
| L3 | the safepoint at `total/body/3` roots `v6` |

```js
const program = g.compile(g.pipeline(), source());
```

$$\text{live}_{in}(b) = \text{use}(b) \cup (\text{live}_{out}(b) \setminus \text{def}(b))$$

```svg
<svg viewBox="0 0 300 60"><rect class="hair f-fill" x="10" y="10" width="80" height="40"/><text class="lbl" x="20" y="34">head</text><line class="ink" x1="90" y1="30" x2="200" y2="30"/><rect class="acc f-sel" x="200" y="10" width="80" height="40"/><text class="lbl" x="210" y="34">body</text></svg>
```

**Figure 1.1.** Two blocks of the fixture.

> **Exercise.** Change the root strategy to `none` and watch the [Plan](lab:show?view=plan).
