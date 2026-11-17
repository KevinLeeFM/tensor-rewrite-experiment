import TensorRewrite.Pilot.Tensor
set_option autoImplicit false
namespace RevisedBenchmark.DividePowerTwo
open TensorRewrite.Pilot Tensor

/-- Encoded shift constant has exactly the dividend's width, as in MakeScalarLike. -/
def shiftCount {w : Nat} (b : BitVec w) : BitVec w := BitVec.ofNat w b.toNat.log2

def shifted {w : Nat} (a b : BitVec w) := a.ushiftRight (shiftCount b).toNat

/-- Two selects keep the sign separately, so the inner absolute magnitude
is used as an unsigned word even for the most-negative input. -/
def signedShift {w : Nat} (a b : BitVec w) : BitVec w :=
  let neg := a.slt 0
  let magnitude := if neg then -a else a
  let q := shifted magnitude b
  if neg then -q else q

def UnsignedCase : Prop := ∀ {r w : Nat} (s : Shape r) (b : BitVec w)
    (_power : ∃ k : Nat, b.toNat = 2 ^ k) (x : Tensor s (BitVec w)),
    map (fun a => a.udiv b) x = map (fun a => shifted a b) x

def SignedCase : Prop := ∀ {r w : Nat} (s : Shape r) (b : BitVec w)
    (_positive : 0 < b.toInt) (_power : ∃ k : Nat, b.toNat = 2 ^ k)
    (x : Tensor s (BitVec w)),
    map (fun a => a.sdiv b) x = map (fun a => signedShift a b) x

end RevisedBenchmark.DividePowerTwo
