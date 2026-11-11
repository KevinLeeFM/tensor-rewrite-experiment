"""Guard exact numeric domains, independent controls and honest partial-workload accounting."""
import copy
from fractions import Fraction
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]/'tools'))
import check_numerical as check
import numerical_examples as oracle
import mathematical_ledger as ledger
import workload_formulation_audit as audit
import check_theory as theory


class NumericalTests(unittest.TestCase):
    def test_frozen_semantic_inputs_and_domain_restrictions_are_enforced(self):
        manifest = check.check_inputs()
        self.assertEqual(len(manifest['candidate_benchmark_labels']), 31)
        original = check.digest
        for suffix in ('NumericalField.lean', 'NumericalReal.lean', 'NumericalComplex.lean',
                       'NumericalCounterexamples.lean', 'NumericalControls.lean',
                       'InvalidNumericalWordField.lean', 'numerical_examples.py',
                       'check_numerical.py', 'numerical-typed-domains-v1.json', 'lake-manifest.json'):
            with patch.object(check, 'digest', side_effect=lambda path, suffix=suffix:
                              'changed' if str(path).endswith(suffix) else original(path)):
                with self.assertRaises(AssertionError):
                    check.check_inputs()
        changed = copy.deepcopy(manifest)
        changed['complex_log_power_strip']['lower_strict'] = False
        with patch.object(check.json, 'loads', return_value=changed):
            with self.assertRaises(AssertionError):
                check.check_inputs()

    def test_independent_controls_include_zero_denominators_and_signed_values(self):
        rows = oracle.field_rows()
        self.assertEqual(len(rows), 625)
        self.assertEqual(len(rows[0][2]), 9)
        for axis in (1, 2, 3):
            self.assertEqual(sum(values[axis] == 0 for _, values, _, _ in rows), 125)
        self.assertEqual(oracle.divide(Fraction(1), Fraction(2)), Fraction(1, 2))
        counts, graphs = oracle.graph_rows()
        self.assertEqual(len(counts), 5)
        self.assertEqual(len(graphs), 48)
        self.assertTrue(any(value < 0 for _, _, _, value, _ in graphs))
        self.assertTrue(any(value == 0 for _, _, _, value, _ in graphs))
        self.assertEqual({r[2] for r in graphs}, {'divide', 'predicatefalse', 'predicatetrue'})
        result = ledger.read('reports/numerical-values.json')
        check.validate_controls(result['control_stdout'])
        for bad in (result['control_stdout'].replace('sample=0 ', 'sample=99 ', 1),
                    result['control_stdout'].replace('lhs=2/1 rhs=2/1', 'lhs=3/1 rhs=2/1', 1),
                    '\n'.join(line for line in result['control_stdout'].splitlines()
                              if not line.startswith('NUM_GRAPH_COUNT scenario=4 '))):
            with self.assertRaises(AssertionError):
                check.validate_controls(bad)

    def test_exact_domains_and_axioms_cannot_be_promoted_to_machine_or_full_workload_claims(self):
        result = ledger.read('reports/numerical-values.json')
        check.validate_result(result)
        for field in check.FALSE_FIELDS:
            changed = copy.deepcopy(result)
            changed[field] = True
            with self.assertRaises(AssertionError):
                check.validate_result(changed)
        changed = copy.deepcopy(result)
        changed['certificate_profiles']['TensorRewrite.Theory.Numerical.real_power_denominator']['domain'] = 'all real bases'
        with self.assertRaises(AssertionError):
            check.validate_result(changed)
        changed = copy.deepcopy(result)
        next(iter(changed['certificate_axioms'].values())).append('sorryAx')
        with self.assertRaises(AssertionError):
            check.validate_result(changed)
        changed = copy.deepcopy(result)
        changed['word_field_rejection']['returncode'] = 0
        with self.assertRaises(AssertionError):
            check.validate_result(changed)

    def test_refutations_are_counted_separately_from_positive_candidate_evidence(self):
        manifest = check.check_inputs()
        rows = ledger.evidence()
        counter = [row for row in rows if 'exact_numerical_domain_refutation' in row['kinds']]
        self.assertEqual({r['theorem'] for r in counter}, set(manifest['counterexample_certificates']))
        self.assertTrue(all(not r['historical_candidate_benchmark_labels'] for r in counter))
        self.assertEqual(theory.measure_file('TensorRewrite/Theory/NumericalCounterexamples.lean', 'C')[0]['category'], 'C')
        model = next(row for row in ledger.mathematical_models() if row['model'] == manifest['model'])
        self.assertEqual(model['checked_theorem_count'], 53)
        self.assertFalse(model['full_family_complete'])
        self.assertFalse(model['word_division_is_field_division'])

    def test_workload_retains_every_record_and_does_not_close_a_whole_case(self):
        progress = ledger.read('census/mathematical-ledger.json')
        result = audit.assemble(ledger.corpus(), progress, audit.read_catalog('census/workload-formulation-catalog-v7.json'))
        self.assertEqual(result['retained_benchmark_records'], 488)
        self.assertEqual(result['records_with_only_unreviewed_proposal_worksheets'], 244)
        self.assertGreaterEqual(progress['kernel_complete_family_profile_count'], 369)
        self.assertEqual(result['whole_benchmark_records_closed'], 0)
        self.assertIsNone(result['mathematical_obligation_denominator'])
        self.assertFalse(result['every_record_has_received_a_complete_proof_attempt'])
        self.assertFalse(any(row['whole_record_mathematically_closed']
                             for row in progress['benchmark_records']))


if __name__ == '__main__':
    unittest.main()
