module
public import FiberSpec

public section
set_option autoImplicit false
namespace RevisedBenchmark.ReduceReshape

private theorem projectGroup (ns : List Nat) (keep : Bool) (ds : Axes) (k : Nat) :
    project (ns.map (fun n => (n,keep)) ++ ds) k =
      (if keep then k % ns.prod + ns.prod * project ds (k / ns.prod)
       else project ds (k / ns.prod)) := by
  induction ns generalizing k with
  | nil => cases keep <;> simp [Nat.mod_one]
  | cons n rest ih =>
    simp only [List.map_cons, List.cons_append, project, List.prod_cons]
    rw [ih, Nat.div_div_eq_div_mul]
    cases keep <;> simp [Nat.mod_mul, Nat.mul_add, Nat.mul_assoc, Nat.add_assoc]

private theorem projectBoth (gs : List Group) (b : Bool) (k : Nat) :
    project (gs.flatMap (axes b false)) k = project (gs.flatMap (axes b true)) k := by
  induction gs generalizing k with
  | nil => rfl
  | cons g rest ih =>
    cases g with
    | single n keep => simp [axes, project, ih]
    | edit a c vol => simp [axes, projectGroup, vol, ih]

private theorem blockShapes (g : Group) (b : Bool) :
    (shape (axes b false g)).prod = (shape (axes b true g)).prod ∧
    (resultShape (axes b false g)).prod = (resultShape (axes b true g)).prod ∧
    (b = false → resultShape (axes b false g) = resultShape (axes b true g)) := by
  cases g with
  | single n keep => simp [axes]
  | edit a c h =>
    have out (ns : List Nat) (keep : Bool) :
        resultShape (ns.map (fun n => (n,keep))) = (if keep then ns else []) := by
      induction ns with
      | nil => cases keep <;> rfl
      | cons n ns ih => cases keep <;> simp_all [resultShape]
    cases b <;> simp [axes, shape, out, List.map_map, Function.comp_def, h]

private theorem allShapes (gs : List Group) (b : Bool) :
    let a := gs.flatMap (axes b false)
    let c := gs.flatMap (axes b true)
    (shape a).prod = (shape c).prod ∧
    (resultShape a).prod = (resultShape c).prod ∧
    (b = false → resultShape a = resultShape c) := by
  induction gs with
  | nil => simp
  | cons g rest ih =>
    obtain ⟨v, w, u⟩ := blockShapes g b
    obtain ⟨vt, wt, ut⟩ := ih
    have s (a c : Axes) : shape (a ++ c) = shape a ++ shape c := by simp [shape]
    have r (a c : Axes) : resultShape (a ++ c) = resultShape a ++ resultShape c := by
      simp [resultShape]
    simp only [List.flatMap_cons, s, r, List.prod_append]
    exact ⟨by rw [v, vt], by rw [w, wt], fun h => by rw [u h, ut h]⟩

private theorem verified (b : Bool) : Goal b := by
  intro gs
  obtain ⟨v, w, u⟩ := allShapes gs b
  have f (out : Nat) : fiber (gs.flatMap (axes b true)) out =
      fiber (gs.flatMap (axes b false)) out := by
    simp only [fiber, v, projectBoth]
  exact ⟨v, by cases b <;> simp [u, w], f, fun α read init op => by simp [reduceFlat, f, w]⟩

/-- Collapse/expand reduced axes, retaining the entire surviving shape. -/
theorem dropReshape : Goal false := verified false

/-- Collapse/expand surviving axes and finish with an output reshape. -/
theorem moveReshape : Goal true := verified true
#print axioms dropReshape
#print axioms moveReshape
end RevisedBenchmark.ReduceReshape
