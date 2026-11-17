module
import GoalCandidate
import GoalCandidateGuard
/-- Well-formed theorem with a different proposition. -/
theorem wrongSignature : True := True.intro
run_cmd Heldout.GoalCandidateGuard.exactGoal ``wrongSignature ``Heldout.SpaceDepthCandidate.Goal
