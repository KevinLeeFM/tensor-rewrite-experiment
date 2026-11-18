import Std
set_option autoImplicit false
namespace ArtifactAux.DynamicSlice

def iota (n : Nat) (i : Fin n) : Int := Int.ofNat i.val

/-- The typed artifact checks nonnegative starts/sizes and start + length ≤ n. -/
def dynamicSlice {n : Nat} (x : Fin n → Int) (s len : Nat) (fits : s+len ≤ n)
    (j : Fin len) : Int :=
  x ⟨s+j.val, by have := j.isLt; omega⟩

def original (n s len : Nat) (fits : s+len ≤ n) : List Int :=
  List.ofFn (dynamicSlice (iota n) s len fits)

def replacement (a : Int) : List Int := List.ofFn (fun _ : Fin 1 => a)

/-- Rank-one finite TensorInt observations, with list length recording the extent.
The source declares no relation between its free literal and the slice indices. -/
def Goal := ∀ (n s len : Nat) (fits : s+len ≤ n) (a : Int),
  original n s len fits = replacement a
end ArtifactAux.DynamicSlice
