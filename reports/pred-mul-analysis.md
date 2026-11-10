# Candidate nonfinite counterexample: predicate conversion multiplication

## Subsequent Lean certificate under an explicit numerical contract

The kernel now checks a binary32 exceptional-output refutation in
TensorRewrite/Pilot/PredMulRefutation.lean. It applies to every infinity/NaN
encoding, includes a nonvacuous scalar tensor, and transfers to every stronger
numerical relation refining the necessary IEEE condition. All reported axiom
dependencies are empty; no floating-point multiplication axiom or native_decide
result is trusted. Exact theorem/code identities are in reports/pilot-values.json.

The relation intentionally permits arbitrary finite outputs. This is safe for
refutation: rejecting an output even under a necessary, permissive condition
also rejects it under a stronger IEEE specification. A consistency theorem and
controls expose that permissiveness explicitly. It cannot be used to certify
general finite arithmetic. Intended optimizer-contract review and verified
source/contract correspondence remain open; the certificate does not settle
those obligations by its own definition.

## Subsequent pinned-XLA replay: observed mismatch confirmed

The real pinned test now passes with fast math disabled for positive infinity,
negative infinity and quiet NaN in both multiplication operand orders. Each
verified input graph is simplified to Select; HloEvaluator reports NaN before
and zero after. Original/rewritten HLO, exact test source, logs, Bazel events and
binary identity are archived in reports/xla-replay-v2/. The first infinity-only
replay is independently retained in reports/xla-replay-v1/.

Run tools/check_xla_replay_evidence.py for offline archive integrity checking.
It does not rerun the pass. Intended optimizer-contract and source-correspondence
review remain open; the kernel-checked conditional refutation is described above.
The later explicit module-settings replay is preserved in reports/xla-replay-v3/.
The arithmetic census narrows inferences from disabled fast math to numerical
intent; see reports/numerical-contract-review.md. The historical limitations below
describe the earlier stage, before the isolated checkout/Bazel build existed.

## Historical pre-replay analysis

Status: native IEEE witness and inspected source path; pinned-XLA replay and
kernel-checked floating-point refutation remain pending. This is not a confirmed
XLA bug report.

Source: e58e523b11f1fde802a493a776d158007486e1bf, HandleMultiply,
algebraic_simplifier.cc:5237–5253. MultiplyAnyOrder matches Convert with a PRED
input and constructs Select(predicate, other_operand, zero). No local finite or
fast-math guard appears. Nearby zero multiplication branches explicitly guard
NaN handling. RunImpl:11315 onward invokes the visitor without an identified
global finite-input gate. The option proto describes enable_fast_math as finite
math; it has no explicit true default.

The parameter graph in tests/xla/pred_mul_nonfinite.hlo avoids earlier constant,
Negate and Abs patterns. For predicate=false and operand=+infinity, strict IEEE
arithmetic gives 0*infinity=NaN, while Select returns zero. Negative infinity and
quiet NaN give the same classification mismatch. This does not depend on NaN
payload or signed-zero observations.

The native witness uses volatile binary32 values and -fno-fast-math with
-ffp-contract=off. It records raw result bits and NaN classes, with finite and
true-predicate controls. Exact results and compiler identity are in
reports/pred-mul-nonfinite.json. It executes arithmetic expressions, not XLA.

Official StableHLO multiply specifies IEEE-754 multiplication:
https://openxla.org/stablehlo/spec#multiply (inspected 2026-11-10).
XLA operation semantics: https://openxla.org/xla/operation_semantics.
The correspondence between those contracts and this optimizer configuration
still needs verification; the references do not settle it by themselves.

## Real-pass replay still required

tests/xla/pred_mul_nonfinite_test.inc is an uncompiled diagnostic snippet for
the pinned AlgebraicSimplifierTest fixture. It requires HloEvaluator and standard
cmath/limits/vector includes/dependencies. It parses/verifies the module,
evaluates before, runs the pass with fast math and fixed-point iteration disabled,
requires a Select root and evaluates after. Its assertions describe the expected
mismatch, not the desired behavior of a future corrected optimizer.

This workspace has no bazel, hlo-opt or jaxlib, and no complete XLA build closure.
Do not infer that the pass fired from the native arithmetic test. No external
issue/report has been sent. Remaining evidence: actual pass/evaluator replay,
intended HLO numerical contract, independently checked guard applicability and
a kernel-checked floating-point refutation.

The experiment should retain this as a refutation candidate rather than prove
an integer-only statement or add a finite-input premise and count the whole
source rule as verified. Full census/attempts and the final verdict remain open.
