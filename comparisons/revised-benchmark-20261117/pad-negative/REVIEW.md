# Independent review of HandlePad/negative-edges

**Accepted for the static homogeneous tensor model of the negative-edge branch.** Reviewed candidate `da2162d4d7d5a8d35c934b7de49c788cc7d2b1af` and statement freeze `9e97f4ab95d7a99e2ff711e2df035e3d9d1222da`. I did not author the candidate. This resolves the declared mathematical model partition of retained record `HandlePad/negative-edges` (site `site-L06399-C012`). Dynamic dimensions, layout/tiling and metadata, nonhomogeneous type restoration, overflow/status behavior, and actual C++ execution and correspondence remain outside the verdict. This is an adapter plus checked reuse of historical paper `pad/rule04`, with no new discovery credit for that theorem.

## Source and statement

At pinned XLA `e58e523b11f1fde802a493a776d158007486e1bf`, [HandlePad 6198–6329](../../../sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc#L6198) returns earlier on empty input, cleared singleton interiors, successful compatible no-op replacement, or the specialized broadcast path. It detects strictly negative low/high edges at 6233–6235, and the option must be enabled at 6329. Those conditions select a source path. The stronger mathematical statement works for all legal original model parameters, including configurations excluded by those earlier returns. The [chosen branch 6329–6399](../../../sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc#L6329) clamps each low/high independently and preserves every interior. It uses the same input and fill, sets start to minus the negative low or zero, subtracts the magnitude of the negative high from the new pad extent, and uses unit stride. The shape check at 6392–6397 includes shape equality with a conditional layout-tile exclusion. The model proves logical dimension equality; layout checking is external. The vendored [helper header](../../../sources/xla/xla/service/hlo_creation_utils.h#L63) supplies signatures, and the shape interpretation comes from [InferPadShape](../../../sources/xla/xla/service/shape_inference.cc#L742) and [InferSliceShape](../../../sources/xla/xla/service/shape_inference.cc#L3424). The helper implementation is absent from this excerpt.

Independently, let `B = n + max(0,n-1)*interior`, `M = B + max(0,low) + max(0,high)`, and `O = B + low + high`. A legal original `Params` has `O ≥ 0` because its checked extent is a natural. For start `S = max(0,-low)` and exclusive limit `E = M + min(0,high)`, the equality `E-S = O` proves `0 ≤ S ≤ E ≤ M`. This covers the original Pad's zero input extent formula and a zero output extent with `E=S`. For nonnegative edges the crop is full width. For a negative low only it removes the prefix, for a negative high only it removes the suffix, and for two negative edges it removes both. Zero edges agree with the nonnegative side. Any combination across axes is permitted by the independent pointwise formula. A rank-zero configuration has no negative edge but also satisfies the broader mathematical identity. The model does not exclude the empty domain to obtain validity.

The exact [goal](NegativeSpec.lean#L19) constructs metadata equalities and a dependent witness for every slice axis. It quantifies arbitrary rank, input/output shapes with original `Params.shape`, arbitrary homogeneous element type, fill, and tensor. There is no validity premise for the replacement. [NegativeProof](NegativeProof.lean#L7) discharges the conversion back from `M.toNat` using nonnegativity, constructs intermediate `Params` directly at `middle p`, and obtains the six slice well-formedness facts by integer arithmetic from the two Pad shape equations. At unit stride the count equals `E-S`. This dependency makes the output index retain the exact original shape, so there is no unchecked frame cast. `IndexMaps.sliceIndex` converts the signed affine coordinate to `Fin (middle p axis)` using the validity-derived nonnegative and strict bounds, and `sliceIndex_val` establishes the corresponding integer equality. The shift relation is `S = clampLow-low`, so the original and replacement occupied-position tests subtract the same effective low and use identical lattice spacing. Equality of all option samples propagates through the same assembly and data/fill selector.

## Dependency and replay evidence

All 14 manifest entries passed `sha256sum -c`. Compared the historical Pad, lattice, and tensor Git blobs at extractor pin `672928dbb90a7607c24a7d0281a7db117036608c` with their manifest hashes. Read the full generated slices in [extract.py](../signed-pad/extract.py) against their source: `LatticeIndex.lean` lines 4–50 and 58–91, `SignedPad.lean` lines 6–97. The generated modules replace historical imports with explicit local dependencies, exclude the convolution-dependent lattice theorem and later Pad theorems, and make proof-only `Int` simp-name qualifications. Decoder, assembly, Pad extent/parameters, sample, and tensor definitions are unchanged. The entire `pad_shift` declaration including proof in `HistoricalShift.lean` matched [the historical declaration](../../tensorright-v1/SignedPad.lean#L222) exactly before the fresh runner's single proof-only `one_mul` to `Int.one_mul` qualification. There was no change to its statement or definitions.

- Extractor SHA-256 `d984c56b5b88d134dbd365465302c124e830ae6c2bf5281a61e0522f511fc49d`. Generated `SignedPadLattice.lean` SHA-256 `b55486e4e7c94564b5f318cfd7ae6eebc07ba5b9d08e9b66f8597433ee374d81`, generated `SignedPadHistorical.lean` SHA-256 `ba083aaa92efa84eb3eedf5394bde3ee42b824ed705c3f71cd06c7a8811cc03e`, and compiled-copy `HistoricalShift.lean` SHA-256 `3c12fa9c21960d32a9c0377380c83f693c5d9ff01bdb40d8e7cfa2407c2b1c56`.
- Candidate/replay source SHA-256 values `30982dc381f0a38a9af450593e75cc63d12fb541414f11453a843c7e20641690` (proof), `75186411dbd7774326391e0e9e1ccb27feb02c363df6b825dfd18756b5150bf0` (controls), and `beae9f7d11569f4fc8e2591db9fc4e2831c439e82f052060a9a239ad09c7a44a` (runner).
- From repo root, `python3 comparisons/revised-benchmark-20261117/pad-negative/replay.py` built 13 fresh modules in 4.703 seconds with no warnings. Independently rebuilt the same ordered closure using `lean -o MODULE.olean MODULE.lean`, only a fresh local directory on `LEAN_PATH`, then added an independent exact-signature and negative-value module. Lean reported version 4.35.0, x86_64-unknown-linux-gnu, commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. Both runs reported only `[propext, Classical.choice, Quot.sound]` for `RevisedBenchmark.NegativePad.correct`. The independent exact check reproduced every quantifier and conclusion from the frozen specification rather than merely naming `Goal`.
- Fresh independent compile durations in seconds in dependency order: Tensor .317, SignedPadLattice .334, SignedPadHistorical .310, ConstantGuard .402, SliceShape .324, SliceIndexBounds .399, IndexMaps .388, ConstantGuardLemmas .297, IndexMapLemmas .297, NegativeSpec .302, HistoricalShift .314, NegativeProof .450, NegativeControls .312, Check .302. Individual values rounded. Total 4.752 seconds.
- Packet controls checked mixed signs, opposite mixed signs, and a both-negative empty crop; their invalid-start control changed slice length. The independent check held shape and stride fixed with the valid wrong crop `[0,6)` in place of `[1,7)`, using input `[11,12,13]`, signed edges `(-1,2)`, interior 1 and fill -7. At output coordinate zero the original and correct crop both return -7; the valid shifted crop returns 11. Checked whole-tensor inequality by evaluation at zero. Its axioms were `[propext, Quot.sound]`. No executable evaluation shortcuts or unapproved axioms were used.
- The first timing wrapper failed before replay because `/usr/bin/time` is absent; Bash `time` replaced it. Two temporary independent-harness compilations failed at the harness module (0.310 and 0.344 seconds, about 4.8 seconds per command, including rebuilt prerequisites). The first used a bare `0` of dependent type `Fin (one 6 axis)` and exposed private constants in public goals. The second used an open goal with `decide`; Lean reported error-recovery `sorryAx` in that failed scratch check. Replaced the numeral with an explicit `Fin` constructor and a closed bound `0 < 6`, kept case-specific declarations private, and replayed from an empty directory. The failed temporary checks provide no theorem evidence. The accepted source and its proofs were unchanged.

Review work window 22:19:35–22:22:31 UTC on 2026-11-17 (176 seconds observed wall time). This includes setup and file inspection, writing, two failed harness runs, and the two passing replay commands. Active reasoning and token use were not measured.

## Independent check source

Compile after the packet targets in the fresh local directory.

```lean
module
public import NegativeProof
public import NegativeControls
public section
set_option autoImplicit false
namespace IndependentCropReview
open TensorRewrite.Pilot TensorRewrite.PaperComparison.SignedPad RevisedBenchmark.NegativePad
private def one (n : Nat) : Shape 1 := fun _ => n
private def original : Params (one 3) (one 6) :=
  ⟨fun _ => -1, fun _ => 2, fun _ => 1, fun _ => by rfl⟩
private def intermediate : Params (one 3) (middle original) :=
  ⟨fun _ => 0, fun _ => 2, fun _ => 1, fun _ => by rfl⟩
private def shifted : Fin 1 → SliceShape.Axis := fun _ => ⟨0, 6, 1⟩
private theorem cropValid (axis : Fin 1) :
    SliceShape.IsWellFormed (middle original axis) (one 6 axis) (crop original axis) := by
  exact (by decide : SliceShape.IsWellFormed 7 6 ⟨1,7,1⟩)
private theorem shiftedValid (axis : Fin 1) :
    SliceShape.IsWellFormed (middle original axis) (one 6 axis) (shifted axis) := by
  exact (by decide : SliceShape.IsWellFormed 7 6 ⟨0,6,1⟩)
private def data : Tensor (one 3) Int := fun index => (index 0).val + (11 : Int)
private def zero : Index (one 6) := fun _ => ⟨0, (by decide : 0 < 6)⟩
private theorem valueProbe :
    tensor original (-7) data zero = -7 ∧
      tensor intermediate (-7) data (IndexMaps.sliceIndex (crop original) cropValid zero) = -7 ∧
      tensor intermediate (-7) data (IndexMaps.sliceIndex shifted shiftedValid zero) = 11 := by decide
private theorem rejectsValidShift :
    tensor original (-7) data ≠ fun output =>
      tensor intermediate (-7) data (IndexMaps.sliceIndex shifted shiftedValid output) := by
  intro same
  have atZero := congrFun same zero
  rw [valueProbe.1, valueProbe.2.2] at atZero
  omega
example : ∀ {r : Nat} {s o : Shape r} (p : Params s o),
    ∃ mid : Params s (middle p),
      mid.low = (fun d => max 0 (p.low d)) ∧
      mid.high = (fun d => max 0 (p.high d)) ∧ mid.interior = p.interior ∧
      ∃ valid : ∀ d, SliceShape.IsWellFormed (middle p d) (o d) (crop p d),
        ∀ {α : Type} (fill : α) (xs : Tensor s α),
          tensor p fill xs = fun j => tensor mid fill xs (IndexMaps.sliceIndex (crop p) valid j) :=
  correct
#print axioms RevisedBenchmark.NegativePad.correct
#print axioms valueProbe
#print axioms rejectsValidShift
end IndependentCropReview
```
