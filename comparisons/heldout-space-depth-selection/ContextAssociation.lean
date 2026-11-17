module
public import ProductAssociation
public import TensorRewrite.Pilot.LinearIndex
/-! Packing reassociation surrounded by arbitrary ranked coordinate contexts. -/
@[expose] public section
set_option autoImplicit false
namespace Heldout.ContextAssociation
open TensorRewrite.Pilot TensorRewrite.Pilot.LinearIndex TensorRewrite.Pilot.FiniteProduct

/-- Merge adjacent axes without changing a packed pre or packed post. -/
theorem context_associate {p a b s : Nat} (pre : Fin p) (x : Fin a) (y : Fin b)
    (post : Fin s) :
    Fin.cast (congrArg (p * ·) (Nat.mul_assoc a b s))
      (join pre (join (join x y) post)) = join pre (join x (join y post)) := by
  apply Fin.ext
  simp only [Fin.val_cast, join, Nat.add_mul, Nat.mul_assoc, Nat.add_assoc]

/-- The same equality for prefixes and suffixes of any rank and any valid coordinates. -/
theorem shape_context_associate {pr sr : Nat} (prefixShape : Shape pr) (suffixShape : Shape sr)
    (pre : Index prefixShape) (post : Index suffixShape) {a b : Nat}
    (x : Fin a) (y : Fin b) :
    Fin.cast (congrArg ((elementCount prefixShape) * ·)
      (Nat.mul_assoc a b (elementCount suffixShape)))
      (join (linearize prefixShape pre) (join (join x y) (linearize suffixShape post))) =
      join (linearize prefixShape pre) (join x (join y (linearize suffixShape post))) :=
  context_associate (linearize prefixShape pre) x y (linearize suffixShape post)

#print axioms context_associate
#print axioms shape_context_associate
end Heldout.ContextAssociation
