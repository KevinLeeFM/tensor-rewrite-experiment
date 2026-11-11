# Mixed-window product/reduction proof and mathematical domain worksheet

The exact convolution theory now covers mixed unit-kernel/spanning-output axes.
A one-input-channel convolution equals a broadcast/reindexed product reduced only
over nonunit spatial kernel axes. Selected spatial reversals move onto the kernel
operand. The proof derives bounded coordinates from the actual unpadded,
undilated, unit-stride window, then constructs a full contribution-domain
equivalence. It removes both unit axes and the sole channel; the target has no
optional sampling or window-coordinate arithmetic.

Eleven statements pass kernel checking and standard-axiom audit. The exact
Semiring contract uses same-type products/accumulation/results, with no output
conversion; multiplication need not commute. Ranks, extents, groups, batches,
output features and selected reversals are arbitrary. Zero extents are included:
an empty spanning kernel can leave a nonempty output, returning the empty sum.
No IEEE, numerical-conversion, physical-layout or source correspondence claim
follows from the finite-sum reindexing proof.

Eleven profiles compare123 outputs and reduced-domain observations with an
independent general integer-convolution oracle. They cover spanning and reversed
spanning kernels (14 versus10), grouped mixed axes, a three-axis window, all-unit
and all-spanning kernels, rank zero, empty kernel/output and absent groups.
All20 mathematical accounting tests pass. New reporting tests reject lost
reversal/domain evidence, conversion promotion, dropped retained records and
unsupported denominator/family-completion claims.

A versioned mathematical domain worksheet retains all31 convolution records,
including12 multiply/reduce variants (nine with conversions) and seven
helper-composition references. It records explicit remaining numerical, type,
shape/broadcast, layout and composition questions. These are mathematical
formulation gaps, not proved source facts. The worksheet does not freeze the
mathematical obligation denominator or close full benchmark records.

The extension adds226 custom Lean lines: S51/H138/R36/A1. Total custom Lean is3924:
S1101/H1392/R1019/A75/C337. Imported libraries, audit/semantic fixtures and Python
tools are counted separately. The theory target has74 registered statements and
the broader ledger audits304 distinct declarations. All488 retained records
remain:405 need formulation,71 have partial model evidence and12 carry the
declared logical-value family; see `census/mathematical-ledger.json`.
Whole records closed remains0. The declared logical-value family remains20
profiles; this milestone adds partial exact convolution evidence.

Source and worksheet pins: `census/convolution-separable-v1.json`. Exact control
and axiom output: `reports/convolution-separable.json` and
`reports/theory-progress.json`. Statement and reproduction guide:
`docs/convolution-separable.md`. Code correspondence remains future work.

Next: formulate numerical accumulation/conversion contracts and the remaining
padding/composition/representation partitions, obtain independent statement
review, and continue the diverse full-workload campaign and residual diagnosis.
A global positive or negative workflow verdict is still unsupported.
