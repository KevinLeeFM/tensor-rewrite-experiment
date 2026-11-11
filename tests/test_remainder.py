"""Protect truncating/word domains, overflow witnesses, floating limits and whole-workload accounting."""
import copy
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
import check_remainder as check
import mathematical_ledger as ledger
import workload_formulation_audit as audit
from remainder_examples import expected, signed


class RemainderTests(unittest.TestCase):
    def test_exhaustive_word_pairs_include_signed_minimum_zero_and_corrected_mask(self):
        result=ledger.read('reports/remainder.json')
        self.assertEqual(check.parse_controls(result['control_stdout']),expected())
        rows=result['word_controls']
        self.assertEqual(len(rows),5461)
        self.assertTrue(all(r['unsigned']==r['unsigned_nested'] and r['signed']==r['signed_nested']
                            for r in rows))
        for row in rows:
            w,x,y=row['width'],row['x'],row['y']
            if y>0 and y & (y-1)==0:
                self.assertEqual(row['unsigned'],row['unsigned_mask'])
                if signed(y,w)>0:self.assertEqual(row['signed'],row['signed_mask'])
            if y==0:
                self.assertEqual(row['unsigned'],x)
                self.assertEqual(row['signed'],signed(x,w))
        minimum=next(r for r in rows if (r['width'],r['x'],r['y'])==(4,8,4))
        self.assertEqual(minimum['signed_mask'],0)
        self.assertEqual(next(r['signed_mask'] for r in rows
                              if (r['width'],r['x'],r['y'])==(4,11,4)),-1)

    def test_actual_iota_graphs_observe_no_wrap_conditions_and_empty_axes(self):
        result=ledger.read('reports/remainder.json')
        counts={c['profile']:c for c in result['iota_counts']}
        self.assertEqual(len(counts),2350)
        self.assertTrue(any(c['width']==0 and c['outputs']==0 and c['unsigned_offset']
                            for c in counts.values()))
        for row in result['iota_controls']:
            profile=counts[row['profile']]
            if profile['unsigned_bound']:self.assertEqual(row['unsigned'],row['value'])
            if profile['signed_bound']:self.assertEqual(row['signed'],row['signed_value'])
            if profile['unsigned_offset']:
                self.assertEqual(row['unsigned_lhs'],row['unsigned'])
                self.assertEqual(row['unsigned_rhs'],row['unsigned'])
            if profile['signed_offset']:
                self.assertEqual(row['signed_lhs'],row['signed'])
                self.assertEqual(row['signed_rhs'],row['signed'])
        unsigned=next(r for r in result['iota_controls'] if r['profile']==2347 and r['coordinate']==7)
        self.assertEqual((unsigned['unsigned_rhs'],unsigned['unsigned']),(1,7))
        signed_case=next(r for r in result['iota_controls'] if r['profile']==2348 and r['coordinate']==5)
        self.assertEqual((signed_case['signed_rhs'],signed_case['signed']),(-2,2))
        self.assertTrue(any(c['outputs']==0 and not c['unsigned_bound'] and c['unsigned_offset']
                            for c in counts.values()))
        self.assertTrue(counts[2349]['unsigned_bound'])
        self.assertEqual(counts[2349]['outputs'],0)
        self.assertTrue(counts[2349]['unsigned_offset'])

    def test_uniform_float_diagnostic_does_not_refute_collective_permitted_behavior(self):
        result=ledger.read('reports/remainder.json')
        row=next(r for r in result['uniform_float_controls'] if r['word']==0x3dcccccd and r['count']==10)
        self.assertEqual((row['fold'],row['product']),(0x3f800001,0x3f800000))
        row=next(r for r in result['uniform_float_controls'] if r['word']==0x80000000 and r['count']==1)
        self.assertEqual((row['fold'],row['product']),(0,0x80000000))
        self.assertFalse(result['uniform_collective_refinement_refuted'])
        self.assertFalse(result['floating_truncating_remainder_formalized'])
        proofs=ledger.evidence()
        uniform=[p for p in proofs if 'uniform_fixed_order_rounding_refutation' in p['kinds']]
        self.assertEqual(len(uniform),1)
        self.assertIn('no collective',uniform[0]['profile_descriptions'][0])
        certificates=[p for p in proofs if 'remainder_contract_refutation' in p['kinds']]
        self.assertEqual(len(certificates),3)
        self.assertTrue(all(not p['historical_candidate_benchmark_labels'] for p in certificates))

    def test_mutated_sign_overflow_flags_certificates_and_frozen_dependencies_are_rejected(self):
        result=ledger.read('reports/remainder.json');check.validate_result(result)
        changed=copy.deepcopy(result)
        next(r for r in changed['word_controls'] if (r['width'],r['x'],r['y'])==(4,11,4))['signed']=3
        with self.assertRaises(AssertionError):check.validate_result(changed)
        changed=copy.deepcopy(result);changed['counterexample_certificates'].pop()
        with self.assertRaises(AssertionError):check.validate_result(changed)
        for key in check.TRUE_FIELDS+check.FALSE_FIELDS:
            changed=copy.deepcopy(result);changed[key]=not changed[key]
            with self.assertRaises(AssertionError):check.validate_result(changed)
        original=check.digest
        for suffix in ('Remainder.lean','RemainderScalar.lean','RemainderProof.lean',
                       'RemainderLemmas.lean','RemainderCounterexamples.lean',
                       'UniformSumCounterexample.lean','RemainderControls.lean',
                       'remainder_examples.py','collective-rotation-mathematical-domains-v1.json',
                       'collective-rotation-cases.json','ordered_float_examples.py','lake-manifest.json'):
            def drift(path):return 'changed' if str(path).endswith(suffix) else original(path)
            with patch.object(check,'digest',side_effect=drift):
                with self.assertRaises(AssertionError):check.check_inputs()

    def test_full_retained_workload_and_worksheet_presence_cannot_be_promoted_to_proof_coverage(self):
        worksheet=ledger.read('census/collective-rotation-mathematical-domains-v1.json')
        self.assertEqual(len(worksheet['records']),17)
        self.assertEqual(sum(bool(r['core_evidence']) for r in worksheet['records']),8)
        self.assertFalse(worksheet['source_guards_adopted_as_proof_assumptions'])
        progress=ledger.read('census/mathematical-ledger.json')
        old_catalog=audit.read_catalog('census/workload-formulation-catalog-v1.json')
        result=audit.assemble(ledger.corpus(),progress,old_catalog)
        self.assertEqual(result['records_with_domain_worksheets'],108)
        self.assertEqual(len(result['records_without_domain_worksheets']),380)
        self.assertEqual(len({r['benchmark_id'] for r in result['records']}),488)
        self.assertFalse(result['worksheet_presence_is_completed_formulation'])
        self.assertFalse(result['every_record_has_received_a_complete_proof_attempt'])
        self.assertIsNone(result['mathematical_obligation_denominator'])
        self.assertEqual(result['whole_benchmark_records_closed'],0)
        changed=copy.deepcopy(progress);changed['benchmark_records'].pop()
        with self.assertRaises(AssertionError):audit.assemble(ledger.corpus(),changed,audit.read_catalog())
        changed=copy.deepcopy(progress);changed['benchmark_records'][0]['whole_record_mathematically_closed']=True
        with self.assertRaises(AssertionError):audit.assemble(ledger.corpus(),changed,audit.read_catalog())


if __name__=='__main__':unittest.main()
