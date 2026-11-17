module
public import TupleReduceSpec
public import SameCountProof
public section
set_option autoImplicit false
namespace RevisedBenchmark.TupleReduce
open TensorRewrite.Pilot TensorRewrite.Pilot.LinearIndex TensorRewrite.Pilot.Reduction

/-- The empty fold preserves each actual initializer in its original slot. -/
theorem empty : EmptyGoal := by
  intro k A p op init xs guard
  let packed := fun i c => xs c i
  have h : reduceTensor p op init packed = Tensor.constant init := by
    rcases guard with h | h
    · exact reduceTensor_empty_input p op init packed h
    · exact reduceTensor_empty_output p op init packed h
  exact congrArg (fun t => fun c j => t j c) h

/-- Transposing component and tensor indexing is lossless in both directions. -/
theorem sameCount : SameGoal := by
  intro k A p op init same
  constructor
  · intro all
    apply (SameCountExact.uniform_iff p op init same).mp
    intro packed
    have h := all (fun c i => packed i c)
    exact congrArg (fun t => fun j c => t c j) h
  · intro law xs
    have h := (SameCountExact.uniform_iff p op init same).mpr law (fun i c => xs c i)
    exact congrArg (fun t => fun c j => t j c) h

private def carrier (c : Fin 2) : Type := if c.val = 0 then Nat else Bool
private def initial (c : Fin 2) : carrier c :=
  if h : c.val = 0 then by simp [carrier, h]; exact 9
  else by simp [carrier, h]; exact false
private def coupled (a b : (c : Fin 2) → carrier c) (c : Fin 2) : carrier c :=
  if h : c.val = 0 then by
    simp [carrier, h]
    let flag : Bool := b 1
    let count : Nat := a 0
    exact if flag then count + 1 else count
  else by simp [carrier, h]; exact true
private def atScalar : Index Plan.scalar.outputShape := fun i => i.elim0
private def xs (p : Plan) (c : Fin 2) : Tensor p.inputShape (carrier c) := fun _ => initial c

example : original (.reduce 0 .scalar) coupled initial (xs _) 0 atScalar = (9 : Nat) := rfl
example : original (.reduce 0 .scalar) coupled initial (xs _) 1 atScalar = false := rfl
example : original (.reduce 1 .scalar) coupled initial (xs _) 1 atScalar ≠
    Reshape.reshapeTensor (xs (.reduce 1 .scalar) 1) Plan.scalar.outputShape (by decide) atScalar := by
  change true ≠ false
  decide
#print axioms empty
#print axioms sameCount
end RevisedBenchmark.TupleReduce
