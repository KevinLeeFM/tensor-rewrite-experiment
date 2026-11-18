import GatherHoistSpec
namespace RevisedBenchmark.GatherReshapePad
open GatherHoist

def splitRow {p q : Nat} (row : Fin (p*q)) : Fin p × Fin q :=
  have pq : 0 < p*q := Nat.zero_lt_of_lt row.isLt
  have hq : 0 < q := by
    by_cases h : q = 0
    · simp [h] at pq
    · omega
  ⟨⟨row.val/q, (Nat.div_lt_iff_lt_mul hq).mpr (by simpa [Nat.mul_comm] using row.isLt)⟩,
   ⟨row.val%q, Nat.mod_lt _ hq⟩⟩

def reshapeRows {p q : Nat} (x : Fin p → Fin q → β) (row : Fin (p*q)) : β :=
  x (splitRow row).1 (splitRow row).2
def padRow (a : Axis) (fill : α) (values : Fin a.size → α) (k : Fin (extent a).toNat) : α :=
  match decode a k with | none => fill | some i => values i
def gatherRows {m w : Nat} (h : w ≤ m) (values : Fin m → β) (s : Int) (j : Fin w) :=
  values (atStart h s j)

def Goal := ∀ (p q w : Nat) (h : w ≤ p*q) (a : Axis), 0 ≤ extent a →
  ∀ (α : Type) (fill : α) (x : Fin p → Fin q → Fin a.size → α) (s : Int)
    (j : Fin w) (k : Fin (extent a).toNat),
    gatherRows h (reshapeRows (fun i b => padRow a fill (x i b))) s j k =
      padRow a fill (gatherRows h (reshapeRows x) s j) k
end RevisedBenchmark.GatherReshapePad
