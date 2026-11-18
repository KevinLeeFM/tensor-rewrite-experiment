module
public import Std
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.SingletonWindow

structure Axis where
  n : Nat
  low : Int
  high : Int
deriving DecidableEq, Repr

def output (a : Axis) : Int := max 0 ((a.n : Int) + a.low + a.high)
def start (a : Axis) := max (-a.low) 0
def stop (a : Axis) := (a.n : Int) + min a.high 0
def padLo (a : Axis) := max a.low 0
def padHi (a : Axis) := max a.high 0
def cut (a : Axis) := -(a.low) ≥ (a.n : Int) ∨ -(a.high) ≥ (a.n : Int)
def full {r : Nat} (ds : Fin r → Axis) :=
  (∃ d, (ds d).low < 0 ∨ (ds d).high < 0) ∧ ∃ d, cut (ds d)
instance {r : Nat} (ds : Fin r → Axis) : Decidable (full ds) := by
  unfold full cut; infer_instance

inductive Op where | add | minimum | maximum deriving DecidableEq, Repr
def applyOp : Op → Int → Int → Int
  | .add => (·+·)
  | .minimum => min
  | .maximum => max

/-- A size-one window visits its translated input point when all axes fit. -/
def old {r : Nat} (ds : Fin r → Axis) (y : Fin r → Int) (op : Op)
    (seed : Int) (x : (Fin r → Int) → Int) :=
  let coord := fun d => y d - (ds d).low
  if ∀ d, 0 ≤ coord d ∧ coord d < (ds d).n then applyOp op seed (x coord) else seed

/-- Broadcast on full crop; otherwise pad a slice of the pointwise operation.
Omitting a zero pad or identity slice is represented by their identity maps. -/
def emitted {r : Nat} (ds : Fin r → Axis) (y : Fin r → Int) (op : Op)
    (seed : Int) (x : (Fin r → Int) → Int) :=
  if full ds then seed else
    let localIdx := fun d => y d - padLo (ds d)
    if ∀ d, 0 ≤ localIdx d ∧ localIdx d < stop (ds d) - start (ds d) then
      applyOp op (x (fun d => start (ds d) + localIdx d)) seed
    else seed

def Goal := ∀ (r : Nat) (_ : 0 < r) (ds : Fin r → Axis),
  (∀ d, 0 < (ds d).n ∧ 0 < output (ds d)) →
  (¬ full ds → ∀ d, 0 ≤ start (ds d) ∧ start (ds d) ≤ stop (ds d) ∧
    stop (ds d) ≤ (ds d).n ∧
    padLo (ds d) + (stop (ds d) - start (ds d)) + padHi (ds d) = output (ds d)) ∧
  ∀ (y : Fin r → Int), (∀ d, 0 ≤ y d ∧ y d < output (ds d)) →
    ∀ (op : Op) (seed : Int) (x : (Fin r → Int) → Int),
    old ds y op seed x = emitted ds y op seed x
end RevisedBenchmark.SingletonWindow
