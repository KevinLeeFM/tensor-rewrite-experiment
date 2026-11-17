module
public import ScanProof

@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.ConcatCrop
open TensorRewrite.Pilot TensorRewrite.Theory.Concatenation RevisedBenchmark.ConcatScan
variable {r : Nat} {α : Type} {f : Frame r}

/-- Unit-stride legality of every half-open interval. -/
def Fits (f : Frame r) (n : Nat) (start len : Shape r) : Prop :=
  ∀ i, start i + len i ≤ f.shape n i

/-- Read at start plus the result coordinate independently on each axis. -/
def crop {n : Nat} (x : Tensor (f.shape n) α) (start len : Shape r)
    (h : Fits f n start len) : Tensor len α := fun j =>
  x (fun i => ⟨start i + (j i).val, Nat.lt_of_lt_of_le
    (Nat.add_lt_add_left (j i).isLt _) (h i)⟩)

/-- Retain every original start except the one translated into the subrange. -/
def shift (f : Frame r) (start : Shape r) (pre : Nat) : Shape r := fun i =>
  if i = f.axis then start i - pre else start i

/-- Recreate the slice on the ordered concatenation of the selected operands. -/
def Multi : Prop := ∀ {r} {f : Frame r} {α : Type} (bs : List (Block f α))
    (start len : Shape r) (h : Fits f (total bs) start len) (c : Cut (Block f α)),
    scan bs (start f.axis) (start f.axis + len f.axis) = some c →
    ∃ h' : Fits f (total c.selected) (shift f start (total c.leading)) len,
    crop (concatenate bs) start len h =
      crop (concatenate c.selected) (shift f start (total c.leading)) len h'

/-- Recreate the slice on the actual operand when the selection is unary. -/
def Single : Prop := ∀ {r} {f : Frame r} {α : Type} (bs : List (Block f α))
    (start len : Shape r) (h : Fits f (total bs) start len) (c : Cut (Block f α))
    (b : Block f α), scan bs (start f.axis) (start f.axis + len f.axis) = some c →
    c.selected = [b] →
    ∃ h' : Fits f b.extent (shift f start (total c.leading)) len,
    crop (concatenate bs) start len h = crop b.values (shift f start (total c.leading)) len h'
end RevisedBenchmark.ConcatCrop
