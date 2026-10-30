#!/usr/bin/env python3
"""Restore the original Strata workspace and verify its recorded identity."""
from pathlib import Path, PurePosixPath
import hashlib
import json
import stat
import zipfile

root = Path(__file__).resolve().parents[1]
manifest = json.loads((root / 'reference/import-manifest.json').read_text())
archive = root / 'archive/strata-workspace-full.zip'
assert hashlib.sha256(archive.read_bytes()).hexdigest() == manifest['sha256']
expected = {entry['path']: entry for entry in manifest['entries']}
destination = root / 'source'
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None, 'ZIP CRC failure'
    names = [i.filename for i in z.infolist() if not i.is_dir()]
    assert len(names) == len(set(names)) and set(names) == set(expected)
    for info in z.infolist():
        path = PurePosixPath(info.filename)
        assert not path.is_absolute() and '..' not in path.parts
        assert not stat.S_ISLNK(info.external_attr >> 16)
        if info.is_dir():
            continue
        data = z.read(info)
        entry = expected[info.filename]
        assert len(data) == entry['bytes']
        assert hashlib.sha256(data).hexdigest() == entry['sha256']
        target = destination.joinpath(*path.parts)
        assert not target.is_symlink()
        assert target.resolve().is_relative_to(destination.resolve())
        if target.exists():
            assert target.read_bytes() == data, f'Refusing to overwrite modified import: {target}'
        else:
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
        assert hashlib.sha256(target.read_bytes()).hexdigest() == entry['sha256']
print(f"Verified original ZIP and {len(expected)} extracted files")
