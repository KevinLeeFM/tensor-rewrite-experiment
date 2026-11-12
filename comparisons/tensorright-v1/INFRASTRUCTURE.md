# Infrastructure, reuse and effort

Measured at `fd89bdf`; exact inventories and Git timestamps are in
[infrastructure-costs.json](infrastructure-costs.json). No new Lean proofs were
needed for this accounting review.

The main maintained Lean source has **15,273 code lines in 271 files**:
9,509 Theory, 2,991 Pilot, 2,168 paper-comparison, 503 earlier tactic-comparison
definitions, 30 library adapters and 72 root-module lines. Imports, declarations
and axiom-audit commands count; blank and comment-only lines do not. The earlier
15,240 subtotal excluded the 33-line `TensorRewrite.lean` root module.
Across all tracked Lean files, including generated audit reports, tests and earlier
trial files, there are **32,986 physical lines in 563 files**, including comments
and blanks. That is not a code-only figure or a minimal proof-size figure.
The existing strict code counter rejects interpolated strings in 29 test fixtures,
so no exact repository-wide code-only total is asserted. External libraries,
build caches and archived ZIP copies are excluded from both inventories.

## What the reusable code does

- Pilot defines tensors as functions over bounded coordinates, shape and index
  arithmetic, permutations, basic operations and earlier graph experiments.
- Theory defines reductions, convolution windows, slicing, padding, concatenation,
  updates and other operators, then proves reusable properties of their indices
  and values. Much of it is domain-specific mathematics, not generic logic.
- Exact scalar laws reuse Mathlib/Std. Optional word/float, Scatter and bit-packing
  developments support broader experiments and are not prerequisites for the
  paper's exact-number comparison.
- Comparison files instantiate those laws or add missing case-specific arguments.
  Python inventories, replay scripts, axiom audits, diagnostic fixtures and pinned
  source archives make results reproducible and preserve counterexamples.

## Measured reuse

| Module | Paper cases | Local code lines | Imported custom code lines |
| --- | ---: | ---: | ---: |
| Add | 4 | 33 | 364 |
| Remainder | 4 | 65 | 143 |
| GroupedSums | 9 | 163 | 1,387 |
| SignedPad | 4 | 214 | 448 |
| MixedConvolution | 1 | 106 | 744 |
| PadConvolution | 1 | 103 | 666 |

These are whole-module import closures, not exact counts of the lemmas used by
proof terms; shared totals cannot be added. The full comparison's 6,966 lines
consist of 2,168 comparison lines plus 4,798 earlier custom lines. Of the 79
imported custom modules, 56 (3,135 lines) occur in at least two comparison modules'
closures. Only 3,810 of Theory's 9,509 lines are in this comparison's closure.
The other 5,699 lines may serve broader experiments but are not demonstrated
investments in this particular benchmark.

Direct proof calls give stronger examples of actual reuse: Add's four proofs,
ScalarArithmetic's ten proofs and numeric double negation all apply the existing
`ArithmeticFamily.rewrite_sound`. The two previously unresolved remainder cases
both use `Remainder.signed_shift`. The final `PadConvolution.term_fusion` calls
`PadWindow.contribution_fusion`, which the earlier window-reduction proofs also
use. Thus established padding geometry is reused for convolution instead of
being proved again. The final convolution equality has a six-line proof body,
but its entire new module is 103 lines; the helper and model cost must not be hidden.

## Timing limits

There is no reliable measurement of time to construct the very first proof or
the final individual proof. The earliest pilot predates the repository's first
commit. Within the paper-comparison phase, Git author timestamps in America/Toronto
show these batch intervals on 12 November:

- Plan checkpoint 00:57:28 to first four Add cases at 01:11:02: **13m34s**.
- Next commit at 01:18:11: **24 more proved cases in 7m09s** between commits.
- 110 proofs at 03:00:13 to final report/116 proofs at 03:35:38: **35m25s**,
  containing six further proofs, the vacuity finding and final auditing/reporting.
- Plan checkpoint to final comparison commit: **2h38m10s**, after the substantial
  earlier infrastructure investment.

These are timestamp intervals, not per-proof timings, and work need not be confined
to the interval of its commit. They mix reuse, development, diagnostic execution,
auditing and documentation. The earlier ~32-hour goal-time report is another,
broader measure and must not be interpreted as this comparison's proof time.

The structural evidence shows that reuse removes repeated mathematical work.
It does not establish a numerical speedup, a monotonic first-to-last improvement,
or that all infrastructure was necessary. Easy reused cases were completed first;
later cases required more geometry. A controlled fresh batch with fixed initial
libraries would be needed to measure marginal effort and generalization.
