# Failed Iota probe can drop a nested-slice multiplier

XLA e58e523b11f1fde802a493a776d158007486e1bf; Lean4.35.0/Std only.
Canonical algebraic_simplifier.cc is unchanged. This is a native-confirmed
finite-integer source-path counterexample with a checked word/index model;
complete source/observation correspondence and whole-file acceptance remain open.

## Source behavior and census correction

At :8330, the DynamicSlice Iota probe strips Multiply's first operand into local
`operand` after recognizing a scalar Broadcast at Multiply operand1. At :8333,
the Iota test can fail without restoring the local binding. At :8385, the nested
DynamicSlice branch tests that surviving local binding. The graph whose operand
is Multiply(innerDS(x),Broadcast(m)) can therefore be rewritten using the inner
DS base and combined starts, discarding multiplication.

The separate source schema `HandleDynamicSlice/nested-after-scaled-probe` now
records the original Multiply graph, rank1/size1/S32-or-U32 probe, runtime scalar,
earlier-return exclusions, fit checks and the assignment/failure/continuation
anchors. Existing `HandleDynamicSlice/nested` retains only the original direct-
nested partition. The arbitrary-rank logical composition theorem remains valid
for its stated graph; it does not justify dropping multiplication.

`census/schema-revisions.json` records487→488 provisional schemas, zero added
lexical sites and the preserved historical packets. The distinct lexical site
count remains339; all mapped discovery sites do not establish a semantic census.
N/F remain null. Typed API links and central review records are regenerated for
488 schemas and531 API witnesses (previously529); their285 endpoints are unchanged.
The initial checkpoint caught the stale529 test expectation, which was corrected
for the two additional mutation-site witnesses before final validation.

## Verified native witness and controls

With x=[1..10], inner width6/start1, outer width1/start2 and runtime scalar7:

```
DS(Multiply(DS(x,1,size6),Broadcast(7)),2,size1) = [28]
DS(x,Clamp(2,0,5)+Clamp(1,0,4),size1)          = [4]
```

`reports/scaled-nested-slice-replay-v1/` archives11 profiles ×3 modes =33 runs:
no-pass control, initialized exact handler and whole pass. Input and output HLO
verify in every run. Runtime S32 starts and small ordinary values avoid the
older high-bit-u64 evaluator/profile ambiguity. Slow native evaluation is explicit.

- Runtime multipliers7,-3,0 change28/-12/0 to4 in handler/pass modes.
- Runtime multiplier1 exercises the same dropped-operation path while preserving4.
- Reversed Multiply operands, outer width2 and S64 result avoid the probe and
  preserve values; they isolate orientation, width and dtype guards.
- Constant starts with default conversion take the earlier static-slice path and
  preserve28; disabling that conversion exposes28→4 again.
- Direct nested slicing and the intended scaled-Iota case preserve their values.

There are8 value-changing runs. Every candidate-after graph has the expected
DynamicSlice root, original data Parameter0 as operand0 and Add-combined starts.
The handler's public Run initialization suppresses only DynamicSlice, and must
leave changed status false and graph text identical before the original handler
is called. No private visitor state or canonical source modification is used.

These are host-evaluator/full-pass observations, not a compiled backend result.
The source correspondence obligation includes typed multiplication and indices,
all earlier guards and graph/API status/frame behavior; it is not hidden by the
successful value witness or by a proof of the direct-nested expression.

## Lean model and burden

`ScaledNestedSlice.original` uses the existing bounded DynamicSlice coordinate
map, slices six input labels, multiplies as32-bit words, then takes the outer
slice. `rewritten` uses the same checked base/combined-start map without scaling.
Seven certificates prove the selected word is4*m versus4, a general non-fixed-
multiplier refutation condition, concrete7/-3/0 witnesses and failure of universal
preservation. The native signed arithmetic is related by the existing promoted
word multiplication bridge; complete source translation is still under review.
The negative control rejects equality of the actual two expressions.

| Category | Previous | Added | Current |
| --- | ---: | ---: | ---: |
| S, semantics | 724 | 20 | 744 |
| H, support | 866 | 0 | 866 |
| R, rules | 691 | 0 | 691 |
| A, integration | 31 | 1 | 32 |
| C, certificates | 274 | 29 | 303 |
| Total custom Lean | 2586 | 50 | 2636 |

The77 preservation laws and86 support lemmas are unchanged. Tests/audits and
non-Lean source review, extraction and replay work remain separately accounted.
All seven new certificates inherit propext/Classical.choice/Quot.sound from the
checked index/word development. No new axiom is introduced and older empty-axiom
certificate gates are preserved; these seven are not labeled axiom-free.

## Independent inspection and validation

The final frozen-v1 handler supplement independently reads Slice, DynamicSlice,
DynamicUpdateSlice, Reduce and ReduceWindow:2104 body lines,94 existing schemas,
29 selected direct local edges/21 helper names. It independently identified this
local-binding gap and supplied the replay recipe; its report correctly claims
no new native or Lean result. All58 Handle-prefixed bodies have now been read
(57 override handlers plus one helper). Body reading is not semantic/helper
closure; the non-Handle functions and full observation contracts remain open.
Prior reports/packets are unchanged. The separate helper inventory review
continues against frozen v1; it does not automatically accept the live split.

The final checkpoint runs61 tests. Mutation controls reject substituting the
old direct-nested LHS, removing the pointer anchors, erasing value changes,
omitting orientation/type/static controls and promoting correspondence status.
Current proof replay and integrity results are in `initial-checkpoint.json` and
`scaled-nested-slice-clean-replay.json`. Source acceptance stays zero and no
whole-workload feasibility verdict is inferred. Next confirm the independent
Scatter parameter-role and narrow-index Gather witnesses, then Concatenate's
allocation/skip outcome and conditional empty-shape/async cases; continue semantic
function/helper/case partitioning before freezing N/F.


Final validation passed:61 tests and the full checkpoint, followed by a clean
Lean replay without an existing Lake cache. The snapshot preserves every earlier
axiom set and reproduces measurements/model probes. Snapshot SHA256:
068aeae047dd45c58d6584256843280b41830a1a294b4da3c8c842279bb7dab7.
