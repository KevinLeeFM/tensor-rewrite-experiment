module
public import TensorRewrite.Pilot.Reshape
public import TensorRewrite.Pilot.Permutation
public import TensorRewrite.Pilot.IndexMaps
public import TensorRewrite.Pilot.DynamicSliceTensor
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.ScalarUsers
open TensorRewrite.Pilot Tensor
/-- Non-tuple sort is observed along an arbitrary single uniform fiber, including the empty fiber. -/
def SortFiber : Prop := ∀ (α : Type) (n : Nat) (v : α) (le : α → α → Bool),
  (List.replicate n v).mergeSort le = List.replicate n v

def Reshaped : Prop := ∀ {r q : Nat} (s : Shape r) (t : Shape q)
    (h : LinearIndex.elementCount s = LinearIndex.elementCount t) (α : Type) (v : α),
  Reshape.reshapeTensor (constant v) t h = constant v

def Transposed : Prop := ∀ {r : Nat} (s t : Shape r) (p : AxisPermutation r)
    (h : ∀ k, t (p.inputToOutput k) = s k) (α : Type) (v : α),
  transpose p h (constant v) = constant v

def Reversed : Prop := ∀ {r : Nat} (s : Shape r) (a : List (Fin r)) (α : Type) (v : α),
  reverse (axisMask a) (constant v : Tensor s α) = constant v

def Sliced : Prop := ∀ {r : Nat} (s t : Shape r) (a : Fin r → SliceShape.Axis)
    (h : ∀ k, SliceShape.IsWellFormed (s k) (t k) (a k)) (α : Type) (v : α),
  reindex (IndexMaps.sliceIndex a h) (constant v : Tensor s α) = constant v

def DynamicSliced : Prop := ∀ {r : Nat} (s t : Shape r) (a : Fin r → Int)
    (h : ∀ k, t k ≤ s k) (α : Type) (v : α),
  DynamicIndex.sliceTensor (constant v : Tensor s α) a h = constant v
end RevisedBenchmark.ScalarUsers
