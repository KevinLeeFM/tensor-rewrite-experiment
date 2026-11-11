"""Mathematical convolution controls and reporting boundaries only."""
import copy
from pathlib import Path
import sys
import unittest

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
from convolution_examples import evaluate, expected_rows
from check_convolution_model import validate_result
import mathematical_ledger as ledger


class ConvolutionModelTests(unittest.TestCase):
    def test_checked_model_and_independent_vectors(self):
        result=ledger.read('reports/convolution-model.json');validate_result(result)
        self.assertEqual(len(expected_rows()),22)
        self.assertEqual(ledger.mathematical_models()[0]['checked_theorem_count'],20)
        self.assertFalse(ledger.mathematical_models()[0]['full_family_complete'])

    def test_no_floating_or_whole_family_promotion(self):
        result=ledger.read('reports/convolution-model.json')
        for key in ('ieee_accumulation_contract_proved','precision_conversions_modeled',
                    'physical_layout_modeled','full_convolution_family_complete'):
            changed=copy.deepcopy(result);changed[key]=True
            with self.assertRaises(AssertionError):validate_result(changed)
        changed=copy.deepcopy(result);changed['scalar_contract']='rounded_binary32'
        with self.assertRaises(AssertionError):validate_result(changed)

    def test_controls_cannot_omit_empty_or_dilation_profiles(self):
        result=ledger.read('reports/convolution-model.json')
        for profile in ('empty_input_padded','base_dilation_hole','no_spatial_axes'):
            changed=copy.deepcopy(result)
            changed['controls']=[row for row in changed['controls'] if row['name']!=profile]
            with self.assertRaises(AssertionError):validate_result(changed)
        changed=copy.deepcopy(result);changed['negative_controls']={}
        with self.assertRaises(AssertionError):validate_result(changed)

    def test_geometry_is_not_clamped_to_an_input_edge(self):
        # At a padded low edge, only the second kernel coordinate is occupied.
        self.assertEqual(evaluate(low=(1,),high=(1,)),2)
        self.assertEqual(evaluate(inputs=(3,),bases=(2,),output=(1,)),4)
        self.assertIsNone(evaluate(output=(4,)))
        # Signed cropping and window reversal deliberately select different coordinates.
        self.assertNotEqual(evaluate(low=(-1,)),evaluate())
        self.assertNotEqual(evaluate(reverse=True),evaluate())


if __name__=='__main__':unittest.main()
