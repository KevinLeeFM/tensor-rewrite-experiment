"""Guard actual paired batch-coordinate targets, raw layouts, counterexamples and scoped claims."""
import copy
from math import prod
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
import check_scatter_batching as check
import mathematical_ledger as ledger
from scatter_batching_examples import expected


class ScatterBatchingTests(unittest.TestCase):
    def test_actual_paired_coordinates_and_raw_axis_metadata_match_independent_oracle(self):
        result=ledger.read('reports/scatter-batching.json');check.validate_result(result)
        self.assertEqual(check.parse_controls(result['control_stdout']),expected())
        counts=result['profile_counts']
        self.assertTrue(any(c['operand_pairs']==[1,0] and c['index_pairs']==[0,1]
                            and c['events'] for c in counts))
        self.assertTrue(any(c['operand_pairs']==[1,0] and c['index_pairs']==[1,0]
                            and c['events'] for c in counts))
        self.assertTrue(any(c['index_pairs']==[1] and c['raw_index_pairs']==[2]
                            and c['vector_axis']==1 and c['events'] for c in counts))
        self.assertTrue(any(c['components']==2 and c['index_axes']==[2,1] and c['events'] for c in counts))
        self.assertTrue(any(c['components']==0 and prod(c['index_raw'])==0 and c['events']>1
                            and c['operand_pairs'] for c in counts))
        self.assertTrue(any(e['target']==-1 for e in result['event_controls']))

    def test_ignoring_batching_changes_slices_and_zero_pair_case_recovers_old_targets(self):
        result=ledger.read('reports/scatter-batching.json')
        self.assertEqual(sum(v['decimal']!=v['ignored'] for v in result['value_controls']),664)
        counts={c['profile']:c for c in result['profile_counts']}
        no_pairs=[v for v in result['value_controls'] if not counts[v['profile']]['operand_pairs']]
        self.assertTrue(no_pairs)
        self.assertTrue(all(v['decimal']==v['ignored'] for v in no_pairs))
        self.assertEqual(result['counterexample_certificates'],
                         ['TensorRewrite.Theory.ScatterBatching.forgetting_batching_refuted'])
        self.assertTrue(all(v['decimal']==v['canonical']==v['moved'] and
                            v['translated']==v['translation_target'] and v['pair']==v['nested']
                            for v in result['value_controls']))

    def test_partial_pairing_retains_unpaired_batch_updates_and_zero_extent_cases(self):
        result=ledger.read('reports/scatter-batching.json');counts=result['profile_counts']
        partial={c['profile'] for c in counts if len(c['batch'])==2 and len(c['operand_pairs'])==1}
        self.assertTrue(partial)
        seen={};duplicate=False
        for e in result['event_controls']:
            if e['profile'] not in partial or e['target']==-1:continue
            key=(e['profile'],e['target'])
            duplicate|=key in seen;seen[key]=True
        self.assertTrue(duplicate)
        self.assertTrue(any(prod(c['batch'])==0 and c['events']==0 for c in counts))
        self.assertTrue(any(prod(c['compact'])==0 and c['events']==0 for c in counts))
        self.assertTrue(any(c['operand']==[] and c['events']==1 for c in counts))

    def test_mutated_pairing_coordinates_legal_attributes_or_claims_are_rejected(self):
        result=ledger.read('reports/scatter-batching.json')
        for field in check.TRUE_FIELDS+check.FALSE_FIELDS:
            changed=copy.deepcopy(result);changed[field]=not changed[field]
            with self.assertRaises(AssertionError):check.validate_result(changed)
        for field in ('operand_pairs','index_pairs','raw_index_pairs'):
            changed=copy.deepcopy(result)
            row=next(c for c in changed['profile_counts'] if len(c[field])==2)
            row[field]=row[field][::-1]
            with self.assertRaises(AssertionError):check.validate_result(changed)
        changed=copy.deepcopy(result);changed['event_controls'][0]['target']+=1
        with self.assertRaises(AssertionError):check.validate_result(changed)
        original=check.digest
        for suffix in ('ScatterBatching.lean','ScatterBatchingLemmas.lean','ScatterBatchingProof.lean',
                       'ScatterBatchingCounterexample.lean','ScatterBatchingControls.lean',
                       'scatter_batching_examples.py','IndexVector.lean','IndexVectorLemmas.lean',
                       'ScatterLayout.lean','OrderedScatterGeometry.lean','lake-manifest.json'):
            def drift(path):return 'changed' if str(path).endswith(suffix) else original(path)
            with patch.object(check,'digest',side_effect=drift):
                with self.assertRaises(AssertionError):check.check_inputs()

    def test_batched_extension_keeps_general_graph_and_workload_review_open(self):
        model=next(m for m in ledger.mathematical_models()
                   if m['model']=='paired_operand_index_batching_and_raw_scatter_v1')
        self.assertTrue(model['operand_index_batching_supported'])
        self.assertTrue(model['canonical_target_and_trace_bridge'])
        self.assertFalse(model['general_raw_concat_graph_bridge_proved'])
        self.assertFalse(model['full_family_complete'])
        proofs=[p for p in ledger.evidence() if '.ScatterBatching.' in p['theorem']]
        self.assertEqual(len(proofs),22)
        self.assertEqual(sum(bool(p['historical_candidate_benchmark_labels']) for p in proofs),3)
        self.assertTrue(all(not p['label_correspondence_certified'] and
                            p['independent_statement_review']=='pending' for p in proofs))
        counter=next(p for p in proofs if p['theorem'].endswith('forgetting_batching_refuted'))
        self.assertIn('paired_scatter_batching_contract_refutation',counter['kinds'])
        self.assertFalse(counter['historical_candidate_benchmark_labels'])


if __name__=='__main__':unittest.main()
