import Std
set_option autoImplicit false
namespace RevisedBenchmark.GatherHoist

/-- Signed crop/edge padding and the number of holes between consecutive data positions. -/
structure Axis where
  size : Nat
  low : Int
  high : Int
  holes : Nat
deriving Repr
def span (a : Axis) : Nat := if a.size = 0 then 0 else (a.size-1)*(a.holes+1)+1
def extent (a : Axis) : Int := a.low + (span a : Int) + a.high
def decode (a : Axis) (i : Fin (extent a).toNat) : Option (Fin a.size) :=
  let u := (i.val : Int) - a.low
  let k := u.toNat / (a.holes+1)
  if h : 0 ≤ u ∧ u.toNat % (a.holes+1) = 0 ∧ k < a.size then
    some ⟨k,h.2.2⟩ else none

/-- A gather window along the indexed axis clamps its start and keeps a bounded offset. -/
def atStart {n w : Nat} (fits : w ≤ n) (s : Int) (j : Fin w) : Fin n :=
  ⟨min s.toNat (n-w) + j.val, by
    have := Nat.min_le_right s.toNat (n-w)
    have := j.isLt
    omega⟩

/-- Pad or crop the operand on batch and full-window axes, leaving lookup coordinates alone. -/
def padded {α : Type} {n : Nat} (b f : Axis) (fill : α)
    (x : Fin b.size → Fin f.size → Fin n → α)
    (bi : Fin (extent b).toNat) (fi : Fin (extent f).toNat) (k : Fin n) : α :=
  match decode b bi, decode f fi with
  | some i, some j => x i j k
  | _, _ => fill

/-- An index row at an inserted batch site takes the independent pad value of the indices. -/
def paddedStart {U : Type} (b : Axis) (fill : Int) (start : Fin b.size → U → Int)
    (bi : Fin (extent b).toNat) (u : U) : Int :=
  match decode b bi with | some i => start i u | none => fill

/-- Complete typed rank-three instance with one explicit batch, one offset passthrough and one
indexed window axis. U indexes any collection of independent query rows. Same result frame
(query, batch, lookup offset, passthrough offset) on both sides. -/
def Case : Prop := ∀ {α U : Type} (b f : Axis) (n w : Nat) (fits : w ≤ n),
  0 ≤ extent b → 0 ≤ extent f → ∀ (fill : α) (ifill : Int)
  (x : Fin b.size → Fin f.size → Fin n → α) (s : Fin b.size → U → Int),
  (fun (u : U) (bi : Fin (extent b).toNat) (j : Fin w) (fi : Fin (extent f).toNat) =>
    padded b f fill x bi fi (atStart fits (paddedStart b ifill s bi u) j)) =
  (fun u bi j fi => match decode b bi, decode f fi with
    | some i, some t => x i t (atStart fits (s i u) j)
    | _, _ => fill)

end RevisedBenchmark.GatherHoist
