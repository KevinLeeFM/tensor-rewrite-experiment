#!/usr/bin/env bash
set -euo pipefail

packet=comparisons/revised-benchmark-20261117/slice-shape-exact
lean=${LEAN:?Set LEAN to the pinned Lean executable}
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/TensorRewrite/Pilot"
export LEAN_PATH="$scratch"
"$lean" --version
sha256sum -c "$packet/SHA256SUMS"
run() {
  TIMEFORMAT="%3R s wall"; time timeout 20 "$lean" "$@"
}
run -o "$scratch/TensorRewrite/Pilot/SliceShape.olean" TensorRewrite/Pilot/SliceShape.lean
run -o "$scratch/TensorRewrite/Pilot/EmptySliceRefutation.olean" TensorRewrite/Pilot/EmptySliceRefutation.lean
run -o "$scratch/SliceShapeExactSpec.olean" "$packet/SliceShapeExactSpec.lean"
if [[ "${1:-}" != spec ]]; then
  run "$packet/SliceShapeExactProof.lean"
fi
