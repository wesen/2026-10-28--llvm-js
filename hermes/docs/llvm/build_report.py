#!/usr/bin/env python3
"""Assemble the textbook report from checked chapters and recorded evidence.

Requires ReportLab; no compiler/test command is executed here. Default PDF
destination is output/pdf beneath the repository root.
"""
from pathlib import Path
import argparse
import html
import json
import re
import textwrap

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    BaseDocTemplate, Frame, PageTemplate, Paragraph, Spacer, PageBreak,
    Table, TableStyle, Preformatted, KeepTogether,
)
from reportlab.platypus.tableofcontents import TableOfContents
from reportlab.graphics.shapes import Drawing, Rect, Line, Polygon, String

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
PARSER = argparse.ArgumentParser(description=__doc__)
PARSER.add_argument("--output", type=Path,
                    default=ROOT / "output/pdf/Direct-LLVM-Implementation-Report.pdf")
ARGS = PARSER.parse_args()
ARGS.output.parent.mkdir(parents=True, exist_ok=True)

def numbered_chapter(text, number, title):
    text = text.split("\n", 1)[1]
    count = 0
    def heading(m):
        nonlocal count
        count += 1
        label = re.sub(r"^\d+\.\s*", "", m[1])
        return f"## {number}.{count}. {label}"
    text = re.sub(r"(?m)^## (.+)$", heading, text)
    return f"# {number}. {title}\n" + text

def compose():
    final_matrix = HERE / "evidence/final-validation.json"
    matrix = json.loads((final_matrix if final_matrix.exists()
                         else HERE / "evidence/validation.json").read_text())
    driver = json.loads((HERE / "evidence/driver-validation.json").read_text())
    lexical = json.loads((HERE / "evidence/lexical-defaults-validation.json").read_text())
    # Only final recorded outcomes support this table.
    assert matrix["source_cases"] == matrix["passed_cases"] == 22
    assert matrix["failed_cases"] == 0
    assert matrix["native_llvm_vs_node_and_c_comparisons"] == 64
    rows = [
        "| Evidence layer | Recorded final outcome | Scope |",
        "|---|---|---|",
        "| Host source cases | 22 / 22 passed | 16 positive, 3 runtime-error, 3 compile-rejection |",
        "| Native differential executions | 64 / 64 comparisons passed | Hermes O0 and O, each at LLVM O0 and O2; compared with Node and C |",
        "| LLVM JIT executions | 3 / 3 comparisons passed | Functions, mutable closures and forced collection |",
        "| Runtime-error executions | 6 / 6 expected errors | Three sources at both Hermes frontend settings |",
        f"| Compiler publication checks | {driver['passed']} / {driver['total']} passed | Default/stdout/exported output, C bypass and preservation on failure |",
        f"| Raw lexical-default checks | {lexical['passed']} / {lexical['total']} passed | Default behavior, explicit overrides and static TDZ diagnostic |",
        "| RV32 integer-world regression | 24 / 24 passed; no skips | Complete recorded socket-enabled simulator/service run |",
        "| RV32 replay artifacts | 6 verified modules; 11 trace records | Linked ELF images, actual instruction execution and reload trace |",
    ]
    intro = (HERE / "REPORT_INTRO.md").read_text()
    intro = intro.split("## 1.5 How to use this report", 1)[0]
    example = (ROOT / "examples/llvm/counter.js").read_text().strip()
    output = (HERE / "evidence/counter-native.txt").read_text().strip()
    assert output == (HERE / "evidence/counter-jit.txt").read_text().strip()
    intro = intro.replace("<!-- COUNTER_SOURCE -->", "```javascript\n" + example + "\n```")
    intro = intro.replace("<!-- COUNTER_OUTPUT -->", "```text\n" + output + "\n```")
    arch = (HERE / "ARCHITECTURE.md").read_text()
    arch, refs = arch.split("## References and source-reading guide", 1)
    arch = numbered_chapter(arch, 2, "Architecture and implementation")
    arch = re.sub(r"Section (\d+)", r"Section 2.\1", arch)
    validation = (HERE / "REPORT_VALIDATION.md").read_text()
    validation = validation.replace("<!-- VALIDATION_TABLE -->", "\n".join(rows))
    validation = validation.replace("`picocalc/logs/", "`picocalc-llvm-poc/logs/")
    if final_matrix.exists():
        validation = validation.replace(
            "The final host results are `docs/llvm/evidence/validation.json` and `validation.log`.",
            "The final host results are `docs/llvm/evidence/final-validation.json` "
            "and `final-validation.log`. The original `validation.json` and "
            "`validation.log` remain as historical evidence.")
        validation = validation.replace(
            "`validated-files.json` connects the execution evidence to hashes of the actual inputs and binaries.",
            "`final-validated-files.json` connects the final execution evidence "
            "to hashes of the actual inputs and binaries; "
            "`validated-files.json` preserves the earlier capture.")
    post = HERE / "evidence/post-review-verifier.json"
    if post.exists():
        validation += (
            "\n## 3.8 Post-review diagnostic parity\n\n"
            "Final review identified one diagnostic parity gap: direct emission "
            "did not consult the requested lowered-Hermes-IR verification option. "
            "The emitter now follows the existing C backend's verifier sequence "
            "before assigning environment indices. The original full-matrix "
            "records and hashes are preserved. The separate post-review record "
            "identifies the final source/compiler hashes: 32 enabled/disabled "
            "emission pairs were byte-identical, all 64 modules assembled and "
            "passed LLVM verification, and both counter executions (native "
            "and JIT) matched the prior output. The broad native matrix was "
            "not rerun after this diagnostic-only change. "
            "The pinned Release build compiles the upstream Hermes verifier "
            "as a no-op unless HERMES_SLOW_DEBUG is enabled; these checks "
            "therefore establish flag plumbing and output invariance, not "
            "a malformed-Hermes-IR rejection experiment. LLVM assembly and "
            "LLVM verification remain real checks in this build.\n"
        )
    if (HERE / "evidence/post-review-driver.json").exists():
        validation += (
            "\nFinal reproduction review also found that the wrapper's "
            "automatic CMake command refreshed only the shared bridge, while "
            "native linking uses the static archive. It now requests both "
            "bridge targets. Separate native and JIT counter runs with "
            "automatic building enabled verified the dependency correction "
            "and matched the prior output. This driver-only change is recorded "
            "separately from the full differential matrix and does not change "
            "the emitter's instruction translation.\n"
        )
    if final_matrix.exists():
        validation = validation.replace(
            "The broad native matrix was not rerun after this diagnostic-only change.",
            "That focused guard check initially left the broad native matrix unchanged.")
        validation += (
            "\nThe subsequent automatic dependency build also refreshed the "
            "Hermes VM binary. To validate that concrete final artifact, the "
            "complete host matrix was then repeated with the final compiler, "
            "driver, runtime and bridges: all 22 cases passed, including "
            "64 native comparisons, three JIT comparisons and six checked "
            "runtime-error executions. No quick mode or JIT skip was used. "
            "The final matrix is the release gate; earlier and focused records "
            "remain available to explain how the implementation reached it.\n"
        )
    integration_source = (HERE / "PICOCALC_INTEGRATION.md").read_text()
    integration_source = integration_source.split("## Source references", 1)[0]
    integration_source += (
        "\nSource-reading pointers for these contracts are collected in "
        "Chapter 6. The standalone integration chapter retains its own "
        "local reference list.\n")
    integration = numbered_chapter(
        integration_source, 4,
        "PicoCalc integration and the device boundary")
    driver_text = numbered_chapter((HERE / "DRIVER.md").read_text(), 5,
                                  "Build, inspect, execute, and reproduce")
    driver_text = driver_text.replace(
        "--target shermes shllvm_runtime_shared",
        "--target shermes shllvm_runtime shllvm_runtime_shared")
    driver_text += r"""
## 5.6 Exact release layout and patch route

The complete archive has a `hermes/` source tree and a `picocalc-llvm-poc/`
tree. Run host commands from `hermes/`. The archive omits build outputs,
Git history, package caches and `node_modules`. It retains the relevant
upstream licences, dependency sources, the PicoCalc lockfile, recorded
evidence and report sources. Rebuild binaries for your installation.

For an existing clone, check out the pinned base in a separate worktree and
apply `Static-Hermes-direct-LLVM.patch` with `git apply --check` followed by
`git apply`. The delivered provenance records a successful independent-index
application to that base and an exact resulting-tree comparison. Do not
assume that a moving upstream branch accepts the patch unchanged.

To reproduce the individual compiler gates after the build:

```sh
python3 utils/test_shllvm_driver.py
python3 utils/test_shllvm_defaults.py
python3 utils/test_shllvm.py --jobs 2
```

For a nondefault installation, configure each test entry point explicitly:

```sh
python3 utils/test_shllvm_driver.py \
  --compiler /path/to/build/bin/shermes
python3 utils/test_shllvm_defaults.py \
  --build-dir /path/to/build --clang /path/to/llvm/bin/clang
python3 utils/test_shllvm.py \
  --build-dir /path/to/build --llvm-bin /path/to/llvm/bin --jobs 2
```

The main differential runner also honors `LLVM_BIN` and `HERMES_BUILD_DIR`.
The raw driver check uses `--compiler`; the lexical-default check uses
`--build-dir` and `--clang` (with `CLANG` supplying its default compiler).
The original evidence contains absolute paths from the recording environment;
these are provenance, not paths that must exist on another machine.
The Python drivers resolve current tool and runtime locations.

The PicoCalc README gives its own toolchain variables, dependency installation,
test commands and replay format. Its original C-oriented technical report is
retained as historical context; `docs/DIRECT_LLVM.md` and the present report
describe the updated compiler. The two projects' test runners are independent.

PDF regeneration uses `python3 docs/llvm/build_report.py` from the Hermes
source root with ReportLab and DejaVu fonts installed. This renders the saved
chapters and evidence; it does not rerun or synthesize validation results.
"""
    references = "# 6. References and source-reading guide\n" + refs
    references += """

## Additional evidence-reading references

The numbered sources above support the architecture chapter. Implementation
and experiment claims also refer to the delivered source and logs named in
Chapter 3. Read `test/LLVMNative/gc_closures.js` together with the upstream
`lib/VM/JSLib/GlobalObject.cpp` collector hook when assessing the forced-GC
test. Follow source code to its runtime implementation when an inline header
declaration does not establish allocation or lifetime behavior.

For further study, use the official
[LLVM garbage-collection documentation](https://releases.llvm.org/18.1.8/docs/GarbageCollection.html)
to compare this explicit-root bridge with compiler-supported collector
interfaces. The present implementation does not use LLVM statepoints.
Use the official
[ECMAScript specification](https://tc39.es/ecma262/)
when distinguishing language semantics from retained Static Hermes
frontend restrictions. A specification describes the required language;
the test matrix describes the subset actually exercised here.
"""
    result = "# Direct LLVM Implementation: Functions, Objects, Closures, and PicoCalc\n\n"
    result += "Technical report and undergraduate compiler laboratory. 28 October 2026.\n\n"
    result += "\n\n".join([intro, arch, validation, integration, driver_text, references])
    if "<!--" in result:
        raise ValueError("Unresolved report placeholder")
    (HERE / "REPORT.md").write_text(result)
    return result

REPORT = compose()
REFERENCE_URLS = dict(re.findall(r"(?m)^\[(\d+)\]:\s*(\S+)\s*$", REPORT))

FONTROOT = Path("/usr/share/fonts/truetype/dejavu")
FONTS = {
    "Body": "DejaVuSerif.ttf", "BodyBold": "DejaVuSerif-Bold.ttf",
    "Head": "DejaVuSans.ttf", "HeadBold": "DejaVuSans-Bold.ttf",
    "Code": "DejaVuSansMono.ttf",
}
for name, filename in FONTS.items():
    pdfmetrics.registerFont(TTFont(name, str(FONTROOT / filename)))
pdfmetrics.registerFontFamily("Body", normal="Body", bold="BodyBold",
                             italic="Body", boldItalic="BodyBold")
pdfmetrics.registerFontFamily("Head", normal="Head", bold="HeadBold",
                             italic="Head", boldItalic="HeadBold")
BLUE = "#163447"; TEAL = "#167b82"; INK = "#283640"; PALE = "#edf4f5"
WIDTH, HEIGHT = A4
MARGIN = 49
CONTENT = WIDTH - 2 * MARGIN
S = {
    "body": ParagraphStyle("body", fontName="Body", fontSize=9.5, leading=14.1,
        spaceAfter=7, textColor=colors.HexColor(INK), allowWidows=0, allowOrphans=0),
    "h1": ParagraphStyle("h1", fontName="HeadBold", fontSize=21, leading=27,
        spaceAfter=17, textColor=colors.HexColor(BLUE), keepWithNext=True),
    "h2": ParagraphStyle("h2", fontName="HeadBold", fontSize=12, leading=17,
        spaceBefore=13, spaceAfter=8, textColor=colors.HexColor(TEAL), keepWithNext=True),
    "h3": ParagraphStyle("h3", fontName="HeadBold", fontSize=10.5, leading=15,
        spaceBefore=10, spaceAfter=6, textColor=colors.HexColor(BLUE), keepWithNext=True),
    "table": ParagraphStyle("table", fontName="Head", fontSize=7.8, leading=11,
        textColor=colors.HexColor(INK), splitLongWords=True),
    "th": ParagraphStyle("th", fontName="HeadBold", fontSize=7.9, leading=11,
        textColor=colors.white),
    "code": ParagraphStyle("code", fontName="Code", fontSize=7, leading=10,
        leftIndent=7, rightIndent=7, borderPadding=7, spaceBefore=4, spaceAfter=10,
        backColor=colors.HexColor("#f1f5f6")),
    "caption": ParagraphStyle("caption", fontName="Head", fontSize=8, leading=11.5,
        spaceBefore=5, spaceAfter=12, textColor=colors.HexColor("#576c78")),
    "bullet": ParagraphStyle("bullet", fontName="Body", fontSize=9.5, leading=14.1,
        leftIndent=13, firstLineIndent=-10, spaceAfter=5,
        textColor=colors.HexColor(INK), allowWidows=0, allowOrphans=0),
    "quote": ParagraphStyle("quote", fontName="Head", fontSize=9.3, leading=14,
        leftIndent=14, rightIndent=10, spaceBefore=4, spaceAfter=10,
        borderPadding=8, backColor=colors.HexColor(PALE), textColor=colors.HexColor(BLUE)),
}

def inline(text, code_size=8):
    fragments = []
    def save(value):
        fragments.append(value)
        return f"ZZINLINE{len(fragments)-1}ZZ"
    text = text.replace("\u2011", "-").replace("\u2013", "-").replace("\u2014", "-")
    text = re.sub(r"`([^`]+)`", lambda m: save(
        f'<font name="Code" size="{code_size}">' + html.escape(m[1]) + "</font>"), text)
    def link(label, target):
        label = html.escape(label)
        if target.startswith(("https://", "http://")):
            return save(f'<link href="{html.escape(target, quote=True)}" color="{TEAL}">{label}</link>')
        return label
    text = re.sub(r"\[([^\]]+)\]\[([0-9]+)\]",
                  lambda m: link(m[1], REFERENCE_URLS[m[2]]), text)
    text = re.sub(r"\[([^\]]+)\]\(([^)]+)\)",
                  lambda m: link(m[1], m[2]), text)
    text = html.escape(text)
    text = re.sub(r"\*\*(.+?)\*\*", r"<b>\1</b>", text)
    text = re.sub(r"(?<!\*)\*([^*]+)\*(?!\*)", r"<i>\1</i>", text)
    for _ in range(2):
        for i, value in enumerate(fragments):
            text = text.replace(f"ZZINLINE{i}ZZ", value)
    return text

def cells(line):
    result, current, code = [], [], False
    for char in line.strip().strip("|"):
        if char == "`": code = not code
        if char == "|" and not code:
            result.append("".join(current).strip()); current = []
        else: current.append(char)
    return result + ["".join(current).strip()]

def table(lines):
    rows = [cells(line) for line in lines]
    rows = [r for r in rows if not all(re.fullmatch(r":?-+:?", c.replace(" ", "")) for c in r)]
    n = max(map(len, rows))
    for row in rows: row.extend([""] * (n - len(row)))
    if n == 2: weights = [.30, .70]
    elif n == 3:
        weights = [.22, .46, .32] if rows[0][0] == "Area" else [.25, .35, .40]
    else: weights = [1/n] * n
    data = [[Paragraph(inline(c, code_size=7.1), S["th" if i == 0 else "table"])
             for c in row] for i, row in enumerate(rows)]
    t = Table(data, colWidths=[CONTENT * w for w in weights],
              repeatRows=1, hAlign="LEFT", spaceBefore=6, spaceAfter=11)
    t.setStyle(TableStyle([
        ("BACKGROUND", (0,0), (-1,0), colors.HexColor(BLUE)),
        ("ROWBACKGROUNDS", (0,1), (-1,-1), [colors.HexColor(PALE), colors.white]),
        ("VALIGN", (0,0), (-1,-1), "TOP"),
        ("TOPPADDING", (0,0), (-1,-1), 6),
        ("BOTTOMPADDING", (0,0), (-1,-1), 6),
        ("LEFTPADDING", (0,0), (-1,-1), 6),
        ("RIGHTPADDING", (0,0), (-1,-1), 6),
    ]))
    return t

def box(d, x, y, w, h, label, accent=BLUE):
    d.add(Rect(x, y, w, h, rx=5, ry=5, fillColor=colors.HexColor(PALE),
               strokeColor=colors.HexColor(accent), strokeWidth=.9))
    lines = label.split("\n")
    for i, line in enumerate(lines):
        d.add(String(x+w/2, y+h/2+(len(lines)-1)*5.5-i*11-3, line,
                     fontName="Head", fontSize=8.7, textAnchor="middle",
                     fillColor=colors.HexColor(accent)))

def arrow(d, x1, y1, x2, y2, accent=TEAL):
    import math
    d.add(Line(x1,y1,x2,y2,strokeColor=colors.HexColor(accent),strokeWidth=1))
    a = math.atan2(y2-y1, x2-x1)
    size = 5.5
    points = [x2,y2,
              x2-size*math.cos(a-.45), y2-size*math.sin(a-.45),
              x2-size*math.cos(a+.45), y2-size*math.sin(a+.45)]
    d.add(Polygon(points, fillColor=colors.HexColor(accent), strokeColor=None))

def diagram(number):
    if number == 1:
        d = Drawing(CONTENT, 292)
        left, right, w = 12, 290, 190
        box(d,left,248,w,36,"JavaScript source\nHermes frontend and IR")
        box(d,left,190,w,36,"Shared module lowering")
        box(d,left,132,w,36,"New direct LLVM emitter",TEAL)
        box(d,left,74,w,36,"LLVM verification\nand code generation")
        box(d,left,16,w,36,"Native guest functions")
        box(d,right,190,w,36,"Existing C backend\nsemantic comparison")
        box(d,right,132,w,36,"Hermes managed runtime")
        box(d,right,74,w,36,"Prebuilt C runtime bridge")
        for y in [248,190,132,74]: arrow(d,left+w/2,y,left+w/2,y-22)
        arrow(d,left+w,208,right,208)
        arrow(d,right+w/2,132,right+w/2,110)
        arrow(d,left+w,34,right+20,74)
        cap = "Figure 1. The direct emitter branches before C-specific register allocation. Generated functions call the prebuilt bridge; the existing C backend remains an independent comparison path."
    else:
        d = Drawing(CONTENT, 240)
        box(d,113,198,100,32,"Object a")
        box(d,385,198,100,32,"Object b")
        for x,label in [(7,"inc closure"),(123,"dec closure"),(239,"read closure")]:
            box(d,x,126,100,32,label)
            arrow(d,163,198,x+50,158)
            arrow(d,x+50,126,163,73)
        box(d,385,126,100,32,"inc closure")
        box(d,63,35,200,38,"Environment A\nshared mutable binding n",TEAL)
        box(d,370,35,125,38,"Environment B\nseparate binding n",TEAL)
        arrow(d,435,198,435,158)
        arrow(d,435,126,432.5,73)
        cap = "Figure 2. Three closures from one counter share a binding. A separate factory invocation creates an independent environment; the environment can outlive its creator's native frame."
    return KeepTogether([d, Paragraph(cap, S["caption"])])

def cover(canvas, doc):
    canvas.saveState()
    canvas.setFillColor(colors.HexColor("#f5f7f5"))
    canvas.rect(0,0,WIDTH,HEIGHT,fill=1,stroke=0)
    canvas.setFillColor(colors.HexColor(BLUE))
    canvas.rect(0,0,WIDTH,108,fill=1,stroke=0)
    canvas.setFillColor(colors.HexColor(TEAL))
    canvas.rect(MARGIN,HEIGHT-122,62,6,fill=1,stroke=0)
    canvas.setFont("Head",9.5)
    canvas.drawString(MARGIN,HEIGHT-84,"AN IMPLEMENTED COMPILER / AN UNDERGRADUATE LABORATORY")
    canvas.setFillColor(colors.HexColor(BLUE))
    canvas.setFont("HeadBold",39)
    canvas.drawString(MARGIN,HEIGHT-190,"Direct LLVM")
    canvas.drawString(MARGIN,HEIGHT-239,"Implementation")
    canvas.setFont("Head",17)
    canvas.drawString(MARGIN,HEIGHT-286,"Functions, objects, closures, and PicoCalc")
    canvas.setFont("Body",12)
    for i,line in enumerate([
        "Architecture and runtime contracts",
        "Working source, native execution, and LLVM JIT",
        "Recorded tests, engineering diary, and primary references",
    ]): canvas.drawString(MARGIN,HEIGHT-351-i*25,line)
    canvas.setStrokeColor(colors.HexColor("#cbdcde"))
    canvas.line(MARGIN,285,WIDTH-MARGIN,285)
    canvas.setFont("HeadBold",10)
    canvas.drawString(MARGIN,258,"TWO VALIDATED EXECUTION TARGETS")
    canvas.setFont("Head",10)
    canvas.drawString(MARGIN,234,"Dynamic JavaScript: Linux x86-64 + Static Hermes runtime")
    canvas.drawString(MARGIN,214,"Integer worlds: RV32IM code + PicoCalc instruction simulator")
    canvas.setFont("Head",9)
    canvas.setFillColor(colors.HexColor("#d8eeed"))
    canvas.drawString(MARGIN,72,"28 OCTOBER 2026  |  EXPERIMENTAL BACKEND RELEASE")
    canvas.setFont("Code",8)
    canvas.drawString(MARGIN,48,"Hermes base: f837b9dd8396ebf5c4e8115412417d273565f0fe")
    canvas.restoreState()

def normal_page(canvas, doc):
    canvas.saveState()
    canvas.setFont("Head",7.5)
    canvas.setFillColor(colors.HexColor("#59717e"))
    canvas.drawString(MARGIN,HEIGHT-27,"DIRECT LLVM / ARCHITECTURE, IMPLEMENTATION, AND EVIDENCE")
    canvas.setStrokeColor(colors.HexColor("#d1dfe2"))
    canvas.line(MARGIN,HEIGHT-35,WIDTH-MARGIN,HEIGHT-35)
    canvas.line(MARGIN,35,WIDTH-MARGIN,35)
    canvas.drawString(MARGIN,22,"Static Hermes + PicoCalc | 28 October 2026")
    canvas.drawRightString(WIDTH-MARGIN,22,str(doc.page))
    canvas.restoreState()

class Book(BaseDocTemplate):
    def __init__(self, path):
        super().__init__(str(path), pagesize=A4, leftMargin=MARGIN,
            rightMargin=MARGIN, topMargin=51, bottomMargin=49,
            title="Direct LLVM Implementation: Functions, Objects, Closures, and PicoCalc",
            author="Direct LLVM implementation project",
            subject="Architecture, implementation, validation, and undergraduate laboratories")
        frame_args = dict(x1=MARGIN, y1=49, width=CONTENT, height=HEIGHT-100,
                          leftPadding=0,rightPadding=0,topPadding=0,bottomPadding=0)
        self.addPageTemplates([
            PageTemplate(id="Cover",frames=[Frame(id="cover",**frame_args)],
                         onPage=cover,autoNextPageTemplate="Normal"),
            PageTemplate(id="Normal",frames=[Frame(id="normal",**frame_args)],
                         onPage=normal_page)])
        self.serial = 0
    def beforeDocument(self): self.serial = 0
    def afterFlowable(self, flow):
        if isinstance(flow, Paragraph) and flow.style.name == "h1":
            title = flow.getPlainText()
            if title == "Contents": return
            self.serial += 1
            key = f"chapter-{self.serial}"
            self.canv.bookmarkPage(key)
            self.canv.addOutlineEntry(title,key,level=0,closed=False)
            self.notify("TOCEntry",(0,title,self.page,key))

story = [Spacer(1,1),PageBreak(),Paragraph("Contents",S["h1"])]
toc = TableOfContents()
toc.levelStyles = [ParagraphStyle("toc",fontName="Head",fontSize=10.3,
    leading=17,spaceBefore=7,textColor=colors.HexColor(BLUE))]
story += [toc, Spacer(1,25), Paragraph(
    "This report explains the delivered implementation and the evidence that "
    "supports it. The accompanying source archive includes the complete source "
    "trees, a patch, exercises, raw logs and the detailed diary. Chapter 2 is "
    "the teaching core; Chapter 3 is the release evidence; Chapter 4 defines "
    "the remaining device integration boundary.",S["body"]),
    Paragraph("How to study the implementation",S["h2"]),
    Paragraph(
        "You should be comfortable with functions, pointers and basic data "
        "structures. Chapter 2 introduces intermediate representations, basic "
        "blocks, phi values, tagged values, roots, closure environments and ABI "
        "contracts. Its five exercises connect source programs to observable "
        "behavior. Chapter 5 gives the build and execution commands; Chapter 6 "
        "provides primary references and a guide to the source.",S["body"]),
    Paragraph(
        "Read the final evidence separately from the engineering diary. The "
        "diary preserves decisions, experiments, failures and fixes. Earlier "
        "failed attempts explain the work; only the identified final runs "
        "support the reported validation counts.",S["body"])]

lines = REPORT.splitlines()
i = 0
started = False
figures = 0
while i < len(lines):
    line = lines[i].strip()
    if not line:
        i += 1; continue
    if re.match(r"^\[\d+\]:",line):
        i += 1; continue
    if line.startswith("# "):
        if not re.match(r"# \d+\.",line):
            i += 1; continue
        started = True
        story += [PageBreak(),Paragraph(inline(line[2:]),S["h1"])]
        i += 1; continue
    if not started: i += 1; continue
    if line.startswith("## "):
        if line.startswith("## 1.3 "):
            story.append(PageBreak())
        story.append(Paragraph(inline(line[3:]),S["h2"]));i += 1;continue
    if line.startswith("### "):
        story.append(Paragraph(inline(line[4:]),S["h3"]));i += 1;continue
    if line.startswith("```"):
        kind = line[3:].strip()
        block = [];i += 1
        while i < len(lines) and not lines[i].strip().startswith("```"):
            raw = lines[i].expandtabs(4)
            if len(raw) > 110:
                lead = len(raw)-len(raw.lstrip())
                block.extend(textwrap.wrap(raw,width=110,
                    subsequent_indent=" "*min(lead+4,20),break_long_words=True,
                    break_on_hyphens=False,replace_whitespace=False,drop_whitespace=False))
            else: block.append(raw)
            i += 1
        i += 1
        if kind == "mermaid":
            figures += 1;story.append(diagram(figures))
        else:
            code = Preformatted("\n".join(block),S["code"])
            story.append(KeepTogether([code]) if len(block) < 57 else code)
        continue
    if line.startswith("|"):
        rows = []
        while i < len(lines) and lines[i].strip().startswith("|"):
            rows.append(lines[i]);i += 1
        story.append(table(rows));continue
    if line.startswith("> "):
        story.append(Paragraph(inline(line[2:]),S["quote"]));i += 1;continue
    if line.startswith("- ") or re.match(r"\d+\. ",line):
        number = re.match(r"(\d+)\. (.*)",line)
        prefix, text = (number[1]+".",number[2]) if number else ("-",line[2:])
        i += 1
        while i < len(lines) and lines[i].startswith("  ") and not lines[i].strip().startswith(("- ","```")):
            text += " " + lines[i].strip();i += 1
        story.append(Paragraph(prefix+" "+inline(text),S["bullet"]));continue
    para = [line];i += 1
    while i < len(lines) and lines[i].strip() and not lines[i].lstrip().startswith(
            ("#","```","|","> ","- ")) and not re.match(r"\d+\. ",lines[i].strip()):
        para.append(lines[i].strip());i += 1
    story.append(Paragraph(inline(" ".join(para)),S["body"]))

doc = Book(ARGS.output)
doc.multiBuild(story)
summary = {"markdown":str(HERE/"REPORT.md"),"pdf":str(ARGS.output),
           "words_approx":len(re.findall(r"\b[\w'-]+\b",REPORT)),
           "pages":doc.page,"vector_figures":figures}
(HERE / "evidence/report-build.json").write_text(json.dumps(summary,indent=2)+"\n")
print(json.dumps(summary,indent=2))
