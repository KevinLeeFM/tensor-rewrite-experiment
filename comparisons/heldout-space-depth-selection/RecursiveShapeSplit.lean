module
public import TensorRewrite.Pilot.LinearIndex
/-! Generic prefix/tail shape construction and packed coordinate decomposition. -/
@[expose] public section
set_option autoImplicit false
namespace Heldout.RecursiveShapeSplit
open TensorRewrite.Pilot TensorRewrite.Pilot.LinearIndex TensorRewrite.Pilot.FiniteProduct

/-- Concatenate a shape prefix and tail, with rank expressed as `tailRank + prefixRank`. -/
def appendShape : {m n : Nat} → Shape m → Shape n → Shape (n + m)
  | 0, _, _, tail => tail
  | _ + 1, _, pre, tail => Fin.cases (pre 0) (appendShape (fun i => pre i.succ) tail)

/-- Concatenate the corresponding bounded coordinates. -/
def appendIndex : {m n : Nat} → {pre : Shape m} → {tail : Shape n} →
    Index pre → Index tail → Index (appendShape pre tail)
  | 0, _, _, _, _, tail => tail
  | _ + 1, _, _, _, pre, tail => Fin.cases (pre 0) (appendIndex (fun i => pre i.succ) tail)

/-- Concatenated shapes have the product count, including zero extents. -/
theorem append_count {m n : Nat} (pre : Shape m) (tail : Shape n) :
    elementCount (appendShape pre tail) = elementCount pre * elementCount tail := by
  induction m with
  | zero => simp [appendShape, elementCount]
  | succ m ih =>
    simp only [appendShape, elementCount, Fin.cases_zero, Fin.cases_succ]
    change pre 0 * elementCount (appendShape (fun i => pre i.succ) tail) =
      (pre 0 * elementCount (fun i => pre i.succ)) * elementCount tail
    rw [ih]
    exact (Nat.mul_assoc _ _ _).symm

/-- Packing a concatenated index is packing its prefix and tail together. -/
theorem append_linearize {m n : Nat} (pre : Shape m) (tail : Shape n)
    (pi : Index pre) (ti : Index tail) :
    Fin.cast (append_count pre tail) (linearize (appendShape pre tail) (appendIndex pi ti)) =
      join (linearize pre pi) (linearize tail ti) := by
  induction m with
  | zero =>
    apply Fin.ext
    simp only [appendShape, appendIndex, linearize, join]
    simp only [Nat.zero_mul, Nat.zero_add]
    exact Fin.val_cast _ _
  | succ m ih =>
    apply Fin.ext
    change (pi 0).val * elementCount (appendShape (fun i => pre i.succ) tail) +
      (linearize (appendShape (fun i => pre i.succ) tail)
        (appendIndex (fun i => pi i.succ) ti)).val =
      ((pi 0).val * elementCount (fun i => pre i.succ) +
        (linearize (fun i => pre i.succ) (fun i => pi i.succ)).val) * elementCount tail +
          (linearize tail ti).val
    have h := congrArg Fin.val (ih (fun i => pre i.succ) (fun i => pi i.succ))
    simp only [Fin.val_cast, join] at h
    rw [h, append_count]
    simp only [Nat.add_mul, Nat.mul_assoc, Nat.add_assoc]

/-- Take a prefix from any full shape, recursively in its prefix rank. -/
def preShape : {m n : Nat} → Shape (n + m) → Shape m
  | 0, _, _ => fun i => Fin.elim0 i
  | _ + 1, _, shape => Fin.cases (shape 0) (preShape (fun i => shape i.succ))

/-- Take the remaining tail from any full shape. -/
def tailShape : {m n : Nat} → Shape (n + m) → Shape n
  | 0, _, shape => shape
  | _ + 1, _, shape => tailShape (fun i => shape i.succ)

/-- The derived prefix and tail reconstruct every full shape. -/
theorem shape_reconstruct {m n : Nat} (shape : Shape (n + m)) :
    appendShape (preShape (m := m) (n := n) shape) (tailShape (m := m) (n := n) shape) = shape := by
  induction m with
  | zero => rfl
  | succ m ih =>
    funext i
    refine Fin.cases ?_ (fun i => ?_) i
    · rfl
    · exact congrFun (ih (fun i => shape i.succ)) i

/-- Derive prefix coordinates from a full index. -/
def preIndex : {m n : Nat} → {shape : Shape (n + m)} →
    (index : Index shape) → Index (preShape (m := m) (n := n) shape)
  | 0, _, _, _ => fun i => Fin.elim0 i
  | m + 1, n, _, index => Fin.cases (index 0) (preIndex (m := m) (n := n) (fun i => index i.succ))

/-- Derive tail coordinates from a full index. -/
def tailIndex : {m n : Nat} → {shape : Shape (n + m)} →
    (index : Index shape) → Index (tailShape (m := m) (n := n) shape)
  | 0, _, _, index => index
  | m + 1, n, _, index => tailIndex (m := m) (n := n) (fun i => index i.succ)

/-- Coordinate reconstruction preserves natural values through shape equality. -/
theorem index_reconstruct_value {m n : Nat} {shape : Shape (n + m)} (index : Index shape)
    (i : Fin (n + m)) :
    (appendIndex (preIndex (m := m) (n := n) index) (tailIndex (m := m) (n := n) index) i).val =
      (index i).val := by
  induction m with
  | zero => rfl
  | succ m ih =>
    refine Fin.cases ?_ (fun i => ?_) i
    · rfl
    · exact ih (fun i => index i.succ) i

/-- Split the element count of any full shape at any prefix rank. -/
theorem full_count_split {m n : Nat} (shape : Shape (n + m)) :
    elementCount shape = elementCount (preShape (m := m) (n := n) shape) *
      elementCount (tailShape (m := m) (n := n) shape) := by
  calc
    elementCount shape = elementCount (appendShape (preShape (m := m) (n := n) shape)
        (tailShape (m := m) (n := n) shape)) :=
      congrArg elementCount (shape_reconstruct (m := m) (n := n) shape).symm
    _ = _ := append_count _ _

/-- Transporting a coordinate over shape equality preserves its packed position. -/
theorem linearize_transport {rank : Nat} {left right : Shape rank} (same : left = right)
    (index : Index left) :
    linearize right (fun i => Fin.cast (congrFun same i) (index i)) =
      Fin.cast (congrArg elementCount same) (linearize left index) := by
  cases same
  rfl

/-- Any actual full index decomposes into the packed derived prefix and tail. -/
theorem full_linearize_split {m n : Nat} {shape : Shape (n + m)} (index : Index shape) :
    (linearize shape index).val =
      (join (linearize (preShape (m := m) (n := n) shape) (preIndex (m := m) (n := n) index))
        (linearize (tailShape (m := m) (n := n) shape) (tailIndex (m := m) (n := n) index))).val := by
  let pi := preIndex (m := m) (n := n) index
  let ti := tailIndex (m := m) (n := n) index
  have equalIndex : (fun i => Fin.cast (congrFun (shape_reconstruct (m := m) (n := n) shape) i)
      (appendIndex pi ti i)) = index := by
    funext i
    apply Fin.ext
    exact index_reconstruct_value index i
  have transport := congrArg Fin.val (linearize_transport (shape_reconstruct (m := m) (n := n) shape)
    (appendIndex pi ti))
  simp only [Fin.val_cast] at transport
  rw [equalIndex] at transport
  have packed := congrArg Fin.val (append_linearize (preShape (m := m) (n := n) shape)
    (tailShape (m := m) (n := n) shape) pi ti)
  simp only [Fin.val_cast] at packed
  exact transport.trans packed

#print axioms full_count_split
#print axioms linearize_transport
#print axioms full_linearize_split
#print axioms index_reconstruct_value
#print axioms shape_reconstruct
#print axioms append_count
#print axioms append_linearize
end Heldout.RecursiveShapeSplit
