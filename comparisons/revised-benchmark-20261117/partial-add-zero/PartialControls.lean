import PartialProof
namespace RevisedBenchmark.PartialAdd
def window (s : Int) : Window 3 1 := ⟨by decide,s⟩
example : locate (window (-5)) 0 = some 0 := by decide
example : locate (window 70) 2 = some 0 := by decide
example : original (window 1) true (fun _ => true) (fun _ => true) 1 = 0x80000000#32 := by decide
example : replacement (window 1) (fun _ => true) (fun _ => true) 0 = 0x80000000#32 := by decide
example : original (window 1) false (fun _ => true) (fun _ => true) 0 = 0#32 := by decide
example : original (window 1) true (fun _ => false) (fun _ => true) =
    replacement (window 1) (fun _ => false) (fun _ => true) := (agree_iff ..).mpr (by simp)
end RevisedBenchmark.PartialAdd
