import FilterSpec
import PadDotProof

set_option autoImplicit false
namespace RevisedBenchmark.ConvFilter
open RevisedBenchmark.PadDot

private theorem extent_at (a : Window) : extent (support a) = span a.kernel (a.gap+1) := by
  cases a with | mk x n g s b d l h r =>
    cases n <;> simp [support, extent, body, step, span]

private theorem shape_at (a : Window) (law : ok a) : oldShape a = newShape a := by
  obtain ⟨_, _, _, hg | hd⟩ := law
  · simp [oldShape,newShape,newDil,hg,extent_at,span]
    cases a.kernel <;> simp
  · simp only [oldShape,newShape,output,extent_at,hd]
    have dh : newDil a = a.gap+1 := by by_cases g : a.gap = 0 <;> simp [newDil,g,hd]
    rw [dh]
    cases h : a.kernel <;> simp [span]

private theorem offset_at (a : Window) (law : ok a) (j : Nat) (hj : j < a.kernel) :
    oldOff a (pos (support a) j) = newOff a j := by
  unfold oldOff newOff
  rw [extent_at]
  have hn : a.kernel ≠ 0 := by omega
  obtain ⟨_, _, _, hg | hd⟩ := law
  · simp [pos,support,step,span,hn,hg,newDil,offset]
  · have dh : newDil a = a.gap+1 := by by_cases g : a.gap = 0 <;> simp [newDil,g,hd]
    simp only [pos,support,step, Nat.zero_add,offset,hd,Nat.mul_one,dh]
    cases a.reverse <;> simp [span,hn,Nat.sub_mul]

private theorem offsets (ws : List Window) (law : ∀ a ∈ ws, ok a)
    (j : List Nat) (hj : j ∈ grid (ws.map Window.kernel)) :
    List.zipWith oldOff ws (address (ws.map support) j) = List.zipWith newOff ws j := by
  induction ws generalizing j with
  | nil => rfl
  | cons a ws ih =>
    simp only [List.map_cons, grid, List.mem_flatMap, List.mem_map, List.mem_range] at hj
    obtain ⟨i,hi,js,hjs,rfl⟩ := hj
    simp only [List.map_cons,address,List.zipWith_cons_cons]
    congr 1
    · exact offset_at _ (law a (by simp)) _ hi
    · exact ih (fun b hb => law b (by simp [hb])) _ hjs

theorem verified : Case := by
  intro ws law
  refine ⟨List.map_inj_left.mpr (fun a ha => shape_at a (law a ha)), ?_⟩
  intro q _ features x k
  unfold oldConv newConv
  apply congrArg List.sum
  apply List.map_inj_left.mpr
  intro c _
  rw [RevisedBenchmark.PadDot.verified]
  unfold replacement
  have sizes : (ws.map support).map sliced = ws.map Window.kernel := by
    simp only [List.map_map]
    exact List.map_inj_left.mpr fun a _ => slice_width (support a)
  rw [sizes]
  apply congrArg List.sum
  exact List.map_inj_left.mpr fun j hj => by simp [times,offsets ws law j hj]

example : Case := verified
#print axioms verified
end RevisedBenchmark.ConvFilter
