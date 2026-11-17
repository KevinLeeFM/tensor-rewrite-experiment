# Independent statement and baseline review

Reviewer: candidate_review worker, separate from coordinator/specification author.
No target proof construction, builds or other source edits were performed.

Actual-file review start: 2026-11-17T01:51:52.440147+00:00
Actual-file review end: 2026-11-17T01:53:45.069103+00:00
Observed interval: 112.628956 seconds, including tools and message latency; not pure reasoning time.
Earlier independent source/overlap review completed by 2026-11-17T01:51:08Z. Its exact start was not recorded by this worker, so its duration is unknown; coordinator spawn timestamps may supply an enclosing interval. The two stages must not be combined into a fabricated measured proof/review time.

## Disposition

Accept the frozen mathematical statement and two-module semantic baseline for a bounded proof trial, **conditional on correction of the operational guard below before freezing**. This is a new terminal mathematical target relative to the inspected repository/paper statements, not independently certified global novelty, a blinded trial, complete source-branch closure or a productivity/speedup result.

## Statement and source grounding

Reviewed Spec.lean declares an arbitrary-rank UnitInsertion with a strictly increasing keptAxis map, retained-extent equality and unit size on every axis outside that map. project preserves every retained coordinate using the extent equality; reshape is its tensor pullback. remappedAxes drops every input axis of extent one and otherwise reads the selected output mask at its retained position. Goal quantifies all ranks, all natural extents, all valid plans, arbitrary axis masks and every value tensor/type in its Lean universe.

This matches the abstract **unit-insertion-only** partition of pinned XLA e58e523b11f1fde802a493a776d158007486e1bf, algebraic_simplifier.cc:7287-7320. The actual branch is layout-insensitive, has an inner Reshape, requires a helper result and deleted_dimensions.empty(), skips ALL output dimensions of size one, and maps every remaining selected output dimension d to d - CountElementsLessThan(inserted_dimensions,d). With an order-preserving embedding and complement equal to inserted axes this is exactly pullback along keptAxis, including dropping retained original unit axes.

Read source helpers: algebraic_simplifier.cc:7200-7215 (count), hlo_instruction.cc:5586-5592 (reshape helper forwarding), shape_util.h:830-851 (descriptor contract), shape_util.cc:1624-1680 (recognition), and :1683-1702 (unmodified-dimension discovery). The implementation's recognition checks reject modified extents greater than one, hence can treat zero-sized gaps as degenerate too. Spec deliberately requires inserted extents exactly one. Do not claim full recognition-helper closure.

The source extraction, order-preserving logical reshape interpretation and native axis-list/remapping correspondence are assumed, not formally proved. Physical layout, metadata, side effects, HLO validation, CommonFactors correctness and actual pass reachability are outside this theorem. Monotonicity and complement-unit conditions establish that this is a valid abstract unit-insertion plan; the coordinate-level equality may require only retained-extent preservation. Their likely nonuse in the proof does not establish wider native-reshape correctness.

No field assumes a commuting index map, tensor equality or desired target equality. Both sides are independently assembled from the unchanged reversal and projection definitions. The proposition is not reflexive by definition merely because both are tensor-valued functions.

## Zero extents, scalars and nonvacuity

No positivity assumption silently excludes retained zero extents or scalar rank. A scalar input has an empty coordinate function; all inserted output axes must be unit. A zero retained extent forces an empty output coordinate domain; both tensors are well typed. This is a legitimate empty case, not evidence that all cases are vacuous. InputRank > outputRank admits no plan by strict monotonicity, as expected for insertion without deletion.

Required meaningful witness: input [2,3], output [1,2,1,3,1], keptAxis [1,3], x(i,j)=10*i+j. At the all-zero output coordinate, selecting output axis 1 yields 10. An incorrect unadjusted-axis remap selecting input axis 1 yields 2. Selecting output axis 3 should yield 2; omitting its reversal yields 0. Coordinator must kernel-check nonempty plan existence and at least one such well-formed wrong-replacement refutation, rather than treat syntax/type failure as negative-proof rejection. Scalar and zero-extent examples should remain separate from the nontrivial witness.

## Existing proof overlap

Repository-wide relevant-declaration search was followed by reading the relevant definitions/theorem statements. No matching terminal reverse-through-unit-insertion reshape theorem was located. This is a scoped audit, not an exhaustive semantic equivalence decision procedure.

- TensorRewrite/Pilot/Reverse.lean:9-48 and IndexLemmas.lean:8-17 cover involution, mask composition, constant/map distribution and unit-axis elimination; they do not transport reversal through rank-changing insertion.
- TensorRewrite/Pilot/ReshapeRules.lean:14-36 covers identity, composition and empty reshapes; ReshapeLemmas.lean covers coordinate composition, not this reversal transport.
- TensorRewrite/Theory/ConvolutionSeparableReindex.lean:17-89 supplies specialized projection/expansion and reversed convolution-position enumeration. These are related existing ingredients, not the arbitrary-rank source rewrite statement proposed here.
- OperandOrderLemmas.lean:21-32 covers pointwise binary/constant pullback, not coordinate reversal transport.
- comparisons/tensorright-v1/Reverse.lean and original artifact rules/reverse/Main.hs contain only reverse/rule01-04: unit axes, involution, overlapping groups and binary constant distribution. The 118-rule historical inventory has no reverse/reshape target. Its reduce/reshape and slice/reverse targets are different equations.
- comparisons/fixed-tactics-v1/targets.json includes floating reindex/reverse-negation and convolution reversal facts, not this target. Existing fixed-tactics timing is artifact replay and is not a matched discovery-time baseline.

No previously solved campaign proof body belongs in the proof worker input. Prior exposure from candidate preparation/review should be disclosed; the proof worker should start with fork_turns=none and only frozen statement, audited baseline and operational instructions.

## Baseline review

Read both actual baseline files in full. Tensor.lean contains only Shape, Index and Tensor abbreviations, and constant/map/map2 semantic definitions, importing Std. Indexing.lean imports Tensor and defines reindex, reverseIndex, reverse and axisMask. There are no theorem/lemma declarations, target-specific helpers, new axioms, sorry/admit or native_decide. Custom import closure is exactly these two files. Std is trusted imported infrastructure, not newly developed case code.

## Operational guard correction required

At review time Guard.noCampaignProofs uses allowed entries including TensorRewrite.Pilot.Tensor plus a general descendants check s.startsWith(a ++ "."). This permits **all** declarations in namespace TensorRewrite.Pilot.Tensor, including quarantined IndexLemmas.reverseIndex_reverseIndex and reverseIndex_comp. The same pattern permits arbitrary descendants of allowed abbreviation names. It does not enforce the claimed exact baseline declaration allowlist.

Before freeze, use exact audited declaration names (and explicitly listed actual generated declarations only if necessary). Run a contamination control importing a known forbidden Tensor-namespace theorem; require the HELDOUT_BASELINE_LEAK error. Lock baseline hashes/import closure as well; the environment guard alone is not a complete defense against changed semantic definitions or nonproject declarations. The planned case-local namespace exemption is expected, but each worker-produced case file still needs axiom/content and exact-goal checks.

Guard.exactGoal compares the elaborated theorem type against unfolded frozen Goal using Lean definitional equality, which is appropriate for the exact mathematical statement. A changed-Goal/signature negative control must exercise that checker with well-formed terms.

## Reviewed byte hashes

These identify the actual bytes inspected. Guard is expected to change to resolve the preceding blocker; this review does not approve its original wildcard policy.

- `Spec.lean`: `9dc5af1030818e6bbdd54835b73ff34fa6382ed7d6a574b558e8e84bb049afea`
- `Guard.lean`: `77eb00f2f83052a26acea5f4270bfacc8295ffe5cbc111bf939ccc18513c5d8f`
- `baseline/TensorRewrite/Pilot/Tensor.lean`: `c1b41d38bee3d55c4a63df7333c7f0d23ea5917e4260062e2efad97edbeab122`
- `baseline/TensorRewrite/Pilot/Indexing.lean`: `73632c28e066f7651378c107bb7b9331b874138d6813d1571ed7386aaaa54c9c`
