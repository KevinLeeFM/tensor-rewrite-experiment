import ShiftProof
set_option autoImplicit false
open RevisedBenchmark.DividePowerTwo
example : shifted 255#8 2#8 = 127#8 := by decide
example : signedShift 128#8 2#8 = 192#8 := by decide
example : signedShift 253#8 2#8 = 255#8 := by decide
example : signedShift 253#8 2#8 ≠ (253#8).sshiftRight 1 := by decide
example : shifted 255#8 128#8 = 1#8 ∧ ¬ (0 < (128#8).toInt) := by decide
example : shifted 15#8 3#8 ≠ (15#8).udiv 3#8 := by decide
example : ¬ (0 < (0#8).toInt) := by decide
example : (0#8).toNat ≠ 2 ^ (0#8).toNat.log2 := by decide
example : ¬ Nonempty (TensorRewrite.Pilot.Index (fun _ : Fin 1 => 0)) := by
  rintro ⟨i⟩
  exact Fin.elim0 (i 0)
example : Nonempty (TensorRewrite.Pilot.Index (fun _ : Fin 0 => 0)) := ⟨fun i => Fin.elim0 i⟩
