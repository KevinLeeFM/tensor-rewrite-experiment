# Slice/Transpose helper expansion and shape counterexamples

Source revision: e58e523b11f1fde802a493a776d158007486e1bf.
Target file: xla/hlo/transforms/simplifiers/algebraic_simplifier.cc.

## Census movement

The shape batch grows from 27 to 58 source schemas across twelve handlers/helpers.
It binds every one of their 47 lexical replacement sites. In particular, all
direct Slice/Transpose replacement sites and the six delegated helper bodies
inspected here now have source descriptions. The combined three batches have
164 schema bindings, 135 distinct lexical replacement sites bound and 209
replacement candidates unmapped. These are bookkeeping counts, not N.

New Slice paths include constant-index dynamic updates with actual clamping,
unstrided slice composition, both broadcast paths, movement into dot operands,
concat exact/subrange selection and reduction-window conversion. Helper paths
include scalar-concat lookup, leading-axis reshape reordering, reverse reordering
and redundant stride removal. Nested loop invariants, integer overflow, statuses,
layout and called helper contracts remain explicit dependencies.

New Transpose paths include canonical and general dot operand swaps, degenerate
reshape, RNG shape mutation, layout bitcast and a reshape/transpose/reshape
transformation. The latter mutates the outer reshape's operand, not the visited
transpose. Its acceptance unit is the affected graph including that user.
Transpose/scatter folding and transpose/broadcast remapping retain their option,
dimension and layout guards. Supplied permutation meaning depends on the caller:
the broadcast helper is also called from a bitcast path.

The shape coverage check rejects silently moving a claimed-covered mutation back
into the residual list. Exact body/anchor checks retain source coordinates,
including a multiline concat guard. None of this establishes semantic coverage
of every indirect write, a complete type/profile split or independent review.

## Actual XLA shape failures

Two source guards suggested empty-slice boundary tests:

1. RemoveRedundantStride (:7616–7653) changes selected limits to start+1 without
   checking start<limit. Slice `[1:1:2]` of `s32[4]` has legal output `s32[0]`.
   The pass produces `[1:2]` while retaining `s32[0]`; inference requires `s32[1]`.
2. TryToReorderSliceAndReverse (:7572–7614) computes the last visited index using
   signed `(limit-start-1)/stride`. For the same empty slice after a reverse,
   C++ truncates -1/2 to zero. Reordering produces `[2:3:2]` with declared
   `s32[0]`, again requiring `s32[1]`.

`reports/empty-slice-replay-v2/result.json` records a real test run against the
unchanged pinned algebraic_simplifier.cc, using the existing Bazel build closure.
Each input is parsed into a plain HloModule and explicitly verified successfully
before the pass. The pass reports change. Explicit post-verification returns
INTERNAL with `Expected instruction to have shape equal to s32[1], actual shape
is s32[0]` in both cases. Full original and rewritten HLO are archived.

A nonempty `[1:3:3]` control is also initially verified; the pass changes it to
`[1:2]`, and verification succeeds. The diagnostic asserts both the error code
and message for the two failures, so successful test status means reproduction
of the expected mismatch, not source correctness.

The first test used VerifiedHloModule, which additionally flagged the expected
invalid output on destruction. That terminal failed run remains in v1. V2 uses
plain modules with explicit successful input and expected-failing output checks;
it does not skip either side's verification. No pass fix or external report was
made. Numerical settings are irrelevant to these integer shape checks.

## Contract and trust boundaries

The archived `sources/indexing-contract-manifest.json` pins and hashes:

- shape_inference.cc:3424–3497: nonnegative start, start<=limit, limit<=extent,
  positive stride and output extent `(limit-start+stride-1)/stride`;
- hlo_verifier.cc:1983–1987: Slice shape checking invokes that inference;
- hlo_instructions.cc:2365–2380: the slice constructor stores the supplied shape
  and bounds, allowing the invalid combination to be represented.

The frozen base source tree plus these sources and archived binary/build/test
identities support a concrete shape-preservation counterexample. There is no
machine-checked C++ extraction or new Lean certificate in this update. Runtime
results establish the two examples, not all legal configurations or a complete
compiler-pipeline failure.

This matters to the experiment design: extensional equality over an empty index
set can hold vacuously even when a replacement is malformed. An acceptance proof
must establish the output is well formed; assuming that as an extra premise
would exclude precisely these legal input cases.

The offline archive checker verifies file hashes, both observations, exact shape
error text, successful test/build events, test XML and contract sources. Negative
controls fabricate an accepted output or omit a witness while updating its hash;
both are rejected. All integrated checks pass. Lean size remains unchanged.
Kernel certificates and independent source correspondence remain open, as do
the unprocessed source families and the full automatic-verification verdict.

Subsequent update: the static-axis kernel certificates and fresh-directory proof
replay are now recorded in reports/empty-slice-formal-refutation.md. Independent
source correspondence, machine-range refinement and the full corpus remain open.
