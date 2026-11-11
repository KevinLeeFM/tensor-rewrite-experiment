"""Mathematical family accounting controls; no native or code-correspondence checks."""
import copy
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
import check_logical_family as family
import mathematical_ledger as ledger


class LogicalFamilyTests(unittest.TestCase):
    def test_compiled_profile_enumeration(self):
        result=ledger.read('reports/logical-values-family.json')
        self.assertEqual(family.profile_rows(result['audit_stdout']),result['profile_units'])
        self.assertEqual(len(ledger.formulated_families()),3)
        self.assertEqual(ledger.formulated_families()[0]['profile_unit_count'],20)
        self.assertTrue(all(c['exit_code']!=0 for c in result['negative_controls'].values()))

    def test_missing_duplicate_or_word_true_profile_rejected(self):
        output=ledger.read('reports/logical-values-family.json')['audit_stdout']
        lines=output.splitlines()
        missing='\n'.join(line for line in lines if line!='LOGICAL_PROFILE word_all_widths xor_equal')
        duplicate=output+'\nLOGICAL_PROFILE predicate not_not\n'
        wrong=output.replace('LOGICAL_PROFILE word_all_widths xor_equal',
                             'LOGICAL_PROFILE word_all_widths and_true_right')
        for changed in (missing,duplicate,wrong):
            with self.assertRaises(AssertionError):family.profile_rows(changed)

    def test_erased_xor_condition_cannot_enter_ledger(self):
        original=ledger.read
        def mutated(path,root=ledger.ROOT):
            value=copy.deepcopy(original(path,root))
            if path=='reports/logical-values-family.json':
                for row in value['profile_units']:
                    if row['rule']=='xor_equal':row['side_condition']='True'
            return value
        with patch.object(ledger,'read',side_effect=mutated):
            with self.assertRaises(AssertionError):ledger.formulated_families()

    def test_family_completion_is_not_whole_workload_completion(self):
        proofs=ledger.evidence()
        for proof in proofs:proof['mathematical_acceptance']='kernel_checked_in_declared_model'
        result=ledger.assemble(ledger.corpus(),proofs,{},ledger.formulated_families())
        self.assertEqual(result['kernel_complete_family_profile_count'],193)
        self.assertEqual(result['whole_benchmark_records_closed'],0)
        self.assertIsNone(result['mathematical_obligation_denominator'])
        self.assertEqual(result['positive_or_negative_workflow_verdict'],'unresolved_full_campaign_required')


if __name__=='__main__':unittest.main()
