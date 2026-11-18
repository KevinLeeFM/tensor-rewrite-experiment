import RemoveSpec
import SwapProof
set_option autoImplicit false

namespace RevisedBenchmark.RemoveInputTransposes
open TensorRewrite.Pilot RevisedBenchmark.DotSwap

/-- Batch-list canonicalization and moving both transposes outward preserve each summand. -/
theorem keepVerified : Keep := by
  intro b s p d m k n a c q i j
  rfl

/-- The existing transpose-of-dot swap law directly applies after normalizing raw slots. -/
theorem swapVerified : Swap := by
  intro b s p d m k n a c q i j
  have law := DotSwap.verified s (p.comp d) (.identity b) (.identity b)
    (Fin m) (Fin n) k (flipLast a) c
  exact congrFun (congrFun (congrFun law q) j) i

/-- Both the original two-step read and the reconstructed outer read are within raw s. -/
theorem readBound {b : Nat} (s : Shape b) (p d : AxisPermutation b)
    (q : Index (fun t => s (p.outputToInput (d.outputToInput t)))) (a : Fin b) :
    operandBatch p (operandBatch d (fun t => (q t).val)) a < s a ∧
    operandBatch (p.comp d) (fun t => (q t).val) a < s a := by
  have h := DotSwap.operandBound s (.identity b) (p.comp d) q a
  exact ⟨h, h⟩

theorem verified : Keep ∧ Swap := ⟨keepVerified, swapVerified⟩
#print axioms verified
#print axioms keepVerified
#print axioms swapVerified
#print axioms readBound
end RevisedBenchmark.RemoveInputTransposes
