from pathlib import Path
import re, json
root = next(p for p in Path(__file__).resolve().parents if (p / ".ttmp.yaml").exists())
ticket = Path(__file__).resolve().parent.parent
guide = next((ticket / "design-doc").glob("*.md"))
text = guide.read_text()
paths = sorted(set(re.findall(r"`((?:hermes/|ttmp/)[^`\n]+)`", text)))
missing = [p for p in paths if not (root / p).exists()]
result = {"checked_paths": paths, "missing_paths": missing,
          "words": len(text.split()), "mermaid_diagrams": text.count("```mermaid"),
          "balanced_fences": sum(line.startswith("```") for line in text.splitlines()) % 2 == 0}
print(json.dumps(result, indent=2))
raise SystemExit(bool(missing) or not result["balanced_fences"])
