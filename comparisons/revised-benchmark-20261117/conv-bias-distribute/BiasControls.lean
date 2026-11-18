import BiasProof
set_option autoImplicit false
namespace RevisedBenchmark.ConvBias
example : old false false 16777216 1 1 3 = 50331648 := by decide
example : newValue 16777216 1 1 3 = 50331652 := by decide
example : old true true 16777216 1 1 1 = newValue 16777216 1 1 1 := by decide
example : ((16777216 : Nat)*1+1)*3 = 16777216*(1*3)+1*3 := by decide
#check (refuted : ∀ a b, ¬ Goal a b)
end RevisedBenchmark.ConvBias
