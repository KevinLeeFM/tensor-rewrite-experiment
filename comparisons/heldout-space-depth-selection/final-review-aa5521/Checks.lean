import OtherAxisIntegration
import GoalCandidateGuard
run_cmd Heldout.GoalCandidateGuard.exactGoal ``Heldout.OtherAxisIntegration.rewrite ``Heldout.SpaceDepthCandidate.Goal
run_cmd Heldout.GoalCandidateGuard.noCampaignProofs
#print axioms Heldout.OtherAxisProof.other
#print axioms Heldout.OtherAxisIntegration.full_index
#print axioms Heldout.OtherAxisIntegration.rewrite
