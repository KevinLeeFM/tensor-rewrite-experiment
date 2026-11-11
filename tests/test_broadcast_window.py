"""Protect covered-window geometry, actual reshape/Broadcast graphs and retained open cases."""
import copy
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
import check_broadcast_window as check
import mathematical_ledger as ledger
from broadcast_window_examples import axis, eligibility, expected, outputs


class BroadcastWindowTests(unittest.TestCase):
    def test_coverage_and_nonassociative_single_live_controls(self):
        axes, counts, rows, *_ = expected()
        self.assertEqual((len(axes), len(counts), len(rows)), (3780, 1277, 440))
        self.assertEqual(sum(a['eligible'] for a in axes), 1268)
        self.assertFalse(eligibility(axis(1, low=1, high=1)))
        self.assertTrue(eligibility(axis(1, low=-2)))
        self.assertEqual(outputs(axis(1, low=-2)), [])
        self.assertTrue(any(a['eligible'] and a['outputs'] > 1 and a['reversed'] for a in axes))
        self.assertTrue(any(r['live'] > 0 for r in rows))
        self.assertTrue(all(sum(v != 0 for v in r['trace']) == 1 for r in rows))
        self.assertTrue(all(r['source'] == r['target'] and
                            r['bool_source'] == r['bool_target'] for r in rows))
        def op(a, b): return b if a == 0 else a if b == 0 else a + 2*b
        self.assertNotEqual(op(op(1, 1), 1), op(1, op(1, 1)))

    def test_retained_axis_order_and_actual_broadcast_indices_are_observed(self):
        result = ledger.read('reports/broadcast-window.json')
        self.assertEqual(check.parse_controls(result['control_stdout'])[:6], expected())
        counts = result['profile_counts']
        self.assertTrue(any(c['axes'] == [1] and c['outputs'] > 0 for c in counts))
        self.assertTrue(any(c['axes'] == [0] and c['outputs'] > 0 for c in counts))
        changed = copy.deepcopy(result)
        next(c for c in changed['profile_counts'] if c['axes'] == [1])['axes'] = [0]
        with self.assertRaises(AssertionError): check.validate_result(changed)
        changed = copy.deepcopy(result)
        next(r for r in changed['controls'] if r['live'] > 0)['live'] = 0
        with self.assertRaises(AssertionError): check.validate_result(changed)

    def test_identity_geometry_claims_and_source_drift_are_rejected(self):
        result = ledger.read('reports/broadcast-window.json')
        check.validate_result(result)
        for key in check.TRUE_FIELDS + check.FALSE_FIELDS:
            changed = copy.deepcopy(result); changed[key] = not changed[key]
            with self.assertRaises(AssertionError): check.validate_result(changed)
        original = check.digest
        for suffix in ('BroadcastWindow.lean', 'BroadcastWindowTarget.lean',
                       'BroadcastWindowFold.lean', 'WindowTransportLemmas.lean',
                       'WindowTupleFamilyProof.lean', 'WindowTupleFloat.lean',
                       'BroadcastWindowControls.lean', 'broadcast_window_examples.py',
                       'IndexMaps.lean', 'Reshape.lean', 'FloatingPoint.lean',
                       'ordered_float_examples.py', 'reduction-window-domains-v3.json',
                       'reduction-window-domains-v4.json', 'lean-toolchain', 'lake-manifest.json'):
            def altered(path):
                return 'changed' if str(path).endswith(suffix) else original(path)
            with patch.object(check, 'digest', side_effect=altered):
                with self.assertRaises(AssertionError): check.check_inputs()

    def test_terminal_broadcast_does_not_close_combined_pad_or_full_workload(self):
        domains = ledger.read('census/reduction-window-domains-v4.json')
        self.assertEqual(len(domains['records']), 31)
        self.assertEqual(sum(bool(r['core_evidence']) for r in domains['records']), 29)
        self.assertEqual({r['benchmark_id'] for r in domains['records'] if not r['core_evidence']},
                         {'HandleReduceWindow/pad-broadcast-'+m+'-combined'
                          for m in ('direct', 'convert')})
        self.assertFalse(any(r['whole_record_closed'] for r in domains['records']))
        manifest = ledger.read(check.MANIFEST)
        labels = {s for group in manifest['candidate_benchmark_bindings'].values() for s in group}
        self.assertEqual(labels, {'HandleReduceWindow/pad-broadcast-'+m+'-existing'
                                  for m in ('direct', 'convert')})
        certificates = [r for r in ledger.evidence() if
                        'broadcast_state_contract_refutation' in r['kinds']]
        self.assertEqual(len(certificates), 3)
        self.assertTrue(all(not r['historical_candidate_benchmark_labels'] for r in certificates))
        self.assertTrue(any('two-component coupled state' in r['profile_descriptions'][0]
                            for r in certificates))
        model = next(m for m in ledger.mathematical_models()
                     if m['model'] == 'covered_singleton_window_broadcast_v1')
        self.assertFalse(model['full_family_complete'])
        self.assertFalse(model['combined_pad_broadcast_composition_proved'])


if __name__ == '__main__': unittest.main()
