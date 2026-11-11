"""Protect full-span ordering, empty/scalar behavior, source pins and partial coverage."""
import copy
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
import check_full_span_window as full
import mathematical_ledger as ledger
from full_span_window_examples import expected, plans


class FullSpanWindowTests(unittest.TestCase):
    def test_mixed_axes_retain_original_order_without_combining_kept_coordinates(self):
        counts, rows = expected()
        self.assertEqual((len(counts), len(rows)), (585, 1111))
        profiles = [plan for rank in range(4) for plan in plans(rank)]
        profile = profiles.index(((2, False), (2, True), (3, False)))
        mixed = [r for r in rows if r['profile'] == profile]
        self.assertEqual([r['trace'] for r in mixed],
                         [[1, 2, 3, 7, 8, 9], [4, 5, 6, 10, 11, 12]])
        self.assertTrue(any(r['inputs'] == 0 and r['outputs'] == 1 and r['kernels'] == 0
                            for r in counts))
        self.assertTrue(any(r['outputs'] == 0 for r in counts))
        self.assertEqual(rows[0]['trace'], [1])
        self.assertEqual(rows[0]['window'], 71)
        self.assertTrue(all(r['window'] == 7 for r in rows if not r['trace']))

    def test_order_or_initializer_mutations_are_rejected(self):
        result = ledger.read('reports/full-span-window.json')
        full.validate_result(result)
        changed = copy.deepcopy(result)
        row = next(r for r in changed['controls'] if r['trace'] == [1, 2])
        self.assertEqual(row['window'], 712)
        row['trace'].reverse()
        row['window'] = 721
        with self.assertRaises(AssertionError):
            full.validate_result(changed)
        changed = copy.deepcopy(result)
        next(r for r in changed['controls'] if r['trace'] == [1, 2])['reshape'] = 12
        with self.assertRaises(AssertionError):
            full.validate_result(changed)
        changed = copy.deepcopy(result)
        changed['certificate_axioms'].popitem()
        with self.assertRaises(AssertionError):
            full.validate_result(changed)

    def test_transports_sampler_fold_and_reshape_definitions_are_pinned(self):
        original = full.digest
        for suffix in ('FullSpanWindow.lean', 'FullSpanWindowLemmas.lean',
                       'FullSpanWindowProof.lean', 'OrderedCoordinates.lean',
                       'ReductionWindow.lean', 'Reduction.lean', 'Reshape.lean',
                       'LinearIndex.lean', 'FiniteProduct.lean',
                       'FullSpanWindowControls.lean', 'full_span_window_examples.py',
                       'check_full_span_window.py', 'lake-manifest.json'):
            def changed(path):
                return 'changed' if str(path).endswith(suffix) else original(path)
            with patch.object(full, 'digest', side_effect=changed):
                with self.assertRaises(AssertionError):
                    full.check_inputs()

    def test_canonical_subprofile_cannot_close_the_window_family(self):
        result = ledger.read('reports/full-span-window.json')
        for key in full.TRUE_FIELDS + full.FALSE_FIELDS:
            changed = copy.deepcopy(result)
            changed[key] = not changed[key]
            with self.assertRaises(AssertionError):
                full.validate_result(changed)
        model = next(m for m in ledger.mathematical_models()
                     if m['model'] == 'ordered_full_span_window_reduction_reshape_v1')
        self.assertFalse(model['full_family_complete'])
        self.assertTrue(model['ordered_contribution_lists_equal'])
        progress = ledger.read('census/mathematical-ledger.json')
        case = next(r for r in progress['benchmark_records']
                    if r['benchmark_id'] == 'HandleReduceWindow/full-dimensions')
        self.assertEqual(case['mathematical_target_status'],
                         'partial_model_evidence_requires_partition_review')
        self.assertEqual(len(case['evidence']), 2)
        self.assertFalse(case['whole_record_mathematically_closed'])
        self.assertIsNone(progress['mathematical_obligation_denominator'])
        self.assertEqual(progress['whole_benchmark_records_closed'], 0)


if __name__ == '__main__':
    unittest.main()
