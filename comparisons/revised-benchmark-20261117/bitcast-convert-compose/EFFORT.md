# Effort and replay record

Continuation started 2026-11-18 03:37:56 UTC. Direct Lean replay finished at 2026-11-18 03:40:12 UTC; 136 seconds elapsed. Fresh closure: packet-local `ShapeInference.lean` and Lean 4.35.0 `Std`; no Mathlib/Lake import or dependency access. Direct command used:

```sh
/workspace/toolchains/lean-4.35.0-linux/bin/lean comparisons/revised-benchmark-20261117/bitcast-convert-compose/ShapeInference.lean -o /tmp/bitcast-shape-check.olean
```

Lean reported version 4.35.0, commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. Direct compile wall times were 0.472 seconds initially, 0.553 seconds for the first final replay, and 0.479 seconds for the final manifest-checked replay. Both the exact shape mismatch target and wrong widening-extent control compiled. Axiom output is recorded by `#print axioms` in the same direct replay.

Earlier materialization attempt belongs to the preceding packet checkpoint: Lake checked out FloatLib (~206 MB observed directory size), but no Lean/build started. The attempt ran 30.3 seconds; the task-created `.lake` directory was removed. It is excluded from this fresh proof closure. A local path-depth mistake caused one checksum command to stop before replay; it was corrected, source checksums passed, and the final replay completed. No further cache or network calls were made. No worker time or token usage measured. Source/proof library remained unchanged.
