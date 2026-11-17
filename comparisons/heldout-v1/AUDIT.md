# Held-out experiment preparation, 16 November 2026

## Scope and result
Base: 86cef93. Main checkout remains unchanged. The inventory covers all 241 maintained custom modules under TensorRewrite/ plus root modules, with 1,573 lexical declarations, including 991 theorem/lemma declarations. The separate historical paper-comparison sources, external dependencies, generated audit files and tests are not reusable-baseline modules and remain excluded. This is a complete structural inventory of that scope, NOT a semantic certification of every declaration.

The existing library is not a clean held-out baseline: roots import finished case proofs, and generic-sounding domain modules can contain specific rewrite vocabularies. Examples:
- TensorRewriteTheory.lean imports LogicalFamilyProof, ConvolutionDotProof and other completed families/refutations.
- Theory/ArithmeticFamily.lean defines a closed Rule enum including negNeg, addZero, addCancel, mulAssoc and factor; ArithmeticFamilyProof.lean proves rewrite_sound and instantiates whole integer/real/complex/word families. Such proof logic would directly solve matching held-out targets.
- Theory/ControlValuesProof.lean directly proves select_equal, select_not, broadcast_select and related target rewrites.
- Pilot/DynamicSliceTensor.lean is mainly semantics but combinedStart already encodes a particular nested-slice normalization. It is quarantined, not silently called generic infrastructure.

Safe cleaning is exclusion, not deletion or semantic modification: all custom modules are quarantined except reviewed Pilot/Tensor.lean and Pilot/Indexing.lean. Those contain the bounded-coordinate tensor model and primitive map/reindex/reverse definitions, with no theorem/lemma declarations; their custom import closure is closed. baseline-manifest.json records exact hashes. This very small baseline is deliberately conservative and not comparable to the historical rich library. Expanding it requires declaration-level review before statements are frozen. No original source or specification was changed.

## Candidate gate
candidate-shortlist.json records three source-ledger candidates with no linked prior proof evidence: DynamicSlice/transpose, Reverse/inserted-unit-dimensions, and Reshape/iota-mixed-radix. They cover coordinate permutation, shape transport and index arithmetic. They are NOT yet certified unverified targets: lack of ledger evidence and keyword hits does not exclude an equivalent theorem, and exact guards still need source review. Do not begin timed proofs or claim held-out success until those gates pass.

## Trial protocol
1. Audit each candidate against all prior theorem statements and the 118 paper cases, not just names. Reject equivalent/previously proved targets; document all prior exposure.
2. Freeze independently reviewed original/replacement definitions, guards, complete theorem statements, source pins and non-vacuity witnesses. Freeze their dependency closure and library manifest before exposing them to proof workers.
3. Review for circular premises: a wrong rewrite must be able to violate the stated property. Check shape-zero, scalar and nontrivial cases and a deliberately wrong replacement. No narrowed guard to make a failed target pass.
4. Use isolated case files and a proof worker not given previous proof bodies. No promotion or sharing of new helpers between cases during the trial. Charge all adapters and case-local helpers as new work.
5. For each attempt record UTC start/end and monotonic command elapsed times; separate specification/setup, proof development, build waiting, review and replay. Record failures and pauses. Token/model/resource figures only when directly observable; otherwise unknown. Record model and effort settings.
6. Initial pilot: at most three accepted targets, one focused attempt each; reconsider after 20 minutes rather than silently expanding. No broad rebuild/download or C++ correspondence proof. A blocked setup is not proof time.
7. Fresh Lean kernel elaboration, transitive axiom audit (only propext, Classical.choice, Quot.sound), no sorry/admit/native_decide/new axioms, exact statement/hash comparator and independent statement review. Report model result, not verified C++.
8. Compare per-case code and time only under matched baselines. Historical discovery times are unavailable, so no numerical speedup claim. Historical replay time is not discovery time.

## Current outcome
Preparation only. No pilot proof has begun, no new rule is claimed, and no semantic cleanup was performed. Next bounded task: validate one candidate and its complete statement against the source and existing proofs, then start a timed case only if that gate passes.

## Timing/accounting
First recorded inspection clock: 22:37:27 UTC. Inventory and initial candidate checks completed by 22:39:13 UTC. This interval includes reading and commands, not proof construction. Exact earlier setup start is not captured. No build/download was launched. Worktree creation, inventory generation and read-only source checks were the only operations.

## Reviewed useful infrastructure extension (22:41 UTC)
The provisional baseline now contains five modules: Tensor, Indexing, Permutation, FiniteProduct and FiniteProductLemmas. Permutation defines bijective axis maps and transpose coordinates, without proving a tensor rewrite. FiniteProduct implements generic row-major pair packing/unpacking; its three inverse laws (row_join, column_join, join_row_column) are useful generic index arithmetic and intentionally retained. Their bodies were read, not merely classified by filename. This preserves substantive reusable infrastructure rather than reducing the experiment to bare definitions. IndexLemmas remains excluded because its reversal-composition facts directly express completed rewrite mathematics; this is conservative rather than a finding of invalidity. The entire candidate baseline is provisional, not a fully cleaned library or a final novelty audit.
