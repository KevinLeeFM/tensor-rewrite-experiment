import TensorRewrite

open TensorRewrite.Pilot
open TensorRewrite.Pilot.LinearIndex
open TensorRewrite.Pilot.Reduction

def unitPlan : Plan := .reduce 1 (.keep 3 (.reduce 1 .scalar))
def noAxesPlan : Plan := .keep 2 (.keep 3 .scalar)
def emptyReducedPlan : Plan := .keep 2 (.reduce 0 (.keep 3 .scalar))
def emptyKeptPlan : Plan := .keep 0 (.reduce 2 .scalar)
def ordinaryPlan : Plan := .reduce 2 (.keep 3 (.reduce 2 .scalar))

def unitInput : Tensor unitPlan.inputShape Bool :=
  fun index => decide ((index ⟨1, by decide⟩).val = 1)
def noAxesInput : Tensor noAxesPlan.inputShape Bool :=
  fun index => decide ((linearize noAxesPlan.inputShape index).val % 2 = 0)
def emptyInput : Tensor emptyReducedPlan.inputShape Bool :=
  fun index => by
    have impossible := index (⟨1, by decide⟩ : Fin 3)
    change Fin 0 at impossible
    exact Fin.elim0 impossible
def emptyKeptInput : Tensor emptyKeptPlan.inputShape Bool :=
  fun index => by
    have impossible := index (⟨0, by decide⟩ : Fin 2)
    change Fin 0 at impossible
    exact Fin.elim0 impossible
def ordinaryInput : Tensor ordinaryPlan.inputShape Bool := fun index =>
  !decide (((index ⟨1, by decide⟩).val = 0 ∧ (index ⟨0, by decide⟩).val = 1 ∧
    (index ⟨2, by decide⟩).val = 1) ∨ ((index ⟨1, by decide⟩).val = 1 ∧
    (index ⟨0, by decide⟩).val = 0 ∧ (index ⟨2, by decide⟩).val = 1))

def values (plan : Plan) (tensor : Tensor plan.outputShape Bool) : List Bool :=
  (List.finRange (elementCount plan.outputShape)).map fun position =>
    tensor (delinearize plan.outputShape position)

def bits (values : List Bool) : String :=
  if values.isEmpty then "empty" else
    String.intercalate "," (values.map fun value => if value then "1" else "0")

def unitReduced : List Bool := values unitPlan (reduceTensor unitPlan Bool.and true unitInput)
def unitReshaped : List Bool := values unitPlan
  (Reshape.reshapeTensor unitInput unitPlan.outputShape (by decide))
def invalidReduced : List Bool := values unitPlan (reduceTensor unitPlan Bool.and false unitInput)
def noAxesValues : List Bool := values noAxesPlan
  (reduceTensor noAxesPlan Bool.and true noAxesInput)
def emptyReducedValues : List Bool := values emptyReducedPlan
  (reduceTensor emptyReducedPlan Bool.and true emptyInput)
def emptyKeptValues : List Bool := values emptyKeptPlan
  (reduceTensor emptyKeptPlan Bool.and true emptyKeptInput)
def ordinaryValues : List Bool := values ordinaryPlan
  (reduceTensor ordinaryPlan Bool.and true ordinaryInput)
def scalarValue : Bool := reduceTensor Plan.scalar Bool.and true (fun _ => false)
  (fun axis => Fin.elim0 axis)

example : unitReduced = [false, true, false] := by decide
example : unitReduced = unitReshaped := by decide
example : reduceTensor unitPlan Bool.and true unitInput =
    Reshape.reshapeTensor unitInput unitPlan.outputShape (by decide) :=
  reduceTensor_sameCount unitPlan Bool.and true (fun value => Bool.true_and value)
    unitInput (by decide)
example : invalidReduced = [false, false, false] ∧ invalidReduced ≠ unitReshaped := by decide
example : ordinaryValues = [false, false, true] := by decide
example : fiberValues ordinaryPlan
    (fun index => (linearize ordinaryPlan.inputShape index).val)
    (delinearize ordinaryPlan.outputShape ⟨1, by decide⟩) = [2, 3, 8, 9] := by decide
example : reduceTensor Plan.scalar Bool.and true (fun _ => false)
    (fun axis => Fin.elim0 axis) = false := by rfl

#eval IO.println ("REDUCTION_MODEL case=unit_axes values=" ++ bits unitReduced)
#eval IO.println ("REDUCTION_MODEL case=no_axes values=" ++ bits noAxesValues)
#eval IO.println ("REDUCTION_MODEL case=empty_reduced values=" ++ bits emptyReducedValues)
#eval IO.println ("REDUCTION_MODEL case=empty_kept values=" ++ bits emptyKeptValues)
#eval IO.println ("REDUCTION_MODEL case=scalar values=" ++ bits [scalarValue])
#eval IO.println ("REDUCTION_MODEL case=nontrivial_axes values=" ++ bits ordinaryValues)
#eval IO.println ("REDUCTION_MODEL case=nonidentity_control before=" ++ bits invalidReduced ++
  " after=" ++ bits unitReshaped)
