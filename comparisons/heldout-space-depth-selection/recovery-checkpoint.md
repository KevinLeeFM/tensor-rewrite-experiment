# Recovered worker checkpoint

Original environment `ccarenv_b64_Y2NhcmVudl9lNjA5YzhmNzUxMjA4MTkxYjczY2U1MjQ4Mjc3ZGY3Yw` reconnected. The worktree was at exactly `b34e4cd8022ae7d1fdae50e2bb3a4df6f744eddc` with no tracked changes. Eight untracked worker/coordination files were copied byte-for-byte before replay into `/workspace/scratch/tensor-worker-recovery-dqh0ij8w`; the following SHA-256 values identify the recovered originals:

- `WorkerIndexJoin.lean`: `3104c7e2e61c54d0c90d0a5c531e789a92dd31e06c3a761db70ac6bb53c3b3b1`
- `WorkerIndexPrefix.lean`: `df61a75414844e09a601f334755336cbc5800e2f7100222ce86cf2fcf2c12fe5`
- `WorkerSuffix.lean`: `a388fc4bcd55941f2e9a7df7f5345b8f367bec55a927c7c6e6af4c60d22f4bdb`
- `proof-coordination-b34e4cd.md`: `52c2a89a2e138c086511d3c5324bf5619b7dfbbdf4c91359bdc3cb5a38248b6a`
- `worker-index-progress.md`: `101d7b883886a3a90910cef9e7f22b848fb47edd0f9e10f5599bd529a8d964b2`
- `worker-suffix-checkpoint.md`: `401d7159e4a04c993b8b96a14a5c0232e51397bdbe31004ea386ccde0a63ac6a`
- `worker-suffix-failure.log`: `504bde72a55aca08faad0c381a60e8ebea5728f33cfe1f2849fb0e789462acd8`
- `worker-suffix-replay.py`: `c1869f888542fac2c707735b3411fbdd88080f2806b1062f43ac7ddb478fe1f5`

All 28 original-goal input hashes and all 45 separate-freeze input hashes matched. Fresh coordinator-run offline Lean 4.35.0 replay rebuilt the 32-module closure in an empty temporary directory in 12.084 seconds, including all three recovered helper modules. Every module compiled without warnings or `sorryAx`; printed dependencies of the recovered results were limited to `propext`, `Classical.choice`, and `Quot.sound`. Exact module outputs, timings and helper hashes are in `recovery-helper-replay.json`. This is a mechanical replay, not an independent review.

The prefix-shape theorem and suffix-extents theorem remain separate. Next derive equal actual tail element counts from suffix extents and the existing merged-head facts, discharge the explicit tail-count premise of `prefix_packed_values_equal`, and connect the remaining tail coordinates, permutation, reshape and frame casts to prove actual `originalIndex = replacementIndex`. The rewrite is not proved. The recovered helpers are unreviewed, the outer-rank guard remains a model restriction, and no C++ correspondence or speedup is claimed. No proof worker was launched in this recovery pass.
