import TensorRewrite.Pilot.Tensor
set_option autoImplicit false
namespace RevisedBenchmark.Components
open TensorRewrite.Pilot Tensor

/-- Semantic type tag distinguishes a real from a complex value with zero imaginary part. -/
inductive Kind where | real | complex deriving DecidableEq
def Value (R : Type) : Kind → Type
  | .real => R
  | .complex => R × R
def realPart {R : Type} (k : Kind) : Value R k → R := by
  cases k
  · exact id
  · exact Prod.fst
def imagPart {R : Type} (zero : R) (k : Kind) : Value R k → R := by
  cases k
  · exact fun _ => zero
  · exact Prod.snd

/-- Immutable statements use actual pointwise pair construction and projections.
An explicit broadcast of a scalar zero reads its sole scalar coordinate. -/
def makeComplex {r : Nat} {s : Shape r} {R : Type} (a b : Tensor s R) :=
  map₂ Prod.mk a b
def scalarZero {R : Type} (z : R) : Tensor (fun _ : Fin 0 => 0) R := constant z
def broadcastScalar {r : Nat} (s : Shape r) {R : Type}
    (x : Tensor (fun _ : Fin 0 => 0) R) : Tensor s R := fun _ => x (fun i => Fin.elim0 i)

def Reconstruction : Prop := ∀ {r : Nat} (s : Shape r) (R : Type) (z : R)
    (x : Tensor s (Value R .complex)),
    makeComplex (map (realPart .complex) x) (map (imagPart z .complex) x) = x

def RealProjection : Prop := ∀ {r : Nat} (s : Shape r) (R : Type) (a b : Tensor s R),
    map (realPart .complex) (makeComplex a b) = a

def ImagProjection : Prop := ∀ {r : Nat} (s : Shape r) (R : Type) (z : R) (a b : Tensor s R),
    map (imagPart z .complex) (makeComplex a b) = b

def RealOfReal : Prop := ∀ {r : Nat} (s : Shape r) (R : Type) (x : Tensor s R),
    map (realPart .real) x = x

def ImagOfReal : Prop := ∀ {r : Nat} (s : Shape r) (R : Type) (z : R) (x : Tensor s R),
    map (imagPart z .real) x = broadcastScalar s (scalarZero z)

/-- For a shared source operand of either admitted kind, the original result of
Complex(Real(x),Imag(x)) is always complex. Forwarding x retains its own kind. -/
def ReconstructionTypeBoundary : Prop :=
  ∀ k : Kind, Kind.complex = k ↔ k = Kind.complex

end RevisedBenchmark.Components
