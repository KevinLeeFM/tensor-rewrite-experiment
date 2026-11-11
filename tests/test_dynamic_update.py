"""Protect decoded-index scope, actual window graphs and independent array/control evidence."""
import copy
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
import check_dynamic_update as check
import dynamic_update_examples as oracle
import mathematical_ledger as ledger
import workload_formulation_audit as audit


class DynamicUpdateTests(unittest.TestCase):
    def test_dense_oracle_covers_empty_scalar_full_nested_and_clipped_windows(self):
        h,located,values=oracle.expected()
        self.assertEqual((len(h),len(located),len(values)),(562,1314,19096))
        self.assertTrue(any(not r[2] for r in h))
        self.assertTrue(any(0 in r[2] for r in h))
        self.assertTrue(any(r[2]==r[3] for r in h))
        self.assertTrue(any(any(raw<0 for raw in r[4]) for r in h))
        self.assertTrue(any(any(raw>bound for raw,bound in zip(r[4],r[5])) for r in h))
        self.assertTrue(any(r[3] is None for r in located))
        self.assertTrue(any(r[3] is not None for r in located))
        self.assertEqual(len({r[2] for r in values}),20)
        self.assertTrue(all(a==b for _,_,_,_,a,b in values))
        self.assertEqual(oracle.starts((5,),(3,),(-2,)),(0,))
        self.assertEqual(oracle.starts((3,),(1,),(100,)),(2,))
        self.assertNotEqual(oracle.starts((5,),(1,),(98,)),(2,))

    def test_actual_membership_attributes_graphs_and_ieee_observations_reject_mutations(self):
        result=ledger.read('reports/dynamic-update.json');text=result['control_stdout']
        check.validate_controls(text)
        for original,changed in [('raw=[]','raw=[0]'),('decoded=none','decoded=[0]'),
                                 ('kind=nested','kind=write'),('DU_IEEE lhs=0','DU_IEEE lhs=2147483648')]:
            self.assertIn(original,text)
            with self.assertRaises(AssertionError):check.validate_controls(text.replace(original,changed,1))
        altered=copy.deepcopy(result);altered['binary32_add_zero_rejection']['returncode']=0
        with self.assertRaises(AssertionError):check.validate_result(altered)

    def test_domains_pins_and_axioms_cannot_be_promoted_to_full_machine_claims(self):
        result=ledger.read('reports/dynamic-update.json');check.validate_result(result)
        for name in check.FALSE_FIELDS:
            changed=copy.deepcopy(result);changed[name]=True
            with self.assertRaises(AssertionError):check.validate_result(changed)
        changed=copy.deepcopy(result);next(iter(changed['certificate_axioms'].values())).append('sorryAx')
        with self.assertRaises(AssertionError):check.validate_result(changed)
        original=check.digest
        for suffix in ('DynamicUpdate.lean','DynamicUpdateLemmas.lean','DynamicUpdateProof.lean',
                       'DynamicUpdateStatic.lean','DynamicUpdateCounterexamples.lean',
                       'DynamicUpdateControls.lean','InvalidDynamicUpdateFloatAdd.lean',
                       'dynamic_update_examples.py','check_dynamic_update.py','dynamic-update-domains-v1.json'):
            with patch.object(check,'digest',side_effect=lambda path,suffix=suffix:
                              'changed' if str(path).endswith(suffix) else original(path)):
                with self.assertRaises(AssertionError):check.check_inputs()

    def test_refutations_and_partial_model_remain_separate_from_positive_bindings(self):
        frozen=check.check_inputs();proofs=ledger.evidence()
        counters=[p for p in proofs if 'dynamic_update_contract_refutation' in p['kinds']]
        self.assertEqual({p['theorem'] for p in counters},set(frozen['counterexample_certificates']))
        self.assertTrue(all(not p['historical_candidate_benchmark_labels'] for p in counters))
        model=next(m for m in ledger.mathematical_models() if m['model']==frozen['model'])
        self.assertFalse(model['full_family_complete'])
        self.assertFalse(model['all_machine_index_decoders_identified'])
        self.assertTrue(model['independently_clamped_nested_update_proved'])

    def test_every_record_and_remaining_partition_stays_in_the_workload(self):
        progress=ledger.read('census/mathematical-ledger.json')
        result=audit.assemble(ledger.corpus(),progress,audit.read_catalog('census/workload-formulation-catalog-v7.json'))
        self.assertEqual(result['retained_benchmark_records'],488)
        self.assertEqual(result['records_with_only_unreviewed_proposal_worksheets'],244)
        self.assertGreaterEqual(progress['kernel_complete_family_profile_count'],369)
        self.assertEqual(result['whole_benchmark_records_closed'],0)
        self.assertIsNone(result['mathematical_obligation_denominator'])
        self.assertFalse(result['every_record_has_received_a_complete_proof_attempt'])


if __name__=='__main__':unittest.main()
