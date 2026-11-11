"""Protect mixed-window evidence and preserve the unresolved mathematical workload."""
import copy
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]/'tools'))
import check_convolution_separable as separable
import mathematical_ledger as ledger


class ConvolutionSeparableTests(unittest.TestCase):
    def test_reversal_axes_empty_domains_and_claim_limits(self):
        result=ledger.read('reports/convolution-separable.json');separable.validate_result(result)
        values={r['name']:r['convolution'] for r in result['controls']}
        self.assertEqual(values['spanning'],14)
        self.assertEqual(values['spanning_reversed'],10)
        self.assertEqual(values['empty_kernel'],0)
        for field in ('nonunit_axes_only','kernel_reversal_reindexed'):
            changed=copy.deepcopy(result);changed[field]=False
            with self.assertRaises(AssertionError):separable.validate_result(changed)
        for field in ('precision_conversions_modeled','ieee_accumulation_contract_proved',
                      'full_convolution_family_complete','independently_reviewed_statements'):
            changed=copy.deepcopy(result);changed[field]=True
            with self.assertRaises(AssertionError):separable.validate_result(changed)
        changed=copy.deepcopy(result);changed['profile_counts'][0]['axes']+=1
        with self.assertRaises(AssertionError):separable.validate_result(changed)
        changed=copy.deepcopy(result);changed['controls'].pop()
        with self.assertRaises(AssertionError):separable.validate_result(changed)

    def test_retained_variants_and_composition_gaps_cannot_disappear(self):
        domains=separable.validate_domains()
        variants=[r for r in domains['records'] if 'partition_flags' in r]
        self.assertEqual(len(variants),12)
        with tempfile.TemporaryDirectory() as folder:
            root=Path(folder);(root/'census').mkdir()
            (root/domains['retained_batch']).write_bytes((ledger.ROOT/domains['retained_batch']).read_bytes())
            for mutation in ('omit_record','close_record','freeze_denominator','cast_promotion'):
                changed=copy.deepcopy(domains)
                if mutation=='omit_record':changed['records'].pop()
                elif mutation=='close_record':changed['records'][0]['whole_benchmark_record_closed']=True
                elif mutation=='freeze_denominator':changed['mathematical_obligation_denominator']=31
                else:
                    row=next(r for r in changed['records'] if 'partition_flags' in r
                             and r['partition_flags']['input_conversion'])
                    row['existing_or_current_exact_model_evidence']=['invented_conversion_theorem']
                (root/separable.DOMAINS).write_text(json.dumps(changed))
                with self.assertRaises(AssertionError):separable.validate_domains(root)

    def test_frozen_inputs_and_model_registration(self):
        separable.check_inputs()
        original_digest=separable.digest
        for suffix in ('Convolution.lean','ConvolutionPointwiseLemmas.lean',
                       'ConvolutionSeparable.lean','ConvolutionSeparableReindex.lean',
                       'convolution-mathematical-domains-v1.json'):
            def changed_digest(path):
                return 'changed' if str(path).endswith(suffix) else original_digest(path)
            with patch.object(separable,'digest',side_effect=changed_digest):
                with self.assertRaises(AssertionError):separable.check_inputs()
        model=ledger.mathematical_models()[-1]
        self.assertEqual(model['checked_theorem_count'],11)
        self.assertTrue(model['nonunit_axes_only'] and model['kernel_reversal_reindexed'])
        self.assertFalse(model['full_family_complete'])


if __name__=='__main__':unittest.main()
