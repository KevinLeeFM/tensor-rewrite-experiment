import SwapSpec
set_option autoImplicit false

namespace RevisedBenchmark.RemoveInputTransposes
open TensorRewrite.Pilot RevisedBenchmark.DotSwap

/-- Read a physically transposed operand's batch coordinates, leaving its last two slots explicit. -/
def pull {b m n : Nat} (p : AxisPermutation b)
    (x : (Fin b → Nat) → Fin m → Fin n → Int) (q : Fin b → Nat) := x (operandBatch p q)

/-- The inherited dot reads both operands by free slot followed by contracting slot. -/
def flipLast {b m n : Nat} (x : (Fin b → Nat) → Fin m → Fin n → Int)
    (q : Fin b → Nat) (j : Fin n) (i : Fin m) := x q i j

/-- Batch axes of the original output follow d; both operand transposes use p.
The replacement dot batches in identity order, before the reconstructed output transpose. -/
def Keep : Prop := ∀ {b : Nat} (s : Shape b) (p d : AxisPermutation b) (m k n : Nat)
    (a : (Fin b → Nat) → Fin m → Fin k → Int) (c : (Fin b → Nat) → Fin k → Fin n → Int)
    (q : Index (fun t => s (p.outputToInput (d.outputToInput t)))) (i : Fin m) (j : Fin n),
    dot k d d (pull p a) (flipLast (pull p c)) (fun t => (q t).val) i j =
    dot k (.identity b) (.identity b) a (flipLast c)
      (operandBatch (p.comp d) (fun t => (q t).val)) i j

/-- The input transposes also exchange their last two axes. The replacement swaps raw
operands and its output transpose exchanges the two free slots back. -/
def Swap : Prop := ∀ {b : Nat} (s : Shape b) (p d : AxisPermutation b) (m k n : Nat)
    (a : (Fin b → Nat) → Fin k → Fin m → Int) (c : (Fin b → Nat) → Fin n → Fin k → Int)
    (q : Index (fun t => s (p.outputToInput (d.outputToInput t)))) (i : Fin m) (j : Fin n),
    dot k d d (flipLast (pull p a)) (pull p c) (fun t => (q t).val) i j =
    dot k (.identity b) (.identity b) c (flipLast a)
      (operandBatch (p.comp d) (fun t => (q t).val)) j i
end RevisedBenchmark.RemoveInputTransposes
