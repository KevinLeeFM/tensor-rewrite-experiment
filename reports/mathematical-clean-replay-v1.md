# Clean mathematical replay and frozen review packet

Target: experiment commit `9bcd44756cbf5261a0c690e05651e96fa162319a`.
All12 mathematical replay stages passed in a fresh Git checkout. The project
build directory was absent at the start, and the cold compiler transcript
records105 project modules built. Mathematical definitions/proof sources stayed
unchanged. The only tracked file changes in the replay checkout were generated
library/theory build logs.

`TensorRewrite/Pilot/Audit.lean` is a standalone import/axiom-print script rather
than a default library build target. It was inspected as such and checked
separately with exit0. The consolidated mathematical audit checks319 registered
declarations, and the theory audit checks89 statements using standard Lean axioms.
No native pass or source-correspondence tool was run.

The replay covered library integration, mathematical theory, the typed logical
family, the base/pointwise/Dot/mixed-window/ordered convolution models, the broad
ledger, and23 mathematical accounting tests (16 convolution,4 logical,3 ledger).
All fields of nine generated JSON artifacts reproduce the committed baseline.
The outputs include all488 retained benchmark records and unchanged proof-size,
axiom, control and coverage data. Whole records closed remains0; mathematical
N/F and the full research verdict are still open.

Ten dependency Git revisions and tracked-source cleanliness were verified before
and after the run. Their source and compiled caches were shared with the existing
workspace; upstream libraries were not rebuilt from scratch. Project outputs were
rebuilt in the new directory. The replay is a reproducibility check performed by
the integrator, not an independent semantic/statement review.

A separate mathematical review packet now freezes268 files, excluding C++ sources,
native fixtures/results and dependency caches. Its brief asks for inspection of
logical-family completeness, geometry, coordinate equivalences, exact/ordered
numerics, controls, assumptions and code-size attribution. The archive and every
file are hash-checked and tied to the target Git snapshot. Independent review
is pending authorization for this new packet; the earlier census/pilot review
authorization is not relabeled as mathematical review.

Three new review/replay accounting tests pass. They reject skipped stages,
changed recorded results, dependency drift, false semantic-review/full-workload
promotion, and changed packet contents under an updated envelope hash.
No Lean was added in this milestone: the custom subtotal remains4165 lines.
New Python orchestration and its tests are separate infrastructure, not new
rewrite proof coverage.

Evidence:

- `reports/mathematical-clean-replay-v1.json`: exact steps, commands and result comparisons.
- `reports/mathematical-clean-replay-v1-logs/`: stage transcripts and the cold compiler/standalone-audit logs.
- `reports/mathematical-clean-replay-v1-observations.json`: build-module and source-tree observations.
- `reports/mathematical-review-readiness-v1.json`: packet/replay linkage and explicit pending review status.
- `reviews/packets/mathematical-foundation-v1.{md,json,zip}` and its manifest: frozen review request/inputs.
- `docs/mathematical-review.md`: verification and new-attempt instructions.

Next obtain separate mathematical review, address any findings in versioned
extensions, and continue formal statement/domain partitions across the remaining
workload. Code correspondence remains user-deferred future work.
