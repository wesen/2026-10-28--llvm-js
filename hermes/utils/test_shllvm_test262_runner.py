#!/usr/bin/env python3
"""Adversarial tests for the direct LLVM Test262 runner."""
import tempfile
from pathlib import Path
import unittest
from unittest.mock import patch

from test_shllvm_test262 import (classify, metadata, variants, prepare_source,
                                 unsupported_reason, invoke)


def record(code=0, stdout='', stderr='', **extra):
    return dict(exit_code=code, stdout=stdout, stderr=stderr, **extra)


class ClassificationTests(unittest.TestCase):
    def test_expected_error_requires_phase_and_actual_type(self):
        error = record(1, stderr='SHLLVM_TEST262_EXCEPTION:TypeError\n')
        self.assertEqual(classify(error, 'runtime', {'phase':'runtime','type':'TypeError'}), 'pass')
        self.assertEqual(classify(error, 'runtime', {'phase':'runtime','type':'ReferenceError'}), 'semantic_failure')
        self.assertEqual(classify(error, 'runtime', {'phase':'parse','type':'TypeError'}), 'semantic_failure')
        self.assertEqual(classify(record(), 'runtime', {'phase':'runtime','type':'TypeError'}), 'semantic_failure')

    def test_printed_error_is_not_error_identity(self):
        for text in ['Uncaught TypeError: pretend\n', 'SHLLVM_TEST262_EXCEPTION:INVALID\n']:
            self.assertEqual(classify(record(1, stderr=text), 'runtime',
                                     {'phase':'runtime','type':'TypeError'}), 'semantic_failure')

    def test_abnormal_process_never_satisfies_negative(self):
        expected = {'phase':'runtime', 'type':'TypeError'}
        for value, status in [(record(-11), 'crash'), (record(None, failure='timeout'), 'timeout'),
                              (record(1, stderr='ERROR: AddressSanitizer'), 'crash'),
                              (record(None, failure='infrastructure_error'), 'infrastructure_error')]:
            self.assertEqual(classify(value, 'runtime', expected), status)

    def test_compile_and_link_failures_are_not_language_errors(self):
        error = record(1, stderr='file.js:1:2: error: unsupported instruction')
        expected = {'phase':'parse', 'type':'SyntaxError'}
        self.assertEqual(classify(error, 'compile', expected), 'unsupported')
        self.assertEqual(classify(error, 'link', expected), 'infrastructure_error')
        self.assertEqual(classify(record(1, stderr='file.js:1:2: error: invalid expression'), 'parse', expected), 'pass')

    def test_async_requires_one_completion_and_no_failure(self):
        for output in ['', 'Test262:AsyncTestComplete\nTest262:AsyncTestComplete\n',
                       'Test262:AsyncTestComplete\nTest262:AsyncTestFailure:Error\n']:
            self.assertEqual(classify(record(stdout=output), 'runtime', asynchronous=True), 'semantic_failure')
        self.assertEqual(classify(record(stdout='Test262:AsyncTestComplete\n'), 'runtime', asynchronous=True), 'pass')

    def test_timeout_and_missing_command(self):
        with tempfile.TemporaryDirectory() as td:
            self.assertEqual(invoke(['/definitely/missing/shllvm-command'], 1, td)['failure'], 'infrastructure_error')
            self.assertEqual(invoke(['python3','-c','import time; time.sleep(10)'], .05, td)['failure'], 'timeout')


class PreparationTests(unittest.TestCase):
    def test_variants_and_missing_metadata(self):
        self.assertEqual(variants({}), ['sloppy','strict'])
        self.assertEqual(variants({'flags':['onlyStrict']}), ['strict'])
        self.assertEqual(variants({'flags':['raw']}), ['sloppy'])
        self.assertEqual(variants({'flags':['module']}), ['module'])
        with self.assertRaises(ValueError):
            metadata('var x;', 'missing.js')
        with self.assertRaises(ValueError):
            metadata('/*---\nflags: [onlyStrict, noStrict]\n---*/', 'bad.js')

    def test_raw_preserves_bytes_and_needs_no_harness(self):
        source = '#!/usr/bin/env js\r\n/*---\nflags: [raw]\n---*/\n'
        text, includes = prepare_source(source, {'flags':['raw']}, 'sloppy', Path('/missing'))
        self.assertEqual(text, source)
        self.assertEqual(includes, [])

    def test_include_missing_and_escape_are_errors(self):
        with tempfile.TemporaryDirectory() as td:
            suite = Path(td)
            (suite/'harness').mkdir()
            with self.assertRaises(OSError):
                prepare_source('', {}, 'sloppy', suite)
            with self.assertRaises(ValueError):
                prepare_source('', {'includes':['../../outside.js']}, 'sloppy', suite)

    def test_strict_directive_precedes_harness_without_function_wrapper(self):
        with tempfile.TemporaryDirectory() as td:
            suite = Path(td)
            (suite/'harness').mkdir()
            for name in ['sta.js','assert.js']:
                (suite/'harness'/name).write_text('// '+name)
            text, files = prepare_source('let lexical = 1;', {}, 'strict', suite)
            self.assertTrue(text.startswith('"use strict";\n'))
            self.assertTrue(text.endswith('let lexical = 1;'))
            self.assertEqual(len(files), 2)

    def test_explicit_host_boundaries(self):
        self.assertIn('module', unsupported_reason({'flags':['module']}))
        self.assertIn('cross-realm', unsupported_reason({'features':['cross-realm']}))
        self.assertIsNone(unsupported_reason({'features':['Symbol.species']}))


if __name__ == '__main__':
    unittest.main()
