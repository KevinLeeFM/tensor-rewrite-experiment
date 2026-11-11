"""Guard scientific reporting and frozen-model boundaries for the pointwise milestone."""
import copy
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]/'tools'))
import mathematical_ledger as ledger
from check_convolution_pointwise import validate_result


class ConvolutionPointwiseTests(unittest.TestCase):
    def test_no_partial_result_promotion(self):
        result=ledger.read('reports/convolution-pointwise.json')
        validate_result(result)
        for key in ('full_convolution_family_complete', 'dot_tensor_bridge_proved',
                    'physical_layout_modeled', 'precision_conversions_modeled',
                    'ieee_accumulation_contract_proved', 'independently_reviewed_statements',
                    'code_correspondence_performed'):
            changed=copy.deepcopy(result);changed[key]=True
            with self.assertRaises(AssertionError):validate_result(changed)
        changed=copy.deepcopy(result);changed['whole_benchmark_records_closed']=1
        with self.assertRaises(AssertionError):validate_result(changed)

    def test_missing_or_changed_semantic_evidence_is_rejected(self):
        result=ledger.read('reports/convolution-pointwise.json')
        changed=copy.deepcopy(result);changed['controls'].pop()
        with self.assertRaises(AssertionError):validate_result(changed)
        changed=copy.deepcopy(result);changed['controls'][0]['channel_sum']+=1
        with self.assertRaises(AssertionError):validate_result(changed)
        changed=copy.deepcopy(result);changed['profile_counts'].pop()
        with self.assertRaises(AssertionError):validate_result(changed)
        changed=copy.deepcopy(result);changed['certificate_axioms'].popitem()
        with self.assertRaises(AssertionError):validate_result(changed)

    def test_base_and_extension_pins_are_required(self):
        models=ledger.mathematical_models()
        self.assertEqual([m['checked_theorem_count'] for m in models], [20, 13, 12, 11, 15])
        self.assertTrue(all(not m['full_family_complete'] for m in models))
        original_digest=ledger.digest
        for suffix in ('Convolution.lean', 'ConvolutionPointwise.lean',
                       'ConvolutionPointwiseControls.lean', 'check_convolution_pointwise.py'):
            def changed_digest(path):
                return 'changed' if str(path).endswith(suffix) else original_digest(path)
            with patch.object(ledger, 'digest', side_effect=changed_digest):
                with self.assertRaises(AssertionError):ledger.mathematical_models()


if __name__=='__main__':unittest.main()
