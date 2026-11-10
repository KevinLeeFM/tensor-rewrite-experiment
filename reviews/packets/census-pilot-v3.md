The v2 archive is preserved as a packaging-repair intermediate; its copied body
retained the older 71-law count. This v3 corrects that prose to 77 and distinguishes
57 visitor overrides from the additional Handle-prefixed shared helper. The
structural inventory's 58-record field remains a lexical Handle-prefix count.

# Revised packet and reproducibility repair

This is a fresh live-basis snapshot after the original v1 review identified
missing tests/test_tools.py and reports/xla-replay-v2. Both are bundled here;
all historical native archives are included despite their differing schemas.
The expected Python suite count is 57. A zero-test or partial discovery result
must fail. Run `python -B -m unittest discover -s tests -v`, verify 57 tests, then
run `python tools/check_pilot.py`. These are separate evidence surfaces.

This snapshot includes the later signed-word and contraction extensions,
2547 custom Lean lines,77 value laws and86 support lemmas. Neither extension
inherits the original review. The raw Clang AST and historical TensorRight
artifacts still require their separately pinned archives; this is not a
hermetic full-checkpoint image. Do not treat unavailable raw-AST replay as done.
Original v1 inputs and findings remain unchanged. No semantic N/F is frozen.

Additional review targets: promoted signed intermediate/narrowing semantics;
general contraction batch/free/contract ordering, explicit casts/finish identity,
and zero-MAC signed-zero diagnostic scope. Review the 20 earlier targets below
against this revised basis only when explicitly assigned to do so. No review
result for this v2 is claimed by creating it.

# Independent review packet: source census and semantic pilot, v3

This is a concrete request for an independent inspection, not evidence that
review has occurred. Use the frozen zip and its manifest/descriptor alongside
this file. The integrator continues other work in the shared workspace: do not
review moving files as though they were the frozen input.

## Purpose and claim boundary

The research question is whether the recorded agent/Lean workflow can provide
source-faithful, rank/size-general verification of every rewrite in the pinned
XLA algebraic_simplifier.cc, with Lean LOC as the primary artifact-burden measure.
The current state is provisional:487 overlapping source schemas, no frozen
semantic N/F, zero accepted source proofs,77 kernel-checked value laws plus
separately reported graph/guard/composition/diagnostic groups. The2547-line custom
Lean count excludes separately reported tests/audits and non-Lean tooling.

XLA e58e523b11f1fde802a493a776d158007486e1bf; target SHA256
1ecfd7d4ba958ac0e795d8663c14f7f6b1ebd147a8a83ed0e99661740105628f.
Lean4.35.0/Std only. The final whole-file verdict is open.

The plan accepts independently reviewed source-to-theorem correspondence as a
trust boundary. It does not require a verified C++ extractor. A separate agent
review is useful scrutiny, not a trusted oracle or a replacement for accountable
human review/checked translation at final source acceptance.

## Frozen materials

- sources/xla/: target, header/options and inspected dependencies.
- census/: all provisional case batches, site bindings, complete calls, typed
  selected callees, replacement API paths, model/source candidates and contracts.
- TensorRewrite/, root Lean/Lake/toolchain files and tests/fixtures/: exact pilot.
- tests/xla/: native fixture source. The canonical pass is not modified.
- reports/: human reports, checkpoint/pilot/audit outputs and native result
  archives with their recorded fixture/BUILD/log/events/XML identities, including
  relevant failed attempts. Large raw Clang AST artifacts remain separately
  pinned in the original workspace and prior typed-call snapshot; structured
  typed records are included here. This packet is not a hermetic compiler image.
- tools/: current evidence tools; parser dependencies are bundled for optional
  fresh-directory checks. Historical TensorRight source artifacts and the paper
  remain separately pinned inputs, not silently reproduced by this review zip.

The descriptor census-pilot-v3.json identifies archive and manifest SHA256.
The manifest lists every included input's hash. Recheck those hashes before
inspection. Work in a fresh extraction directory if executing checks.

## Review work A: whole-source census/dependency reconciliation

Inspect all57 visitor override handlers, the shared HandleAllReduceOrReduceScatter
helper, and other transformation helpers against the actual target.
Treat the339 executable lexical replacement-related sites,7391 syntactic calls,
292 typed local edges and285 API sites/boundaries as discovery aids. They do not
establish semantic coverage or valid execution paths.

Identify missing transformations, incorrectly merged/split schemas, omitted
non-replacement mutations, early exits/status paths, stateful matcher captures,
layout/dtype/options partitions, alias writes, callback/external helpers and
construction-before-skip outcomes. Explain each with a source location and
proposed ledger correction. Review the whole handler/helper surface; do not
sample only theorem-backed cases. If inspection is partial, enumerate exactly
which handlers/functions/case IDs remain unreviewed.

Check API defaults/overloads against source. In particular, distinguish existing-
instruction visitor relay from new-instruction default-false relay and low-level
rewiring. Static helper paths overapproximate alternatives and retain unresolved
external calls; do not convert them to path conditions or safety classifications.
Decide whether N can be frozen; report reasons if it cannot. Do not freeze it
or promote accepted-source fields yourself.

## Review work B: twenty concrete semantic/statement targets

Inspect definitions and theorem assumptions, not just successful Lean builds.
For each item, check whether its claimed profile is independently meaningful,
rank/size general where allowed, nonvacuous and correctly related to source.
Distinguish value-level proof, context proof, source counterexample candidate,
backend/evaluator diagnostic and verified extraction. The20 targets below are
review targets, not a claim that the diverse pilot gate is already met.

1. Boolean.and_rhs_false and its pure/effectful DAG counterparts: IsAll and
   control-successor ordering; inspect the native reversed-order witness.
2. Boolean/Bitwise.xor_self: pointer-self versus Identical-equivalent operands,
   side-effect and sharding/layout requirements.
3. Bitwise.and_rhs_zero: arbitrary width, legal source dtype and constant guard.
4. Subtract.sub_self: integral/fast-math partition; exceptional floating values.
5. ModularArithmetic.factor_any_order: all shared-factor positions, one-use,
   numerical permission and captured operand bindings.
6. ModularArithmetic.broadcast_factor_any_order: scalar versus nonscalar
   constant, non-Broadcast guard and concrete dimension-array preservation.
7. Reverse.reverse_trivial: empty/singleton extents and legal axis attributes.
8. Transpose.transpose_comp: composition order, casts and extent premises.
9. Reshape.reshapeTensor_identity: shape, total indexing and empty values.
10. Reshape.reshapeTensor_compose: rank changes, counts and logical/physical split.
11. Reduction.reduceTensor_empty_input: actual initializer and output coordinates.
12. Reduction.reduceTensor_sameCount: required initializer law and source reducer.
13. DenseLayout.transpose_eq_bitcast: actual minor-order array equation; tiled
    ArraySize diagnostic, packing/memory spaces and profile limits.
14. DynamicIndex.sliceTensor_compose: logical decoded starts, finite arithmetic
    and nested unsigned evaluator discrepancy kept separate.
15. BooleanDag.and_rhs_true_of_isAll: literal storage/view model, recognized
    wrappers, bounds, source constant interpretation and DAG root/reference map.
16. Float32Exceptional.false_inf_refutes: necessary IEEE condition, actual strict
    module/pass controls and family-specific floating permissions.
17. SliceShape.remove_redundant_stride_refutes and witness: legal empty input,
    required shape observation and real verifier-rejected replacement.
18. SelectContraction.nonzero_sum_refutes: mathematical proof versus binary32
    correspondence, both Select branches and convolution option controls.
19. DynamicIndex.unsigned64_high_bit_disagrees: source/backend meaning versus
    evaluator oracle; do not promote an oracle mismatch to a compiler defect.
20. ControlOrder.original_requires_forward/replacement_admits_reverse: native
    schedule graph correspondence, synchronous effects, retained actors and the
    difference between fixed-schedule proofs and trace-set refinement.

Also identify missing semantic families that prevent a genuinely diverse reviewed
pilot, including advanced floating/complex numerical operations, tuples/windows,
dynamic shapes and backend-dependent contracts. Do not mark them out of scope.

## Allowed actions and output

Read the frozen snapshot. Optional builds/checks run in a fresh extraction so
shared live files are not regenerated. Do not alter the pass, definitions,
proofs, ledger fields, evidence or any accepted-source count. Write findings only
to reviews/results/census-pilot-v3-REVIEWER.md, using a distinct reviewer label.
Keep actionable findings source-linked; report validation commands/outcomes and
any incomplete inspection explicitly. Do not send external messages or issues.

The output must state reviewer identity/config where observable (unknown fields
stay unknown), input archive/hash, actual review extent, prioritized findings,
per-target disposition, proposed census/contract corrections, and acceptance-
blocking gaps. A clean result is not an authority to accept source proofs; the
integrator must resolve findings and preserve independent/human review provenance.
