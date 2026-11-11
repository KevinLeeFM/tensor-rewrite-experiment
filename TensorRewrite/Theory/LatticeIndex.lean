module

public import TensorRewrite.Theory.Convolution

/-! Bounded occupied lattice positions, shared support for independent padding semantics. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.LatticeIndex

/-- Decode an occupied position without clipping negative positions or dilation holes. -/
def decode? (extent spacing : Nat) (positive : 0 < spacing) (position : Int) :
    Option (Fin extent) :=
  if valid : 0 ≤ position ∧ position % (spacing : Int) = 0 ∧
      position / (spacing : Int) < extent then
    some ⟨(position / (spacing : Int)).toNat, by
      have nonnegative : 0 ≤ position / (spacing : Int) :=
        Int.ediv_nonneg valid.1 (by omega)
      omega⟩
  else none

/-- A successful decoding is exactly a bounded occupied lattice point. -/
theorem decode_eq_some_iff (extent spacing : Nat) (positive : 0 < spacing)
    (position : Int) (index : Fin extent) :
    decode? extent spacing positive position = some index ↔
      position = (index.val : Int) * spacing := by
  constructor
  · intro sampled
    unfold decode? at sampled
    split at sampled
    next valid =>
      have values := congrArg Fin.val (Option.some.inj sampled)
      dsimp only at values
      have nonnegative : 0 ≤ position / (spacing : Int) :=
        Int.ediv_nonneg valid.1 (by omega)
      have cast := congrArg (fun value : Nat => (value : Int)) values
      rw [Int.toNat_of_nonneg nonnegative] at cast
      rw [← cast]
      simpa only [valid.2.1, add_zero] using (Int.ediv_mul_add_emod position (spacing : Int)).symm
    next invalid => contradiction
  · intro occupied
    subst position
    have nonzero : (spacing : Int) ≠ 0 := by omega
    have quotient : (index.val : Int) * spacing / spacing = index.val := by
      exact Int.mul_ediv_cancel _ nonzero
    have nonnegative : 0 ≤ (index.val : Int) * spacing :=
      Int.mul_nonneg (by omega) (by omega)
    simp [decode?, quotient, nonnegative, index.isLt]

/-- Existing window sampling has the same occupied-point meaning. -/
theorem window_eq_some_iff (axis : Convolution.Axis) (output : Nat)
    (kernel : Fin axis.kernelExtent) (index : Fin axis.inputExtent) :
    axis.inputIndex? output kernel = some index ↔
      axis.basePosition output kernel = (index.val : Int) * axis.baseDilation :=
  decode_eq_some_iff _ _ axis.baseDilation_pos _ _

/-- Assemble independent optional bounded coordinates, failing if any axis is absent. -/
def assemble? {rank : Nat} {shape : Pilot.Shape rank}
    (samples : (axis : Fin rank) → Option (Fin (shape axis))) : Option (Pilot.Index shape) :=
  if valid : ∀ axis, (samples axis).isSome then
    some fun axis => (samples axis).get (valid axis)
  else none

/-- Assembled coordinates are precisely the individually successful samples. -/
theorem assemble_eq_some_iff {rank : Nat} {shape : Pilot.Shape rank}
    (samples : (axis : Fin rank) → Option (Fin (shape axis))) (index : Pilot.Index shape) :
    assemble? samples = some index ↔ ∀ axis, samples axis = some (index axis) := by
  unfold assemble?
  split
  next valid =>
    rw [Option.some.injEq]
    constructor
    · intro same axis
      rw [← same]
      exact (Option.some_get (valid axis)).symm
    · intro same
      funext axis
      simp only [same]
      rfl
  next invalid =>
    constructor
    · intro impossible
      cases impossible
    · intro all
      exfalso
      apply invalid
      intro axis
      rw [all axis]
      rfl

/-- Independent axis sampling commutes with assembling and optional composition. -/
theorem assemble_bind {rank : Nat} {first second : Pilot.Shape rank}
    (outer : (axis : Fin rank) → Option (Fin (first axis)))
    (inner : (axis : Fin rank) → Fin (first axis) → Option (Fin (second axis))) :
    (assemble? outer).bind (fun index => assemble? (fun axis => inner axis (index axis))) =
      assemble? (fun axis => (outer axis).bind (inner axis)) := by
  classical
  apply Option.ext
  intro index
  rw [Option.bind_eq_some_iff, assemble_eq_some_iff]
  constructor
  · rintro ⟨middle, outerSome, innerSome⟩ axis
    apply Option.bind_eq_some_iff.mpr
    exact ⟨middle axis, (assemble_eq_some_iff _ _).mp outerSome axis,
      (assemble_eq_some_iff _ _).mp innerSome axis⟩
  · intro all
    have samples (axis : Fin rank) := Option.bind_eq_some_iff.mp (all axis)
    let middle : Pilot.Index first := fun axis => (samples axis).choose
    refine ⟨middle, ?_, ?_⟩
    · apply (assemble_eq_some_iff _ _).mpr
      intro axis
      exact (samples axis).choose_spec.1
    · apply (assemble_eq_some_iff _ _).mpr
      intro axis
      exact (samples axis).choose_spec.2

end TensorRewrite.Theory.LatticeIndex
