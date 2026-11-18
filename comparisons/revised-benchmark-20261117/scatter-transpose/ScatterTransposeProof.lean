import ScatterTransposeSpec
set_option autoImplicit false
namespace RevisedBenchmark.ScatterT
open TensorRewrite.Pilot
private theorem mappedOrigin {r : Nat} (p : AxisPermutation r) (xs : List (Fin r × Int)) (a : Fin r) :
    origin (xs.map (fun (d,v) => (p.inputToOutput d,v))) a = origin xs (p.outputToInput a) := by
  induction xs with
  | nil => rfl
  | cons x xs ih =>
    obtain ⟨d,v⟩ := x
    have iff : a = p.inputToOutput d ↔ p.outputToInput a = d := by
      constructor
      · rintro rfl; exact p.output_input d
      · intro h; rw [← h,p.input_output]
    simp only [List.map_cons, origin, ih, iff]

private theorem sameStep {r : Nat} {α : Type} (s w : Shape r) (p : AxisPermutation r)
    (q : Point r) (op : α → α → α) (v : α) (e : Entry r α) :
    applyEntry s w (pull p q) op v e =
      applyEntry (fun a => s (p.outputToInput a)) (fun a => w (p.outputToInput a)) q op v (moved p e) := by
  have ho : origin (moved p e).1 = fun a => origin e.1 (p.outputToInput a) :=
    funext (mappedOrigin p e.1)
  have hitEq : hit s w (pull p q) (origin e.1) ↔
      hit (fun a => s (p.outputToInput a)) (fun a => w (p.outputToInput a)) q (origin (moved p e).1) := by
    rw [ho]
    constructor
    · intro h a; simpa [pull,p.input_output] using h (p.outputToInput a)
    · intro h a; simpa [pull,p.output_input] using h (p.inputToOutput a)
  unfold applyEntry
  by_cases h : hit s w (pull p q) (origin e.1)
  · rw [ite_eq_left h, ite_eq_left (hitEq.mp h)]
    congr 1
    change e.2 _ = e.2 _
    apply congrArg e.2
    funext a
    simp only [pull, ho, p.output_input]
  · rw [ite_eq_right h, ite_eq_right (fun h2 => h (hitEq.mpr h2))]

theorem verified : Case := by
  intro r α s w p es op base out
  let q : Point r := fun a => (out a).val
  have run (v : α) : es.foldl (applyEntry s w (pull p q) op) v =
      (es.map (moved p)).foldl (applyEntry (fun a => s (p.outputToInput a))
        (fun a => w (p.outputToInput a)) q op) v := by
    induction es generalizing v with
    | nil => rfl
    | cons e es ih =>
      simp only [List.foldl_cons,List.map_cons]
      rw [← sameStep,ih]
  exact run _
example : Case := verified
#print axioms verified
end RevisedBenchmark.ScatterT
