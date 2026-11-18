import Std
namespace RevisedBenchmark.ReshapeBroadcast

/-- A matched input broadcast dimension and its output reshape partner at
common-factor boundaries. The two prefix lists can have different lengths. -/
structure Match (oldShape newShape : List Nat) (width : Nat) where
  p q s t : List Nat
  oldSplit : oldShape = p ++ width :: s
  newSplit : newShape = q ++ width :: t
  prefix : p.prod = q.prod

def oldRead {m : Nat} {oldShape newShape : List Nat} {width : Fin m → Nat}
    (mapping : ∀ i, Match oldShape newShape (width i)) (flat : Fin newShape.prod)
    (data : (Fin m → Nat) → α) :=
  data (fun i => (flat.val / (mapping i).s.prod) % width i)

def newRead {m : Nat} {oldShape newShape : List Nat} {width : Fin m → Nat}
    (mapping : ∀ i, Match oldShape newShape (width i)) (flat : Fin newShape.prod)
    (data : (Fin m → Nat) → α) :=
  data (fun i => (flat.val / (mapping i).t.prod) % width i)

def Goal := ∀ (m : Nat) (before after : List Nat) (width : Fin m → Nat)
    (mapping : ∀ i, Match before after (width i)), before.prod = after.prod →
    ∀ (flat : Fin after.prod) (α : Type) (data : (Fin m → Nat) → α),
      oldRead mapping flat data = newRead mapping flat data
end RevisedBenchmark.ReshapeBroadcast
