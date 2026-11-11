import TensorRewrite.Theory.ReductionWindowCounterexamples

set_option autoImplicit false

open TensorRewrite.Pilot
open TensorRewrite.Theory.ReductionWindow

private def axis (n k : Nat) (s b d : Nat := 1) (lo hi : Int := 0)
    (rev : Bool := false) : TensorRewrite.Theory.Convolution.Axis := {
  inputExtent := n
  kernelExtent := k
  stride := s + 1
  baseDilation := b + 1
  kernelDilation := d + 1
  paddingLow := lo
  paddingHigh := hi
  reversed := rev
  stride_pos := by omega
  baseDilation_pos := by omega
  kernelDilation_pos := by omega
}

private def plan (axes : List TensorRewrite.Theory.Convolution.Axis) : Plan axes.length :=
  ⟨fun index => axes[index]⟩

private def profile {rank : Nat} (name : String) (p : Plan rank) : IO Unit := do
  let count := LinearIndex.elementCount p.outputShape
  let window := LinearIndex.elementCount p.kernelShape
  let eligible := (List.finRange rank).all fun i =>
    (p.window i).kernelExtent == 1 && (p.window i).baseDilation == 1
  IO.println s!"WINDOW_COUNT name={name} outputs={count} window={window} affine={eligible}"
  let input : Tensor p.inputShape Int := fun i => (LinearIndex.linearize p.inputShape i).val + 1
  for position in List.finRange count do
    let output := LinearIndex.delinearize p.outputShape position
    let trace := values p 0 input output
    let sum := reduce p (· + ·) 7 3 input output
    let zero := reduce p (· + ·) 0 0 input output
    let decimal := reduce p (fun a b => 10*a+b) 0 0 input output
    let minimum := reduce p min 5 5 input output
    let maximum := reduce p max 5 5 input output
    let gather := gatherMap p 0 id input output
    let row := s!"WINDOW name={name} output={position.val} trace={trace} sum={sum} " ++
      s!"zero={zero} decimal={decimal} min={minimum} max={maximum} gather={gather}"
    IO.println row

#eval do
  profile "scalar" (plan [])
  profile "pointwise" (plan [axis 3 1 0 0 6 0 0 true])
  profile "unit_padding" (plan [axis 2 1 0 0 0 1 2])
  profile "unit_crop" (plan [axis 4 1 0 0 0 (-1) (-1)])
  profile "unit_stride" (plan [axis 5 1 1 0 0 1])
  profile "base_holes" (plan [axis 3 1 0 1 0])
  profile "kernel_dilation" (plan [axis 6 3 0 0 1 1 1])
  profile "kernel_reversal" (plan [axis 3 3 0 0 0 0 0 true])
  profile "empty_input" (plan [axis 0 2 0 0 0 2 2])
  profile "empty_kernel" (plan [axis 2 0 0 0 0])
  profile "empty_output" (plan [axis 2 5 0 0 0])
  profile "mixed_unit" (plan [axis 2 1 0 0 0 1,axis 3 1 0 0 0 (-1)])
  profile "crop_all_low" (plan [axis 2 1 0 0 0 (-2) 3])
  profile "crop_all_high" (plan [axis 2 1 0 0 0 3 (-2)])
  profile "mixed_kernel" (plan [axis 2 2 0 0 0,axis 3 2 0 0 0 1])
