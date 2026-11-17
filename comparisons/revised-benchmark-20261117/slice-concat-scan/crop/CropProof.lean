module
public import CropSpec

@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.ConcatCrop
open TensorRewrite.Pilot TensorRewrite.Theory.Concatenation RevisedBenchmark.ConcatScan
variable {r : Nat} {α : Type} {f : Frame r}

/-- Evaluate the existing one-axis identity at an index carrying all cropped
off-axis coordinates. The resulting two reads are the direct multi-axis crops. -/
private theorem liftAxis {m n : Nat} (x : Tensor (f.shape m) α) (y : Tensor (f.shape n) α)
    (s l : Shape r) (p : Nat) (h : Fits f m s l)
    (hx : s f.axis + l f.axis ≤ m) (hy : s f.axis - p + l f.axis ≤ n)
    (law : f.slice x (s f.axis) (l f.axis) hx =
      f.slice y (s f.axis - p) (l f.axis) hy) :
    ∃ h' : Fits f n (shift f s p) l, crop x s l h = crop y (shift f s p) l h' := by
  have fit : Fits f n (shift f s p) l := by
    intro i
    by_cases eq : i = f.axis
    · simpa [eq, shift, Frame.shape] using hy
    · simpa [shift, Frame.shape, eq] using h i
  refine ⟨fit, ?_⟩
  funext j
  let k : Index (f.shape (l f.axis)) := fun i =>
    if eq : i = f.axis then ⟨(j i).val, by simpa [eq, Frame.shape] using (j i).isLt⟩
    else ⟨s i + (j i).val, by
      have H := Nat.lt_of_lt_of_le (Nat.add_lt_add_left (j i).isLt (s i)) (h i)
      simpa [Frame.shape, eq] using H⟩
  have bridge := congrFun law k
  refine Eq.trans ?_ (Eq.trans bridge ?_)
  · apply congrArg x
    funext i
    apply Fin.ext
    by_cases eq : i = f.axis
    · subst i; simp [Frame.withPosition, Frame.position, k]
    · simp [Frame.withPosition, k, eq]
  · apply congrArg y
    funext i
    apply Fin.ext
    by_cases eq : i = f.axis
    · subst i; simp [Frame.withPosition, Frame.position, k, shift]
    · simp [Frame.withPosition, k, shift, eq]

/-- Normalize a length under the dependent slice bound and result shape together. -/
private theorem normalize {m n a b d e : Nat} (x : Tensor (f.shape m) α)
    (y : Tensor (f.shape n) α) (eq : d = e) (hx : a + d ≤ m)
    (result : ∃ hy : b + d ≤ n, f.slice x a d hx = f.slice y b d hy) :
    ∃ hy : b + e ≤ n, f.slice x a e (by omega) = f.slice y b e hy := by
  cases eq
  exact result

/-- A selected subrange supports exactly the original multidimensional crop. -/
theorem multi : Multi := by
  intro r f α bs s l h c found
  have hx : s f.axis + l f.axis ≤ total bs := by simpa [Frame.shape] using h f.axis
  have result := subrange bs _ _ (Nat.le_add_right _ _) hx c found
  obtain ⟨hy, law⟩ := normalize _ _ (Nat.add_sub_cancel_left (s f.axis) (l f.axis)) _ result
  exact liftAxis _ _ s l _ h hx hy law

/-- A singleton selection uses the actual operand, including all off-axis starts. -/
theorem single : Single := by
  intro r f α bs s l h c b found one
  have hx : s f.axis + l f.axis ≤ total bs := by simpa [Frame.shape] using h f.axis
  have result := unary bs _ _ (Nat.le_add_right _ _) hx c b found one
  obtain ⟨hy, law⟩ := normalize _ _ (Nat.add_sub_cancel_left (s f.axis) (l f.axis)) _ result
  exact liftAxis _ _ s l _ h hx hy law

private def grid : Frame 2 := ⟨fun _ => 4, 0⟩
private def block (width base : Nat) : Block grid Nat :=
  ⟨width, fun i => base + 10 * (i 0).val + (i 1).val⟩
private def blocks := [block 1 10, block 3 20, block 2 30]
private def start : Shape 2 := fun _ => 2
private def unitShape : Shape 2 := fun _ => 1
private def point : Index unitShape := fun _ => ⟨0, Nat.zero_lt_one⟩

-- Both axes crop. Global (2,2) selects the middle operand at (1,2).
example : (scan blocks 2 3).map (fun c => c.selected.map Block.extent) = some [3] := by decide
example : crop (concatenate blocks) start unitShape (by unfold Fits; decide) point = 32 := by decide
example : crop (block 3 20).values (shift grid start 1) unitShape (by unfold Fits; decide) point = 32 := by decide
-- A well-typed, incorrect reset of the off-axis start reads value 30.
example : crop (concatenate blocks) start unitShape (by unfold Fits; decide) point ≠
    crop (block 3 20).values (fun i => if i = 0 then 1 else 0) unitShape (by unfold Fits; decide) point := by
  decide

-- A proper two-block selection with an off-axis crop includes both operands.
private def multiStart : Shape 2 := fun i => if i = 0 then 0 else 2
private def multiLen : Shape 2 := fun i => if i = 0 then 2 else 1
private def lastPoint : Index multiLen := fun i =>
  if h : i = 0 then ⟨1, by simp [multiLen,h]⟩ else ⟨0, by simp [multiLen,h]⟩
example : (scan blocks 0 2).map (fun c => c.selected.map Block.extent) = some [1,3] := by decide
example : crop (concatenate blocks) multiStart multiLen (by unfold Fits; decide) lastPoint =
    crop (concatenate [block 1 10, block 3 20]) multiStart multiLen (by unfold Fits; decide) lastPoint := by decide

#print axioms multi
#print axioms single
end RevisedBenchmark.ConcatCrop
