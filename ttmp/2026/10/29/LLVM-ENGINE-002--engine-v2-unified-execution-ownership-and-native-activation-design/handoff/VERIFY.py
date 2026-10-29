#!/usr/bin/env python3
"""Verify packet payload hashes and source archive paths without extracting."""
import hashlib
import json
from pathlib import Path, PurePosixPath
import tarfile

root = Path(__file__).resolve().parent
manifest = json.loads((root / "MANIFEST.json").read_text())
for name, expected in manifest["files"].items():
    path = PurePosixPath(name)
    assert not path.is_absolute() and ".." not in path.parts, name
    actual = hashlib.sha256((root / name).read_bytes()).hexdigest()
    assert actual == expected, f"hash mismatch: {name}"
with tarfile.open(root / "source/current-code.tar.gz", "r:gz") as archive:
    members = archive.getmembers()
    for member in members:
        path = PurePosixPath(member.name)
        assert not path.is_absolute() and ".." not in path.parts, member.name
        assert member.isfile() or member.isdir() or member.issym(), member.name
        if member.issym():
            target = PurePosixPath(member.linkname)
            assert not target.is_absolute(), member.name
            depth = len(path.parent.parts)
            for part in target.parts:
                depth += -1 if part == ".." else (0 if part == "." else 1)
                assert depth >= 0, member.name
print(f"Verified {len(manifest['files'])} payload hashes and {len(members)} safe source entries")
