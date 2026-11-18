import TensorRewrite.Pilot.Permutation
set_option autoImplicit false
namespace RevisedBenchmark.DotSwap
open TensorRewrite.Pilot
/-- Read batch coordinates by the position of each local operand axis in the paired batch list. -/
def operandBatch {b : Nat} (order : AxisPermutation b) (q : Fin b → Nat) : Fin b → Nat :=
  fun a => q (order.inputToOutput a)

/-- The remaining contraction coordinates are enumerated in the common paired order, linearized. -/
def dot {L R : Type} {b : Nat} (k : Nat) (lx rx : AxisPermutation b)
    (x : (Fin b → Nat) → L → Fin k → Int) (y : (Fin b → Nat) → R → Fin k → Int)
    (q : Fin b → Nat) (i : L) (j : R) : Int :=
  (List.ofFn (fun t => x (operandBatch lx q) i t * y (operandBatch rx q) j t)).sum

def Case : Prop := ∀ {b : Nat} (shape : Shape b) (p lx rx : AxisPermutation b)
    (L R : Type) (k : Nat) (x : (Fin b → Nat) → L → Fin k → Int)
    (y : (Fin b → Nat) → R → Fin k → Int),
  (fun (q : Index (fun a => shape (p.outputToInput a))) (j : R) (i : L) =>
    dot k lx rx x y (operandBatch p (fun a => (q a).val)) i j) =
  (fun q j i => dot k (rx.comp p) (lx.comp p) y x (fun a => (q a).val) j i)
end RevisedBenchmark.DotSwap
