import Std
set_option autoImplicit false
namespace Auxiliary.DebugPad
abbrev V (r : Nat) := Fin r → Int

def span (s h : Int) := s + max 0 (s-1)*h
def extent {r : Nat} (s lo hi h : V r) : V r := fun i => lo i + hi i + span (s i) (h i)
def zero {r : Nat} : V r := fun _ => 0
def plus {r : Nat} (a b : V r) : V r := fun i => a i + b i
def valid {r : Nat} (s q : V r) := ∀ i, 0 ≤ q i ∧ q i < s i
def occupied (s lo h q : Int) := lo ≤ q ∧ q < lo + span s h ∧ (q-lo) % (h+1) = 0

instance (s lo h q : Int) : Decidable (occupied s lo h q) := by unfold occupied; infer_instance

def pad {r : Nat} {α : Type} (s lo h : V r) (fill : α) (x : V r → α) (q : V r) :=
  if ∀ i, decide (occupied (s i) (lo i) (h i) (q i)) = true then
    x (fun i => (q i-lo i)/(h i+1)) else fill

def nestedGoal := ∀ (r : Nat) (s l h t u v : V r),
  (∀ i, 0 ≤ s i ∧ 0 ≤ l i ∧ 0 ≤ h i ∧ 0 ≤ t i) →
  let mid := extent s l h t
  let lhs := extent mid u v zero
  let rhs := extent s (plus l u) (plus h v) t
  (∀ i, 0 ≤ lhs i) →
  lhs = rhs ∧ ∀ (α : Type) (z : α) (x : V r → α) (q : V r), valid lhs q →
    pad mid u zero z (pad s l t z x) q = pad s (plus l u) t z x q

/-- The primitive padLow tests only the low boundary on a valid output index. -/
def padLow {r : Nat} {α : Type} (l : V r) (z : α) (x : V r → α) (q : V r) :=
  if ∀ i, l i ≤ q i then x (fun i => q i-l i) else z
def lowGoal := ∀ (r : Nat) (s l u : V r), (∀ i, 0 ≤ s i ∧ 0 ≤ l i ∧ 0 ≤ u i) →
  plus (plus s l) u = plus s (plus l u) ∧ ∀ (α : Type) (z : α) (x : V r → α) (q : V r),
    valid (plus (plus s l) u) q → padLow u z (padLow l z x) q = padLow (plus l u) z x q
end Auxiliary.DebugPad
