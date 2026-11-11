"""Guard the actual raw-coordinate bridge, event order, coupled values and explicit scope limits."""
import copy
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
import check_scatter_layout as check
import mathematical_ledger as ledger
from scatter_layout_examples import expected


class ScatterLayoutTests(unittest.TestCase):
    def test_actual_interleaved_and_inserted_coordinates_match_dense_oracle(self):
        result=ledger.read('reports/scatter-layout.json');check.validate_result(result)
        self.assertEqual(check.parse_controls(result['control_stdout']),expected())
        counts=result['profile_counts'];events=result['event_controls'];values=result['value_controls']
        self.assertTrue(any(c['update_mask']==[1,0] and c['events'] for c in counts))
        self.assertTrue(any(c['update_mask']==[0,1,0,1] and c['events'] for c in counts))
        self.assertTrue(any(c['insert_mask']==[0,1,0] and c['events'] for c in counts))
        self.assertTrue(any(c['compact']==[] and c['events']>1 for c in counts))
        self.assertTrue(any(0 in c['batch'] and c['events']==0 for c in counts))
        self.assertTrue(any(0 in c['compact'] and c['events']==0 for c in counts))
        self.assertTrue(any(e['target']==-1 for e in events))
        self.assertTrue(all(v['decimal']==v['canonical'] and v['source']==v['target']
                            and v['word_source']==v['word_target']
                            and v['coupled']==v['coupled_canonical'] for v in values))

    def test_raw_storage_order_is_observably_different_and_has_a_kernel_certificate(self):
        result=ledger.read('reports/scatter-layout.json')
        self.assertEqual(sum(v['decimal']!=v['storage'] for v in result['value_controls']),4)
        profile=next(c['profile'] for c in result['profile_counts'] if c['operand']==[1]
                     and c['raw']==[2,2] and c['update_mask']==[1,0])
        row=next(v for v in result['value_controls'] if v['profile']==profile)
        self.assertEqual((row['decimal'],row['storage']),(232,223))
        self.assertEqual(result['counterexample_certificates'],
                         ['TensorRewrite.Theory.ScatterLayout.raw_storage_order_refuted'])
        self.assertFalse(result['raw_storage_order_equality_assumed'])
        self.assertFalse(result['floating_associativity_assumed'])

    def test_changed_pairing_insertions_and_unsupported_claims_are_rejected(self):
        result=ledger.read('reports/scatter-layout.json')
        for field in check.TRUE_FIELDS+check.FALSE_FIELDS:
            changed=copy.deepcopy(result);changed[field]=not changed[field]
            with self.assertRaises(AssertionError):check.validate_result(changed)
        for key,field in [('event_controls','value'),('event_controls','target'),
                          ('value_controls','decimal')]:
            changed=copy.deepcopy(result);changed[key][0][field]+=1
            with self.assertRaises(AssertionError):check.validate_result(changed)
        changed=copy.deepcopy(result)
        next(c for c in changed['profile_counts'] if c['insert_mask']==[1,0])['insert_mask']=[0,1]
        with self.assertRaises(AssertionError):check.validate_result(changed)
        original=check.digest
        for suffix in ('ScatterLayout.lean','ScatterLayoutLemmas.lean','ScatterLayoutProof.lean',
                       'ScatterLayoutCounterexample.lean','ScatterLayoutControls.lean',
                       'scatter_layout_examples.py','ReductionFiber.lean',
                       'ReductionFiberLemmas.lean','OrderedScatter.lean','lake-manifest.json'):
            def drift(path):return 'changed' if str(path).endswith(suffix) else original(path)
            with patch.object(check,'digest',side_effect=drift):
                with self.assertRaises(AssertionError):check.check_inputs()

    def test_new_layout_model_remains_partial_with_uncertified_candidate_labels(self):
        model=next(m for m in ledger.mathematical_models()
                   if m['model']=='raw_update_layout_and_inserted_scatter_windows_v1')
        self.assertTrue(model['arbitrary_batch_window_axis_interleaving'])
        self.assertTrue(model['inserted_singleton_window_axes_derived'])
        self.assertFalse(model['operand_index_batching_supported'])
        self.assertFalse(model['implicit_index_vector_layout_supported'])
        self.assertFalse(model['full_family_complete'])
        proofs=[p for p in ledger.evidence() if '.ScatterLayout.' in p['theorem']]
        self.assertEqual(len(proofs),16)
        bound=[p for p in proofs if p['historical_candidate_benchmark_labels']]
        self.assertEqual(len(bound),4)
        self.assertTrue(all(not p['label_correspondence_certified'] and
                            p['independent_statement_review']=='pending' for p in proofs))
        counter=next(p for p in proofs if p['theorem'].endswith('raw_storage_order_refuted'))
        self.assertIn('scatter_layout_order_refutation',counter['kinds'])
        self.assertFalse(counter['historical_candidate_benchmark_labels'])


if __name__=='__main__':unittest.main()
