import CopySpec
set_option autoImplicit false
namespace RevisedBenchmark.SwapCopyBitcast
open CopyChain
abbrev Cell (n : Nat) := Fin n × Fin n
def sw {n : Nat} (flip : Bool) (p : Cell n) := if flip then p.swap else p
private theorem swTwice {n : Nat} (f : Bool) (p : Cell n) : sw f (sw f p) = p := by
  cases f <;> cases p <;> rfl

/-- Major/minor physical digits packed at actual contiguous offsets. -/
def row {n : Nat} (hn : 0<n) : Layout (Cell n) (n*n) where
  address p := ⟨n*p.1.val + p.2.val, by
    have h := Nat.mul_le_mul_left n p.1.isLt
    rw [Nat.mul_succ] at h
    have := p.2.isLt
    omega⟩
  coordinate i := (⟨i.val/n,(Nat.div_lt_iff_lt_mul hn).2 i.isLt⟩,⟨i.val%n,Nat.mod_lt _ hn⟩)
  decode_encode p := by
    apply Prod.ext <;> apply Fin.ext
    · simp [Nat.mul_add_div hn, Nat.div_eq_of_lt p.2.isLt]
    · simp [Nat.mod_eq_of_lt p.2.isLt]
  encode_decode a := Fin.ext (Nat.div_add_mod _ _)

-- false gives axis 1 minor; true gives axis 0 minor.
def view {n : Nat} (hn : 0<n) (flip : Bool) : Layout (Cell n) (n*n) where
  address p := (row hn).address (sw flip p)
  coordinate i := sw flip ((row hn).coordinate i)
  decode_encode p := by simp only [(row hn).decode_encode,swTwice]
  encode_decode i := by simp only [swTwice,(row hn).encode_decode]

structure OrderTile where
  order : Bool
  two : Bool
deriving DecidableEq, Repr

def tile (t : Bool) : Nat := if t then 2 else 1
/-- With a complete minor-axis tile, blocks are contiguous and have the usual digit address. -/
def tiledOffset (n maj min : Nat) (t : Bool) :=
  (maj*(n/tile t) + min/tile t)*tile t + min%tile t

/-- In the equal nonunit square, each old axis matches the result axis at the
same physical slot. Walk the new operand's minor axis through that map. -/
def remap (fromOrder toOrder which : Bool) := if which = fromOrder then toOrder else !toOrder

/-- Only one tile dimension; matched axis extents and one-to-one dimension map
make the validation test equality of the tile widths. -/
def valid (a b : OrderTile) := a.two == b.two
def old {n : Nat} {α : Type} (hn : 0<n) (s c b d : OrderTile) (x : Fin (n*n) → α) :=
  copy (view hn b.order) (view hn d.order) (copy (view hn s.order) (view hn c.order) x)
def emitted {n : Nat} {α : Type} (hn : 0<n) (s c b d : OrderTile) (x : Fin (n*n) → α) :=
  if valid b s then
    some (copy (view hn (remap c.order b.order s.order)) (view hn d.order) x)
  else if valid c d then
    some (copy (view hn s.order) (view hn (remap b.order c.order d.order)) x)
  else none

def Goal := ∀ k : Nat, let n := 2*(k+1)
  (∀ (p : Cell n) (t : Bool), tiledOffset n p.1.val p.2.val t = n*p.1.val + p.2.val) ∧
  ∀ (α : Type) (s c b d : OrderTile), valid b c = true →
  (valid b s = true ∨ valid c d = true) →
  ∀ x : Fin (n*n) → α, let hn : 0 < n := by dsimp [n]; omega
  emitted hn s c b d x = some (old hn s c b d x)
end RevisedBenchmark.SwapCopyBitcast
