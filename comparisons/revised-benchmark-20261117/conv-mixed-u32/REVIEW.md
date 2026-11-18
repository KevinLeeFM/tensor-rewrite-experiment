# Independent review: mixed U32 pointwise convolution

**Verdict: accepted for the two frozen exact evaluator-model outcomes.** With a U32 result and rank-three, one-spatial-axis pointwise geometry, U8/U8 operands always agree between the evaluator-shaped convolution and emitted U32 multiply. Either single-cast orientation (U8/U32 or U32/U8) is not universally equal; the packet supplies a valid grouped output where the original clamps to U32 maximum and the emitted multiply wraps to `U32_MAX - 1`. These are typed model results, not native execution or optimizer-reachability findings.

## Verifier admissibility and source paths

I inspected the frozen files and source hashes, including `hlo_verifier.cc`, `shape_inference.cc`, `algebraic_simplifier.cc`, `hlo_evaluator.cc`, and `hlo_evaluator_typed_visitor.h`. `ShapeVerifier::HandleConvolution` calls `InferConvolveShape` with the declared result element type as its preferred type (`hlo_verifier.cc:474–486`). The forward shape inference uses that preferred type for the result (`shape_inference.cc:2193–2201`, `:2282–2284`) and validates dimensions/grouping (`:2205–2216`, `:2443–2463`, `:2586–2617`). The mixed-precision operand check is specifically about differing floating-point precisions, and convolution is allow-listed (`hlo_verifier.cc:2668–2684`, `:2714–2733`). The inspected verifier path imposes no same-element-type constraint that rejects the packet's U8/U32 pairs. This is source inspection only; no verifier executable was run.

For these pointwise IDs, the simplifier checks kernel input-feature extent one and input/result feature extents equal to the feature-group count (`algebraic_simplifier.cc:11141–11147`). The frozen `PointSpec.Legal`/shape model retains positive and non-simultaneously-nonunit batch/feature groups plus the needed divisibility conditions. Each selected setup uses batch groups one and two feature groups, with batch one and one input feature per group; its one spatial kernel tap and channel make the convolution one product at each actual output. The independently reviewed `ConvPointAxes.verified` lemma supplies the physical address, in-bounds, and one-product reduction facts for arbitrary valid independent axis permutations. This packet adds the mixed-width conversion/observation reasoning; it does not claim a new proof of that geometry adapter.

The original evaluator first converts each differing operand to the U32 result type (`hlo_evaluator.cc:6558–6569`), then widens unsigned arithmetic to U64 (`:5767–5778`, `:6630–6641`). Its one-term accumulation is U64 (`:5986`, `:6040–6065`); since each converted operand is at most `2^32-1`, their product is below `2^64`, so this term is exact before clamp. The clamp uses the result type's limits (`:5926–5944`, `:6080–6085`) and final storage is U32 (`:6656–6670`). Thus the modeled original observation is `min(p, U32_MAX)`.

The simplifier converts each differing operand to the convolution result type and emits multiply in that type (`algebraic_simplifier.cc:11181–11217`). The U32 evaluator visitor uses U64 as its elementwise type and narrows its result to `ReturnT` (`hlo_evaluator_typed_visitor.h:484–489`, `:1194–1218`; unsigned type selection at `hlo_evaluator.cc:5767–5778`). This implements the low 32 bits, `p mod 2^32`, in the packet. For `p = product` the Lean criterion is exact: `min(p,U32_MAX) = p mod 2^32` iff `p < 2^32` or `p mod 2^32 = U32_MAX`. The proof also establishes `p < 2^64` from the two operand bounds, so the original U64 accumulator cannot wrap in the domain.

`SimplifyConvToDot` rejects `feature_group_count != 1` (`algebraic_simplifier.cc:11048–11050`), after which `HandleConvolution` proceeds to `SimplifyConvToMultiply` if no earlier rewrite returns (`:11264–11271`). The author correctly discloses that earlier dispatcher branches and actual rewrite reachability are not tested. This review therefore accepts the guarded source-shaped multiply case, not a claim that every compiled pipeline reaches it.

## Exact outcomes and controls

`ConvMixedU32.Goal` states the exact per-output equality criterion, the all-values U8/U8 universal theorem, and failure of both universal single-cast orientations. The pair of single-cast counterexamples uses shape `[1,2,1]`, two feature groups, and legal batch groups one. For U8 value 2 paired with U32 maximum (in either operand order), the converted product is `8589934590`; the original clamps to `4294967295`, while the emitted product has low word `4294967294`. The witnessed output coordinate is in bounds. For U8/U8, both operands are at most 255 and the product at most 65025, so it is below U32 maximum for every channel and every allowed geometry; `bytePair` correctly proves the universal case.

The controls exercise both cast orientations, a byte pair with product 65025, and an overflowing product that nevertheless agrees because its low word is all ones (`7 * 1227133513`). The last is a useful counterexample to the overly strong claim that every product above U32 maximum disagrees. The exact goal is stronger than those examples and is actually proved/refuted, rather than inferred from controls.

## Fresh replay and limitations

Fresh targeted replay command:

```sh
LEAN=/workspace/toolchains/lean-4.35.0-linux/bin/lean python3 replay.py
```

It passed on 2026-11-18 with Lean 4.35.0, commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. The replay verified packet, reused pointwise-model, toolchain, source, and census hashes, then compiled five modules in fresh temporary outputs: `PointSpec` 0.387 s, `PointProof` 0.359 s, `MixedSpec` 0.304 s, `MixedProof` 0.331 s, and `MixedControls` 0.371 s (1.752 s summed Lean command time; about 2 s total replay wall). The terminal theorem reports `[propext, Classical.choice, Quot.sound]`; these are standard Lean axioms, with no project axiom. Inspection found no `sorry`, `admit`, or `native_decide` in the packet's Lean files.

The admitted cases are narrowly U8/U8→U32 equality and U8/U32 or U32/U8→U32 counterexamples under this pointwise model. The work reuses the separately reviewed physical-index theorem and does not establish other widths, floating-point behavior, nonpointwise reductions, higher ranks, source correspondence, or actual backend execution. The census's three lexical IDs in this outcome are grouped into two mathematical outcome profiles, with both single-cast orientations separately controlled. Whole source-record closure remains open.

## Timing

This review began at 2026-11-18 03:01:23 UTC. The targeted replay began at 03:02:20 UTC and took about 2 s wall (1.752 s compiler time). Review inspection and this report were completed at 03:03:20 UTC, for 1 min 57 s total wall. No build, dependency setup, network operation, worker, or native execution was used. Active reasoning time and token cost were not measured.
