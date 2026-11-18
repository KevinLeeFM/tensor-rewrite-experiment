# Convolution Mathlib cache feasibility preflight

**Outcome:** the pinned, selective official Mathlib cache route is documented, but this environment cannot currently reach its official endpoint and has no local Mathlib artifacts. The cache payload size for the exact convolution import closure is therefore **not measurable here**. No cache object, package, or build was requested.

## Scope and pin

- Checked on 2026-11-18, from this worktree; source project has Lean 4.35.0 (`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`) and `lake-manifest.json` pins Mathlib `56a005855ea17e0b0958f73ec801ae140b0a1679`.
- The preceding local setup record, [`convolution-cloud-setup.md`](convolution-cloud-setup.md), reports that the 18 local modules reachable from `TensorRewrite.Theory.ConvolutionSeparableProof` need these direct external Mathlib roots: `Mathlib.Algebra.BigOperators.Fin`, `Mathlib.Algebra.BigOperators.Group.Finset.Basic`, `Mathlib.Algebra.BigOperators.Group.Finset.Sigma`, `Mathlib.Algebra.BigOperators.Ring.List`, and `Mathlib.Data.Fintype.Pi`; `Std` is also imported. The exact transitive package artifact count and bytes had not been measured.
- Current shared checkout was clean at the time of inspection, but its HEAD advanced during this pass (`9b94f68` in the task handoff, then `20fa0f5`, then `687df44`). No source files were edited. This report is based on the unchanged pin/setup note and current filesystem observations, not on assuming those intermediate commits were identical.

## Local cache, toolchain and disk observations

Read-only search of `/home/agent/.cache`, `/workspace`, and `/tmp` to depth five found no Mathlib tree, `.lake/build/lib/lean/Mathlib`, or Mathlib-named cache directory. The worktree has no `.lake` directory. This is consistent with the prior empty-module-path result in `convolution-cloud-setup.md`; it does not prove there is no cache outside the searched roots.

The installed Lean executable is `/workspace/toolchains/lean-4.35.0-linux/bin/lean`, version 4.35.0, commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. The corresponding Lake reports version `5.0.0-src+eb6cafb`. The toolchain directory occupies 2.5G; this is not Mathlib storage. `df -B1 /workspace` reported 67,586,535,424 total bytes, 17,871,540,224 used and 46,262,292,480 available (about 43.1 GiB free). Disk space is not the present blocker, but free space alone cannot bound the requested selective cache.

## Official pinned cache documentation and endpoint probe

Inspected the official upstream `Cache/README.md` and `Cache/Requests.lean` at the exact Mathlib pin above. The pinned README documents that `lake exe cache get <module-or-file>` fetches only those targets and transitive imports, that `lookup` reports cache-file information, that artifacts are served through `https://cache.mathlib.org`, and that downloaded `.ltar` archives are unpacked into compiled artifacts (including `.olean`, `.ilean`, `.trace`, generated `.c`, and hash files). It also documents the cache filename form under `{container}/{key}` and how an external cache client forms object URLs. This is an official, revision-matched path; it supports a selective request rather than a full Mathlib cache fetch.

A bounded endpoint availability check was attempted:

```text
curl -I --max-time 10 --connect-timeout 5 --max-filesize 0 https://cache.mathlib.org/
```

It returned curl exit 56 immediately with `HTTP/1.1 403 Forbidden`, `content-length: 16`, and `curl: (56) CONNECT tunnel failed, response 403`. No artifact request was made and no payload was downloaded. The failure is at the environment's CONNECT tunnel; it does not establish that the official cache lacks the pinned artifacts. No network/security setting was changed.

Official pinned sources:

- [Mathlib Cache README at 56a0058](https://github.com/leanprover-community/mathlib4/blob/56a005855ea17e0b0958f73ec801ae140b0a1679/Cache/README.md)
- [Mathlib Cache Requests at 56a0058](https://github.com/leanprover-community/mathlib4/blob/56a005855ea17e0b0958f73ec801ae140b0a1679/Cache/Requests.lean)

## Size estimate and feasibility

The official docs establish that the cache client can restrict artifacts to the listed modules and transitive imports, but this checkout lacks the pinned Mathlib source and cache client, so it cannot compute the exact transitive hash closure or invoke `lake exe cache lookup`. The proxy denied the only bounded endpoint HEAD probe before an object URL/hash could be obtained. The observed endpoint response supplies no artifact-size metadata. Consequently, neither compressed download bytes nor decompressed footprint for the precise convolution closure can responsibly be estimated from the available evidence. The 2.5G Lean toolchain and unrelated full-cache sizes are not valid substitutes.

**Feasibility verdict:** the selective official mechanism is suitable in principle, and local disk currently has approximately 43.1 GiB free; network/cache reachability and exact selective closure size are unverified here. Do not start cache download or a Lake build in this environment based on this preflight.

## Minimal next action

Run the official cache client's `lookup` for the five exact Mathlib roots above in an already configured, approved environment that has the exact pinned Mathlib checkout and matching Lean build. Record the resulting transitive hashes and use bounded HEAD requests on only those documented object URLs to sum reported content lengths, if the endpoint provides them. Then check the expected unpacked footprint and free disk before any transfer. If that metadata route is unavailable, ask for a read-only cache mount or environment with approved access; do not use a mirror, switch cache revisions, or fall back to a full cache/build.

## Commands and timing

Inspection began at 2026-11-18 02:03:58 UTC and ended at 02:06:41 UTC (2m43s wall time, including report preparation). Commands were read-only status/revision checks, reading the existing setup note and manifest, bounded local filesystem/disk/toolchain inspection, pinned upstream documentation inspection, and the single bounded `curl -I` above. The endpoint check completed in under one second with the recorded failure. No Lean compile, package install, artifact download, cache lookup, Lake build, or worker was run. No proof-search effort or token cost was measured.

### Exact default object host and URL shape (follow-up, 02:07 UTC)

The pinned `Cache/Infra.lean` distinguishes the actual read host and the low-level storage account:

- Normal reads use the public endpoint `https://cache.mathlib.org`; the endpoint is described as edge-caching the same container namespace as storage. The `MATHLIB_CACHE_DEBUG_USE_LEGACY` troubleshooting path instead sends `master` reads to `https://lakecache.blob.core.windows.net`. I did **not** probe the legacy host or change the client setting.
- For the canonical `leanprover-community/mathlib4` repo, the default read chain is only `master`, whose `flatPath` is true. The pinned `Cache/Infra.lean` plus `Cache/Location.lean` constructs the canonical file URL as `https://cache.mathlib.org/mathlib4-master/f/{hash}.ltar`. (A `forks` read has repo/SHA namespace segments; it is not the default route for this canonical repo.)
- The earlier HEAD was only `https://cache.mathlib.org/`, the endpoint root. It does **not** test that the known container path responds or establish whether any particular artifact exists. No cache hashes are available locally, so no artifact-specific HEAD/metadata request was made. The root probe remains an environment egress failure, not evidence of a cache miss.

This exact route is supported by the [pinned Cache/Infra.lean](https://github.com/leanprover-community/mathlib4/blob/56a005855ea17e0b0958f73ec801ae140b0a1679/Cache/Infra.lean) and [pinned Cache/Location.lean](https://github.com/leanprover-community/mathlib4/blob/56a005855ea17e0b0958f73ec801ae140b0a1679/Cache/Location.lean). Remaining blocker is obtaining the exact transitive cache hashes through the pinned client in a properly provisioned environment; do not bypass this environment's CONNECT denial.
