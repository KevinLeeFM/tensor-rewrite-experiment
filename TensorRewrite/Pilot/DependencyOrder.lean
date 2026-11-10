module

public import Std

/-! Finite data/control dependency schedules. All nodes must appear once and
after their direct prerequisites. Effect traces project a schedule's labels. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.DependencyOrder

/-- Direct data/control prerequisites for every node of a finite computation. -/
structure Graph (nodes : Nat) where
  /-- Nodes that must execute before this node. -/
  predecessors : Fin nodes → List (Fin nodes)

/-- A complete dependency-respecting instruction order, matching native schedule checks. -/
def Graph.IsSchedule {nodes : Nat} (graph : Graph nodes) (order : List (Fin nodes)) : Prop :=
  order.length = nodes ∧ order.Nodup ∧ (∀ node, node ∈ order) ∧
    ∀ node predecessor, predecessor ∈ graph.predecessors node →
      order.idxOf predecessor < order.idxOf node

/-- The externally visible event labels in a chosen complete schedule. -/
def eventTrace {nodes : Nat} (labels : Fin nodes → Option String)
    (order : List (Fin nodes)) : List String := order.filterMap labels

/-- A label trace admitted by some complete prerequisite-respecting schedule. -/
def Graph.IsTrace {nodes : Nat} (graph : Graph nodes) (labels : Fin nodes → Option String)
    (trace : List String) : Prop :=
  ∃ order, graph.IsSchedule order ∧ eventTrace labels order = trace

end TensorRewrite.Pilot.DependencyOrder
