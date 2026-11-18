import Std
set_option autoImplicit false
namespace RevisedBenchmark.PadDot

/-- Effective removable padding on a paired axis. Untouched axes use zero effective
padding and the original retained-padded extent. -/
structure Axis where
  width : Nat
  low : Nat
  high : Nat
  interior : Nat
deriving DecidableEq, Repr

def step (a : Axis) := a.interior + 1
def body (a : Axis) := match a.width with
  | 0 => 0
  | k+1 => k * step a + 1
def extent (a : Axis) := a.low + body a + a.high
def limit (a : Axis) := extent a - a.high

/-- Number of positions in [start, stop) sampled at a positive stride. -/
def sliceWidth (start stop stride : Nat) :=
  if stop ≤ start then 0 else (stop - start - 1) / stride + 1

def sliced (a : Axis) := sliceWidth a.low (limit a) (step a)
def pos (a : Axis) (i : Nat) := a.low + i * step a

/-- Enumerate the complete Cartesian domain in contracting-axis pair order. -/
def grid : List Nat → List (List Nat)
  | [] => [[]]
  | n :: ns => (List.range n).flatMap (fun i => (grid ns).map (i :: ·))

/-- Coordinates outside the enumerated rank are never used. -/
def address := List.zipWith pos

def total {α : Type} (xs : List α) (f : α → Int) := (xs.map f).sum
def times (leftPad : Bool) (x y : Int) := if leftPad then x*y else y*x

/-- Zero-filled scatter of each original value at its padded coordinate. -/
def padded (ds : List Axis) (x : List Nat → Int) (p : List Nat) : Int :=
  total (grid (ds.map Axis.width)) (fun i => if address ds i = p then x i else 0)

def original (ds : List Axis) (leftPad : Bool) (x y : List Nat → Int) :=
  total (grid (ds.map extent)) (fun p => times leftPad (padded ds x p) (y p))

def replacement (ds : List Axis) (leftPad : Bool) (x y : List Nat → Int) :=
  total (grid (ds.map sliced)) (fun i => times leftPad (x i) (y (address ds i)))

/-- At any observed batch/free coordinate, x is the operand with all unremoved
padding intact. Both sides quantify over its values, including any retained zeros. -/
def Case := ∀ (ds : List Axis) (leftPad : Bool) (x y : List Nat → Int),
  original ds leftPad x y = replacement ds leftPad x y
end RevisedBenchmark.PadDot
