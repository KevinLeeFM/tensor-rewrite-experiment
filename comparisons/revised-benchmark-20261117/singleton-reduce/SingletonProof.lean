module
public import StructuralReuse
public section
set_option autoImplicit false
namespace RevisedBenchmark.SingletonReduce
open TensorRewrite.Pilot TensorRewrite.Pilot.Reduction

/-- Transport the entire ordered fold through singleton packing. -/
theorem unpack : Goal := by
  intro α p body init xs
  let pack := fun (x : α) (_ : Fin 1) => x
  let step := fun a b => body a b 0
  let whole := fun (a b : Fin 1 → α) => body (a 0) (b 0)
  have conjugate (a b : α) : whole (pack a) (pack b) = pack (step a b) := by
    funext i
    exact congrArg (body a b) (Subsingleton.elim i 0)
  funext c j
  change (fiberValues p (Tensor.map pack xs) j).foldl whole (pack init) c =
    (fiberValues p xs j).foldl step init
  rw [Reuse.fiberValues_map, Reuse.foldl_map_hom pack step whole conjugate]

private def body (a b : Nat) (_ : Fin 1) := 2*a+b
private def j : Index Plan.scalar.outputShape := fun i => i.elim0
private def pairInput : Tensor (Plan.reduce 2 .scalar).inputShape Nat := fun i => (i ⟨0, by decide⟩).val + 1
example : reduceTensor (.reduce 2 .scalar) (fun a b => body a b 0) 3 pairInput j = 16 := by decide
example : reduceTensor (.reduce 2 .scalar) (fun a b => body a b 0) 3 pairInput j ≠
    reduceTensor (.reduce 2 .scalar) Nat.add 3 pairInput j := by decide
example : reduceTensor (.reduce 0 .scalar) (fun a b => body a b 0) 3 (fun _ => 7) j = 3 := by decide
example : reduceTensor .scalar (fun a b => body a b 0) 3 (fun _ => 7) j = 13 := by decide
#print axioms unpack
end RevisedBenchmark.SingletonReduce
