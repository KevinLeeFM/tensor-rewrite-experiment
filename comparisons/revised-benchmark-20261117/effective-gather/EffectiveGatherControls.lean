module
public import EffectiveGatherProof
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.EffectiveGather
open TensorRewrite.Pilot

abbrev line (n : Nat) : Shape 1 := fun _ => n
def atLine {n : Nat} (i : Fin n) : Index (line n) := fun _ => i

/-- A scalar operand, scalar start vectors of length zero and arbitrary output shape. -/
def direct {t : Nat} (d : Shape t) : Window scalar d where
  vectorSize := 0
  start a := a.elim0
  readComponent _ k := k.elim0
  width := scalar
  fits a := a.elim0
  offset _ := origin

example : gather (direct (line 3)) (fun _ => 17) (atLine 2) = 17 := rfl
example : gather (direct scalar) (fun _ => 17) origin ≠ 18 := by decide
example (o : Index (line 0)) : False := (o 0).elim0

/-- Ordinary 1D windows: one start vector for every output row; its second output
coordinate selects the in-window offset. A negative or oversized start clamps. -/
abbrev grid (rows width : Nat) : Shape 2 := Fin.cases rows (fun _ => width)
def windows (n w : Nat) (ok : w ≤ n) : Window (line n) (grid 2 w) where
  vectorSize := 1
  start _ := .component 0
  readComponent o _ := if (o 0).val = 0 then -8 else 27
  width := line w
  fits _ := ok
  offset o _ := o 1

def point {w : Nat} (i : Fin 2) (j : Fin w) : Index (grid 2 w) :=
  Fin.cases i (fun _ => j)
example : gather (windows 1 1 (by decide)) (fun _ => 71) (point 1 0) = 71 := rfl
example : Reshape.reshapeTensor (fun _ : Index (line 1) => 71) scalar
    (countOne _ (fun _ => rfl)) origin = 71 := rfl
example : gather (windows 5 2 (by decide)) (fun p => (p 0).val) (point 0 1) = 1 := rfl
example : gather (windows 5 2 (by decide)) (fun p => (p 0).val) (point 1 1) = 4 := rfl
example : gather (windows 5 2 (by decide)) (fun p => (p 0).val) (point 1 1) ≠ 0 := by decide
example : Window (line 1) (grid 2 0) := windows 1 0 (by decide)
example (o : Index (grid 2 0)) : False := (o 1).elim0

/-- Explicit matching batch dimensions with elided operand window axis. -/
def batches (n : Nat) (pos : 0 < n) : Window (line n) (line n) where
  vectorSize := 0
  start _ := .batch 0
  readComponent _ j := j.elim0
  width := line 1
  fits _ := pos
  offset _ := atLine 0

example : gather (batches 3 (by decide)) (fun p => (p 0).val) (atLine 2) = 2 := rfl
example : gather (batches 1 (by decide)) (fun _ => 19) (atLine 0) = 19 := rfl
end RevisedBenchmark.EffectiveGather
