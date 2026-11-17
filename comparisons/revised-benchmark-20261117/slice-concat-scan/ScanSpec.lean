module
public import TensorRewrite.Theory.ConcatenationSlice
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.ConcatScan
open TensorRewrite.Pilot TensorRewrite.Theory.Concatenation
variable {r : Nat} {f : Frame r} {α : Type}
abbrev B := Block f α
/-- Once a start is located, stop at the first accumulated end at or beyond the limit. -/
def finish : List (B (f:=f) (α:=α)) → Nat → Option (List (Block f α) × List (Block f α))
  | [], _ => none
  | b :: bs, hi => if hi ≤ b.extent then some ([b],bs) else
    (finish bs (hi-b.extent)).map fun (picked,tail) => (b::picked,tail)

structure Cut (β : Type) where
  leading : List β
  selected : List β
  trailing : List β

/-- Scan in original operand order. Ending before finding a strict start yields no match. -/
def scan : List (Block f α) → Nat → Nat → Option (Cut (Block f α))
  | [],_,_ => none
  | b::bs,lo,hi =>
    if lo < b.extent then (finish (b::bs) hi).map fun (p,t) => ⟨[],p,t⟩
    else if hi ≤ b.extent then none
    else (scan bs (lo-b.extent) (hi-b.extent)).map fun c => {c with leading := b::c.leading}

def Subrange : Prop := ∀ {r : Nat} {f : Frame r} {α : Type} (bs : List (Block f α))
    (lo hi : Nat) (ordered : lo ≤ hi) (bound : hi ≤ total bs) (c : Cut (Block f α)),
    scan bs lo hi = some c →
    ∃ h : lo - total c.leading + (hi-lo) ≤ total c.selected,
    f.slice (concatenate bs) lo (hi-lo) (by omega) =
      f.slice (concatenate c.selected) (lo - total c.leading) (hi-lo) h

def Exact : Prop := ∀ {r : Nat} {f : Frame r} {α : Type} (bs : List (Block f α))
    (lo hi : Nat) (ordered : lo ≤ hi) (bound : hi ≤ total bs)
    (c : Cut (Block f α)) (b : Block f α), scan bs lo hi = some c →
    c.selected = [b] → (size : hi-lo = b.extent) →
    f.slice (concatenate bs) lo b.extent (by omega) = b.values
end RevisedBenchmark.ConcatScan
