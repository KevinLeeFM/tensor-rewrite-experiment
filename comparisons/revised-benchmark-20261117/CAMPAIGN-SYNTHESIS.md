# Tensor rewrite campaign as of 18 November 2026

**The newer XLA catalog has 229 accepted mathematical cases, comprising 171 proofs and 58 refutations.** Each case specifies original and replacement calculations, types and conditions. A refutation needs an admitted input with distinguishable outcomes. The historical paper artifact separately has 116 model proofs, one refutation and one vacuous case among 118 executed main cases. The inventories overlap and have different units. A combined proof count or benchmark coverage percentage would require a common set of obligations. [Adopted experiment plan](../../docs/experiment-plan.md) · [contract and dated register](CONTRACT.md)

## What was and was not resolved

| Inventory | Enumerated obligations and outcomes | Evidence |
|---|---|---|
| Paper artifact, Zenodo 14159871 | Of 175 paper rules, 121 were expressible and 118 executed. The other 54 and three respectively fall outside those gates. Of the 115 original solver successes, the historical Lean analysis credits 114 meaningful proofs and flags conv/rule01 as vacuous under its dilation/interior conditions. Two former nonproofs, divmod/rule06 and 07, have proofs with truncating remainder. Slice/rule13 has an admitted counterexample. For dot/rule03 the artifact checked self-equality, while the historical Lean theorem establishes the intended semiring rearrangement. | [Paper reconciliation](../tensorright-v1/REPORT.md) · [118 case identities](../tensorright-v1/cases.md) |
| Recovered auxiliary artifact declarations | Four entries outside the main 118. Two debug Pad declarations share a common-fill mathematical law. Dormant dynamic slice has a same-shape witness with different values. Generalized input-Pad convolution reuses the zero-fill semiring proof and admits positive edge padding. These entries have their own identity and overlap register. | [Four dispositions and evidence](model-audit/artifact-auxiliary-outcomes.json) |
| XLA mathematical cases, source e58e523b | The exhaustive CSV gives each of the 229 case IDs, both calculations, conditions, types, terminal declaration, source links, overlap, review and effort references. A conditional delegation only covers inputs satisfying the callee's contract. The ledger maps 359 lexical labels to catalog cases and 127 to historical reuse, with four labels in both sets. The union covers 482 labels. There are 100 reuse rows and 14 delegation edges. | [229-case index](model-audit/campaign-case-index.csv) · [versioned source and case joins](outcome-ledger.json) |
| Stronger whole-source-record question | Of 488 retained lexical records, seven carry a disproof of preservation and 481 remain unresolved at this stronger level. The seven are HandleAdd/scatter-single-lhs and scatter-single-rhs, HandleDynamicSlice/nested-after-scaled-probe, HandleGather/small-select-chain, RemoveRedundantStride/single-element-axes, ScalarMultiplyReduction/target-output and TryToReorderSliceAndReverse/commute. Eleven labels link to archived configured-native witnesses across seven distinct report paths. | [Per-record outcomes, evidence and work state](outcome-ledger.json) |

The six labels without a mathematical-case or historical-reuse link have different blockers. HandleBitcast/recursive-inner requires a successful graph mutation and rematch. HandleDynamicUpdateSlice/pad-tuple fails the pinned tuple-index admission check. ReplaceInstructionIfCompatible/{single,span-single,span-tuple} and ReplaceWithBitcast/unary require a concrete caller and a relation between old and replacement values. Compatible shapes alone leave that relation undetermined. These six dispositions yield zero additional proofs. [Six-label analysis](model-audit/six-label-disposition.md)

Source links are many-to-many. For example, AssociativeReorderNestedDot/lhs-direct maps to an exact-integer identity and rounded-domain counterexamples. Conversely, a single mixed-spatial convolution identity covers two labels. Historical dynamic-slice/broadcast reuse links back to dyslice/rule03. Historical proofs retain their original revisions and timing provenance. Space-depth passed independent review under Kevin's revised established-lemma contract, with its outer-rank restriction and empty-domain interpretation. The earlier held-out guard rejected five campaign lemmas and that failed check stands. [Space-depth acceptance and failed-guard history](space-depth-review/REVIEW.md) · [All joins](outcome-ledger.json)

## Independent audit against source

A fresh reviewer compared the pinned source branches, operand/axis order, guards, frozen Lean goals and counterexample controls. All 16 compiler commands for three sampled packets passed in fresh output trees, totalling 5.870 compiler seconds. Terminal axioms fell within propext, Quot.sound and Classical.choice. The audit supports the following interpretations under the stated translation assumptions. It does not establish general C++–Lean correspondence. [Source lines, exact goals, axiom sets and replay timings](model-audit/synthesis-sample-audit.md)

| Case | What the checked result establishes | Limit of the source inference |
|---|---|---|
| Triangular nested dot | Reassociation preserves exact integer sums over all six finite extents. A nonunit fixture satisfies the strict cost gate at 9,216 versus 1,728 operations. An incorrect axis gives 24 in place of 3. | One direct lhs-inner profile. Layout, options, cost and machine arithmetic govern actual activation. |
| Mixed-spatial convolution | For a fixed rank-four geometry with arbitrary admitted data, the carried coordinate survives, the contracted coordinate is reduced, and both models read identical bounded pairs. A legal grouped fixture returns 8,726 forward and 4,726 reversed. | One common unconverted Nat domain and particular axis orders. Earlier source branches can take precedence. |
| Narrow inner dot result | With one BF16 intermediate store, 129 × 129 rounds to 16,640. The reassociation retains 16,641. The two orientations give one mechanism. | Defined, nonnegative integer-valued round-to-nearest-even observations. The F32 evaluator rejects pre-round values above 2³⁰. Backend rounding and execution remain unverified. |

A second reviewer distinguished two frequently conflated slice results. For paper slice/rule13 the witness forces a negative replacement start. The fixed-input artifact diagnostic confirms original-valid/replacement-invalid. In the separate archived XLA run, two admitted **empty** slices become ill-shaped while the nonempty control passes. The reviewer verified hashes, inputs and logs; native execution was historical. The two independent reviews took 124 and 151 elapsed seconds and overlapped. Neither the sample nor the historical receipt inspection revalidates all 229 cases. [Historical source and configured-run audit](model-audit/synthesis-historical-and-tools.md)

## What the timing supports

| Recorded UTC window, Nov 18 | Delivered mathematical outcomes | Observed wall time per delivered outcome |
|---|---:|---:|
| 02:54:15–04:36:34 | 27, across 23 packets | 6,139 s / 27 = 3.79 min |
| 04:38:03–05:00:03 | 9, comprising four proofs and five refutations | 1,320 s / 9 = 2.44 min |
| 05:00:52–05:17:53, through registration | 3, comprising two proofs and one refutation, plus auxiliary reconciliation | 1,021 s / 3 = 5.67 min |

These are elapsed delivery rates with overlapping workers, setup and review. The third window includes auxiliary work. For the rank-changing chain, the author window was 537.6 s, final compilation 5.224 s and independent review 62 s including 5.590 s of compilation. Chunk hoisting took 295 author seconds including 73 s setup, one failed compilation and 4.122 s of timed attempts. Independent replay took 1.222 s. Mixed-spatial convolution had a 164.7 s author window and 1.758 s final compilation. [Effort receipts](model-audit/effort.json) · [Chronological register](CONTRACT.md)

The CSV normalizes a comparable freeze-to-candidate checkpoint interval for 97 groups encompassing 127 cases. Among the 77 measured single-case groups the median was 36 s (range 1–247 s). Shared intervals repeat across rows and must be counted once. Some endpoints have only second-resolution Git timestamps. These windows omit work before freeze and after candidate. Another 102 cases have no normalized interval, including one same-commit group. Individual receipts may still contain phase timings. All 118 historical discovery times, uninterrupted space-depth effort, total active worker time, token cost and a comparable end-to-end baseline remain unknown. Interrupted work, failed cast attempts, failed setups and blocked dependency checks remain recorded. A campaign-wide discovery rate or speedup cannot be estimated from these data. [Case-level timings](model-audit/campaign-case-index.csv) · [Space-depth record](space-depth-review/REVIEW.md)

## Reproduction and practical remaining work

From the repository root with complete Git history and the pinned Lean 4.35.0 binary (eb6cafb), the following regenerates the indices and replays the three sampled packets. Each script builds only its own closure in private output. The 229 catalog verdicts draw on their linked packet reviews and historical receipts.

```bash
D=comparisons/revised-benchmark-20261117
export LEAN=/workspace/toolchains/lean-4.35.0-linux/bin/lean
python3 "$D/build_ledger.py"
python3 "$D/model-audit/export_case_effort.py"
for packet in dot-triangle-contract conv-mixed-spatial dot-inner-result-precision; do
  python3 "$D/$packet/replay.py" || exit 1
done
git diff --exit-code -- "$D/outcome-ledger.json" "$D/model-audit/campaign-case-index.csv"
```

The smallest remaining executable target with an existing compatible Mathlib cache is the positive-real log/sqrt adapter. The pinned library already supplies Real.log_sqrt, and the repository has the positive-real identity with the scalar factor on the opposite side. Reorder that factor, lift pointwise and check the exact source-model goal. The source's unguarded log/sqrt and strict F32 disproof remain separate. The sigmoid/maximum case has Real.sigmoid_monotone. For tanh/maximum, the pin supplies an inverse order equivalence on the open unit interval, suggesting an adapter that still needs Lean checking. The inspected module list yielded no confirmed named erf monotonicity result. An unspecified monotone callback would leave that function-specific obligation open. [Pinned log/sqrt lemma](https://github.com/leanprover-community/mathlib4/blob/56a005855ea17e0b0958f73ec801ae140b0a1679/Mathlib/Analysis/SpecialFunctions/Log/Basic.lean#L303) · [Sigmoid](https://github.com/leanprover-community/mathlib4/blob/56a005855ea17e0b0958f73ec801ae140b0a1679/Mathlib/Analysis/SpecialFunctions/Sigmoid.lean#L102) · [Artanh and tanh](https://github.com/leanprover-community/mathlib4/blob/56a005855ea17e0b0958f73ec801ae140b0a1679/Mathlib/Analysis/SpecialFunctions/Artanh.lean#L81)

The local import test failed with `unknown module prefix 'Mathlib'`. The cloud search found neither the pinned compiled modules nor a runnable native HLO fixture. A receipt from a different machine establishes prior availability of the exact Mathlib pin. Resumption needs a cloud-accessible compiled closure for that pin and Lean version, or a specified caller contract for one of the open helpers. The source-only inspection did not retry the blocked cache endpoint. No new case was registered in this synthesis. [Tool and cache preflight](model-audit/synthesis-historical-and-tools.md)
