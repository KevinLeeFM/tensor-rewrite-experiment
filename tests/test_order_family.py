"""Check order-family scope, independent guard/tree controls and honest workload accounting."""
import copy
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
import check_order_family as check
import order_examples as oracle
import mathematical_ledger as ledger
import workload_formulation_audit as audit


class OrderFamilyTests(unittest.TestCase):
    def test_all_orders_directions_and_explicit_domains_have_independent_witnesses(self):
        rules=oracle.rules();rows=list(oracle.rows())
        self.assertEqual(len(rules),44)
        self.assertEqual(len(check.profile_units()),176)
        self.assertEqual({r['condition'] for r in rules},
                         {'true','lower','upper','bounds','nonnegative','range'})
        for rule in rules:
            selected=[r for r in rows if r[0]=='integer' and r[5]==rule['key']]
            self.assertTrue(any(r[6] for r in selected))
            if rule['condition']!='true':self.assertTrue(any(not r[6] for r in selected))
        self.assertNotEqual(oracle.evaluate('x1 x0 x2 min max',(0,2,1)),
                            oracle.evaluate('x1 x0 x2 clamp',(0,2,1)))
        self.assertEqual(sum(r[6] for r in rows),11603)
        self.assertEqual({r[1] for r in rows if r[0]=='signed'},{0,1,2,4,8})
        self.assertTrue(any(r[0]=='signed' and -128 in r[4] for r in rows))

    def test_actual_tree_order_and_admission_changes_are_rejected(self):
        result=ledger.read('reports/order-values-family.json')
        check.validate_controls(result['control_stdout'])
        for text in (result['control_stdout'].replace('lhs=x0 x0 max','lhs=x0 x1 max',1),
                     result['control_stdout'].replace('admitted=false','admitted=true',1),
                     result['control_stdout'].replace('decoded=-2,-2,-2','decoded=2,2,2',1),
                     result['control_stdout'].replace('nan_eq=false','nan_eq=true',1)):
            with self.assertRaises(AssertionError):check.validate_controls(text)
        changed=copy.deepcopy(result);changed['binary32_order_rejection']['returncode']=0
        with self.assertRaises(AssertionError):check.validate_result(changed)

    def test_frozen_inputs_and_non_ieee_claim_boundary_are_enforced(self):
        result=ledger.read('reports/order-values-family.json')
        check.validate_result(result)
        for key in check.FALSE_FIELDS:
            changed=copy.deepcopy(result);changed[key]=True
            with self.assertRaises(AssertionError):check.validate_result(changed)
        changed=copy.deepcopy(result);changed['profile_units'][0]['side_condition']='unrecorded stronger premise'
        with self.assertRaises(AssertionError):check.validate_result(changed)
        changed=copy.deepcopy(result);next(iter(changed['certificate_axioms'].values())).append('sorryAx')
        with self.assertRaises(AssertionError):check.validate_result(changed)
        original=check.digest
        for suffix in ('OrderFamily.lean','OrderWord.lean','OrderFamilyProof.lean','OrderInstances.lean',
                       'OrderCounterexamples.lean','OrderFamilyControls.lean','InvalidOrderBinary32.lean',
                       'order_examples.py','check_order_family.py','order-typed-domains-v1.json'):
            with patch.object(check,'digest',side_effect=lambda path,suffix=suffix:
                              'changed' if str(path).endswith(suffix) else original(path)):
                with self.assertRaises(AssertionError):check.check_inputs()

    def test_refutations_are_separate_from_positive_family_bindings(self):
        manifest=check.check_inputs();proofs=ledger.evidence()
        counters=[p for p in proofs if 'exact_order_domain_refutation' in p['kinds']]
        self.assertEqual({p['theorem'] for p in counters},set(manifest['counterexample_certificates']))
        self.assertTrue(all(not p['historical_candidate_benchmark_labels'] for p in counters))
        families=ledger.formulated_families()
        family=next(f for f in families if f['family']=='typed_linear_order_values_v1')
        self.assertEqual(family['profile_unit_count'],176)
        self.assertEqual(len(family['candidate_benchmark_labels']),48)
        self.assertFalse(family['label_correspondence_certified'])

    def test_full_workload_keeps_all_488_records_and_open_partitions(self):
        progress=ledger.read('census/mathematical-ledger.json')
        result=audit.assemble(ledger.corpus(),progress,audit.read_catalog())
        self.assertEqual(result['records_with_domain_worksheets'],488)
        self.assertEqual(result['records_with_only_unreviewed_proposal_worksheets'],244)
        self.assertEqual(progress['kernel_complete_family_profile_count'],369)
        self.assertEqual(result['whole_benchmark_records_closed'],0)
        self.assertIsNone(result['mathematical_obligation_denominator'])
        self.assertFalse(result['every_record_has_received_a_complete_proof_attempt'])


if __name__=='__main__':unittest.main()
