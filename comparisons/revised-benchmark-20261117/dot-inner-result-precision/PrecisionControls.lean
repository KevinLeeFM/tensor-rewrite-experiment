import PrecisionProof
set_option autoImplicit false
namespace RevisedBenchmark.DotResult
open NestedDot
example : (¬ Goal true) ∧ (¬ Goal false) := refuted
example : left 2 8 (operand (single 129)) (operand (single 129)) (operand (single 1)) 0 0 =
           some 16641 ∧ right 2 8 (operand (single 129)) (operand (single 129)) (operand (single 1)) 0 0 =
           some 16641 := by decide
example : old true 2 8 (operand (single 128)) (operand (single 129)) (operand (single 1)) 0 0 = some 16512 ∧
           new true 2 8 (operand (single 128)) (operand (single 129)) (operand (single 1)) 0 0 = some 16512 := by decide
example : old false 8 2 (operand (single 1)) (operand (single 129)) (operand (single 129)) 1 1 = some 0 ∧
           new false 8 2 (operand (single 1)) (operand (single 129)) (operand (single 129)) 1 1 = some 0 := by decide
end RevisedBenchmark.DotResult
