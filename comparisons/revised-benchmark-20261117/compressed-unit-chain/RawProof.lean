import RawSpec
import ChainProof
namespace CompressedChain
open TensorRewrite.Pilot
theorem addr_live (s : Frame n) (a : Fin (n+1)) (o : AxisPermutation n)
    (w : Fin n → Nat) (z : Digits s) (hz : validUnit s z) :
    address s a o w z = ordinal (List.ofFn (fun j => let i := o.outputToInput j; (w i,z (slot s i)))) 0 := by
  cases s with
  | plain => rfl
  | unit u => simpa only [address, (show z u=0 from hz)] using
      fold_unit (List.ofFn (fun j => let i := o.outputToInput j; (w i,z (slot (.unit u) i)))) a.val 0
theorem raw_verified : RawGate := by
  intro n s t c hid su tu o w y hy α storage
  rw [addr_live _ _ _ _ _ (chain_unit _ _ hy), addr_live _ _ _ _ _ hy]
  have h (j : Fin n) : back c y (slot s j) = y (slot t j) := by simpa [hid] using chain_slot c y j
  simp only [h]
#print axioms raw_verified
end CompressedChain
