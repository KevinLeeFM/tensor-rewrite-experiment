"""Protect Dot-bridge evidence, coordinate observations, and mathematical claim limits."""
import copy
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]/'tools'))
import check_convolution_dot as dot
import mathematical_ledger as ledger


class ConvolutionDotTests(unittest.TestCase):
    def test_no_numerical_or_full_family_promotion(self):
        result=ledger.read('reports/convolution-dot.json');dot.validate_result(result)
        for key in ('full_convolution_family_complete', 'physical_layout_modeled',
                    'precision_conversions_modeled', 'ieee_accumulation_contract_proved',
                    'independently_reviewed_statements', 'code_correspondence_performed'):
            changed=copy.deepcopy(result);changed[key]=True
            with self.assertRaises(AssertionError):dot.validate_result(changed)
        for key in ('dot_tensor_bridge_proved', 'both_coordinate_round_trips_proved'):
            changed=copy.deepcopy(result);changed[key]=False
            with self.assertRaises(AssertionError):dot.validate_result(changed)

    def test_coordinate_or_direction_loss_is_rejected(self):
        result=ledger.read('reports/convolution-dot.json')
        for field in ('dot', 'row', 'feature'):
            changed=copy.deepcopy(result);changed['controls'][0][field]+=1
            with self.assertRaises(AssertionError):dot.validate_result(changed)
        changed=copy.deepcopy(result)
        changed['controls']=[r for r in changed['controls'] if r['direction']=='convolution']
        with self.assertRaises(AssertionError):dot.validate_result(changed)
        changed=copy.deepcopy(result);changed['profile_counts'].pop()
        with self.assertRaises(AssertionError):dot.validate_result(changed)
        changed=copy.deepcopy(result);changed['certificate_axioms'].popitem()
        with self.assertRaises(AssertionError):dot.validate_result(changed)

    def test_frozen_predecessors_and_new_coordinates_are_required(self):
        dot.check_inputs()
        original_digest=dot.digest
        for suffix in ('Convolution.lean', 'ConvolutionPointwise.lean', 'ConvolutionDot.lean',
                       'ConvolutionDotLemmas.lean', 'ConvolutionDotControls.lean'):
            def changed_digest(path):
                return 'changed' if str(path).endswith(suffix) else original_digest(path)
            with patch.object(dot, 'digest', side_effect=changed_digest):
                with self.assertRaises(AssertionError):dot.check_inputs()
        models=ledger.mathematical_models()
        self.assertTrue(models[-1]['dot_tensor_bridge_proved'])
        self.assertTrue(models[-1]['both_coordinate_round_trips_proved'])
        self.assertFalse(models[-1]['full_family_complete'])


if __name__=='__main__':unittest.main()
