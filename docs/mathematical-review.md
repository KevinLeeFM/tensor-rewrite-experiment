# Mathematical foundation review and clean replay

The current mathematical foundation is frozen for separate semantic review at
commit `9bcd44756cbf5261a0c690e05651e96fa162319a`. The packet's review brief is
`reviews/packets/mathematical-foundation-v1.md`; its JSON descriptor pins a zip
archive and a268-file manifest. Mathematical sources, tools, controls, retained
abstract benchmark records and scope/measurement protocols are included.
C++ sources, native fixtures/results and dependency caches are excluded.

## What has been reproduced

`tools/replay_mathematical.py` checked out the committed snapshot in a new
temporary directory. The project's `.lake/build` did not exist before the run;
project build artifacts were not copied. The cold compiler transcript records105
project modules built. The remaining tracked Lean file under the project module
paths is `TensorRewrite/Pilot/Audit.lean`, a standalone import/axiom-print script;
it was checked separately with exit0.

All12 mathematical replay stages passed, including the library build/audit,
theory build/audit, logical-family and all convolution-model controls, the broader
mathematical ledger and23 accounting tests. All fields of nine generated JSON
results match the committed baseline. Mathematical source files stayed unchanged;
only the two generated build transcripts differed in the replay checkout.

Ten pinned dependency checkouts and their compiled caches were reused. Their Git
revisions match the Lake manifest, and tracked dependency sources were clean
before and after replay. Upstream libraries were not rebuilt from scratch. This
is a clean project replay with disclosed dependency reuse; independent semantic
inspection remains a separate gate.

## Review gate and limits

The packet requests inspection of mathematical meanings and assumptions, rank and
extent generality, empty cases, coordinate/domain equivalences, exact versus
ordered numerical observations, controls, proof dependencies and code counts.
The reviewer must use the frozen inputs, identify inspected declarations and
limits, and report concrete issues before changes are integrated.

The packet does not request source correspondence, C++ extraction, native pass
investigation or a full-workload verdict. It retains the current limits:89 theory
statements,319 registered declarations,4165 custom Lean lines,488 benchmark
records and zero whole records closed. Mathematical N/F, the diverse reviewed
pilot, full campaign and residual diagnosis remain open.

The user authorized the mathematical reviewer, whose independent result is
`reviews/results/mathematical-foundation-v1-review.md` (and JSON companion).
The reviewer found no false statement in the inspected 89-statement foundation,
but requested two bookkeeping corrections: MF-01 (30 omitted retained declaration
references) and MF-02 (12 counterexample lines misclassified as correctness proofs).
See `reports/mathematical-review-corrections-v1.md` for the response and limits.
The reviewer separately replayed all 12 stages and probed 2,160 geometries with
5,968 sample comparisons. Raw logs and scratch sources are preserved in
`reviews/results/mathematical-foundation-v1-evidence.zip` with a hash manifest.
The original packet and integrator replay remain immutable historical evidence.

## Verify the frozen evidence

```sh
python3 tools/freeze_mathematical_review.py --verify
python3 tools/check_mathematical_review.py
python3 -m unittest discover -s tests -p test_mathematical_review_readiness.py -v
```

The readiness checker verifies archive/manifest/file hashes, binds packet sources
to the target commit, validates replay commands, logs, actual test counts,
complete JSON comparisons, dependency pins and claim boundaries. Three additional
accounting tests reject skipped replay stages, false semantic-review/full-workload
claims, changed results/dependencies, and altered packet contents even when the
archive envelope hash is updated.

For a new replay attempt, use a new report name rather than replacing v1:

```sh
python3 tools/replay_mathematical.py --ref 9bcd447 --report reports/mathematical-clean-replay-v2.json
```

The source snapshot and replay evidence are preserved separately from the moving
worktree. The current v1 report/validator is deliberately bound to this baseline;
a later reviewed extension needs a separately versioned packet and record.
Code correspondence remains future work.

## Correction closeout

The final independent recheck at `4273260` closes MF-01, MF-01-R1 and MF-02
with no remaining finding in that correction scope. The witness metadata now
matches its exact-integer model, ledger regeneration matches committed bytes,
and all31 baseline tests pass. The reviewer reused verified project/dependency
artifacts for this narrow final replay and preserved portable evidence in
`reviews/results/mathematical-foundation-v1-final-correction-recheck.json`.
Its Markdown companion records inspected scope and all limitations.

The reviewed basis remains349 declarations/89 theory statements/4165 custom
lines. The later scalar-domain milestone at `27937c1` raises current totals
to363/103/4283; its14 new statements were excluded from the old review and
await independent review. No whole retained record is closed by this review.

## Scalar/reduction extension packet

The separate packet `reviews/packets/mathematical-extensions-v1.md` freezes source
commit `1714add` in a353-file mathematical-only archive with a per-file manifest.
Its descriptor and archive were committed at `bb9b58d`. It requests inspection
of the41 additions (14 scalar,27 reduction), their definitions/assumptions and
the60-record reduction formulation worksheet. The original89-statement review
does not cover these additions. New reviewer authorization has been requested
under the session's subagent constraint; dispatch is pending. No other review
status or full-workload acceptance follows from packaging.

Verify the new packet against exact committed source bytes:

```sh
python3 tools/freeze_mathematical_extensions_review.py --verify
```

Current totals are130 theory statements/390 ledger declarations/4598 custom Lean
lines, with four integration theorems separate. All38 focused worktree tests
pass; the isolated packet needs35 of those tests (the three old packet-readiness
tests remain historical evidence outside this new review).

The v1 isolated preflight found a missing `reports/pilot-values.json` accounting
input after its Lean build/axiom audit passed. V1 remains preserved as incomplete
packaging. The v2 packet adds the report with unchanged41 statements/Lean sources;
use `tools/freeze_mathematical_extensions_review_v2.py --verify` for v2.
This is an infrastructure correction, not a mathematical refutation.

V2 isolated replay passed: all35 packet tests and five complete JSON result
comparisons match the frozen snapshot. Project build outputs were absent at
start; the cold compiler transcript is preserved with the report. Ten dependency
source/compiled caches were reused with matching revisions and clean tracked
sources before/after; upstream libraries were not rebuilt. This is an integrator
reproduction, not independent semantic review. Exact commands, hashes and limits
are in `reports/mathematical-extensions-preflight-v2.json`. The41-statement
review scope is unchanged from the authorization request; dispatch remains pending.
