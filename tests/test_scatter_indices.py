"""Protect actual raw-index packing, component decoding and nonempty zero-vector batches."""
import copy
from math import prod
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
import check_scatter_indices as check
import mathematical_ledger as ledger
from scatter_indices_examples import expected


class ScatterIndicesTests(unittest.TestCase):
    def test_all_raw_reader_and_relayout_controls_match_coordinate_oracle(self):
        result=ledger.read('reports/scatter-indices.json');check.validate_result(result)
        self.assertEqual(check.parse_controls(result['control_stdout']),expected())
        counts=result['reader_profile_counts']
        self.assertTrue(all(axis in {r['axis'] for r in counts} for axis in (-1,0,1,2)))
        self.assertTrue(any(r['axis']==-1 and r['target_axis']==0 for r in counts))
        self.assertTrue(any(r['axis']==0 and r['target_axis']==-1 for r in counts))
        self.assertTrue(any(r['batch']==[] and r['components']==1 for r in counts))
        self.assertTrue(all(r['value']==r['packed'] for r in result['raw_controls']))
        self.assertTrue(all(r['value']==r['moved'] for r in result['read_controls']))
        self.assertTrue(any(r['signed']!=r['unsigned'] for r in result['read_controls']))

    def test_zero_component_raw_emptiness_is_separate_from_implicit_singleton_and_empty_batch(self):
        result=ledger.read('reports/scatter-indices.json')
        implicit=[c for c in result['reader_profile_counts'] if c['axis']==-1]
        self.assertTrue(implicit);self.assertTrue(all(c['components']==1 for c in implicit))
        controls=result['scatter_profile_counts']
        self.assertTrue(any(c['components']==0 and prod(c['index_raw'])==0 and c['events']>1
                            and prod(c['batch'])>0 for c in controls))
        self.assertTrue(any(prod(c['batch'])==0 and c['events']==0 for c in controls))
        self.assertFalse(result['raw_index_emptiness_implies_no_events'])
        self.assertEqual(result['counterexample_certificates'],
                         ['TensorRewrite.Theory.ScatterIndices.empty_index_tensor_not_single_map'])

    def test_actual_scatter_relayout_is_exact_but_decoder_changes_can_change_results(self):
        result=ledger.read('reports/scatter-indices.json')
        self.assertTrue(all(v['decimal']==v['canonical']==v['moved'] and
                            v['word_source']==v['word_target'] for v in result['value_controls']))
        self.assertTrue(any(v['decimal']!=v['unsigned'] for v in result['value_controls']))
        self.assertFalse(result['signed_unsigned_decoders_identified'])
        self.assertTrue(any(e['target']==-1 for e in result['event_controls']))
        self.assertTrue(any(c['index_axis']==2 and c['events'] for c in result['scatter_profile_counts']))

    def test_wrong_coordinates_decoders_empty_assumptions_or_frozen_inputs_are_rejected(self):
        result=ledger.read('reports/scatter-indices.json')
        for field in check.TRUE_FIELDS+check.FALSE_FIELDS:
            changed=copy.deepcopy(result);changed[field]=not changed[field]
            with self.assertRaises(AssertionError):check.validate_result(changed)
        for group,field in [('raw_controls','value'),('read_controls','signed'),
                            ('relayout_controls','value'),('event_controls','target')]:
            changed=copy.deepcopy(result);changed[group][0][field]+=1
            with self.assertRaises(AssertionError):check.validate_result(changed)
        original=check.digest
        for suffix in ('IndexVector.lean','IndexVectorLemmas.lean','ScatterIndices.lean',
                       'ScatterIndicesProof.lean','ScatterIndicesCounterexample.lean',
                       'ScatterIndicesControls.lean','scatter_indices_examples.py',
                       'ScatterLayout.lean','IndexMaps.lean','lake-manifest.json'):
            def drift(path):return 'changed' if str(path).endswith(suffix) else original(path)
            with patch.object(check,'digest',side_effect=drift):
                with self.assertRaises(AssertionError):check.check_inputs()

    def test_extension_keeps_full_workload_review_and_general_dimensions_open(self):
        model=next(m for m in ledger.mathematical_models()
                   if m['model']=='explicit_implicit_raw_index_vectors_and_scatter_v1')
        self.assertTrue(model['implicit_index_vector_layout_supported'])
        self.assertFalse(model['operand_index_batching_supported'])
        self.assertFalse(model['general_transpose_graph_bridge_proved'])
        self.assertFalse(model['full_family_complete'])
        proofs=[p for p in ledger.evidence() if '.IndexVector.' in p['theorem'] or
                '.ScatterIndices.' in p['theorem']]
        self.assertEqual(len(proofs),20)
        self.assertEqual(sum(bool(p['historical_candidate_benchmark_labels']) for p in proofs),2)
        self.assertTrue(all(not p['label_correspondence_certified'] and
                            p['independent_statement_review']=='pending' for p in proofs))
        counter=next(p for p in proofs if p['theorem'].endswith('empty_index_tensor_not_single_map'))
        self.assertIn('raw_index_tensor_contract_counterexample',counter['kinds'])
        self.assertFalse(counter['historical_candidate_benchmark_labels'])


if __name__=='__main__':unittest.main()
