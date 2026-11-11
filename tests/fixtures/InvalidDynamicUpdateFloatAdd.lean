import TensorRewrite.Theory.DynamicUpdateCounterexamples

-- Stored-value binary32 addition does not satisfy the generic AddZeroClass contract.
example : AddZeroClass FloatLib.Floats.Binary32 := by infer_instance
