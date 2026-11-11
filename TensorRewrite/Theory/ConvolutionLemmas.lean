module

public import TensorRewrite.Theory.Convolution

/-! Geometry and exact algebra for the factored convolution model. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.Convolution

/-- A window position below the padded input contributes no input coordinate. -/
theorem inputIndex?_negative (axis : Axis) (output : Nat) (kernel : Fin axis.kernelExtent)
    (negative : axis.basePosition output kernel < 0) :
    axis.inputIndex? output kernel = none := by
  simp [Axis.inputIndex?, not_le.mpr negative]

/-- Toggling kernel reversal and reversing the bounded kernel index preserve geometry. -/
theorem basePosition_reverse (axis : Axis) (output : Nat) (kernel : Fin axis.kernelExtent) :
    Axis.basePosition { axis with reversed := !axis.reversed } output kernel.rev =
      axis.basePosition output kernel := by
  cases reversed : axis.reversed <;> simp [Axis.basePosition, reversed]

/-- Every returned coordinate occupies precisely its requested base-dilation position. -/
theorem inputIndex?_position (axis : Axis) (output : Nat) (kernel : Fin axis.kernelExtent)
    (index : Fin axis.inputExtent) (sample : axis.inputIndex? output kernel = some index) :
    (index.val : Int) * axis.baseDilation = axis.basePosition output kernel := by
  unfold Axis.inputIndex? at sample
  dsimp only at sample
  split at sample
  next valid =>
    have values := congrArg Fin.val (Option.some.inj sample)
    dsimp only at values
    have nonnegative : 0 ≤ axis.basePosition output kernel / (axis.baseDilation : Int) :=
      Int.ediv_nonneg valid.1 (by have := axis.baseDilation_pos; omega)
    have cast : (index.val : Int) = axis.basePosition output kernel / axis.baseDilation := by
      have castValues : ((axis.basePosition output kernel / axis.baseDilation).toNat : Int) =
          (index.val : Int) := congrArg (fun value : Nat => (value : Int)) values
      rw [Int.toNat_of_nonneg nonnegative] at castValues
      exact castValues.symm
    rw [cast]
    simpa only [valid.2.1, add_zero] using
      Int.ediv_mul_add_emod (axis.basePosition output kernel) (axis.baseDilation : Int)
  next invalid => contradiction

/-- A kernel whose values are all zero produces only zero contributions. -/
theorem term_zero_kernel {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (input : Input plan α) (output : OutputIndex plan)
    (position :
      Fin (plan.inputFeaturesPerGroup * Pilot.LinearIndex.elementCount plan.kernelShape)) :
    term plan input (fun _ _ _ _ _ => 0) output position = 0 := by
  dsimp only [term]
  split <;> simp

/-- A zero-valued input likewise produces only zero contributions. -/
theorem term_zero_input {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (kernel : Kernel plan α) (output : OutputIndex plan)
    (position :
      Fin (plan.inputFeaturesPerGroup * Pilot.LinearIndex.elementCount plan.kernelShape)) :
    term plan (fun _ _ _ => 0) kernel output position = 0 := by
  dsimp only [term]
  split <;> simp

/-- Exact convolution with a zero kernel returns zero even on padded/grouped/empty domains. -/
theorem convolve_zero_kernel {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (input : Input plan α) : convolve plan input (fun _ _ _ _ _ => 0) = fun _ => 0 := by
  funext output
  change (List.map (term plan input (fun _ _ _ _ _ => 0) output) _).sum = 0
  rw [show term plan input (fun _ _ _ _ _ => (0 : α)) output = fun _ => 0 by
    funext position; exact term_zero_kernel plan input output position]
  simp

/-- Exact convolution of a zero input returns zero without a nonempty-window premise. -/
theorem convolve_zero_input {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (kernel : Kernel plan α) : convolve plan (fun _ _ _ => 0) kernel = fun _ => 0 := by
  funext output
  change (List.map (term plan (fun _ _ _ => 0) kernel output) _).sum = 0
  rw [show term plan (fun _ _ _ => (0 : α)) kernel output = fun _ => 0 by
    funext position; exact term_zero_input plan kernel output position]
  simp

/-- No input channels or no kernel coordinates means an empty sum at every output. -/
theorem convolve_empty_fiber {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (input : Input plan α) (kernel : Kernel plan α)
    (empty : plan.inputFeaturesPerGroup * Pilot.LinearIndex.elementCount plan.kernelShape = 0) :
    convolve plan input kernel = fun _ => 0 := by
  funext output
  have noPositions : List.finRange
      (plan.inputFeaturesPerGroup * Pilot.LinearIndex.elementCount plan.kernelShape) = [] :=
    List.eq_nil_of_length_eq_zero (List.length_finRange.trans empty)
  change (List.map (term plan input kernel output) _).sum = 0
  rw [noPositions]
  rfl


/-- An empty spatial input admits no coordinate, regardless of output padding. -/
theorem spatialInput?_empty {rank : Nat} (plan : Plan rank)
    (empty : Pilot.LinearIndex.elementCount plan.inputShape = 0)
    (output : Pilot.Index plan.outputShape) (kernel : Pilot.Index plan.kernelShape) :
    spatialInput? plan output kernel = none := by
  cases sample : spatialInput? plan output kernel with
  | none => rfl
  | some coordinates =>
    have bound := (Pilot.LinearIndex.linearize plan.inputShape coordinates).isLt
    omega

/-- All contributions from an empty spatial input are zero. -/
theorem term_empty_spatial_input {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (input : Input plan α) (kernel : Kernel plan α) (output : OutputIndex plan)
    (position :
      Fin (plan.inputFeaturesPerGroup * Pilot.LinearIndex.elementCount plan.kernelShape))
    (empty : Pilot.LinearIndex.elementCount plan.inputShape = 0) :
    term plan input kernel output position = 0 := by
  dsimp only [term]
  rw [spatialInput?_empty plan empty]

/-- Empty spatial input yields zero even if padding makes the output nonempty. -/
theorem convolve_empty_spatial_input {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (input : Input plan α) (kernel : Kernel plan α)
    (empty : Pilot.LinearIndex.elementCount plan.inputShape = 0) :
    convolve plan input kernel = fun _ => 0 := by
  funext output
  change (List.map (term plan input kernel output) _).sum = 0
  rw [show term plan input kernel output = fun _ => (0 : α) by
    funext position; exact term_empty_spatial_input plan input kernel output position empty]
  simp

/-- An empty spatial kernel is an empty reduction fiber. -/
theorem convolve_empty_kernel {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (input : Input plan α) (kernel : Kernel plan α)
    (empty : Pilot.LinearIndex.elementCount plan.kernelShape = 0) :
    convolve plan input kernel = fun _ => 0 :=
  convolve_empty_fiber plan input kernel (by rw [empty, Nat.mul_zero])

/-- Zero input channels likewise produce an empty reduction fiber. -/
theorem convolve_no_channels {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (input : Input plan α) (kernel : Kernel plan α) (empty : plan.inputFeaturesPerGroup = 0) :
    convolve plan input kernel = fun _ => 0 :=
  convolve_empty_fiber plan input kernel (by rw [empty, Nat.zero_mul])

end TensorRewrite.Theory.Convolution
