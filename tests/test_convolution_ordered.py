"""Protect ordered numerical observations and preserve unsupported-contract gaps."""
import copy
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
import check_convolution_ordered as ordered
import mathematical_ledger as ledger
from ordered_float_examples import add, decode, encode, expected_rows, multiply


class ConvolutionOrderedTests(unittest.TestCase):
    def test_independent_oracle_distinguishes_signed_zero_and_rounding(self):
        for word in (0,0x80000000,1,0x007fffff,0x00800000,0x3f800000,0x7f7fffff):
            self.assertEqual(encode(decode(word),bool(word>>31)),word)
        self.assertEqual(multiply(0x80000000,0x3f800000),0x80000000)
        self.assertEqual(add(0,0x80000000),0)
        self.assertEqual(add(0x80000000,0x80000000),0x80000000)
        self.assertEqual(add(0x007fffff,1),0x00800000)
        self.assertEqual(add(0x3f800000,0x33800000),0x3f800000)
        rows={n:int(c) for n,c,_,_ in expected_rows()}
        self.assertNotEqual(rows['finite_order'],rows['finite_reverse'])
        for word in (0x7f800000,0x7fc00000):
            with self.assertRaises(ValueError):decode(word)

    def test_value_evidence_cannot_promote_to_external_backend_or_changed_precision(self):
        result=ledger.read('reports/convolution-ordered.json');ordered.validate_result(result)
        for key in ('semiring_assumed_for_ordered_dot','fma_modeled','exception_flags_observed',
                    'changed_cast_placement_equivalence_proved','external_backend_schedule_verified',
                    'full_convolution_family_complete','full_numerical_workload_complete',
                    'independently_reviewed_statements','code_correspondence_performed'):
            changed=copy.deepcopy(result);changed[key]=True
            with self.assertRaises(AssertionError):ordered.validate_result(changed)
        changed=copy.deepcopy(result);changed['finite_binary32_controls'][0]['dot']+=1
        with self.assertRaises(AssertionError):ordered.validate_result(changed)
        changed=copy.deepcopy(result);changed['heterogeneous_control']['dot']+=1
        with self.assertRaises(AssertionError):ordered.validate_result(changed)
        changed=copy.deepcopy(result);changed['fold_omission_words'][1]=0
        with self.assertRaises(AssertionError):ordered.validate_result(changed)
        changed=copy.deepcopy(result);changed['certificate_axioms'].popitem()
        with self.assertRaises(AssertionError):ordered.validate_result(changed)

    def test_ordered_contract_pins_and_refutations_remain_separate(self):
        ordered.check_inputs()
        original_digest=ordered.digest
        for suffix in ('Convolution.lean','ConvolutionDot.lean','ConvolutionOrdered.lean',
                       'ConvolutionFloat.lean','ordered_float_examples.py','lake-manifest.json'):
            def changed_digest(path):
                return 'changed' if str(path).endswith(suffix) else original_digest(path)
            with patch.object(ordered,'digest',side_effect=changed_digest):
                with self.assertRaises(AssertionError):ordered.check_inputs()
        model=ledger.mathematical_models()[-1]
        self.assertTrue(model['binary32_ordered_pointwise_proved'])
        self.assertFalse(model['external_backend_schedule_verified'])
        self.assertFalse(model['full_family_complete'])
        refutations=[r for r in ledger.evidence() if 'numerical_contract_refutation' in r['kinds']]
        self.assertEqual(len(refutations),2)
        self.assertTrue(all(not r['label_correspondence_certified'] for r in refutations))


if __name__=='__main__':unittest.main()
