import ChunkSpec
set_option autoImplicit false
namespace RevisedBenchmark.ChunkHoist

private theorem expandVolume (ws : List Nat) (v : Nat) : volume (expand ws v) = ws.prod := by
  induction ws generalizing v with
  | nil => rfl
  | cons w ws ih => simp [expand,volume] at ih ⊢; rw [ih]

private theorem expandPack (ws : List Nat) {v : Nat} (hv : v < ws.prod) :
    pack (expand ws v) = v ∧ ∀ d ∈ expand ws v, d.2 < d.1 := by
  induction ws generalizing v with
  | nil => simp only [List.prod_nil] at hv; simp [expand,pack]; omega
  | cons w ws ih =>
    have less : v < w * ws.prod := hv
    have hp : 0 < ws.prod := by
      by_cases h : ws.prod = 0
      · simp [h] at less
      · omega
    obtain ⟨eq, bounds⟩ := ih (Nat.mod_lt v hp)
    constructor
    · simp only [expand,pack,expandVolume,eq]
      rw [Nat.mul_comm, Nat.div_add_mod]
    · intro d hd
      simp only [expand,List.mem_cons] at hd
      rcases hd with rfl | hd
      · exact (Nat.div_lt_iff_lt_mul hp).2 less
      · exact bounds d hd

private theorem volAppend (a b : List Digit) : volume (a++b) = volume a * volume b := by
  simp [volume,List.prod_append]

private theorem packAppend (a b : List Digit) : pack (a++b) = pack a * volume b + pack b := by
  induction a with
  | nil => simp [pack]
  | cons d a ih =>
    rcases d with ⟨w,v⟩
    simp only [List.cons_append,pack,volAppend,ih,Nat.add_mul,Nat.mul_assoc,Nat.add_assoc]

private def summarize (ds : List Digit) : Digit := (volume ds, pack ds)
private theorem volBlocks (bs : List (List Digit)) : volume bs.flatten = volume (bs.map summarize) := by
  induction bs with
  | nil => rfl
  | cons b bs ih => simp [volume,summarize,List.prod_append] at ih ⊢; rw [ih]

private theorem packBlocks (bs : List (List Digit)) : pack bs.flatten = pack (bs.map summarize) := by
  induction bs with
  | nil => rfl
  | cons b bs ih =>
    simp only [List.flatten_cons,List.map_cons,packAppend,volBlocks,ih,summarize,pack]

theorem verified : Goal := by
  intro m p blocks _ i
  have summary (u : Fin m) : summarize (expanded i u) = outDigit i u := by
    exact Prod.ext (expandVolume _ _) (expandPack _ (i u).isLt).1
  constructor
  · rw [packBlocks,List.map_ofFn]
    congr 1
    exact congrArg List.ofFn (funext summary)
  constructor
  · intro u
    exact (expandPack _ (i u).isLt).2
  · unfold original emitted
    rw [packBlocks,List.map_ofFn]
    congr 1
    apply congrArg List.ofFn
    funext k
    change summarize (expanded i (p.toOutput k)) = _
    rw [summary]
    exact Prod.ext (congrArg (fun j => (blocks j).prod) (p.leftInv k)) rfl
private theorem packBound (ds : List Digit) (bounds : ∀ d ∈ ds, d.2 < d.1) :
    pack ds < volume ds := by
  induction ds with
  | nil => decide
  | cons d ds ih =>
    rcases d with ⟨w,v⟩
    have hd : v < w := bounds _ (List.mem_cons_self ..)
    have ht := ih (fun x hx => bounds x (List.mem_cons_of_mem _ hx))
    calc
      pack ((w,v)::ds) = v * volume ds + pack ds := rfl
      _ < v * volume ds + volume ds := Nat.add_lt_add_left ht _
      _ = (v+1) * volume ds := (Nat.succ_mul ..).symm
      _ ≤ w * volume ds := Nat.mul_le_mul_right _ hd
      _ = volume ((w,v)::ds) := rfl

theorem inputBound {m : Nat} {p : Order m} {blocks : Fin m → List Nat} (i : Index p blocks) :
    emitted i < (List.ofFn fun k => (blocks k).prod).prod := by
  let ds : List Digit := List.ofFn fun k => ((blocks k).prod,(i (p.toOutput k)).val)
  have h := packBound ds (by
    intro d hd
    obtain ⟨k,rfl⟩ := List.mem_ofFn.mp hd
    simpa only [p.leftInv] using (i (p.toOutput k)).isLt)
  simpa only [emitted,ds,volume,List.map_ofFn,Function.comp_def] using h
private theorem digitShape (ws : List Nat) (v : Nat) : (expand ws v).map Prod.fst = ws := by
  induction ws generalizing v with
  | nil => rfl
  | cons w ws ih => simp [expand,ih]

private theorem unpackPack (ds : List Digit) (bounds : ∀ d ∈ ds, d.2 < d.1) :
    expand (ds.map Prod.fst) (pack ds) = ds := by
  induction ds with
  | nil => rfl
  | cons d ds ih =>
    rcases d with ⟨w,v⟩
    have ht := fun x hx => bounds x (List.mem_cons_of_mem _ hx)
    have hv := packBound ds ht
    have hp := Nat.zero_lt_of_lt hv
    have hq : (v * volume ds + pack ds) / volume ds = v := by
      rw [Nat.mul_comm v, Nat.mul_add_div hp, Nat.div_eq_of_lt hv, Nat.add_zero]
    have hr : (v * volume ds + pack ds) % volume ds = pack ds := by
      simp [Nat.add_mod, Nat.mod_eq_of_lt hv]
    change (w,(v * volume ds + pack ds) / volume ds) ::
      expand (ds.map Prod.fst) ((v * volume ds + pack ds) % volume ds) = _
    rw [hq,hr,ih ht]

/-- Independently decode the old outer reshape from the single packed output
position against the full transpose-output shape, before any inverse permutation. -/
theorem directReshape {m : Nat} (p : Order m) (blocks : Fin m → List Nat)
    (nonempty : ∀ k, blocks k ≠ []) (i : Index p blocks) :
    expand ((List.ofFn fun u => blocks (p.toInput u)).flatten) (pack (List.ofFn (outDigit i))) =
      (List.ofFn (expanded i)).flatten := by
  obtain ⟨oldFlat, legal, _⟩ := verified m p blocks nonempty i
  let ds := (List.ofFn (expanded i)).flatten
  have shape : ds.map Prod.fst = (List.ofFn fun u => blocks (p.toInput u)).flatten := by
    simp [ds,List.map_flatten,List.map_ofFn,Function.comp_def,expanded,digitShape]
  rw [←shape,←oldFlat]
  apply unpackPack
  intro d hd
  obtain ⟨group,hg,hit⟩ := List.mem_flatten.mp hd
  obtain ⟨u,rfl⟩ := List.mem_ofFn.mp hg
  exact legal u d hit
#print axioms directReshape
#print axioms inputBound
#print axioms verified
end RevisedBenchmark.ChunkHoist
