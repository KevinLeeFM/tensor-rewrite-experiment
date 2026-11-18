import ConvPadProof
set_option autoImplicit false
namespace RevisedBenchmark.ConvPad
open TensorRewrite.Pilot.Float32Exceptional

example : classify V.zero.bits = .zero ∧ classify V.posInf.bits = .infinity ∧
    classify V.nan.bits = .nan := by decide
example (x y : V) : MulCompatible x.bits y.bits (mul x y).bits := by
  unfold MulCompatible
  cases x <;> cases y <;> decide
example : conv [.zero,.posInf] [.posInf,.posInf] 0 0 1 = [.nan] ∧
    conv [.posInf] [.posInf,.posInf] 1 0 1 = [.posInf] := by decide
example : interior 1 [.posInf,.posInf] = [.posInf,.zero,.posInf] ∧
    conv [.posInf,.posInf,.posInf] (interior 1 [.posInf,.posInf]) 0 0 1 = [.nan] ∧
    conv [.posInf,.posInf,.posInf] [.posInf,.posInf] 0 0 2 = [.posInf] := by decide
example : interior 0 [.zero,.posInf] = [.zero,.posInf] := by decide
example : conv [.zero,.zero] [.zero,.zero] 0 0 1 = conv [.zero] [.zero,.zero] 1 0 1 := by decide
example : conv [.zero,.zero,.zero] (interior 1 [.zero,.zero]) 0 0 1 =
    conv [.zero,.zero,.zero] [.zero,.zero] 0 0 2 := by decide
example : conv [.posInf] [.posInf] 0 0 1 = [.posInf] := by decide
end RevisedBenchmark.ConvPad
