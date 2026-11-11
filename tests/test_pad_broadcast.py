"""Protect raw Pad composition, converted fills, real target maps and partial coverage boundaries."""
import copy
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
import check_pad_broadcast as check
import mathematical_ledger as ledger
from pad_broadcast_examples import axis, eligible, expected, output_positions


class PadBroadcastTests(unittest.TestCase):
    def test_materialized_pad_oracle_and_raw_coverage_include_empty_and_reversed_cases(self):
        result = ledger.read('reports/pad-broadcast.json')
        self.assertEqual(check.parse_controls(result['control_stdout']), expected())
        axes, counts, rows = expected()
        self.assertEqual((len(axes), len(counts), len(rows)), (14400, 3785, 1805))
        self.assertEqual(sum(a['eligible'] for a in axes), 3776)
        self.assertTrue(any(a['eligible'] and a['outputs'] > 1 and a['reversed'] for a in axes))
        self.assertTrue(any(c['outputs'] == 0 and c['padded'] > 0 for c in counts))
        self.assertTrue(eligible(axis(1, 1, 1, 3, 1, 1, 0, 0, False)))
        self.assertFalse(eligible(axis(1, 1, 1, 1, 1, 1, 0, 0, False)))
        self.assertEqual(output_positions(axis(0, 0, 1, 1, 1, 1, -2, 0, False)), [])
        self.assertTrue(all(sum(v != 0 for v in r['trace']) == 1 for r in rows))
        self.assertTrue(all(r['source'] == r['target'] for r in rows))

    def test_real_reshape_axes_and_converted_fill_cannot_be_silently_changed(self):
        result = ledger.read('reports/pad-broadcast.json')
        self.assertTrue(any(c['axes'] == [1] and c['outputs'] > 0 for c in result['profile_counts']))
        self.assertTrue(any(c['axes'] == [0, 1] and c['outputs'] > 0 for c in result['profile_counts']))
        self.assertTrue(all(r['shifted_trace'] == [v+1 for v in r['trace']] and
                            r['converted'] == r['converted_target'] == r['target']+1
                            for r in result['controls']))
        changed = copy.deepcopy(result)
        next(c for c in changed['profile_counts'] if c['axes'] == [1])['axes'] = [0]
        with self.assertRaises(AssertionError): check.validate_result(changed)
        changed = copy.deepcopy(result)
        row = next(r for r in changed['controls'] if 0 in r['trace'])
        row['shifted_trace'] = row['trace']
        with self.assertRaises(AssertionError): check.validate_result(changed)
        changed = copy.deepcopy(result)
        next(r for r in changed['controls'] if 0 in r['trace'])['trace'] = [1]
        with self.assertRaises(AssertionError): check.validate_result(changed)

    def test_contract_mutations_counterexample_omissions_and_dependency_drift_are_rejected(self):
        result = ledger.read('reports/pad-broadcast.json'); check.validate_result(result)
        for key in check.TRUE_FIELDS + check.FALSE_FIELDS:
            changed = copy.deepcopy(result); changed[key] = not changed[key]
            with self.assertRaises(AssertionError): check.validate_result(changed)
        changed = copy.deepcopy(result); changed['counterexample_certificates'].pop()
        with self.assertRaises(AssertionError): check.validate_result(changed)
        original = check.digest
        for suffix in ('PadBroadcast.lean', 'PadBroadcastGeometry.lean', 'PadBroadcastPlan.lean',
                       'PadBroadcastCompile.lean', 'PadBroadcastTarget.lean', 'PadBroadcastProof.lean',
                       'PadBroadcastCounterexamples.lean', 'PadBroadcastControls.lean',
                       'pad_broadcast_examples.py', 'PadWindowProof.lean', 'BroadcastWindowTarget.lean',
                       'reduction-window-domains-v4.json', 'reduction-window-domains-v5.json',
                       'pad-window-v1.json', 'broadcast-window-v1.json', 'lake-manifest.json'):
            def drift(path): return 'changed' if str(path).endswith(suffix) else original(path)
            with patch.object(check, 'digest', side_effect=drift):
                with self.assertRaises(AssertionError): check.check_inputs()

    def test_all_window_records_with_core_evidence_still_does_not_close_full_records(self):
        domains = ledger.read('census/reduction-window-domains-v5.json')
        self.assertEqual(len(domains['records']), 31)
        self.assertTrue(all(r['core_evidence'] and not r['whole_record_closed']
                            for r in domains['records']))
        old = ledger.read('census/reduction-window-domains-v4.json')
        self.assertEqual(sum(bool(r['core_evidence']) for r in old['records']), 29)
        self.assertFalse(domains['source_guards_adopted_as_proof_assumptions'])
        proofs = ledger.evidence()
        certificates = [p for p in proofs if 'pad_broadcast_contract_refutation' in p['kinds']]
        self.assertEqual(len(certificates), 3)
        self.assertTrue(all(not p['historical_candidate_benchmark_labels'] for p in certificates))
        self.assertTrue(any('source8 versus converted target6' in p['profile_descriptions'][0]
                            for p in certificates))
        for proof in proofs: proof['mathematical_acceptance'] = 'kernel_checked_in_declared_model'
        result = ledger.assemble(ledger.corpus(), proofs, {}, ledger.formulated_families())
        for row in result['benchmark_records']:
            if '/pad-broadcast-' in row['benchmark_id'] and row['benchmark_id'].endswith('-combined'):
                self.assertEqual(row['mathematical_target_status'],
                                 'partial_model_evidence_requires_partition_review')
        self.assertEqual(result['whole_benchmark_records_closed'], 0)
        self.assertIsNone(result['mathematical_obligation_denominator'])
        model = next(m for m in ledger.mathematical_models()
                     if m['model'] == 'raw_pad_window_broadcast_composition_v1')
        self.assertTrue(model['combined_pad_broadcast_composition_proved'])
        self.assertFalse(model['full_family_complete'])


if __name__ == '__main__': unittest.main()
