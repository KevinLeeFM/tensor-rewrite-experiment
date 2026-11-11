"""Protect derived Slice legality, output shape and the boundary of the window corollary."""
import copy
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
import check_slice_pad as factor
import mathematical_ledger as ledger
from slice_pad_examples import expected


class SlicePadTests(unittest.TestCase):
    def test_rounding_and_empty_slice_endpoints_are_observed(self):
        axes,profiles,rows=expected()
        self.assertEqual((len(axes),len(profiles),len(rows)),(675,15,45))
        fractional=next(a for a in axes if (a['n'],a['outputs'],a['stride'],a['low'])==(4,3,2,1))
        self.assertEqual((fractional['first'],fractional['start'],fractional['count']),(1,1,2))
        empty=next(a for a in axes if (a['n'],a['outputs'],a['stride'],a['low'])==(1,3,3,1))
        self.assertEqual((empty['count'],empty['start'],empty['limit']),(0,1,1))
        self.assertTrue(all(a['shape']==a['outputs'] and a['legal'] for a in axes))
        result=ledger.read('reports/slice-pad.json')
        next(a for a in result['axis_controls'] if a==fractional)['start']=0
        with self.assertRaises(AssertionError):factor.validate_result(result)

    def test_separate_graph_agrees_and_unit_window_premises_cannot_be_erased(self):
        _,profiles,rows=expected();eligible={r['name'] for r in profiles if r['eligible']}
        self.assertTrue(all(r['graph']==r['gather'] for r in rows))
        self.assertTrue(all(r['zero_graph']==r['zero_window'] for r in rows if r['name'] in eligible))
        self.assertTrue(any(r['zero_graph']!=r['zero_window'] for r in rows if r['name']=='base_holes'))
        result=ledger.read('reports/slice-pad.json');factor.validate_result(result)
        for key in ('unit_window_side_conditions_retained','slice_attributes_well_formed',
                    'output_shape_equality_derived','separate_slice_pad_graph_equivalence_proved'):
            changed=copy.deepcopy(result);changed[key]=False
            with self.assertRaises(AssertionError):factor.validate_result(changed)
        for key in ('shape_or_index_equivalence_postulated','ieee_zero_identity_supplied',
                    'all_window_rewrites_proved','full_workload_complete',
                    'independently_reviewed_statements','benchmark_correspondence_certified',
                    'code_correspondence_performed'):
            changed=copy.deepcopy(result);changed[key]=True
            with self.assertRaises(AssertionError):factor.validate_result(changed)
        changed=copy.deepcopy(result);changed['counterexample_certificates'].pop()
        with self.assertRaises(AssertionError):factor.validate_result(changed)

    def test_new_graph_evidence_cannot_close_whole_benchmark_records(self):
        model=next(m for m in ledger.mathematical_models() if m['model']=='derived_map_slice_pad_v1')
        self.assertTrue(model['separate_slice_pad_graph_equivalence_proved'])
        self.assertFalse(model['full_family_complete'])
        self.assertEqual(model['base_window_manifest'],'census/reduction-window-v1.json')
        proofs=ledger.evidence()
        certificates=[r for r in proofs if 'slice_pad_geometry_refutation' in r['kinds']]
        self.assertEqual(len(certificates),2)
        self.assertTrue(all(not r['historical_candidate_benchmark_labels'] for r in certificates))
        result=ledger.read('census/mathematical-ledger.json')
        self.assertIsNone(result['mathematical_obligation_denominator'])
        self.assertFalse(any(r['whole_record_mathematically_closed'] for r in result['benchmark_records']))

    def test_ordinary_slice_operator_and_new_geometry_are_pinned(self):
        original=factor.digest
        for suffix in ('SlicePad.lean','SlicePadLemmas.lean','SlicePadFactor.lean',
                       'SlicePadCounterexamples.lean','SlicePadControls.lean','slice_pad_examples.py',
                       'ReductionWindowAlgebra.lean','SliceShape.lean','IndexMapLemmas.lean',
                       'lake-manifest.json'):
            def changed(path):return 'changed' if str(path).endswith(suffix) else original(path)
            with patch.object(factor,'digest',side_effect=changed):
                with self.assertRaises(AssertionError):factor.check_inputs()


if __name__=='__main__':unittest.main()
