# Pointwise convolution: a checked channel-only reduction

The convolution milestone now proves the exact mathematical identity from a unit
spatial kernel to a channel reduction, and its one-channel product corollary.
The proof derives unchanged spatial shapes, the unique kernel coordinate and
successful bounded sampling. An equivalence eliminates the original spatial
kernel loop. This is partial mathematical progress toward the retained workload;
no whole benchmark record, full convolution family or research verdict is closed.

The premises are explicit: kernel extents one, stride one, base dilation one,
and zero padding on every spatial axis. Kernel dilation and reversal remain
unrestricted within the positive-dilation model. Ranks, extents, groups, batches
and channel counts are arbitrary. The scalar contract is exact Semiring, with
same-type values, products, accumulation and results, and no finish conversion.
Multiplication may be noncommutative. IEEE operations, precision conversion and
physical layout are not established by these theorems.

Thirteen new statements pass kernel checking and the transitive-axiom audit.
Eight finite profiles exercise78 output coordinates; the original convolution
and separately defined channel sum agree with an independent integer-convolution
oracle. Two profiles with no outputs are explicitly retained. The grouped 2D
profile exercises64 outputs with multiple batch/feature groups, batches, input
channels and output features. Reversal and kernel dilation7 also agree for a
unit kernel. Rank zero with input `[1,11]` and kernel `[3,4]` gives47; zero channels
gives0 on nonempty output domains. These runs inspect model meaning; they do not
replace the arbitrary-size proofs.

The extension adds175 custom Lean lines: S33/H73/R68/A1. Total custom Lean is3493:
S1000/H1159/R924/A73/C337. Imported dependencies, Python tools, Lean control fixtures
and audits remain separate from that subtotal. The theory target has51 registered
statements. The broader ledger audits281 distinct declarations and retains488
benchmark records:407 need formulation/domain partitions,69 have partial model
evidence, and12 have the completed declared logical-value family. That family
still has20 declared profiles. Whole benchmark records closed remains0.

All14 mathematical accounting tests pass. They include rejection of omitted or
changed semantic results, broken base/extension pins, and illicit promotion to
Dot, IEEE, physical layout, independent review or whole-family completion. The
prior convolution and logical-family checks also pass. Standard Lean axioms are
the only dependencies recorded for accepted theorems.

The versioned inputs are in `census/convolution-pointwise-v1.json`; exact output
and axiom evidence are in `reports/convolution-pointwise.json` and
`reports/theory-progress.json`. The broader audit is in
`reports/mathematical-ledger-audit.{lean,log}`. The statement, declarations and
reproduction commands are documented in `docs/convolution-pointwise.md`.

Remaining: prove the mathematical coordinate/flattening bridge to the existing
Dot model, formulate the other geometry and numerical partitions, obtain
independent statement review, complete the diverse pilot and full-workload
campaign, diagnose residuals, and perform independent final replay. Code
correspondence remains user-deferred future work.
