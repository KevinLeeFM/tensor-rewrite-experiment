# Swapped convolution visits the matched taps in reverse

The one output has the same batch/feature coordinates before and after (both dimensions have extent one). At spatial coordinate zero:

| Tap | Original reads (input,filter) | Swapped (reversed filter position, reversed-window input position) | Swapped reads in original (input,filter) coordinates |
|---|---|---|---|
| 0 | (0,0) | (1,2) | (2,2) |
| 1 | (1,1) | (2,1) | (1,1) |
| 2 | (2,2) | (3,0) | (0,0) |
| 3 | skipped (input 3 out of bounds) | no tap | — |

The original unit-stride output extent is 3+0+1−4+1=1. With padding high 1, neither the unchanged group window nor the pure-contraction exception fires in conv_operand_swapper.cc:67–87. The benefit compares kernel sizes 4>3. Lines 90–120 give a new width 3, explicitly reverse the old kernel, set window reversal and derive padding 3+0−4=−1, 3+1−4=0. The output extent is still 4−1−3+1=1. Lines 127–168 exchange the batch/feature roles and operand precisions and preserve spatial output axes. Use two DEFAULT precision entries, no block scaling/sparsity/grouping, standard successful lowerability callback, and layout-insensitive enabled swap. Two parameter tensors bypass the prior pad and zero checks; select scalar movement disabled (algebraic_simplifier.cc:10887–10901,11223–11252). This is a complete finite mathematical case, without executing the dispatcher.

The old input is [1,1,16777216], filter [1,1,1,7]. The sentinel 7 cannot influence the correct output. hlo_evaluator.cc:5986–6078 starts at +0, iterates the kernel coordinate upward, skips out-of-bounds input and reverses the kernel index on a reversed window. In the one-spatial-axis scalar-channel specialization the three exact products are 1,1,16777216 before versus 16777216,1,1 after. Strict binary32 nearest-even summation gives 16777218 before and 16777216 after. Each late addition of 1 in the swapped order ties and rounds downward to 16777216. Products are exact, so contraction of a multiply and add at an individual step would not change this witness. Both arrays and all intermediate values are finite, and all inputs are exactly representable; bounded Fin coordinates encode every tensor access. Exact integer sums agree as a control. A second witness catches omission of the explicit Reverse. This is an order-specific mathematical observation, not an XLA backend guarantee or a native compiler defect.

Earlier conv-full-taps compares the multiply/reduce branch with a one-spatial-axis convolution under equal term order, and conv-mixed-u32 addresses conversion and saturation. Neither tests exchanging input and filter with changed padding and ordered MACs. Existing r32 is reused. Source reading supports the finite model only.

UTC 2026-11-18. Inspection started 04:26:33; source and statement freeze aeb40a4 at 04:27:16 (43 s). The proof and controls passed by 04:27:39 (23 s including compiler time). All four fresh Lean 4.35 subprocesses passed in 1.514 s combined, with no failed compile. Both axiom audits list only propext and Quot.sound. Report packaging followed; active reasoning/token usage unmeasured. Independent review pending.
