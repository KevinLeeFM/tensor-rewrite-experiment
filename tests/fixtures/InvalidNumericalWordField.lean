import TensorRewrite.Theory.NumericalCounterexamples
import Mathlib.Data.BitVec

-- Modular words are not a field, even though their ring identities are useful.
example : Field (BitVec 8) := by infer_instance
