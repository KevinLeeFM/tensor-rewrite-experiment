import TensorRewriteTheory

open TensorRewrite.Theory.LogicalFamily

-- Predicate true is not a word-one identity.
example : Rule (.word 32) := Rule.andTrueRight
