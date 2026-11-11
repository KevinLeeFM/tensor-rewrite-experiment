"""Coverage/accounting controls for the mathematical campaign, without native/source analysis."""
import copy
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
import mathematical_ledger as ledger


class MathematicalLedgerTests(unittest.TestCase):
    def test_full_retained_corpus_and_hash_boundary(self):
        rows=ledger.corpus()
        manifest=ledger.read(ledger.MANIFEST)
        self.assertEqual(set(rows),set(manifest['benchmark_ids']))
        self.assertTrue(all(not r['whole_record_mathematically_closed'] for r in rows.values()))
        with patch.object(ledger,'digest',return_value='changed'):
            with self.assertRaises(AssertionError):ledger.corpus()
        with self.assertRaises(ValueError):ledger.freeze()

    def test_checked_model_evidence_is_not_whole_record_coverage(self):
        proofs=ledger.evidence()
        self.assertTrue(all(p['mathematical_acceptance']=='kernel_check_pending' for p in proofs))
        with self.assertRaises(AssertionError):ledger.assemble(ledger.corpus(),proofs,{})
        checked=copy.deepcopy(proofs)
        for proof in checked:proof['mathematical_acceptance']='kernel_checked_in_declared_model'
        result=ledger.assemble(ledger.corpus(),checked,{})
        self.assertEqual(result['whole_benchmark_records_closed'],0)
        self.assertIsNone(result['mathematical_obligation_denominator'])
        self.assertTrue(any(r['evidence'] for r in result['benchmark_records']))
        self.assertTrue(all(not r['whole_record_mathematically_closed'] for r in result['benchmark_records']))
        self.assertFalse(result['code_correspondence_performed'])

    def test_every_explicit_retained_declaration_reference_is_registered(self):
        pilot=ledger.read('census/pilot-value-proofs.json')
        references=ledger.retained_declaration_refs(pilot)
        evidence={row['theorem']:row for row in ledger.evidence()}
        self.assertEqual(len(references),260)
        self.assertFalse(set(references)-set(evidence))
        for name,origins in references.items():
            self.assertEqual(evidence[name]['retained_manifest_paths'],sorted(origins))
        for name in ('TensorRewrite.Pilot.BooleanDag.and_rhs_true_of_isAll',
                     'TensorRewrite.Pilot.ZeroMacProfile.zero_bits_differ'):
            self.assertIn(name,evidence)
        newly_added=['TensorRewrite.Pilot.BooleanDag.and_rhs_true_of_isAll',
                     'TensorRewrite.Pilot.ZeroMacProfile.zero_bits_differ']
        self.assertTrue(all(not evidence[n]['label_correspondence_certified'] for n in newly_added))

    def test_integer_select_witnesses_keep_their_retained_mathematical_profile(self):
        group=ledger.read('census/pilot-value-proofs.json')['algebraic_refutation']
        proofs={row['theorem']:row for row in ledger.evidence()}
        for name in group['witness_theorems']:
            self.assertEqual(proofs[name]['profile_descriptions'],[group['profile']])
            self.assertEqual(proofs[name]['kinds'],['concrete_witness_certificate'])
            self.assertFalse(proofs[name]['historical_candidate_benchmark_labels'])

    def test_unknown_benchmark_label_is_rejected(self):
        proof=copy.deepcopy(ledger.evidence()[0])
        proof['mathematical_acceptance']='kernel_checked_in_declared_model'
        proof['historical_candidate_benchmark_labels']=['invented-benchmark']
        with self.assertRaises(AssertionError):ledger.assemble(ledger.corpus(),[proof],{})


if __name__=='__main__':unittest.main()
