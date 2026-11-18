module
public import EarlySpec
public section
set_option autoImplicit false
namespace RevisedBenchmark.WindowEarly

private theorem nonemptyDims {ns : List Nat} (p : Coord ns) : 0 ∉ ns := by
  induction p with
  | nil => simp
  | @cons n ns i _ ih =>
    intro impossible
    rcases List.mem_cons.mp impossible with hz | tail
    · have := i.isLt; omega
    · exact ih tail

theorem empty : EmptyGoal := by
  intro α axes h op init x
  funext o
  rcases h with hi | ho
  · have none : reads axes o = [] := by
      cases eq : reads axes o with
      | nil => rfl
      | cons p ps => exact False.elim (nonemptyDims p hi)
    simp [window,none]
  · exact False.elim (nonemptyDims o ho)

theorem scalar : ScalarGoal := by
  intro α op init identity x
  funext p
  cases p
  exact identity _

theorem singleton : SingletonGoal := by
  intro α axes op init x
  funext o
  unfold window
  generalize reads axes o = ps
  induction ps generalizing init with
  | nil => rfl
  | cons p ps ih =>
    simp only [List.foldl_cons]
    cases eq : op ⟨init⟩ ⟨x p⟩ with
    | mk v => exact ih v

/-- Inputs of different element types at a common coordinate are fed to a
single coupled reducer. Each tuple output takes its corresponding result field. -/
theorem emptyTuple {n : Nat} (τ : Fin (n+1) → Type) (axes : List Axis)
    (h : 0 ∈ axes.map Axis.base ∨ 0 ∈ axes.map extent)
    (op : ((j : Fin (n+1)) → τ j) → ((j : Fin (n+1)) → τ j) → ((j : Fin (n+1)) → τ j))
    (seed : (j : Fin (n+1)) → τ j) (xs : (j : Fin (n+1)) → Coord (axes.map Axis.base) → τ j) :
    (fun j o => window axes op seed (fun p j => xs j p) o j) =
      (fun (j : Fin (n+1)) (_ : Coord (axes.map extent)) => seed j) := by
  funext j o
  exact congrFun (congrFun (empty _ axes h op seed _) o) j

theorem scalarTuple {n : Nat} (τ : Fin (n+1) → Type)
    (op : ((j : Fin (n+1)) → τ j) → ((j : Fin (n+1)) → τ j) → ((j : Fin (n+1)) → τ j))
    (seed : (j : Fin (n+1)) → τ j) (h : ∀ v, op seed v = v)
    (xs : (j : Fin (n+1)) → Coord [] → τ j) :
    (fun j o => window [] op seed (fun p j => xs j p) o j) = xs := by
  funext j o
  exact congrFun (congrFun (scalar _ op seed h _) o) j

#print axioms emptyTuple
#print axioms scalarTuple
#print axioms empty
#print axioms scalar
#print axioms singleton
end RevisedBenchmark.WindowEarly
