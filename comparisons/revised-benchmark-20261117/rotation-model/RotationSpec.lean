module
public import TensorRewrite.Pilot.Tensor

@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.Rotation
open TensorRewrite.Pilot

/-- Each entry pairs its validated axis with a signed mathematical shift.
A chain lists the instructions' entries from the outer shuffle toward the base. -/
abbrev Entry (r : Nat) := Fin r × Int

/-- Pull a left rotation back to its source coordinate. The coordinate supplies positivity. -/
def cyclic {n : Nat} (x : Fin n) (k : Int) : Fin n :=
  let v := ((x.val : Int) + k) % (n : Int)
  ⟨v.toNat, by
    have hx := x.isLt
    have hp : 0 < (n : Int) := by omega
    have := Int.emod_lt_of_pos ((x.val : Int) + k) hp
    have := Int.emod_nonneg ((x.val : Int) + k) (Int.ne_of_gt hp)
    dsimp [v]; omega⟩

/-- Original semantics processes each entry in sequence, without accumulating shifts. -/
def walk {r : Nat} {s : Shape r} (entries : List (Entry r)) (i : Index s) : Index s :=
  match entries with
  | [] => i
  | (a,k) :: tail => walk tail (fun d => if d = a then cyclic (i d) k else i d)

/-- Per-axis aggregate computed from the original entries. -/
def total {r : Nat} (axis : Fin r) : List (Entry r) → Int
  | [] => 0
  | (a,k) :: tail => (if axis = a then k else 0) + total axis tail

/-- Enumerate axes in ascending order and retain precisely their observable, nonzero rotations. -/
def canonicalEntry {r : Nat} (s : Shape r) (visible : Fin r → Bool)
    (xs : List (Entry r)) (d : Fin r) : Option (Entry r) :=
  let residue := total d xs % (s d : Int)
  if visible d && 1 < s d && residue != 0 then some (d, residue) else none

def canonical {r : Nat} (s : Shape r) (visible : Fin r → Bool)
    (xs : List (Entry r)) : List (Entry r) :=
  (List.finRange r).filterMap (canonicalEntry s visible xs)

/-- The base can depend arbitrarily on exactly the retained set of visible coordinates.
All-visible admits every tensor; constant and broadcast axes can be omitted structurally. -/
abbrev Projected {r : Nat} (s : Shape r) (visible : Fin r → Bool) :=
  (d : {a : Fin r // visible a = true}) → Fin (s d.val)

def observe {r : Nat} {s : Shape r} {v : Fin r → Bool} {α : Type}
    (base : Projected s v → α) (entries : List (Entry r)) : Tensor s α :=
  fun i => base (fun d => walk entries i d.val)

/-- Both dispatches: empty canonical list returns the base; otherwise build a single
rotation from the canonical attribute list, directly evaluated by the same rotation semantics. -/
def replacement {r : Nat} {s : Shape r} {v : Fin r → Bool} {α : Type}
    (base : Projected s v → α) (xs : List (Entry r)) : Tensor s α :=
  match canonical s v xs with
  | [] => fun i => base (fun d => i d.val)
  | hd :: tl => observe base (hd :: tl)

def Goal : Prop := ∀ {r : Nat} (s : Shape r) (visible : Fin r → Bool)
    (α : Type) (base : Projected s visible → α) (xs : List (Entry r)),
    observe base xs = replacement base xs

end RevisedBenchmark.Rotation
