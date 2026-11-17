# Five historical model partitions recovered for the source register

Each row in [the crosswalk](heldout-crosswalk.json) identifies one independently accepted historical model partition, its primary census binding, exact theorem, original Git revisions, and packet-relative artifact paths and SHA-256 digests. These are five existing results, zero new proofs, zero newly closed source records. The separate 118 paper-artifact outcomes remain unchanged. No mapping here certifies C++ correspondence.

| Primary source record | Source line | Attribution boundary |
| --- | ---: | --- |
| HandleReverse/inserted-unit-dimensions | 7313 | Unit insertion only. The helper can recognize zero-sized modified gaps outside the proof. |
| SimplifyTransposeOfBroadcast/mapped-dims-logical | 2946 | Transpose caller at 10744. The helper has a shared layout-sensitive replacement site and a Bitcast caller; neither receives credit. |
| HandleDynamicSlice/unit-reshape | 8239 | Unit insertion and width-one model restriction. Deletions remain open. |
| TryRemoveUpcastAndDowncastSurroundingBinaryOp/remainder | 2387 | Unsigned remainder only. Four other opcode IDs share this site. The mathematical width domain extends beyond source types. |
| HandleDynamicSlice/transpose | 8257 | Arbitrary permutation with decoded starts and legal widths. Native decoding, layout and reachability remain outside the proof. |

For each packet, I checked the original report, declared scope, independent reviews, acceptance receipt and pinned source site. Across five packets, all 54 frozen input entries matched both their preproof Git bytes and the historical accepted revision; entries can overlap across packets. The census and packet all reference identical simplifier bytes. The JSON records byte hashes from Git for each named artifact, including the proof and effort ledger. Reproduce an artifact hash with `git show <historical_commit>:<packet_directory>/<file> | sha256sum`.

The historical unit-reverse reviewer inspected the coordinator replay. The other four reviewers reported fresh replays. This reconciliation checked Git evidence only. Historical worker intervals and original failures stay with their packets; approximate, overlapping and missing intervals cannot be added to obtain comparable discovery costs. Historical statements in the synthesis about then-unresolved space-depth describe that earlier assessment only.
