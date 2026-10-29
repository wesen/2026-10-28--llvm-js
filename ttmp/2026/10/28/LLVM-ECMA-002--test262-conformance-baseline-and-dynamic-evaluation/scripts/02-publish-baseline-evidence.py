#!/usr/bin/env python3
"""Publish compact auditable evidence only from a complete single-profile report.

The complete raw report is retained as a compressed local build artifact. Git
receives every variant identity/status, all input fingerprints, and representative
failure commands, without duplicating command logs for every successful test.
"""
import argparse
from collections import Counter
import gzip
import hashlib
import json
from pathlib import Path
import shutil
import sys

ROOT = next(p for p in Path(__file__).resolve().parents
            if (p / 'hermes/utils/summarize_shllvm_test262.py').is_file())
sys.path.insert(0, str(ROOT / 'hermes/utils'))
from summarize_shllvm_test262 import aggregate, summarize, annotate_suite


def digest(path):
    value = hashlib.sha256()
    with path.open('rb') as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b''):
            value.update(chunk)
    return value.hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--report', type=Path, required=True)
    parser.add_argument('--suite', type=Path, required=True)
    parser.add_argument('--archive', type=Path, required=True)
    args = parser.parse_args()
    if args.archive.resolve() == args.report.resolve() or (args.archive.exists() and args.archive.samefile(args.report)):
        parser.error('archive must not replace the raw report')
    report = json.loads(args.report.read_text())
    try:
        results, fixtures = aggregate([report])
    except ValueError as exc:
        parser.error(str(exc))
    summary = summarize(results, fixtures)
    annotate_suite(summary, results, args.suite.resolve(), report['suite_revision'])
    evidence = Path(__file__).resolve().parents[1] / 'reference/evidence'
    evidence.mkdir(parents=True, exist_ok=True)
    args.archive.parent.mkdir(parents=True, exist_ok=True)
    with args.report.open('rb') as source, gzip.open(args.archive, 'wb') as target:
        shutil.copyfileobj(source, target, length=1024 * 1024)
    raw_hash = digest(args.report)
    receipt = {key: report[key] for key in ('complete', 'scope', 'suite_revision', 'specification',
               'selection', 'hermes_opt', 'llvm_opt', 'partition', 'execution',
               'planned_variants', 'counts', 'changed_inputs', 'suite_dirty_after', 'host_limitations')}
    receipt.update(raw_report_sha256=raw_hash, local_archive=str(args.archive.resolve()),
                   local_archive_sha256=digest(args.archive), publisher_sha256=digest(Path(__file__)),
                   summarizer_sha256=digest(ROOT / 'hermes/utils/summarize_shllvm_test262.py'),
                   runtime_source_commit='20fd0f6', runner_source_commit='fd08c16')
    summary['experiment'] = receipt
    samples = []
    sampled = Counter()
    with (evidence / 'full-baseline-results.jsonl').open('w') as out:
        for result in results:
            compact = {key:value for key,value in result.items() if key not in
                       ('commands', 'includes', 'artifacts', 'features', 'prepared_sha256')}
            out.write(json.dumps(compact, separators=(',', ':')) + '\n')
            key = ('/'.join(result['test'].split('/')[:3]), result['status'], result.get('observed_phase'))
            if result['status'] != 'pass' and sampled[key] < 2:
                samples.append(result)
                sampled[key] += 1
    for name, value in [('full-baseline-summary.json', summary),
                        ('full-baseline-inputs.json', report['fingerprints']),
                        ('full-baseline-failure-samples.json', samples),
                        ('full-baseline-fixtures.json', fixtures)]:
        (evidence / name).write_text(json.dumps(value, indent=2) + '\n')
    print(json.dumps(receipt, indent=2))


if __name__ == '__main__':
    main()
