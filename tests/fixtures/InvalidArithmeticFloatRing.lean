import TensorRewrite.Theory.ArithmeticFloatCounterexamples
import Mathlib.Data.BitVec

open FloatLib.Floats

example : CommRing Binary32 := by infer_instance
