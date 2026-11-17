# Independent review of the signed Gather literal boundary

**Verdict:** Accepted for the frozen signed coordinate-selection model.
At every positive signed width `w = k + 1`, the clamp and sequential
Select chain agree at every index exactly when the extent is at most
`2^k`. Every larger modeled extent admits an in-bounds signed-zero
input with a different selected coordinate. This strengthens the
previous S8 extent-129 counterexample for the same retained record
`HandleGather/small-select-chain`. It adds no source-record count
and makes no new native claim.

## Frozen goal and proof

Spec freeze `4ae6622fb85ca3706a5dd6f5ffda22efe207f3db`, reviewed proof
`b5a3d0a77870fc832f1c66b0a50362c488313d12`. All seven frozen input
hashes passed. The Git diff from the freeze adds only the proof and
controls. I checked the named theorem against the expanded exact type:

```lean
∀ (k extent : Nat),
  (∀ i : BitVec (k+1), selectedIndex extent i = originalIndex extent i) ↔ extent ≤ 2^k
```

In the positive direction each generated position is strictly below
`extent`, hence strictly below `2^k`. The underlying word has
`2^(k+1)` distinct encodings and signed maximum `2^k - 1`. Thus the
narrowing and signed interpretation preserve every literal.
`selectedIndex_eq_original` then proves equality by induction on
the left-to-right Select chain, including the initial coordinate 0.
The model at extent 0 returns numerical index 0 on both sides. This is
a total convention for the coordinate functions, with no admitted
element access at extent 0.

In the negative direction set `t = 2^k`. At `extent = t + 1`,
the loop includes position `t` with signed literal `-t`. The signed-zero
predicate accepts it and chooses position `t`, whereas clamping signed
zero chooses 0. By `step`, every further iteration either retains
the chosen position or selects the larger current position. Thus the
chosen coordinate stays at least `t > 0`, even through repeated
literal wraparounds. There is no assumption on how far above `t` the
extent lies. Both coordinates remain below the positive extent:
`originalIndex` clamps and `selectedIndex` can only retain 0 or take a
position in its loop range. For example, labeling 0 distinctly from
all other positions witnesses value inequality without requiring a
data type large enough to label each position distinctly.
[Specification](GatherSpec.lean) · [Proof](GatherProof.lean)
· [Frozen coordinate functions](../../../TensorRewrite/Pilot/ReducerIndex.lean)
· [Reused exact-literal theorem](../../../TensorRewrite/Pilot/ReducerIndexLemmas.lean#L50)

## Source guard and interpretation

At pinned XLA revision `e58e523b11f1fde802a493a776d158007486e1bf`,
`HandleGather` returns earlier for empty or effective-scalar operands.
The Select branch requires rank-one operand, extent at most
`very_small_gather_size`, the implicit scalar index-vector condition
`index_vector_dim == index rank` and one collapsed slice dimension.
For the legal rank-one scalar Gather specialization, the evaluator
clamps to `[0, extent-1]`. The branch initializes with element 0,
then builds a Select for every increasing `int64_t` position. A
signed comparison against `MakeScalarLike(index, position)` gives
the modeled narrowing when host representation and conversion agree
with signed word semantics. The helper converts the position literal
to the index element type, whose integral host conversion follows
the native cast path. The historical S8 archive directly records
`128 → -128` and the in-bounds input zero changing from label 0
to 128 under threshold 129. At threshold 128 or 4 for extent 129,
the same small-select branch did not fire. At extent 128 with
threshold 128, the exercised S8 input preserved its label.
[Dispatch](../../../sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc#L4634)
· [Option](../../../sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier_options.proto#L72)
· [Literal helper](../../../sources/xla/xla/service/hlo_creation_utils.h#L334)
· [Native conversion](../../../sources/xla/xla/literal.cc#L1881)
· [Evaluator](../../../sources/xla/xla/hlo/evaluator/hlo_evaluator.cc#L2763)
· [Historical archive](../../../reports/reducer-index-replay-v1/result.json)

The option's default is 4. The mathematical threshold is independent
of that policy. Source use requires legal HLO, an actual supported signed
index type, host conversion matching the model, representable extents
and loop positions, and sufficient resources to construct the per-element
chain and evaluate the graph. Arbitrary Lean widths are not an inventory
of XLA data types. For example, the idealized S64 threshold `2^63` is
already above the positive `int64_t` range used for the source extent and
option. An arbitrarily large mathematical extent is therefore not a
claim of reachable or feasible native execution. Unsigned, mixed index
representations, shape admission, non-scalar Gather variants, layout,
metadata, control, status and backend behavior are outside this
coordinate theorem. The already archived runtime result remains
historical. No fresh native work or C++–Lean correspondence proof
was performed.

## Fresh replay and controls

Lean 4.35.0, commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.
A clean temporary Std-only path compiled all six relevant local
modules and the existing controls (S3 extents 4, 5 and 12 and S8 extents
128 and 129). It also checked the expanded exact theorem, extent zero,
the smallest signed width, and S3 extents 21 and 22, beyond two full
word moduli. Signed-zero Select chooses 20 and 21 respectively
while clamp returns zero. A false two-wrap equality was rejected
specifically because kernel `decide` found it false. The exact theorem
reported only `propext`, `Classical.choice` and `Quot.sound`, all
permitted. No source/specification edit was needed.
[Existing controls](GatherControls.lean)

Reproduce from the repository root:

```bash
set -eu
packet=comparisons/revised-benchmark-20261117/gather-exact
sha256sum -c "$packet/SHA256SUMS"
lean=/workspace/toolchains/lean-4.35.0-linux/bin/lean
"$lean" --version
export LEAN_PATH="$(mktemp -d)"
export LEAN_SRC_PATH="$PWD"
trap 'rm -rf "$LEAN_PATH"' EXIT
mkdir -p "$LEAN_PATH/TensorRewrite/Pilot"
for mod in Tensor ReducerIndex ReducerIndexLemmas; do
  path=TensorRewrite/Pilot/$mod
  "$lean" -o "$LEAN_PATH/$path.olean" "$path.lean"
done
for mod in GatherSpec GatherProof GatherControls; do
  "$lean" -o "$LEAN_PATH/$mod.olean" "$packet/$mod.lean"
done
cat > "$LEAN_PATH/Audit.lean" <<'LEAN'
import GatherProof
open TensorRewrite.Pilot.ReducerIndex.GatherLiterals
example : ∀ (k extent : Nat),
    (∀ i : BitVec (k+1), selectedIndex extent i = originalIndex extent i) ↔ extent ≤ 2^k :=
  RevisedBenchmark.GatherExact.correct
example : selectedIndex 0 (-1 : BitVec 1) = originalIndex 0 (-1 : BitVec 1) := by decide
example : selectedIndex 1 (0 : BitVec 1) = originalIndex 1 (0 : BitVec 1) := by decide
example : selectedIndex 2 (0 : BitVec 1) = 1 ∧ originalIndex 2 (0 : BitVec 1) = 0 := by decide
example : selectedIndex 21 (0 : BitVec 3) = 20 ∧ originalIndex 21 (0 : BitVec 3) = 0 := by decide
example : selectedIndex 22 (0 : BitVec 3) = 21 ∧ originalIndex 22 (0 : BitVec 3) = 0 := by decide
#print axioms RevisedBenchmark.GatherExact.correct
LEAN
"$lean" "$LEAN_PATH/Audit.lean"
cat > "$LEAN_PATH/Negative.lean" <<'LEAN'
import GatherProof
open TensorRewrite.Pilot.ReducerIndex.GatherLiterals
example : selectedIndex 21 (0 : BitVec 3) = originalIndex 21 (0 : BitVec 3) := by decide
LEAN
rc=0
"$lean" "$LEAN_PATH/Negative.lean" > "$LEAN_PATH/negative.log" 2>&1 || rc=$?
test "$rc" = 1
rg -F 'is false' "$LEAN_PATH/negative.log"
```

The observed independent-review window was 22:32:49–22:34:59 UTC on
2026-11-17 (130 seconds through the written checkpoint).
The first replay (22:33:25–22:33:26) compiled through the proof, with
1.586 seconds in Lean. My harness had assumed an unnecessarily narrow
axiom list and halted on the permitted `Classical.choice`. The corrected
replay (22:33:55–22:33:58) took 2.644 seconds in Lean, including 1.960
seconds for six modules, 0.314 seconds for the exact-goal/control audit
and 0.370 seconds for the expected negative rejection. Summed observed
Lean command time was 4.230 seconds. The harness correction belongs to
review overhead. There was no fresh proof-search time in this review.
Active reasoning time and token usage were not separately measured.
