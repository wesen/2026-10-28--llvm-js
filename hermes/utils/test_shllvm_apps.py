#!/usr/bin/env python3
"""Check that the application harness rejects incomplete and incorrect runs."""
import json
from pathlib import Path
import tempfile
from types import SimpleNamespace
import unittest
from qualify_shllvm_apps import Campaign, MARKER


class ResultContracts(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.campaign = Campaign(SimpleNamespace(output=Path(self.temp.name)/'result.json', timeout=1))
        self.expected = {'application': 'data-pipeline', 'accepted': 1}

    def process(self, value=None, marker=True, code=0):
        return {'returncode': code, 'stdout': json.dumps(value or self.expected) + '\n' +
                (MARKER + '\n' if marker else ''), 'stderr': ''}

    def test_complete_result(self):
        self.assertEqual(self.campaign.result(self.process(), 'data-pipeline', self.expected, True)[0], 'pass')

    def test_zero_exit_without_completion(self):
        self.assertEqual(self.campaign.result(self.process(marker=False), 'data-pipeline', self.expected, True)[0], 'missing-completion')

    def test_wrong_total(self):
        self.assertEqual(self.campaign.result(self.process({'application': 'data-pipeline', 'accepted': 2}), 'data-pipeline', self.expected, True)[0], 'oracle-mismatch')

    def test_failed_process_cannot_publish_success(self):
        self.assertEqual(self.campaign.result(self.process(code=1), 'data-pipeline', self.expected, True)[0], 'process-failure')

    def test_duplicate_results(self):
        p = self.process()
        p['stdout'] += json.dumps(self.expected) + '\n'
        self.assertEqual(self.campaign.result(p, 'data-pipeline', self.expected, True)[0], 'missing-or-duplicate-result')

    def test_timeout_cannot_publish_success(self):
        p = self.process(); p['timeout'] = True
        self.assertEqual(self.campaign.result(p, 'data-pipeline', self.expected, True)[0], 'timeout')

if __name__ == '__main__':
    unittest.main()
