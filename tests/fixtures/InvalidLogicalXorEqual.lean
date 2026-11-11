import TensorRewriteTheory

open TensorRewrite.Theory.LogicalFamily

-- The missing equality condition matters: false xor true differs from false.
example : Domain.xor .predicate false true = Domain.zero .predicate := by
  rfl
