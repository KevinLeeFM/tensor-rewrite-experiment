import ReverseMaskSpec
set_option autoImplicit false
namespace RevisedBenchmark.ReverseMasks
open TensorRewrite.Pilot Tensor

theorem compose : Compose := by
  intro r s a b α x
  rw [Reverse.reverse_comp]
  have mask : (fun k => axisMask a k ^^ axisMask b k) = axisMask (difference a b) := by
    funext k
    by_cases ha : k ∈ a <;> by_cases hb : k ∈ b <;> simp [axisMask, difference, ha, hb]
  rw [mask]

theorem cancel : Cancel := by
  intro r s a b α x empty
  rw [compose, empty]
  exact Reverse.reverse_axisMask_trivial x [] (by simp)

theorem identityBoundary : IdentityBoundary := by
  intro r s a
  constructor
  · intro forwards ⟨j⟩ k hk
    let zero : Index s := fun t => ⟨0, Nat.zero_lt_of_lt (j t).isLt⟩
    have eq := congrFun (forwards Nat (fun i => (i k).val)) zero
    change ((reverseIndex (axisMask a) zero k).val) = 0 at eq
    simp [reverseIndex, axisMask, hk, zero, Fin.rev] at eq
    have bound := (j k).isLt
    omega
  · intro h α x
    by_cases inhabited : Nonempty (Index s)
    · exact Reverse.reverse_axisMask_trivial x a (h inhabited)
    · funext i
      exact (inhabited ⟨i⟩).elim

theorem binary : Binary := by
  intro r s a α f x v
  exact ⟨Reverse.reverse_binary_constant_lhs x _ f v, Reverse.reverse_binary_constant_rhs x _ f v⟩

example : difference ([1,0] : List (Fin 3)) [0,2] = [1,2] := by decide
example : difference ([1,0] : List (Fin 3)) [0,1] = [] := by decide
example : ¬ (∀ (α : Type) (x : Tensor (fun _ : Fin 1 => 2) α),
    reverse (axisMask [0]) x = x) := by
  intro bad
  have e := (identityBoundary _ _).mp bad ⟨fun _ => ⟨0,by decide +revert⟩⟩ 0 (by decide)
  contradiction
example : map₂ (· - ·) (constant 3) (constant 8 : Tensor (fun _ : Fin 0 => 1) Int)
    (fun i => i.elim0) = -5 := by decide
example : map₂ (· - ·) (constant 8) (constant 3 : Tensor (fun _ : Fin 0 => 1) Int)
    (fun i => i.elim0) = 5 := by decide
#print axioms compose
#print axioms cancel
#print axioms identityBoundary
#print axioms binary
end RevisedBenchmark.ReverseMasks
