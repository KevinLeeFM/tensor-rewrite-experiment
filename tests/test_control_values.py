"""Protect exact operand/branch semantics, observation limits and whole-workload accounting."""
import copy
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
import check_control_values as check
import control_values_examples as oracle
import mathematical_ledger as ledger
import workload_formulation_audit as audit


class ControlValueTests(unittest.TestCase):
    def test_independent_oracle_covers_operand_repetition_both_broadcast_axes_and_exceptional_bits(self):
        lines=oracle.expected_lines()
        self.assertEqual(len(lines),137)
        self.assertTrue(any('CV_MAP first=2 second=2' in line for line in lines))
        self.assertTrue(any('CV_BROADCAST axis=0 row=1 column=2' in line for line in lines))
        self.assertTrue(any('CV_BROADCAST axis=1 row=1 column=2' in line for line in lines))
        self.assertTrue(any('CV_HETERO flag=1 input=-17 value=-16'==line for line in lines))
        self.assertTrue(any('CV_FLOAT predicate=0 left=0 right=2147483648 bits=2147483648'==line
                            for line in lines))
        self.assertIn('CV_EMPTY coordinates=0',lines)

    def test_actual_results_reject_changed_directions_axes_traces_and_float_payloads(self):
        result=ledger.read('reports/control-values-family.json');stdout=result['control_stdout']
        check.validate_controls(stdout)
        for old,new in [('direction=gt','direction=lt'),('axis=1 row=0 column=0','axis=0 row=0 column=0'),
                        ('first=2 second=2','first=2 second=0'),('target_event=1','target_event=0'),
                        ('bits=2147483648','bits=0')]:
            self.assertIn(old,stdout)
            with self.assertRaises(AssertionError):check.validate_controls(stdout.replace(old,new,1))

    def test_invalid_profiles_are_false_propositions_rather_than_parser_failures(self):
        result=ledger.read('reports/control-values-family.json');check.validate_result(result)
        altered=copy.deepcopy(result);altered['invalid_profile_rejections']['returncode']=0
        with self.assertRaises(AssertionError):check.validate_result(altered)
        altered=copy.deepcopy(result)
        altered['invalid_profile_rejections']['diagnostic']='unexpected token; failed to parse'
        with self.assertRaises(AssertionError):check.validate_result(altered)
        frozen=check.check_inputs()
        counters=[p for p in ledger.evidence() if 'control_value_contract_refutation' in p['kinds']]
        self.assertEqual({p['theorem'] for p in counters},set(frozen['counterexample_certificates']))
        self.assertTrue(all(not p['historical_candidate_benchmark_labels'] for p in counters))

    def test_frozen_inputs_axioms_and_observation_contract_cannot_be_silently_promoted(self):
        result=ledger.read('reports/control-values-family.json')
        for field in check.FALSE_FIELDS:
            altered=copy.deepcopy(result);altered[field]=True
            with self.assertRaises(AssertionError):check.validate_result(altered)
        altered=copy.deepcopy(result);next(iter(altered['certificate_axioms'].values())).append('sorryAx')
        with self.assertRaises(AssertionError):check.validate_result(altered)
        original=check.digest
        for row in check.check_inputs()['files']:
            with patch.object(check,'digest',side_effect=lambda p,target=row['path']:
                              'changed' if str(p).endswith(target) else original(p)):
                with self.assertRaises(AssertionError):check.check_inputs()

    def test_universal_profiles_refine_nineteen_worksheets_without_closing_whole_records(self):
        progress=ledger.read('census/mathematical-ledger.json')
        old=audit.assemble(ledger.corpus(),progress,audit.read_catalog('census/workload-formulation-catalog-v7.json'))
        current=audit.assemble(ledger.corpus(),progress,audit.read_catalog('census/workload-formulation-catalog-v8.json'))
        self.assertEqual(old['records_with_only_unreviewed_proposal_worksheets'],244)
        self.assertEqual(current['records_with_only_unreviewed_proposal_worksheets'],225)
        self.assertEqual(current['records_with_domain_worksheets'],488)
        family=next(f for f in ledger.formulated_families() if f['family']=='typed_pure_control_values_v1')
        self.assertEqual(family['profile_unit_count'],19)
        self.assertEqual(len(family['candidate_benchmark_labels']),19)
        self.assertFalse(family['label_correspondence_certified'])
        self.assertEqual(current['whole_benchmark_records_closed'],0)
        self.assertIsNone(current['mathematical_obligation_denominator'])
        self.assertFalse(current['every_record_has_received_a_complete_proof_attempt'])


if __name__=='__main__':unittest.main()
