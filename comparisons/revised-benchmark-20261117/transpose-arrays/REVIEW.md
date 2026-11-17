# Independent final review of three transpose value obligations

**Accept all three frozen mathematical statements.** I reviewed freeze `522483b8da7d0927ec359fe62550b4a94c31fe08` and proof `5ee479681a5aef9d5ec83c1df7ae5ae08d82281c` independently of their author. All 13 frozen source hashes matched, the direct/transitive custom import graph matched that list, and the proof SHA-256 was `d14d354ebd597164ce635d837584913d5fd54a453fd52b55adcac8f261a2d012`. The proof commit added only TransProof.lean. I found no admitted proof, new axiom or unsafe/native shortcut in the custom closure.

| Retained ID | Checked reason and boundary |
| --- | --- |
| HandleTranspose/identity | The premise is numeric nondecreasing order. The inverse laws imply injectivity and thus strict increase. Induction gives a lower bound on every image; applying it to the reversed order gives the upper bound. Forward and inverse maps are identity, so the matched input/output extents give equality of shapes and transport preserves every value. The proof derives shape equality; it is not an input. |
| HandleTranspose/compose | Inner array p and outer q compose as p[q[i]]. The source-style append loop, tabulation of the composite and whole-tensor equality are all connected. Established loop correctness and transpose composition are explicitly reused. The proof's nonsymmetric pair distinguishes composition orders at axis zero. |
| HandleBroadcast/transpose | The dimensions map sends input axis k to an output axis. Its inverse is the output-to-input map of the replacement transpose. The frozen map-to-permutation witness is essential; equal rank, count and corresponding extents alone do not establish it. An independently compiled unsorted [1,0,1] example on equal 3×3×3 shapes satisfies those extent conditions and has no such permutation. The positive result covers all witnessed legal permutations over the declared static logical values. |

I checked the pinned simplifier at algebraic_simplifier.cc 5769–5796 and 10407–10430, both implementation loops in permutation_util.h, shape_inference.cc 4226ff, shape_util.cc 1561ff, and hlo_verifier.cc 1741ff and 4736ff. All five local source files matched the recorded SHA-256 in the main, indexing, and dependency-supplement manifests for XLA e58e523b. Transpose inference checks length and permutation. Broadcast checks the mapped extent and range; its optional order check requires sorted dimensions. Sorted equal-count Broadcast is handled by the earlier reshape branch. Transpose first tries Scatter folding; sorted transpose also precedes nested composition. The mathematical laws can hold outside the dynamic execution of those branches. Physical layout, dynamic descriptors, recovery metadata, machine counts, pipeline admission, execution and C++–Lean correspondence are outside these verdicts.

**Fresh replay.** Copied only the twelve frozen custom library files, frozen spec and submitted proof into an empty temporary directory. Used Lean 4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc and its shipped standard library, without Lake or prior custom object files. From that directory compiled each file sequentially with `LEAN_PATH="$PWD" lean -o <module>.olean <module>.lean`, preserving the TensorRewrite/Pilot paths. All returned zero with no warnings. Order and wall seconds were Tensor .323, Indexing .318, Permutation .317, PermutationArrays .496, PermutationArrayLemmas .433, PermutationLoop .397, PermutationLoopLemmas .441, Transpose .309, ConstantGuard .462, SliceShape .333, SliceIndexBounds .346, IndexMaps .387, TransSpec .317 and TransProof .392. Total 5.271 s. Axioms for sortedForward and broadcastTranspose were propext and Quot.sound. Nested additionally used Classical.choice. The independent harness assigned each theorem to its exact frozen type.

**Independent controls.** The three-cycle [1,2,0] is unsorted. With output coordinate (0,1,2) and a nonconstant input tensor returning its first coordinate, Broadcast and the inverse transpose both return 1; the forward transpose returns 2. The harness also distinguishes a rank-zero scalar's inhabited coordinate domain from the empty coordinate domain of shape [0]. Below is the complete replayable supplemental harness (sha256 dfcbec1ce854b57a38ab089fdc6fb0c4fbd0ce8f7aa7b7e77a1ca2bf9cb9f9b9).

```lean
import TransProof
set_option autoImplicit false
open TensorRewrite.Pilot Tensor RevisedBenchmark.TransArrays
example : SortedForward := sortedForward
example : Nested := nested
example : BroadcastTranspose := broadcastTranspose
private def f : AxisArray 3 := #[1,2,0].toVector
private def b : AxisArray 3 := #[2,0,1].toVector
private def perm := AxisArray.toPermutation f b (by decide) (by decide)
private def axes : IndexMaps.BroadcastAxes 3 3 := ⟨#[1,2,0].toVector, by decide⟩
private def shape : Shape 3 := fun _ => 3
private def val : Tensor shape Nat := fun j => (j 0).val
private def pos : Index shape := fun k => k
private theorem legal : ∀ i, axes.decode i = perm.outputToInput i := by decide
private theorem hs : ∀ i, shape i = shape (axes.decode i) := fun _ => rfl
example : reindex (IndexMaps.broadcastIndex axes hs) val =
    transpose (inverse perm) (fun _ => rfl) val := broadcastTranspose shape shape axes perm legal hs Nat val
example : reindex (IndexMaps.broadcastIndex axes hs) val pos = 1 := rfl
example : transpose (inverse perm) (fun _ => rfl) val pos = 1 := rfl
example : transpose perm (fun _ => rfl) val pos = 2 := rfl
example : reindex (IndexMaps.broadcastIndex axes hs) val pos ≠ transpose perm (fun _ => rfl) val pos := by decide
example : val pos ≠ val (fun _ => (2 : Fin 3)) := by decide
example : ¬ (∀ i j : Fin 3, i < j → perm.outputToInput i ≤ perm.outputToInput j) := by decide
example (x : Tensor (fun _ : Fin 0 => 0) Nat) :
    transpose (AxisPermutation.identity 0) (fun _ => rfl) x = x := rfl
example (x : Tensor (fun _ : Fin 1 => 0) Nat) :
    transpose (AxisPermutation.identity 1) (fun _ => rfl) x = x := rfl
example : ¬ Nonempty (Index (fun _ : Fin 1 => 0)) := by
  rintro ⟨i⟩
  exact Fin.elim0 (i 0)
example : Nonempty (Index (fun _ : Fin 0 => 0)) := ⟨fun i => Fin.elim0 i⟩
private def dup : IndexMaps.BroadcastAxes 3 3 := ⟨#[1,0,1].toVector, by decide⟩
example : ∀ i, shape i = shape (dup.decode i) := fun _ => rfl
example : ¬ ∃ p : AxisPermutation 3, ∀ i, dup.decode i = p.outputToInput i := by
  rintro ⟨p,h⟩
  have heq : p.outputToInput 0 = p.outputToInput 2 := (h 0).symm.trans (h 2)
  have impossible := congrArg p.inputToOutput heq
  rw [p.input_output, p.input_output] at impossible
  exact (by decide : (0 : Fin 3) ≠ 2) impossible
```

Review window 23:08:06–23:10:50 UTC (164 s wall, including compilation). The first control harness failed on an untyped dependent numeral and emitted two declaration-style warnings (0.467 s); fixing the harness took a successful 0.503 s compile, and the final duplicate-axis control replay took 0.435 s. No theorem or frozen input changed. Exclusive reasoning time, token cost and original discovery effort are unknown. No native implementation was run.
