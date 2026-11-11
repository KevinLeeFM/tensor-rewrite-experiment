import TensorRewrite.Comparisons.FixedTacticsGuard

set_option maxHeartbeats 400000
set_option maxRecDepth 4096
-- The same uniform list intentionally contains unused definitions for some goals.
set_option linter.unusedSimpArgs false

run_cmd TensorRewrite.Comparisons.FixedTactics.noCampaignProofs

namespace FixedTacticTrial

/-- One frozen-policy attempt at the unchanged reviewed proposition. -/
theorem candidate : TensorRewrite.Theory.Convolution.case_015 := by
  unfold TensorRewrite.Theory.Convolution.case_015
  intros
  rfl

end FixedTacticTrial

#print axioms FixedTacticTrial.candidate
