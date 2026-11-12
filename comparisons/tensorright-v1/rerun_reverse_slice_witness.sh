#!/usr/bin/env bash
# Add only the documented fixed-input precondition, then run the paper's Slice suite.
set -euo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
frozen="$repo_root/sources/tensorright/artifact/tr-artifact"
comparison="$repo_root/comparisons/tensorright-v1"
work_dir=$(mktemp -d "${TMPDIR:-/tmp}/tensorright-witness-src.XXXXXXXX")
result_dir=$(mktemp -d "${TMPDIR:-/tmp}/tensorright-witness-log.XXXXXXXX")
trap 'rm -rf "$work_dir"' EXIT
cp -a "$frozen/." "$work_dir/"
patch -s -d "$work_dir" -p1 < "$comparison/reverse-slice-witness.patch"
image='lsrcz/tensor-right@sha256:2bff63d64900e2206d97666db503507abe16a898603b2eb2108422625afea047'
printf 'Saving container stdout and stderr in %s\n' "$result_dir"
docker run --rm --network none --mount "type=bind,src=$work_dir,dst=/frozen,readonly" \
  --entrypoint bash "$image" -lc \
  'set -e; cd /home/tr; rm -rf rules src; cp -a /frozen/rules /frozen/src .; cp /frozen/package.yaml /frozen/stack.yaml /frozen/runall.sh .; stack build tensor-right:exe:rules-slice; echo FIXED_WITNESS_BUILD_COMPLETE; stack exec rules-slice' \
  > "$result_dir/stdout" 2> "$result_dir/stderr"
printf 'Inspect the slice/rule13 result in %s/stdout\n' "$result_dir"
