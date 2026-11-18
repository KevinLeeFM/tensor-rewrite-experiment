# Independent review: rounded `log(sqrt(x))`

**Verdict:** The frozen positive binary32 mathematical model has a valid mismatch. At the immediate binary32 successor of 1, correctly rounded `sqrt` produces exactly 1, while the stated strict rational interval places `log(1+2^-23)` inside the rounding cell for significand `m=2^24-1`. Halving that rounded log result is exact and nonzero. The kernel theorem verifies the rational-certificate implication; real logarithm bounds and native/backend `log` behavior remain mathematical/source assumptions, not Lean formalization or runtime evidence.

## Source and exact arithmetic check

The packet hashes for `LogSpec.lean`, `FREEZE.md`, and the pinned `algebraic_simplifier.cc` matched in the fresh replay. At lines 5539–5545, `HandleLog` matches `Log(Sqrt(a))`, builds `Log(a)`, and replaces the original with multiplication by scalar `0.5`. No positivity or precision-mode check is in this local branch; the packet explicitly scopes to F32 and positive finite x. The source code establishes the graph rewrite, not correctly rounded backend evaluation.

Let `t=2^-23` and `q=2^-47=t²/2`. The F32 input `1+t` is the immediate successor of 1. The midpoint between 1 and `1+t` is `1+t/2`; because `1+t < (1+t/2)^2`, `sqrt(1+t) < 1+t/2`, so positive correctly-rounded sqrt is 1. Thus the original result is `log(1)=0`.

For the replacement's log, `m=2^24-1`, `v=mq=t-q`. The exact rounding cell for this interior representable value has strict midpoint bounds `v-q/2` and `v+q/2`. The alternating-series bounds for `0<t<1` are

` t - t²/2 < log(1+t) < t - t²/2 + t³/3 `.

The lower endpoint is `v`, strictly above the lower midpoint. The upper endpoint is `v+t³/3`, strictly below `v+q/2`, since `t³/3 < q/2`. This is the correct binade: `2^23 < m < 2^24`, so the log result is in `[2^-24,2^-23)` with spacing `q`. Hence correctly rounded log has value `m q`. Multiplication by 0.5 is an exact exponent shift to `m 2^-48`; this is a normal exactly representable value just below `2^-24`. In the model's units it differs from original zero because `m≠0`.

The zero case `u=0` gives exact root/log zero and the agreement control. `u=2` is rejected by the root-cell check. `m=16777214` is outside the true log's cell. The `m=16777216` rejection is due to the strict internal-binade guard, not a midpoint inequality; that value is the boundary float in the next binade. The actual result is the lower interior value, and the freeze correctly treats the boundary candidate as excluded from this grid. This distinction should be retained when describing the control.

The Lean definitions do not import a real-analysis library or define a machine `log`: `logRead` is a Boolean predicate that checks the rational inequalities above. The source-facing interpretation therefore assumes the standard alternating-series fact and correctly-rounded elementary functions. This is an explicit limitation rather than a defect in the rational witness. The proof is not evidence that XLA's native math implementation or any backend returns these exact bits.

## Replay, controls, and trust boundary

Fresh command: `LEAN=/workspace/toolchains/lean-4.35.0-linux/bin/lean python3 comparisons/revised-benchmark-20261117/log-rounded-sqrt/replay.py`. Fresh Lean 4.35.0 targets `LogSpec`, `LogProof`, and `LogControls` exited 0; times 0.523, 0.305, 0.276 seconds (sum 1.104 s), total shell wall 1.144 s. All three frozen source/spec hashes matched. Axiom report for `refuted`: `[propext, Classical.choice, Quot.sound]`, all standard Lean axioms; no project-added axiom, admission, or native evaluation. The controls check zero agreement, neighboring significand outcomes and a root boundary. The witnessed mismatch is nonvacuous: the exact integer certificate for `u=1,m=16777215` compiles, and the conclusion contradicts `0=m`.

No setup, download, Lake or broad build. Replay ran 2026-11-18 04:54:55–04:54:56 UTC. Source-review start and total reviewer active/wall time were not instrumented separately; only command and compiler time are measured. No speedup or native-correctness claim. See `review.log`.
