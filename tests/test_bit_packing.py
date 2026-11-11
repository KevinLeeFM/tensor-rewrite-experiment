"""Protect representation semantics, explicit order/shape domains and partial workload accounting."""
import copy
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
import check_bit_packing as check
import bit_packing_examples as oracle
import mathematical_ledger as ledger
import workload_formulation_audit as audit


class BitPackingTests(unittest.TestCase):
    def test_independent_integer_stream_preserves_raw_words_across_widths_and_empty_shapes(self):
        self.assertEqual(oracle.repack_words([0x12,0x34],8,1,16,'lsb','lsb'),[0x3412])
        self.assertEqual(oracle.repack_words([0x12,0x34],8,1,16,'msb','msb'),[0x1234])
        self.assertEqual(oracle.repack_words([0,0],0,3,0,'lsb','msb'),[0,0,0])
        lines=oracle.expected_lines()
        self.assertEqual(len(lines),4127)
        self.assertTrue(any('BP_SHAPE rank=0 other=0 factor=4 width=8 order=lsb '
                            'input_shape=- output_shape=4'==line for line in lines))
        self.assertTrue(any('BP_LAYOUT in_col=true mid_col=false out_col=true' in line for line in lines))
        self.assertTrue(any('BP_FLOAT input=2147483648 bytes=0,0,0,128 back=2147483648'==line for line in lines))
        self.assertTrue(any('BP_BUFFER cells=4 width=3' in line for line in lines))

    def test_actual_graph_rows_reject_bit_order_shape_layout_word_and_float_mutations(self):
        result=check.read('reports/bit-packing.json');text=result['control_stdout']
        check.validate_controls(text)
        for old,new in [('out_order=msb','out_order=lsb'),('input_shape=- output_shape=4',
                         'input_shape=1 output_shape=4'),('out_col=true','out_col=false'),
                        ('bytes=0,0,0,128','bytes=128,0,0,0'),('back=2147483648','back=0')]:
            self.assertIn(old,text)
            with self.assertRaises(AssertionError):check.validate_controls(text.replace(old,new,1))
        first=next(line for line in text.splitlines() if 'direct=120' in line)
        with self.assertRaises(AssertionError):check.validate_controls(text.replace(first,first.replace('direct=120','direct=121'),1))

    def test_exact_storage_model_cannot_be_promoted_to_all_encodings_memory_or_numerical_casts(self):
        result=check.read('reports/bit-packing.json');check.validate_result(result)
        for key in check.FALSE_FIELDS:
            changed=copy.deepcopy(result);changed[key]=True
            with self.assertRaises(AssertionError):check.validate_result(changed)
        changed=copy.deepcopy(result);changed['nonempty_width_inference_guard_required']=False
        with self.assertRaises(AssertionError):check.validate_result(changed)
        changed=copy.deepcopy(result);next(iter(changed['certificate_axioms'].values())).append('sorryAx')
        with self.assertRaises(AssertionError):check.validate_result(changed)
        model=next(r for r in ledger.mathematical_models() if r['model']=='bounded_stored_word_bit_packing_v1')
        self.assertFalse(model['full_family_complete'])
        self.assertTrue(model['actual_word_stream_roundtrips_proved'])
        original=check.digest
        for row in check.check_inputs()['files']:
            with patch.object(check,'digest',side_effect=lambda path,target=row['path']:
                              'changed' if str(path).endswith(target) else original(path)):
                with self.assertRaises(AssertionError):check.check_inputs()

    def test_false_profiles_reject_normally_and_refutations_are_not_positive_bindings(self):
        result=check.read('reports/bit-packing.json');check.validate_result(result)
        changed=copy.deepcopy(result);changed['invalid_profile_rejections']['returncode']=0
        with self.assertRaises(AssertionError):check.validate_result(changed)
        changed=copy.deepcopy(result);changed['invalid_profile_rejections']['diagnostic']='unknown identifier'
        with self.assertRaises(AssertionError):check.validate_result(changed)
        counters=[r for r in ledger.evidence() if 'bit_packing_contract_refutation' in r['kinds']]
        self.assertEqual({r['theorem'] for r in counters},set(result['counterexample_certificates']))
        self.assertTrue(all(not r['historical_candidate_benchmark_labels'] for r in counters))

    def test_seven_partial_records_preserve_corpus_history_and_do_not_add_complete_profiles(self):
        progress=ledger.read('census/mathematical-ledger.json')
        old=audit.assemble(ledger.corpus(),progress,audit.read_catalog('census/workload-formulation-catalog-v10.json'))
        new=audit.assemble(ledger.corpus(),progress,audit.read_catalog('census/workload-formulation-catalog-v11.json'))
        self.assertEqual(old['records_with_only_unreviewed_proposal_worksheets'],213)
        self.assertEqual(new['records_with_only_unreviewed_proposal_worksheets'],206)
        self.assertEqual(new['records_with_domain_worksheets'],488)
        self.assertEqual(new['whole_benchmark_records_closed'],0)
        self.assertIsNone(new['mathematical_obligation_denominator'])
        self.assertGreaterEqual(progress['kernel_complete_family_profile_count'],397)
        frozen=check.check_inputs()
        rows={r['benchmark_id']:r for r in progress['benchmark_records']}
        for label in frozen['candidate_benchmark_labels']:
            self.assertEqual(rows[label]['mathematical_target_status'],
                             'partial_model_evidence_requires_partition_review')


if __name__=='__main__':unittest.main()
