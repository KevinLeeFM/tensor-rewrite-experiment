import TensorRewriteTheory

open TensorRewrite.Theory.LogicalFamily

#print axioms rewrite_sound
#print axioms allRules_complete
#print axioms allRules_nodup
#print axioms word_keys_uniform
#print axioms predicate_count
#print axioms word_count

#eval do
  for rule in allRules .predicate do
    IO.println s!"LOGICAL_PROFILE predicate {rule.key}"
  for rule in allRules (.word 0) do
    IO.println s!"LOGICAL_PROFILE word_all_widths {rule.key}"
