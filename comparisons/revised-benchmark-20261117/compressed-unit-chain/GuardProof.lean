import BoundedSpec
import RawProof
namespace CompressedChain
theorem paired_input {s t : Frame n} (c : Chain n s t) (hi : ∀ i, total c i=i)
    (y : Digits t) (hy : validUnit t y) : back c y = expand s (y ∘ slot t) := by
  apply digits_ext _ _ _ (chain_unit _ _ hy) (unit_pull (.edit s t) y hy)
  intro i
  change back c y (slot s i) = expand s (y ∘ slot t) (slot s i)
  rw [expand_slot]
  simpa [hi] using chain_slot c y i
theorem guard_verified : GuardGate := by
  intro n s t c hi a b hab y hy α storage
  exact congrArg storage ((congrArg a (paired_input c hi y hy)).trans (hab y hy))
theorem bounded_verified : BoundedAddressGate := by
  intro n s t c hi w a b hab y hy hw α storage
  exact congrArg storage ((congrArg a (paired_input c hi y hy)).trans (hab y hy hw))
#print axioms bounded_verified
theorem concrete_guard (s t : Frame n) (su tu : Fin (n+1)) (o : TensorRewrite.Pilot.AxisPermutation n)
    (w : Fin n → Nat) : SameAddress (address s su o w) (address t tu o w) := by
  intro y hy
  exact raw_verified (.snoc (.start s) (.edit s t)) (fun _ => rfl) su tu o w y hy Nat id
#print axioms guard_verified
#print axioms concrete_guard
end CompressedChain
