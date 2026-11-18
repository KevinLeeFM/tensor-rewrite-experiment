import ReadProof
set_option autoImplicit false
open RevisedBenchmark.IotaRead
example : replacement 8 true false 4294967295#32 none 0 = 0 := by decide
example : replacement 8 false true 4294967295#32 none 0 = 7 := by decide
example : replacement 5 false true 8#32 (some 4294967295#32) 0 = 4294967292#32 := by decide
example : replacement 1 false true 4294967295#32 (some 5#32) 0 = 0 := by decide
example : replacement 4294967399 false false 4294967295#32 none 0 = 4294967295#32 := by decide
example : replacement 2147483749 true true 2147483647#32 none 0 = 2147483647#32 := by decide
example : original 5 (by decide) false 8#32 (some 3#32) 0 ≠
    replacement 5 false false 8#32 none 0 := by decide
