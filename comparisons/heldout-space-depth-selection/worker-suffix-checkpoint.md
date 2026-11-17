# Worker suffix checkpoint

## Result

Added `WorkerSuffix.lean` with `Heldout.WorkerSuffix.suffix_extents`. For every
`Conditions shape inner outer` and every remaining suffix index
`k : Fin (rank - moved - 1)`, it proves the actual original tail extent at
`2 + k.val` equals the actual replacement tail extent at `1 + k.val`.
The theorem uses `cutShape`, `replacementCutShape`, and the actual ordered
chunk output shape. It does not assume the desired equality or add a source
invariant.

The proof splits on the exact width-axis boundary. The width case uses
`innerWidthAxis` and `chunk_output_shape`; the preceding and following regions
use `between_moved_split` / `after_split` with `prefixAxes` / `suffixAxes`.
All reasoning is by extent equality, so zero extents require no special
nonemptiness assumptions. If the suffix domain is empty, the universal result
is vacuous, as required.

## Validation

Compiled offline with Lean 4.35.0 (`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`)
against a fresh temporary OLean closure in `/tmp/suffix-proof-olean`. The exact
worker module compiled with no warnings. `#print axioms suffix_extents` reports
`[propext, Classical.choice, Quot.sound]`; it does not depend on `sorryAx`.
The frozen files and existing source modules were not edited.

Attempted a standalone file to instantiate the repository's named nonempty,
one-chunk, empty-input, and zero-width plans. Those test declarations are not
exported from `GoalCandidateTests.lean`, so they are unavailable to an importing
module. That failed test file was removed; this limitation is not a theorem
failure. The worker theorem remains fully quantified over `Conditions`,
including zero-extent plans.

## Time

Focused elapsed time was approximately 7 minutes: about 1 minute reading
instructions/definitions, 4 minutes proof development and repair, and 2 minutes
fresh targeted compilation. Initial compile failures and cast/index repairs are
preserved in `worker-suffix-failure.log`. No broad build or download was run.

## Handoff limits

This result covers only suffix extents. It does not prove suffix index
coordinate equality, the frozen rewrite goal, or any C++ correspondence.
