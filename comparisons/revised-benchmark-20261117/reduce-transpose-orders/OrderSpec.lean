import RadixSpec

set_option autoImplicit false
namespace RevisedBenchmark.ReduceOrders
/-- Input physical axes [x,A,y,B]. Old transpose has [A,y,B,x] or [B,y,A,x]. -/
abbrev Input (α : Type) (x a y b : Nat) := Fin x → Fin a → Fin y → Fin b → α
def coords (m n : Nat) : List (Fin m × Fin n) :=
  (List.finRange m).flatMap fun i => (List.finRange n).map fun j => (i,j)
def frame (swap : Bool) (a b : Nat) := if swap then (b,a) else (a,b)

def before {α : Type} {x a y b : Nat} (swap : Bool) (u : Input α x a y b)
    (z : α) (op : α → α → α) :
    Fin (frame swap a b).1 → Fin (frame swap a b).2 → α :=
  match swap with
  | false => fun i j => (coords y x).foldl (fun acc t => op acc (u t.2 i t.1 j)) z
  | true => fun j i => (coords y x).foldl (fun acc t => op acc (u t.2 i t.1 j)) z

/-- New reduction on the untransposed operand enumerates the x,y coordinates. -/
def direct {α : Type} {x a y b : Nat} (u : Input α x a y b) (z : α)
    (op : α → α → α) (i : Fin a) (j : Fin b) :=
  (coords x y).foldl (fun acc t => op acc (u t.1 i t.2 j)) z
def after {α : Type} {x a y b : Nat} (swap : Bool) (u : Input α x a y b)
    (z : α) (op : α → α → α) :
    Fin (frame swap a b).1 → Fin (frame swap a b).2 → α :=
  match swap with
  | false => direct u z op
  | true => fun j i => direct u z op i j

def IntCase := ∀ (x a y b : Nat) (swap : Bool) (u : Input Int x a y b) (z : Int),
  before swap u z (·+·) = after swap u z (·+·)

/-- Only runs for which all sums stay in the finite integer-valued binary32 fragment are compared. -/
def add32 (a b : Option Nat) : Option Nat := do
  let m ← a
  let n ← b
  if m+n ≤ 2^30 then some (RadixIota.r32 (m+n)) else none
def FloatCase (swap : Bool) := ∀ (x a y b : Nat) (u : Input Nat x a y b),
  let data := fun i j k l => some (RadixIota.r32 (u i j k l))
  ∀ i j v w, before swap data (some 0) add32 i j = some v →
    after swap data (some 0) add32 i j = some w → v = w
end RevisedBenchmark.ReduceOrders
