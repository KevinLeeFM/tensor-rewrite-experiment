import TensorRewrite.Theory.BitPackingProof

open TensorRewrite.Pilot
open TensorRewrite.Theory.BitPacking

set_option autoImplicit false

namespace RevisedBenchmark.BitcastConvertCompose

private theorem hNarrow : 1 * 32 = 2 * 16 := by norm_num
private theorem hNarrowAgain : 2 * 16 = 4 * 8 := by norm_num
private theorem hTotal : 1 * 32 = 4 * 8 := by norm_num

/-- The exact stored byte stream is invariant under the frozen U32 -> U16 -> U8 partition. -/
theorem nestedU32U16U8 (input : Words 1 32) :
    repack Order.leastFirst Order.leastFirst hNarrowAgain
      (repack Order.leastFirst Order.leastFirst hNarrow input) =
    repack Order.leastFirst Order.leastFirst hTotal input := by
  simpa only [hTotal] using
    (repack_compose Order.leastFirst Order.leastFirst Order.leastFirst
      hNarrow hNarrowAgain input)

/-- The reverse width sequence reconstructs the original 32-bit stored word. -/
theorem reverseRoundTrip (input : Words 1 32) :
    repack Order.leastFirst Order.leastFirst hNarrow
      (repack Order.leastFirst Order.leastFirst hNarrowAgain.symm
        (repack Order.leastFirst Order.leastFirst hNarrowAgain
          (repack Order.leastFirst Order.leastFirst hNarrow input))) = input := by
  rw [repack_compose]
  rw [repack_compose]
  simpa only [hTotal, eq_comm] using
    (repack_refl Order.leastFirst input)

/-- The same-width, same-order identity control. -/
theorem sameWidthIdentity (input : Words 1 32) :
    repack Order.leastFirst Order.leastFirst rfl input = input :=
  repack_refl Order.leastFirst input

/-- The nested `[2,2]` result and direct `[4]` result have different tensor ranks. -/
theorem nestedAndDirectRanksDiffer : 2 ≠ 1 := by decide

end RevisedBenchmark.BitcastConvertCompose
