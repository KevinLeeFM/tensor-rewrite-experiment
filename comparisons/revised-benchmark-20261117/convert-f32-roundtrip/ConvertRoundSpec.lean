import RadixSpec
set_option autoImplicit false
namespace RevisedBenchmark.ConvertRound
open RevisedBenchmark.RadixIota
/-- t is the word width minus one. -/
def low (signed : Bool) (t : Nat) : Int := if signed then -(2^t : Nat) else 0
def high (signed : Bool) (t : Nat) : Int :=
  (if signed then (2^t : Nat) else (2^(t+1) : Nat) : Int) - 1
def encode32 (x : Int) : Int :=
  if x < 0 then -(r32 (-x).toNat : Int) else (r32 x.toNat : Int)
def back (signed : Bool) (t : Nat) (x : Int) := max (low signed t) (min (high signed t) (encode32 x))
def fixed (signed : Bool) (t : Nat) := ∀ x, low signed t ≤ x → x ≤ high signed t →
  back signed t x = x
def Case := ∀ (signed : Bool) (t : Nat), t < 64 →
  (fixed signed t ↔ (if signed then t ≤ 24 else t+1 ≤ 24))
end RevisedBenchmark.ConvertRound
