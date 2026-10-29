#!/usr/bin/env python3
import unittest
import tempfile
import hashlib
from pathlib import Path
from unittest.mock import patch
from summarize_shllvm_test262 import aggregate, summarize, annotate_suite


def report(index=0):
    return dict(complete=True, changed_inputs=[], suite_dirty_after=False,
                suite_revision='pin', specification='edition', selection=['test'],
                hermes_opt='O0', llvm_opt='0', fingerprints={'compiler':'hash'},
                host_limitations=['modules'], partition=dict(count=2, index=index,
                    selected_files_before_partition=2, selected_files=1),
                planned_variants=1, counts={'pass':1}, fixtures=[],
                results=[dict(test=f'test/language/{index}.js', variant='sloppy',status='pass',features=['feature'])])


class SummaryTests(unittest.TestCase):
    def test_complete_union_and_explicit_membership(self):
        results, fixtures = aggregate([report(1), report(0)])
        self.assertEqual(len(results), 2)
        summary = summarize(results, fixtures)
        self.assertEqual(summary['counts'], {'pass':2})
        self.assertEqual(summary['feature_ledger']['feature']['edition_membership'], 'unreviewed')

    def test_invalid_experiments_rejected(self):
        for mutate in [lambda r:r.update(complete=False),
                       lambda r:r.update(changed_inputs=['compiler']),
                       lambda r:r.update(suite_dirty_after=True),
                       lambda r:r.update(llvm_opt='2'),
                       lambda r:r.update(fingerprints={'compiler':'other'}),
                       lambda r:r.update(counts={'pass':2}),
                       lambda r:r.update(planned_variants=2),
                       lambda r:r['partition'].update(selected_files=2),
                       lambda r:r['partition'].update(index=0),
                       lambda r:r['results'][0].update(test='test/language/0.js')]:
            a, b = report(0), report(1)
            mutate(b)
            with self.subTest(report=b), self.assertRaises(ValueError):
                aggregate([a,b])
        with self.assertRaises(ValueError):
            aggregate([report(0)])

    def test_fixture_and_empty_partition(self):
        a, b = report(0), report(1)
        a.update(planned_variants=0, results=[], counts={}, fixtures=['test/fixture_FIXTURE.js'])
        b['partition']['selected_files_before_partition'] = 1
        a['partition']['selected_files_before_partition'] = 1
        b['partition']['selected_files'] = 0
        b.update(planned_variants=0, results=[], counts={})
        results, fixtures = aggregate([a,b])
        self.assertEqual(results, [])
        self.assertEqual(fixtures, ['test/fixture_FIXTURE.js'])

    def test_annotations_verify_source_and_keep_categories_distinct(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            (root / 'test').mkdir()
            (root / 'features.txt').write_text('## Proposed language features\nproposal-x\n')
            source = root / 'test/probe.js'
            source.write_text('// $262.createRealm reference candidate\n')
            result = dict(test='test/probe.js', variant='sloppy', status='semantic_failure',
                          source_sha256=hashlib.sha256(source.read_bytes()).hexdigest(),
                          features=['proposal-x'])
            summary = summarize([result], [])
            with patch('summarize_shllvm_test262.subprocess.check_output', side_effect=['pin', '']):
                annotate_suite(summary, [result], root, 'pin')
            self.assertEqual(summary['feature_ledger']['proposal-x']['pinned_catalog_category'], 'proposed')
            self.assertEqual(summary['feature_ledger']['proposal-x']['edition_membership'], 'unreviewed')
            self.assertEqual(summary['host_reference_candidates']['createRealm']['count'], 1)
            self.assertEqual(summary['counts'], {'semantic_failure':1})
            source.write_text('changed')
            with patch('summarize_shllvm_test262.subprocess.check_output', side_effect=['pin', '']), self.assertRaisesRegex(ValueError, 'differs'):
                annotate_suite(summary, [result], root, 'pin')
            with patch('summarize_shllvm_test262.subprocess.check_output', side_effect=['pin', ' M features.txt']), self.assertRaisesRegex(ValueError, 'clean'):
                annotate_suite(summary, [result], root, 'pin')


if __name__ == '__main__':
    unittest.main()
