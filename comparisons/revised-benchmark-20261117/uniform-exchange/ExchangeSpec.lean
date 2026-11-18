import Std
set_option autoImplicit false
namespace RevisedBenchmark.Exchange

private theorem widthPos {g k : Nat} (i : Fin (g*k)) : 0 < k := by
  cases k with
  | zero => exact False.elim (by simpa using i.isLt)
  | succ n => exact Nat.zero_lt_succ n

/-- Source group position in an ordered concatenation of equal length blocks. -/
def sender {g k : Nat} (i : Fin (g*k)) : Fin g :=
  ⟨i.val/k, (Nat.div_lt_iff_lt_mul (widthPos i)).mpr i.isLt⟩

def offset {g k : Nat} (i : Fin (g*k)) : Fin k := ⟨i.val%k, Nat.mod_lt _ (widthPos i)⟩

/-- Offset into a participant's unsplit input. -/
def slot {g k : Nat} (r : Fin g) (j : Fin k) : Fin (g*k) :=
  ⟨r.val*k+j.val, by
    have lt := Nat.add_lt_add_left j.isLt (r.val*k)
    have le := Nat.mul_le_mul_right k (Nat.succ_le_of_lt r.isLt)
    rw [Nat.succ_mul] at le
    omega⟩

/-- C collects coordinates on all unmodified axes, including a possibly empty product. -/
def gather {g k : Nat} {C A : Type} (x : Fin g → Fin k → C → A) :
    Fin g → Fin (g*k) → C → A := fun _ i c => x (sender i) (offset i) c

/-- Single-array HLO AllToAll, split and concat on the same axis. -/
def exchange {g k : Nat} {C A : Type} (x : Fin g → Fin (g*k) → C → A) :
    Fin g → Fin (g*k) → C → A := fun receiver i c =>
  x (sender i) (slot receiver (offset i)) c

/-- A participant-local constant can be forwarded globally precisely under
group agreement on inhabited outputs. -/
def Agreement (g k : Nat) (C A : Type) (v : Fin g → A) : Prop :=
  k = 0 ∨ ¬ Nonempty C ∨ ∀ a b, v a = v b

def GatherCase : Prop := ∀ (g k : Nat) (_ : 0 < g) (C A : Type) (v : Fin g → A),
  (gather (k := k) (C := C) (fun r _ _ => v r) = fun r _ _ => v r) ↔ Agreement g k C A v

def ExchangeCase : Prop := ∀ (g k : Nat) (_ : 0 < g) (C A : Type) (v : Fin g → A),
  (exchange (k := k) (C := C) (fun r _ _ => v r) = fun r _ _ => v r) ↔ Agreement g k C A v
end RevisedBenchmark.Exchange
