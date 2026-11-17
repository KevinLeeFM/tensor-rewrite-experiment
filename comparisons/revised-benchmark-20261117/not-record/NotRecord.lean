import TensorRewrite.Pilot.Boolean
import TensorRewrite.Pilot.Bitwise
set_option autoImplicit false

namespace RevisedBenchmark.NotRecord
open TensorRewrite.Pilot Tensor

/-- The two operand families of XLA Not. Each pair of maps uses the same
realized array shape and element type as the forwarded operand. -/
def Obligation : Prop := ∀ {r : Nat} (s : Shape r),
    (∀ x : Tensor s Bool, map Bool.not (map Bool.not x) = x) ∧
    ∀ (w : Nat) (x : Tensor s (BitVec w)),
      map (fun z => ~~~z) (map (fun z => ~~~z) x) = x

end RevisedBenchmark.NotRecord
