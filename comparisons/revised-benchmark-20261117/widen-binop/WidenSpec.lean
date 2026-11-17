import TensorRewrite.Pilot.Tensor
set_option autoImplicit false
namespace RevisedBenchmark.Widen
open TensorRewrite.Pilot Tensor

inductive Op where | add | sub | mul | udiv deriving DecidableEq
def applyOp {w : Nat} : Op → BitVec w → BitVec w → BitVec w
  | .add => (· + ·)
  | .sub => (· - ·)
  | .mul => (· * ·)
  | .udiv => BitVec.udiv

/-- Signed conversion interprets the original signed integer; unsigned conversion uses zero extension. -/
def convert {w : Nat} (toWidth : Nat) (signed : Bool) (x : BitVec w) : BitVec toWidth :=
  if signed then BitVec.ofInt toWidth x.toInt else x.setWidth toWidth

def Case (op : Op) : Prop := ∀ {rank n : Nat} (s : Shape rank) (w : Nat) (_ : n ≤ w)
    (signed : Bool) (_ : op = .udiv → signed = false) (a b : Tensor s (BitVec n)),
    map (convert n signed) (map₂ (applyOp op) (map (convert w signed) a) (map (convert w signed) b))
    = map₂ (applyOp op) a b
end RevisedBenchmark.Widen
