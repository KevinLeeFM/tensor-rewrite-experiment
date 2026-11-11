import TensorRewrite.Theory.OrderCounterexamples

-- IEEE numerical comparison does not supply the exact-family linear order.
example : LinearOrder FloatLib.Floats.Binary32 := by infer_instance
