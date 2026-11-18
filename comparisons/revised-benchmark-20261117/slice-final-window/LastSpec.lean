module
public import Std
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.SliceFinalWindow

structure Axis where
  input : Nat
  kernel : Nat
  low : Int
  high : Int
  start : Nat
  stop : Nat
deriving Repr, DecidableEq

/-- Unit stride, no base/kernel dilation; count valid window positions. -/
def win (a : Axis) : Nat := ((a.input : Int)+a.low+a.high-a.kernel+1).toNat
def width (a : Axis) := a.stop-a.start
def keep (a : Axis) := a.kernel == 1 && win a == width a && a.start == 0

/-- Common raw source guards plus one of the two selected axis branches. -/
def matched (a : Axis) := 0 < a.kernel ∧ a.start ≤ a.stop ∧
    win a = a.stop ∧ a.low = a.start ∧ a.high = 0 ∧
    (keep a = true ∨ (width a = 1 ∧ win a = a.kernel))

/-- Kernel reads at an actual sliced window output. Skip positions that miss
the operand, as in logical window visitation. -/
def samples (a : Axis) (y : Nat) :=
  (List.range a.kernel).filterMap fun k =>
    let p := ((a.start + y + k : Nat) : Int) - a.low
    if 0 ≤ p ∧ p < a.input then some p.toNat else none

abbrev Fiber := List (List Nat)

/-- Prepend all chosen head indices to every tail coordinate, in physical
major-to-minor order. -/
def extend (head : List Nat) (t : Fiber) : Fiber :=
  head.flatMap fun i => t.map (i :: ·)

/-- Row-major output list of ordered fibers for Slice(ReduceWindow). -/
def old : List Axis → List Fiber
  | [] => [[[]]]
  | a::ds => (List.range (width a)).flatMap fun y => (old ds).map (extend (samples a y))

/-- Row-major result of Reduce. The eliminated axis contributes input points
to every tail fiber but creates no new result dimension. -/
def reduced : List Axis → List Fiber
  | [] => [[[]]]
  | a::ds =>
    if keep a then (List.range a.input).flatMap fun y => (reduced ds).map (extend [y])
    else (reduced ds).map (extend (List.range a.input))

def reducedShape (ds : List Axis) := (ds.filter keep).map Axis.input

def values {α : Type} (fibers : List Fiber) (x : List Nat → α) (op : α → α → α) (seed : α) :=
  fibers.map fun row => (row.map x).foldl op seed

/-- Compare complete flat result payloads and the element-count precondition
for the scalar/smaller-rank Reduce to be reshaped to the slice's shape. -/
def Goal := ∀ (ds : List Axis), (∀ a ∈ ds, matched a) →
  (∃ a ∈ ds, a.low ≠ 0 ∨ a.high ≠ 0) → (∃ a ∈ ds, keep a = false) →
  (ds.map width).prod = (reducedShape ds).prod ∧ old ds = reduced ds ∧
  ∀ (α : Type) (x : List Nat → α) (op : α → α → α) (seed : α),
    values (old ds) x op seed = values (reduced ds) x op seed
end RevisedBenchmark.SliceFinalWindow
