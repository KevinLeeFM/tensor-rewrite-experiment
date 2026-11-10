import TensorRewrite

open TensorRewrite.Pilot
open TensorRewrite.Pilot.IndexMaps

-- Dropping the stride multiplier changes the second selected input coordinate.
example : (sliceIndex
    (fun _ : Fin 1 => { start := 1, limit := 6, stride := 2 })
    (inputShape := fun _ => 6) (outputShape := fun _ => 3)
    (by decide) (fun _ => 1) 0).val = 2 := by
  rfl
