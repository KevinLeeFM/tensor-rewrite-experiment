"""Protect singleton outer tuple values, state conjugacy and binary32 fold observations."""
import copy
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
import check_broadcast_window as check
import mathematical_ledger as ledger


class WindowTupleFamilyTests(unittest.TestCase):
    def test_initial_padding_and_nonidentity_state_equivalence_are_preserved(self):
        result = ledger.read('reports/broadcast-window.json')
        rows = result['tuple_controls']
        self.assertEqual([r['scalar'] for r in rows if r['name'] == 'nontrivial'], [707, 721, 732])
        self.assertTrue(all(r['scalar'] == 7 for r in rows if r['name'] == 'empty_kernel'))
        self.assertEqual(next(r['outputs'] for r in result['tuple_counts']
                              if r['name'] == 'empty_output'), 0)
        self.assertTrue(all(r['source'] == r['target'] == r['scalar'] and
                            r['shifted'] == r['scalar']+1 for r in rows))
        changed = copy.deepcopy(result); changed['tuple_controls'][0]['shifted'] -= 1
        with self.assertRaises(AssertionError): check.validate_result(changed)

    def test_binary32_order_signed_zero_and_empty_initial_are_observed(self):
        result = ledger.read('reports/broadcast-window.json')
        bits = {r['name']: r['source'] for r in result['float_controls']}
        self.assertEqual(bits['finite_order'], 0)
        self.assertEqual(bits['finite_reverse'], 0x3f800000)
        self.assertEqual(bits['negative_zero'], 0)
        self.assertEqual(bits['negative_initial'], 0x80000000)
        self.assertEqual(bits['empty_negative_initial'], 0x80000000)
        self.assertEqual(bits['subnormals'], 3)
        changed = copy.deepcopy(result)
        next(r for r in changed['float_controls'] if r['name'] == 'negative_initial')['target'] = 0
        with self.assertRaises(AssertionError): check.validate_result(changed)

    def test_closed_family_rejects_missing_duplicate_and_larger_tuple_profiles(self):
        family = ledger.read('reports/window-tuple-family.json')
        check.validate_family_result(family)
        for rules in ([], ['singleton', 'singleton'], ['singleton', 'pair']):
            changed = copy.deepcopy(family); changed['enumerated_rules'] = rules
            with self.assertRaises(AssertionError): check.validate_family_result(changed)
        for key, value in (('tuple_arity', 2), ('domain', 'integers_only'), ('side_condition', 'unknown')):
            changed = copy.deepcopy(family); changed['profile_units'][0][key] = value
            with self.assertRaises(AssertionError): check.validate_family_result(changed)
        original = check.json.loads
        def wrong_profile(text):
            value = original(text)
            if value.get('family') == 'singleton_window_tuple_values_v1':
                value['profile_units'][0]['tuple_arity'] = 2
            return value
        with patch.object(check.json, 'loads', side_effect=wrong_profile):
            with self.assertRaises(AssertionError): check.family_inputs()

    def test_complete_value_profile_still_leaves_full_record_and_verdict_open(self):
        families = ledger.formulated_families()
        self.assertEqual({f['family']: f['profile_unit_count'] for f in families
                          if f['family'] != 'typed_pure_control_values_v1'},
                         {'typed_logical_values_v1': 20, 'singleton_window_tuple_values_v1': 1,
                          'typed_commutative_ring_values_v1': 172, 'typed_linear_order_values_v1': 176})
        proofs = ledger.evidence()
        for p in proofs: p['mathematical_acceptance'] = 'kernel_checked_in_declared_model'
        result = ledger.assemble(ledger.corpus(), proofs, {}, families)
        self.assertGreaterEqual(result['kernel_complete_family_profile_count'], 369)
        self.assertEqual(result['whole_benchmark_records_closed'], 0)
        self.assertIsNone(result['mathematical_obligation_denominator'])
        row = next(r for r in result['benchmark_records']
                   if r['benchmark_id'] == 'HandleReduceWindow/singleton-tuple')
        self.assertEqual(row['mathematical_target_status'],
                         'declared_value_family_complete_full_record_partitions_open')
        self.assertFalse(row['whole_record_mathematically_closed'])
        self.assertEqual(result['positive_or_negative_workflow_verdict'],
                         'unresolved_full_campaign_required')


if __name__ == '__main__': unittest.main()
