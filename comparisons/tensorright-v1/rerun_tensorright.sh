#!/usr/bin/env bash
# Rebuild the frozen artifact using the authors' image, without changing the source tree.
set -euo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
frozen="$repo_root/sources/tensorright/artifact/tr-artifact"
result_dir=$(mktemp -d "${TMPDIR:-/tmp}/tensorright-rerun.XXXXXXXX")
image='lsrcz/tensor-right@sha256:2bff63d64900e2206d97666db503507abe16a898603b2eb2108422625afea047'
printf 'Saving container stdout and stderr in %s\n' "$result_dir"
docker run --rm --network none --mount "type=bind,src=$frozen,dst=/frozen,readonly" \
  --entrypoint bash "$image" -lc \
  'set -e; cd /home/tr; rm -rf rules src; cp -a /frozen/rules /frozen/src .; cp /frozen/package.yaml /frozen/stack.yaml /frozen/runall.sh .; stack build; echo FROZEN_BUILD_COMPLETE; ./runall.sh' \
  > "$result_dir/stdout" 2> "$result_dir/stderr"
cat "$result_dir/stdout"
