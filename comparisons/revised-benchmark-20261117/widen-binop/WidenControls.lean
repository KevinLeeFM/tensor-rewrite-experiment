import WidenProof
set_option autoImplicit false
open RevisedBenchmark.Widen
example : convert 16 true 255#8 = 65535#16 ∧ convert 16 false 255#8 = 255#16 := by decide
example : convert 8 true (convert 16 true 128#8 * convert 16 true 255#8) = 128#8 := by decide
example : convert 8 false (convert 16 false 1#8 - convert 16 false 3#8) = 254#8 := by decide
example : convert 8 false (convert 16 false 250#8 + convert 16 false 9#8) = 3#8 := by decide
example : convert 8 false ((convert 16 false 250#8).udiv (convert 16 false 2#8)) = 125#8 := by decide
example : convert 8 false ((convert 16 true 250#8).udiv (convert 16 false 2#8)) ≠
    (250#8).udiv 2#8 := by decide
example : convert 8 false ((convert 4 false 32#8).udiv (convert 4 false 2#8)) ≠
    (32#8).udiv 2#8 := by decide
