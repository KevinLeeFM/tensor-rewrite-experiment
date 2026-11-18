module
import AdjacentProof
set_option autoImplicit false
namespace RevisedBenchmark.AdjacentScan
example : Goal := verified
private def a : Key := ⟨0,[1],[2]⟩
private def b : Key := ⟨1,[1],[2]⟩
private def c : Key := ⟨1,[1],[3]⟩
private def ops : List Block :=
  [.slice a 3 1,.slice a 4 2,.slice a 6 2,.slice b 8 1,.slice b 9 1,
   .opaque 4 1,.slice b 10 2,.slice c 12 1,.slice c 14 1]
example : scan ops = [.slice a 3 5,.slice b 8 2,.opaque 4 1,
    .slice b 10 2,.slice c 12 1,.slice c 14 1] := by decide
private def values : Reader Nat := fun id p i s => 10000*id + 1000*p.sum + 10*i + s.sum
example : packed values values [2] [2] [.slice a 3 1,.slice a 4 1] =
    [1032,1033,1042,1043,2032,2033,2042,2043] := by decide
example : packed values values [1] [1] [.slice b 11 1,.slice c 12 1] ≠
    packed values values [1] [1] [.slice b 11 2] := by decide
example : scan [.slice a 0 0,.slice a 0 1] = [.slice a 0 1] := by decide
example : packed values values [0] [2] ops = [] := by decide
end RevisedBenchmark.AdjacentScan
