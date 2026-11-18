import EarlySpec
set_option autoImplicit false
namespace RevisedBenchmark.EmptyFold
open WindowEarly (Axis extent)

/-- One axis of an interior-free Pad and its subsequent width-two, stride-one window.
The stored dilation field encodes the actual dilation minus one. -/
structure Dim where
  n : Nat
  lo : Nat
  hi : Nat
  dilM1 : Nat

def originalAxis (d : Dim) : Axis :=
  { base := d.n + d.lo + d.hi, widthM1 := 1, baseDilM1 := d.dilM1 }
def emittedAxis (d : Dim) : Axis :=
  { base := d.n, widthM1 := 1, baseDilM1 := d.dilM1,
    low := (d.dilM1 + 1) * d.lo, high := (d.dilM1 + 1) * d.hi }
def declared (ds : List Dim) := ds.map fun d => extent (originalAxis d)
def inferred (ds : List Dim) := ds.map fun d => extent (emittedAxis d)

def geometry (n dilM1 : Nat) : List Dim := [⟨n,1,1,dilM1⟩, ⟨3,0,0,0⟩]

/-- Result annotation must agree with shape inference after folding the Pad. -/
def Goal := ∀ n dilM1 : Nat, declared (geometry n dilM1) = inferred (geometry n dilM1)
end RevisedBenchmark.EmptyFold
