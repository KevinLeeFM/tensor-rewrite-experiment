#!/usr/bin/env bash
set -euo pipefail
p=comparisons/revised-benchmark-20261117/slice-shape-exact
r=$p/rank
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
export LEAN_PATH="$scratch"
lean=${LEAN:?Set LEAN to Lean 4.35.0}
"$lean" --version
sha256sum -c "$r/SHA256SUMS"
build() {
  echo "$2"
  TIMEFORMAT="%3R s wall"; time timeout 20 "$lean" -o "$scratch/$1.olean" "$2"
}
mkdir -p "$scratch/TensorRewrite/Pilot"
for name in Tensor Indexing ConstantGuard SliceShape SliceIndexBounds IndexMaps EmptySliceRefutation; do
  build "TensorRewrite/Pilot/$name" "TensorRewrite/Pilot/$name.lean"
done
build SliceShapeExactSpec "$p/SliceShapeExactSpec.lean"
build SliceShapeExactProof "$p/SliceShapeExactProof.lean"
build RankSpec "$r/RankSpec.lean"
if [[ ${1:-} != spec ]]; then
  build RankProof "$r/RankProof.lean"
fi
