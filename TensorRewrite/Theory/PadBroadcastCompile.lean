module

public import TensorRewrite.Theory.PadBroadcastPlan

/-! Derive complete window attribute equality for the raw Pad/window axis compiler. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.PadBroadcast

/-- The terminal window is exactly the actual fused window, including all attributes. -/
theorem fused_window (plan : Plan) :
    PadWindow.fusedWindow (padPlan plan) = BroadcastWindow.windowPlan (broadcastPlan plan) := by
  induction plan with
  | scalar =>
    apply congrArg ReductionWindow.Plan.mk
    funext coordinate
    exact Fin.elim0 coordinate
  | keep axis tail ih =>
    apply congrArg ReductionWindow.Plan.mk
    funext coordinate
    exact Fin.cases rfl (fun coordinate => congrFun (congrArg ReductionWindow.Plan.window ih)
      coordinate) coordinate
  | expand axis covers tail ih =>
    apply congrArg ReductionWindow.Plan.mk
    funext coordinate
    exact Fin.cases (expansion_axis axis).symm
      (fun coordinate => congrFun (congrArg ReductionWindow.Plan.window ih) coordinate) coordinate


end TensorRewrite.Theory.PadBroadcast
