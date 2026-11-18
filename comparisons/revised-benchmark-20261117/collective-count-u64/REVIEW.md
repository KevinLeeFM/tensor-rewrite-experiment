# Independent review: exact U64 uniform collective sum

**Verdict: accept the complete frozen mathematical case for both AllReduce and ReduceScatter output projections.** The U64 host fold and U64 participant sum agree exactly modulo `2^64` for every admitted group size and word. The packet establishes this for its specified ordered model and every modeled output position; it does not prove source-code correspondence, a native collective, communication progress, or a particular backend schedule.

## Source guards and host arithmetic

The frozen transform is `HandleAllReduceOrReduceScatter/sum-integral` in `algebraic_simplifier.cc:1432–1500`, reached by the AllReduce and ReduceScatter handlers (`:1493–1500`). It first calls `MatchUniformCollectiveOperand`: the instruction must be a one-operand array collective without control dependencies, async context, or conditional ancestry; layout-sensitive host-memory outputs are excluded (`:1340–1366`). A scalar constant or scalar-constant broadcast matches, as does a nonempty all-first constant array. The packet's scalar-literal broadcast is directly inside this accepted subset.

The reducer must match a direct scalar binary Add of the two reducer parameters in either operand order (`collective_ops_utils.cc:99–109`; opcode mapping at `:69–80`). For SUM, the simplifier obtains a known group size (`algebraic_simplifier.cc:1454–1460`), reads the U64 scalar, converts the positive `int64_t` group size to the same unsigned type, multiplies in U64, constructs a scalar literal, then emits a replacement constant/broadcast with the collective's output shape (`:1461–1486`). The product therefore wraps modulo `2^64` just like U64 addition. The frozen guard `g+1 < 2^63` keeps the positive group size in the source's signed `int64_t` representation before conversion; the cast to U64 is then exact, and the product itself is unsigned modular arithmetic.

`GetReplicaGroupCountAndSize` returns the Iota device-list group size directly, or for explicit groups derives participant counts and requires all groups to have the same size (`collective_ops_utils.cc:554–576`). The packet assumes a known equal group size and models one group's participant set. It does not model group IDs/communication, which are irrelevant to the uniform per-element value once the actual group size is fixed.

## Both output projections

`GroupSpec.Goal` contains two whole-function equalities. The first quantifies over every receiver `Fin (g+1)` and every all-reduce coordinate `I`; for uniform input word `v`, each receiver and coordinate gets the repeated participant sum, equal to the source scalar `v * group_size`.

The second quantifies over every reduce-scatter receiver and every local output coordinate `Fin k × C`. HLO ReduceScatter first reduces each input position across the group and then gives receiver `r` its `r`-th equal-sized block; its shape inference requires the scatter dimension to divide by the shard count and sets output width to input width/group size (`shape_inference.cc:2883–2917`). For input width `(g+1)*k`, local coordinate `j` at receiver `r` projects from global slot `r*k+j`; this is exactly `Exchange.slot`. Other axes are carried in `C`. The source creates a uniform replacement broadcast to the collective output shape (`algebraic_simplifier.cc:1372–1401,1483–1486`), so the model compares all projected receiver blocks, not just a single reduction scalar. `k=0` represents an empty scatter output and the function equality is vacuous, as it should be; positive-width cases use the checked slot map.

The source contract describes ReduceScatter as all-reduce followed by splitting the reduced value and giving replica `i` its `i`-th shard (`operation_semantics.md:4049–4087`). That documentation is supporting evidence but is not in this packet's source hash manifest. The implementation helper and shape-inference files inspected for this review are also not listed in `SHA256SUMS`; their current SHA-256 fingerprints are `3331b9caa3527d1105b1d2b76d90b6b4e0c2f32ab99747d7b7bce59d859c7c20` (`collective_ops_utils.cc`), `e55b7a4f46b2e6ac157ac6918fff06078c78c7e865f8a24b5da8c259d932c5e6` (`shape_inference.cc`), and `35bce8d2344a1b5fe3c7ea7dfa5cc7bb7092ef76b673a73b3738e8ee412c4115` (`operation_semantics.md`). The packet Git snapshot identifies the reviewed tree, but the checksum runner itself does not enforce those helper/doc hashes.

## Proof reuse and new work

`GroupProof.uniform` reuses `WideCount.folded` from the earlier Std-only `prefix-wide-count/PrefixProof.lean`, via the fresh import of `PrefixProof`; it does not redo its list-repetition induction. It also reuses the prior `ExchangeSpec.slot` coordinate function for the ReduceScatter projection. The repository library has the corresponding general theorem `TensorRewrite.Theory.PrefixWindow.word_replicate_fold`, valid at arbitrary BitVec width, count, initial word, and repeated value. The new packet keeps the replay Std-only and does not import the Mathlib-dependent project library theorem.

The new proof work is the collective-specific pair of whole-output specifications plus function extensionality over every receiver/coordinate, showing that both collective result observations reduce to the same reused uniform fold/product fact. `verified` explicitly covers both AllReduce and ReduceScatter; the proof is not merely a scalar arithmetic lemma. The controls check modular wrap for three maximum U64 participants, evaluate the direct ordered reduction to the same word, reject a nonuniform participant-value control, and check a nonzero ReduceScatter slot. They check the slot and reduction separately; the theorem supplies their combined all-position result.

## Fresh replay and axioms

At 2026-11-18 02:34:57 UTC, ran:

```text
LEAN=/workspace/toolchains/lean-4.35.0-linux/bin/lean python3 comparisons/revised-benchmark-20261117/collective-count-u64/replay.py
```

The runner verified all six listed entries and compiled the six modules in a fresh temporary directory. `ExchangeSpec` 0.397 s, `PrefixSpec` 0.278 s, `PrefixProof` 0.307 s, `GroupSpec` 0.347 s, `GroupProof` 0.417 s, and `GroupControls` 0.406 s; all exited 0. Wrapper wall time was about 2.4 s; summed Lean module time was 2.152 s. Axiom output is `[propext, Quot.sound]` for `verified` and `[propext]` for the imported wide-count refutation. These are standard Lean axioms. No `sorry`, `admit`, `native_decide`, or added axiom appears in the reviewed proof. The checksum manifest does not hash `GroupProof.lean` or `GroupControls.lean`; this report is tied to the submitted Git snapshot, and the runner enforces the statement/freeze/dependency-source hashes rather than separate proof/control hashes.

## Limits and reuse classification

The model fixes identical U64 input `v` at every participant and position, a direct SUM reducer, known equal positive group size, and the stated admissible context. It excludes nonuniform inputs, control-dependent/async collectives, layout-sensitive host-memory outputs, unknown or unequal group sizes, and any native communication/backend execution. It does not assert a C++–Lean correspondence theorem. The historical exact repetition identity is reused, not counted as a new arithmetic discovery. The new result closes the frozen mathematical U64 collective case for both output projections under those assumptions.

## Timing

Independent inspection began at 2026-11-18 02:32:22 UTC and evidence/report preparation ended at 02:35:59 UTC (3m37s before commit). The interval included source, prior-lemma and packet inspection plus the fresh replay. Source-analysis time was not separately instrumented. No native test, broad build, or child worker was used; active-token usage is unknown.
