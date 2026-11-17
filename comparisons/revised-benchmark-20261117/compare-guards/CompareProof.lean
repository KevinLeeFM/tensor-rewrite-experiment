module
public import CompareSpec
public section
set_option autoImplicit false
namespace RevisedBenchmark.CompareGuards
open TensorRewrite.Pilot

theorem predGuards : PredGuards := by
  intro r s g x
  constructor
  · intro guard
    rw [g.isAll_sound false guard]
    constructor <;> funext i <;> cases h : x i <;> rfl
  · intro guard
    rw [g.isAll_sound true guard]
    constructor <;> funext i <;> cases h : x i <;> rfl

theorem causalBoundary : CausalBoundary := by
  intro r s α eqv yes no rhs
  constructor
  · intro h i
    have a := congrFun (h (Tensor.constant true)) i
    have b := congrFun (h (Tensor.constant false)) i
    simpa [causal, Tensor.constant] using And.intro a b
  · intro h p
    funext i
    rcases h i with ⟨a,b⟩
    cases v : p i <;> simp [causal,v,a,b]

theorem causalPred : CausalPred := by
  intro r s yes no rhs p hy hn hr
  rw [yes.isAll_sound true hy, no.isAll_sound false hn, rhs.isAll_sound false hr]
  exact (causalBoundary s Bool _ _ _).mpr (fun _ => ⟨by change true ≠ false; decide, rfl⟩) p

/-- Concrete integer branch with tensor GE predicate, one/zero arms and zero RHS. -/
theorem integerGE {r : Nat} {s : Shape r} (x y : Tensor s Int) :
    causal (fun i => decide (x i ≥ y i)) (Tensor.constant 1) (Tensor.constant 0)
      (Tensor.constant (0 : Int)) = (fun i => decide (x i ≥ y i)) :=
  (causalBoundary s Int _ _ _).mpr (fun _ => ⟨by change (1 : Int) ≠ 0; decide,rfl⟩) _

example : causal (Tensor.constant true) (Tensor.constant (0 : Int))
    (Tensor.constant 0) (Tensor.constant 0) (s:=fun _ : Fin 0 => 1) (fun i => i.elim0) = false := by decide
example : causal (Tensor.constant false) (Tensor.constant (1 : Int))
    (Tensor.constant 1) (Tensor.constant 0) (s:=fun _ : Fin 0 => 1) (fun i => i.elim0) = true := by decide
#print axioms predGuards
#print axioms causalBoundary
#print axioms causalPred
#print axioms integerGE
end RevisedBenchmark.CompareGuards
