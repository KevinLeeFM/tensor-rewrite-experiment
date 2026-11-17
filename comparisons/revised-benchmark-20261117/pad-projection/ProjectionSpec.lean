module
public import SignedPadHistorical
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.PadProjection
open TensorRewrite.Pilot TensorRewrite.PaperComparison.SignedPad

def retained {r : Nat} {s o : Shape r} (p : Params s o) : List (Fin r) :=
  (List.finRange r).filter (fun d => decide (p.low d ≠ 0 ∨ p.high d ≠ 0 ∨ p.interior d ≠ 0))

def axis {r : Nat} {s o : Shape r} (p : Params s o) (k : Fin (retained p).length) :
    Fin r := (retained p).get k

def smaller {r : Nat} {s o : Shape r} (p : Params s o) :
    Params (fun k => s (axis p k)) (fun k => o (axis p k)) :=
  ⟨fun k => p.low (axis p k), fun k => p.high (axis p k),
   fun k => p.interior (axis p k), fun k => p.shape (axis p k)⟩

def slot {r : Nat} {s o : Shape r} (p : Params s o) (d : Fin r)
    (mem : d ∈ retained p) : Fin (retained p).length :=
  ⟨(retained p).idxOf d, List.idxOf_lt_length_iff.mpr mem⟩

theorem atSlot {r : Nat} {s o : Shape r} (p : Params s o) (d : Fin r)
    (mem : d ∈ retained p) : axis p (slot p d mem) = d := by
  exact List.getElem_idxOf (List.idxOf_lt_length_iff.mpr mem)

/-- Broadcast operand dimensions are looked up in the sorted retained-axis
    list using their first occurrence. Padded output axes are the same list. -/
def Goal : Prop :=
  ∀ {r n : Nat} {s o : Shape r} (p : Params s o) (b : Fin n → Fin r)
    (contained : ∀ a, b a ∈ retained p)
    {α : Type} (fill : α) (x : Tensor (fun a => s (b a)) α),
    tensor p fill (fun j => x (fun a => j (b a))) =
      fun j => tensor (smaller p) fill (fun k => x (fun a =>
        (k (slot p (b a) (contained a))).cast (congrArg s (atSlot p (b a) (contained a)))))
        (fun k => j (axis p k))
end RevisedBenchmark.PadProjection
