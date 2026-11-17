module
public import Std
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.DynamicSort
inductive Dim where
  | fixed (n : Nat)
  | bounded (upper : Nat)
  | unbounded
def Dim.stored : Dim → Int
  | .fixed n | .bounded n => n
  | .unbounded => -(2^63)
def Dim.admits (d : Dim) (n : Nat) : Prop :=
  match d with
  | .fixed k => n = k
  | .bounded k => n ≤ k
  | .unbounded => True
/-- Source-shaped guard for a rank-one array. -/
def forward (d : Dim) : Prop := d.stored = 0 ∨ d.stored ≤ 1

/-- Pointwise equality of forwarding and ascending runtime sorting. -/
def SingleClaim : Prop :=
  ∀ (d : Dim) (xs : List Nat), d.admits xs.length → forward d →
    xs.mergeSort (fun a b => decide (a < b)) = xs
/-- Row representation of two component arrays, sorted together by key. -/
def TupleClaim : Prop :=
  ∀ (d : Dim) (rows : List (Nat × Bool)), d.admits rows.length → forward d →
    (rows.mergeSort (fun a b => decide (a.1 < b.1))).map Prod.fst = rows.map Prod.fst ∧
    (rows.mergeSort (fun a b => decide (a.1 < b.1))).map Prod.snd = rows.map Prod.snd
end RevisedBenchmark.DynamicSort
