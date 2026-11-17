# Independent review of ordered Broadcast to Reshape

**Accepted for the full frozen strict, static logical model.** The proof at ec8a9c4cf72636e1f730cb2c408304da3c06c76c inhabits the exact `RevisedBenchmark.BroadcastOrdered.Target` at 05bb8d3a43fcdab25327b8d3327448eec0d9a2d4. All 17 frozen hashes matched. I reviewed the statement, proof, controls, and relevant source as a fresh reviewer and independently compiled them from Git blobs. No proof or semantic file changed in this review.

The vector contains one signed, in-range dimension per input axis. Each decoded axis must match the corresponding output extent. Strict increase ensures injectivity and preserves axis order. Input and output ranks and all natural extents are quantified, and the same element type and equal logical element counts are required. The conclusion compares the existing pullback on coordinates to the existing delinearization of the output row-major position, extensionally for every tensor. Neither operator definition assumes that equality.

The proof inducts on output rank while generalizing input rank. If no input axis hits the first output axis, the recursive comparison gives input count ≤ tail count. In the presence of an output index, the head extent and tail count are positive, so equality of the full counts forces the skipped head extent to be one and its only coordinate to be zero. Otherwise strictness makes the first matched axis the input head, and its positive extent cancels, yielding equal tail counts. In both branches the recursion preserves complete linear position. The checked delinearize/linearize inverse then gives equality of input indices. These positive-count deductions are local to an inhabited coordinate domain. The theorem permits a nonunit skipped axis when the index domain is empty.

At XLA e58e523b11f1fde802a493a776d158007486e1bf the simplifier tests nondecreasing order and equal stored element count at algebraic_simplifier.cc 5776–5785. ShapeVerifier::HandleBroadcast checks element type, axis array length/range and extent equality at hlo_verifier.cc 1741ff. InstructionVerifier optionally checks nondecreasing order at 4734ff. The distinct client InferBroadcastShape check rejects consecutive equal dimensions at shape_inference.cc 4024ff. Pipeline enforcement of that client restriction on every HLO reaching the simplifier is unestablished. The existing duplicate-square [0,0] diagnostic remains separate: sequential destination writes in literal.cc 1229–1255 differ structurally from a repeated-axis pullback. This positive proof covers strict embeddings of exact static extents. Runtime dynamic extents, descriptor changes, physical layout, arbitrary repeated dimensions, source execution and compiler correspondence remain outside its verdict.

**Independent replay.** The only custom module search path was a new empty temporary directory. I populated it by reading the ten dependencies and OrderedSpec from frozen Git blobs and OrderedProof/OrderedControls from the proof commit; each matched the working copy. I ran Lean 4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc serially with `lean -o MOD.olean MOD.lean`, reusing only shipped toolchain modules. Each invocation exited zero without warnings. The exact target audit returned propext, Classical.choice and Quot.sound. The proof combines its private structural induction with the established row-major inverse; there is no appeal to the target or project axiom.

| Modules in replay order | Wall seconds in matching order |
|---|---|
| Tensor, ConstantGuard, SliceShape, SliceIndexBounds, IndexMaps | 0.416, 0.457, 0.383, 0.378, 0.484 |
| FiniteProduct, LinearIndex, Reshape, FiniteProductLemmas, LinearIndexLemmas | 0.311, 0.297, 0.250, 0.257, 0.289 |
| OrderedSpec, OrderedProof, OrderedControls, independent control | 0.256, 0.478, 0.450, 0.329 |

The committed controls exercise inserted head and interior axes on [2,3] → [1,2,1,3], producing 12 on a nonconstant tensor, and check [0] → [5,0] and rank-zero scalar shapes. The extra control below checks identity axes at positive equal rank. Swapping two equal-sized axes leaves all extents and counts matched but violates strict ordering; on the same tensor and output index the two reads give 2 and 1. This is a mathematical strength test outside the ordered guard.

```lean
module
public import OrderedProof
public section
set_option autoImplicit false
open TensorRewrite.Pilot RevisedBenchmark.BroadcastOrdered
private def s : Shape 2 := fun _ => 2
private def idAxes : IndexMaps.BroadcastAxes 2 2 := ⟨#[0,1].toVector, by decide⟩
private def swapped : IndexMaps.BroadcastAxes 2 2 := ⟨#[1,0].toVector, by decide⟩
private def j : Index s := fun a => ⟨a.val, a.isLt⟩
private def x : Tensor s Nat := fun i => 2*(i 0).val + (i 1).val
example : (fun k => x (IndexMaps.broadcastIndex idAxes (fun _ => rfl) k)) =
    Reshape.reshapeTensor x s rfl := orderedReshape s s idAxes (by decide) (fun _ => rfl) rfl Nat x
example : ¬ (∀ a b, a < b → swapped.decode a < swapped.decode b) := by decide
example : x (IndexMaps.broadcastIndex swapped (fun _ => rfl) j) = 2 := rfl
example : Reshape.reshapeTensor x s rfl j = 1 := rfl
example : x (IndexMaps.broadcastIndex swapped (fun _ => rfl) j) ≠ Reshape.reshapeTensor x s rfl j := by decide
```

Observed review window began at 23:21:10 UTC and ended 23:22:38 UTC on 2026-11-17 (89 s, including replay and report preparation). The 13-module replay used approximately 4.706 s and the extra control 0.329 s. Exclusive reasoning time, tokens and cost are unknown.
