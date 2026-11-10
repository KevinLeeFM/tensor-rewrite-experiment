"""Inspected partial shape/indexing schemas; all remain pending independent review."""
import hashlib
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
S=ROOT/'sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc'

def main():
 source=S.read_text(); lines=source.splitlines()
 inventory=json.loads((ROOT/'census/source-sites.json').read_text())
 definitions={d['name']:d for d in inventory['definitions']}
 rows=[]
 def add(handler,name,lhs,rhs,guard,anchor,dependencies):
  d=definitions[handler]; body='\n'.join(lines[d['line']-1:d['end_line']])
  assert anchor in body, (handler,anchor)
  line=d['line']+body[:body.index(anchor)].count('\n')
  rows.append({'id':handler+'/'+name,'handler':handler,'line':d['line'],'end_line':d['end_line'],
   'branch_anchor':anchor,'anchor_line':line,'lhs':lhs,'rhs':rhs,'guard':guard,
   'path_condition':'earlier successful handler rewrites excluded; explicit branch nesting also applies',
   'dependencies':dependencies,'status':'source_extracted_pending_independent_review','proof':None,
   'source_body_sha256':hashlib.sha256(body.encode()).hexdigest()})
 add('HandleReshape','empty','Reshape(x,target)','empty constant with updated layout',
  'target IsZeroElementArray; establish default literal layout if absent',
  'ShapeUtil::IsZeroElementArray(reshape->shape())',['Literal::CreateFromShape','CreateConstantWithLayoutUpdated','ReplaceWithNewInstruction with relay_control_dependency=true'])
 add('HandleReshape','identity','Reshape(x,target)','x','SameShape(reshape,x)',
  'if (SameShape(reshape, operand))',['SameShape','ReplaceInstruction preserve_frontend_attributes=false'])
 add('HandleReshape','compose','Reshape(Reshape(x,s),t)','Reshape(x,t)','operand opcode Reshape',
  '// Merge reshapes.',['rank-polymorphic linearization','CreateReshape','ReplaceWithNewInstruction with relay_control_dependency=true'])
 add('HandleReshape','rng-shape','Reshape(Rng(...),target)','Rng(...) mutated to target shape',
  'operand opcode Rng; user_count == 1','operand->opcode() == HloOpcode::kRng',
  ['RNG distribution/state semantics','in-place shape mutation','ReplaceInstruction'])
 add('HandleReverse','trivial-dimensions','Reverse(x,dims)','x',
  'all reversed dimensions have extent 1 (includes empty dims list)',
  'if (absl::c_all_of(reverse->dimensions(), dim_is_one))',['ReplaceInstruction','reverse index map'])
 add('HandleReverse','cancel','Reverse(Reverse(x,a),b)','x',
  'layout insensitive; inner opcode Reverse; symmetric difference of axes empty',
  'if (sym_diff.empty())',['sorting dimensions in place','set operations','ReplaceInstruction'])
 add('HandleReverse','symmetric-difference','Reverse(Reverse(x,a),b)','Reverse(x,a symmetric_difference b)',
  'layout insensitive; inner opcode Reverse; symmetric difference nonempty',
  'new_dimensions = absl::MakeConstSpan(sym_diff)',['sorting dimensions in place','MakeReverseHlo','ReplaceInstruction'])
 for side in (0,1):
  add('HandleReverse',f'binary-scalar-{side}','Reverse(Binary(x,y),dims)',f'Binary with operand {1-side} reversed',
   f'layout insensitive; binary elementwise; not Compare/Fusion; no side effects; operand {side} is Broadcast(scalar) with empty broadcast dims',
   f'if (match_with_scalar(inner->mutable_operand({side})))',['CloneWithNewOperands','MakeReverseHlo','ReplaceWithNewInstruction'])
 add('HandleReverse','inserted-unit-dimensions','Reverse(Reshape(x),dims)','Reshape(Reverse(x,remapped_dims))',
  'layout insensitive; inner Reshape merely inserts/deletes 1-sized dims; deleted_dimensions empty',
  'reshape_degenerate.has_value()',['CountElementsLessThan','ReshapeMerelyInsertsOrDeletes1SizedDimensions','MakeReshapeHlo','MakeReverseHlo'])
 add('HandleSlice','identity','Slice(x,starts,limits,strides)','x',
  'ReplaceInstructionIfCompatible succeeds; legality plus equal output extents must justify identity',
  'if (ReplaceInstructionIfCompatible(slice, slice->mutable_operand(0)))',['SameShape','slice well-formedness','ReplaceInstructionIfCompatible'])
 add('HandleSlice','padding-only','Slice(Pad(x,v),starts,limits,strides)','Broadcast(v,output_shape)',
  'slice_in_padding becomes true if some limit <= low or start >= padded_extent-high',
  'if (slice_in_padding)',['loop/break path conditions','MakeBroadcastHlo','explicit output shape assignment','ReplaceInstruction'])
 add('HandleSlice','undo-pad','Slice(Pad(x,v),starts,limits,strides)','x',
  'not padding-only; every start == low and stride-1 == interior; compatibility replacement succeeds',
  'if (slice_undoes_pad &&',['padding bounds','ReplaceInstructionIfCompatible'])
 add('HandleSlice','inside-pad','Slice(Pad(x,v),starts,limits,strides)','Slice(x,starts-low,limits-low,strides)',
  'not padding-only; prior undo-pad did not succeed; every start >= low, limit <= padded_extent-high, interior == 0, stride == 1',
  'if (slice_inside_pad)',['MakeSliceHlo','explicit output shape assignment','ReplaceInstruction'])
 add('HandleTranspose','identity','Transpose(x,permutation)','x','permutation sorted; legal permutation therefore identity; earlier scatter folding failed',
  'if (std::is_sorted(transpose->dimensions().begin(),',['permutation validity','original-value recovery metadata','ReplaceInstruction'])
 add('HandleTranspose','compose','Transpose(Transpose(x,p),q)','Transpose(x,ComposePermutations(p,q))',
  'inner opcode Transpose; prior scatter folding and sorted-permutation cases did not rewrite',
  'if (HloOpcode::kTranspose == operand->opcode())',['ComposePermutations','CreateTranspose','ReplaceWithNewInstruction'])
 add('HandleReshape','copy-reorder','Reshape(Copy(x))','aligned Reshape/Bitcast(x), optionally followed by Copy',
  'layout sensitive; copy-before has one user; AlignLayouts succeeds; rewrite profitability and bitcast predicates pass; source memory is not host; new allocation estimate <= 10*old/9',
  '// Try to reorder copy-reshape to reshape-copy.',
  ['AlignLayouts','ReshapeIsBitcast','UpdateLayout','Shape::Equal IgnoreMemorySpaceInLayout','ArraySize overflow behavior','ReplaceInstruction'])
 add('HandleReshape','broadcast','Reshape(Broadcast(x,dims))','Broadcast(x,remapped_dims)',
  'operand opcode Broadcast; ReshapeLeavesDimensionsUnmodified returns remapped dimensions',
  'if (HloOpcode::kBroadcast == operand->opcode())',
  ['ReshapeLeavesDimensionsUnmodified','CreateBroadcast','ReplaceWithNewInstruction relay_control_dependency=true'])
 add('HandleReshape','iota-mixed-radix','Reshape(Iota(s,axis),t)','mixed-radix sum of output Iotas',
  'CommonFactors contains a nontrivial output boundary at iota axis and a boundary at iota axis+1; source loop bounds determine terms',
  'if (operand->opcode() == HloOpcode::kIota)',
  ['CommonFactors','CreateIota','finite-width multiplier and value arithmetic','MakeScalarLike','ReplaceInstruction'])
 add('HandleReshape','dynamic-update-unit-dims','Reshape(DynamicUpdateSlice(base,update,indices))','DynamicUpdateSlice(Reshape(base),Reshape(update),remapped_indices)',
  'layout insensitive; reshape merely inserts/deletes unit dimensions; DUS one user; DUS and its base unsharded; inserted indices zero; deleted indices omitted',
  'if (trivial_reshape.has_value() &&',
  ['ReshapeMerelyInsertsOrDeletes1SizedDimensions','MakeScalarLike index zero','CloneWithNewOperands','ReplaceWithNewInstruction relay_control_dependency=true'])
 add('HandleReshape','bitcast-chain','Reshape(copy/reshape chain)','Bitcast(selected ancestor)',
  'BitcastingOperandOfReshapeOrCopyChain returns a nonnull operand',
  'BitcastingOperandOfReshapeOrCopyChain(reshape)',
  ['BitcastingOperandOfReshapeOrCopyChain','ReplaceWithBitcast','layout and memory-space contracts'])
 # Delegated paths are recorded as unresolved families, not falsely expanded proofs.
 add('HandleReshape','transpose-chain-delegation','Reshape(transpose/reshape/bitcast chain)','helper-dependent replacement',
  'TryRemovingBitcastOrReshapeTransposeChain returns true',
  'TryRemovingBitcastOrReshapeTransposeChain(reshape)',
  ['TryRemovingBitcastOrReshapeTransposeChain: expand all internal branches'])
 add('HandleReshape','transpose-hoist-delegation','Reshape(transpose chain)','helper-dependent hoisted graph',
  'layout insensitive; enable_hoist_transpose_of_reshape; TryHoistTransposeOfReshape succeeds',
  'TryHoistTransposeOfReshape(reshape)',
  ['TryHoistTransposeOfReshape: expand all internal branches'])
 chain_guard = ('valid start; walk of permitted Reshape/Bitcast/Transpose nodes; '
  'reshape/bitcast nodes insert/delete unit axes with <=1 unit axis at each endpoint; '
  'bitcast nodes satisfy ReshapeIsBitcast; no inner identity transpose; '
  'at least one walked node; accumulated effective permutation identity')
 add('TryRemovingBitcastOrReshapeTransposeChain','layout-identity','transpose/reshape/bitcast chain','ancestor',
  chain_guard+'; layout sensitive; ShapeUtil::Equal(output,ancestor)',
  'if (ShapeUtil::Equal(instruction->shape(), new_operand->shape()))',
  ['effective permutation construction','ComposePermutations','ShapeUtil::Equal','ReplaceInstruction'])
 add('TryRemovingBitcastOrReshapeTransposeChain','layout-bitcast','transpose/reshape/bitcast chain','Bitcast(ancestor,output shape)',
  chain_guard+'; layout sensitive; output shape not equal; ReshapeIsBitcast(ancestor,output)',
  '} else if (ReshapeIsBitcast(new_operand->shape(),',
  ['byte-size/layout invariant','CreateBitcast','ReplaceWithNewInstruction'])
 add('TryRemovingBitcastOrReshapeTransposeChain','logical-identity','transpose/reshape/bitcast chain','ancestor',
  chain_guard+'; layout insensitive; shapes equal ignoring layout',
  'if (Shape::Equal().IgnoreLayout()(instruction->shape(),',
  ['Shape::Equal IgnoreLayout','ReplaceInstruction'])
 add('TryHoistTransposeOfReshape','contiguous-chunks','Reshape(Transpose(Reshape(x)))','Transpose(Reshape(x,new chunk sizes),new chunk permutation)',
  'input opcode sequence matches; FindContiguousChunks returns chunks; chunk sort and result_dim_idx determine mapping; caller supplies layout/option guards',
  'FindContiguousChunks(reshape, transpose)',
  ['FindContiguousChunks: expand its algorithm invariants','sorting and chunk products','UpdateLayout','ReplaceWithNewInstruction'])
 add('HandleSlice','exact-dynamic-update','Slice(DynamicUpdateSlice(base,update,i),s,l,strides)','update',
  'DUS operand_count == rank+2; all indices ConstantScalar with GetFirstInteger success; c=clamp(i,0,base_extent-update_extent); every s==c and l==c+update_extent; unstrided slice; compatibility replacement succeeds',
  'if (slice_matches_dus &&',['integer index extraction','dynamic-update index clamping','ReplaceInstructionIfCompatible'])
 add('HandleSlice','inside-dynamic-update','Slice(DynamicUpdateSlice(base,update,i),s,l,strides)','Slice(update,s-c,l-c,strides)',
  'same constant-index checks as exact-dynamic-update; every s>=c and l<=c+update_extent; layout insensitive OR output layout equals update layout',
  'if (slice_inside_dus &&',['dynamic-update clamping','MakeSliceHlo','explicit output shape assignment'])
 add('HandleSlice','compose-unstrided','Slice(Slice(x,a,b,1),s,l,1)','Slice(x,s+a,l+a,1)',
  'inner Slice opcode; both slices IsUnstridedSlice',
  'HloInstruction* operand_slice = slice->mutable_operand(0);',['slice bounds','signed int64 index additions','ReplaceWithNewInstruction'])
 add('HandleSlice','broadcast-only-dims','Slice(Broadcast(x,dims),s,l,strides)','Broadcast(x,dims,output shape)',
  'broadcast opcode; every mapped dim has start0, stride1, limit equal broadcast extent; other output dims may be sliced',
  'if (only_broadcast_dims_sliced())',['broadcast index map','slice output extent computation'])
 add('HandleSlice','broadcast-sink','Slice(Broadcast(x,dims),s,l,strides)','Broadcast(Slice(x,s[dims],l[dims],strides[dims]),dims)',
  'Slice/Broadcast match; earlier broadcast-only and scalar helper paths did not rewrite; new slice extent ceil((limit-start)/stride)',
  'VLOG(3) << "Sink broadcast through slice"',['mapped dimensions order','UpdateLayout','CreateSlice','MakeBroadcastHlo'])
 add('HandleSlice','dot-operands','Slice(Dot(lhs,rhs,dnums),s,l,strides)','Dot(selected slices of lhs/rhs,dnums)',
  'layout insensitive; raise_slice_and_reduce_through_dot; Dot operand; ConstructToDotMaps maps noncontracting/batch axes; only changed operands sliced; !DotHasOnlyBatchAndContractingOnOneOperand on new true dimension counts',
  '// Try to reorder slice of dot to the operand it comes from',['ConstructToDotMaps','DotHasOnlyBatchAndContractingOnOneOperand','MakeDotHlo precision_config and result type','dot reduction/numerical semantics'])
 add('HandleSlice','concat-exact-piece','Slice(Concat(xs,axis),s,l,1)','xs[selected]',
  'unstrided; cumulative extent loop finds start piece and exclusive limit piece; they identify one piece; SameShape(piece,output)',
  'SameShape(concat->operand(*start_operand), slice))',['prefix-sum loop invariant','zero-sized concat operands','SameShape'])
 for multi in (False,True):
  add('HandleSlice','concat-subrange-'+('multi' if multi else 'single'),'Slice(Concat(xs,axis),s,l,1)',
   'Slice('+('Concat(selected pieces,axis)' if multi else 'selected piece')+',s-concat_start,adjusted_l,1)',
   'unstrided; cumulative loop finds start and limit; selected count less than original operand count; selected count '+('>1' if multi else '==1')+'; adjusted axis limit = adjusted start + output extent',
   'if (start_operand && limit_operand &&\n        *limit_operand - *start_operand < concat->operand_count())',
   ['prefix sums and bounds','MakeConcatHlo when multiple pieces','layout copy and UpdateLayout','SetupDerivedInstruction'])
 add('HandleSlice','reduce-window','Slice(ReduceWindow(x,init,window,f),s,l,1)','Reshape(Reduce(x,init,effective_dims,f),output shape)',
  'enable_window_reduce_to_reduce_replacement; ReduceWindow one use; no stride/dilation; HasPadding; all axes have limit=rw_extent, low_padding=start, high_padding=0; each axis is size1 full unsliced OR output_extent1 and rw_extent==window_size and limit-start1; at least one latter axis',
  'if (!effective_reduce_dims.empty())',['window reversal and padding semantics','reduction computation effects, identities and reassociation','ShapeUtil::DeleteDimensions','UpdateLayout'])
 def delegate(owner,slug,target,anchor,guard):
  add(owner,slug,'caller graph','helper-dependent graph',guard,anchor,[target+': retain every success branch and caller contract'])
  rows[-1]['delegation_target']=target
 delegate('HandleSlice','scalar-slice-delegation','TrySimplifyScalarSlice','TrySimplifyScalarSlice(slice)','prior direct paths did not rewrite; helper status succeeds and replaced=true')
 delegate('HandleSlice','reshape-reorder-delegation','TryToReorderSliceAndReshape','TryToReorderSliceAndReshape(slice)','layout insensitive; previous scalar helper returned false; helper returns true')
 delegate('HandleSlice','reverse-reorder-delegation','TryToReorderSliceAndReverse','TryToReorderSliceAndReverse(slice)','Slice(Reverse) matcher; prior paths did not rewrite; helper returns true')
 delegate('HandleSlice','stride-delegation','RemoveRedundantStride','RemoveRedundantStride(slice)','prior paths did not rewrite; helper returns true')
 add('HandleTranspose','dot-canonical','Transpose(Dot(a,b),p)','Dot(b,a,swapped_contracting_dims,swapped_precision)',
  '!supports_non_canonical_dots; dot one user; swap-policy permits; lhs/rhs batch lists equal and permutation of iota; both have >=1 contracting dims and exactly one free dim; p identity except last two swapped',
  'DotDimensionNumbers new_dnums = dnums;',['IsPermutationOfIota','consider_swapping_dot_operands and IsParameterLike','SwapOperandsInDotPrecisionConfig','dot contraction/accumulation order'])
 add('HandleTranspose','dot-general','Transpose(Dot(a,b),p)','Dot(b,a,new_dnums,swapped_precision)',
  'supports_non_canonical_dots; dot one user; swap-policy permits; p maps leading batch positions only to batch positions; remaining positions exactly exchange rhs/lhs free-axis blocks; contracting lists exchanged and batch lists permuted through p',
  'DotDimensionNumbers new_dnums;',['MakeDotHlo .value and CHECK_OK failure paths','SwapOperandsInDotPrecisionConfig','layout assignment','SetupDerivedInstruction'])
 add('HandleTranspose','degenerate-reshape','Transpose(x,p)','Reshape(x,output shape)',
  'OnlyPermutesDegenerateDims(output shape,p): at least one output axis extent1; p entries at output axes with extent!=1 form sorted sequence',
  'if (OnlyPermutesDegenerateDims(transpose->shape(),',['OnlyPermutesDegenerateDims algorithm','permutation validity','row-major logical reshape'])
 add('HandleTranspose','rng-shape','Transpose(Rng(...),p)','Rng(...) mutated to output shape',
  'Rng opcode; one user',
  'if (operand->opcode() == HloOpcode::kRng && operand->user_count() == 1)',
  ['in-place shape assignment','RNG distribution versus fixed-sample observation','effect/state contract','ReplaceInstruction'])
 add('HandleTranspose','layout-bitcast','Transpose(x,p)','Bitcast(x,output shape)',
  'layout sensitive; TransposeIsBitcast(transpose)',
  'if (options_.is_layout_sensitive() && TransposeIsBitcast(transpose))',['TransposeIsBitcast','ReplaceWithBitcast','byte/layout/memory-space contract'])
 add('HandleTranspose','space-depth-user-mutation','Reshape(Transpose(Reshape(x)))','Reshape(Concat(Slice(x,chunk_i),concat_axis))',
  'layout insensitive; rewrite_reshape_transpose_as_slice_concatenate; inner Reshape; transpose one user which is Reshape; inner rank=input rank+1; exactly one split input axis into num_chunks*chunk_size; 0<=num_chunks<=5; permutation moves only small split axis to neither split position; output reshape axes match source scaling equations',
  '// Replace reshape of a transpose of a reshape with concatenated slicing',
  ['split-dimension search and product/division arithmetic','permutation offset loop','outer shape/rank assumptions','MakeSliceHlo and MakeConcatHlo','ReplaceOperandWithDifferentShape on outer reshape','MarkAsChanged'])
 rows[-1]['mutation_subject']='outer reshape operand0; transpose itself is not replaced at this site'
 delegate('HandleTranspose','scatter-fold-delegation','TryFoldTransposeIntoScatter','TryFoldTransposeIntoScatter(transpose)','first handler path; helper returns true')
 delegate('HandleTranspose','chain-delegation','TryRemovingBitcastOrReshapeTransposeChain','TryRemovingBitcastOrReshapeTransposeChain(transpose)','identity/composition and initial scatter fold did not rewrite; helper returns true')
 delegate('HandleTranspose','broadcast-delegation','SimplifyTransposeOfBroadcast','SimplifyTransposeOfBroadcast(transpose, transpose->dimensions())','all earlier direct/helper paths did not rewrite; helper may replace or return no change')
 for compatible in (True,False):
  add('TrySimplifyScalarSlice','concat-'+('piece' if compatible else 'slice'),'effective scalar Slice(Concat(xs),s,l,stride)',
   'selected concat operand' if compatible else 'Slice(selected operand,s-prefix,s-prefix+1,stride)',
   'effective scalar output; rank1; Concat operand; loop finds first prefix_end>slice_start; compatibility replacement '+('succeeds' if compatible else 'fails'),
   'bool replaced = ReplaceInstructionIfCompatible(' if compatible else 'Folding scalar slice of concat into slice of concat operand',
   ['effective scalar definition','prefix-sum loop and TF_RET_CHECK','ReplaceInstructionIfCompatible','source keeps original stride'])
 add('TryToReorderSliceAndReshape','leading-slice','Slice(Reshape(x),s,l,1)','Reshape(Slice(x,new_starts,new_limits,1),output shape)',
  'Slice opcode; unstrided; Reshape operand; only output dimension0 actually sliced; linear start and element count align to operand first-nonunit-axis suffix product; suffix product nonzero; reverse-axis decomposition passes divisibility/no-spill checks and ends offset0,count1; caller layout guard applies',
  'if (sliced_dims.size() == 1 && sliced_dims[0] == 0)',
  ['products and finite int64 overflow','all-unit/zero-dimension cases','Euclidean decomposition loop','ShapeUtil::ElementsIn','UpdateLayout'])
 add('TryToReorderSliceAndReverse','commute','Slice(Reverse(x,dims),s,l,stride)','Reverse(Slice(x,new_s,new_l,stride),dims)',
  'Slice(Reverse) matcher; each reversed axis computes last=s+((l-s-1)/stride)*stride, new_s=extent-last-1, new_l=extent-s; no explicit nonempty-slice guard',
  'if (Match(slice, m::Slice(m::Reverse())))',['C++ signed division truncates toward zero','empty slice output and bound legality','shape-preserving strided index arithmetic','UpdateLayout'])
 add('RemoveRedundantStride','single-element-axes','Slice(x,s,l,stride)','Slice(x,s,new_l,new_stride) with original output shape',
  'Slice opcode; selected axes have stride!=1 AND (stride>=limit OR start+stride>=limit); at least one selected axis; selected limit becomes start+1 and stride becomes1; no explicit start<limit guard',
  'if (index_to_change.empty())',['legal empty slice configurations','integer overflow in start+stride','declared versus inferred output shape','ReplaceWithNewInstruction'])
 add('TryFoldTransposeIntoScatter','simplified-scatter','Transpose(Scatter(base,indices,updates),p)','Scatter(Transpose(base,p),indices,Transpose(updates,[0]+(p+1)),new_dnums)',
  'enable_fold_transpose_into_scatter; Scatter one user; exactly one scatter operand; IsSimplifiedScatter; no input/index batching dims; WriteRunLength(scatter,p)>=WriteRunLength(scatter); new scatter_dims_to_operand_dims=inverse(p)[old_dims]',
  'const ScatterDimensionNumbers& old_dnums =',
  ['ScatterSimplifier::IsSimplifiedScatter','ScatterSimplifier::WriteRunLength','update rank/permutation construction','InversePermutation','indices_are_sorted and unique_indices retained','scatter reduction and collisions'])
 for layout in (False,True):
  add('SimplifyTransposeOfBroadcast','mapped-dims-'+('layout' if layout else 'logical'),'view(Broadcast(x,dims),p)','Broadcast(x,inverse(p)[dims],output shape)',
   'operand Broadcast; original dims sorted; mapped dims sorted; '+('layout sensitive; operand and extracted output layout sort permutations equal' if layout else 'layout insensitive')+'; caller justifies supplied p for transpose or bitcast',
   'auto inv_perm = InversePermutation(dimensions);',
   ['InversePermutation','caller-specific transpose/bitcast index relation','layout extraction and sort comparator','MakeBroadcastHlo'])
 out={'schema':1,'status':'partial_source_extraction','denominator_frozen':False,
      'source_sha256':inventory['source_sha256'],'cases':rows,
      'lexical_replacement_coverage_owners':sorted({c['handler'] for c in rows}),
      'residuals':['shape helper algorithm invariants and caller-to-helper semantic refinement',
                   'delegated helpers and datatype/layout case splitting','independent source and semantic review']}
 (ROOT/'census/shape-cases.json').write_text(json.dumps(out,indent=2)+'\n')
 print(f'Extracted {len(rows)} shape/indexing source schemas')
if __name__=='__main__':main()
