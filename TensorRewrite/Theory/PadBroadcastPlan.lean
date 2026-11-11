module

public import TensorRewrite.Theory.PadBroadcastGeometry

/-! Compile raw independent Pad/window axes to the derived terminal Broadcast graph. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.PadBroadcast

/-- Arbitrary finite axis lists with raw retained or singleton-expansion attributes. -/
inductive Plan where
  | scalar
  | keep (axis : KeptAxis) (tail : Plan)
  | expand (axis : Expansion) (covers : axis.Covers) (tail : Plan)

/-- Derive terminal attributes and their admission proofs from raw Pad/window attributes. -/
def broadcastPlan : Plan → BroadcastWindow.Plan
  | .scalar => .scalar
  | .keep axis tail =>
    .keep (PadWindow.fusedAxis axis.padding axis.window) (kept_pointwise axis) (broadcastPlan tail)
  | .expand axis covers tail =>
    .expand axis.broadcast (expansion_covers axis covers) (broadcastPlan tail)

/-- The original graph uses independent Pad and unchanged outer window templates. -/
def padPlan : (plan : Plan) → PadWindow.Plan (broadcastPlan plan).rank
  | .scalar => ⟨Fin.elim0, Fin.elim0⟩
  | .keep axis tail =>
    ⟨Fin.cases axis.padding (padPlan tail).padding, Fin.cases axis.window (padPlan tail).window⟩
  | .expand axis _ tail =>
    ⟨Fin.cases axis.padding (padPlan tail).padding, Fin.cases axis.window (padPlan tail).window⟩

end TensorRewrite.Theory.PadBroadcast
