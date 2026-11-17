# Independent review of the scaled nested DynamicSlice witness

**Verdict:** Recovered model counterexample for the retained candidate
`HandleDynamicSlice/nested-after-scaled-probe`. The frozen rank-one S32
specialization disproves universal value preservation. The pinned archive
separately records the same observed change in the HLO handler and pass.
This review freshly replays the Lean certificate and checks the archive offline.
It records no fresh native execution or discovery.

## Exact claim and admitted witness

Repository freeze `d1b6ab01f65010c5180146ddd3a30434ddeccba1`. The 21 packet
checksums passed, and the pilot sources, control fixtures and archive matched
the frozen Git revision. The operative declaration is
`TensorRewrite.Pilot.ScaledNestedSlice.not_universally_preserving`:

```lean
¬ (∀ multiplier : BitVec 32,
  original 1 (by decide) multiplier 1 2 = rewritten 1 (by decide) 1 2)
```

`original` slices six from the rank-one input `[1,2,3,4,5,6,7,8,9,10]`
at decoded start 1, multiplies the slice pointwise by the runtime word,
and slices one at decoded start 2. `rewritten` slices one from the original
unscaled input at the sum of the separately clamped starts. The shape
constraints are inhabited (`1 ≤ 6 ≤ 10`), and `witnessIndex` is the
unique rank-one coordinate at offset 0 in the result. The inner, outer
and final start bounds are 4, 5 and 9. The starts 1 and 2 are in bounds,
and their sum 3 is in bounds for the combined slice. Both sides select
input label 4 before the multiplication effect. Multiplier 7 gives
`28#32 ≠ 4#32`, with neither arithmetic overflow nor high-bit index
decoding involved. The refutation uses the pointwise witness to reject
tensor function equality. At multiplier 1 the observed coordinate agrees.
[Model](../../../TensorRewrite/Pilot/ScaledNestedSlice.lean)
· [Certificates](../../../TensorRewrite/Pilot/ScaledNestedSliceCertificates.lean)

## Source dispatch and historical archive

I read the pinned XLA `HandleDynamicSlice` body (lines 8142–8433, body
SHA256 `a8512ebdce236bb372b68d161a5854f3677e31de8ccad88a63003f3cf2a2ffa4`).
XLA revision `e58e523b11f1fde802a493a776d158007486e1bf` and pass-file
SHA256 `1ecfd7d4ba958ac0e795d8663c14f7f6b1ebd147a8a83ed0e99661740105628f`
agree with the frozen source and receipt. The three dispatch span hashes
agree with the linked census and pilot profile.

For the verified entry fixture, the op is outside an async computation,
its rank-one output extent 1 differs from the rank-one operand extent 6,
and its data operand is Multiply. The earlier scalar, same-shape,
same-extent, Broadcast, Reshape and Transpose paths therefore fall through.
Runtime starts skip static conversion (8263–8301). The rank-one, width-one
S32 gate admits the Iota probe (8307–8311). The right operand is a Broadcast
of a runtime scalar with empty dimensions, so the matcher succeeds
without any Constant requirement. Line 8330 rebinds the **local** operand
to the left DynamicSlice. This fails the Iota test at 8333, leaving the
rebound local live at the nested continuation (8385). The fits checks test
4 against the inner S32 range and 9 against the outer S32 range. Lines
8401–8402 replace the outer data operand with the inner slice's base and
8403–8428 install the summed clamps. Both starts have S32 type so this
fixture skips the conversion at 8419–8423. The new root reads the base
directly, bypassing the original multiplication.
[Source](../../../sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc#L8142)
· [Pinned dispatch spans](../../../census/scaled-nested-slice-contract.json)
· [Pilot receipt](../../../reports/pilot-values.json)

The archived fixture parses and verifies the input, evaluates it with
HloEvaluator fast paths off, verifies the output, and reevaluates the
same arguments. The handler isolation checks an unchanged initialization
with DynamicSlice handling suppressed before dispatching the original root.
The full pass uses one pass with fast math disabled and layout sensitivity
enabled. Captured original HLO reads `%product` and the captured replacement
uses `dynamic-slice(%data, %add)`, with the two S32 clamps visible. The
`scaled` results were `28 → 28` in the no-pass control and `28 → 4`
in both handler and pass modes. Negative and zero scalars gave
`-12 → 4` and `0 → 4`; scalar one gave `4 → 4` despite a graph change.
Reversed multiply, width two and an S64 **result** stayed unchanged in this
fixture. Constant starts preserved 28 with static conversion enabled and
changed `28 → 4` with it disabled. Intended Iota retained the scale
(`14 → 14`). In total, the archive has 33 case/mode rows and eight
value differences, including both modes for each of four input/options
variants. The offline archive checker verified the source and artifact
hashes, logged rows, XML success, and Bazel event status. The archive records
15.149 seconds for its historical command. Its binary SHA256
`84ff25c759549ee15c005cfb298b168853a1af4ec811a3af0c89fab3bd994b26`
identifies the binary in the receipt.
[Fixture](../../../reports/scaled-nested-slice-replay-v1/fixture.cc#L53)
· [Before/after HLO](../../../reports/scaled-nested-slice-replay-v1/test.log#L41)
· [Archive receipt](../../../reports/scaled-nested-slice-replay-v1/result.json)

The direct `HandleDynamicSlice/nested` positive partition shares the
mutation sites but has no Multiply in its original graph. Its
`DynamicIndex.sliceTensor_compose` proof describes ordinary logical
composition of two slices, and the archive's direct control rewrites
with `4 → 4`. Neither is evidence for dropping the scale. This
counterexample suffices to reject a universal value-preservation claim
that includes the exhibited input. Complete source correspondence,
other operand orientations and data/index types, successful Iota,
backend execution, metadata/control effects and general API/status
outcomes lie outside the checked Lean statement.
[Direct composition theorem](../../../TensorRewrite/Pilot/DynamicSliceComposition.lean#L12)
· [Retained cases](../../../census/tensor-index-cases.json)

## Fresh Lean replay

Lean 4.35.0, commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.
Twelve project modules were freshly compiled in dependency order with only
the installed Lean/Std libraries and a temporary `LEAN_PATH`. The exact
proposition below elaborated against the frozen certificate, together with
kernel-checked multiplier-one equality and multiplier-seven disequality.
All seven certificates reported exactly the permitted axioms `propext`,
`Classical.choice` and `Quot.sound`. The existing positive evaluation
fixture gave 28, −12, 4 and 0 before and 4 after in all four cases. The
existing false-equality fixture failed on its expected `rfl` mismatch;
the kernel-checked disequality establishes the stronger negative result.

From the repository root, with the installed Lean binary at the recorded path:

```bash
set -eu
sha256sum -c comparisons/revised-benchmark-20261117/recovered-witnesses/SHA256SUMS
PYTHONDONTWRITEBYTECODE=1 python3 tools/check_scaled_nested_slice_evidence.py
lean=/workspace/toolchains/lean-4.35.0-linux/bin/lean
"$lean" --version
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/TensorRewrite/Pilot"
export LEAN_PATH="$tmp"
export LEAN_SRC_PATH="$PWD"
for mod in Tensor ConstantGuard ConstantGuardLemmas DynamicIndexValue DynamicIndexBounds \
  DynamicIndex DynamicIndexLemmas DynamicSliceTensor DynamicSliceCompositionLemmas \
  DynamicSliceComposition ScaledNestedSlice ScaledNestedSliceCertificates
do
  p=TensorRewrite/Pilot/$mod
  "$lean" -o "$tmp/$p.olean" "$p.lean"
done
cat > "$tmp/Audit.lean" <<'LEAN'
import TensorRewrite.Pilot.ScaledNestedSliceCertificates
open TensorRewrite.Pilot.ScaledNestedSlice
example : ¬ (∀ multiplier : BitVec 32,
    original 1 (by decide) multiplier 1 2 = rewritten 1 (by decide) 1 2) :=
  not_universally_preserving
example : original 1 (by decide) 1 1 2 witnessIndex =
    rewritten 1 (by decide) 1 2 witnessIndex := by decide
example : original 1 (by decide) 7 1 2 ≠ rewritten 1 (by decide) 1 2 :=
  changes_of_not_fixed 7 (by decide)
LEAN
for decl in original_witness rewritten_witness changes_of_not_fixed \
  multiplier_seven_changes negative_multiplier_changes zero_multiplier_changes \
  not_universally_preserving
do
  printf '#print axioms TensorRewrite.Pilot.ScaledNestedSlice.%s\n' "$decl" >> "$tmp/Audit.lean"
done
"$lean" "$tmp/Audit.lean"
for name in ScaledNestedSliceControls InvalidScaledNestedSlice; do
  sed '1c\import TensorRewrite.Pilot.ScaledNestedSliceCertificates' \
    "tests/fixtures/$name.lean" > "$tmp/$name.lean"
done
"$lean" "$tmp/ScaledNestedSliceControls.lean"
rc=0
"$lean" "$tmp/InvalidScaledNestedSlice.lean" > "$tmp/invalid.log" 2>&1 || rc=$?
test "$rc" = 1
rg -F 'Tactic `rfl` failed' "$tmp/invalid.log"
```

Fresh replay ran 22:30:53–22:30:58 UTC, 2026-11-17. Summed compiler
commands were 4.597 seconds (12 modules 3.675 s, exact/audit 0.295 s,
positive fixture 0.326 s, expected rejection 0.301 s). Offline archive
checking took 0.053 s. The observed setup/source review started by the
22:29:35 clock sample and continued through report writing. Precise active
reasoning and token usage are unmeasured. There was no new proof-search or
native-execution time in this allocation.
