"""Protect empty geometry, explicit/implicit fill distinctions, conversion and partial coverage."""
import copy
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
import check_pad_window as fusion
import mathematical_ledger as ledger
from pad_window_examples import expected, profiles, WINDOWS


class PadWindowTests(unittest.TestCase):
    def test_materialized_oracle_observes_empty_inputs_and_two_levels_of_dilation(self):
        counts, rows = expected()
        self.assertEqual((len(counts), len(rows)), (655, 3043))
        profile = profiles().index(([(0, 1, 1, 1)], [WINDOWS[3]]))
        self.assertEqual(counts[profile]['outputs'], 5)
        # The naive high edge has one extra output here; the occupied input is empty.
        self.assertEqual(counts[profile]['fused'], 5)
        self.assertTrue(all(all(value == -3 for value in r['trace'])
                            for r in rows if r['profile'] == profile))
        profile = profiles().index(([(3, 1, 2, 2)], [WINDOWS[3]]))
        mixed = [r['trace'] for r in rows if r['profile'] == profile]
        self.assertTrue(any(-3 in trace and any(value > 0 for value in trace) for trace in mixed))
        self.assertEqual(next(r for r in rows if r['profile'] == 648)['trace'], [1])
        self.assertTrue(all(r['source'] == 7 and r['bool_source'] for r in rows if not r['trace']))
        self.assertTrue(any(r['rank'] == 2 and r['inputs'] == 0 for r in counts))

    def test_padding_order_and_converted_fill_mutations_are_rejected(self):
        result = ledger.read('reports/pad-window.json')
        fusion.validate_result(result)
        changed = copy.deepcopy(result)
        row = next(r for r in changed['controls'] if -3 in r['trace'] and len(r['trace']) > 1)
        row['fused_trace'] = [v for v in row['fused_trace'] if v != -3]
        with self.assertRaises(AssertionError):
            fusion.validate_result(changed)
        changed = copy.deepcopy(result)
        row = next(r for r in changed['controls'] if r['trace'] == [-3])
        row['bool_target'] = not row['bool_target']
        with self.assertRaises(AssertionError):
            fusion.validate_result(changed)
        changed = copy.deepcopy(result)
        changed['counterexample_certificates'].pop()
        with self.assertRaises(AssertionError):
            fusion.validate_result(changed)

    def test_sources_operator_meanings_and_domain_successor_are_pinned(self):
        original = fusion.digest
        for suffix in ('LatticeIndex.lean', 'PadWindow.lean', 'PadWindowLemmas.lean',
                       'PadWindowProof.lean', 'PadWindowCounterexamples.lean',
                       'ReductionWindow.lean', 'Convolution.lean', 'Tensor.lean',
                       'PadWindowControls.lean', 'pad_window_examples.py', 'check_pad_window.py',
                       'reduction-window-domains-v2.json', 'reduction-window-domains-v1.json',
                       'lake-manifest.json'):
            def changed(path):
                return 'changed' if str(path).endswith(suffix) else original(path)
            with patch.object(fusion, 'digest', side_effect=changed):
                with self.assertRaises(AssertionError):
                    fusion.check_inputs()

    def test_fusion_cannot_be_promoted_to_broadcast_or_whole_workload_closure(self):
        result = ledger.read('reports/pad-window.json')
        for key in fusion.TRUE_FIELDS + fusion.FALSE_FIELDS:
            changed = copy.deepcopy(result)
            changed[key] = not changed[key]
            with self.assertRaises(AssertionError):
                fusion.validate_result(changed)
        model = next(m for m in ledger.mathematical_models()
                     if m['model'] == 'ordered_pad_window_fusion_v1')
        self.assertFalse(model['full_family_complete'])
        self.assertFalse(model['broadcast_sequence_proved'])
        certificates = [p for p in ledger.evidence() if 'pad_window_contract_refutation' in p['kinds']]
        self.assertEqual(len(certificates), 2)
        self.assertTrue(all(not p['historical_candidate_benchmark_labels'] for p in certificates))
        progress = ledger.read('census/mathematical-ledger.json')
        self.assertEqual(progress['whole_benchmark_records_closed'], 0)
        self.assertIsNone(progress['mathematical_obligation_denominator'])
        domains = ledger.read('census/reduction-window-domains-v2.json')
        self.assertEqual(len(domains['records']), 31)
        self.assertEqual(sum(bool(r['core_evidence']) for r in domains['records']), 22)
        remaining = [r for r in domains['records'] if not r['core_evidence']]
        self.assertEqual(len(remaining), 9)
        self.assertEqual(sum('/pad-broadcast-' in r['benchmark_id'] for r in remaining), 4)
        self.assertFalse(any(r['whole_record_closed'] for r in domains['records']))


if __name__ == '__main__':
    unittest.main()
