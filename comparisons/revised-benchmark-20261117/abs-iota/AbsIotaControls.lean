import AbsIotaProof
open RevisedBenchmark.AbsIota
example : original 6 128 Unit = replacement 6 128 Unit := (verified ..).2 (.inr (by decide))
example : original 6 129 Unit = replacement 6 129 Unit := (verified ..).2 (.inr (by decide))
example : original 6 130 Unit ⟨129, by decide⟩ () ≠ replacement 6 130 Unit ⟨129, by decide⟩ () := by decide
example : original 0 100 Empty = replacement 0 100 Empty := (verified ..).2 (.inl Empty.elim)
example : original 0 0 Unit = replacement 0 0 Unit := (verified ..).2 (.inr (by decide))
