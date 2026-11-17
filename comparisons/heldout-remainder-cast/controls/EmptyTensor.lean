module
import Spec
open TensorRewrite.Pilot Heldout.RemainderCast
/-- Empty-output equality is valid because no output coordinate exists. -/
example (left right : Tensor (fun _ : Fin 1 => 0) (BitVec 8)) :
    original 16 left right = replacement left right := by
  funext index
  exact Fin.elim0 (index 0)
