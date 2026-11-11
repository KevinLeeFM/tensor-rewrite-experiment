"""Protect branch conventions, partial coverage and separate counterexample accounting."""
import copy
import json
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]/'tools'))
import check_scalar_domains as scalar
import mathematical_ledger as ledger
import check_theory as theory


class ScalarDomainTests(unittest.TestCase):
    def test_domain_profiles_cannot_be_promoted_to_rounded_or_full_workload_claims(self):
        result=ledger.read('reports/scalar-domains.json')
        scalar.validate_result(result)
        for key in ('rounded_transcendentals_modeled','fast_math_permissions_modeled',
                    'full_scalar_control_family_complete','full_workload_complete',
                    'independently_reviewed_statements','code_correspondence_performed',
                    'benchmark_correspondence_certified'):
            changed=copy.deepcopy(result);changed[key]=True
            with self.assertRaises(AssertionError):scalar.validate_result(changed)
        changed=copy.deepcopy(result);changed['profiles'][1]['domain']='all_complex_inputs'
        with self.assertRaises(AssertionError):scalar.validate_result(changed)
        changed=copy.deepcopy(result);changed['control_axioms'].popitem()
        with self.assertRaises(AssertionError):scalar.validate_result(changed)
        changed=copy.deepcopy(result)
        next(iter(changed['certificate_axioms'].values())).append('untrustedOracle')
        with self.assertRaises(AssertionError):scalar.validate_result(changed)

    def test_pins_and_half_open_branch_convention_are_required(self):
        original=scalar.digest
        for suffix in ('ScalarDomains.lean','ScalarDomainLemmas.lean',
                       'ScalarDomainCounterexamples.lean','ScalarDomainControls.lean',
                       'check_scalar_domains.py','lake-manifest.json'):
            def changed(path):
                return 'changed' if str(path).endswith(suffix) else original(path)
            with patch.object(scalar,'digest',side_effect=changed):
                with self.assertRaises(AssertionError):scalar.check_inputs()
        manifest=ledger.read(scalar.MANIFEST)
        manifest['complex_branch_strip']['lower_strict']=False
        with patch.object(scalar.json,'loads',return_value=manifest):
            with self.assertRaises(AssertionError):scalar.check_inputs()

    def test_counterexamples_stay_separate_and_no_whole_record_is_closed(self):
        manifest=scalar.check_inputs()
        proofs=ledger.evidence()
        certs=[r for r in proofs if 'scalar_domain_counterexample' in r['kinds']]
        self.assertEqual({r['theorem'] for r in certs},set(manifest['counterexample_certificates']))
        self.assertTrue(all(not r['label_correspondence_certified'] for r in certs))
        model=next(m for m in ledger.mathematical_models() if m['model']==manifest['model'])
        self.assertFalse(model['full_family_complete'])
        self.assertFalse(model['rounded_transcendentals_modeled'])
        self.assertEqual(model['checked_theorem_count'],14)
        self.assertEqual(theory.measure_file('TensorRewrite/Theory/ScalarDomainCounterexamples.lean',
                                            'C')[0]['category'],'C')
        self.assertFalse(any(r['whole_record_mathematically_closed']
                             for r in ledger.read('census/mathematical-ledger.json')['benchmark_records']))


if __name__=='__main__':unittest.main()
