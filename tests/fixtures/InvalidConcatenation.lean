import TensorRewrite.Theory.ConcatenationCounterexamples

open TensorRewrite.Pilot TensorRewrite.Theory.Concatenation

example : emptyOtherFrame.shape (total emptyOtherBlocks) 0 = emptyOtherFrame.shape 2 0 := by decide

example : emptyOtherFrame.shape (total (filterEmpty emptyOtherBlocks)) 0 =
    emptyOtherFrame.shape (total emptyOtherBlocks) 0 := by decide

example : concatenate ([⟨1, Tensor.constant 7⟩, ⟨1, Tensor.constant 9⟩] : List (Block lineFrame Nat))
    (lineIndex (0 : Fin 2)) = concatenate [⟨1, Tensor.constant 9⟩, ⟨1, Tensor.constant 7⟩]
      (lineIndex (0 : Fin 2)) := by decide

example : let first : Block lineFrame Nat := ⟨2, Tensor.constant 7⟩
    let second : Block lineFrame Nat := ⟨2, Tensor.constant 9⟩
    lineFrame.slice (concatenate [first, second]) 0 2 (by decide) (lineIndex (0 : Fin 2)) =
      second.values (lineIndex (0 : Fin 2)) := by decide
