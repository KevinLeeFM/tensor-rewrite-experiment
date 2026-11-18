import GatherHoistSpec
set_option autoImplicit false
namespace RevisedBenchmark.GatherHoist

theorem verified : Case := by
  intro α U b f n w fits _ _ fill ifill x s
  funext u bi j fi
  cases hb : decode b bi <;> cases hf : decode f fi <;> simp [padded, paddedStart, hb, hf]

def idAxis (n : Nat) : Axis := ⟨n,0,0,0⟩
theorem idExtent (n : Nat) : (extent (idAxis n)).toNat = n := by
  cases n <;> simp [extent,span,idAxis]
theorem startUnchanged {U : Type} (n : Nat) (s : Fin n → U → Int) (ifill : Int)
    (i : Fin (extent (idAxis n)).toNat) (u : U) :
    paddedStart (idAxis n) ifill s i u = s (Fin.cast (idExtent n) i) u := by
  have bound : i.val < n := by simpa only [idExtent] using i.isLt
  simp [paddedStart,decode,idAxis,bound,Fin.cast,Nat.mod_one]

#print axioms verified
#print axioms startUnchanged
end RevisedBenchmark.GatherHoist
