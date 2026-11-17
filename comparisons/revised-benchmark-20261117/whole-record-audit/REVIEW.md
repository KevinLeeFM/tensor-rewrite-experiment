# Independent contract adjudication of 11 archived witness records

Reviewed benchmark checkout 248db5683522ddbb9313d63430cd2bf881131729, source snapshot XLA e58e523b11f1fde802a493a776d158007486e1bf, simplifier SHA-256 1ecfd7d4ba958ac0e795d8663c14f7f6b1ebd147a8a83ed0e99661740105628f. I owned this report only. I inspected the revised contract, AGENTS, repository guidance and docs/experiment-plan.md, record-outcomes.json, census/site-case-map.json, earlier independent reviews, source and archive evidence. Earlier Lean certificate checks and native executions are inherited. This pass only ran offline archive checkers and read source. The 118 historical paper entries are unaffected.

## Decision rule

For each record R, the universal correctness obligation ranges over legal inputs and applicable options for which the complete transformation R fires. The replacement must be well-formed and preserve the specified observable on that input. A single applicable witness violating either conjunct disproves that proposition for R. Additional satisfied subcases, admissible element types, or uncharacterized inputs cannot reverse that logical conclusion. Attributing an internal intermediate failure alone is insufficient when the caller can repair it. Use final before/after IR and matching dispatch, controls and configured pass observations. The result does not classify the entire safe domain or constitute C++ correspondence. Quantifying instead over only a default pipeline, only an exact-real model excluding machine-index behavior, or every backend's intended numerical allowances would be a different proposition.

## Supported complete negative record outcomes

Seven unique lexical IDs have definite witnesses against universal well-formedness or logical result preservation in these admitted configurations. All seven are recovered outcomes. The scatter orientations share a witness family.

| Retained record | Decisive admissible witness and observation | Source and evidence |
| --- | --- | --- |
| RemoveRedundantStride/single-element-axes | Input S32[4], [1:1:2], legal declared output length 0. Replacement [1:2:1] requires length 1 but retains 0. | simplifier 7616–7651, 8104–8111; reports/empty-slice-replay-v2/{fixture.cc,test.log,result.json}; reports/empty-slice-formal-refutation.md |
| TryToReorderSliceAndReverse/commute | Same legal slice over Reverse. C++ truncation gives (-1)/2 = 0. Replacement inner [2:3:2] requires length 1 but retains 0. | simplifier 7572–7614; same archive. Both originals passed the same verifier that rejected the corresponding rewritten instruction after the full single pass. Nonempty control remained valid. Empty element observation cannot conceal a wrong declared shape. |
| HandleDynamicSlice/nested-after-scaled-probe | Verified S32 program, starts 1,2, scale 7, extents 10→6→1. The same base element 4 yields 28 originally and 4 after bypassing the multiply. No overflow, exceptional value, or out-of-bounds start. | simplifier 8307–8333, 8385–8428; reports/scaled-nested-slice-replay-v1. Failed Iota match leaves rebound operand live; replacement root uses original base and new summed start. Handler and complete pass agree, control retains 28. |
| HandleAdd/scatter-single-rhs | In-range single update with reducer old+old, base [3,3], independent [1,1], updated at 0. RHS scatter gives [7,4] then [8,4]. | simplifier 1095–1117, 1252–1253; reports/reducer-index-replay-v1; recovered-witnesses/SCATTER-GATHER-REVIEW.md. |
| HandleAdd/scatter-single-lhs | Same legal input in the opposite source orientation and the distinct operand-write/final-replacement path, same result change. No colliding updates, ambiguous update order, wraparound or undefined arithmetic. | simplifier 1258–1259; same archive. Both handler and pass changed values; controls using one of each reducer argument agree. |
| HandleGather/small-select-chain | Extent 129 with explicitly enabled threshold 129, S8 runtime index **0** and S32 data labels. Original returns 0. Generated signed threshold 128 narrows to −128, so last select returns 128. Input index is valid even under a contract excluding out-of-bounds gathers. | simplifier 4634–4686; reports/reducer-index-replay-v1. Handler and complete pass exhibit the result. Default threshold 4 suppresses this case; an assertion limited to default settings remains separate. |
| ScalarMultiplyReduction/target-output | Finite normal F32 convolution with four ones and two Select arms scaled by 2 or 3. Original chooses one factor and produces 8/12. Replacement removes both scales then multiplies output by 6 and produces 24. These small integers and all products/partial sums are exactly representable under reassociation. | simplifier 638–647, 695–702, 723–822, caller 11223–11276; options proto 46–48. reports/scalar-select-replay-v2/{fixture.cc,result.json,test.log}, enabled/disabled option, pass fast math off. Output shows surviving convolution and new root multiply after caller continuation. Exclude failed v1 control. Verdict for exact finite-value preservation; no assertion about an unspecified approximate backend relation. |

The first two violate the structural result contract even before asking about values. The other five violate concrete, defined data results. None requires downstream compiled-machine execution under this experiment's stated model/observation contract. Seven record IDs do not imply seven independent experiments.

## Keep four configured failures separately qualified

HandleCompare/nonnegative-ge and HandleCompare/nonnegative-le flip an ordered quiet-NaN comparison's Boolean from false to true in reports/compare-nonnegative-replay-v1. HandleMultiply/predicate-convert changes the strict exceptional-class result NaN to zero in reports/xla-replay-v3. These refute strict evaluator preservation. The absence of fast math and presence of honor flags support those observations. They do not by themselves settle site-specific optimizer allowances for nonfinite inputs; see reports/numerical-contract-review.md. HandleDynamicSlice/nested has a documented high-bit U64 decoding difference in reports/nested-slice-replay-v2. The mathematical nested-slice identity with consistently decoded starts still holds. The normative unsigned-index/backend interpretation remains unresolved. Retain all four as definite configured/evaluator findings, leaving unconditional promotion open pending a matching contract. Distinguish the direct nested record from the scaled-probe fallthrough.

## Reverse selection boundary

In HandleReverse (7217–7228, 7288–7318), the all-unit reverse test precedes the layout-insensitive insertion-only reshape arm. ShapeUtil::InsertedOrDeleted1SizedDimensions (shape_util.cc 1624–1681) rejects unmatched extents greater than one, so its name alone does not prove it excludes unmatched zero. The documented CommonFactors contract (util.h 786–797) returns the diagonal for equal shapes and only endpoints for unequal zero-product shapes. DimensionsUnmodifiedByReshape (shape_util.cc 1684–1703) retains only singleton-to-singleton blocks. On legal static unequal empty shapes there is no such block: the only rank-one to rank-one zero-product pair has equal shape [0]. Hence every source axis is unmatched, and either a >1 gap rejects the descriptor or the nonempty input-axis list is deleted, failing the branch. Equal static empty shapes have identity correspondence; reversal may still reach the arm when an axis of extent zero is selected. A mathematical insertion-only lemma may honor empty shapes yet be broader than the helper's possible descriptor on unequal empty shapes. Dynamic shapes and full-pipeline behavior remain outside this argument.

## Checks and cost

I ran python3 tools/check_NAME_evidence.py with NAME, return code and elapsed seconds below. All were read-only archive checks, using retained fixture, results, logs and source hashes. Native and Lean compiler time for this pass were both zero.

| NAME | Code | Seconds |
| --- | ---: | ---: |
| empty_slice_replay | 0 | .039 |
| scaled_nested_slice | 0 | .137 |
| reducer_index | 0 | .071 |
| scalar_select_replay | 0 | .043 |
| ordered_source | 0 | .105 |
| nested_slice | 0 | .034 |
| xla_replay | 0 | .060 |

Review started at 23:31:09 UTC on 2026-11-17. Archive checks total .489 s within review wall time. Historical discovery time, reviewer active reasoning, token usage and comparative speedup are unavailable. A first lookup for util.cc found no retained file; the pinned declaration explicitly documents the zero-product contract. No new proof, native run, or dependency setup.
Report completed 23:34:03 UTC (174 s observed review wall, including checker time).
