# Independent review: mixed carried and contracted convolution axes

**Verdict:** The frozen rank-four exact-Nat model proves one complete physical-index case for a convolution with T contracted and C carried. The three physical axis orders, transpose directions, window reversal, broadcast coordinate, reduction axis and singleton reshape agree with the pinned source. This is one profile, not a count of its two source aliases or reversal settings. It is not native evaluator evidence or C++ correspondence; the model deliberately uses unbounded Nat arithmetic and a bounded exact geometry.

## Source and shape audit

I inspected `MixedSpec`, `MixedProof`, controls, `ConvPointAxes` imported specification/proof, `FREEZE.md`, the frozen simplifier source, and the source calculations. The packet hashes matched. The official pinned XLA source blobs for the relevant supporting files were also fetched; their whole-file Git blob IDs match the local files:

- `hlo_evaluator.cc`: `870725d890f97787a2b7b661f25005678bcd1f54`
- `hlo_instruction.cc`: `7eb3374e7cb882735c097465001c8c5fad0a1e32`
- `shape_inference.cc`: `b4b9c04cffe2d400937420d324f3cf12cce3e5fe`

The fixed physical orders are:

| Tensor | Physical axes and sizes | Source output-position-to-input-axis map |
|---|---|---|
| Input | `[T,B,C,F] = [spatial,batch,c,groups]` | output `[F,T,C,B]` uses `[3,0,2,1]` |
| Kernel | `[C,F,T,I] = [1,groups,w,1]` | output `[F,T,C,I]` uses `[1,2,0,3]` |
| Convolution result | `[F,T,C,B] = [groups,win(spatial,w),win(c,1),batch/batchGroups]` | output axes are in their listed order |

These are actual transpose directions from `SimplifyConvToMultiply`: output batch maps to input slot 1/kernel slot 3, feature to input slot 3/kernel slot 1, and ordered spatial roles T,C map to input slots 0,2 and kernel slots 2,0. For `w>1`, the source requires the output T extent to be one. With unit stride, zero padding and unit dilations, shape inference uses the undilated window bound; that condition forces `spatial=w`. The C kernel extent is one, so C is carried with `win(c,1)=c`. Only T enters `reduction_dimensions`; after reduction, reshape reinserts singleton axis 1. `packed` proves that this squeeze/reinsert preserves each admitted output's row-major offset.

The exact source guards are represented as conditions/derived properties: layout-insensitive mode, no sparse RHS, no stride/padding/dilation, and each spatial axis either has kernel extent one or output extent one. Kernel input features are one; input and output feature counts equal `feature_group_count`, giving one input and output feature per group. Convolution shape inference rejects both feature-group and batch-group counts above one and requires the relevant feature/batch divisibilities. The frozen `Legal` conjunction reflects these relationships, and the imported `ConvPointAxes.oneBatch` derives `batch_group_count=1`; that is not an extra theorem guard. With output feature count `groups`, all feature-group and batch-group offsets reduce to the source terms used by `oldPair`.

For each output, the source evaluator uses the output batch and group indices, enumerates spatial taps, applies `window_reversal` as `window_size-1-tap`, then reads the selected input and kernel feature coordinates. With the carried C kernel size one, C's reversal is a no-op; T's reversal is exactly `flip r w t`. The model's old term list records these physical reads. The replacement transposes the operands, broadcasts the transposed kernel, multiplies at every T coordinate, reduces exactly T, then reshapes. `CreateBroadcastSequence` keeps equal-extent axes (including extent one) and only broadcasts an extent-one operand where extents differ. Here F and T are retained; C and B are retained if their extents equal one, otherwise their kernel extent-one coordinates are inserted at zero. `newPair` models this behavior, and the theorem proves each new physical coordinate is in bounds and the whole ordered old/new term lists agree.

Shape inference and evaluator source in this review are source-mapping evidence; no evaluator execution or floating/machine arithmetic behavior is claimed. The Lean arrays use exact Nat products/sums; finite-width overflow, conversion paths, layout-sensitive cases, sparse/backward convolution, padding and other axis orders are excluded. A zero carried extent or batch yields no complete output coordinate and is vacuous; it is not claimed as a live source rewrite since the source may take an earlier empty-tensor path.

## Distinctness, controls, and case counting

The prior normalized `ConvolutionSeparable.convolve_eq_productReduction` covers the abstract separable value law, while `conv-pointwise-axes` and `conv-full-taps` cover only one spatial axis at a time. They do not jointly establish this two-axis physical composition with one nonunit contracted T axis and a nonunit carried C coordinate. This is one distinct mathematical geometry case. The two `reduce-000` and `reduce-100` source labels are aliases for the same branch with reversal settings; `r` and `rc` are theorem parameters, not separately counted cases. In particular, reversal of C is observationally inert because its kernel extent is one.

The concrete control uses batch 2, group count 2, batch groups 1, spatial T width 3, carried C extent 3, and a valid output with F=1, C=2, B=1. All three spatial/feature/batch roles contribute to the selected offsets. The forward old and replacement calculations both yield 8726; reversing T yields 4726 on both. Resetting the carried coordinate changes the result, showing C is live. Additional controls test the exact reversed physical kernel coordinate, output flat packing 11, retention when singleton extents happen to match, a wrong output T extent, and a zero-C output with no valid coordinate. These are concrete nonvacuity/negative controls; generality comes from the compiled theorem.

## Replay, dependencies, and axioms

Fresh command: `LEAN=/workspace/toolchains/lean-4.35.0-linux/bin/lean python3 comparisons/revised-benchmark-20261117/conv-mixed-spatial/replay.py`. All five manifest hashes matched. Lean 4.35.0 freshly compiled `PointSpec`, `PointProof`, `MixedSpec`, `MixedProof`, and `MixedControls`, all exit 0. Axiom reports are `[propext, Quot.sound]` for `physicalKernelSequence`, and `[propext, Classical.choice, Quot.sound]` for `ConvPointAxes.verified` and `ConvMixedSpatial.verified`. These are standard axioms from the imported finite-index developments; no project axiom, admission, or native evaluation occurs in the accepted closure. Compiler and replay times are recorded in `review.log`.

The packet is a complete theorem for the frozen static mathematical profile, not a full source-record/implementation theorem. It does not claim all layouts, higher ranks or other permutations, an actual native convolution result, cost benefit, or backend correctness.
