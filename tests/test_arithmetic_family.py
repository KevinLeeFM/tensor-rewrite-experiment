"""Protect complete typed exact arithmetic, actual Broadcast rebuilding and separate IEEE failures."""
import copy
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
import check_arithmetic_family as check
import mathematical_ledger as ledger
import workload_formulation_audit as audit
from arithmetic_examples import expected


class ArithmeticFamilyTests(unittest.TestCase):
    def test_closed_family_enumeration_covers_all_matched_orders_and_four_concrete_tracks(self):
        result=ledger.read('reports/arithmetic-values-family.json');check.validate_result(result)
        trees,profiles,values,counts,graphs,floats=check.parse_controls(result['control_stdout'])
        self.assertEqual((trees,profiles,values,counts,graphs),expected())
        self.assertEqual(len({r['id'] for r in result['profile_units']}),172)
        self.assertEqual({r['domain'] for r in result['profile_units']},
                         {'integer','real','complex','word_all_widths'})
        for prefix,count in [('four_factors_',8),('factor_',4),('add_assoc_',4),
                             ('mul_assoc_',4),('sub_add_constants_',2),('predicate_multiply_',2)]:
            self.assertEqual(sum(r['key'].startswith(prefix) for r in trees),count)
        self.assertTrue(all(v['lhs']==v['rhs'] for v in values+graphs))

    def test_exhaustive_words_and_actual_broadcast_graphs_include_wraparound_and_empty_shapes(self):
        result=ledger.read('reports/arithmetic-values-family.json')
        values=result['value_controls']
        for width,count in [(0,86),(1,1376),(2,22016)]:
            self.assertEqual(sum(v['domain']=='word' and v['width']==width for v in values),count)
        self.assertTrue(any(v['domain']=='integer' and v['lhs']<0 for v in values))
        self.assertTrue(any(v['domain']=='word' and any(x<0 for x in v['values']) for v in values))
        self.assertTrue(any(c['axes']==[1,0] for c in result['graph_counts']))
        self.assertTrue(any(0 in c['output'] for c in result['graph_counts']))
        self.assertTrue(any(c['small']==[] for c in result['graph_counts']))
        self.assertEqual(len(result['graph_controls']),480)

    def test_same_ast_refutations_and_actual_float_class_rejection_block_ieee_shortcuts(self):
        result=ledger.read('reports/arithmetic-values-family.json')
        self.assertEqual([(r['lhs'],r['rhs']) for r in result['float_controls'][:2]],
                         [(0,0x3f800000),(0,1)])
        self.assertEqual(result['float_controls'][2]['rhs'],0)
        self.assertNotEqual(result['float_controls'][2]['lhs'],0)
        self.assertNotEqual(result['negative_float_ring']['exit_code'],0)
        self.assertIn('CommRing Binary32',result['negative_float_ring']['output'])
        self.assertIn('error(lean.synthInstanceFailed)',result['negative_float_ring']['output'])
        self.assertFalse(result['ieee_commutative_ring_assumed'])
        self.assertEqual(len(result['counterexample_certificates']),3)

    def test_mutations_of_trees_values_domains_flags_dependencies_or_negative_control_are_rejected(self):
        result=ledger.read('reports/arithmetic-values-family.json')
        for field in check.TRUE_FIELDS+check.FALSE_FIELDS:
            changed=dict(result);changed[field]=not changed[field]
            with self.assertRaises(AssertionError):check.validate_result(changed)
        for group,field in [('expression_trees','rhs'),('value_controls','rhs'),('graph_controls','rhs')]:
            changed=copy.deepcopy(result)
            changed[group][0][field]=('x3' if group=='expression_trees' else changed[group][0][field]+1)
            with self.assertRaises(AssertionError):check.validate_result(changed)
        changed=dict(result,negative_float_ring=dict(exit_code=0,output='CommRing Binary32'))
        with self.assertRaises(AssertionError):check.validate_result(changed)
        original=check.digest
        for suffix in ('ArithmeticFamily.lean','ArithmeticFamilyProof.lean','ArithmeticBroadcast.lean',
                       'ArithmeticFloatCounterexamples.lean','ArithmeticFamilyControls.lean',
                       'arithmetic_examples.py','arithmetic-typed-domains-v1.json',
                       'mathlib/Mathlib/Data/BitVec.lean','lake-manifest.json'):
            def drift(path):return 'changed' if str(path).endswith(suffix) else original(path)
            with patch.object(check,'digest',side_effect=drift):
                with self.assertRaises(AssertionError):check.check_inputs()

    def test_typed_refinement_and_complete_profiles_preserve_all_other_workload_partitions(self):
        families=ledger.formulated_families()
        family=next(f for f in families if f['family']=='typed_commutative_ring_values_v1')
        self.assertEqual(family['profile_unit_count'],172)
        self.assertEqual(len(family['candidate_benchmark_labels']),33)
        self.assertFalse(family['label_correspondence_certified'])
        progress=ledger.read('census/mathematical-ledger.json')
        self.assertEqual(progress['kernel_complete_family_profile_count'],193)
        self.assertEqual(progress['whole_benchmark_records_closed'],0)
        self.assertIsNone(progress['mathematical_obligation_denominator'])
        rows=audit.assemble(ledger.corpus(),progress,audit.read_catalog())
        self.assertEqual(rows['records_with_domain_worksheets'],488)
        self.assertEqual(rows['records_with_only_unreviewed_proposal_worksheets'],309)
        records=ledger.read('census/arithmetic-typed-domains-v1.json')['records']
        self.assertEqual(len(records),34)
        self.assertTrue(all(not r['whole_record_closed'] for r in records))
        counter=[p for p in ledger.evidence() if 'arithmetic_ieee_profile_refutation' in p['kinds']]
        self.assertEqual(len(counter),3)
        self.assertTrue(all(not p['historical_candidate_benchmark_labels'] for p in counter))


if __name__=='__main__':unittest.main()
