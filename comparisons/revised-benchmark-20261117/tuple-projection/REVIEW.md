# Independent review of tuple projection

**Accept the frozen logical-value model.** `RevisedBenchmark.TupleProjection.projection` covers the one retained replacement action for every successful, legal projection of an already evaluated tuple, at the declared typed-value observation. This closes the `pure_tuple` partition of `HandleGetTupleElement/tuple-projection` (`site-L05566-C009`). The retained record also lists `effect_graph`, which remains unresolved. No full-record, physical-layout, execution-reachability or C++ correspondence verdict follows.

## Source binding and coverage

The retained mapping is unique for this case. `census/site-case-map.json` binds it to line 5566 with no additional sites. `census/source-normalization-registry.json` calls it a source action variant without an alias. `census/mathematical-ledger.json` and `census/formulation-evidence-baseline-v1.json` attach no prior proof evidence to the row. `census/simple-mathematical-domains-v1.json` identifies the two domains and explicitly leaves possible changes from eliminating other field evaluations open. This is a new checked partition of a newer candidate record, separate from the historical artifact inventory.

At pinned XLA `e58e523b11f1fde802a493a776d158007486e1bf`, `algebraic_simplifier.cc:5558–5573` has exactly one replacement action. It checks `kTuple`, then forwards the operand at the original `tuple_index()` through the compatibility helper. An unsuccessful compatibility path and a non-`kTuple` producer have no replacement. There is no dtype, rank, position or value dispatch on the successful path. `hlo_instruction.cc:2737–2746` builds tuple shapes from operands in order and passes those same operands to `CreateVariadic`. `hlo_verifier.cc:1446–1452,2010–2012,2933–2938` checks tuple/projection shapes, and `shape_inference.cc:3819–3835` checks tuple shape and signed index bounds, returning the selected component shape. Legal index is a source validity assumption represented by `Fin n`, rather than a test newly attributed to the simplifier.

`algebraic_simplifier.cc:623–634,861–880` rejects control predecessors and requires `SameShape`, which uses equality or compatibility according to layout sensitivity. The helper passes preservation flags. `dfs_hlo_visitor_with_default.h:384–399` delegates with control-dependency relay and unused-operand removal enabled. `hlo_computation.cc:2063–2078,2089–2164` checks compatibility, can refuse incompatible sharding, and can relay control dependencies, transfer metadata/sharding or attributes, replace uses and remove the old instruction and unused operands. These operations and their success/failure conditions lie outside the typed-value observation. The theorem can represent logical shapes as tags and proves preservation of the chosen tag and payload within the model. It assumes valid source HLO and successful substitution when interpreting the model, and does not verify the HLO shape verifier, metadata, layouts, evaluation effects, control/graph mutation, or success of a replacement.

## Exact theorem, assumptions and controls

`TupleSpec.lean` quantifies over arbitrary tag and payload universes, finite arity, tag family, dependent operand family, and every bounded index. `makeTuple` materializes `List.ofFn` of sigma pairs and applies standard optional list lookup. The RHS directly indexes the family. There is no equality hypothesis, constrained payload family, element predicate, distinct-tag requirement, hypothesis on rank/shape, or implementation-defined output witness. Arbitrary nested values and logical component shapes can remain opaque payloads and tags. The only computational domain restriction is a legal selected index on already available inputs. `Fin 0` has no inhabitants, so the theorem admits an empty tuple representation with no valid projection.

The proof uses Std's list lookup simplification and the index bound. Project-local closure consists of `TupleSpec` alone, which imports toolchain `Std` plus implicit `Init`. No project theorem or target-specific import provides the equality. The checked-in heterogeneous witnesses exercise both indices and the wrong-index witness rejects picking the `Bool` payload at the `Nat` position. Singleton lookup succeeds and an empty list returns `none` at zero. An independent check also rejects picking payload `4` instead of `3` with the **same** tag, and proves `¬ Nonempty (Fin 0)`. These controls distinguish value and position errors without asserting the source optimizer accepts invalid indices.

## Reproduce the fresh focused replay

Review checkout `84a81af1f97e08468750fd93d8208dc4d6e882a3`, spec freeze `977b0065ab231cf531ccaa26aaaaa5bd27b8af6b`. Checkout files byte-matched the exact Git blobs. `sha256sum -c` passed against the frozen manifest. The only packet change between the two revisions is `TupleProof.lean`. Lean 4.35.0 x86_64 Release reported commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. Both packet modules were compiled in an empty temporary directory using the installed toolchain's compiled standard library. No Lake, package cache, network, XLA execution, or build of other project modules was involved. This is a fresh source-to-kernel check of the packet and an exact expanded-type witness, with the installed Lean/Std trusted.

```bash
set -eu
p=comparisons/revised-benchmark-20261117/tuple-projection
sha256sum -c "$p/SHA256SUMS"
d=$(mktemp -d /tmp/tuple-review.XXXXXX)
lean=/workspace/toolchains/lean-4.35.0-linux/bin/lean
git show 977b0065ab231cf531ccaa26aaaaa5bd27b8af6b:"$p/TupleSpec.lean" > "$d/TupleSpec.lean"
git show 84a81af1f97e08468750fd93d8208dc4d6e882a3:"$p/TupleProof.lean" > "$d/TupleProof.lean"
cmp "$p/TupleSpec.lean" "$d/TupleSpec.lean"
cmp "$p/TupleProof.lean" "$d/TupleProof.lean"
cd "$d"
export LEAN_PATH="$d" LEAN_SRC_PATH="$d"
"$lean" --version
"$lean" --deps TupleSpec.lean
"$lean" -o TupleSpec.olean TupleSpec.lean
"$lean" --deps TupleProof.lean
"$lean" -o TupleProof.olean TupleProof.lean
cat > Independent.lean <<'LEAN'
module
public import TupleProof
public section
set_option autoImplicit false
namespace RevisedBenchmark.TupleProjection
universe u v
example : ∀ {Tag : Type u} {Payload : Tag → Type v} {n : Nat}
    (tags : Fin n → Tag) (operands : (i : Fin n) → Payload (tags i)) (i : Fin n),
    (List.ofFn (fun k => (⟨tags k, operands k⟩ : Sigma Payload)))[i.val]? =
      some ⟨tags i, operands i⟩ := projection

private def sameTags : Fin 2 → Unit := fun _ => ()
private def sameEntries (i : Fin 2) : Nat := i.val + 3

example : (makeTuple (Payload := fun _ : Unit => Nat) sameTags sameEntries)[0]? = some ⟨(), 3⟩ := rfl
example : (makeTuple (Payload := fun _ : Unit => Nat) sameTags sameEntries)[0]? ≠ some ⟨(), 4⟩ := by
  intro h
  have h34 : (3 : Nat) = 4 := congrArg (fun a : Sigma (fun _ : Unit => Nat) => a.2) (Option.some.inj h)
  contradiction
example : ¬ Nonempty (Fin 0) := fun h => h.elim Fin.elim0

#print axioms Goal
#print axioms makeTuple
#print axioms projection
end RevisedBenchmark.TupleProjection
LEAN
"$lean" Independent.lean
```

All five Lean commands returned 0 without warnings or stderr. `Goal` and `projection` each report `[propext]`. `makeTuple` reports no axioms. The `--deps` output referenced only `Init`, `Std`, and the temporary `TupleSpec.olean`. Independent checking used the committed proof and frozen spec, and no files other than this review were changed in the checkout by the reviewer.

| Input | SHA-256 |
| --- | --- |
| `TupleSpec.lean` | `f4ab9ec8b3d8336604179ca35f89c349432570b7edb3b2dbbf693932e8de44ce` |
| `TupleProof.lean` | `d1b022760e74e34fe72b131ee2753a86c686984d9778d5081be1d3b9566bb519` |
| `lean-toolchain` | `ca5f1f601d34c49079e38d7e7041eb0f2a9c227fbc1df0f404820069a052330c` |
| `algebraic_simplifier.cc` | `1ecfd7d4ba958ac0e795d8663c14f7f6b1ebd147a8a83ed0e99661740105628f` |
| `dfs_hlo_visitor_with_default.h` | `ac918b83c5608e76bbdd2792c3b3975b85054bf8c6c3190bacd8cec74243e383` |
| `hlo_computation.cc` | `f3afcd7e3122e17e36462dd70b1cb947be16c725cc2235432829bbf33d6f5aef` |
| `hlo_instruction.cc` | `39fa166394233ef34fd3adb38265b116e8361e27dadfe4301909a32456168b85` |
| `hlo_verifier.cc` | `3e7aee3f96e025965e861e68efe90cee276bc9377efc271e7180b9bb78bb9101` |
| `shape_inference.cc` | `e55b7a4f46b2e6ac157ac6918fff06078c78c7e865f8a24b5da8c259d932c5e6` |
| `Init.olean` | `84ffd94782b2f2f65408dee401a4332bfa7c3274abc7b1040cea7d7a307314f5` |
| `Std.olean` | `81655926012444f214099f1ed6610ed63ade63f9e91b2e5af6689acd9cf1b400` |

All listed XLA source files matched their repository source manifests (`sources/manifest.json`, `dependency-supplement.json` or `indexing-contract-manifest.json`).

## Review effort

Review clock started at 21:52:27 UTC on 2026-11-17. An initial replay setup found `/usr/bin/time` missing before Lean started. Python monotonic timing resolved it without installs. Dependency inspection took 0.036 and 0.033 seconds. Fresh spec/proof compilation took 0.303 and 0.299 seconds. The independent Lean witness and controls took 0.382 seconds. Total measured Lean command time was 1.052 seconds including dependency inspection. Author proof development time and active/token costs are unmeasured by this review.

The review was recorded at 21:55:00 UTC, 153 seconds of wall time from the first tool timestamp, including evidence reading, setup repair, replay, and reporting.
