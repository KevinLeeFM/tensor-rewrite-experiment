# Held-out workflow smoke checkpoint

**One narrow mathematical model partition proved; zero additional complete source branches claimed.**

The new target is rank-one to rank-three Nat-valued reshape-Iota mixed-radix arithmetic, all dimensions >1, arbitrary bounded coordinates. No matching target was found in this repository's existing proof statements and 118 paper cases. The candidate DynamicSlice/transpose was rejected because paper rule04 already covers that labeled rewrite. Lack of a census link is not evidence of novelty.

Frozen specification and five-module provisional generic allowlist are in `frozen-manifest.json`. Whole-library inventory covers 241 modules/1,573 lexical declarations, but semantic review was selective: **not a fully cleaned library**. Entire Theory root, target-specific ArithmeticFamily rules and similar rewrite proof modules remain excluded. This case imports only the FiniteProduct definitions, so it does not measure the benefit of the other allowed lemmas. Existing reusable modules were not edited.

Independent reviewer accepted the mathematical smoke scope, with explicit caveat that it is easy packing/algebra and not broad productivity evidence. Source transcription review and novelty search were performed by the preparing worker. The trial is not blinded. See `review.md`, `STATEMENT.md` and `Spec.lean`.

## Measured effort and checks

- Follow-on source/overlap review first observed 22:42:23 UTC. Earlier inventory stage first observed 22:37:27; true initial setup start unavailable.
- Isolated setup: five modules + spec, 3.322 seconds compiler time.
- Proof-development interval 22:46:59.278539–22:47:45.462787 UTC, **46.184 seconds**, including messaging/tool latency; one successful attempt, 0.478 s Lean. This is not pure reasoning time.
- Final validation: proof replay 0.732 s; audit initially failed decidability synthesis (0.462 s), fixed by unfolding the unchanged guard, then passed (0.485 s). Failure preserved in ledger.
- Guard has explicit [2,3,4] witness; original at [1,2,3] is 23; deliberately wrong RHS omitting outer term is 11. 729 preproof mathematical coordinate checks, zero mismatches. Not native XLA tests.
- Exact `Goal` check and transitive axiom report passed; theorem uses only `propext`. No sorry/admit/native_decide/project axioms. Frozen hashes unchanged.
- Token counts and exact runtime model unavailable. No historical per-proof baseline exists, so **no speedup claim**.

Run `LEAN=/path/to/lean python3 comparisons/heldout-v1/replay.py` from this worktree. Lean 4.35.0 required. Only Std and the allowlisted custom files are rebuilt, with independent local import search path; no dependency fetches. Generated build files are excluded.

This validates the freeze/build/exact-goal/negative-control/timing workflow cheaply. It is too small and too specialized to establish meaningful proof productivity. Next useful step, if desired, is one complete abstract rewrite statement with nontrivial shape quantification (e.g. inserted-unit-dimension reverse), independent statement review, then the same frozen-library protocol. No large campaign has started.
