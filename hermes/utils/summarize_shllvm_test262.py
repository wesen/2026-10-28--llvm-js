#!/usr/bin/env python3
"""Validate completed Test262 report partitions and summarize failure ownership.

This summarizes an exploratory pinned-suite experiment, not an edition-qualified
conformance claim. Original per-variant reports remain authoritative evidence.
"""
import argparse
from collections import Counter, defaultdict
import hashlib
import json
import re
import subprocess
from pathlib import Path


def aggregate(reports):
    if not reports:
        raise ValueError('no reports')
    first = reports[0]
    identity_fields = ('suite_revision', 'specification', 'selection', 'hermes_opt',
                       'llvm_opt', 'fingerprints', 'host_limitations')
    partition_count = first['partition']['count']
    if partition_count < 1 or len(reports) != partition_count:
        raise ValueError('missing or extra partitions')
    partition_indices = set()
    identities = set()
    results = []
    fixtures = set()
    for report in reports:
        if not report['complete'] or report.get('changed_inputs') or report.get('suite_dirty_after'):
            raise ValueError('incomplete or changed-input report')
        if any(report[key] != first[key] for key in identity_fields):
            raise ValueError('incompatible suite, selection, optimization profile, or build')
        partition = report['partition']
        if partition['count'] != partition_count or not 0 <= partition['index'] < partition_count:
            raise ValueError('incompatible partition')
        if partition['index'] in partition_indices:
            raise ValueError('duplicate partition')
        partition_indices.add(partition['index'])
        if partition['selected_files_before_partition'] != first['partition']['selected_files_before_partition']:
            raise ValueError('incompatible selection size')
        actual = dict(Counter(r['status'] for r in report['results']))
        if actual != report['counts']:
            raise ValueError('result counts do not match records')
        if sum('variant' in r for r in report['results']) != report['planned_variants']:
            raise ValueError('planned variants do not match completed records')
        for fixture in report['fixtures']:
            if fixture in fixtures:
                raise ValueError('duplicate fixture')
            fixtures.add(fixture)
        for result in report['results']:
            key = (result['test'], result.get('variant'))
            if key in identities:
                raise ValueError('duplicate test/variant')
            identities.add(key)
            results.append(result)
        unique_files = {r['test'] for r in report['results']} | set(report['fixtures'])
        if len(unique_files) != partition['selected_files']:
            raise ValueError('selected files do not match result and fixture inventory')
    if sum(r['partition']['selected_files'] for r in reports) != first['partition']['selected_files_before_partition']:
        raise ValueError('partition union does not cover selection')
    return sorted(results, key=lambda r: (r['test'], r.get('variant', ''))), sorted(fixtures)


def failure_group(result):
    status = result['status']
    phase = result.get('observed_phase', 'host/preparation')
    if result.get('reason'):
        reason = result['reason']
    elif phase == 'compile':
        diagnostics = '\n'.join(c.get('stderr', '') for c in result.get('commands', []))
        boundaries = ('direct eval in a derived constructor is not supported',
                      'unsupported instruction',
                      'function exceeds 1024 combined root/argument-slot admission limit')
        # This is triage, not a declaration that arbitrary compiler failures
        # are specification-sanctioned rejections.
        reason = next((x for x in boundaries if x in diagnostics), 'compiler diagnostic requires review')
    elif phase == 'runtime':
        reason = 'runtime failure requires inspection of retained command evidence'
    else:
        reason = 'stage failure requires inspection of retained command evidence'
    return status, phase, reason


def summarize(results, fixtures):
    families = defaultdict(Counter)
    groups = defaultdict(list)
    features = defaultdict(Counter)
    for result in results:
        parts = result['test'].split('/')
        family = '/'.join(parts[:3])
        families[family][result['status']] += 1
        for feature in result.get('features', []):
            features[feature][result['status']] += 1
        if result['status'] != 'pass':
            groups[failure_group(result)].append({'test': result['test'], 'variant': result.get('variant')})
    return {
        'scope': 'exploratory pinned-suite selection; not an edition-qualified conformance claim',
        'variants_and_metadata_errors': len(results), 'fixture_files': len(fixtures),
        'counts': dict(Counter(r['status'] for r in results)),
        'families': dict(sorted(families.items())),
        'failure_groups': [dict(status=key[0], phase=key[1], reason=key[2],
                                count=len(values), examples=values[:10])
                           for key, values in sorted(groups.items(), key=lambda x: (-len(x[1]), x[0]))],
        'feature_ledger': {name: {'edition_membership': 'unreviewed', 'counts': counts}
                           for name, counts in sorted(features.items())},
        'edition_note': 'Feature labels alone do not establish edition membership; all entries require review.'}


def annotate_suite(summary, results, suite, revision):
    """Add source-reference candidates without reclassifying runtime results."""
    actual = subprocess.check_output(['git', '-C', str(suite), 'rev-parse', 'HEAD'], text=True).strip()
    if actual != revision:
        raise ValueError('annotation suite revision differs from reports')
    if subprocess.check_output(['git', '-C', str(suite), 'status', '--porcelain'], text=True).strip():
        raise ValueError('annotation suite checkout must be clean')
    catalog = suite / 'features.txt'
    sections = {'## Proposed language features': 'proposed',
                '## Standard language features': 'standard',
                '## Test-Harness Features': 'test-harness'}
    section = 'unknown'
    labels = {}
    for line in catalog.read_text().splitlines():
        if line in sections:
            section = sections[line]
        label = line.split('#', 1)[0].strip()
        if label:
            labels[label] = section
    summary['feature_catalog_sha256'] = hashlib.sha256(catalog.read_bytes()).hexdigest()
    for label, entry in summary['feature_ledger'].items():
        entry['pinned_catalog_category'] = labels.get(label, 'unlisted')
    cache = {}
    def read(relative, expected):
        path = (suite / relative).resolve()
        if not path.is_relative_to(suite):
            raise ValueError('source reference escapes suite')
        if relative not in cache:
            data = path.read_bytes()
            cache[relative] = (hashlib.sha256(data).hexdigest(), data.decode('utf-8'))
        digest, text = cache[relative]
        if digest != expected:
            raise ValueError('annotation source differs from executed input: ' + relative)
        return text
    candidates = defaultdict(list)
    for result in results:
        if result['status'] == 'pass':
            continue
        text = read(result['test'], result['source_sha256']) if 'source_sha256' in result else ''
        for relative, expected in result.get('includes', {}).items():
            text += '\n' + read(relative, expected)
        for helper in sorted(set(re.findall(r'\$262\.([A-Za-z_$][A-Za-z0-9_$]*)', text))):
            candidates[helper].append({'test': result['test'], 'variant': result.get('variant'),
                                       'status': result['status']})
    summary['host_reference_candidates'] = {name: {'count': len(values), 'examples': values[:10]}
                                             for name, values in sorted(candidates.items())}
    summary['host_reference_note'] = ('Textual references in failing source or harness are triage candidates, '
                                      'not proof of invocation or automatic result reclassification.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--suite', type=Path, help='pinned checkout for source/harness and feature-catalog annotation')
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('reports', type=Path, nargs='+')
    args = parser.parse_args()
    if any(args.output.resolve() == p.resolve() or
           (args.output.exists() and args.output.samefile(p)) for p in args.reports):
        parser.error('summary output must not overwrite an input report')
    try:
        reports = [json.loads(path.read_text()) for path in args.reports]
        results, fixtures = aggregate(reports)
    except (ValueError, KeyError, OSError) as exc:
        parser.error(str(exc))
    summary = summarize(results, fixtures)
    if args.suite:
        try:
            annotate_suite(summary, results, args.suite.resolve(), reports[0]['suite_revision'])
        except (ValueError, KeyError, OSError, subprocess.CalledProcessError) as exc:
            parser.error(str(exc))
    summary['summarizer_sha256'] = hashlib.sha256(Path(__file__).read_bytes()).hexdigest()
    summary['profile'] = {key: reports[0][key] for key in
                          ('suite_revision', 'specification', 'selection', 'hermes_opt', 'llvm_opt')}
    summary['reports'] = {str(p): hashlib.sha256(p.read_bytes()).hexdigest() for p in args.reports}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(summary, indent=2) + '\n')
    print(json.dumps(summary['counts'], sort_keys=True))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
