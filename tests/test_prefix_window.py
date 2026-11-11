"""Protect ordered prefixes, observed retained strides, modular domains and partial coverage."""
import copy
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
import check_prefix_window as prefix_check
import check_prefix_window_strides as stride_check
import mathematical_ledger as ledger
from prefix_window_examples import expected, plans, fold_decimal


class PrefixWindowTests(unittest.TestCase):
    def test_arbitrary_axis_positions_and_nonzero_retained_stride_outputs(self):
        counts, rows, casts = expected()
        self.assertEqual((len(counts), len(rows), len(casts)), (726, 1290, 45))
        profiles = [p for rank in range(1, 4) for p in plans(rank)]
        self.assertEqual({p[2] for p in profiles if len(p[0]) == 3}, {0, 1, 2})
        profile = profiles.index(((2, 3, 2), (2, 1, 2), 1))
        self.assertEqual(next(r for r in rows if r['profile'] == profile and r['index'] == 2)['prefix'],
                         [1, 3, 5])
        self.assertTrue(all(c['outputs'] == 0 for c in counts if c['scan'] == 0))
        self.assertTrue(any(c['outputs'] > 0 and c['outputs'] < c['inputs'] for c in counts))
        supplement = ledger.read('reports/prefix-window-stride-controls.json')
        stride_check.validate_result(supplement)
        self.assertEqual([r['direct'] for r in supplement['controls']],
                         [[5, 6], [3, 6], [21, 24, 27], [21, 24]])
        changed = copy.deepcopy(supplement)
        changed['controls'][0]['direct'] = [3, 4]
        with self.assertRaises(AssertionError):
            stride_check.validate_result(changed)

    def test_modular_products_and_exact_unsigned_signed_conversion_domains(self):
        _, rows, casts = expected()
        self.assertTrue(any(r['count'] == 4 and r['count2u'] == 0 for r in rows))
        self.assertTrue(any(r['count'] == 2 and r['count2s'] == -2 for r in rows))
        self.assertTrue(all(r['product2'] == (3 * r['count']) % 4 for r in rows))
        self.assertTrue(any(r['padding'] and r['source'] != fold_decimal(r['prefix'], 7)
                            for r in rows))
        self.assertTrue(all(r['neutral'] == r['prefix_fold'] for r in rows))
        for row in casts:
            count, width = row['count'], row['width']
            self.assertEqual(row['unsigned'] == count, count < 2**width)
            self.assertEqual(row['signed'] == count, 2 * count < 2**width)
        for width in (32, 64):
            boundary = next(r for r in casts if r['width'] == width and r['count'] == 2**(width-1))
            self.assertEqual(boundary['signed'], -2**(width-1))

    def test_padding_count_or_domain_mutation_and_source_drift_are_rejected(self):
        result = ledger.read('reports/prefix-window.json')
        prefix_check.validate_result(result)
        changed = copy.deepcopy(result)
        row = next(r for r in changed['controls'] if r['padding'])
        row['trace'] = row['prefix']
        with self.assertRaises(AssertionError):
            prefix_check.validate_result(changed)
        changed = copy.deepcopy(result)
        changed['conversion_controls'][-1]['signed'] = changed['conversion_controls'][-1]['count']
        with self.assertRaises(AssertionError):
            prefix_check.validate_result(changed)
        changed = copy.deepcopy(result)
        changed['counterexample_certificates'].pop()
        with self.assertRaises(AssertionError):
            prefix_check.validate_result(changed)
        original = prefix_check.digest
        for suffix in ('PrefixWindow.lean', 'PrefixWindowStride.lean', 'PrefixWindowTarget.lean',
                       'PrefixWindowSampling.lean', 'PrefixWindowArithmetic.lean',
                       'PrefixWindowProof.lean', 'PrefixWindowInteger.lean',
                       'PrefixWindowCounterexamples.lean', 'LatticeIndex.lean',
                       'PrefixWindowControls.lean', 'prefix_window_examples.py',
                       'reduction-window-domains-v2.json', 'reduction-window-domains-v3.json',
                       'lean-toolchain', 'lake-manifest.json'):
            def changed_digest(path):
                return 'changed' if str(path).endswith(suffix) else original(path)
            with patch.object(prefix_check, 'digest', side_effect=changed_digest):
                with self.assertRaises(AssertionError):
                    prefix_check.check_inputs()

    def test_cumulative_core_is_not_whole_record_or_rounded_arithmetic_closure(self):
        result = ledger.read('reports/prefix-window.json')
        for key in prefix_check.TRUE_FIELDS + prefix_check.FALSE_FIELDS:
            changed = copy.deepcopy(result)
            changed[key] = not changed[key]
            with self.assertRaises(AssertionError):
                prefix_check.validate_result(changed)
        model = next(m for m in ledger.mathematical_models()
                     if m['model'] == 'ordered_prefix_window_integer_domains_v1')
        self.assertFalse(model['full_family_complete'])
        self.assertFalse(model['rounded_uniform_sum_product_proved'])
        certificates = [r for r in ledger.evidence() if 'prefix_window_contract_refutation' in r['kinds']]
        self.assertEqual(len(certificates), 3)
        self.assertTrue(all(not r['historical_candidate_benchmark_labels'] for r in certificates))
        progress = ledger.read('census/mathematical-ledger.json')
        self.assertEqual(progress['whole_benchmark_records_closed'], 0)
        self.assertIsNone(progress['mathematical_obligation_denominator'])
        domains = ledger.read('census/reduction-window-domains-v3.json')
        self.assertEqual(len(domains['records']), 31)
        self.assertEqual(sum(bool(r['core_evidence']) for r in domains['records']), 26)
        residual = [r for r in domains['records'] if not r['core_evidence']]
        self.assertEqual(len(residual), 5)
        self.assertEqual(sum('/pad-broadcast-' in r['benchmark_id'] for r in residual), 4)
        self.assertFalse(any(r['whole_record_closed'] for r in domains['records']))


if __name__ == '__main__':
    unittest.main()
