module

public import TensorRewrite.Theory.ControlValues

/-! General pure-value laws and exact branch-dispatch equivalence. Empty shapes and rank-zero
scalars are included by the coordinate quantifiers; data need no equality or algebra instance.
-/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.ControlValues

open Pilot

/-- Equal branch tensors permit elimination of the predicate in the pure-value model. -/
theorem select_equal {rank : Nat} {shape : Shape rank} {α : Type}
    (predicate : Tensor shape Bool) (input : Tensor shape α) :
    select predicate input input = input := by
  funext index
  simp [select]

/-- A uniformly true predicate selects the entire true tensor. -/
theorem select_true {rank : Nat} {shape : Shape rank} {α : Type}
    (onTrue onFalse : Tensor shape α) : select (Tensor.constant true) onTrue onFalse = onTrue := rfl

/-- A uniformly false predicate selects the entire false tensor. -/
theorem select_false {rank : Nat} {shape : Shape rank} {α : Type}
    (onTrue onFalse : Tensor shape α) :
    select (Tensor.constant false) onTrue onFalse = onFalse := rfl

/-- Negating the predicate exchanges the value branches. -/
theorem select_not {rank : Nat} {shape : Shape rank} {α : Type}
    (predicate : Tensor shape Bool) (onTrue onFalse : Tensor shape α) :
    select (Tensor.map Bool.not predicate) onTrue onFalse = select predicate onFalse onTrue := by
  funext index
  cases h : predicate index <;> simp [select, Tensor.map, h]

/-- Boolean true/false branches recover the full predicate tensor. -/
theorem select_true_false {rank : Nat} {shape : Shape rank} (predicate : Tensor shape Bool) :
    select predicate (Tensor.constant true) (Tensor.constant false) = predicate := by
  funext index
  cases h : predicate index <;> simp [select, Tensor.constant, h]

/-- Boolean false/true branches recover the pointwise negated predicate. -/
theorem select_false_true {rank : Nat} {shape : Shape rank} (predicate : Tensor shape Bool) :
    select predicate (Tensor.constant false) (Tensor.constant true) =
      Tensor.map Bool.not predicate := by
  funext index
  cases h : predicate index <;> simp [select, Tensor.constant, Tensor.map, h]

/-- Select distributes over the actual Broadcast coordinate projection for arbitrary data. -/
theorem broadcast_select {inputRank outputRank : Nat} {inputShape : Shape inputRank}
    {outputShape : Shape outputRank} {α : Type}
    (axes : IndexMaps.BroadcastAxes inputRank outputRank)
    (extents : ∀ axis, inputShape axis = outputShape (axes.decode axis))
    (predicate : Tensor inputShape Bool) (onTrue onFalse : Tensor inputShape α) :
    broadcast axes extents (select predicate onTrue onFalse) =
      select (broadcast axes extents predicate) (broadcast axes extents onTrue)
        (broadcast axes extents onFalse) := rfl

/-- Broadcasting a uniform tensor preserves its exact data value, including exceptional bits. -/
theorem broadcast_constant {inputRank outputRank : Nat} {inputShape : Shape inputRank}
    {outputShape : Shape outputRank} {α : Type}
    (axes : IndexMaps.BroadcastAxes inputRank outputRank)
    (extents : ∀ axis, inputShape axis = outputShape (axes.decode axis)) (value : α) :
    broadcast axes extents (Tensor.constant value) = Tensor.constant value := rfl

/-- A broadcast predicate with true/false branches retains its actual dimension map. -/
theorem select_true_false_broadcast {inputRank outputRank : Nat} {inputShape : Shape inputRank}
    {outputShape : Shape outputRank} (axes : IndexMaps.BroadcastAxes inputRank outputRank)
    (extents : ∀ axis, inputShape axis = outputShape (axes.decode axis))
    (predicate : Tensor inputShape Bool) :
    select (broadcast axes extents predicate) (Tensor.constant true) (Tensor.constant false) =
      broadcast axes extents predicate := select_true_false _

/-- Negation commutes with the actual Broadcast map in the false/true case. -/
theorem select_false_true_broadcast {inputRank outputRank : Nat} {inputShape : Shape inputRank}
    {outputShape : Shape outputRank} (axes : IndexMaps.BroadcastAxes inputRank outputRank)
    (extents : ∀ axis, inputShape axis = outputShape (axes.decode axis))
    (predicate : Tensor inputShape Bool) :
    select (broadcast axes extents predicate) (Tensor.constant false) (Tensor.constant true) =
      broadcast axes extents (Tensor.map Bool.not predicate) := select_false_true _

/-- Boolean less-than selection is conjunction under false=0, true=1. -/
theorem select_compare_lt {rank : Nat} {shape : Shape rank} (left right : Tensor shape Bool) :
    select (Tensor.map₂ (compare .lt) left right) left right = Tensor.map₂ Bool.and left right := by
  funext index
  cases leftValue : left index <;> cases rightValue : right index <;>
    simp [select, Tensor.map₂, compare, leftValue, rightValue]

/-- Boolean less-or-equal selection has the same conjunction value, including ties. -/
theorem select_compare_le {rank : Nat} {shape : Shape rank} (left right : Tensor shape Bool) :
    select (Tensor.map₂ (compare .le) left right) left right = Tensor.map₂ Bool.and left right := by
  funext index
  cases leftValue : left index <;> cases rightValue : right index <;>
    simp [select, Tensor.map₂, compare, leftValue, rightValue]

/-- Boolean greater-than selection is disjunction under false=0, true=1. -/
theorem select_compare_gt {rank : Nat} {shape : Shape rank} (left right : Tensor shape Bool) :
    select (Tensor.map₂ (compare .gt) left right) left right = Tensor.map₂ Bool.or left right := by
  funext index
  cases leftValue : left index <;> cases rightValue : right index <;>
    simp [select, Tensor.map₂, compare, leftValue, rightValue]

/-- Boolean greater-or-equal selection has the same disjunction value, including ties. -/
theorem select_compare_ge {rank : Nat} {shape : Shape rank} (left right : Tensor shape Bool) :
    select (Tensor.map₂ (compare .ge) left right) left right = Tensor.map₂ Bool.or left right := by
  funext index
  cases leftValue : left index <;> cases rightValue : right index <;>
    simp [select, Tensor.map₂, compare, leftValue, rightValue]

/-- Select on Boolean equality returns the right operand even when the operands differ. -/
theorem select_compare_eq {rank : Nat} {shape : Shape rank} (left right : Tensor shape Bool) :
    select (Tensor.map₂ (compare .eq) left right) left right = right := by
  funext index
  cases leftValue : left index <;> cases rightValue : right index <;>
    simp [select, Tensor.map₂, compare, leftValue, rightValue]

/-- Select on Boolean inequality returns the left operand even when the operands agree. -/
theorem select_compare_ne {rank : Nat} {shape : Shape rank} (left right : Tensor shape Bool) :
    select (Tensor.map₂ (compare .ne) left right) left right = left := by
  funext index
  cases leftValue : left index <;> cases rightValue : right index <;>
    simp [select, Tensor.map₂, compare, leftValue, rightValue]

/-- A parameter-root Map returns the selected operand, with heterogeneous types and legal index. -/
theorem map_parameter {arity rank : Nat} {shape : Shape rank} {inputTypes : Fin arity → Type}
    (parameter : Fin arity) (inputs : (argument : Fin arity) → Tensor shape (inputTypes argument)) :
    mapTensor (fun values => values parameter) inputs = inputs parameter := rfl

/-- A constant-root Map returns the output-shaped uniform value, including nullary maps. -/
theorem map_constant {arity rank : Nat} {shape : Shape rank} {β : Type}
    {inputTypes : Fin arity → Type} (value : β)
    (inputs : (argument : Fin arity) → Tensor shape (inputTypes argument)) :
    mapTensor (fun _ => value) inputs = Tensor.constant value := rfl

/-- At rank zero the constant root is exactly the scalar constant, rather than a resized array. -/
theorem map_scalar_constant {arity : Nat} {β : Type} {inputTypes : Fin arity → Type}
    (value : β)
    (inputs : (argument : Fin arity) → Tensor (Fin.elim0 : Shape 0) (inputTypes argument)) :
    mapTensor (fun _ => value) inputs = Tensor.constant value := rfl

/-- The nonscalar constant-root replacement is the actual rank-zero Broadcast graph. -/
theorem map_constant_broadcast {arity rank : Nat} {shape : Shape rank} {β : Type}
    {inputTypes : Fin arity → Type} (value : β)
    (inputs : (argument : Fin arity) → Tensor shape (inputTypes argument)) :
    mapTensor (fun _ => value) inputs =
      broadcast (scalarAxes rank) (fun axis => Fin.elim0 axis)
        (Tensor.constant (shape := (Fin.elim0 : Shape 0)) value) := rfl

/-- Clone a scalar elementwise root with its actual ordered, possibly repeated operand selection. -/
theorem map_elementwise {arity selected rank : Nat} {shape : Shape rank} {β : Type}
    {inputTypes : Fin arity → Type} (parameters : Fin selected → Fin arity)
    (operation : ((argument : Fin selected) → inputTypes (parameters argument)) → β)
    (inputs : (argument : Fin arity) → Tensor shape (inputTypes argument)) :
    mapTensor (fun values => operation (fun argument => values (parameters argument))) inputs =
      elementwise operation (fun argument => inputs (parameters argument)) := rfl

/-- Boolean-to-index conversion preserves the selected branch, its own argument and all results. -/
theorem conditional_convert {argumentTypes : Fin 2 → Type} {β : Type} (predicate : Bool)
    (arguments : (branch : Fin 2) → argumentTypes branch)
    (branches : (branch : Fin 2) → argumentTypes branch → β) :
    indexedConditional (booleanIndex predicate) arguments branches =
      predicateConditional predicate (arguments 1) (branches 1) (arguments 0) (branches 0) := by
  cases predicate <;> rfl

end TensorRewrite.Theory.ControlValues
