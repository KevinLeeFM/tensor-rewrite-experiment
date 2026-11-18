import SwapSpec
set_option autoImplicit false
namespace RevisedBenchmark.DotSwap
open TensorRewrite.Pilot

/-- The ambient batch access stays inside the local operand's actual batch extent. -/
theorem operandBound {b : Nat} (s : Shape b) (ord p : AxisPermutation b)
    (q : Index (fun a => s (p.outputToInput a))) (a : Fin b) :
    operandBatch (ord.comp p) (fun t => (q t).val) a < s (ord.inputToOutput a) := by
  have bound := (q (p.inputToOutput (ord.inputToOutput a))).isLt
  change _ < s (p.outputToInput (p.inputToOutput (ord.inputToOutput a))) at bound
  rwa [p.output_input] at bound

theorem verified : Case := by
  intro b s p lx rx L R k x y
  funext q j i
  unfold dot
  apply congrArg List.sum
  apply congrArg List.ofFn
  funext t
  exact Int.mul_comm _ _
example : Case := verified
#print axioms verified
#print axioms operandBound
end RevisedBenchmark.DotSwap
