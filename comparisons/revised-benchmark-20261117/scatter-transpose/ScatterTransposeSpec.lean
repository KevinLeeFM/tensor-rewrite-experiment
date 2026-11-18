import TensorRewrite.Pilot.Permutation
set_option autoImplicit false
namespace RevisedBenchmark.ScatterT
open TensorRewrite.Pilot
abbrev Point (r : Nat) := Fin r → Int
def pull {r : Nat} (p : AxisPermutation r) (q : Point r) : Point r := fun a => q (p.inputToOutput a)
abbrev Entry (r : Nat) (α : Type) := List (Fin r × Int) × (Point r → α)
def origin {r : Nat} : List (Fin r × Int) → Point r
  | [], _ => 0
  | (d,v)::ds, a => if a = d then v else origin ds a
def hit {r : Nat} (s w : Shape r) (q o : Point r) : Prop := ∀ a,
  0 ≤ o a ∧ o a + (w a : Int) ≤ s a ∧ o a ≤ q a ∧ q a < o a + (w a : Int)
instance {r : Nat} (s w : Shape r) (q o : Point r) : Decidable (hit s w q o) := by
  unfold hit
  infer_instance
def applyEntry {r : Nat} {α : Type} (s w : Shape r) (q : Point r) (op : α → α → α)
    (acc : α) (e : Entry r α) :=
  if hit s w q (origin e.1) then op acc (e.2 (fun a => q a - origin e.1 a)) else acc
def moved {r : Nat} {α : Type} (p : AxisPermutation r) (e : Entry r α) : Entry r α :=
  (e.1.map (fun (d,v) => (p.inputToOutput d,v)), fun i => e.2 (pull p i))

def Case : Prop := ∀ {r : Nat} {α : Type} (s w : Shape r) (p : AxisPermutation r)
    (es : List (Entry r α)) (op : α → α → α) (base : Point r → α)
    (out : Index (fun a => s (p.outputToInput a))),
  let q : Point r := fun a => (out a).val
  es.foldl (applyEntry s w (pull p q) op) (base (pull p q)) =
    (es.map (moved p)).foldl
      (applyEntry (fun a => s (p.outputToInput a)) (fun a => w (p.outputToInput a)) q op)
      (base (pull p q))
end RevisedBenchmark.ScatterT
