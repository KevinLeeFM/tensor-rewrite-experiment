"""Protect actual ordered geometry, reducer roles, coupled state and open Scatter bridge claims."""
import copy
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
import check_ordered_scatter as check
import mathematical_ledger as ledger
import workload_formulation_audit as audit
from scatter_examples import expected


class OrderedScatterTests(unittest.TestCase):
    def test_actual_address_generation_matches_independent_dense_table_oracle(self):
        result=ledger.read('reports/ordered-scatter.json')
        self.assertEqual(check.parse_controls(result['control_stdout']),expected())
        self.assertEqual(tuple(map(len,expected())),(2709,3354,2968,11872,4))
        counts=result['profile_counts'];events=result['event_controls'];values=result['value_controls']
        self.assertTrue(any(c['axes']==[1,0] and c['outputs']>0 for c in counts))
        self.assertTrue(any(c['axes']==[1] and c['outputs']>0 for c in counts))
        self.assertTrue(any(c['operand']==[] and c['events']>1 for c in counts))
        self.assertTrue(any(e['target']==-1 for e in events))
        self.assertTrue(any(len(v['trace'])>1 for v in values))
        self.assertTrue(any(v['decimal']!=v['reverse'] for v in values))

    def test_empty_events_and_actual_full_window_map_preserve_whole_coupled_state(self):
        result=ledger.read('reports/ordered-scatter.json')
        counts={c['profile']:c for c in result['profile_counts']}
        map_rows=[v for v in result['value_controls'] if counts[v['profile']]['map_case']]
        self.assertTrue(map_rows)
        self.assertTrue(all(v['decimal']==v['map_expected'] for v in map_rows))
        empty_rows=[v for v in result['value_controls'] if counts[v['profile']]['events']==0]
        self.assertTrue(empty_rows)
        self.assertTrue(all(v['decimal']==v['output']+2 and
                            v['coupled']==[v['output']+2,-(v['output']+2)] for v in empty_rows))
        self.assertTrue(any(c['events']==0 and c['outputs']>0 for c in counts.values()))
        self.assertTrue(any(c['outputs']==0 and c['events']>0 for c in counts.values()))

    def test_fusion_and_distinct_word_roles_are_separate_from_bad_role_counterexamples(self):
        result=ledger.read('reports/ordered-scatter.json')
        for value in result['value_controls']:
            self.assertEqual(value['translation_source'],value['translation_target'])
            self.assertEqual(value['pair_source'],value['concatenated'])
            self.assertEqual(value['pair_source'],value['nested'])
        roles=result['role_controls']
        self.assertTrue(all(r['source']==r['target'] for r in roles if r['first']!=r['second']))
        self.assertTrue(any(r['source']!=r['target'] and r['first']==r['second']=='current' for r in roles))
        self.assertTrue(any(r['source']!=r['target'] and r['first']==r['second']=='update' for r in roles))
        self.assertEqual((result['float_controls'][0]['source'],result['float_controls'][0]['target']),
                         (0,0x3f800000))
        self.assertFalse(result['floating_associativity_assumed'])

    def test_mutated_event_order_roles_policy_and_frozen_dependencies_are_rejected(self):
        result=ledger.read('reports/ordered-scatter.json');check.validate_result(result)
        changed=copy.deepcopy(result);next(e for e in changed['event_controls'] if e['target']==-1)['target']=0
        with self.assertRaises(AssertionError):check.validate_result(changed)
        changed=copy.deepcopy(result)
        row=next(r for r in changed['value_controls'] if len(r['trace'])>1)
        row['trace']=row['trace'][::-1]
        with self.assertRaises(AssertionError):check.validate_result(changed)
        for key in check.TRUE_FIELDS+check.FALSE_FIELDS:
            changed=copy.deepcopy(result);changed[key]=not changed[key]
            with self.assertRaises(AssertionError):check.validate_result(changed)
        original=check.digest
        for suffix in ('OrderedScatter.lean','OrderedScatterFullWindow.lean','OrderedScatterGraph.lean',
                       'OrderedScatterGeometry.lean','OrderedScatterCounterexamples.lean',
                       'OrderedScatterControls.lean','scatter_examples.py','ReducerIndex.lean',
                       'scatter-mathematical-domains-v1.json','workload-formulation-catalog-v2.json',
                       'lake-manifest.json'):
            def drift(path):return 'changed' if str(path).endswith(suffix) else original(path)
            with patch.object(check,'digest',side_effect=drift):
                with self.assertRaises(AssertionError):check.check_inputs()

    def test_legacy_scatter_and_gather_candidate_associations_are_separated(self):
        proofs=ledger.evidence()
        scatter=[p for p in proofs if '.Pilot.ReducerIndex.ScatterRoles.' in p['theorem']]
        gather=[p for p in proofs if '.Pilot.ReducerIndex.GatherLiterals.' in p['theorem']]
        self.assertTrue(scatter and gather)
        for proof in scatter:
            self.assertEqual(proof['historical_candidate_benchmark_labels'],
                             ['HandleAdd/scatter-single-lhs','HandleAdd/scatter-single-rhs'])
            self.assertIn('current/update parameter roles',proof['profile_descriptions'][0])
        for proof in gather:
            self.assertEqual(proof['historical_candidate_benchmark_labels'],['HandleGather/small-select-chain'])
            self.assertIn('represented-threshold',proof['profile_descriptions'][0])
        self.assertTrue(all(not p['label_correspondence_certified'] for p in scatter+gather))
        certificates=[p for p in proofs if 'ordered_scatter_contract_refutation' in p['kinds']]
        self.assertEqual(len(certificates),4)
        self.assertTrue(all(not p['historical_candidate_benchmark_labels'] for p in certificates))

    def test_partial_profile_refinement_does_not_close_tensor_concat_or_full_workload(self):
        result=ledger.read('reports/ordered-scatter.json')
        self.assertFalse(result['tensor_input_concatenation_bridge_proved'])
        self.assertFalse(result['all_scatter_dimension_numbers_supported'])
        self.assertFalse(result['whole_window_drop_policy_proved'])
        model=next(m for m in ledger.mathematical_models()
                   if m['model']=='ordered_full_window_scatter_and_trace_fusion_v1')
        self.assertFalse(model['full_family_complete'])
        self.assertFalse(model['tensor_input_concatenation_bridge_proved'])
        progress=ledger.read('census/mathematical-ledger.json')
        result=audit.assemble(ledger.corpus(),progress,audit.read_catalog())
        self.assertEqual(result['records_with_domain_worksheets'],488)
        self.assertEqual(result['records_with_only_unreviewed_proposal_worksheets'],374)
        self.assertEqual(result['whole_benchmark_records_closed'],0)
        self.assertIsNone(result['mathematical_obligation_denominator'])
        worksheet=ledger.read('census/scatter-mathematical-domains-v1.json')
        original_read=ledger.read
        subset=copy.deepcopy(original_read(audit.CATALOG))
        subset['worksheets']=[row for row in subset['worksheets']
                              if row['path']=='census/scatter-mathematical-domains-v1.json']
        def limited(path,root=ledger.ROOT):
            return subset if path==audit.CATALOG else original_read(path,root)
        original_digest=audit.digest
        def changed_second_source(path):
            return 'changed' if str(path).endswith('scalar-control-cases.json') else original_digest(path)
        with patch.object(ledger,'read',side_effect=limited):
            with patch.object(audit,'digest',side_effect=changed_second_source):
                with self.assertRaises(AssertionError):audit.read_catalog()
        self.assertEqual(len(worksheet['records']),6)
        self.assertFalse(any(r['whole_record_closed'] for r in worksheet['records']))


if __name__=='__main__':unittest.main()
