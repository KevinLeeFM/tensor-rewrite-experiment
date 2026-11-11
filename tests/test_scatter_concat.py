"""Protect actual tensor-input bridging and the stated limits of leading-axis concatenation."""
import copy
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
import check_scatter_concat as check
import mathematical_ledger as ledger
from scatter_concat_examples import expected


class ScatterConcatTests(unittest.TestCase):
    def test_coordinate_oracle_matches_actual_concatenated_inputs_and_order(self):
        result=ledger.read('reports/scatter-concat.json')
        check.validate_result(result)
        self.assertEqual(check.parse_controls(result['control_stdout']),expected())
        counts=result['profile_counts'];events=result['event_controls']
        self.assertTrue(any(c['first']==0<c['second'] and c['events'] for c in counts))
        self.assertTrue(any(c['second']==0<c['first'] and c['events'] for c in counts))
        self.assertTrue(any(c['tail']==[2,0] and c['events']==0 for c in counts))
        self.assertTrue(any(c['tail']==[2,2] and c['events'] for c in counts))
        self.assertTrue(any(c['operand']==[] and c['events']>1 for c in counts))
        self.assertTrue(any(c['axes']==[1,0] and c['events'] for c in counts))
        self.assertTrue(any(e['target']==-1 for e in events))
        profile=next(c['profile'] for c in counts if c['operand']==[] and
                     c['first']==c['second']==1 and c['tail']==[])
        trace=[e['value'] for e in events if e['profile']==profile]
        self.assertEqual(trace,[1,14])
        value=next(v for v in result['value_controls'] if v['profile']==profile)
        self.assertEqual(value['decimal'],224)
        self.assertEqual(value['word_source'],2)

    def test_corrupted_order_payload_pairing_and_overclaimed_layouts_are_rejected(self):
        result=ledger.read('reports/scatter-concat.json')
        for field in check.TRUE_FIELDS+check.FALSE_FIELDS:
            mutated=copy.deepcopy(result);mutated[field]=not mutated[field]
            with self.assertRaises(AssertionError):check.validate_result(mutated)
        changed=copy.deepcopy(result)
        changed['event_controls'][0]['value']+=1
        with self.assertRaises(AssertionError):check.validate_result(changed)
        changed=copy.deepcopy(result)
        a,b=next((a,b) for a,b in zip(range(len(changed['event_controls'])-1),
                                     range(1,len(changed['event_controls'])))
                 if changed['event_controls'][a]['profile']==changed['event_controls'][b]['profile'])
        changed['event_controls'][a],changed['event_controls'][b]=(
            changed['event_controls'][b],changed['event_controls'][a])
        with self.assertRaises(AssertionError):check.validate_result(changed)
        original=check.digest
        for suffix in ('ScatterConcat.lean','ScatterConcatLemmas.lean','ScatterConcatProof.lean',
                       'ScatterConcatControls.lean','scatter_concat_examples.py',
                       'OrderedScatter.lean','OrderedCoordinates.lean','lake-manifest.json'):
            def drift(path):return 'changed' if str(path).endswith(suffix) else original(path)
            with patch.object(check,'digest',side_effect=drift):
                with self.assertRaises(AssertionError):check.check_inputs()

    def test_refined_profile_remains_partial_and_old_trace_milestone_is_preserved(self):
        models=ledger.mathematical_models()
        old=next(m for m in models if m['model']=='ordered_full_window_scatter_and_trace_fusion_v1')
        new=next(m for m in models if m['model']=='leading_batch_tensor_concat_scatter_v1')
        self.assertFalse(old['tensor_input_concatenation_bridge_proved'])
        self.assertTrue(new['leading_batch_axis_bridge_proved'])
        self.assertFalse(new['arbitrary_concat_axis_bridge_proved'])
        self.assertFalse(new['full_family_complete'])
        proofs=[p for p in ledger.evidence() if '.ScatterConcat.' in p['theorem']]
        self.assertEqual(len(proofs),9)
        bound=[p for p in proofs if p['historical_candidate_benchmark_labels']]
        self.assertEqual(len(bound),3)
        self.assertTrue(all(p['historical_candidate_benchmark_labels']==['HandleAdd/scatter-concat']
                            and not p['label_correspondence_certified'] for p in bound))
        self.assertTrue(all(p['independent_statement_review']=='pending' for p in proofs))


if __name__=='__main__':unittest.main()
