# Reuse review of six source labels

At checkout ffddfc3306b655b07fb1a4bb8466a10cb690c27e and XLA e58e523b11f1fde802a493a776d158007486e1bf, two labels have exact historical links, one has an exact subcase plus a missing run construction, and three share a normalization obligation. These links represent zero newly discovered proofs. I independently read the pinned source, exact historical Lean statements, definitions and original receipts. I did not rebuild the historical artifacts or execute XLA.

| Source ID | Historical case and checked theorem | Reuse decision |
|---|---|---|
| HandleConcatenate/pad-low | concat/rule05, PaperComparison.Concatenate.pad_low | Accept low-edge branch, arbitrary static compatible shape, common payload type |
| HandleConcatenate/pad-high | concat/rule06, PaperComparison.Concatenate.pad_high | Accept high-edge branch under the same shape/type profile |
| HandleConcatenate/adjacent-slices | concat/rule04, PaperComparison.Concatenate.touching_slices; Theory.Concatenation.adjacent_slices_context and slice_merge_run | Accept two adjacent slices and the represented valid merge sequences as inherited subcases. Whole scanner coverage pending |
| HandleDynamicUpdateSlice/pad-scalar-list | dyupslice/rule02, PaperComparison.UpdatePad.update_eq_pad | Canonical already-clamped start only. Full decoded-start link pending |
| HandleDynamicUpdateSlice/pad-tuple | same | Same post-decoding calculation conditional on successful decoding. Positive-rank tuple fails index shape checks |
| HandleDynamicUpdateSlice/pad-concatenate | same | Same post-decoding calculation conditional on successful decoding. At positive rank, valid concatenation operands conflict with the scalar matcher |

Prefix each Lean name above with TensorRewrite. No assumption about source reachability or correspondence enters these historical acceptance decisions.

## Concat and edge Pad

The handler selects the broadcast on the first operand if both operands match, otherwise the broadcast on the second operand. It emits the matching scalar fill, selects the other operand as data, sets all interior padding to zero and sets only the corresponding low or high edge of the concat axis to the matched broadcast width. A shared Frame fixes every non-concat extent and a selected in-range axis; the two operand widths can differ. The theorem's constantBlock is an actual broadcast from rank zero, and edgePadding_shape checks the complete output shape. Equality is over arbitrary payloads and all output coordinates, including zero extents in the mathematical domain. Earlier empty/flatten handlers can take precedence in the source. There is no separate mathematical case for the both-match priority. [Handler lines 2232–2262](../../../sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc#L2232) · [Historical proofs](../../tensorright-v1/Concatenate.lean#L82) · [Frame and scalar block](../../../TensorRewrite/Theory/ConcatenationGraphs.lean#L47)

## Concat and adjacent slices

Pinned code scans in order, requires the same operand, unit strides, touching selected-axis limit/start and equal other-axis starts. Since verified concat operand extents agree on every other axis, legality of unit slices gives equal other-axis limits. It retains other operands in order and constructs one slice using the first attributes and last selected-axis limit. The historical pair theorem takes exactly the touching condition. unit_stride_adjacent derives the sampled-adjacency arithmetic needed by the general theorem. mergeAxis constructs the same merged endpoints, merged_axis_valid proves validity and summed length, adjacent_slices_context allows arbitrary neighbors, and slice_merge_run preserves the packed block of any sequence supplied inductively. None assumes output equality. [Scanner](../../../sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc#L2163) · [Pair](../../tensorright-v1/Concatenate.lean#L65) · [Run relation](../../../TensorRewrite/Theory/ConcatenationMerge.lean) · [Preservation](../../../TensorRewrite/Theory/ConcatenationAdjacent.lean#L93)

For arbitrary inputs, the existing theorem takes an explicit run over a fixed source tensor and fixed common crop. Its statement does not construct that run from the scanner, whose distinct runs can cut different tensors with different non-axis crops. The smallest mathematical extension is to turn each nonempty touching segment into its left-folded pair merges, with sum of widths equal to last.limit − first.start, then compose contextual equalities across unrelated segments. The two-slice case is an accepted expression-domain partition. There is no new proof of the entire scan here.

## Uniform DUS to Pad

The source reads start operands in axis order, extracts an integer, clamps on each axis to low = min(max(0, raw), outer − inner), and sets high = outer − (low + inner). It preserves update values in the window, using the scalar broadcast value elsewhere. Recorded configuration includes rewrite enabled, successful extraction and the host-offloading exclusion. The paper theorem starts with nonnegative low and high, defines outer via padding.outputShape, and constructs padWindow with raw starts equal to low. start_eq_low shows this already legal start remains unchanged. It does not directly quantify original arbitrary raw starts in an independently given outer shape. For example with outer=5, inner=2, raw=−2 or 9, the original raw windows differ from the paper window's starts 0 or 3. DynamicIndex.clampStart and DynamicUpdate.start_bounds already give the relevant normalization/bounds. Bridge needed: derive low+inner+high = outer, transport the paper output shape, then show the original window locates the identical update index because its clamped start equals low. This one bridge addresses the decoded value law for all encodings. [Handler](../../../sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc#L8442) · [Historical theorem](../../tensorright-v1/UpdatePad.lean#L51) · [Window semantics](../../../TensorRewrite/Theory/DynamicUpdate.lean#L24)

For positive-rank verified HLO, scalar-list is an admissible encoding. DUS shape inference accepts a single integral rank-one index array or the required same-type integral scalars. A tuple is neither. A legal concatenate used as a rank-one index vector must have rank-one operands; the handler instead matches each operand with ConstantScalar, which disables effective-scalar matching. Concatenating rank-zero literals fails axis bounds. These facts prevent counting three distinct executable source cases; they do not establish a native run, a compiler bug or a vacuous success. The separate pad-concat-low/high packet rewrites a DUS *on a padded input* into a concatenate and has different expressions. [Verifier](../../../sources/xla/xla/service/hlo_verifier.cc#L1999) · [DUS shape check](../../../sources/xla/xla/service/shape_inference.cc#L3625) · [Concat shape check](../../../sources/xla/xla/service/shape_inference.cc#L502) · [Matcher](../../../sources/xla/xla/service/pattern_matcher.h#L2515)

## Source identity and historical receipt checks

The historical paper proof hashes below match cases.json. The concat and DUS check logs report only propext, Quot.sound and, for both Pad results and update_eq_pad, Classical.choice. Theory-progress also records propext and Quot.sound for adjacent_slices_context and slice_merge_run and source hashes matching the current ConcatenationAdjacent, ConcatenationMerge, ConcatenationGraphs, and DynamicUpdate modules. No fresh compiler time was charged. [Case inventory](../../tensorright-v1/cases.json) · [Concat log](../../tensorright-v1/concatenate-check.log) · [DUS log](../../tensorright-v1/update-pad-check.log) · [Theory receipt](../../../reports/theory-progress.json)

Inspected source and receipt hashes (SHA-256):

```text
1ecfd7d4ba958ac0e795d8663c14f7f6b1ebd147a8a83ed0e99661740105628f  sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc
e55b7a4f46b2e6ac157ac6918fff06078c78c7e865f8a24b5da8c259d932c5e6  sources/xla/xla/service/shape_inference.cc
3e7aee3f96e025965e861e68efe90cee276bc9377efc271e7180b9bb78bb9101  sources/xla/xla/service/hlo_verifier.cc
78dd71e595f00bbe26391a8fd904d641d5c219cecb2da0622be34bb76d3e85b1  sources/xla/xla/service/pattern_matcher.h
4ad979d5d60d039cd6ea754acbada063e48ee4e3cf1710e3282d03f73d8fadfa  comparisons/tensorright-v1/Concatenate.lean
04e427b88d55961b4e754619c245856e8cfcb0ff97cdd8c443c3fa289ce9bd4c  comparisons/tensorright-v1/UpdatePad.lean
9556eeb01a7af476c01242ee4fcc5b5f69fccf4abd4704cd861a4f12ccbf4e6d  comparisons/tensorright-v1/concatenate-check.log
8fdfa8288a6d6a5ad426d9523874df36fca07ad886b234b0d86597c0624339ec  comparisons/tensorright-v1/update-pad-check.log
bf42003a686bf5d555ac5c523e7da9eb5a5f026c0d483a9e07578daaae2120df  TensorRewrite/Theory/ConcatenationAdjacent.lean
286dee0166e20cde8825931b0a4c41024290bf768449602a7a2b354ba92fa2d2  TensorRewrite/Theory/ConcatenationMerge.lean
142c1f68b6b1b649ac133a5523aef56c32d49574112e3e6f2fae94c80ff8e098  TensorRewrite/Theory/ConcatenationGraphs.lean
9e6206541b6aa6e95a8a953e60efada0c7fc234fdd4ac2f5d4813a96588a5dc3  TensorRewrite/Theory/DynamicUpdate.lean
 ```

Review elapsed 109 seconds, 01:29:45–01:31:34 UTC on November 18. Exclusive reasoning time and token usage were unmeasured. No Lean process, native build or proof search was run.
