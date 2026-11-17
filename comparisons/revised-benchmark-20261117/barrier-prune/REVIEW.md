# Independent review of barrier tuple pruning

**Accepted for the per-GTE logical-value observation in both operand modes.** This is one shared Lean theorem with two admitted mode values, attached to two distinct retained source records. Both whole-record outcomes remain unresolved. I reviewed and replayed the work independently of its proof author.

## Source and scope

- XLA pin `e58e523b11f1fde802a493a776d158007486e1bf` in [sources/manifest.json](../../../sources/manifest.json). The [simplifier handler](../../../sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc#L5575) at lines 5575–5650 matches the frozen file hash and the census body SHA-256 `e067cdb19de7a0e3196c79b80eb71d986b0b646dbd6fe21f25143bff39e502f7` over that span without the last newline. The [layout census](../../../census/layout-cases.json#L817) and [independent normalization record](../../../reviews/results/census-pilot-v1-shape-layout-source-normalization.json#L11012), the latter matching registry hash `58b48cdcf6ffa778d4e082c6932a00956c15338b768d574f168f00a43bcab`, describe one shared action and two source mode records. Source line 5617 establishes that compaction proceeds only if a position is dropped.
- The source checks tuple-shaped non-root barrier and all GTE users (5577–5596). The keep mask includes every selected position and every **direct** token slot (5591–5601). For a `kTuple` operand, it also includes otherwise droppable components whose producing instruction has more than one user, equals the computation root, or has a side effect (5603–5615). In the other mode the extra producer predicate is ignored. The Lean proof universally quantifies the flag and both component predicates. The correspondence between input list slots, legal GTE indices and actual source predicates is a model interpretation.
- In the increasing source scan (5622–5636), the counter starts at zero and increments iff the mask retains the slot. Thus a kept original index maps to the number of retained strictly earlier slots, exactly `newPosition`. The retained values are appended in original order. The `kTuple` arm forwards the existing operand at that slot. The non-`kTuple` arm constructs a GTE at the **original** index on the original operand and then inserts its result in the new tuple. The actual barrier users select using the **new** index (5645–5647). Both arms therefore consume the same ordered old values in the model. Source-reading support for the logical interpretation includes the pinned [evaluator](../../../sources/xla/xla/hlo/evaluator/hlo_evaluator.cc#L3304) (tuple order at 1689–1724, barrier operand clone and GTE subliteral access at 3304–3334), independently matched to its [supplemental manifest](../../../sources/dynamic-index-contract-manifest.json), and the separately [reviewed tuple projection model](../tuple-projection/REVIEW.md). The projection model is supporting interpretation and contributes no proof import here.
- The exact observation is `some xs[i]` after optional lookup in the compacted list at the new index, for **every** original in-bounds index appearing in the user list. It establishes defined access and preservation of the particular logical component value, including arbitrarily many (or repeated) users by pointwise quantification. The carrier is a universe-polymorphic type and may represent heterogeneous values using tagged sums. There is no fixed arity, built-in numerical law, assumed rewritten value, or arbitrary map witness. Other user-list entries outside the original arity are inert in the pure model. A legal source use list instead consists of in-range GTE uses. All-kept cases satisfy the broader pure identity while the source exits without rewriting. Empty input and all-dropped masks admit no selected index. With no users, retained token slots can still give a nonempty compacted tuple, yet the user observation is empty.
- Parent obligations remain beyond this observation. They include shape/type/layout and memory-space obligations for the ordered compacted tuple and GTE results, preservation of relevant effect/token/control dependencies and DCE behavior, complete old-to-new map including the dropped `-1` entries and the two `CopyOriginalValue` metadata updates, and the ordered graph mutations and status/failure boundaries. In particular the fully dropped/no-user nonempty input can produce an empty tuple; the theorem has no user to check in that case and gives no separate shape/effect/metadata result there. The branch guards, the source’s early returns, and success/failure sequencing are understood from source, outside the theorem. No source-level reachability, C++–Lean correspondence or implementation bug is inferred.

## Exact proof and replay

Freeze `4160b573c55151570dc9db28b256924b7a175c04`. Candidate `5e5c85f12fbcd03818f03dfa6fb0d4d223da8771` adds only `PruneProof.lean`. The packet contract, spec, manifest, source and toolchain pin are unchanged. All three frozen SHA-256 entries match. The fresh compiled proof has SHA-256 `3efa6638dedbf437065efae76490eb396417777562f5a15450fdf32a28d8c2dc`. The complete custom closure is `PruneProof → PruneSpec → Std`; only the exact pinned distribution supplies the upstream closure. I inspected both local modules including the source-defined `keep`, `compact`, `newPosition`, and `Goal`. The private prefix lemma equates filtered-position count and compacted prefix length using the standard `zipIdx` specification. The second private lemma puts the kept head immediately after that prefix. The terminal proof splits the original list at the Fin index and applies these two lemmas. No proof dependency reaches another project module or a previously asserted rewrite. I found no proof placeholders, native evaluation, new axioms or unchecked definitions in the packet.

Fresh Lean 4.35.0, x86_64 Linux, commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`, replayed the raw commit sources plus an independently written fully quantified type check. Both `preserved` and the expanded `exactReplay` have exactly `[propext, Quot.sound]` transitive axioms. The successful module checks exited 0 with no warnings. Admitted duplicate uses at original slot 3 preserve distinct value 44, with a leading/trailing drop, token slot 1, protected slot 2, and mode-specific ranks 2 and 1. The kernel-checked probes reject the old rank, a one-less rank, and cross-mode ranks (one selects the wrong value, one is missing). An intentionally false old-rank equality additionally failed compilation with exit 1 and the expected well-formed `decide` diagnostic. Extra model checks include empty input, nonempty all-dropped input, a token retained with no users, and all-kept identity. These are model instances, not source execution.

Independent assessment ran 21:57:21–22:00:34 UTC through report validation (193 seconds wall). Final command ran 21:59:21–21:59:23 UTC. Its fresh commands took 0.384 seconds (spec), 0.330 (proof and original axiom check), 0.412 (exact target, axiom and controls) and 0.324 (expected rejection), 1.450 seconds summed compiler wall time. The review included a missing external timing executable (no Lean invoked), two unsuccessful harness syntax attempts (reserved `protected` and whitespace before indexing, 1.128 and 1.138 seconds summed compiler wall), and a successful theorem/negative replay with a mismatched shell diagnostic string (1.589 seconds summed compiler wall). Those are review overhead, not proof failures. Supplemental evaluator hash was located in its separate manifest after checking the main manifest. Separate active/token costs and author discovery costs are unknown to this review.

### Reproduce from repository root

```bash
set -euo pipefail
freeze=4160b573c55151570dc9db28b256924b7a175c04
proof=5e5c85f12fbcd03818f03dfa6fb0d4d223da8771
packet=comparisons/revised-benchmark-20261117/barrier-prune
lean=/workspace/toolchains/lean-4.35.0-linux/bin/lean
tmp=$(mktemp -d /tmp/barrier-independent.XXXXXX)
trap 'rm -rf "$tmp"' EXIT
"$lean" --version
git show "$freeze:$packet/SHA256SUMS" > "$tmp/SHA256SUMS"
sha256sum -c "$tmp/SHA256SUMS"
git diff --exit-code "$freeze" "$proof" -- "$packet/CONTRACT.md" "$packet/PruneSpec.lean" "$packet/SHA256SUMS" lean-toolchain sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc
git show "$freeze:$packet/PruneSpec.lean" > "$tmp/PruneSpec.lean"
git show "$proof:$packet/PruneProof.lean" > "$tmp/PruneProof.lean"
sha256sum "$tmp"/Prune*.lean
cat > "$tmp/Audit.lean" <<'EOF'
import PruneProof
set_option autoImplicit false
open RevisedBenchmark.BarrierPrune
universe u

theorem exactReplay :
    ∀ {α : Type u} (xs : List α) (isTuple : Bool) (uses : List Nat)
      (token locked : Nat → Bool) (i : Fin xs.length),
      i.val ∈ uses →
      (compact (keep isTuple uses token locked) xs)[newPosition (keep isTuple uses token locked) i.val]? = some xs[i] :=
  RevisedBenchmark.BarrierPrune.preserved

def xs : List Nat := [11, 22, 33, 44, 55]
def flags (mode : Bool) := keep mode [3, 3] (· == 1) (· == 2)

example : (compact (flags true) xs)[newPosition (flags true) 3]? = some 44 ∧
    (compact (flags false) xs)[newPosition (flags false) 3]? = some 44 := by decide
example : newPosition (flags true) 3 = 2 ∧ newPosition (flags false) 3 = 1 := by decide
example : (compact (flags true) xs)[3]? ≠ some 44 ∧
    (compact (flags false) xs)[3]? ≠ some 44 := by decide
example : (compact (flags true) xs)[newPosition (flags false) 3]? = some 33 ∧
    (compact (flags false) xs)[newPosition (flags true) 3]? = none := by decide
example : (compact (flags true) xs)[newPosition (flags true) 3 - 1]? = some 33 ∧
    (compact (flags false) xs)[newPosition (flags false) 3 - 1]? = some 22 := by decide
example : compact (keep true [] (fun _ => false) (fun _ => false)) xs = [] ∧
    compact (keep false [] (fun _ => true) (fun _ => true)) ([] : List Nat) = [] := by decide
example : compact (keep false [] (· == 1) (fun _ => true)) xs = [22] := by decide
example : compact (keep true [0,1] (fun _ => false) (fun _ => false)) [11,22] = [11,22] := by decide

#print axioms exactReplay
EOF
cat > "$tmp/Wrong.lean" <<'EOF'
import PruneProof
open RevisedBenchmark.BarrierPrune
def wrongMask := keep true [3,3] (· == 1) (· == 2)
example : (compact wrongMask [11,22,33,44,55])[3]? = some 44 := by decide
EOF
cd "$tmp"
export LEAN_PATH="$tmp"
for unit in PruneSpec PruneProof Audit; do
  TIMEFORMAT="$unit %3R s wall"
  time "$lean" -o "$unit.olean" "$unit.lean"
done
TIMEFORMAT='Wrong %3R s wall'
if { time "$lean" Wrong.lean; } > Wrong.log 2>&1; then
  exit 1
else
  rc=$?
fi
cat Wrong.log
test "$rc" -eq 1
rg -F 'is false' Wrong.log
```

