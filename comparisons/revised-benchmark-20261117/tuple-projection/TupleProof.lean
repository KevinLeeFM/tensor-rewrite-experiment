module
public import TupleSpec
public section
set_option autoImplicit false
namespace RevisedBenchmark.TupleProjection
universe u v

/-- Positional lookup after ordered tuple formation returns the typed operand. -/
theorem projection : Goal.{u,v} := by
  intro Tag Payload n tags operands i
  simp [makeTuple, i.isLt]

private def payload : Bool → Type
  | false => Nat
  | true => Bool

private def tags (i : Fin 2) : Bool := decide (i.val = 1)

private def entries (i : Fin 2) : payload (tags i) :=
  if h : i.val = 1 then by simp [tags, h, payload]; exact true
  else by simp [tags, h, payload]; exact 3

example : (makeTuple tags entries)[1]? = some ⟨true, true⟩ := rfl
example : (makeTuple tags entries)[0]? = some ⟨false, (3 : Nat)⟩ := rfl
example : (makeTuple tags entries)[0]? ≠ some ⟨true, true⟩ := by
  intro h
  exact Bool.noConfusion (congrArg Sigma.fst (Option.some.inj h))

example : (makeTuple (Payload := fun _ : Unit => Nat)
    (fun _ : Fin 1 => ()) (fun _ => 17))[0]? = some ⟨(), 17⟩ := rfl
example : (makeTuple (Payload := fun _ : Unit => Nat)
    (fun _ : Fin 0 => ()) (fun i => i.elim0))[0]? = none := rfl

#print axioms projection
end RevisedBenchmark.TupleProjection
