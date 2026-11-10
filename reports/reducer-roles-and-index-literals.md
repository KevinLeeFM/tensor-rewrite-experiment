# Scatter parameter roles and Gather literal narrowing

XLA e58e523b11f1fde802a493a776d158007486e1bf; Lean4.35.0/Std only.
Canonical algebraic_simplifier.cc is unchanged. The pinned real pass and exact
handlers reproduce two source-path value failures. Lean checks their value models
and general repaired-condition lemmas. Full source/observation correspondence
and whole-file experimental closure remain open.

## Scatter: parameter opcode is not parameter role

The matcher at :1105–1118 accepts Add(Parameter(),Parameter()) without checking
numbers or distinctness. The two single-Scatter paths :1249–1259 keep the same
update computation while adding the separate operand into the Scatter base.
The lhs path constructs Add(lhs Scatter base,original rhs); the rhs path constructs
Add(original lhs,rhs Scatter base). The extracted expressions now preserve that
order and the actual callback f, rather than implicitly treating it as ordinary
current-plus-update addition.

For A=[1,1], B=[3,3], index0, update5 and f(current,update)=current+current:

```
A + Scatter_f(B,0,5) = [7,4]
Scatter_f(A+B,0,5)   = [8,4]
```

Repeating the update parameter instead gives[11,4] versus[10,4]. Distinct roles01
and10 preserve[9,4] in the same controls. Both Add orientations are exercised,
as are layout-sensitive skip and no-pass modes. There is one unique update,
so no collision/order ambiguity, exceptional float, overflow or Reduce-style
initializer premise accounts for these differences.

Legality was checked against the operation contract as well as the verifier.
The [pinned Scatter specification](https://github.com/openxla/xla/blob/e58e523b11f1fde802a493a776d158007486e1bf/docs/operation_semantics.md#L4759)
defines current-value/update argument roles and permits noncommutative callbacks.
Both parameters need not occur in the body. The [official current documentation](https://openxla.org/xla/operation_semantics#scatter)
agrees on the role distinction; it was a supplementary check, not the experiment's
version identity. One index satisfies both asserted sorted/unique flags.

The two-Scatter concat/nested branches share the permissive matcher but are not
covered by this native witness. Their finding remains source-inspected and
unreplayed. They are not silently promoted from the single-Scatter results.

## Gather: the generated comparison literal is narrowed

At :4656–4686, configurable small-Gather unrolling compares the runtime index
against MakeScalarLike(index,i) for every position, selecting that data element
when the comparison succeeds. This is a typed Select chain, not an automatically
correct mathematical clamp. MakeScalarLike converts the integer literal to the
actual index type; the source has no local representability guard.

For s32 data labels0..128, s8 index0 and threshold129, the final generated literal
128 becomes signed8 -128 on the pinned host. The last comparison succeeds,
changing result0 to128. Index127 is also in bounds and changes127 to128. Thus the
principal counterexamples do not rely on an out-of-bounds-index contract.

Negative-index and wider positive out-of-bounds controls are recorded separately
as observations of the pinned evaluator's explicit clamping (:2765–2771).
The model's originalIndex uses that clamp. Threshold4/default, threshold128,
extent128 and s32-index controls isolate configuration, extent and signed-width
boundaries. The explicit Literal.Convert(128,S8) replay records -128.
This is a nondefault threshold profile; no default129-element rewrite is claimed.

## Native archive and formal evidence

`reports/reducer-index-replay-v1/` contains48 Scatter runs and27 Gather runs:
75 total, each under no-pass, initialized original-handler or whole-pass mode.
All input and transformed HLO verify. Fourteen runs change values:8 Scatter and
6 Gather. Every expected firing/retention occurs. Public visitor Run priming
suppresses Add/Gather and must leave both status and graph text unchanged before
the original handler is called. Slow HloEvaluator and single-pass mode are explicit.
No private state access, canonical pass edit or compiled-backend execution is used.

`ReducerIndex.lean` retains actual parameter roles and signed literal narrowing.
Eight certificates establish the repeated-role and Gather value failures, the
narrowed literal, and refutations of the model's universal preservation claims.
Thirteen Lean vectors agree with separate Python references and native outputs.
Invalid equality controls are rejected for both actual model computations.

Four general support lemmas provide corrected-statement interventions:

- Distinct parameter roles preserve the single in-bounds update for arbitrary
  vector lengths and word widths, in either Add-parameter order.
- Exact signed representation of every generated position makes the Select-chain
  index equal the clamped original index, for arbitrary extent/word width/index.

These premises are absent from the tested source guards. They are not inserted
into the original obligations to make proofs pass. The Scatter lemmas do not
claim floating reassociation, arbitrary multi-update frames or complete graph
correctness; the Gather lemma concerns the declared signed coordinate model.

## Lean artifact burden and dependencies

| Category | Previous | Added | Current |
| --- | ---: | ---: | ---: |
| S, semantics | 744 | 32 | 776 |
| H, support | 866 | 60 | 926 |
| R, rules | 691 | 0 | 691 |
| A, integration | 32 | 1 | 33 |
| C, certificates | 303 | 34 | 337 |
| Total custom Lean | 2636 | 127 | 2763 |

Preservation laws remain77; shared support lemmas rise86→90. Refutations and
conditional repair lemmas do not inflate accepted source-preservation counts.
Tests/audits and non-Lean native/reference/review/registry work are separate.
The new Scatter certificates use propext; all five Gather certificates have empty
axiom sets. The four generic support lemmas use propext/Quot.sound. Every older
axiom set and stricter certificate gate is preserved; no new axiom/native_decide
is introduced. Source mapping/review effort is visible beyond the Lean count.

## Census progress and limits

The authenticated helper inventory covers all103 non-Handle function IDs and
80 selected helper-origin local edges; together with58 Handle-prefixed bodies,
all161 top-level source function records have independent reading coverage.
Every semantic/interface closure remains explicitly open.

The census-closure report crosswalks all487 frozen schemas and64 selected effect
records. Aliases, shared API contracts and caller/helper duplication must be
reconciled before N/F can be frozen; source reading is not proof closure. The
current source count remains488 after the earlier scaled-probe child.

The new checked source-normalization registry consumes85 arithmetic records,
56 frozen tensor/index records plus that child, and88 shape/layout records:
230 locally inspected source records, including15 delegation aliases, with813
exact excerpt hashes. It records
actual guards, predecessor CONTINUATION requirements, current captures/pointers,
ordered writes and API/status outcomes under declared interface boundaries.
258 current records are not yet locally normalized; canonical alias/family and
global/caller/effect composition remain distinct work. No ratio here is verified
rewrite coverage. Raw JSON review data/excerpts are not Lean proofs and remain
separately archived; exact spans and source bodies are independently rechecked.

The final full checkpoint runs64 tests. Controls reject illicitly strengthening
actual guards, dropping repeated-role profiles, erased value changes/cast result,
missing layout/type/threshold controls, wrong source excerpts, invented predecessor
stages and false source acceptance. Clean replay artifacts are
`reports/reducer-index-clean-replay.json` and `snapshots/reducer-index-pilot-v2.zip`.
The first snapshot/replay is preserved; subsequent metadata normalization/pins
leave all Lean source bytes, counts and statements unchanged.

Accepted source rewrites remain zero. Verified counterexamples are successful
bug detection; they prevent a claim that all original rewrites are correct but
do not show that LLMs plus Lean cannot verify the workload. Remaining source
normalization, canonical census, reviewed pilot, full campaign and representative
residual diagnosis still govern the final research verdict.

The clean Lean archive SHA256 is
`fb82d1a825bdca3ea9227915b82d139e99844f19c51b636c5631331fbe54187d`.
This is proof/model replay; the later source-normalization registry is checked
separately by the checkpoint and is not part of that Lean archive.
