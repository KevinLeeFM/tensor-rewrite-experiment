module
public import Std
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.Literal

/-- Exact equality of adjoining stored elements, the logical version of the overlapping range check. -/
def adjacent {α : Type} [DecidableEq α] : List α → Bool
  | [] | [_] => true
  | a :: b :: tail => decide (a = b) && adjacent (b :: tail)

/-- The literal's first scalar is broadcast across the original shape. Empty storage has no first. -/
def broadcastFirst {α : Type} (dims : List Nat) (xs : List α) : List α :=
  match xs with
  | [] => []
  | a :: _ => List.replicate dims.prod a

/-- Observe the shape and the full ordered list of logical elements. -/
def Uniform : Prop := ∀ (α : Type) [DecidableEq α] (dims : List Nat) (xs : List α),
  xs.length = dims.prod → 1 < dims.prod → adjacent xs = true →
  (dims, xs) = (dims, broadcastFirst dims xs)

/-- Walk the literal serially, testing each element against the scalar expected at its position. -/
def scan {α : Type} [DecidableEq α] (expected : Nat → α) : Nat → List α → Bool
  | _, [] => true
  | k, x :: xs => decide (x = expected k) && scan expected (k+1) xs

/-- Logical one-dimensional iota, with a specified scalar encoding. -/
def iota {α : Type} (encode : Nat → α) (n : Nat) : List α :=
  (List.range n).map encode

/-- Uniform reduction appears earlier in the handler; recognition requires a rank-one nonsingleton. -/
def Iota : Prop := ∀ (α : Type) [DecidableEq α] (encode : Nat → α) (xs : List α),
  1 < xs.length → adjacent xs = false → scan encode 0 xs = true →
  ([xs.length], xs) = ([xs.length], iota encode xs.length)

/-- Stride is inferred from the second literal element. Both preceding branches have priority. -/
def stride? (xs : List Int) : Option Int :=
  match xs with
  | _ :: s :: _ =>
    if adjacent xs || scan Int.ofNat 0 xs || s == 0 then none
    else if scan (fun k => Int.ofNat k * s) 0 xs then some s else none
  | _ => none

/-- One multiplication per iota entry by the inferred, scalar-broadcast stride. -/
def Strided : Prop := ∀ (xs : List Int) (s : Int), stride? xs = some s →
  ([xs.length], xs) = ([xs.length], (iota Int.ofNat xs.length).map (fun x => x * s))
end RevisedBenchmark.Literal
