"""Keep reduction domains complete, premises visible and partial results separate."""
import copy
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
import check_reduction_algebra as reduction
from reduction_examples import expected
import mathematical_ledger as ledger


class ReductionAlgebraTests(unittest.TestCase):
    def test_every_retained_record_remains_in_the_domain_diagnosis(self):
        domains=ledger.read(reduction.WORKSHEET);reduction.validate_domains(domains)
        for change in ('omit','duplicate','premise','guard','close'):
            changed=copy.deepcopy(domains)
            if change=='omit':changed['families'].pop()
            elif change=='duplicate':changed['families'][0]['benchmark_ids'].append(
                changed['families'][1]['benchmark_ids'][0])
            elif change=='premise':changed['families'][0]['declared_premises']=[]
            elif change=='guard':changed['source_guards_adopted_as_proof_assumptions']=True
            else:changed['families'][0]['whole_record_closed']=True
            with self.assertRaises(AssertionError):reduction.validate_domains(changed)
        broadcast=next(f for f in domains['families'] if f['classification']=='broadcast_axes')
        self.assertIn('commutative',' '.join(broadcast['declared_premises']))
        known={r['theorem'] for r in ledger.evidence()}
        known.add('TensorRewrite.Theory.ReductionFiber.splitEquiv')
        for family in domains['families']:
            for name in family['core_evidence']:
                full='TensorRewrite.'+('' if name.startswith('Pilot.') else 'Theory.')+name
                self.assertIn(full,known)

    def test_finite_controls_observe_empty_fibers_and_axis_order(self):
        counts,rows=expected()
        self.assertEqual(len(counts),9);self.assertEqual(len(rows),20)
        mixed=next(r for r in rows if r['name']=='mixed' and r['output']==0)
        self.assertEqual(mixed['fiber'],[1,2,5,6,9,10])
        empty=next(r for r in rows if r['name']=='empty_fiber')
        self.assertEqual((empty['fiber'],empty['sum'],empty['constant'],empty['max']),([],5,7,5))
        self.assertFalse(any(r['name']=='empty_output' for r in rows))
        changed=ledger.read('reports/reduction-algebra.json')
        next(r for r in changed['controls'] if r['name']=='mixed')['coords'].reverse()
        with self.assertRaises(AssertionError):reduction.validate_result(changed)

    def test_contracts_cannot_be_promoted_or_certificates_hidden(self):
        result=ledger.read('reports/reduction-algebra.json');reduction.validate_result(result)
        for key in ('ieee_addition_algebra_assumed','window_geometry_proved',
                    'full_reduction_family_complete','full_workload_complete',
                    'independently_reviewed_statements','benchmark_correspondence_certified',
                    'code_correspondence_performed'):
            changed=copy.deepcopy(result);changed[key]=True
            with self.assertRaises(AssertionError):reduction.validate_result(changed)
        changed=copy.deepcopy(result);changed['counterexample_certificates'].pop()
        with self.assertRaises(AssertionError):reduction.validate_result(changed)
        changed=copy.deepcopy(result);next(iter(changed['certificate_axioms'].values())).append('oracle')
        with self.assertRaises(AssertionError):reduction.validate_result(changed)
        model=next(m for m in ledger.mathematical_models() if m['model']==reduction.check_inputs()['model'])
        self.assertTrue(model['actual_ordered_fiber_to_coordinate_sum_proved'])
        self.assertFalse(model['full_family_complete'])

    def test_mathematical_sources_and_dependencies_are_pinned(self):
        original=reduction.digest
        for suffix in ('ReductionFiber.lean','ReductionFiberLemmas.lean','ReductionAlgebra.lean',
                       'ReductionCounterexamples.lean','ReductionAlgebraControls.lean',
                       'reduction_examples.py','reduction-mathematical-domains-v2.json',
                       'ReductionRules.lean','lake-manifest.json'):
            def changed(path):return 'changed' if str(path).endswith(suffix) else original(path)
            with patch.object(reduction,'digest',side_effect=changed):
                with self.assertRaises(AssertionError):reduction.check_inputs()


if __name__=='__main__':unittest.main()
