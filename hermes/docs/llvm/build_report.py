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
    feature = HERE / "feature-work"
    matrix = json.loads((feature / "core-final-validation.json").read_text())
    extension = json.loads((feature / "extension-final-validation.json").read_text())
    driver = json.loads((feature / "driver-final-validation.json").read_text())
    lexical = json.loads((feature / "lexical-defaults-final-validation.json").read_text())
    # The report is a view of completed evidence, never a substitute for it.
    assert matrix["source_cases"] == matrix["passed_cases"]
    assert matrix["failed_cases"] == 0
    assert extension["source_cases"] == extension["passed_cases"]
    assert extension["failed_cases"] == 0 and extension["skipped_cases"] == 0
    assert extension["input_files_unchanged"] and not extension["partial_gate"]
    assert driver["passed"] == driver["total"]
    assert lexical["passed"] == lexical["total"]

    def count_records(data, stage, kind=None):
        return sum(record.get("stage") == stage
                   for result in data["results"]
                   if kind is None or result["kind"] == kind
                   for record in result["records"])

    core_kinds = {
        kind: sum(result["kind"] == kind for result in matrix["results"])
        for kind in ["positive", "runtime-error", "compile-rejection"]
    }
    positive_runs = count_records(extension, "llvm-run", "positive")
    error_runs = count_records(extension, "llvm-run", "runtime-error")
    rejected_runs = extension["native_llvm_expected_rejections"]
    rows = [
        "| Evidence layer | Recorded final outcome | Scope |",
        "|---|---|---|",
        f"| Core source cases | {matrix['passed_cases']} / {matrix['source_cases']} passed | "
        f"{core_kinds['positive']} positive, {core_kinds['runtime-error']} runtime-error, "
        f"{core_kinds['compile-rejection']} compile-rejection contracts |",
        f"| Core native comparisons | {matrix['native_llvm_vs_node_and_c_comparisons']} passed | "
        "Hermes O0/O, LLVM O0/O2; Node and patched C backend |",
        f"| Core JIT and errors | {count_records(matrix, 'lli-jit')} JIT; "
        f"{count_records(matrix, 'runtime-error')} runtime-error executions passed | "
        "Separate execution contracts |",
        f"| Extension source cases | {extension['passed_cases']} / {extension['source_cases']} passed | "
        f"{extension['positive_cases']} positive, {extension['runtime_error_cases']} language-error, "
        f"{extension['runtime_rejection_cases']} explicit runtime-boundary, "
        f"{extension['compile_error_cases']} compile-error contracts |",
        f"| Extension native execution | {positive_runs} output comparisons; "
        f"{error_runs} language-error checks; {rejected_runs} expected rejections | "
        "Four frontend/LLVM combinations per executable fixture |",
        f"| Extension LLVM JIT | {extension['lli_vs_node_matches']} Node-contract matches; "
        f"{extension['lli_expected_rejections']} expected rejections | "
        "Real lli execution at Hermes O / LLVM O2 |",
        f"| Compiler publication checks | {driver['passed']} / {driver['total']} passed | "
        "Default/stdout/exported output, C bypass and preservation on failure |",
        f"| Raw lexical-default checks | {lexical['passed']} / {lexical['total']} passed | "
        "Default behavior, explicit overrides and static TDZ diagnostic |",
        "| RV32 integer-world regression | Earlier 24 / 24 verified; unchanged lane | "
        "200 C-vs-LLVM event comparisons, 160 original Node oracle events |",
        "| RV32 replay artifacts | 6 verified modules; 11 trace records | "
        "Linked ELF images, instruction execution and reload trace |",
    ]
    intro = (HERE / "REPORT_INTRO.md").read_text()
    intro = intro.split("## 1.5 How to use this report", 1)[0]
    example = (ROOT / "examples/llvm/counter.js").read_text().strip()
    output = (HERE / "evidence/counter-native.txt").read_text().strip()
    assert output == (HERE / "evidence/counter-jit.txt").read_text().strip()
    intro = intro.replace("<!-- COUNTER_SOURCE -->", "```javascript\n" + example + "\n```")
    intro = intro.replace("<!-- COUNTER_OUTPUT -->", "```text\n" + output + "\n```")
    arch, refs = (HERE / "ARCHITECTURE.md").read_text().split(
        "## References and source-reading guide", 1)
    arch = numbered_chapter(arch, 2, "Architecture and implementation")
    arch = re.sub(r"Section (\d+)", r"Section 2.\1", arch)
    validation = (HERE / "REPORT_VALIDATION.md").read_text()
    validation = validation.replace("<!-- VALIDATION_TABLE -->", "\n".join(rows))
    validation = validation.replace("`picocalc/logs/", "`picocalc-llvm-poc/logs/")
    validation += (
        "\n## 3.8 Extension evidence and oracle boundaries\n\n"
        "The final extension gate used no selection filter, quick mode, "
        "JIT skip or oracle-only option. It recorded unchanged source and "
        "binary fingerprints before and after execution. The positive "
        "fixture output, expected exception classes, explicit unsupported "
        "boundaries and output-publication checks remain separate records. "
        "A rejected Node-valid program is a passing rejection contract, "
        "not a passing JavaScript semantic comparison.\n\n"
        f"The updated core suite supplied {matrix['native_llvm_vs_node_and_c_comparisons']} "
        f"native comparisons and the extension suite supplied {positive_runs}. "
        "The latter includes lexical-eval cases compared directly with Node "
        "because the inherited C helper lacks caller environment semantics. "
        "For ordinary shared features, C and LLVM use the same rebuilt "
        "runtime including the Promise, async-generator and typed-array fixes.\n\n"
        "The compiler and runtime were built with AddressSanitizer; leak "
        "checking was disabled only for the documented sandbox restriction. "
        "The pinned Release build makes the upstream Hermes IR verifier a "
        "no-op unless HERMES_SLOW_DEBUG is enabled. The wrapper's LLVM "
        "assembly and opt verification are real structural checks, and "
        "the executions are real host native/JIT runs.\n"
    )
    if extension["c_oracle_limitations"]:
        validation += (
            "\nThe machine-readable result explicitly lists these C-oracle "
            "limitations; they are not reported as matched C executions:\n\n"
        )
        for item in extension["c_oracle_limitations"]:
            name = item.get("name", item.get("case", "fixture"))
            reason = item.get("reason", item.get("c_oracle_reason", "see fixture metadata"))
            validation += f"- `{name}`: {reason}\n"
    integration_source = (HERE / "PICOCALC_INTEGRATION.md").read_text()
    integration_source = integration_source.split("## Source references", 1)[0]
    integration_source += (
        "\nSource-reading pointers for these contracts are collected in "
        "Chapter 6. The standalone integration chapter retains its local "
        "reference list. This extension phase did not modify that lane.\n")
    integration = numbered_chapter(
        integration_source, 4, "PicoCalc integration and the device boundary")
    driver_text = numbered_chapter((HERE / "DRIVER.md").read_text(), 5,
                                  "Build, inspect, execute, and reproduce")
    driver_text += r"""

## 5.7 Release layout and exact patch reproduction

The archive contains `hermes/` and `picocalc-llvm-poc/` source trees,
`Static-Hermes-direct-LLVM.patch`, the PDF report, consolidated diary,
`PROVENANCE.json` and `SHA256SUMS.txt`. Host commands run from `hermes/`.
Build directories, downloaded toolchain binaries, Git history and Node
dependencies are omitted; rebuild those for the local installation.

The patch applies to Static Hermes commit
`f837b9dd8396ebf5c4e8115412417d273565f0fe`. Reproduction was checked with
separate Git indexes: applying the patch to the exact base produced the
same source tree as the packaged modifications, without staging the
working repository. The recorded patch hash and resulting tree identity
are in `PROVENANCE.json`. Every packaged ZIP member was read back with CRC
and SHA-256 checks.

`docs/llvm/feature-work/` preserves the extension diary, original failures,
final test records and input identities. The old `evidence/` directory
preserves the first release's tests and toolchain provenance. These are
different stages of the same project; only the named final records support
the current host counts.

Regenerate the PDF with `python3 docs/llvm/build_report.py` using ReportLab
and DejaVu fonts. The script reads completed final evidence and refuses
failed, partial or changed-input extension gates. It renders documentation;
it does not manufacture test results or rerun the compiler.
"""
    references = "# 6. References and source-reading guide\n" + refs
    references += """

## How to connect source and evidence

Chapter 7 adds source pointers for generator lowering, Promise jobs,
typed-array properties and lexical evaluation. Follow each bridge call to
the runtime implementation when a header declaration does not establish
allocation or lifetime behavior. The test harness defines exactly which
outputs and errors are compared.

The official [LLVM garbage-collection documentation](https://releases.llvm.org/18.1.8/docs/GarbageCollection.html)
provides a useful comparison with this explicit-root design. The current
emitter does not use LLVM statepoints or coroutine intrinsics. The
[ECMAScript specification](https://tc39.es/ecma262/) describes the language;
the delivered source and targeted tests establish what this implementation
actually supports.
"""
    extensions = numbered_chapter((HERE / "LANGUAGE_EXTENSIONS.md").read_text(), 7,
                                  "Language extensions and dynamic evaluation")
    result = "# Direct LLVM Implementation: JavaScript Language Extensions and PicoCalc\n\n"
    result += "Technical report and undergraduate compiler laboratory. 28 October 2026.\n\n"
    result += "\n\n".join([intro, arch, validation, integration,
                           driver_text, references, extensions])
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
    # Compact protocol/state tables read best as one unit. Long tables still
    # split with their header repeated on the following page.
    return KeepTogether([t]) if len(rows) <= 5 else t

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
        arrow(d,right+w/2,110,right+w/2,132)
        arrow(d,left+w,34,right+20,74)
        cap = "Figure 1. The direct emitter branches before C-specific register allocation. Generated functions call the prebuilt bridge; the C backend provides a second code-generation path using the same runtime."
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
    canvas.drawString(MARGIN,HEIGHT-286,"Generators, async code, values, and dynamic eval")
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
            title="Direct LLVM Implementation: Language Extensions and PicoCalc",
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
    "the remaining device integration boundary. Chapter 7 explains generators, "
    "async execution, richer values and lexical eval.",S["body"]),
    Paragraph("How to study the implementation",S["h2"]),
    Paragraph(
        "You should be comfortable with functions, pointers and basic data "
        "structures. Chapter 2 introduces intermediate representations, basic "
        "blocks, phi values, tagged values, roots, closure environments and ABI "
        "contracts. Its five exercises connect source programs to observable "
        "behavior. Chapter 5 gives the build and execution commands; Chapter 6 "
        "provides primary references and a guide to the source. Chapter 7 adds "
        "six exercises connecting language extensions to runtime behavior.",S["body"]),
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
(HERE / "feature-work/report-build.json").write_text(json.dumps(summary,indent=2)+"\n")
print(json.dumps(summary,indent=2))
