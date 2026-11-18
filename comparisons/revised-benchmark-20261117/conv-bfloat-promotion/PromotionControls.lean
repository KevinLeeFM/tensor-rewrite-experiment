import PromotionProof
open RevisedBenchmark.ConvPromotion
example : original witness 3 0 = 768 ∧ promoted witness 3 0 = 772 := by decide
example : original witness 3 1 = 0 ∧ promoted witness 3 1 = 0 := by decide
example : original witness 3 2 = 776 ∧ promoted witness 3 2 = 776 := by decide
example : bf 255 = 255 ∧ bf 257 = 256 ∧ bf 259 = 260 := by decide
