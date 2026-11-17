set -eu
root=/workspace/tensor-benchmark-orchestration-20261117
build=$(mktemp -d /tmp/rank-review.XXXXXX)
lean=/workspace/toolchains/lean-4.35.0-linux/bin/lean
export LEAN_PATH="$build"
cd "$root"
echo "BUILD=$build"
"$lean" --version
mkdir -p "$build/TensorRewrite/Pilot"
for m in Tensor ConstantGuard SliceShape SliceIndexBounds IndexMaps ConstantGuardLemmas IndexMapLemmas; do
  TIMEFORMAT='%3R seconds'; time "$lean" -o "$build/TensorRewrite/Pilot/$m.olean" "TensorRewrite/Pilot/$m.lean"
done
static=comparisons/revised-benchmark-20261117/slice-compose-static
rank=comparisons/revised-benchmark-20261117/slice-compose-rank
cp "$static/Goal.lean" "$build/StaticGoal.lean"
sed 's/^public import Goal$/public import StaticGoal/' "$static/Proof.lean" > "$build/StaticProof.lean"
sha256sum "$build/StaticGoal.lean" "$build/StaticProof.lean"
diff -u "$static/Goal.lean" "$build/StaticGoal.lean"
diff -u "$static/Proof.lean" "$build/StaticProof.lean" || test "$?" -eq 1
cd "$build"
for m in StaticGoal StaticProof; do time "$lean" -o "$build/$m.olean" "$build/$m.lean"; done
cp "$root/$rank/Goal.lean" "$build/Goal.lean"
cp "$root/$rank/Proof.lean" "$build/Proof.lean"
cp "$root/$rank/Controls.lean" "$build/Controls.lean"
for m in Goal Proof Controls; do time "$lean" -o "$build/$m.olean" "$build/$m.lean"; done
cat > "$build/Exact.lean" <<'EOF'
module
public import Proof
@[expose] public section
set_option autoImplicit false
open TensorRewrite.Pilot TensorRewrite.Pilot.SliceShape TensorRewrite.Pilot.IndexMaps
example : RevisedBenchmark.SliceComposeRank.Goal = (∀ {rank : Nat} {inputShape middleShape outputShape : Shape rank} (inner outer : Fin rank → Axis), (∀ i, IsWellFormed (inputShape i) (middleShape i) (inner i)) → (∀ i, IsWellFormed (middleShape i) (outputShape i) (outer i)) → (∀ i, (inner i).stride = 1) → (∀ i, (outer i).stride = 1) → let combined : Fin rank → Axis := fun i => { start := (inner i).start + (outer i).start, limit := (inner i).start + (outer i).limit, stride := 1 }; ∃ (valid : ∀ i, IsWellFormed (inputShape i) (outputShape i) (combined i)), ∀ (innerValid : ∀ i, IsWellFormed (inputShape i) (middleShape i) (inner i)) (outerValid : ∀ i, IsWellFormed (middleShape i) (outputShape i) (outer i)) (index : Index outputShape), sliceIndex inner innerValid (sliceIndex outer outerValid index) = sliceIndex combined valid index) := rfl
#print axioms RevisedBenchmark.SliceComposeRank.correctness
#print axioms RevisedBenchmark.SliceComposeStatic.validity
EOF
time "$lean" -o "$build/Exact.olean" "$build/Exact.lean"
