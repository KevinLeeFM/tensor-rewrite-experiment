import Std
namespace RevisedBenchmark.FullWidth

/-- Binary32 word rounding with the exponent budget fixed at eight.
A NaN with positive retained mantissa budget preserves its payload.
With no retained payload bit the source fallback uses positive infinity. -/
def reduce (retained : Nat) (w : BitVec 32) : BitVec 32 :=
  let x := w.toNat
  let stride := 2 ^ (23 - retained)
  let q := x / stride
  let r := x % stride
  let increment := if 2 * r > stride ∨ (2 * r = stride ∧ q % 2 = 1) then 1 else 0
  if x / (2 ^ 23) % 256 = 255 ∧ x % (2 ^ 23) ≠ 0 then
    if retained > 0 then w else 0x7f800000#32
  else BitVec.ofNat 32 ((q + increment) * stride)

def Goal := ∀ m, m + 1 = 24 → ∀ (I : Type) (operand : I → BitVec 32),
  (fun i => reduce m (operand i)) = operand
end RevisedBenchmark.FullWidth
