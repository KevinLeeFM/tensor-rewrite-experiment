"""Protect window padding/order observations and the boundary of the affine transformation."""
import copy
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
import check_reduction_window as window
import mathematical_ledger as ledger
from reduction_window_examples import expected


class ReductionWindowTests(unittest.TestCase):
    def test_all_window_records_and_core_names_are_retained(self):
        domains=ledger.read(window.DOMAINS);window.validate_domains(domains)
        self.assertEqual(domains['benchmark_record_count'],31)
        for mutation in ('omit','duplicate','close','guard'):
            changed=copy.deepcopy(domains)
            if mutation=='omit':changed['records'].pop()
            elif mutation=='duplicate':changed['records'][0]=copy.deepcopy(changed['records'][1])
            elif mutation=='close':changed['records'][0]['whole_record_closed']=True
            else:changed['source_guards_adopted_as_proof_assumptions']=True
            with self.assertRaises(AssertionError):window.validate_domains(changed)
        proofs={r['theorem']:r for r in ledger.evidence()}
        for row in domains['records']:
            for name in row['core_evidence']:
                self.assertIn(name,proofs)
                self.assertIn(row['benchmark_id'],proofs[name]['historical_candidate_benchmark_labels'])
        certificates=[r for r in proofs.values() if 'window_contract_refutation' in r['kinds']]
        self.assertEqual(len(certificates),2)
        self.assertTrue(all(not r['historical_candidate_benchmark_labels'] for r in certificates))

    def test_oracle_observes_padding_empty_windows_and_noncommutative_order(self):
        counts,rows=expected()
        byname=lambda n:[r for r in rows if r['name']==n]
        self.assertEqual(len(counts),15);self.assertEqual(len(rows),45)
        self.assertEqual(byname('empty_input')[0]['sum'],13)
        self.assertEqual(byname('empty_input')[0]['trace'],[0,0])
        self.assertEqual(byname('empty_kernel')[0]['sum'],7)
        self.assertEqual(byname('empty_kernel')[0]['trace'],[])
        self.assertEqual(byname('kernel_reversal')[0]['decimal'],321)
        self.assertFalse(next(c for c in counts if c['name']=='base_holes')['unit_affine'])
        self.assertNotEqual(byname('base_holes')[1]['zero'],byname('base_holes')[1]['gather'])
        self.assertTrue(all(r['gather']==0 for r in byname('crop_all_high')))
        changed=ledger.read('reports/reduction-window.json')
        next(r for r in changed['controls'] if r['name']=='kernel_reversal')['trace'].reverse()
        with self.assertRaises(AssertionError):window.validate_result(changed)

    def test_no_silent_padding_or_domain_relaxation_and_no_full_graph_promotion(self):
        result=ledger.read('reports/reduction-window.json');window.validate_result(result)
        for key in ('ieee_add_zero_identity_supplied','separate_slice_pad_graph_equivalence_proved',
                    'all_window_rewrites_proved','full_workload_complete','independently_reviewed_statements',
                    'benchmark_correspondence_certified','code_correspondence_performed'):
            changed=copy.deepcopy(result);changed[key]=True
            with self.assertRaises(AssertionError):window.validate_result(changed)
        for key in ('unit_affine_requires_undilated_input','invalid_samples_are_folded'):
            changed=copy.deepcopy(result);changed[key]=False
            with self.assertRaises(AssertionError):window.validate_result(changed)
        changed=copy.deepcopy(result);changed['counterexample_certificates'].pop()
        with self.assertRaises(AssertionError):window.validate_result(changed)
        changed=copy.deepcopy(result);changed['mathematical_obligation_denominator']=31
        with self.assertRaises(AssertionError):window.validate_result(changed)
        model=next(m for m in ledger.mathematical_models() if m['model']=='ordered_window_unit_affine_v1')
        self.assertTrue(model['unit_affine_gather_proved'])
        self.assertFalse(model['full_family_complete'])
        self.assertFalse(model['separate_slice_pad_graph_equivalence_proved'])

    def test_shared_geometry_and_new_mathematical_sources_are_pinned(self):
        original=window.digest
        for suffix in ('ReductionWindow.lean','ReductionWindowLemmas.lean',
                       'ReductionWindowAlgebra.lean','ReductionWindowCounterexamples.lean',
                       'ReductionWindowControls.lean','reduction_window_examples.py',
                       'reduction-window-domains-v1.json','Convolution.lean','lake-manifest.json'):
            def changed(path):return 'changed' if str(path).endswith(suffix) else original(path)
            with patch.object(window,'digest',side_effect=changed):
                with self.assertRaises(AssertionError):window.check_inputs()


if __name__=='__main__':unittest.main()
