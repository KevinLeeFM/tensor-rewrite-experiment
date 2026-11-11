"""Protect frozen-comparison scope, proof isolation, negative-control repair and LOC accounting."""
import copy
import json
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
import check_fixed_tactics as check
import run_fixed_tactics as run


class FixedTacticTests(unittest.TestCase):
    def test_reviewed_subset_selection_does_not_count_excluded_or_unreviewed_targets(self):
        frozen,revision=check.verify_registration()
        selection=run.read(run.PACKET+'/targets.json')
        self.assertEqual((len(selection['targets']),len(selection['exclusions'])),(44,45))
        self.assertTrue(all(r['reviewed_header_identical'] for r in selection['targets']))
        self.assertEqual({r['original'].split('.')[-2] for r in selection['targets']},
                         {'FloatNegation','FiniteSum','Convolution','ConvolutionPointwise',
                          'LogicalFamily','ContractionAlgebra'})
        self.assertFalse(frozen['whole_workload_compared'])
        self.assertEqual(revision,'be93b376d74e7a1d84609de3245816d86f741845')

    def test_every_measured_pair_is_fresh_and_counted_exactly_once(self):
        result=run.read(run.PACKET+'/results/summary.json')
        accepted,targets,policies,_=check.validate_summary(result)
        self.assertEqual(len(accepted),31)
        self.assertEqual(len({r['target'] for r in accepted}),13)
        self.assertEqual(result['accepted_by_policy'],{'rfl':5,'simp':5,'funext_simp':8,'aesop':13})
        self.assertEqual(sum(not r['negative_control'] for r in result['attempts']),176)
        changed=copy.deepcopy(result);changed['attempts'].append(changed['attempts'][0])
        with self.assertRaises(AssertionError):check.validate_summary(changed)
        changed=copy.deepcopy(result);changed['union_accepted_targets']=44
        with self.assertRaises(AssertionError):check.validate_summary(changed)

    def test_weak_statements_or_leaked_proofs_cannot_enter_the_baseline(self):
        root=Path(check.ROOT/run.PACKET/'results')
        self.assertIn('FIXED_BASELINE_GUARD absent=835 present=0',(root/'basis.log').read_text())
        self.assertIn('SIGNATURES exact=44',(root/'signatures.log').read_text())
        self.assertIn('FIXED_BASELINE_LEAK',(root/'leak_negative.log').read_text())
        self.assertIn('FIXED_BASELINE_SIGNATURE_MISMATCH',(root/'signature_negative.log').read_text())
        original=check.digest
        with patch.object(check,'digest',side_effect=lambda path:
                          'changed' if str(path).endswith('FixedTacticsPolicies.lean') else original(path)):
            with self.assertRaises(AssertionError):check.verify_registration()

    def test_parser_errors_are_not_false_goal_rejections_and_repair_is_required(self):
        result=run.read(run.PACKET+'/results/summary.json')
        self.assertEqual({r['status'] for r in result['attempts'] if r['negative_control']},
                         {'infrastructure_failure'})
        repair=run.read(run.PACKET+'/negative-repair-v2/results.json')
        self.assertEqual(len(repair['controls']),8)
        self.assertTrue(all(r['status']=='fixed_tactic_unsuccessful' for r in repair['controls']))
        original=check.read
        bad=copy.deepcopy(repair);bad['measured_attempts_changed']=True
        with patch.object(check,'read',side_effect=lambda path:
                          bad if path.endswith('negative-repair-v2/results.json') else original(path)):
            with self.assertRaises(AssertionError):check.validate_summary(result)
        self.assertFalse(repair['policies_changed'])

    def test_historical_replay_is_not_new_coverage_or_a_blinded_discovery_result(self):
        result=run.read(run.PACKET+'/results/summary.json')
        for key,value in [('fresh_blinded_agent_comparison',True),('whole_workload_compared',True),
                          ('independent_comparison_review',True),('code_correspondence_performed',True)]:
            changed=copy.deepcopy(result);changed[key]=value
            with self.assertRaises(AssertionError):check.validate_summary(changed)
        analysis=run.read('reports/fixed-tactics-comparison-v1.json')
        self.assertEqual(analysis['comparison_new_unique_mathematical_coverage'],0)
        self.assertEqual(analysis['main_campaign_theory_statements_unchanged'],575)
        self.assertEqual(analysis['comparison_shared_statement_lines'],350)
        self.assertEqual(analysis['comparison_shared_automation_lines'],153)
        self.assertEqual(analysis['historical_agent_replay']['code_lines'],387)
        self.assertFalse(analysis['minimum_proof_size_estimated'])
        self.assertTrue(all(p['accepted_trial_whole_module_lines']>0 for p in analysis['policy_details']))


if __name__=='__main__':unittest.main()
