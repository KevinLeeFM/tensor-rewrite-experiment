# SimplifyConvToMultiply: remaining source-adapter gate

**Audit result:** the existing convolution theory directly justifies three of the twelve normalized geometry variants under an exact same-type Semiring contract. These are historical theorem reuse, not new complete source proofs. All twelve still lack the physical-axis/shape adapter; the nine cast variants also lack a typed conversion model. No source-rewrite record is closed by these receipts.

## Source identity and guards

Inspected `SimplifyConvToMultiply` at the pinned XLA commit `e58e523b11f1fde802a493a776d158007486e1bf`, source SHA-256 `1ecfd7d4ba958ac0e795d8663c14f7f6b1ebd147a8a83ed0e99661740105628f`, lines 11102–11220. The function rejects layout-sensitive mode and RHS sparse convolution; requires every spatial axis to have unit kernel extent or output extent one; rejects stride, padding, and dilation; and requires kernel input-feature extent one plus input and output feature extents equal to `feature_group_count`. Hence there is one input and one output feature per feature group. It builds input/kernel permutations into output-axis positions, reverses selected kernel axes, conditionally converts each operand to result type, broadcasts the kernel to input shape, multiplies, reduces the nonunit kernel axes, and reshapes to the convolution result shape.

The source-normalization registry contains all twelve `SimplifyConvToMultiply` action variants and binds them to the shared source branch. Its recorded source review explicitly says there is **no** `batch_group_count == 1` gate; do not add one based on another convolution helper. `Convolution.Plan` factors `batchGroups` and `featureGroups` separately and its theorem allows arbitrary groups, but the source-to-Plan mapping must still account for HLO batch/feature grouping, shape inference, and flattened group/batch indices. Do not conflate the two group counts or infer that all combinations are source-valid from the normalized theorem.

The source review artifact is `reviews/results/census-pilot-v1-dot-convolution-source-normalization.json`, SHA-256 `bc4a0ec7589be5c77dae9e7275d2282a9c72541d21973d0ddb352bce7af4e557`. It identifies the same XLA commit and source hash and records the 12 IDs. Its own status is `review_artifact_only_not_canonical_acceptance`; its reviewer model/config are unknown, and its scope is local paths under declared external interfaces, not proof or rewrite acceptance. This is useful enumeration evidence, not a canonical independent source verdict.

## Exact normalized-theory overlap

`TensorRewrite.Theory.ConvolutionSeparable.convolve_eq_productReduction` states the old convolution equals a product/read reindexing reduced over only nonunit kernel axes, under `IsSeparable` (per axis: unit stride, unit base/kernel dilation, zero padding, and kernel extent one or output extent one), `inputFeaturesPerGroup = 1`, and a single same-type Semiring. Reversal is independently allowed on every axis and is applied to the kernel. Rank, extents including zero, batch groups, feature groups, batches, and output features are arbitrary. This matches the source's normalized geometric and one-input-channel guards for the no-conversion variants. Its finite-sum theorem does not establish floating-point accumulation order, physical layout, XLA conversion semantics, or source correspondence.

`ConvolutionPointwise.convolve_eq_channelSum` and `convolve_single_channel` also provide the pointwise special case; these are same-type Semiring theorems. `ConvolutionSeparable` itself already covers the all-unit geometry, so there is no extra mathematical result to prove for that normalized case.

| Source label | Normalized flags (reduce, nontrivial reverse, input cast, kernel cast) | Existing normalized theorem | Source-level remainder |
| --- | --- | --- | --- |
| `pointwise-000` | 0,0,0,0 | Separable theorem; also pointwise channel-sum/single-channel corollary | Dimension/broadcast/result-shape adapter; numerical contract |
| `pointwise-001` | 0,0,0,1 | None for typed cast | Dimension adapter plus kernel-conversion/intermediate-type model |
| `pointwise-010` | 0,0,1,0 | None for typed cast | Dimension adapter plus input-conversion/intermediate-type model |
| `pointwise-011` | 0,0,1,1 | None for typed casts | Dimension adapter plus both conversion paths |
| `reduce-000` | 1,0,0,0 | Separable theorem | Dimension/reduction/reshape adapter; numerical contract |
| `reduce-001` | 1,0,0,1 | None for typed cast | Dimension adapter plus kernel conversion and reduction/reshape |
| `reduce-010` | 1,0,1,0 | None for typed cast | Dimension adapter plus input conversion and reduction/reshape |
| `reduce-011` | 1,0,1,1 | None for typed casts | Dimension adapter plus both conversions and reduction/reshape |
| `reduce-100` | 1,1,0,0 | Separable theorem, including selected reversal | Dimension/reversal/reduction/reshape adapter; numerical contract |
| `reduce-101` | 1,1,0,1 | None for typed cast | Dimension/reversal adapter plus kernel conversion and reduction/reshape |
| `reduce-110` | 1,1,1,0 | None for typed cast | Dimension/reversal adapter plus input conversion and reduction/reshape |
| `reduce-111` | 1,1,1,1 | None for typed casts | Dimension/reversal adapter plus both conversions and reduction/reshape |

The flags and existing-evidence links above match `census/convolution-mathematical-domains-v1.json`. That worksheet already lists `convolve_eq_productReduction` for exactly `pointwise-000`, `reduce-000`, and `reduce-100`; it marks statement review pending and all whole records open. Concise machine-readable *normalized-core reuse only* rows (not source acceptance):

```json
{
  "source_commit": "e58e523b11f1fde802a493a776d158007486e1bf",
  "kind": "normalized_geometry_core_reuse_only",
  "source_proof_accepted": false,
  "rows": [
    {"id":"SimplifyConvToMultiply/pointwise-000","theorem":"TensorRewrite.Theory.ConvolutionSeparable.convolve_eq_productReduction","geometry":"all kernel spatial extents are 1","casts":false,"reversal":false,"source_adapter_pending":true},
    {"id":"SimplifyConvToMultiply/reduce-000","theorem":"TensorRewrite.Theory.ConvolutionSeparable.convolve_eq_productReduction","geometry":"each spatial axis has kernel extent 1 or output extent 1","casts":false,"reversal":false,"source_adapter_pending":true},
    {"id":"SimplifyConvToMultiply/reduce-100","theorem":"TensorRewrite.Theory.ConvolutionSeparable.convolve_eq_productReduction","geometry":"each spatial axis has kernel extent 1 or output extent 1","casts":false,"reversal":"selected nonunit kernel axes","source_adapter_pending":true}
  ]
}
```

## Missing adapter and package boundary

The existing imported declarations are sufficient for the normalized value theorem: `Convolution` defines the factored model; `ConvolutionSeparable` plus its reindex/geometry proofs supplies the mixed-window result; `ConvolutionPointwise` supplies the pointwise specialization. Their existing Lake closure uses the pinned Mathlib v4.35.0 (`56a005855ea17e0b0958f73ec801ae140b0a1679`). No new third-party package is justified for a source adapter.

The smallest missing custom unit is a source-facing shape/coordinate adapter that (1) constructs the normalized `Plan` from convolution dimension numbers and physical shapes; (2) proves the input/kernel transpose or permutation views, feature-group and batch-group index factorization, and output-axis ordering; (3) identifies the `CreateBroadcastSequence` result and the physical reduction axes; and (4) proves that reducing then reshaping to `convolution_shape` agrees with the normalized product at each output coordinate. This separates **logical axis normalization** (already represented in `Plan` and covered by the theorem) from **physical-axis placement and reshape order** (not proved by that theorem).

For the nine cast variants, add a typed adapter for the source's `MakeConvertToHlo` paths and the original convolution's element-type semantics. `Convolution` currently uses one `α` for both operands, products, accumulator and result; its Semiring theorem cannot silently identify mixed element types or prove that conversion commutes with products/sums. Exact-Int or same-type conversion-preserving cases may permit a small specialization, but F32/BF16 or other rounded conversions need explicit observation/accumulation contracts. No Lean conversion declarations in the existing convolution modules close this gap. The source performs separate input and kernel conversions, then multiply/reduce in result type, so each flag pair needs the corresponding adapter path.

## Evidence trust and limits

The current source hash matches the pinned source entry. Current manifests `census/convolution-separable-v1.json` (`347097e6242880005e51b3eeb25a9adfa29776b573879f1437f08f6ce6a061b8`) and `census/convolution-pointwise-v1.json` (`bf76965a3fe8fc7bd4f88c9646550e1d15e84f64a619b6b6d26e362d2a039662`) match their reports and all listed source/proof hashes in this checkout. `reports/convolution-separable.json` records 11 kernel-checked statements, 11 profiles/123 oracle outputs, and standard axioms `[propext, Quot.sound, Classical.choice]` for the terminal theorem. `reports/convolution-pointwise.json` records 13 statements, 8 profiles/78 outputs and the same standard axiom family. `reports/theory-progress.json` records prior full theory build/audit exit code 0. The separate clean-replay log files are one-line pass summaries, not raw Lean invocation logs.

These are consistent historical **receipts**, not fresh builds/replays or independent statement reviews in this audit: both extension manifests say `independently_reviewed_statements: false`; the reports say no full convolution family and zero whole source records closed. Per instruction, no build/install or code change was run. Fresh source-facing work should freeze the exact target and adapter, then run targeted Lean checks and obtain independent mathematical review before assigning any source-record outcome.

Audit start: **2026-11-18 01:50:40 UTC**. Source/receipt inspection and note completed at **01:57:08 UTC** (**6 min 28 s** observed wall; exceeded the nominal ~3-minute target while reading the large source-normalization artifact). No compiler/build time, worker time, or token usage; no source files or proof packets changed. One unrelated untracked `rng-reshape-transpose/REVIEW.md` was present at start and left untouched.
