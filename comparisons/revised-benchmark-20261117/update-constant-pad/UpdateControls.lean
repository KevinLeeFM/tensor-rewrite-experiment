import UpdateProof
namespace RevisedBenchmark.UpdateConstantPad
def extent (_ : Fin 1) := 5
def width (_ : Fin 1) := 2
def at4 (_ : Fin 1) : Fin 5 := 4
def at0 (_ : Fin 1) : Fin 5 := 0
def read (x : Fin 1 → Nat) := 7 + x 0
example : update extent width (fun _ => 99) 0 read at4 = 8 := by decide
example : padded extent width (fun _ => 99) 0 read at0 = 0 := by decide
example : padded extent width (fun _ => -8) 0 read at0 = 7 := by decide
example : update extent (fun _ => 0) (fun _ => 0) 42 read at4 = 42 := by decide
example : high 5 2 99 ≠ 1 := by decide
#check (verified : Goal)
end RevisedBenchmark.UpdateConstantPad
