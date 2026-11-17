# Independent final review of HandleSlice/identity

**Accepted for the complete frozen static logical-value observation.** At freeze d8671ee1e736c0b881b0e5a4b6e5c7558c3cb874, `RevisedBenchmark.StaticIdentity.Goal` quantifies over every finite rank, shape, legal equal-input/output-shape axis configuration, element type and tensor. The conclusion is equality of the entire sliced and original tensor. Proof 5514a3ccf99084f0f7505736264cbda11b988ead checks at precisely that type. I did not author either file.

The source file matched the recorded XLA e58e523b SHA-256 1ecfd7d4ba958ac0e795d8663c14f7f6b1ebd147a8a83ed0e99661740105628f. See algebraic_simplifier.cc lines 7655–7660, 623–634 and 858–879. Source forwarding also considers layout sensitivity, control predecessors and replacement metadata/sharding. The theorem proves value preservation on homogeneous static logical tensors assuming a legal represented slice. It leaves replacement status, dynamic/runtime shape reconciliation, layout, metadata, overflow and C++ correspondence outside scope.

The historical Haskell rule01 in sources/tensorright/artifact/tr-artifact/rules/slice/Main.hs requires start zero, end equal to size and stride one. Its inherited Lean SliceGeometry.full uses explicit starts and strides alongside equal-shape validity. The present proof derives pointwise identity from legal equal extents alone. For each admitted coordinate j on an axis of extent n, sliceIndex_val gives start + stride*j. Applying coordinate_bounds at n−1 shows start + (stride−1)*(n−1) ≤ 0. Both terms are nonnegative, and the displacement at j is bounded by the displacement at n−1. Thus even singleton axes with arbitrary positive stride read the same coordinate. On an empty axis there is no admitted coordinate; rank zero has the unique empty coordinate tuple. Value equality therefore covers both without asserting unit stride.

All eight freeze entries matched, and the source SHA-256 of IdentityProof.lean was df1af3e819c30da41acabd16de4119d5a994745123a097e5201a5a8944503090. I compared actual transitive imports with the freeze. The seven local dependencies end at shipped Std, with no historical paper theorem imported. SliceShape contains additional source-shaped attribute transformers, but the proof uses legality, the coordinate formula and its independently general bound. Fresh Lean 4.35.0 eb6cafb7 kernel replay of every local source, spec and proof in an empty temporary directory printed only propext and Quot.sound for forward. No extra axiom, native evaluation or admitted proof appeared.

## Independent controls and time

The following reviewer harness compiled. A (1,3) nonconstant Nat tensor retains value 2 at (0,2), even with stride 7 on its first axis; replacing the result by constant zero is refuted. The final check excludes an incorrectly declared identity size. The author's extent-zero/stride-seven and invalid shifted-slice controls also compiled.

```lean
import IdentityProof
open TensorRewrite.Pilot RevisedBenchmark.StaticIdentity
def dims (k : Fin 2) : Nat := if k.val = 0 then 1 else 3
def axes (k : Fin 2) : SliceShape.Axis := if k.val = 0 then ⟨0,1,7⟩ else ⟨0,3,1⟩
theorem ok (k : Fin 2) : SliceShape.IsWellFormed (dims k) (dims k) (axes k) := by
  rcases k with ⟨k,h⟩
  have : k = 0 ∨ k = 1 := by omega
  rcases this with rfl | rfl <;> simp [dims,axes] <;> decide
def tensor : Tensor dims Nat := fun j => (j 1).val
def pt (k : Fin 2) : Fin (dims k) :=
  if h : k.val = 0 then ⟨0, by simp [dims,h]⟩ else ⟨2, by simp [dims,h]⟩
example : tensor (IndexMaps.sliceIndex axes ok pt) = 2 := by
  exact congrFun (forward dims axes ok Nat tensor) pt
example : (fun j => tensor (IndexMaps.sliceIndex axes ok j)) ≠ (fun _ => 0) := by
  intro h
  have x := congrFun h pt
  change tensor (IndexMaps.sliceIndex axes ok pt) = 0 at x
  have y := congrFun (forward dims axes ok Nat tensor) pt
  change tensor (IndexMaps.sliceIndex axes ok pt) = 2 at y
  omega
example : ¬ SliceShape.IsWellFormed 3 3 ⟨0,3,2⟩ := by decide
```

Independent replay used only the pinned compiler, shipped standard library, and fresh local oleans. Final clean per-module seconds, in order Tensor, ConstantGuard, ConstantGuardLemmas, SliceShape, SliceIndexBounds, IndexMaps, IndexMapLemmas, IdentitySpec, IdentityProof, controls: 0.297, 0.428, 0.318, 0.316, 0.334, 0.415, 0.287, 0.246, 0.341, 0.387 (3.369 s total). A first fresh pass took 3.653 s and the reviewer's control failed because decide saw an unreduced proof field. Unfolding the concrete shape and attributes fixed it; a second pass took 3.643 s with only a reviewer-local declaration-style warning. Changing def to theorem cleared it. The submitted theorem and freeze stayed unchanged throughout. Shipped Std artifacts were reused. No broad build, package installation or native execution.

Review began 22:51:20 UTC, ended 22:53:25 UTC on 2026-11-17 (125 s wall including review, replay and recording). Prior discovery time and active/token cost unknown.
