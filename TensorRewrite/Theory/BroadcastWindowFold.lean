module

public import TensorRewrite.Theory.BroadcastWindowSampling
public import TensorRewrite.Theory.ReductionWindowLemmas
public import TensorRewrite.Pilot.LinearIndexLemmas

/-! Exactly one live contribution in the original fold order; no associativity is assumed. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.BroadcastWindow

open Pilot

/-- A finite fold with one distinguished value and identity padding yields that value in place. -/
theorem foldl_single_live {α : Type} (operation : α → α → α) (initial padding value : α)
    (left : operation initial value = value) (right : ∀ state, operation state padding = state)
    (count : Nat) (live : Fin count) :
    ((List.finRange count).map fun position => if position = live then value else padding).foldl
      operation initial = value := by
  induction count with
  | zero => exact Fin.elim0 live
  | succ count ih =>
    refine Fin.cases ?_ (fun live => ?_) live
    · simp only [List.finRange_succ, List.map_cons, List.map_map, Function.comp_def,
        ite_true, Fin.succ_ne_zero, ite_false, List.foldl_cons, left, List.map_const',
        List.length_finRange]
      exact ReductionWindow.foldl_replicate_fixed operation value padding (right value) count
    · simp only [List.finRange_succ, List.map_cons, List.map_map, Function.comp_def,
        Fin.succ_inj, Ne.symm (Fin.succ_ne_zero live), ite_false,
        List.foldl_cons, right]
      exact ih live

/-- The live linear position is derived by the existing row-major coordinate linearization. -/
def livePosition (plan : Plan) (output : Index (windowPlan plan).outputShape) :
    Fin (LinearIndex.elementCount (windowPlan plan).kernelShape) :=
  LinearIndex.linearize (windowPlan plan).kernelShape (liveKernel plan output)

/-- The actual contribution at each linear position is the live input value or actual padding. -/
theorem contribution_at_position {α : Type} (plan : Plan) (padding : α)
    (input : Tensor (windowPlan plan).inputShape α) (output : Index (windowPlan plan).outputShape)
    (position : Fin (LinearIndex.elementCount (windowPlan plan).kernelShape)) :
    ReductionWindow.contribution (windowPlan plan) padding input output
      (LinearIndex.delinearize (windowPlan plan).kernelShape position) =
      if position = livePosition plan output then input (sourceIndex plan output) else padding := by
  classical
  unfold ReductionWindow.contribution
  rw [sample_if]
  by_cases same : position = livePosition plan output
  · subst position
    simp only [livePosition, LinearIndex.delinearize_linearize, ite_true]
  · have different : LinearIndex.delinearize (windowPlan plan).kernelShape position ≠
        liveKernel plan output := by
      intro equal
      apply same
      calc
        position = LinearIndex.linearize (windowPlan plan).kernelShape
            (LinearIndex.delinearize (windowPlan plan).kernelShape position) :=
          (LinearIndex.linearize_delinearize _ _).symm
        _ = livePosition plan output := congrArg (LinearIndex.linearize _) equal
    simp only [same, different, ite_false]

end TensorRewrite.Theory.BroadcastWindow
