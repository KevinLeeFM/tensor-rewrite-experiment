module
public import SliceUpdateSpec
public section
set_option autoImplicit false
namespace SliceUpdate
open TensorRewrite.Pilot TensorRewrite.Theory.DynamicUpdate

/-- The source match reads precisely the embedded update position. -/
theorem exactMatch : ExactGoal := by
  intro r b u α w a h matchAxes base upd
  funext i
  have equal : IndexMaps.sliceIndex a h i = w.embed i := by
    funext d
    apply Fin.ext
    have source := IndexMaps.sliceIndex_val a h i d
    rw [(matchAxes d).1, (matchAxes d).2.2, Int.one_mul] at source
    rw [embed_value]
    omega
  simp [equal, Window.update, locate_embed]

/-- Translating a legal contained slice preserves its extent and all embedded coordinates. -/
theorem contained : InsideGoal := by
  intro r b u o α w a h bounds
  have valid : ∀ d, SliceShape.IsWellFormed (u d) (o d) (translate (a d) (w.start d)) := by
    intro d
    obtain ⟨_, hl, _, hs, ho, hc⟩ := h d
    obtain ⟨hlo, hhi⟩ := bounds d
    refine ⟨by dsimp [translate]; omega, by dsimp [translate]; omega,
      by dsimp [translate]; omega, hs, ho, ?_⟩
    unfold SliceShape.Axis.elementCount at hc ⊢
    dsimp [translate]
    rwa [show (a d).limit - w.start d - ((a d).start - w.start d) =
      (a d).limit - (a d).start by omega]
  refine ⟨valid, ?_⟩
  intro base upd
  funext i
  let j := IndexMaps.sliceIndex (fun d => translate (a d) (w.start d)) valid i
  have equal : IndexMaps.sliceIndex a h i = w.embed j := by
    funext d
    apply Fin.ext
    have src := IndexMaps.sliceIndex_val a h i d
    have rel := IndexMaps.sliceIndex_val (fun d => translate (a d) (w.start d)) valid i d
    change ((j d).val : Int) = (a d).start - w.start d + (a d).stride * (i d : Int) at rel
    rw [embed_value]
    omega
  simp [equal, Window.update, locate_embed, j]
#print axioms exactMatch
#print axioms contained
end SliceUpdate
