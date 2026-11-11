"""Protect actual empty-shape guards, ordered concatenation and bounded Slice observations."""
import copy
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
import check_concatenation as check
import concatenation_examples as oracle
import mathematical_ledger as ledger
import workload_formulation_audit as audit


class ConcatenationTests(unittest.TestCase):
    def test_independent_arrays_cover_all_selected_axes_empty_tails_and_nary_operand_order(self):
        lines=oracle.expected_lines()
        self.assertEqual(len(lines),11742)
        self.assertTrue(any('rank=3 axis=2 other=2 counts=1,2,1,2' in line for line in lines))
        self.assertTrue(any('rank=2 axis=0 other=0 counts=2,1 shape=3,0 kept=- kept_total=0'
                            in line for line in lines))
        self.assertTrue(any('rank=1 axis=0 other=0 counts=2,1 shape=3 kept=2,1 kept_total=3'
                            in line for line in lines))
        self.assertTrue(any('track=word8' in line and 'source=239' in line for line in lines))
        self.assertTrue(any('CAT_SLICE ' in line and 'variant=1' in line for line in lines))

    def test_actual_rows_reject_shape_filter_offset_order_and_stored_bit_mutations(self):
        result=ledger.read('reports/concatenation.json');text=result['control_stdout']
        check.validate_controls(text)
        for old,new in [('shape=3,0 kept=- kept_total=0','shape=0,0 kept=- kept_total=0'),
                        ('counts=2,1','counts=1,2'),('variant=1 start=1','variant=1 start=0'),
                        ('nested=-17','nested=17'),('output=2147483648','output=0')]:
            self.assertIn(old,text)
            with self.assertRaises(AssertionError):check.validate_controls(text.replace(old,new,1))

    def test_false_profiles_have_normal_rejections_and_refutations_are_not_positive_bindings(self):
        result=ledger.read('reports/concatenation.json');check.validate_result(result)
        changed=copy.deepcopy(result);changed['invalid_profile_rejections']['returncode']=0
        with self.assertRaises(AssertionError):check.validate_result(changed)
        changed=copy.deepcopy(result);changed['invalid_profile_rejections']['diagnostic']='unexpected token'
        with self.assertRaises(AssertionError):check.validate_result(changed)
        frozen=check.check_inputs()
        counters=[r for r in ledger.evidence() if 'concatenation_contract_refutation' in r['kinds']]
        self.assertEqual({r['theorem'] for r in counters},set(frozen['counterexample_certificates']))
        self.assertTrue(all(not r['historical_candidate_benchmark_labels'] for r in counters))

    def test_scope_pins_and_axioms_do_not_allow_unconditional_empty_or_complete_family_claims(self):
        result=ledger.read('reports/concatenation.json')
        for name in check.FALSE_FIELDS:
            changed=copy.deepcopy(result);changed[name]=True
            with self.assertRaises(AssertionError):check.validate_result(changed)
        changed=copy.deepcopy(result);next(iter(changed['certificate_axioms'].values())).append('sorryAx')
        with self.assertRaises(AssertionError):check.validate_result(changed)
        original=check.digest
        for row in check.check_inputs()['files']:
            with patch.object(check,'digest',side_effect=lambda path,target=row['path']:
                              'changed' if str(path).endswith(target) else original(path)):
                with self.assertRaises(AssertionError):check.check_inputs()
        model=next(r for r in ledger.mathematical_models() if r['model']=='arbitrary_axis_nary_concatenation_v1')
        self.assertFalse(model['full_family_complete'])
        self.assertTrue(model['all_empty_first_shape_iff_proved'])

    def test_eight_typed_records_preserve_all_cases_and_the_unfrozen_denominator(self):
        progress=ledger.read('census/mathematical-ledger.json')
        old=audit.assemble(ledger.corpus(),progress,audit.read_catalog('census/workload-formulation-catalog-v8.json'))
        new=audit.assemble(ledger.corpus(),progress,audit.read_catalog('census/workload-formulation-catalog-v9.json'))
        self.assertEqual(old['records_with_only_unreviewed_proposal_worksheets'],225)
        self.assertEqual(new['records_with_only_unreviewed_proposal_worksheets'],217)
        self.assertEqual(new['records_with_domain_worksheets'],488)
        self.assertGreaterEqual(progress['kernel_complete_family_profile_count'],388)
        self.assertEqual(new['whole_benchmark_records_closed'],0)
        self.assertIsNone(new['mathematical_obligation_denominator'])
        self.assertFalse(new['every_record_has_received_a_complete_proof_attempt'])


if __name__=='__main__':unittest.main()
