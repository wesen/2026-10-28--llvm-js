#!/usr/bin/env python3
import unittest
from summarize_shllvm_test262 import aggregate, summarize


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


if __name__ == '__main__':
    unittest.main()
