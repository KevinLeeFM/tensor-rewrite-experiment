"""Protect graph semantics, exact declared family domains and historical snapshot boundaries."""
import copy
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
import check_concatenation_family as check
import concatenation_graph_examples as oracle
import mathematical_ledger as ledger
import workload_formulation_audit as audit


class ConcatenationFamilyTests(unittest.TestCase):
    def test_independent_arrays_cover_noncanonical_strides_crops_empty_cases_and_scalar_reshape(self):
        lines=oracle.expected_lines()
        self.assertEqual(len(lines),11544)
        self.assertTrue(any('raw=5,1,2,5,2 counts=1,1' in line for line in lines))
        self.assertTrue(any('AG_PROFILE' in line and 'rank=3 axis=1 other=2' in line for line in lines))
        self.assertTrue(any('PG_PROFILE' in line and 'extent=0 low=2 high=0' in line for line in lines))
        self.assertTrue(any('RG_PROFILE' in line and 'rank=1 axis=0' in line and
                            'dropped=- axes=-' in line for line in lines))
        self.assertTrue(any('RG_PROFILE' in line and 'rank=3 axis=1' in line and
                            'axes=0,2' in line for line in lines))
        self.assertTrue(any('word8' in line and 'source=239' in line for line in lines))
        self.assertTrue(any('CG_FLOAT input=2147483648 repeat=2147483648 pad=2147483648'
                            ==line for line in lines))

    def test_actual_replay_rejects_coordinate_shape_axis_side_and_stored_bit_mutations(self):
        result=check.read('reports/concatenation-values-family.json')
        text=result['control_stdout'];check.validate_controls(text)
        for old,new in [('raw=5,1,2,5,2','raw=5,1,2,5,1'),('counts=1,1','counts=1,2'),
                        ('low=2 high=0','low=0 high=2'),('axes=0,2','axes=0,1'),
                        ('target=71','target=72'),('pad=2147483648','pad=0')]:
            self.assertIn(old,text)
            with self.assertRaises(AssertionError):check.validate_controls(text.replace(old,new,1))

    def test_all_nine_retained_concat_schemas_have_exact_domains_without_closing_whole_records(self):
        frozen=check.check_inputs()
        result=check.read('reports/concatenation-values-family.json');check.validate_result(result)
        self.assertEqual(len(frozen['profiles']),9)
        empty=next(p for p in frozen['profiles'] if p['id'].endswith('/filter-all-empty'))
        self.assertIn('iff complete output shape',empty['domain'])
        old=audit.assemble(ledger.corpus(),ledger.read('census/mathematical-ledger.json'),
                           audit.read_catalog('census/workload-formulation-catalog-v9.json'))
        new=audit.assemble(ledger.corpus(),ledger.read('census/mathematical-ledger.json'),audit.read_catalog())
        self.assertEqual(old['records_with_only_unreviewed_proposal_worksheets'],217)
        self.assertEqual(new['records_with_only_unreviewed_proposal_worksheets'],213)
        self.assertEqual(new['records_with_domain_worksheets'],488)
        self.assertEqual(new['whole_benchmark_records_closed'],0)
        self.assertIsNone(new['mathematical_obligation_denominator'])

    def test_axioms_pins_and_claim_boundaries_cannot_be_strengthened_silently(self):
        result=check.read('reports/concatenation-values-family.json')
        for key in check.FALSE_FIELDS:
            bad=copy.deepcopy(result);bad[key]=True
            with self.assertRaises(AssertionError):check.validate_result(bad)
        bad=copy.deepcopy(result);next(iter(bad['certificate_axioms'].values())).append('sorryAx')
        with self.assertRaises(AssertionError):check.validate_result(bad)
        original=check.digest
        for row in check.check_inputs()['files']:
            with patch.object(check,'digest',side_effect=lambda path,target=row['path']:
                              'changed' if str(path).endswith(target) else original(path)):
                with self.assertRaises(AssertionError):check.check_inputs()

    def test_four_false_profiles_fail_normally_and_refutations_have_no_positive_labels(self):
        result=check.read('reports/concatenation-values-family.json');check.validate_result(result)
        for diagnostic in ('unexpected token','unknown identifier',''):
            bad=copy.deepcopy(result);bad['invalid_profile_rejections']['diagnostic']=diagnostic
            with self.assertRaises(AssertionError):check.validate_result(bad)
        bad=copy.deepcopy(result);bad['invalid_profile_rejections']['returncode']=0
        with self.assertRaises(AssertionError):check.validate_result(bad)
        rows=[r for r in ledger.evidence() if 'concatenation_graph_contract_refutation' in r['kinds']]
        self.assertEqual({r['theorem'] for r in rows},set(result['counterexample_certificates']))
        self.assertTrue(all(not r['historical_candidate_benchmark_labels'] for r in rows))
        historical=check.read('reports/concatenation.json')
        self.assertEqual(len(historical['certificate_axioms']),48)
        self.assertFalse(historical['full_concatenation_family_complete'])
        self.assertFalse(historical['adjacent_slice_merge_proved'])


if __name__=='__main__':unittest.main()
