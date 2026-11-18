# Bounded source/Lean result

## Source finding

The source shapes are not equal under the proposed direct replacement. Shape inference yields U16[2] for U32[] -> U16 and U8[2,2] for U16[2] -> U8. Direct inference for U32[] -> U8 appends the ratio dimension 4 and yields U8[4]. However, `HandleBitcastConvert` constructs the replacement with the original outer result shape U8[2,2]. `HloComputation::ReplaceInstruction` only checks compatibility with the old outer shape; it does not infer the new op's shape. The pinned `ShapeVerifier::HandleBitcastConvert` does infer the output shape and compares it to the given shape. Thus the selected case exposes a shape-verifier mismatch in the rewritten node. This is a source-level well-typedness finding, not a claim that the optimizer accepts it, executes it, or ships a bug; no pass invocation/native test was run.

The byte-stream equality is still a meaningful, separate mathematical proposition: nested repacking to four U8 words has the same stream as direct repacking to four U8 words. It does not establish a type-preserving HLO replacement because the source's inferred direct result shape is rank 1 while the original result is rank 2. The explicit frozen target and controls are in `FREEZE.md`; `BitcastCompose.lean` expresses the primary target by reusing the general `repack_compose` theorem and includes reverse/identity controls, but none of these Lean declarations were elaborated.

## Replay attempt and blocker

The first command `lake env lean ...` failed immediately because `lake` is not on PATH. The pinned executable exists at `/workspace/toolchains/lean-4.35.0-linux/bin/lake`. Running that binary caused Lake to materialize FloatLib from its upstream Git URL; after 30.3 seconds it had checked out the dependency but had not started Lean compilation. This task explicitly prohibited cache/dependency setup, so I stopped. `.lake` was absent at task start and contained only this attempt; it was removed. No source, project dependency, or proof-library files were changed. Fresh Lean replay and proof acceptance remain blocked pending an already materialized dependency environment; no download or build is requested here.

## Evidence and timing

Source commit inspected: `d3a90a78d8aef76674aa42453f737f2b36d5b3d3` (XLA source bundle hashes match its manifest). Read the simplifier, `ShapeInference::InferBitcastConvertShape`, `ShapeVerifier::HandleBitcastConvert`, `InstructionVerifier::HandleBitcastConvert`, `HloComputation::ReplaceInstruction`, and evaluator delegation. Existing mathematical support located: `TensorRewrite.Theory.BitPacking.repack_compose` and `physical_convert_compose`; reused theorem statements were not freshly replayed.

Start 2026-11-18 03:31:17 UTC; end 03:35:39 UTC; 262 seconds elapsed. Compiler time 0 seconds; one failed-by-policy setup/replay attempt took 30.3 seconds before dependency checkout, followed by cache cleanup (7.5 seconds). No workers or builds. `BitcastCompose.lean` and its frozen hashes are candidate, unverified artifacts; independent review is pending. Do not report the mathematical theorem as newly proved.
