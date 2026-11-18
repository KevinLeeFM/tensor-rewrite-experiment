module
public import Std

@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.ReduceReshape

/-- A static common-factor group in minor-to-major order. Singleton pairs
may be kept or reduced. All edited axes have the branch's uniform role. -/
inductive Group where
  | single (size : Nat) (keep : Bool)
  | edit (input reshaped : List Nat) (volume : input.prod = reshaped.prod)

abbrev Axes := List (Nat × Bool)

/-- Row-major axes, least significant first. true marks a surviving axis. -/
def axes (editedKeep afterReshape : Bool) (g : Group) : Axes :=
  match g with
  | .single n keep => [(n, keep)]
  | .edit a b _ => (if afterReshape then b else a).map (fun n => (n, editedKeep))

def shape (ds : Axes) := ds.map Prod.fst
def resultShape (ds : Axes) := (ds.filter fun d => d.2).map Prod.fst

/-- Decode a flat input position and repack only its surviving digits. -/
def project : Axes → Nat → Nat
  | [], _ => 0
  | (n, keep) :: ds, k =>
    let high := project ds (k / n)
    if keep then k % n + n * high else high

/-- Ordered physical positions in the output fiber. -/
def fiber (ds : Axes) (out : Nat) : List Nat :=
  (List.range (shape ds).prod).filter (fun k => project ds k == out)

/-- Flat observations. Reshape preserves flat order on equal-size shapes. -/
def reduceFlat {α : Type} (ds : Axes) (read : Nat → α) (init : α) (op : α → α → α) :=
  (List.range (resultShape ds).prod).map fun out =>
    (fiber ds out).foldl (fun acc k => op acc (read k)) init

/-- Both results have equal shape (drop reshape) or compatible size (move
reshape after reduce), and each physical input fiber and result value agrees. -/
def Goal (editedKeep : Bool) := ∀ (groups : List Group),
  let src := groups.flatMap (axes editedKeep false)
  let dst := groups.flatMap (axes editedKeep true)
  (shape src).prod = (shape dst).prod ∧
  (if editedKeep then (resultShape src).prod = (resultShape dst).prod
   else resultShape src = resultShape dst) ∧
  (∀ out, fiber dst out = fiber src out) ∧
  ∀ (α : Type) (read : Nat → α) (init : α) (op : α → α → α),
    reduceFlat dst read init op = reduceFlat src read init op
end RevisedBenchmark.ReduceReshape
