import FilterProof
set_option autoImplicit false
namespace RevisedBenchmark.ConvFilter
def a : Window := ⟨6,3,1,1,1,1,0,0,true⟩
def inputs (_ : Nat) (p : List Nat) : Int := p.head! + (1 : Int)
def weights (_ : Nat) (j : List Nat) : Int := (j.head! : Int) + 1
example : oldShape a = 2 ∧ newShape a = 2 := by decide
example : oldConv [a] [1] 1 inputs weights = 20 ∧ newConv [a] [1] 1 inputs weights = 20 := by decide
example : newConv [{a with reverse := false}] [1] 1 inputs weights = 28 := by decide
example : oldOff a 2 = 2 ∧ newOff a 1 = 2 := by decide
example : oldShape {a with input := 0} = 0 := by decide
end RevisedBenchmark.ConvFilter
