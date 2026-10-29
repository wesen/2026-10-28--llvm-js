#!/usr/bin/env python3
"""Package pinned tracked source and current research documents; no engine changes."""
import argparse
import gzip
import hashlib
import io
import json
from pathlib import Path
import subprocess
import tarfile
import tempfile
import zipfile

BASELINE = '87d4658c4ed27aee42ddf4e023f9e9666ef3a2a1'
TICKET = 'ttmp/2026/10/29/LLVM-ENGINE-002--engine-v2-unified-execution-ownership-and-native-activation-design'

def digest(data):
    return hashlib.sha256(data).hexdigest()

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repo', type=Path, default=Path.cwd())
    parser.add_argument('--ticket', type=Path, help='Defaults to the ticket in --repo')
    parser.add_argument('--output', type=Path, help='Defaults to ticket/deliverables')
    args = parser.parse_args()
    repo = args.repo.resolve()
    ticket = args.ticket.resolve() if args.ticket else repo / TICKET
    output = args.output.resolve() if args.output else ticket / 'deliverables'
    output.mkdir(parents=True, exist_ok=True)
    def git(*command):
        return subprocess.check_output(['git', '-C', str(repo), *command])
    commit = git('rev-parse', BASELINE + '^{commit}').decode().strip()
    tree = git('ls-tree', '-r', '-z', commit).split(b'\0')
    inventory = {}
    for entry in filter(None, tree):
        info, path = entry.split(b'\t', 1)
        mode, kind, oid = info.decode().split()
        if kind != 'blob':
            raise RuntimeError('Unsupported source entry: ' + entry.decode())
        inventory[path.decode()] = {'mode': mode, 'git_blob': oid}
    raw = git('archive', '--format=tar', commit)
    with tarfile.open(fileobj=io.BytesIO(raw)) as archive:
        exported = {m.name for m in archive.getmembers() if not m.isdir()}
    if exported != set(inventory):
        raise RuntimeError('Git archive and tracked inventory disagree')
    files = {'source/current-code.tar.gz': gzip.compress(raw, mtime=0)}
    files['source/SOURCE.json'] = (json.dumps({
        'commit': commit,
        'tracked_files': len(inventory),
        'scope': 'Entire tracked repository; no git database, untracked files or installed build dependencies',
        'archive_sha256': digest(files['source/current-code.tar.gz']),
        'inventory': inventory,
    }, indent=2, sort_keys=True) + '\n').encode()
    for path in sorted((ticket / 'design-doc').glob('0[123]-*.md')):
        files['documents/' + path.name] = path.read_bytes()
    if len([n for n in files if n.startswith('documents/')]) != 3:
        raise RuntimeError('Expected all three design documents')
    for path in sorted((ticket / 'handoff').rglob('*')):
        if path.is_file() and '__pycache__' not in path.parts:
            relative = path.relative_to(ticket / 'handoff')
            if relative.name[:2].isdigit() and relative.name[2:3] == '-':
                relative = relative.with_name(relative.name[3:])
            files[relative.as_posix()] = path.read_bytes()
    files['tools/01-build-seminar-package.py'] = Path(__file__).read_bytes()
    manifest = {
        'format': 1, 'ticket': 'LLVM-ENGINE-002', 'assignment': 'Design research only',
        'source_commit': commit,
        'files': {name: digest(data) for name, data in sorted(files.items())},
    }
    files['MANIFEST.json'] = (json.dumps(manifest, indent=2, sort_keys=True) + '\n').encode()
    destination = output / 'LLVM-ENGINE-002-design-seminar-handoff.zip'
    with zipfile.ZipFile(destination, 'w') as z:
        for name, data in sorted(files.items()):
            entry = zipfile.ZipInfo(name, (2026, 10, 29, 0, 0, 0))
            entry.create_system = 3
            entry.external_attr = 0o100644 << 16
            entry.compress_type = zipfile.ZIP_STORED if name.endswith('.gz') else zipfile.ZIP_DEFLATED
            z.writestr(entry, data)
    with zipfile.ZipFile(destination) as z:
        assert z.testzip() is None
        with tempfile.TemporaryDirectory(prefix='llvm-seminar-verify-') as tmp:
            z.extractall(tmp)
            subprocess.run(['python3', str(Path(tmp) / 'VERIFY.py')], check=True)
    sha = digest(destination.read_bytes())
    destination.with_suffix('.zip.sha256').write_text(sha + '  ' + destination.name + '\n')
    receipt = {'archive': destination.name, 'bytes': destination.stat().st_size,
               'sha256': sha, 'source_commit': commit, 'source_files': len(inventory),
               'payload_files': len(files), 'checks': ['git inventory equality', 'ZIP CRC', 'payload SHA-256', 'safe source paths']}
    (output / 'package-receipt.json').write_text(json.dumps(receipt, indent=2) + '\n')
    print(json.dumps(receipt, indent=2))

if __name__ == '__main__':
    main()
