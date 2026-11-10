# Frozen-v1 source-obligation census closure: crosswalk and concrete remainder

Reviewer: human-authorized independent Codex task `census_pilot_review`;
model/config identifiers remain unknown. Date: 10 November 2026. This report
preserves prior reports and makes no actual N/F freeze or source acceptance.

**The remaining census task is source bookkeeping and source-path reconciliation,
not proving every rewrite correct first.** Lean semantics, proof coverage, numeric
observation adoption and a verified C++ extractor are not prerequisites for
counting a clearly defined set of source obligations. A source census may contain
incorrect, unsupported or not-yet-formalized rules. It must accurately say what
the pinned source tries to do, in which contexts, and what it changes.

The frozen 487 rows are not yet such a counted set: caller/helper/API entries
are mixed, ordered outcomes are only partly attached, and one concrete input
path is missing from the nested DynamicSlice description. This report provides
a complete 487-row source-role crosswalk, exact proposed links for all 64 existing
supplementary effect records, a finite source-only correction list, and a
proposed counting/family policy. It does not substitute a new number for N.

## Frozen basis, actual review and what remains unreviewed

Archive SHA256:
`f119335b261a0930a5a2497f5ba3339570d34c5ee6e4baf4a26345cf12b55ce3`;
manifest SHA256:
`da6899931075f018df5d7189c10e8bb87ee4e2560433b2d96e3c1d85f1bdaca4`.
XLA `e58e523b11f1fde802a493a776d158007486e1bf`; pass SHA256
`1ecfd7d4ba958ac0e795d8663c14f7f6b1ebd147a8a83ed0e99661740105628f`.
Unqualified source lines refer to `sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc` in the immutable extracted packet. Schema IDs refer to the ten frozen `census/*-cases.json` batches; API roles and effects refer to `census/replacement-api-paths.json` and `census/nonreplacement-effects.json`. Only extracted v1 inputs were used. The later parent-reported488-row state,
Scatter/Gather native witnesses and scaled-continuation proofs are not adopted
as frozen evidence. A required added child below is inferred from frozen source.

All161 function bodies were read in the previous reports; their proof and API
closure was correctly left open. That statement must NOT be read as requiring
all those proofs before a census freeze. Here I inspected all 487 schema IDs,
owners, guard/RHS/link fields for the crosswalk and compared the identified
path/effect defects with source. I explicitly reconciled the 23 Compare branch
schemas as a bounded example: their actual source guards/output actions are
adequate symbolic enumeration despite the NaN correctness concern. I did NOT
independently normalize every other row into a complete ordered source decision
graph in this turn. The table marks that exact remaining source-normalization
extent; an unflagged row is not a source-closure certificate.

All487 IDs have a site binding and an API-path record. Existing discovery reports
retain zero unmapped executable lexical replacement sites, but this does not
establish source-input graph coverage or proper units. No additional entirely
omitted handler or lexical transformation site was established by this review.
The confirmed source-description omission is the scaled-probe path below;
other listed defects concern output expressions, outcome/frame coverage or
counting/caller composition rather than a newly missing replacement instruction.

## Proposed obligation unit and grouping policy

Count one canonical **source rewrite schema** for a concrete transformation
stage with an actual graph-construction/mutation program and eligibility guard,
parameterized by its captured operands, legal types/shapes/options and loop
indices. Preserve differing source branch/action sequences as child variants;
do not count each rank, width, orientation or loop iteration as a new rule.
Do not merge an entire handler into one rule merely because it is easy to prove
through an interpreter, and do not split cases simply to make proof coverage grow.

Use four registry roles:

- **R:** candidate canonical transformation or explicit finite variant. Resolve
  variants sharing the same source action into a parent rule with an explicit
  discriminant. The 447 R rows below are NOT 447 unique final rules.
- **A:** source call/delegation alias. It contributes caller eligibility, capture
  bindings, prior-stage state and continuation, not a second copy of the callee's
  rule. Recursive HandleBitcast is a source recurrence edge, not infinite rules.
- **G:** shared replacement/constructor/driver/frame contract. Count and audit
  its implementation/Lean support once, and attach it to every applicable rule.
  The four generic API-wrapper rows are G, not independent tensor identities.
- **E:** explicit external transformation call obligation. For the current
  SwapConvolutionOperandsIfBeneficial boundary, either retain one declared
  delegated-call unit with exact call/callback/return behavior, or deliberately
  expand a separately pinned callee before counting its internal rules. Do not
  leave it as an uncounted “helper-dependent graph” alias and claim closed scope.
  A declared opaque E obligation can be enumerated while its proof/model remains
  unsupported; a fully verified external implementation is not a census gate.

The frozen binding labels are 452 replacement /35 delegation. Proposed crosswalk
roles are447 R /35 A /4 G /1 E, after treating HandleReduce/same-element-count as
a caller alias and the convolution swap as E. These are registry-row roles,
not a numerical estimate of N. In particular HandleReduce/same-element-count
must not be counted in addition to ReplaceReduceWithReshape/single and /tuple.

A canonical record needs only source-grounded data, not a completed formal model:
source/function/branch identity; actual entry/capture expressions; ordered source
guards referencing pinned helper bodies; action sequence including loops and
attribute construction; success/skip/error/continue outcomes; caller bindings;
shared effect/API references; source family and original-row lineage. Ordinary
source/helper predicates may remain symbolic with pinned definitions. No need to
inline IEEE arithmetic or prove an invariant merely to describe its source use.

For continuing helpers, use a source decision graph with ordered stage edges,
not a Cartesian product of every possible whole-pass trace. A later rule's entry
bindings refer to the state returned by the earlier stage. Composition correctness
is proved later. Known impossible branches may be marked inapplicable with
source reasoning; unproved reachability must not masquerade as a positive proof.

### Proposed 16 source families

These are a transparent grouping proposal, not a frozen F. Cross-cutting dtype,
layout, effect, dynamic-shape and numerical profiles remain fields/tags. Alias
rows have entry-owner family provenance; the counted rule takes its canonical
callee family's grouping. Thus family numbers below are not proof-family totals.

| Proposed family | Source concern |
| --- | --- |
| F01 | logical / bitwise |
| F02 | elementwise algebra / arithmetic |
| F03 | nonlinear floating / complex |
| F04 | comparison / bounds / minmax |
| F05 | literal / conversion / reinterpretation |
| F06 | logical reshape / axis permutation |
| F07 | broadcast / Iota / shuffle |
| F08 | copy / physical layout / Bitcast |
| F09 | Slice / DynamicSlice / update / Gather |
| F10 | Concat / Pad |
| F11 | Reduce / ReduceWindow / scan / ArgMinMax |
| F12 | Dot contraction / reordering |
| F13 | Convolution / scale movement |
| F14 | tuple / Select / control / higher-order / CustomCall |
| F15 | collective participation / uniform collective |
| F16 | Scatter / Sort structure |

## Concrete source-census correction and normalization list

### C01 — remove caller/helper/API double counting

Reconcile all 35 A rows and four G rows using the role crosswalk. In particular:
HandleReduce/same-element-count is a call to ReplaceReduceWithReshape, not a
third independent rule besides its single/tuple outputs. HandleAllReduce and
HandleReduceScatter instantiate the four shared-handler branches with their
actual opcode/group configuration. HandleBitcast recursion is an edge followed
by further local handling. Use actual typed selected callees and call sites;
a static API endpoint witness is not another source rewrite or a guard path.

### C02 — REQUIRED added input-graph child, from frozen source

HandleDynamicSlice/nested currently describes a direct nested DynamicSlice.
At8328–8330 the failed scaled-Iota probe can leave LOCAL operand pointing through
Multiply(input, Broadcast(scalar)); at8385 the nested test then accepts that
stripped DynamicSlice and8401–8428 remove the scalar. Add a child for the actual
scaled input graph (output rank1/extent1/typeS32/U32, correct operand orientation,
failed Iota test, nested range guards, non-returning earlier conversions), while
preserving the direct-nested child. This is a genuine source-enumeration repair,
not a request for a new Lean proof first. It contributes at least one additional
provisional child to frozen 487; the later live count is not evidence used here.
Keep source IDs/lineage stable; canonical N may group both children only with
an explicit input-shape/capture discriminant and actual differing actions.

### C03 — replace an idealized Gather output with its actual typed chain

HandleGather/small-select-chain says it chooses a “clamped” element. The source
actually constructs successive Selects using `index >= Convert(index_dtype,i)`.
Specify that chain, extent, runtime/config threshold and literal conversion;
do not assume every i is representable. No additional local representability
guard exists. One parametric rule can enumerate all index dtypes/thresholds;
a separate ID for every width is not required. A later correctness witness for
s8/threshold129 diagnoses that rule/profile, not a formerly absent lexical site.
The untested source recipe was supplied in the first large-handler supplement.

### C04 — preserve the actual Scatter reducer pattern, not an Add meaning

HandleAdd/scatter-concat, /scatter-nested, /scatter-single-rhs and /scatter-single-lhs
match Add(Parameter(),Parameter()), without parameter numbers. Capture those
roles explicitly, or retain the exact pinned pattern as the guard. Do not
rewrite it to “the additive reducer” or add a distinct-parameter condition.
Roles00/01/10/11 can be discriminant values of the same source rule, not four
mandatory N entries. Existing dependencies already flag parameter identity;
the source enumeration does not need a native/Lean counterexample to be frozen
once it faithfully records that permissive guard and actual rebuilt computation.

### C05 — Compare's numerical counterexample is NOT an enumeration blocker

All23 HandleCompare rows correspond to actual source branches and retain their
source predicates. GE/LE use IsNonNegative without a non-NaN or fast-math guard
(:5942–5947). A symbolic reference to the pinned helper at540–607 is enough to
enumerate that guard. Expanding its numeric meaning or refuting partial-order
NaN behavior is later correctness work. Do not demand a full IEEE model, a new
NaN child ID or a theorem about IsNonNegative before counting this source rule.
Keep comparison order/type as captured attributes and retain the exact source
order/else-if priority; ordinary ordered-guard normalization remains mechanical
source work, not a kernel-proof gate.

### C06 — retain bad shapes and precondition failures as possible SOURCE outcomes

For HandleReshape/dynamic-update-unit-dims and HandleDynamicSlice/unit-reshape,
record actual update/slice-size arrays and index-slot reads. The source comments
about unit axes do not add missing extent-one guards. A count-changing empty-axis
outcome can be represented in the existing parameterized rule; proving that an
actual pass reaches it is separate from enumerating the action. Direct-helper,
normal postorder and async contexts must be stated when they differ.
TryToReorderSliceAndReshape similarly uses per-axis division after only an
aggregate zero check. Record that operation and its source API precondition;
do not assume all dimensions positive or silently add such a guard. N can contain
a rule whose definedness or output legality fails. No valid-output proof is a
prerequisite for the census.

### C07 — expose the actual Dot list/map operations instead of mathematical names

The mirror-Broadcast rows must preserve original contraction-list order and
`DeleteDimension(from_index-deleted_dims)` at3798–3807, not an abstract safe
“remove contracting axes” operation. AssociativeReorderNestedDot's four outcome
rows must reference the actual value-equality origin selection at3992/4000/4003.
These can remain source algorithm/precondition fields without a new rule for
every list permutation. What is missing is a source-faithful action expression
and explicit conditional failure/outcome, not a proof of the intended algebra.

### C08 — attach attempt/skip/error outcomes after graph construction

Existing cases record returns_even_if_compatibility_fails for Concatenate but
success guards exclude false. Attach rejected-attempt outcomes for filter-many
and adjacent-slice merging, including nodes already allocated and whether the
handler returns. Keep distinct the new-instruction default-false-relay OK skip
in HandleAdd/constant-right, and compatible-existing-node false in Concat.
Include Slice-through-Dot and dot/reduce cost-veto allocations; a final returned
null/false is not proof no nodes were added. Describe helper loops' successful
prefix if a later status fails. These outcomes are variants/shared frame
obligations of the canonical rule, not automatically extra “rewrites” in N.
Choose and document whether allocation/metadata-only transition variants are
counted separately; the choice cannot be driven by proof convenience.

### C09 — encode actual continuation/rebinding, already partly documented

The frozen ScalarMultiplyReduction and promotion rows already note continuation.
Wire those facts into the caller decision graph: scalar movement does not stop
HandleConvolution; incompatible BF16 promotion mutates and writes the caller
pointer then returns false; compatible BF16 returns true without promotion and
stops. Add the caller-pointer write at10977 as source state, not a tensor-edge
write. HandleBitcast's recursive/continuing stages need the same distinction.
The source rows are not absent; their generic “compose previous effects” prose
is not yet an explicit entry-state relation for later stages. No full composite
semantic theorem is required to encode those source edges.

### C10 — replace owner-wide effect links with exact branch/stage links

The64-record crosswalk below supplies concrete proposed links for all 49 call
records and 15 pointer writes. For example recovery at5812 belongs only to
Broadcast/inserted-unit-axes, recovery at10419 only to Transpose/identity, and
embedded computations at9068/9633 only to singleton tuple reduction branches.
Locals such as scratch Shape or new_dnums are not existing-graph mutations;
existing Barrier/Broadcast/RNG fields are. Derived metadata applies to the named
new object and exact branch, not every row owned by the handler.

Add two source effects absent from this selected 49+15 supplement (already
mentioned elsewhere in source case prose): in-place sorting of BOTH outer/inner
Reverse dimension arrays at7235–7236, and pointer-to-pointer convolution
rebinding at10977. Attach them to existing rule/action stages; they are not
missing whole transformations or a reason to add two arbitrary N entries.
Other UpdateLayout calls/implicit reference effects still need source argument
provenance classified where relevant; refer to the existing full-call and
structural-assignment inventories rather than claiming64 records are exhaustive.

### C11 — make the already cataloged external swap boundary count explicitly

API endpoint `call-451193-451362` at10894 is already an
external-convolution-rewrite-boundary. Under the proposed E policy,
HandleConvolution/operand-swap-delegation is the single explicit delegated-call
obligation, with option/layout guards, callback and success/false/error results.
Do not require every backend's swap proof or a verified C++ extractor just to
count it. If the dataset instead claims all internal callee rewrite alternatives
are enumerated, pin/inspect that implementation and expand the boundary. Choose
that SOURCE scope before freezing, rather than switching definitions afterward.

## Source work that does and does not block the freeze

Actual remaining blockers are: adopt the unit/family policy; add C02; correct
source output/capture descriptions C03/C04/C06/C07; normalize ordered caller/
continuation/API outcome graphs C01/C08/C09; apply exact effect provenance C10;
and record the explicit E scope C11. A symbolic guard/action referencing a
pinned helper is sufficient where its source behavior has been inspected; it
need not have a verified semantic implementation.

Not blockers merely for census enumeration: Lean theorem existence; rank-general
proofs; kernel verification of IEEE/layout/effect models; equality of source and
Lean; proving a refutation's native reproduction; minimal Lean LOC; a verified
C++ extractor; or completing a whole-pass correctness theorem. Those govern
proof acceptance/experimental verdict later. A negative or unsupported item stays
in the source census. Existing local identity/reassociation premises from the
HLO operation domain must be declared in applicability; their formal proofs are
not a source-enumeration gate.

I have not completed source decision-graph normalization for the rows marked S
below, nor exhausted all unclassified implicit/external mutation effects. Thus
this review does not itself authorize a freeze. It provides the exact row/effect
work surface and concrete defects, not the assertion that all 447 R variants
have been independently source-certified. “No new defect identified” in a row
is not “all semantic proofs required.”

## Complete487-row crosswalk / exact source-normalization remainder

R/A/G/E have the meanings above. The key is a provisional action/delegation
anchor, NOT a counted canonical unit. Compound action sites and shared helper
APIs still need normalization; raw site equality is not the grouping policy.
V=bounded Compare source-branch reconciliation done (still pending global unit/
API normalization). S=ID/owner/guard-output/link screened but complete ordered
source-normalization not independently finished. All S rows are the exact
remaining normalization list; no missing proof is implied. Family tags on aliases
show entry provenance, not an extra counted canonical family.

| Source ID | Role / proposed family | Provisional source anchor or callee | Source-normalization review | Specific correction refs |
| --- | --- | --- | --- | --- |
| `HandleAnd/lhs-true` | R / F01 | `site-L01519-C026` | S | — |
| `HandleAnd/lhs-zero` | R / F01 | `site-L01534-C024` | S | — |
| `HandleAnd/rhs-true` | R / F01 | `site-L01513-C026` | S | — |
| `HandleAnd/rhs-zero` | R / F01 | `site-L01527-C024` | S | — |
| `HandleOr/lhs-true` | R / F01 | `site-L05452-C026` | S | — |
| `HandleOr/lhs-zero` | R / F01 | `site-L05465-C024` | S | — |
| `HandleOr/rhs-true` | R / F01 | `site-L05446-C026` | S | — |
| `HandleOr/rhs-zero` | R / F01 | `site-L05459-C024` | S | — |
| `HandleNot/involution` | R / F01 | `site-L05430-C007` | S | — |
| `HandleNegate/involution` | R / F02 | `site-L05419-C007` | S | — |
| `HandleXor/equal-inputs` | R / F01 | `site-L05489-C012` | S | — |
| `HandleXor/lhs-zero` | R / F01 | `site-L05500-C024` | S | — |
| `HandleXor/rhs-zero` | R / F01 | `site-L05494-C024` | S | — |
| `TrySimplifyTautologicalCompare/Lt-Lt` | R / F04 | `site-L01298-C026` | S | — |
| `TrySimplifyTautologicalCompare/Lt-Gt` | R / F04 | `site-L01298-C026` | S | — |
| `TrySimplifyTautologicalCompare/Gt-Lt` | R / F04 | `site-L01298-C026` | S | — |
| `TrySimplifyTautologicalCompare/Gt-Gt` | R / F04 | `site-L01298-C026` | S | — |
| `HandleGetTupleElement/tuple-projection` | R / F14 | `site-L05566-C009` | S | — |
| `HandleComplex/components` | R / F03 | `site-L06155-C012` | S | — |
| `HandleReal/complex-projection` | R / F03 | `site-L06164-C012` | S | — |
| `HandleReal/noncomplex` | R / F03 | `site-L06168-C012` | S | — |
| `HandleImag/complex-projection` | R / F03 | `site-L06177-C012` | S | — |
| `HandleImag/noncomplex` | R / F03 | `site-L06181-C012` | S | — |
| `HandleIota/trivial-axis` | R / F07 | `site-L06193-C012` | S | — |
| `HandleExp/zero-scalar` | R / F03 | `site-L06144-C012` | S | — |
| `HandleExp/zero-broadcast` | R / F03 | `site-L06144-C012` | S | — |
| `HandleSubtract/self` | R / F02 | `site-L02461-C014` | S | — |
| `HandleSubtract/zero` | R / F02 | `site-L02466-C024` | S | — |
| `HandleSubtract/constant` | R / F02 | `site-L02482-C012` | S | — |
| `HandleSubtract/broadcast-constant` | R / F02 | `site-L02482-C012` | S | — |
| `HandleSubtract/sub-sub-self` | R / F02 | `site-L02493-C009` | S | — |
| `HandleSubtract/sub-add-self-left` | R / F02 | `site-L02505-C012` | S | — |
| `HandleSubtract/add-sub-self-left` | R / F02 | `site-L02520-C009` | S | — |
| `HandleSubtract/sub-add-self-right` | R / F02 | `site-L02505-C012` | S | — |
| `HandleSubtract/add-sub-self-right` | R / F02 | `site-L02520-C009` | S | — |
| `HandleMultiply/rhs-one` | R / F02 | `site-L05189-C024` | S | — |
| `HandleMultiply/rhs-zero` | R / F02 | `site-L05209-C007` | S | — |
| `HandleMultiply/lhs-one` | R / F02 | `site-L05194-C024` | S | — |
| `HandleMultiply/lhs-zero` | R / F02 | `site-L05202-C007` | S | — |
| `HandleMultiply/negated-operands` | R / F02 | `site-L05218-C038` | S | — |
| `HandleMultiply/abs-square` | R / F02 | `site-L05229-C038` | S | — |
| `HandleMultiply/predicate-convert` | R / F02 | `site-L05247-C014` | S | — |
| `HandleMultiply/four-factors` | R / F02 | `site-L05274-C014` | S | — |
| `HandleMultiply/constant-product` | R / F02 | `site-L05302-C014` | S | — |
| `HandleMultiply/broadcast-factor` | R / F02 | `site-L05338-C016` | S | — |
| `HandleMultiply/legacy-constant-product-direct` | R / F02 | `site-L05368-C012` | S | — |
| `HandleMultiply/legacy-constant-product-broadcast-scalars` | R / F02 | `site-L05368-C012` | S | — |
| `HandleMultiply/exp-product` | R / F02 | `site-L05380-C012` | S | — |
| `HandleMultiply/sqrt-square` | R / F02 | `site-L05394-C012` | S | — |
| `HandleMultiply/rsqrt-square` | R / F02 | `site-L05406-C012` | S | — |
| `HandleMultiply/conv-reorder-delegation` | A / F02 | `TryToReorderConvAddMultiply` | S | C01 |
| `HandleReshape/empty` | R / F06 | `site-L06927-C012` | S | — |
| `HandleReshape/identity` | R / F06 | `site-L06935-C012` | S | — |
| `HandleReshape/compose` | R / F06 | `site-L06941-C012` | S | — |
| `HandleReshape/rng-shape` | R / F06 | `site-L06950-C012` | S | — |
| `HandleReverse/trivial-dimensions` | R / F06 | `site-L07225-C012` | S | — |
| `HandleReverse/cancel` | R / F06 | `site-L07244-C016` | S | C10 |
| `HandleReverse/symmetric-difference` | R / F06 | `site-L07247-C014` | S | C10 |
| `HandleReverse/binary-scalar-0` | R / F06 | `site-L07271-C016` | S | — |
| `HandleReverse/binary-scalar-1` | R / F06 | `site-L07280-C016` | S | — |
| `HandleReverse/inserted-unit-dimensions` | R / F06 | `site-L07313-C016` | S | — |
| `HandleSlice/identity` | R / F09 | `site-L07657-C007` | S | — |
| `HandleSlice/padding-only` | R / F09 | `site-L07703-C014` | S | — |
| `HandleSlice/undo-pad` | R / F09 | `site-L07706-C009` | S | — |
| `HandleSlice/inside-pad` | R / F09 | `site-L07714-C014` | S | — |
| `HandleTranspose/identity` | R / F06 | `site-L10421-C012` | S | C10 |
| `HandleTranspose/compose` | R / F06 | `site-L10425-C012` | S | — |
| `HandleReshape/copy-reorder` | R / F08 | `site-L07076-C020` | S | — |
| `HandleReshape/broadcast` | R / F06 | `site-L07089-C014` | S | — |
| `HandleReshape/iota-mixed-radix` | R / F06 | `site-L07136-C014` | S | — |
| `HandleReshape/dynamic-update-unit-dims` | R / F06 | `site-L07186-C014` | S | C06 |
| `HandleReshape/bitcast-chain` | R / F08 | `site-L07195-C005` | S | — |
| `HandleReshape/transpose-chain-delegation` | A / F06 | `TryRemovingBitcastOrReshapeTransposeChain` | S | C01 |
| `HandleReshape/transpose-hoist-delegation` | A / F06 | `TryHoistTransposeOfReshape` | S | C01 |
| `TryRemovingBitcastOrReshapeTransposeChain/layout-identity` | R / F06 | `site-L06834-C032` | S | — |
| `TryRemovingBitcastOrReshapeTransposeChain/layout-bitcast` | R / F06 | `site-L06844-C032` | S | — |
| `TryRemovingBitcastOrReshapeTransposeChain/logical-identity` | R / F06 | `site-L06852-C032` | S | — |
| `TryHoistTransposeOfReshape/contiguous-chunks` | R / F06 | `site-L06905-C024` | S | — |
| `HandleSlice/exact-dynamic-update` | R / F09 | `site-L07767-C013` | S | — |
| `HandleSlice/inside-dynamic-update` | R / F09 | `site-L07777-C018` | S | — |
| `HandleSlice/compose-unstrided` | R / F09 | `site-L07793-C012` | S | — |
| `HandleSlice/broadcast-only-dims` | R / F09 | `site-L07813-C012` | S | — |
| `HandleSlice/broadcast-sink` | R / F09 | `site-L07860-C012` | S | — |
| `HandleSlice/dot-operands` | R / F09 | `site-L07947-C014` | S | C08 |
| `HandleSlice/concat-exact-piece` | R / F09 | `site-L07981-C014` | S | — |
| `HandleSlice/concat-subrange-single` | R / F09 | `site-L08005-C014` | S | — |
| `HandleSlice/concat-subrange-multi` | R / F09 | `site-L08005-C014` | S | — |
| `HandleSlice/reduce-window` | R / F09 | `site-L08088-C014` | S | — |
| `HandleSlice/scalar-slice-delegation` | A / F09 | `TrySimplifyScalarSlice` | S | C01 |
| `HandleSlice/reshape-reorder-delegation` | A / F09 | `TryToReorderSliceAndReshape` | S | C01 |
| `HandleSlice/reverse-reorder-delegation` | A / F09 | `TryToReorderSliceAndReverse` | S | C01 |
| `HandleSlice/stride-delegation` | A / F09 | `RemoveRedundantStride` | S | C01 |
| `HandleTranspose/dot-canonical` | R / F06 | `site-L10494-C026` | S | — |
| `HandleTranspose/dot-general` | R / F06 | `site-L10563-C016` | S | — |
| `HandleTranspose/degenerate-reshape` | R / F06 | `site-L10574-C012` | S | — |
| `HandleTranspose/rng-shape` | R / F06 | `site-L10581-C012` | S | — |
| `HandleTranspose/layout-bitcast` | R / F08 | `site-L10585-C005` | S | — |
| `HandleTranspose/space-depth-user-mutation` | R / F06 | `site-L10733-C030` | S | — |
| `HandleTranspose/scatter-fold-delegation` | A / F06 | `TryFoldTransposeIntoScatter` | S | C01 |
| `HandleTranspose/chain-delegation` | A / F06 | `TryRemovingBitcastOrReshapeTransposeChain` | S | C01 |
| `HandleTranspose/broadcast-delegation` | A / F06 | `SimplifyTransposeOfBroadcast` | S | C01 |
| `TrySimplifyScalarSlice/concat-piece` | R / F09 | `site-L07436-C021` | S | — |
| `TrySimplifyScalarSlice/concat-slice` | R / F09 | `site-L07442-C028` | S | — |
| `TryToReorderSliceAndReshape/leading-slice` | R / F09 | `site-L07563-C026` | S | C06 |
| `TryToReorderSliceAndReverse/commute` | R / F09 | `site-L07605-C026` | S | — |
| `RemoveRedundantStride/single-element-axes` | R / F09 | `site-L07648-C024` | S | — |
| `TryFoldTransposeIntoScatter/simplified-scatter` | R / F16 | `site-L10403-C007` | S | — |
| `SimplifyTransposeOfBroadcast/mapped-dims-logical` | R / F07 | `site-L02946-C010` | S | — |
| `SimplifyTransposeOfBroadcast/mapped-dims-layout` | R / F07 | `site-L02946-C010` | S | — |
| `HandleAbs/nonnegative` | R / F03 | `site-L00921-C012` | S | — |
| `HandleClamp/idempotent` | R / F04 | `site-L05111-C007` | S | — |
| `HandleClamp/runtime-id` | R / F04 | `site-L05131-C014` | S | — |
| `HandleLog/exp` | R / F03 | `site-L05512-C007` | S | — |
| `HandleLog/power-real` | R / F03 | `site-L05533-C012` | S | — |
| `HandleLog/power-complex` | R / F03 | `site-L05533-C012` | S | — |
| `HandleLog/sqrt` | R / F03 | `site-L05542-C012` | S | — |
| `HandleLog/rsqrt` | R / F03 | `site-L05550-C012` | S | — |
| `HandleConvert/same-type` | R / F05 | `site-L06061-C012` | S | — |
| `HandleConvert/noop-pair` | R / F05 | `site-L06076-C012` | S | — |
| `HandleConvert/constant-fold` | R / F05 | `site-L06092-C012` | S | — |
| `HandleConvert/binary-surround-delegation` | A / F05 | `TryRemoveUpcastAndDowncastSurroundingBinaryOp` | S | C01 |
| `HandleCustomCall/dynamic-roundtrip-raw-size` | R / F14 | `site-L06123-C014` | S | — |
| `HandleCustomCall/dynamic-roundtrip-clamped-size` | R / F14 | `site-L06123-C014` | S | — |
| `HandleCustomCall/layout-identity` | R / F14 | `site-L06129-C014` | S | — |
| `HandleCustomCall/layout-copy` | R / F14 | `site-L06131-C012` | S | — |
| `HandlePower/zero` | R / F02 | `site-L06410-C012` | S | — |
| `HandlePower/one` | R / F02 | `site-L06414-C024` | S | — |
| `HandlePower/exp-base` | R / F02 | `site-L06424-C012` | S | — |
| `HandlePower/two` | R / F02 | `site-L06431-C012` | S | — |
| `HandlePower/three` | R / F02 | `site-L06441-C012` | S | — |
| `HandlePower/minus-one` | R / F02 | `site-L06448-C012` | S | — |
| `HandlePower/half` | R / F02 | `site-L06456-C012` | S | — |
| `HandleRsqrt/inverse-square` | R / F03 | `site-L08126-C012` | S | — |
| `HandleRsqrt/reciprocal` | R / F03 | `site-L08134-C012` | S | — |
| `HandleReducePrecision/full-width` | R / F03 | `site-L09563-C012` | S | — |
| `HandleSelect/equal-values` | R / F14 | `site-L10118-C007` | S | — |
| `HandleSelect/true` | R / F14 | `site-L10123-C007` | S | — |
| `HandleSelect/false` | R / F14 | `site-L10128-C007` | S | — |
| `HandleSelect/not-predicate` | R / F14 | `site-L10136-C012` | S | — |
| `HandleSelect/true-false-direct` | R / F14 | `site-L10160-C014` | S | — |
| `HandleSelect/true-false-broadcast` | R / F14 | `site-L10160-C014` | S | — |
| `HandleSelect/false-true-direct` | R / F14 | `site-L10160-C014` | S | — |
| `HandleSelect/false-true-broadcast` | R / F14 | `site-L10160-C014` | S | — |
| `HandleSelect/boolean-compare-gt` | R / F14 | `site-L10172-C016` | S | — |
| `HandleSelect/boolean-compare-ge` | R / F14 | `site-L10172-C016` | S | — |
| `HandleSelect/boolean-compare-lt` | R / F14 | `site-L10178-C016` | S | — |
| `HandleSelect/boolean-compare-le` | R / F14 | `site-L10178-C016` | S | — |
| `HandleSelect/boolean-compare-eq` | R / F14 | `site-L10183-C016` | S | — |
| `HandleSelect/boolean-compare-ne` | R / F14 | `site-L10186-C016` | S | — |
| `HandleSelect/update-false-tensor-pred` | R / F14 | `site-L10231-C012` | S | — |
| `HandleSelect/update-false-scalar-pred` | R / F14 | `site-L10231-C012` | S | — |
| `HandleSelect/update-true-tensor-pred` | R / F14 | `site-L10231-C012` | S | — |
| `HandleSelect/update-true-scalar-pred` | R / F14 | `site-L10231-C012` | S | — |
| `HandleScatter/empty-updates` | R / F16 | `site-L10244-C007` | S | — |
| `HandleScatter/empty-indices` | R / F16 | `site-L10251-C012` | S | — |
| `HandleSort/trivial-single` | R / F16 | `site-L10266-C014` | S | — |
| `HandleSort/trivial-tuple` | R / F16 | `site-L10269-C012` | S | — |
| `HandleSqrt/square-complex` | R / F03 | `site-L10294-C014` | S | — |
| `HandleSqrt/square-real` | R / F03 | `site-L10297-C012` | S | — |
| `HandleMap/parameter-root` | R / F14 | `site-L11282-C005` | S | — |
| `HandleMap/constant-root-scalar` | R / F14 | `site-L11292-C014` | S | — |
| `HandleMap/constant-root-broadcast` | R / F14 | `site-L11294-C012` | S | — |
| `HandleMap/elementwise-root` | R / F14 | `site-L11312-C010` | S | — |
| `HandleConditional/predicate-convert` | R / F14 | `site-L11356-C012` | S | — |
| `HandleAdd/rhs-zero` | R / F02 | `site-L00932-C024` | S | — |
| `HandleAdd/lhs-zero` | R / F02 | `site-L00937-C024` | S | — |
| `HandleAdd/constant-right` | R / F02 | `site-L00945-C012` | S | C08 |
| `HandleAdd/constant-sum-direct-constants` | R / F02 | `site-L00973-C012` | S | — |
| `HandleAdd/constant-subtract-direct-constants` | R / F02 | `site-L00994-C012` | S | — |
| `HandleAdd/constant-sum-broadcast-scalars` | R / F02 | `site-L00973-C012` | S | — |
| `HandleAdd/constant-subtract-broadcast-scalars` | R / F02 | `site-L00994-C012` | S | — |
| `HandleAdd/cancel-subtract-lhs` | R / F02 | `site-L01008-C009` | S | — |
| `HandleAdd/partial-update-lhs` | R / F02 | `site-L01051-C012` | S | — |
| `HandleAdd/cancel-subtract-rhs` | R / F02 | `site-L01008-C009` | S | — |
| `HandleAdd/partial-update-rhs` | R / F02 | `site-L01051-C012` | S | — |
| `HandleAdd/factor-lhs-lhs` | R / F02 | `site-L01087-C012` | S | — |
| `HandleAdd/factor-lhs-rhs` | R / F02 | `site-L01087-C012` | S | — |
| `HandleAdd/factor-rhs-lhs` | R / F02 | `site-L01087-C012` | S | — |
| `HandleAdd/factor-rhs-rhs` | R / F02 | `site-L01087-C012` | S | — |
| `HandleAdd/scatter-concat` | R / F02 | `site-L01237-C014` | S | C04 |
| `HandleAdd/scatter-nested` | R / F02 | `site-L01245-C031` | S | C04 |
| `HandleAdd/scatter-single-rhs` | R / F02 | `site-L01252-C031` | S | C04 |
| `HandleAdd/scatter-single-lhs` | R / F02 | `site-L01258-C031` | S | C04 |
| `HandleDivide/one` | R / F02 | `site-L02597-C022` | S | — |
| `HandleDivide/power-two-unsigned` | R / F02 | `site-L02613-C012` | S | — |
| `HandleDivide/power-two-signed` | R / F02 | `site-L02613-C012` | S | — |
| `HandleDivide/exp-pair` | R / F02 | `site-L02624-C012` | S | — |
| `HandleDivide/exp-denominator` | R / F02 | `site-L02636-C012` | S | — |
| `HandleDivide/power-denominator` | R / F02 | `site-L02656-C012` | S | — |
| `HandleDivide/sqrt-denominator` | R / F02 | `site-L02665-C012` | S | — |
| `HandleDivide/rsqrt-denominator` | R / F02 | `site-L02674-C012` | S | — |
| `HandleDivide/constant-direct` | R / F02 | `site-L02711-C020` | S | — |
| `HandleDivide/constant-broadcast` | R / F02 | `site-L02711-C020` | S | — |
| `HandleDivide/broadcast-reciprocal` | R / F02 | `site-L02736-C012` | S | — |
| `HandleDivide/fractions` | R / F02 | `site-L02751-C012` | S | — |
| `HandleDivide/nested-numerator` | R / F02 | `site-L02760-C012` | S | — |
| `HandleDivide/nested-denominator` | R / F02 | `site-L02769-C012` | S | — |
| `HandleDivide/predicate-scalar-broadcast` | R / F02 | `site-L02785-C012` | S | — |
| `HandleMaximum/self` | R / F04 | `site-L04928-C012` | S | — |
| `HandleMaximum/lhs-extreme` | R / F04 | `site-L04942-C014` | S | — |
| `HandleMaximum/rhs-extreme` | R / F04 | `site-L04946-C014` | S | — |
| `HandleMaximum/nested-left-lhs` | R / F04 | `site-L04953-C012` | S | — |
| `HandleMaximum/nested-left-rhs` | R / F04 | `site-L04953-C012` | S | — |
| `HandleMaximum/nested-right-first` | R / F04 | `site-L04957-C012` | S | — |
| `HandleMaximum/nested-right-second` | R / F04 | `site-L04964-C018` | S | — |
| `HandleMaximum/clamp-lhs-lhs` | R / F04 | `site-L04983-C014` | S | — |
| `HandleMaximum/clamp-lhs-rhs` | R / F04 | `site-L04983-C014` | S | — |
| `HandleMaximum/clamp-rhs-lhs` | R / F04 | `site-L04983-C014` | S | — |
| `HandleMaximum/clamp-rhs-rhs` | R / F04 | `site-L04983-C014` | S | — |
| `HandleMinimum/self` | R / F04 | `site-L05039-C012` | S | — |
| `HandleMinimum/lhs-extreme` | R / F04 | `site-L05053-C014` | S | — |
| `HandleMinimum/rhs-extreme` | R / F04 | `site-L05057-C014` | S | — |
| `HandleMinimum/nested-left-lhs` | R / F04 | `site-L05064-C012` | S | — |
| `HandleMinimum/nested-left-rhs` | R / F04 | `site-L05064-C012` | S | — |
| `HandleMinimum/nested-right-first` | R / F04 | `site-L05068-C012` | S | — |
| `HandleMinimum/nested-right-second` | R / F04 | `site-L05075-C018` | S | — |
| `HandleMinimum/clamp-lhs-lhs` | R / F04 | `site-L05094-C014` | S | — |
| `HandleMinimum/clamp-lhs-rhs` | R / F04 | `site-L05094-C014` | S | — |
| `HandleMinimum/clamp-rhs-lhs` | R / F04 | `site-L05094-C014` | S | — |
| `HandleMinimum/clamp-rhs-rhs` | R / F04 | `site-L05094-C014` | S | — |
| `HandleMaximum/clamp-lower-lhs` | R / F04 | `site-L04997-C009` | S | — |
| `HandleMaximum/clamp-lower-rhs` | R / F04 | `site-L04997-C009` | S | — |
| `HandleMaximum/sink-cbrt` | R / F04 | `site-L05024-C012` | S | — |
| `HandleMaximum/sink-erf` | R / F04 | `site-L05024-C012` | S | — |
| `HandleMaximum/sink-logistic` | R / F04 | `site-L05024-C012` | S | — |
| `HandleMaximum/sink-tanh` | R / F04 | `site-L05024-C012` | S | — |
| `HandleCompare/unsigned-lt-zero` | R / F04 | `site-L05917-C014` | V | — |
| `HandleCompare/unsigned-ge-zero` | R / F04 | `site-L05922-C014` | V | — |
| `HandleCompare/unsigned-zero-gt` | R / F04 | `site-L05927-C014` | V | — |
| `HandleCompare/unsigned-zero-le` | R / F04 | `site-L05932-C014` | V | — |
| `HandleCompare/nonnegative-lt` | R / F04 | `site-L05938-C012` | V | C05 |
| `HandleCompare/nonnegative-gt` | R / F04 | `site-L05941-C012` | V | C05 |
| `HandleCompare/nonnegative-ge` | R / F04 | `site-L05944-C012` | V | C05 |
| `HandleCompare/nonnegative-le` | R / F04 | `site-L05947-C012` | V | C05 |
| `HandleCompare/integral-self-gt` | R / F04 | `site-L05955-C016` | V | — |
| `HandleCompare/integral-self-lt` | R / F04 | `site-L05955-C016` | V | — |
| `HandleCompare/integral-self-ne` | R / F04 | `site-L05955-C016` | V | — |
| `HandleCompare/integral-self-eq` | R / F04 | `site-L05959-C016` | V | — |
| `HandleCompare/integral-self-ge` | R / F04 | `site-L05959-C016` | V | — |
| `HandleCompare/integral-self-le` | R / F04 | `site-L05959-C016` | V | — |
| `HandleCompare/predicate-ne-rhs` | R / F04 | `site-L05967-C016` | V | — |
| `HandleCompare/predicate-ne-lhs` | R / F04 | `site-L05971-C016` | V | — |
| `HandleCompare/predicate-eq-rhs` | R / F04 | `site-L05976-C016` | V | — |
| `HandleCompare/predicate-eq-lhs` | R / F04 | `site-L05980-C016` | V | — |
| `HandleCompare/causal-mask` | R / F04 | `site-L06016-C014` | V | — |
| `HandleCompare/maximum-first` | R / F04 | `site-L06029-C039` | V | — |
| `HandleCompare/maximum-second` | R / F04 | `site-L06033-C039` | V | — |
| `HandleCompare/minimum-first` | R / F04 | `site-L06039-C039` | V | — |
| `HandleCompare/minimum-second` | R / F04 | `site-L06043-C039` | V | — |
| `HandleBitcast/unary-sandwich` | R / F08 | `site-L01585-C012` | S | C09 |
| `HandleBitcast/compose-stage` | R / F08 | `site-L01599-C009` | S | C09 |
| `HandleBitcast/compatible-stage` | R / F08 | `site-L01610-C007` | S | C09 |
| `HandleBitcast/recursive-inner` | A / F08 | `HandleBitcast` | S | C01,C09 |
| `HandleBitcast/chain-delegation` | A / F08 | `TryRemovingBitcastOrReshapeTransposeChain` | S | C01,C09 |
| `HandleBitcast/broadcast-delegation` | A / F08 | `SimplifyTransposeOfBroadcast` | S | C01,C09 |
| `HandleBitcastConvert/compose` | R / F05 | `site-L01905-C012` | S | — |
| `HandleBitcastConvert/concat-delegation` | A / F05 | `TrySimplifyTautologicalBitcastConvert` | S | C01 |
| `HandleBitcastConvert/same-physical-shape` | R / F05 | `site-L01923-C007` | S | — |
| `HandleBitcastConvert/last-contiguous-axis` | R / F05 | `site-L01946-C007` | S | — |
| `HandleBitcastConvert/compatible` | R / F05 | `site-L01952-C003` | S | — |
| `HandleCopy/swap-delegation` | A / F08 | `SwapCopyBitcastCopy` | S | C01 |
| `HandleCopy/compose-identity` | R / F08 | `site-L01964-C014` | S | — |
| `HandleCopy/compose-copy` | R / F08 | `site-L01966-C012` | S | — |
| `HandleCopy/compatible` | R / F08 | `site-L01972-C007` | S | — |
| `HandleCopy/chain-bitcast` | R / F08 | `site-L01986-C007` | S | — |
| `HandleCopy/reshape-clone` | R / F08 | `site-L02000-C012` | S | — |
| `HandleCopy/reshape-reorder-new-copy-reshape` | R / F08 | `site-L02094-C018` | S | — |
| `HandleCopy/reshape-reorder-new-copy-bitcast` | R / F08 | `site-L02094-C018` | S | — |
| `HandleCopy/reshape-reorder-omit-copy-reshape` | R / F08 | `site-L02094-C018` | S | — |
| `HandleCopy/reshape-reorder-omit-copy-bitcast` | R / F08 | `site-L02094-C018` | S | — |
| `SwapCopyBitcastCopy/move-bitcast` | R / F08 | `site-L01877-C014` | S | — |
| `SwapCopyBitcastCopy/move-copy` | R / F08 | `site-L01893-C014` | S | — |
| `TrySimplifyTautologicalBitcastConvert/concat` | R / F05 | `site-L02309-C024` | S | — |
| `HandleConstant/tuple` | R / F05 | `site-L02412-C012` | S | — |
| `HandleConstant/uniform` | R / F05 | `site-L02430-C012` | S | — |
| `HandleConstant/iota` | R / F05 | `site-L02436-C012` | S | — |
| `HandleConstant/strided-iota` | R / F05 | `site-L02445-C012` | S | — |
| `HandleOptimizationBarrier/prune-producer` | R / F14 | `site-L05641-C016` | S | C10 |
| `HandleOptimizationBarrier/prune-tuple` | R / F14 | `site-L05641-C016` | S | C10 |
| `HandleAllGather/uniform` | R / F15 | `site-L01413-C010` | S | — |
| `HandleAllToAll/uniform` | R / F15 | `site-L01426-C010` | S | — |
| `HandleAllReduceOrReduceScatter/min` | R / F15 | `site-L01449-C014` | S | — |
| `HandleAllReduceOrReduceScatter/max` | R / F15 | `site-L01449-C014` | S | — |
| `HandleAllReduceOrReduceScatter/sum-integral` | R / F15 | `site-L01483-C014` | S | — |
| `HandleAllReduceOrReduceScatter/sum-floating` | R / F15 | `site-L01483-C014` | S | — |
| `HandleAllReduce/shared-handler` | A / F15 | `HandleAllReduceOrReduceScatter` | S | C01 |
| `HandleReduceScatter/shared-handler` | A / F15 | `HandleAllReduceOrReduceScatter` | S | C01 |
| `HandleRemainder/nested` | R / F02 | `site-L06621-C012` | S | — |
| `HandleRemainder/power-two-unsigned` | R / F02 | `site-L06636-C012` | S | — |
| `HandleRemainder/power-two-signed` | R / F02 | `site-L06636-C012` | S | — |
| `HandleRemainder/iota-in-range` | R / F02 | `site-L06660-C014` | S | — |
| `HandleRemainder/iota-add-lhs` | R / F02 | `site-L06695-C016` | S | — |
| `HandleRemainder/iota-add-rhs` | R / F02 | `site-L06695-C016` | S | — |
| `HandleShuffle/rotate-identity` | R / F07 | `site-L07386-C016` | S | — |
| `HandleShuffle/rotate-canonical` | R / F07 | `site-L07394-C016` | S | — |
| `TryToSinkBroadcastAfterElementwiseOps/eligible-user` | R / F07 | `site-L06544-C032` | S | C08 |
| `HandleConcatenate/unary` | R / F10 | `site-L02108-C005` | S | — |
| `HandleConcatenate/filter-all-empty` | R / F10 | `site-L02131-C005` | S | — |
| `HandleConcatenate/filter-one-nonempty` | R / F10 | `site-L02131-C005` | S | — |
| `HandleConcatenate/filter-many-nonempty` | R / F10 | `site-L02131-C005` | S | C08 |
| `HandleConcatenate/flatten` | R / F10 | `site-L02156-C012` | S | — |
| `HandleConcatenate/adjacent-slices` | R / F10 | `site-L02227-C005` | S | C08 |
| `HandleConcatenate/pad-low` | R / F10 | `site-L02262-C014` | S | — |
| `HandleConcatenate/pad-high` | R / F10 | `site-L02262-C014` | S | — |
| `HandleConcatenate/repeat-unit-axis` | R / F10 | `site-L02277-C012` | S | — |
| `HandleBroadcast/reshape` | R / F07 | `site-L05782-C012` | S | — |
| `HandleBroadcast/transpose` | R / F07 | `site-L05792-C012` | S | — |
| `HandleBroadcast/inserted-unit-axes` | R / F07 | `site-L05822-C014` | S | C10 |
| `HandleBroadcast/sink-users-delegation` | A / F07 | `TryToSinkBroadcastAfterElementwiseOps` | S | C01 |
| `HandleBroadcast/scalar-user-reshape` | R / F07 | `site-L05859-C022` | S | — |
| `HandleBroadcast/scalar-user-reverse` | R / F07 | `site-L05859-C022` | S | — |
| `HandleBroadcast/scalar-user-transpose` | R / F07 | `site-L05859-C022` | S | — |
| `HandleBroadcast/scalar-user-sort` | R / F07 | `site-L05859-C022` | S | — |
| `HandleBroadcast/scalar-user-slice` | R / F07 | `site-L05859-C022` | S | — |
| `HandleBroadcast/scalar-user-dynamicslice` | R / F07 | `site-L05859-C022` | S | — |
| `HandleBroadcast/iota` | R / F07 | `site-L05867-C012` | S | — |
| `HandleBroadcast/compose` | R / F07 | `site-L05881-C012` | S | — |
| `HandleBroadcast/drop-unit-axes` | R / F07 | `site-L05900-C012` | S | — |
| `HandlePad/empty-input` | R / F10 | `site-L06200-C012` | S | — |
| `HandlePad/unit-interior` | R / F10 | `site-L06218-C014` | S | — |
| `HandlePad/compatible` | R / F10 | `site-L06248-C009` | S | — |
| `HandlePad/broadcast-projection` | R / F10 | `site-L06325-C014` | S | C10 |
| `HandlePad/negative-edges` | R / F10 | `site-L06399-C012` | S | — |
| `HandleDynamicSlice/scalar` | R / F09 | `site-L08150-C012` | S | — |
| `HandleDynamicSlice/same-shape` | R / F09 | `site-L08155-C012` | S | — |
| `HandleDynamicSlice/zero-full-axis-indices` | R / F09 | `site-L08175-C012` | S | — |
| `HandleDynamicSlice/broadcast-scalar` | R / F09 | `site-L08213-C012` | S | — |
| `HandleDynamicSlice/broadcast-array` | R / F09 | `site-L08213-C012` | S | — |
| `HandleDynamicSlice/unit-reshape` | R / F09 | `site-L08239-C012` | S | C06 |
| `HandleDynamicSlice/transpose` | R / F09 | `site-L08257-C012` | S | — |
| `HandleDynamicSlice/constant-indices` | R / F09 | `site-L08297-C012` | S | — |
| `HandleDynamicSlice/iota-plain-same-type` | R / F09 | `site-L08375-C016` | S | — |
| `HandleDynamicSlice/iota-plain-convert` | R / F09 | `site-L08375-C016` | S | — |
| `HandleDynamicSlice/iota-scaled-same-type` | R / F09 | `site-L08375-C016` | S | — |
| `HandleDynamicSlice/iota-scaled-convert` | R / F09 | `site-L08375-C016` | S | — |
| `HandleDynamicSlice/nested` | R / F09 | `site-L08401-C041` | S | C02 |
| `HandleDynamicUpdateSlice/pad-scalar-list` | R / F09 | `site-L08539-C014` | S | — |
| `HandleDynamicUpdateSlice/pad-tuple` | R / F09 | `site-L08539-C014` | S | — |
| `HandleDynamicUpdateSlice/pad-concatenate` | R / F09 | `site-L08539-C014` | S | — |
| `HandleDynamicUpdateSlice/full-update` | R / F09 | `site-L08546-C012` | S | — |
| `HandleDynamicUpdateSlice/pad-concat-high` | R / F09 | `site-L08635-C018` | S | — |
| `HandleDynamicUpdateSlice/pad-concat-low` | R / F09 | `site-L08635-C018` | S | — |
| `HandleDynamicUpdateSlice/zero-full-axis-indices` | R / F09 | `site-L08659-C012` | S | — |
| `HandleDynamicUpdateSlice/empty-update` | R / F09 | `site-L08670-C012` | S | — |
| `HandleDynamicUpdateSlice/nested` | R / F09 | `site-L08699-C048` | S | — |
| `HandleGather/empty-input` | R / F09 | `site-L04637-C012` | S | — |
| `HandleGather/effective-scalar-rank-zero` | R / F09 | `site-L04651-C012` | S | — |
| `HandleGather/effective-scalar-unit-array` | R / F09 | `site-L04651-C012` | S | — |
| `HandleGather/small-select-chain` | R / F09 | `site-L04686-C012` | S | C03 |
| `HandleGather/pad-hoist-passthrough` | R / F09 | `site-L04761-C014` | S | — |
| `HandleGather/pad-hoist-batching` | R / F09 | `site-L04761-C014` | S | — |
| `HandleGather/reshape-pad-hoist` | R / F09 | `site-L04853-C016` | S | — |
| `HandleReduce/empty-delegation` | A / F11 | `BroadcastReduce` | S | C01 |
| `HandleReduce/singleton-tuple` | R / F11 | `site-L09069-C019` | S | C10 |
| `HandleReduce/same-element-count` | A / F11 | `ReplaceReduceWithReshape/{single,tuple}` | S | C01 |
| `HandleReduce/negate-sum` | R / F11 | `site-L09103-C034` | S | — |
| `HandleReduce/argmin-constant` | R / F11 | `site-L09134-C014` | S | — |
| `HandleReduce/argmax-constant` | R / F11 | `site-L09134-C014` | S | — |
| `HandleReduce/dot-reorder-delegation` | A / F11 | `ReorderReduceDotToDotReduce` | S | C01,C08 |
| `HandleReduce/transpose-sorted` | R / F11 | `site-L09183-C014` | S | — |
| `HandleReduce/transpose-permute-result` | R / F11 | `site-L09196-C012` | S | — |
| `HandleReduce/merge-delegation` | A / F11 | `MergeReduces` | S | C01 |
| `HandleReduce/reshape-reduced-axes` | R / F11 | `site-L09260-C014` | S | — |
| `HandleReduce/reshape-output-axes` | R / F11 | `site-L09287-C014` | S | — |
| `HandleReduce/concat` | R / F11 | `site-L09323-C014` | S | — |
| `HandleReduce/dot-batch-all-batch` | R / F11 | `site-L09371-C014` | S | — |
| `HandleReduce/dot-batch-residual-reduce` | R / F11 | `site-L09377-C012` | S | — |
| `HandleReduce/reuse-argmax` | R / F11 | `site-L09394-C014` | S | — |
| `HandleReduce/reuse-argmin` | R / F11 | `site-L09414-C014` | S | — |
| `HandleReduce/scalar-broadcast-maximum` | R / F11 | `site-L09435-C014` | S | — |
| `HandleReduce/scalar-broadcast-minimum` | R / F11 | `site-L09435-C014` | S | — |
| `HandleReduce/scalar-broadcast-and` | R / F11 | `site-L09435-C014` | S | — |
| `HandleReduce/scalar-broadcast-or` | R / F11 | `site-L09435-C014` | S | — |
| `HandleReduce/broadcast-base-axes` | R / F11 | `site-L09490-C014` | S | — |
| `HandleReduce/broadcast-replicated-axes` | R / F11 | `site-L09543-C014` | S | — |
| `BroadcastReduce/tuple` | R / F11 | `site-L08871-C012` | S | — |
| `ReplaceReduceWithReshape/tuple` | R / F11 | `site-L08894-C012` | S | — |
| `BroadcastReduce/single` | R / F11 | `site-L08875-C010` | S | — |
| `ReplaceReduceWithReshape/single` | R / F11 | `site-L08898-C010` | S | — |
| `MergeReduces/combined-axes` | R / F11 | `site-L09038-C010` | S | — |
| `ReorderReduceDotToDotReduce/profitable` | R / F11 | `site-L09007-C016` | S | — |
| `HandleReduceWindow/empty-tuple` | R / F11 | `site-L09582-C014` | S | — |
| `HandleReduceWindow/empty-single` | R / F11 | `site-L09585-C012` | S | — |
| `HandleReduceWindow/scalar-tuple` | R / F11 | `site-L09582-C014` | S | — |
| `HandleReduceWindow/scalar-single` | R / F11 | `site-L09585-C012` | S | — |
| `HandleReduceWindow/singleton-tuple` | R / F11 | `site-L09634-C036` | S | C10 |
| `HandleReduceWindow/cumsum-i64-canonicalize-literal` | R / F11 | `site-L09775-C014` | S | — |
| `HandleReduceWindow/cumsum-i64-reuse-literal` | R / F11 | `site-L09775-C014` | S | — |
| `HandleReduceWindow/cumsum-i32-canonicalize-literal` | R / F11 | `site-L09775-C014` | S | — |
| `HandleReduceWindow/cumsum-i32-reuse-literal` | R / F11 | `site-L09775-C014` | S | — |
| `HandleReduceWindow/singleton-crop-all-add` | R / F11 | `site-L09837-C018` | S | — |
| `HandleReduceWindow/singleton-add-no-pad-no-crop` | R / F11 | `site-L09868-C012` | S | — |
| `HandleReduceWindow/singleton-add-no-pad-crop` | R / F11 | `site-L09868-C012` | S | — |
| `HandleReduceWindow/singleton-add-pad-no-crop` | R / F11 | `site-L09868-C012` | S | — |
| `HandleReduceWindow/singleton-add-pad-crop` | R / F11 | `site-L09868-C012` | S | — |
| `HandleReduceWindow/singleton-crop-all-minimum` | R / F11 | `site-L09837-C018` | S | — |
| `HandleReduceWindow/singleton-minimum-no-pad-no-crop` | R / F11 | `site-L09868-C012` | S | — |
| `HandleReduceWindow/singleton-minimum-no-pad-crop` | R / F11 | `site-L09868-C012` | S | — |
| `HandleReduceWindow/singleton-minimum-pad-no-crop` | R / F11 | `site-L09868-C012` | S | — |
| `HandleReduceWindow/singleton-minimum-pad-crop` | R / F11 | `site-L09868-C012` | S | — |
| `HandleReduceWindow/singleton-crop-all-maximum` | R / F11 | `site-L09837-C018` | S | — |
| `HandleReduceWindow/singleton-maximum-no-pad-no-crop` | R / F11 | `site-L09868-C012` | S | — |
| `HandleReduceWindow/singleton-maximum-no-pad-crop` | R / F11 | `site-L09868-C012` | S | — |
| `HandleReduceWindow/singleton-maximum-pad-no-crop` | R / F11 | `site-L09868-C012` | S | — |
| `HandleReduceWindow/singleton-maximum-pad-crop` | R / F11 | `site-L09868-C012` | S | — |
| `HandleReduceWindow/full-dimensions` | R / F11 | `site-L09911-C014` | S | — |
| `HandleReduceWindow/pad-broadcast-direct-combined` | R / F11 | `site-L10098-C012` | S | — |
| `HandleReduceWindow/pad-broadcast-direct-existing` | R / F11 | `site-L10098-C012` | S | — |
| `HandleReduceWindow/pad-fold-direct` | R / F11 | `site-L10106-C010` | S | — |
| `HandleReduceWindow/pad-broadcast-convert-combined` | R / F11 | `site-L10098-C012` | S | — |
| `HandleReduceWindow/pad-broadcast-convert-existing` | R / F11 | `site-L10098-C012` | S | — |
| `HandleReduceWindow/pad-fold-convert` | R / F11 | `site-L10106-C010` | S | — |
| `ReplaceWithBitcast/unary` | G / F08 | `shared API ReplaceWithBitcast` | S | C01 |
| `ReplaceInstructionIfCompatible/single` | G / shared | `shared API ReplaceInstructionIfCompatible` | S | C01 |
| `ReplaceInstructionIfCompatible/span-single` | G / shared | `shared API ReplaceInstructionIfCompatible` | S | C01 |
| `ReplaceInstructionIfCompatible/span-tuple` | G / shared | `shared API ReplaceInstructionIfCompatible` | S | C01 |
| `TryRemoveUpcastAndDowncastSurroundingBinaryOp/add` | R / F05 | `site-L02387-C024` | S | — |
| `TryRemoveUpcastAndDowncastSurroundingBinaryOp/subtract` | R / F05 | `site-L02387-C024` | S | — |
| `TryRemoveUpcastAndDowncastSurroundingBinaryOp/multiply` | R / F05 | `site-L02387-C024` | S | — |
| `TryRemoveUpcastAndDowncastSurroundingBinaryOp/divide` | R / F05 | `site-L02387-C024` | S | — |
| `TryRemoveUpcastAndDowncastSurroundingBinaryOp/remainder` | R / F05 | `site-L02387-C024` | S | — |
| `RemoveDegenerateDimensionFromDot/direct` | R / F12 | `site-L02864-C026` | S | — |
| `RemoveDegenerateDimensionFromDot/reshape-result` | R / F12 | `site-L02866-C026` | S | — |
| `RemoveTransposesFromDotOperands/keep-order` | R / F12 | `site-L03020-C024` | S | — |
| `RemoveTransposesFromDotOperands/swap` | R / F12 | `site-L03020-C024` | S | — |
| `MoveDotParamToRhs/parameter-left` | R / F12 | `site-L03089-C007` | S | — |
| `RewriteAsMultiplyDotWithZeroLhsContractingDim/casts-00` | R / F12 | `site-L03926-C010` | S | — |
| `RewriteAsMultiplyDotWithZeroLhsContractingDim/casts-01` | R / F12 | `site-L03926-C010` | S | — |
| `RewriteAsMultiplyDotWithZeroLhsContractingDim/casts-10` | R / F12 | `site-L03926-C010` | S | — |
| `RewriteAsMultiplyDotWithZeroLhsContractingDim/casts-11` | R / F12 | `site-L03926-C010` | S | — |
| `AssociativeReorderNestedDot/lhs-transpose` | R / F12 | `site-L04272-C028` | S | C07 |
| `AssociativeReorderNestedDot/lhs-direct` | R / F12 | `site-L04275-C028` | S | C07 |
| `AssociativeReorderNestedDot/rhs-transpose` | R / F12 | `site-L04272-C028` | S | C07 |
| `AssociativeReorderNestedDot/rhs-direct` | R / F12 | `site-L04275-C028` | S | C07 |
| `RewriteBatchPlusContractingAsReduce/no-free-lhs` | R / F12 | `site-L04362-C010` | S | — |
| `RewriteBatchPlusContractingAsReduce/no-free-rhs` | R / F12 | `site-L04362-C010` | S | — |
| `RewriteBatchPlusContractingAsReduce/no-free-both` | R / F12 | `site-L04362-C010` | S | — |
| `HandleDot/empty` | R / F12 | `site-L04399-C012` | S | — |
| `HandleDot/outer-product-delegation` | A / F12 | `RewriteAsMultiplyDotWithZeroLhsContractingDim` | S | C01 |
| `HandleDot/nested-delegation` | A / F12 | `AssociativeReorderNestedDot` | S | C01 |
| `HandleDot/strength-reduce-delegation` | A / F12 | `RewriteBatchPlusContractingAsReduce` | S | C01 |
| `HandleDot/degenerate-delegation` | A / F12 | `RemoveDegenerateDimensionFromDot` | S | C01 |
| `HandleDot/transposes-delegation` | A / F12 | `RemoveTransposesFromDotOperands` | S | C01 |
| `HandleDot/parameter-swap-delegation` | A / F12 | `MoveDotParamToRhs` | S | C01 |
| `HandleDot/mirror-reverse-lhs-to-rhs` | R / F12 | `site-L04445-C014` | S | — |
| `HandleDot/mirror-pad-lhs-to-rhs` | R / F12 | `site-L04445-C014` | S | — |
| `HandleDot/mirror-broadcast-lhs-to-rhs` | R / F12 | `site-L04445-C014` | S | C07 |
| `HandleDot/mirror-reverse-rhs-to-lhs` | R / F12 | `site-L04445-C014` | S | — |
| `HandleDot/mirror-pad-rhs-to-lhs` | R / F12 | `site-L04445-C014` | S | — |
| `HandleDot/mirror-broadcast-rhs-to-lhs` | R / F12 | `site-L04445-C014` | S | C07 |
| `HandleDot/reorder-contracting-lhs` | R / F12 | `site-L04470-C012` | S | — |
| `HandleDot/concat-lhs` | R / F12 | `site-L04478-C012` | S | — |
| `HandleDot/reorder-contracting-rhs` | R / F12 | `site-L04470-C012` | S | — |
| `HandleDot/concat-rhs` | R / F12 | `site-L04478-C012` | S | — |
| `HandleDot/dynamic-slice-lhs` | R / F12 | `site-L04489-C012` | S | — |
| `HandleDot/dynamic-slice-rhs` | R / F12 | `site-L04489-C012` | S | — |
| `ScalarMultiplyReduction/target-lhs` | R / F13 | `site-L00748-C034` | S | C09 |
| `ScalarMultiplyReduction/target-rhs` | R / F13 | `site-L00748-C034` | S | C09 |
| `ScalarMultiplyReduction/target-output` | R / F13 | `site-L00748-C034` | S | C09 |
| `TryToReorderConvAddMultiply/order-lhs-lhs` | R / F13 | `site-L05180-C010` | S | — |
| `TryToReorderConvAddMultiply/order-lhs-rhs` | R / F13 | `site-L05180-C010` | S | — |
| `TryToReorderConvAddMultiply/order-rhs-lhs` | R / F13 | `site-L05180-C010` | S | — |
| `TryToReorderConvAddMultiply/order-rhs-rhs` | R / F13 | `site-L05180-C010` | S | — |
| `FoldConvInputPad/compose` | R / F13 | `site-L10812-C009` | S | — |
| `FoldConvFilterPad/dilation` | R / F13 | `site-L10883-C007` | S | — |
| `PromoteConvolutionToF32IfNotOnednnCompatible/promote-and-continue` | R / F13 | `site-L10976-C024` | S | C09 |
| `SimplifyConvToDot/pointwise-layout` | R / F13 | `site-L11098-C007` | S | — |
| `SimplifyConvToMultiply/pointwise-000` | R / F13 | `site-L11219-C024` | S | — |
| `SimplifyConvToMultiply/pointwise-001` | R / F13 | `site-L11219-C024` | S | — |
| `SimplifyConvToMultiply/pointwise-010` | R / F13 | `site-L11219-C024` | S | — |
| `SimplifyConvToMultiply/pointwise-011` | R / F13 | `site-L11219-C024` | S | — |
| `SimplifyConvToMultiply/reduce-000` | R / F13 | `site-L11219-C024` | S | — |
| `SimplifyConvToMultiply/reduce-001` | R / F13 | `site-L11219-C024` | S | — |
| `SimplifyConvToMultiply/reduce-010` | R / F13 | `site-L11219-C024` | S | — |
| `SimplifyConvToMultiply/reduce-011` | R / F13 | `site-L11219-C024` | S | — |
| `SimplifyConvToMultiply/reduce-100` | R / F13 | `site-L11219-C024` | S | — |
| `SimplifyConvToMultiply/reduce-101` | R / F13 | `site-L11219-C024` | S | — |
| `SimplifyConvToMultiply/reduce-110` | R / F13 | `site-L11219-C024` | S | — |
| `SimplifyConvToMultiply/reduce-111` | R / F13 | `site-L11219-C024` | S | — |
| `HandleConvolution/empty` | R / F13 | `site-L11232-C012` | S | C09 |
| `HandleConvolution/scalar-movement-delegation` | A / F13 | `ScalarMultiplyReduction` | S | C01,C09 |
| `HandleConvolution/input-pad-delegation` | A / F13 | `FoldConvInputPad` | S | C01,C09 |
| `HandleConvolution/filter-pad-delegation` | A / F13 | `FoldConvFilterPad` | S | C01,C09 |
| `HandleConvolution/operand-swap-delegation` | E / F13 | `SwapConvOperands -> external swap@10894` | S | C01,C09,C11 |
| `HandleConvolution/onednn-delegation` | A / F13 | `PromoteConvolutionToF32IfNotOnednnCompatible` | S | C01,C09 |
| `HandleConvolution/to-dot-delegation` | A / F13 | `SimplifyConvToDot` | S | C01,C09 |
| `HandleConvolution/to-multiply-delegation` | A / F13 | `SimplifyConvToMultiply` | S | C01,C09 |

## Exact proposed links for existing supplementary effects

These case lists are conditional source branch links, not proofs every
caller/profile reaches the effect. Conditions in the final column remain part
of the link. Alias IDs are provenance edges and do not count again. Local-only
writes are classified as such. Every original record ID is retained.

### 49 call records

| Record / source line | Source classification | Exact proposed case links | Stage / condition |
| --- | --- | --- | --- |
| `call-22322-22340` / 610 | visitor_traversal_state | G only | G: visitor reset; caller Run/RunImpl |
| `call-22344-22361` / 611 | visitor_change_flag | G only | G: changed flag reset; not a tensor rewrite |
| `call-28106-28121` / 791 | visitor_change_flag | `ScalarMultiplyReduction/target-lhs`, `ScalarMultiplyReduction/target-output`, `ScalarMultiplyReduction/target-rhs` | after at least one collected scale; target dispatch remains |
| `call-114842-114879` / 2861 | derived_instruction_metadata_or_virtual_hook | `RemoveDegenerateDimensionFromDot/direct`, `RemoveDegenerateDimensionFromDot/reshape-result` | new Dot before direct/reshape result choice |
| `call-121450-121487` / 3019 | derived_instruction_metadata_or_virtual_hook | `RemoveTransposesFromDotOperands/keep-order`, `RemoveTransposesFromDotOperands/swap` | new Dot in both operand-order modes |
| `call-124206-124279` / 3085 | derived_instruction_metadata_or_virtual_hook | `MoveDotParamToRhs/parameter-left` | new Dot; preserve_user_fusion_attr=true |
| `call-124283-124389` / 3086 | derived_instruction_metadata_or_virtual_hook | `MoveDotParamToRhs/parameter-left` | new Transpose; preserve_user_fusion_attr=false |
| `call-125847-125884` / 3120 | cached_module_embedded_computation_construction | `RewriteBatchPlusContractingAsReduce/no-free-both`, `RewriteBatchPlusContractingAsReduce/no-free-lhs`, `RewriteBatchPlusContractingAsReduce/no-free-rhs` | AddReduce; cache miss adds module computation, hit reuses |
| `call-131555-131592` / 3256 | derived_instruction_metadata_or_virtual_hook | `HandleDot/concat-lhs`, `HandleDot/concat-rhs` | per constructed piece Dot in Concat helper |
| `call-135939-135982` / 3364 | derived_instruction_metadata_or_virtual_hook | `HandleDot/dynamic-slice-lhs`, `HandleDot/dynamic-slice-rhs` | memoized full Dot before lookup slice |
| `call-140601-140629` / 3475 | local_dimension_number_value | `HandleDot/reorder-contracting-lhs`, `HandleDot/reorder-contracting-rhs` | local contracting-list copy only |
| `call-141946-141974` / 3510 | local_dimension_number_value | `HandleDot/reorder-contracting-lhs`, `HandleDot/reorder-contracting-rhs` | local contracting-list copy only |
| `call-154172-154216` / 3795 | local_dimension_number_value | `HandleDot/mirror-broadcast-lhs-to-rhs`, `HandleDot/mirror-broadcast-rhs-to-lhs` | local new_dnums, not live instruction metadata |
| `call-154224-154268` / 3796 | local_dimension_number_value | `HandleDot/mirror-broadcast-lhs-to-rhs`, `HandleDot/mirror-broadcast-rhs-to-lhs` | local new_dnums, not live instruction metadata |
| `call-159518-159555` / 3920 | derived_instruction_metadata_or_virtual_hook | `RewriteAsMultiplyDotWithZeroLhsContractingDim/casts-00`, `RewriteAsMultiplyDotWithZeroLhsContractingDim/casts-01`, `RewriteAsMultiplyDotWithZeroLhsContractingDim/casts-10`, `RewriteAsMultiplyDotWithZeroLhsContractingDim/casts-11` | only if new_lhs != original lhs |
| `call-159589-159626` / 3923 | derived_instruction_metadata_or_virtual_hook | `RewriteAsMultiplyDotWithZeroLhsContractingDim/casts-00`, `RewriteAsMultiplyDotWithZeroLhsContractingDim/casts-01`, `RewriteAsMultiplyDotWithZeroLhsContractingDim/casts-10`, `RewriteAsMultiplyDotWithZeroLhsContractingDim/casts-11` | only if new_rhs != original rhs |
| `call-159634-159685` / 3925 | derived_instruction_metadata_or_virtual_hook | `RewriteAsMultiplyDotWithZeroLhsContractingDim/casts-00`, `RewriteAsMultiplyDotWithZeroLhsContractingDim/casts-01`, `RewriteAsMultiplyDotWithZeroLhsContractingDim/casts-10`, `RewriteAsMultiplyDotWithZeroLhsContractingDim/casts-11` | new Multiply before final replacement |
| `call-204091-204106` / 4965 | visitor_change_flag | `HandleMaximum/nested-right-second` | after operand1 rewrite |
| `call-208460-208475` / 5076 | visitor_change_flag | `HandleMinimum/nested-right-second` | after operand1 rewrite |
| `call-214589-214604` / 5220 | visitor_change_flag | `HandleMultiply/negated-operands` | after both operand writes |
| `call-214966-214981` / 5231 | visitor_change_flag | `HandleMultiply/abs-square` | after both operand writes |
| `call-230633-230648` / 5621 | visitor_change_flag | `HandleOptimizationBarrier/prune-producer`, `HandleOptimizationBarrier/prune-tuple` | before projection mutations/status checks |
| `call-231452-231498` / 5643 | existing_or_new_instruction_original_value_projection | `HandleOptimizationBarrier/prune-producer`, `HandleOptimizationBarrier/prune-tuple` | existing barrier original-value map |
| `call-231502-231552` / 5644 | existing_or_new_instruction_original_value_projection | `HandleOptimizationBarrier/prune-producer`, `HandleOptimizationBarrier/prune-tuple` | operand-to-new-tuple original-value map |
| `call-237645-238289` / 5812 | module_recovery_table_and_instruction_metadata | `HandleBroadcast/inserted-unit-axes` | module recovery callback before replacement |
| `call-238702-238717` / 5833 | visitor_change_flag | `HandleBroadcast/sink-users-delegation`, `TryToSinkBroadcastAfterElementwiseOps/eligible-user` | after successful helper result; may cover several user rewrites |
| `call-239872-239887` / 5858 | visitor_change_flag | `HandleBroadcast/scalar-user-dynamicslice`, `HandleBroadcast/scalar-user-reshape`, `HandleBroadcast/scalar-user-reverse`, `HandleBroadcast/scalar-user-slice`, `HandleBroadcast/scalar-user-sort`, `HandleBroadcast/scalar-user-transpose` | before selected user ReplaceAllUsesWith |
| `call-246635-246650` / 6030 | visitor_change_flag | `HandleCompare/maximum-first` | after operand0 write |
| `call-246818-246833` / 6034 | visitor_change_flag | `HandleCompare/maximum-second` | after operand0 write |
| `call-247065-247080` / 6040 | visitor_change_flag | `HandleCompare/minimum-first` | after operand1 write |
| `call-247248-247263` / 6044 | visitor_change_flag | `HandleCompare/minimum-second` | after operand1 write |
| `call-258668-258695` / 6318 | existing_instruction_metadata | `HandlePad/broadcast-projection` | existing Broadcast sharding clear after shape/dims writes |
| `call-283924-283971` / 6922 | local_shape_value | `HandleReshape/empty` | scratch literal shape; not existing-node mutation |
| `call-329184-329227` / 8002 | derived_instruction_metadata_or_virtual_hook | `HandleSlice/concat-subrange-multi` | new sub-Concat metadata only |
| `call-348240-348255` / 8430 | visitor_change_flag | `HandleDynamicSlice/nested` | plus required NEW scaled-probe child; after all index writes |
| `call-360984-360999` / 8728 | visitor_change_flag | `HandleDynamicUpdateSlice/nested` | after data/update/index writes |
| `call-374625-374898` / 9068 | module_embedded_computation_construction | `HandleReduce/singleton-tuple` | module computation clone before node replacement |
| `call-376466-376481` / 9107 | visitor_change_flag | `HandleReduce/negate-sum` | after input write/new Negate, before ReplaceUsesWith status |
| `call-382443-382458` / 9246 | visitor_change_flag | `HandleReduce/reshape-reduced-axes` | before constructing/replacing new Reduce |
| `call-386616-386654` / 9341 | local_dimension_number_value | `HandleReduce/dot-batch-all-batch`, `HandleReduce/dot-batch-residual-reduce` | local new_dnums batch list |
| `call-386660-386698` / 9342 | local_dimension_number_value | `HandleReduce/dot-batch-all-batch`, `HandleReduce/dot-batch-residual-reduce` | local new_dnums batch list |
| `call-387749-387786` / 9369 | derived_instruction_metadata_or_virtual_hook | `HandleReduce/dot-batch-all-batch`, `HandleReduce/dot-batch-residual-reduce` | new Dot before optional residual reduction |
| `call-388003-388046` / 9376 | derived_instruction_metadata_or_virtual_hook | `HandleReduce/dot-batch-residual-reduce` | new residual Reduce only |
| `call-399517-399799` / 9633 | module_embedded_computation_construction | `HandleReduceWindow/singleton-tuple` | module computation clone before replacement |
| `call-431715-431761` / 10389 | local_dimension_number_value | `TryFoldTransposeIntoScatter/simplified-scatter` | local scatter dnums copy |
| `call-432934-433033` / 10419 | module_recovery_table_and_instruction_metadata | `HandleTranspose/identity` | module recovery before existing-node replacement |
| `call-438737-438774` / 10562 | derived_instruction_metadata_or_virtual_hook | `HandleTranspose/dot-general` | new Dot metadata; not canonical Dot branch |
| `call-445802-445817` / 10738 | visitor_change_flag | `HandleTranspose/space-depth-user-mutation` | after OUTER reshape operand write |
| `call-451386-451401` / 10898 | visitor_change_flag | `HandleConvolution/operand-swap-delegation` | E external rewrite reports changed; conditional callback path |

### 15 direct pointer-write records

| Record / source line | Source classification | Exact proposed case links | Object / condition |
| --- | --- | --- | --- |
| `assignment-53503-53589` / 1385 | new_instruction_layout | `HandleAllGather/uniform`, `HandleAllToAll/uniform`, `HandleAllReduceOrReduceScatter/max`, `HandleAllReduceOrReduceScatter/min`, `HandleAllReduceOrReduceScatter/sum-floating`, `HandleAllReduceOrReduceScatter/sum-integral` | factory scalar/default-memory/layout-valid branch; guard can be infeasible for some caller opcodes |
| `assignment-231400-231448` / 5642 | existing_instruction_shape | `HandleOptimizationBarrier/prune-producer`, `HandleOptimizationBarrier/prune-tuple` | existing barrier projection shape |
| `assignment-258551-258597` / 6316 | existing_instruction_shape | `HandlePad/broadcast-projection` | existing Broadcast shape |
| `assignment-258605-258660` / 6317 | existing_instruction_dimensions | `HandlePad/broadcast-projection` | existing Broadcast dimension list |
| `assignment-258839-258883` / 6321 | new_instruction_padding_config | `HandlePad/broadcast-projection` | new Pad config |
| `assignment-284992-285036` / 6949 | existing_rng_shape | `HandleReshape/rng-shape` | existing RNG shape |
| `assignment-316109-316155` / 7702 | new_instruction_shape | `HandleSlice/padding-only` | new Broadcast shape |
| `assignment-316576-316622` / 7713 | new_instruction_shape | `HandleSlice/inside-pad` | new Slice shape |
| `assignment-319416-319462` / 7776 | new_instruction_shape | `HandleSlice/inside-dynamic-update` | new Slice shape |
| `assignment-329025-329110` / 7999 | new_instruction_layout | `HandleSlice/concat-subrange-multi` | new sub-Concat layout |
| `assignment-356414-356472` / 8634 | new_instruction_shape | `HandleDynamicUpdateSlice/pad-concat-high`, `HandleDynamicUpdateSlice/pad-concat-low` | new Concat shape; exact low/high overwrite guard |
| `assignment-437899-437993` / 10544 | local_dimension_number_value | `HandleTranspose/dot-general` | local new_dnums lhs contract list |
| `assignment-438001-438095` / 10546 | local_dimension_number_value | `HandleTranspose/dot-general` | local new_dnums rhs contract list |
| `assignment-438655-438728` / 10560 | new_instruction_layout | `HandleTranspose/dot-general` | new Dot layout |
| `assignment-439349-439395` / 10580 | existing_rng_shape | `HandleTranspose/rng-shape` | existing RNG shape |

## Concrete source-only exit artifact

A next census version should publish: the canonical R/E registry and variant
policy; all original-row lineage/alias/G mappings; the added scaled child;
source-ordered caller/capture/outcome graph; and effect/callout provenance with
remaining UNKNOWN entries explicitly listed. A reviewer can then audit that
source closure and freeze N/F without waiting for correctness proofs. Proof and
unsupported/refuted status can be attached afterward without changing the
source denominator unless a newly discovered SOURCE omission is versioned.

This report does not create or approve that next version. It preserves the
frozen source basis and supplies the specific transformations/partitions and
crosswalk needed to build it.
