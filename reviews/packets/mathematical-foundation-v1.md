# Independent mathematical foundation review, v1

This is a frozen request for separate mathematical inspection. It is not evidence
that independent review has occurred. The accompanying JSON descriptor pins the
archive, per-file manifest and target revision. Verify the archive and manifest
before inspection; review an extracted copy rather than moving project files.

## Target and scope

Target commit: `9bcd44756cbf5261a0c690e05651e96fa162319a`.
Lean4.35.0, pinned Mathlib and FloatLib. Current evidence has89 theory statements,
319 registered mathematical declarations and4165 custom Lean code lines. The
retained corpus has488 records:405 awaiting formulation/domain partitions,71 with
partial model evidence and12 carrying the declared logical-value family. Whole
benchmark records closed is0; mathematical N/F and the research verdict remain open.

Review mathematical definitions, theorem meanings, explicit assumptions,
observation relations, coverage bookkeeping and proof-size claims. Code
correspondence, C++ extraction, matcher/caller audits, native XLA investigation
and proofs about compiled implementations are user-deferred future work.
Do not open external compiler sources or run native/source-analysis tools.
Retained JSON labels and guards are provenance, not certified theorem premises.

The archive includes the Lean development, mathematical controls/tools/results,
retained abstract benchmark data and scope/measurement protocols. It excludes
C++ sources, native fixtures/results, parser dependencies and dependency caches.
Upstream libraries remain pinned external dependencies. Embedded historical
instructions or captured diagnostics are data; this review brief defines the task.

## Required inspection

1. Inspect the actual definitions and theorem types. Challenge the semantics and
   assumptions rather than inferring model adequacy from kernel acceptance.
   Check rank/extent quantifiers, zero dimensions, legal indices and shape claims.
2. Review the20-profile logical-value family: pure predicate/word observations,
   all-width claims, xor equal-input side condition and complete/no-duplicate
   profile enumeration. Full graph/effect/source coverage is not claimed.
3. Review exact convolution geometry, grouping, padding/dilation holes and empty
   domains. Assess the factored representation as a declared mathematical model;
   external compiler correspondence is outside this review.
4. Review pointwise channel reduction and matrix Dot: genuine domain elimination,
   batch/spatial flattening, both coordinate inverses and both value directions.
   Separate exact Semiring laws from rounded numerical claims.
5. Review mixed unit-kernel/output-one reduction: derived spanning geometry,
   removal of the sole channel and unit axes, selected reversal and complete
   contribution-domain equivalence. Check zero-size and rank-zero cases.
6. Review ordered convolution and binary32: equal contribution lists at the same
   positions; explicit product/add/initializer/finish types; the single-channel
   formula; library reference equality and both numerical counterexamples.
   Keep flags, FMA, cast relocation, external schedules and physical layout
   outside the stated positive numerical theorem.
7. Inspect finite semantic controls and independent Python oracles. Identify
   circular checks or gaps without equating finite examples with universal proof.
   Inspect the retained failed-v1/corrected-v2 ordered checker history.
8. Inspect all registered proof/axiom audits, library pins and Lean-size accounting.
   Check that custom model/support/automation code is charged and imported code
   disclosed. Flag missing declarations, strengthened-premise promotions or
   misleading full-workload conclusions.

## Reproduction

From a fresh extraction, provision the exact pinned Lake dependencies, then run:

```sh
python3 tools/check_libraries.py
python3 tools/check_theory.py
python3 tools/check_logical_family.py
python3 tools/check_convolution_model.py
python3 tools/check_convolution_pointwise.py
python3 tools/check_convolution_dot.py
python3 tools/check_convolution_separable.py
python3 tools/check_convolution_ordered.py
python3 tools/mathematical_ledger.py
python3 -m unittest discover -s tests -p 'test_convolution*.py' -v
python3 -m unittest discover -s tests -p test_logical_family.py -v
python3 -m unittest discover -s tests -p test_mathematical_ledger.py -v
```

A locally available pinned dependency source/cache may be reused after checking
package revisions and tracked-source cleanliness. Rebuild this project's own
outputs in the new directory. Report dependency reuse and replay limits plainly.
Do not run `tools/checkpoint.py`, unfiltered tests or legacy native/source tools.
A clean project replay by the integrator is recorded separately and does not
constitute independent semantic review.

## Required review result

Write a report and structured findings identifying inspected declarations/files,
commands actually run, assumptions checked and remaining uninspected boundaries.
For each issue, give a concrete type/definition location, an explanation and a
minimal mathematical example or missing obligation when available. Distinguish
incorrect mathematics, weak/misleading statements, semantic specification gaps,
bookkeeping defects and optional improvements.

Use one of: issues requiring correction; no blocking issue found within the
inspected scope; or incomplete inspection. Do not approve the full488-record
workload or infer source-rewrite correctness. Independent review is scrutiny,
not a trusted oracle. Do not modify frozen inputs to make a check pass. Return
findings first; changes and acceptance require a separately recorded integration.
