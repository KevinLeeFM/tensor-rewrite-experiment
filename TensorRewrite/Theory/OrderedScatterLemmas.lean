module

public import TensorRewrite.Theory.OrderedScatter

/-! Coordinatewise ordered-fold and scalar-transport facts for the actual update evaluator. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.OrderedScatter

open Pilot

/-- An event changes precisely its actual address and leaves every other coordinate unchanged. -/
theorem step_at {rank : Nat} {shape : Shape rank} {α : Type} (operation : α → α → α)
    (base : Tensor shape α) (entry : Entry shape α) (index : Index shape) :
    step operation base entry index =
      if entry.target = some index then operation (base index) entry.value else base index := by
  cases entry with
  | mk target value =>
    cases target with
    | none => rfl
    | some target => simp [step, eq_comm]

/-- Coordinate evaluation is exactly the original-order fold of values targeting that coordinate. -/
theorem run_at {rank : Nat} {shape : Shape rank} {α : Type} (operation : α → α → α)
    (base : Tensor shape α) (entries : List (Entry shape α)) (index : Index shape) :
    run operation base entries index = (valuesAt entries index).foldl operation (base index) := by
  induction entries generalizing base with
  | nil => rfl
  | cons entry rest ih =>
    change run operation (step operation base entry) rest index = _
    rw [ih, step_at]
    by_cases hit : entry.target = some index <;> simp [valuesAt, hit]

/-- Appending traces runs the first completely before the second, without reducer laws. -/
theorem run_append {rank : Nat} {shape : Shape rank} {α : Type} (operation : α → α → α)
    (base : Tensor shape α) (first second : List (Entry shape α)) :
    run operation base (first ++ second) = run operation (run operation base first) second := by
  simp only [run, List.foldl_append]

/-- Filtering a trace by coordinate preserves the actual append order and every duplicate. -/
theorem values_append {rank : Nat} {shape : Shape rank} {α : Type}
    (first second : List (Entry shape α)) (index : Index shape) :
    valuesAt (first ++ second) index = valuesAt first index ++ valuesAt second index := by
  simp only [valuesAt, List.filterMap_append]

/-- A genuine scalar reducer homomorphism commutes with one event and preserves its
actual target. -/
theorem step_map {rank : Nat} {shape : Shape rank} {α β : Type} (convert : α → β)
    (first : α → α → α) (second : β → β → β)
    (hom : ∀ a b, convert (first a b) = second (convert a) (convert b))
    (base : Tensor shape α) (entry : Entry shape α) :
    Tensor.map convert (step first base entry) =
      step second (Tensor.map convert base) (entry.mapValue convert) := by
  funext index
  cases entry with
  | mk target value =>
    cases target with
    | none => rfl
    | some target =>
      by_cases hit : index = target <;> simp [Tensor.map, step, Entry.mapValue, hit, hom]

/-- State mapping keeps the complete ordered trace and maps the actual original base. -/
theorem run_map {rank : Nat} {shape : Shape rank} {α β : Type} (convert : α → β)
    (first : α → α → α) (second : β → β → β)
    (hom : ∀ a b, convert (first a b) = second (convert a) (convert b))
    (base : Tensor shape α) (entries : List (Entry shape α)) :
    Tensor.map convert (run first base entries) =
      run second (Tensor.map convert base) (entries.map (Entry.mapValue convert)) := by
  induction entries generalizing base with
  | nil => rfl
  | cons entry rest ih =>
    change Tensor.map convert (run first (step first base entry) rest) = _
    rw [ih, step_map convert first second hom]
    rfl

/-- An associative operation pulls one left factor out of an actual ordered list fold. -/
theorem foldl_translate {α : Type} (operation : α → α → α)
    (assoc : ∀ a b c, operation (operation a b) c = operation a (operation b c))
    (first initial : α) (values : List α) :
    values.foldl operation (operation first initial) =
      operation first (values.foldl operation initial) := by
  induction values generalizing initial with
  | nil => rfl
  | cons value rest ih =>
    simpa only [List.foldl_cons, assoc] using ih (operation initial value)

/-- Associativity and commutativity derive two-fold combination without assuming trace equality. -/
theorem foldl_combine {α : Type} (operation : α → α → α)
    (assoc : ∀ a b c, operation (operation a b) c = operation a (operation b c))
    (comm : ∀ a b, operation a b = operation b a)
    (first second : α) (left right : List α) :
    operation (left.foldl operation first) (right.foldl operation second) =
      (left ++ right).foldl operation (operation first second) := by
  induction left generalizing first with
  | nil => exact (foldl_translate operation assoc first second right).symm
  | cons value rest ih =>
    simp only [List.foldl_cons, List.cons_append]
    rw [ih]
    have swap : operation (operation first value) second =
        operation (operation first second) value := by
      rw [assoc, comm value second, ← assoc]
    rw [swap]

end TensorRewrite.Theory.OrderedScatter
