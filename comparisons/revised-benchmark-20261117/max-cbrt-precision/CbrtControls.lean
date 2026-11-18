import CbrtProof
open RevisedBenchmark.MaxCbrt
example : rounds 7 2 161 ∧ rounds 23 2 10568984 ∧ 161*2^16 = 10551296 := by decide
example : ¬ rounds 23 2 10551296 ∧ ¬ rounds 23 2 10568983 ∧ ¬ rounds 23 2 10568985 := by decide
example : rounds 7 1 128 ∧ rounds 23 1 8388608 ∧ max (128*2^16) 8388608 = 8388608 := by decide
example : ¬ rounds 7 8 256 := by decide
