module
public import TensorRewrite.Theory.DynamicUpdateLemmas
@[expose] public section
set_option autoImplicit false
namespace SliceUpdate
open TensorRewrite.Pilot TensorRewrite.Theory.DynamicUpdate
/-- Source subtracts the clamped start from both endpoints, retaining stride. -/
def translate (a : SliceShape.Axis) (s : Nat) : SliceShape.Axis :=
  ⟨a.start - s, a.limit - s, a.stride⟩
/-- Exact unstrided compatible branch, with common update/output extent. -/
def ExactGoal : Prop :=
  ∀ {r : Nat} {b u : Shape r} {α : Type} (w : Window b u)
    (a : Fin r → SliceShape.Axis)
    (h : ∀ d, SliceShape.IsWellFormed (b d) (u d) (a d)),
    (∀ d, (a d).start = w.start d ∧ (a d).limit = (w.start d : Int) + u d ∧ (a d).stride = 1) →
    ∀ (base : Tensor b α) (upd : Tensor u α),
      (fun i => w.update base upd (IndexMaps.sliceIndex a h i)) = upd
/-- Contained fallback branch constructs legal relative metadata and preserves each value. -/
def InsideGoal : Prop :=
  ∀ {r : Nat} {b u o : Shape r} {α : Type} (w : Window b u)
    (a : Fin r → SliceShape.Axis)
    (h : ∀ d, SliceShape.IsWellFormed (b d) (o d) (a d)),
    (∀ d, (w.start d : Int) ≤ (a d).start ∧ (a d).limit ≤ (w.start d : Int) + u d) →
    ∃ v : ∀ d, SliceShape.IsWellFormed (u d) (o d) (translate (a d) (w.start d)),
      ∀ (base : Tensor b α) (upd : Tensor u α),
        (fun i => w.update base upd (IndexMaps.sliceIndex a h i)) =
        (fun i => upd (IndexMaps.sliceIndex (fun d => translate (a d) (w.start d)) v i))
end SliceUpdate
