import MirrorSpec
set_option autoImplicit false
namespace RevisedBenchmark.DotMirror
private theorem reverseFn {n : Nat} (f : Fin n → Int) :
    List.ofFn (fun i => f i.rev) = (List.ofFn f).reverse := by
  apply List.ext_getElem (by simp)
  intro i h j
  rw [List.getElem_reverse, List.getElem_ofFn, List.getElem_ofFn]
  congr 1
  apply Fin.ext
  simp [Fin.rev]
  omega

private theorem sumMirror (ds : Axes) (f : Coord ds → Int) :
    sumAt ds (fun i => f (mirror ds i)) = sumAt ds f := by
  induction ds with
  | nil => rfl
  | cons a ds ih =>
    obtain ⟨n, flag⟩ := a
    let row := fun (i : Fin n) => sumAt ds (fun t => f (i,t))
    let pick := fun (i : Fin n) => if flag then i.rev else i
    change (List.ofFn (fun i => sumAt ds (fun t => f (pick i, mirror ds t)))).sum =
      (List.ofFn row).sum
    have rows : (fun i => sumAt ds (fun t => f (pick i, mirror ds t))) =
        (fun i => row (pick i)) :=
      funext fun i => ih (fun t => f (pick i,t))
    rw [rows]
    cases flag with
    | false => rfl
    | true => exact (congrArg List.sum (reverseFn row)).trans (List.sum_reverse _)

private theorem twice (ds : Axes) (k : Coord ds) : mirror ds (mirror ds k) = k := by
  induction ds with
  | nil => rfl
  | cons a ds ih =>
    obtain ⟨n, flag⟩ := a
    obtain ⟨i,t⟩ := k
    cases flag <;> simp [mirror, ih] <;> rfl

theorem verified : Case := by
  intro br lr b l R keepB keepL ds swapped x y
  funext batch i j
  have eq := sumMirror ds (fun k => times swapped
    (x (TensorRewrite.Pilot.Tensor.reverseIndex keepB batch)
       (TensorRewrite.Pilot.Tensor.reverseIndex keepL i) k) (y batch j (mirror ds k)))
  simpa only [twice] using eq
example : Case := verified
#print axioms verified
end RevisedBenchmark.DotMirror
