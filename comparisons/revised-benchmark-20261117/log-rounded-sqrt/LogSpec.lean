import Std
namespace RevisedBenchmark.LogSqrt
-- Inputs are 1 and the immediate F32 successor of 1. Store the input as
-- its increment count above 1; output significands use units 2^(-48).
def t : Rat := 1/(2^23:Rat)
def rootIsOne (u : Nat) : Bool :=
  decide (1 ≤ 1+u*t ∧ 1+u*t < (1+t/2)^2)
def logRead (u m : Nat) : Bool :=
  if u = 0 then m == 0
  else Id.run do
    let h := u*t
    let q : Rat := 1/(2^47:Rat)
    let v : Rat := m*q
    if !(2^23 < m && m < 2^24) then return false
    return decide (v-q/2 < h-h^2/2 ∧ h-h^2/2+h^3/3 < v+q/2)
def Goal := ∀ u m : Nat, u ≤ 1 → rootIsOne u = true → logRead u m = true →
  -- sqrt rounded to 1 gives log(1)=0. Multiplication of m*2^-47
  -- by the exactly represented positive half gives m*2^-48.
  (0 : Nat) = m
end RevisedBenchmark.LogSqrt
