# try, catch and finally lowered

A `finally` block must run however its `try` is left: by falling off the end, by `return`, or by an exception, caught or not. And after it runs, the function must carry on the way it was going: return the value, rethrow the exception, or continue after the statement. The frontend lowers this with **completion records**, small values that say how a region ended. This preset calls one function three times so that all three kinds of completion happen.

> **Try it.** [Run it](lab:build) and read the output: `finally after …` is printed before each result, including before `main caught zero is not allowed`. Then [show attempt on the Stage](lab:fn?name=attempt) with [exceptional edges](lab:overlay?name=exceptional&on=1).

## Three ways out

| call | path through `try` | completion | after `finally` |
|---|---|---|---|
| `attempt(1)` | `return "returned 1"` | return | returns `returned 1` |
| `attempt(-1)` | throws RangeError, `catch` handles it | normal | falls through to `return "fell through"` |
| `attempt(0)` | throws `"zero"`, `catch` throws TypeError | throw | rethrows to `main` |

## The blocks

The `try` and the `catch` are protected regions with different handlers. Blocks of the `try` (`try7`, `then8`, `then10`, `endif11`) are headed `throws to catch5`: an exception goes to the `catch`. Blocks of the `catch` (`catch5`, `then12`, `endif13`) are headed `throws to finthrow2`: an exception thrown while handling goes to the `finally`'s throw entry.

Every exit leads to one block, `finally1(c4: completion)`, with a different record:

```text
endif11() throws to catch5:
  …
  v15 = js.add("returned ", x)
  c16 = completion.return(v15)
  jump finally1(c16)
endtry6() throws to finthrow2:
  c26 = completion.normal()
  jump finally1(c26)
finthrow2(e5: any) throws unwind:
  c27 = completion.throw(e5)
  jump finally1(c27)
```

[Select finally1](lab:node?id=attempt/finally1): three incoming edges, one record each. The `finally` body runs once, in `finally1`, and then dispatches on the record:

```text
  isret30 = completion.is[return](c4)
  branch isret30, fin_return14(), fin_rest15()
fin_rest15() throws unwind:
  isthrow32 = completion.is[throw](c4)
  branch isthrow32, fin_throw16(), endfinally3()
```

`fin_return14` returns `completion.value(c4)`, `fin_throw16` throws it, and `endfinally3` is the code after the statement.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 200">
  <defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto"><path d="M0,0 L10,5 L0,10 z" class="f-ink"/></marker></defs>
  <g font-size="11">
    <rect x="10" y="20" width="150" height="26" fill="none" stroke="currentColor" class="ink"/><text x="20" y="37">endif11: return v15</text>
    <rect x="10" y="80" width="150" height="26" fill="none" stroke="currentColor" class="ink"/><text x="20" y="97">endtry6: fell off</text>
    <rect x="10" y="140" width="150" height="26" fill="none" stroke="currentColor" class="ink"/><text x="20" y="157">finthrow2: caught e5</text>
    <rect x="250" y="70" width="140" height="46" fill="none" stroke="currentColor" class="acc" stroke-width="1.6"/>
    <text x="262" y="89" class="b">finally1(c4)</text><text x="262" y="106" class="mut">print, then dispatch</text>
    <rect x="480" y="20" width="150" height="26" fill="none" stroke="currentColor" class="ink"/><text x="490" y="37">fin_return14: return</text>
    <rect x="480" y="80" width="150" height="26" fill="none" stroke="currentColor" class="ink"/><text x="490" y="97">endfinally3: continue</text>
    <rect x="480" y="140" width="150" height="26" fill="none" stroke="currentColor" class="ink"/><text x="490" y="157">fin_throw16: rethrow</text>
  </g>
  <g fill="none" stroke="currentColor" class="ink">
    <path d="M160,33 L205,33 L205,82 L250,82" marker-end="url(#arrow)"/>
    <path d="M160,93 L250,93" marker-end="url(#arrow)"/>
    <path d="M160,153 L205,153 L205,104 L250,104" marker-end="url(#arrow)"/>
    <path d="M390,82 L435,82 L435,33 L480,33" marker-end="url(#arrow)"/>
    <path d="M390,93 L480,93" marker-end="url(#arrow)"/>
    <path d="M390,104 L435,104 L435,153 L480,153" marker-end="url(#arrow)"/>
  </g>
  <g font-size="10" class="mut">
    <text x="168" y="27">return</text><text x="168" y="84">normal</text><text x="168" y="168">throw</text>
    <text x="398" y="27">is[return]</text><text x="440" y="88">neither</text><text x="398" y="168">is[throw]</text>
  </g>
</svg>
```

**Figure 1.** The `finally` join of `attempt`. Three exits make three completion records; one block runs the `finally` body and sends each record on its way. Schematic: block names are the engine's, the layout is not the Stage's.

## Why a record and not three copies

A compiler could copy the `finally` body onto every exit instead. That is fine for one `print`, but a `finally` with loops in it, or nested `try`s with `finally`s of their own, would multiply. One join with a record keeps the code linear in the source, and the record is an ordinary value: `completion.return(v)` allocates a small object (its type is `completion`, and it is a managed value that may need a root slot). The cost is a few branches after the `finally`.

## The handler's view of steps

`steps` is written inside the `try` and inside the `catch`, and read in the `finally`. As [I-09](lab:preset?id=I-09) explains, a handler can only receive values from the head of a protected block, so `steps` stays the cell `c_steps3`, and the `finally` reads whatever the last store left: `start, ok` after the return, `start, caught negative` after the caught throw, and `start` after the rethrow.

> **Exercise.** Add `return "from finally";` at the end of the `finally` block and rerun. What do the three calls print now, and where did `main`'s exception go? Find the block that makes this happen.

## Where next

[Chapter 5](lab:book?ch=5) explains completion records with the rest of exceptional control flow. [J-03](lab:preset?id=J-03) uses `finally` with `return` in a larger function, and [L-08](lab:preset?id=L-08) shows the `setjmp` machinery behind the handlers.
