"""Keep complete retained-record proposals distinct from reviewed semantics and accepted proofs."""
import copy
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
import check_formulation_expansion as check
import formulate_remaining_batches as proposals
import mathematical_ledger as ledger
import workload_formulation_audit as audit


class FormulationExpansionTests(unittest.TestCase):
    def test_all_380_records_have_explicit_case_preserving_proposals(self):
        manifest,worksheets=check.check_inputs()
        self.assertEqual({Path(p).name.split('-mathematical-domains-')[0]:len(x['records'])
                          for p,x in worksheets.items()},
                         {'simple':51,'arithmetic':85,'scalar-control':55,'shape':58,
                          'tensor-index':57,'layout':30,'dot':44})
        records={r['benchmark_id']:r for x in worksheets.values() for r in x['records']}
        self.assertEqual(len(records),380)
        for batch in proposals.BATCHES:
            for raw in ledger.read('census/'+batch+'-cases.json')['cases']:
                self.assertEqual(records[raw['id']]['retained_lhs'],raw.get('lhs'))
                self.assertEqual(records[raw['id']]['retained_rhs'],raw.get('rhs'))
                self.assertTrue(records[raw['id']]['explicit_mathematical_premises'])
                self.assertTrue(records[raw['id']]['remaining_mathematical_partitions'])
        self.assertEqual(manifest['new_Lean_statements'],0)
        self.assertEqual(manifest['new_custom_Lean_lines'],0)

    def test_counterexample_and_missing_operator_partitions_are_preserved(self):
        _,sheets=check.check_inputs()
        rows={r['benchmark_id']:r for x in sheets.values() for r in x['records']}
        for name,risk in (
            ('HandleMultiply/predicate-convert','known_exceptional_value_counterexample_partition'),
            ('TryToReorderSliceAndReverse/commute','known_empty_shape_counterexample_partition'),
            ('RemoveRedundantStride/single-element-axes','known_empty_shape_counterexample_partition'),
            ('HandleDynamicSlice/nested-after-scaled-probe','known_discarded_multiplier_counterexample_partition'),
            ('HandleSqrt/square-complex','principal_branch_counterexample_partition'),
            ('HandleGather/empty-input','empty_input_gather_domain_gap'),
            ('HandleReshape/rng-shape','rng_observation_contract_missing')):
            self.assertIn(risk,rows[name]['mathematical_risks'])
            self.assertFalse(rows[name]['whole_record_closed'])
        self.assertNotIn('principal_branch_counterexample_partition',
                         rows['HandleSqrt/square-real']['mathematical_risks'])
        scatter=rows['HandleAdd/scatter-concat']
        self.assertTrue(any('p0+p0' in text and 'p1+p1' in text
                            for text in scatter['remaining_mathematical_partitions']))
        self.assertTrue(any('NaN' in text for text in
                            rows['HandleCompare/nonnegative-ge']['remaining_mathematical_partitions']))

    def test_support_schemas_and_unspecified_graphs_are_not_denominator_units(self):
        manifest,sheets=check.check_inputs();result=check.assemble_report(manifest,sheets)
        self.assertEqual(result['record_role_counts']['support_schema'],4)
        self.assertEqual(result['record_role_counts']['delegated_or_unspecified_target'],22)
        self.assertEqual(result['risk_record_counts']['retained_target_not_explicit'],23)
        rows={r['benchmark_id']:r for x in sheets.values() for r in x['records']}
        context=rows['ReplaceInstructionIfCompatible/single']
        self.assertEqual(context['record_role'],'support_schema')
        self.assertTrue(any('SameShape is not semantic equality' in x
                            for x in context['remaining_mathematical_partitions']))
        self.assertIsNone(result['mathematical_obligation_denominator'])
        self.assertFalse(result['mathematical_denominator_frozen'])
        self.assertFalse(result['complete_proof_attempts_for_all_partitions'])

    def test_frozen_integrity_and_no_acceptance_promotion(self):
        result=ledger.read('reports/workload-formulation-expansion.json');check.validate_result(result)
        for field,value in (('new_custom_Lean_lines',1),('whole_benchmark_records_closed',1),
                            ('semantic_correctness_of_proposals_independently_reviewed',True),
                            ('every_proposed_domain_has_a_Lean_operator_definition',True),
                            ('mathematical_denominator_frozen',True)):
            changed=copy.deepcopy(result);changed[field]=value
            with self.assertRaises(AssertionError):check.validate_result(changed)
        original=check.digest
        for suffix in ('formulate_remaining_batches.py','mathematical-domain-proposals-v1.json',
                       'formulation-evidence-baseline-v1.json','shape-mathematical-domains-v1.json',
                       'dot-mathematical-domains-v1.json','workload-formulation-catalog-v1.json'):
            def drift(path):return 'changed' if str(path).endswith(suffix) else original(path)
            with patch.object(check,'digest',side_effect=drift):
                with self.assertRaises(AssertionError):check.check_inputs()
        manifest,sheets=check.check_inputs();changed=copy.deepcopy(sheets)
        next(iter(changed.values()))['records'][0]['source_guards_adopted_as_proof_assumptions']=True
        with self.assertRaises(AssertionError):check.assemble_report(manifest,changed)

    def test_catalog_successor_covers_488_without_upgrading_proof_acceptance(self):
        progress=ledger.read('census/mathematical-ledger.json')
        old=audit.assemble(ledger.corpus(),progress,
                           audit.read_catalog('census/workload-formulation-catalog-v1.json'))
        result=audit.assemble(ledger.corpus(),progress,audit.read_catalog())
        self.assertEqual(old['records_with_domain_worksheets'],108)
        self.assertEqual(len(old['records_without_domain_worksheets']),380)
        self.assertEqual(result['records_with_domain_worksheets'],488)
        self.assertEqual(result['records_with_only_unreviewed_proposal_worksheets'],380)
        self.assertFalse(result['records_without_domain_worksheets'])
        self.assertFalse(result['records_with_evidence_but_no_domain_worksheet'])
        self.assertEqual(len(result['records']),488)
        self.assertEqual(result['whole_benchmark_records_closed'],0)
        self.assertFalse(result['worksheet_presence_is_completed_formulation'])
        self.assertFalse(result['every_record_has_received_a_complete_proof_attempt'])
        self.assertEqual(result['positive_or_negative_workflow_verdict'],
                         'unresolved_full_campaign_required')
        self.assertEqual({r['benchmark_id']:r['mathematical_target_status'] for r in result['records']},
                         {r['benchmark_id']:r['mathematical_target_status'] for r in progress['benchmark_records']})
        self.assertEqual(len(progress['proofs']),progress['distinct_checked_declarations'])


if __name__=='__main__':unittest.main()
