import Std
namespace RevisedBenchmark.UpdateConstantPad
def start (e w : Nat) (s : Int) : Int := max 0 (min s ((e : Int) - w))
def low (e w : Nat) (s : Int) := min s.toNat (e - w)
def high (e w : Nat) (s : Int) := e - (low e w s + w)
abbrev Axis (r : Nat) := Fin r
abbrev Shape (r : Nat) := Axis r → Nat
abbrev Ix {r : Nat} (e : Shape r) := (j : Axis r) → Fin (e j)
def update {r : Nat} {α : Type} (e w : Shape r) (s : Axis r → Int)
    (fill : α) (read : (Axis r → Nat) → α) (o : Ix e) : α :=
  if ∀ j, start (e j) (w j) (s j) ≤ (o j).val ∧
      ((o j).val : Int) < start (e j) (w j) (s j) + w j then
    read (fun j => (((o j).val : Int) - start (e j) (w j) (s j)).toNat)
  else fill
def padded {r : Nat} {α : Type} (e w : Shape r) (s : Axis r → Int)
    (fill : α) (read : (Axis r → Nat) → α) (o : Ix e) : α :=
  if ∀ j, low (e j) (w j) (s j) ≤ (o j).val ∧
      (o j).val - low (e j) (w j) (s j) < w j then
    read (fun j => (o j).val - low (e j) (w j) (s j))
  else fill
def Goal := ∀ (r : Nat) (e w : Shape r) (fit : ∀ j, w j ≤ e j) (s : Axis r → Int),
  (∀ j, low (e j) (w j) (s j) + w j + high (e j) (w j) (s j) = e j) ∧
  ∀ (α : Type) (fill : α) (read : (Axis r → Nat) → α),
    update e w s fill read = padded e w s fill read
end RevisedBenchmark.UpdateConstantPad
