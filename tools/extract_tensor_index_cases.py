"""Inspected concat/broadcast/pad/gather/dynamic-index schemas; no proof acceptance."""
import hashlib
import json
from pathlib import Path
from extract_scalar_control_cases import validate_batch
from extract_arithmetic_cases import validate_helpers

ROOT=Path(__file__).resolve().parents[1]


def validate_index_effects(batch, source, structural):
    case=next(c for c in batch['cases'] if c['id']=='HandlePad/broadcast-projection')
    effects=case['effect_evidence']
    expected=['broadcast shape assignment','broadcast dimensions assignment','broadcast sharding clear','new pad config assignment']
    if [e['role'] for e in effects]!=expected:
        raise ValueError('pad projection effect omitted or reordered')
    for effect in effects:
        if not case['line']<=effect['line']<=case['end_line'] or effect['anchor'] not in source[effect['line']-1]:
            raise ValueError('pad effect source identity mismatch')
        if effect['role'].endswith('assignment') and not any(
            a['line']==effect['line'] and a['source']==effect['anchor'].removesuffix(';')
            for a in structural['assignment_expressions']):
            raise ValueError('pad graph assignment missing from syntax ledger')


def validate_loop_mutations(batch, structural):
    calls={(c['line'],c['call']):c for c in structural['calls']}
    for case in batch['cases']:
        if case.get('mutation_multiplicity')!='one outer write then one index write per axis':continue
        items=[case]+case['additional_replacement_sites']
        if len(items)!=2 or [i['replacement_call'] for i in items]!=['ReplaceOperandWithDifferentShape','ReplaceOperandWith']:
            raise ValueError('nested-index mutation group incomplete')
        first,last=[calls[(i['replacement_line'],i['replacement_call'])] for i in items]
        if any(c['kind']=='for_statement' for c in first['context']):
            raise ValueError('outer graph write incorrectly treated as per-axis')
        if not any(c['kind']=='for_statement' for c in last['context']):
            raise ValueError('per-axis graph write lost its loop context')


def main():
    inventory=json.loads((ROOT/'census/source-sites.json').read_text())
    structural=json.loads((ROOT/'census/normalized-structural-sites.json').read_text())
    source=(ROOT/'sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc').read_text().splitlines()
    definitions={d['name']:d for d in inventory['definitions']}
    cases=[]
    def add(owner,slug,ordinals,lhs,rhs,guard,deps,helpers=()):
        d=definitions[owner];body='\n'.join(source[d['line']-1:d['end_line']])
        row=dict(id=owner+'/'+slug,handler=owner,line=d['line'],end_line=d['end_line'],lhs=lhs,rhs=rhs,guard=guard,
                 source_body_sha256=hashlib.sha256(body.encode()).hexdigest(),
                 status='source_extracted_pending_independent_review',proof=None,
                 path_condition='legal HLO; earlier returning branches and current matcher bindings apply; failed compatibility attempts can still return from handler',
                 dependencies=deps,helper_contract_ids=list(helpers),
                 type_partition_status='datatype, dynamic shape, layout and index-width profiles not exhaustively split')
        if isinstance(ordinals,tuple):
            target,anchor=ordinals;assert anchor in body
            row.update(delegation_target=target,delegation_line=d['line']+body[:body.index(anchor)].count('\n'))
        else:
            if isinstance(ordinals,int):ordinals=[ordinals]
            sites=[s for s in inventory['sites'] if s['owner']==owner and s['kind']=='replacement']
            chosen=[sites[i] for i in ordinals]
            def identity(s):
                return dict(replacement_site_id=s['id'],replacement_line=s['line'],replacement_call=s['call'],replacement_source=source[s['line']-1])
            row.update(replacement_ordinals=ordinals,**identity(chosen[0]),additional_replacement_sites=[identity(s) for s in chosen[1:]])
        cases.append(row);return row

    row=add('HandleConcatenate','unary',0,'Concat(x)','x','one operand; compatibility succeeds', ['SameShape','return even if compatibility fails'])
    row['returns_even_if_compatibility_fails']=True
    for form in ('all-empty','one-nonempty','many-nonempty'):
        rhs={'all-empty':'original first operand','one-nonempty':'only nonempty operand','many-nonempty':'cloned Concat of nonempty operands'}[form]
        row=add('HandleConcatenate','filter-'+form,1,'Concat(xs)',rhs,
                'at least one operand zero-element; selected nonempty count '+{'all-empty':'0','one-nonempty':'1','many-nonempty':'>1'}[form]+'; compatibility succeeds',
                ['empty means zero total elements, not necessarily zero concat-axis extent','SameShape can reject all-empty shape differences','CloneWithNewOperands'])
        row['returns_even_if_compatibility_fails']=True
    layout_free='layout insensitive; '
    add('HandleConcatenate','flatten',2,'Concat(xs with nested Concat on same axis)','Concat(unnested operands)',
        layout_free+'unnested operand count differs from original count', ['source expands one level in operand order','concat extent sums and empty-operand early returns'])
    row=add('HandleConcatenate','adjacent-slices',3,'Concat(...,Slice(x),Slice(x),...)','Concat(...,merged Slice(x),...)',
            layout_free+'merge loop finds >=2 consecutive unstrided Slices sharing x; adjacent concat-axis limits/starts; other-axis starts equal; new operand count smaller; compatibility succeeds',
            ['nested scan and prefix bounds','legal equal nonconcat extents imply equal other limits','UpdateLayout','return even if compatibility fails'])
    row['returns_even_if_compatibility_fails']=True
    for low in (True,False):
        add('HandleConcatenate','pad-'+('low' if low else 'high'),4,'binary Concat of x and scalar Broadcast',
            'Pad(other operand,scalar,padding on concat axis '+('low' if low else 'high')+')',
            layout_free+'exactly two operands; '+('operand0 scalar Broadcast (takes priority even if both match)' if low else 'operand0 not scalar Broadcast; operand1 scalar Broadcast'),
            ['pad extent equals broadcast concat-axis extent','padding elsewhere zero','value and mixed output type semantics'])
    add('HandleConcatenate','repeat-unit-axis',5,'Concat(x,x,...,axis)','Broadcast(Reshape(x,delete axis),all other axes)',
        layout_free+'all operand pointers same; x extent on concat axis ==1', ['MakeReshapeHlo .value error boundary','dimension deletion and remapped broadcast','rank and count overflow'])

    add('HandleBroadcast','reshape',0,'Broadcast(x,dims)','Reshape(x,output shape)',
        'dims sorted; equal input/output element counts', ['legal broadcast indexing including zero extents','logical row-major reshape versus layout'])
    add('HandleBroadcast','transpose',1,'Broadcast(x,dims)','Transpose(x,InversePermutation(dims))',
        'input/output rank equal; element counts equal; prior sorted/count branch did not return', ['permutation validity from legal broadcast','inverse direction'])
    add('HandleBroadcast','inserted-unit-axes',2,'Broadcast(Reshape(x),dims)','Broadcast(x,dims with inserted reshape axes erased)',
        'ReshapeMerelyInsertsOrDeletes1SizedDimensions descriptor exists; deleted_dimensions empty; erase inserted dimensions in reversed order',
        ['dimension-list positions and index shifting','original-value recovery computation construction','shape and metadata preservation'])
    add('HandleBroadcast','sink-users-delegation',('TryToSinkBroadcastAfterElementwiseOps','TryToSinkBroadcastAfterElementwiseOps(broadcast)'),
        'Broadcast feeding elementwise users','helper-dependent smaller operations and broadcasts',
        'enable_sink_broadcast; helper returns true; handler MarkAsChanged then returns', ['caller option now explicit','helper can change several users'])
    for op in ('Reshape','Reverse','Transpose','Sort','Slice','DynamicSlice'):
        add('HandleBroadcast','scalar-user-'+op.lower(),3,op+'(Broadcast(scalar))','new Broadcast(scalar,MakeStaticShape(user output)) replacing all user uses',
            'operand scalar; user live; '+('OutputIsPermutationOfOperandElements true (Sort result must not Tuple)' if op in ('Reshape','Reverse','Transpose','Sort') else 'OutputIsSubsetOfOperandElements true: broadcast occurs once, at data operand0')+'; first qualifying user in loop',
            ['mutates uses of a user, not visited Broadcast','MakeStaticShape and runtime dynamic dimensions','MarkAsChanged before ReplaceAllUsesWith status'],
            ['OutputIsPermutationOfOperandElements'] if op in ('Reshape','Reverse','Transpose','Sort') else ['OutputIsSubsetOfOperandElements'])
    nonscalar='operand nonscalar: scalar branch returns even if it finds no user; '
    add('HandleBroadcast','iota',4,'Broadcast(Iota(axis),dims)','Iota(output shape,dims[axis])',nonscalar+'operand Iota', ['finite-width Iota values','dimension mapping'])
    add('HandleBroadcast','compose',5,'Broadcast(Broadcast(x,inner_dims),dims)','Broadcast(x,[dims[d] for d in inner_dims])',nonscalar+'operand Broadcast', ['arbitrary rank and non-sorted dimension maps'])
    add('HandleBroadcast','drop-unit-axes',6,'Broadcast(x,dims)','Broadcast(Reshape(x,drop unit axes),filtered dims)',
        nonscalar+layout_free+'enable_broadcast_degenerate_dimension; operand HasDegenerateDimensions', ['drop only extent1, not extent0','layout and dynamic-extent flags'])

    add('HandlePad','empty-input',0,'Pad(empty,value,config)','Broadcast(value,output shape)',
        'operand0 zero-element array', ['empty shape versus empty scalar index domain','padding/cropping output extents and mixed types'])
    add('HandlePad','unit-interior',1,'Pad(x,value,config)','Pad(x,value,config with selected interior padding zero)',
        'HasInteriorPadding; at least one axis has interior>0 and input extent1', ['one-element axes have no inter-element gaps','all other padding attributes preserved'])
    add('HandlePad','compatible',2,'Pad(x,value,config)','x','all edge padding low/high zero; compatibility succeeds (interior may remain in source predicate)',
        ['source all_zero tracks edges rather than all config fields','legal pad extents and SameShape justify actual no-op'])
    row=add('HandlePad','broadcast-projection',3,'Pad(Broadcast(x),value,config)','Broadcast(smaller Pad(mutated smaller Broadcast(x)),padded axes)',
            'padded/interior axis list strict subset of output axes; Broadcast one user; rank(x)<=padded axis count; every original broadcast target axis in padded list',
            ['delete all unpadded axes in descending order','in-place Broadcast shape/dimensions/sharding/layout changes','cloned smaller Pad config and layout','negative padding handled later only if this branch does not return'])
    anchors=[('*broadcast->mutable_shape() = broadcast_shape1;','broadcast shape assignment'),
             ('*broadcast->mutable_dimensions() = broadcast_dimensions;','broadcast dimensions assignment'),
             ('broadcast->clear_sharding();','broadcast sharding clear'),
             ('*pad2->mutable_padding_config() = pad_config;','new pad config assignment')]
    body='\n'.join(source[row['line']-1:row['end_line']])
    row['effect_evidence']=[dict(anchor=a,line=row['line']+body[:body.index(a)].count('\n'),role=r) for a,r in anchors]
    add('HandlePad','negative-edges',4,'Pad(x,value,negative config)','Slice(Pad(x,value,nonnegative-edge config),crop starts/ends,stride1)',
        'some edge negative; enable_negative_padding_replacement; final shape check succeeds, ignoring tiles only when layout insensitive',
        ['MakePadHlo then restore original output element type','copy layout to new pad and slice','negating int64 minimum and extent arithmetic','status/error and TF_RET_CHECK boundaries'])

    sync='not in async computation; '
    add('HandleDynamicSlice','scalar',0,'DynamicSlice(scalar,indices)','operand',sync+'result shape scalar', ['rank-zero legality'])
    add('HandleDynamicSlice','same-shape',1,'DynamicSlice(x,indices)','x',sync+'SameShape(x,result)', ['index clamping to zero on full extents','layout-sensitive equality'])
    add('HandleDynamicSlice','zero-full-axis-indices',2,'DynamicSlice(x,indices)','cloned DynamicSlice with full-axis indices zero',
        sync+'at least one axis has input extent==result extent and index not (Constant AND IsAll(0))',
        ['mutable_operands returns InstructionVector by value: temporary edits do not alias original graph','zero type uses first index operand','CloneWithNewOperands'])
    for scalar in (True,False):
        add('HandleDynamicSlice','broadcast-'+('scalar' if scalar else 'array'),3,'DynamicSlice(Broadcast(x,dims),indices,sizes)',
            'Broadcast('+('x' if scalar else 'DynamicSlice(x,selected indices,selected sizes)')+',dims,output shape)',
            sync+'Broadcast operand; broadcast input rank '+('0' if scalar else '>0'), ['preserve broadcast dims order','clamp equality on mapped axes','UpdateLayout for new slice'])
    add('HandleDynamicSlice','unit-reshape',4,'DynamicSlice(Reshape(x),indices,sizes)','Reshape(DynamicSlice(x,remapped indices/sizes),output shape)',
        sync+layout_free+'Reshape only inserts/deletes unit axes', ['DimensionsUnmodifiedByReshape','new input-axis slice sizes default to1; no inserted-output-axis slice-size1 check','zero copied from first index type'])
    add('HandleDynamicSlice','transpose',5,'DynamicSlice(Transpose(x,p),indices,sizes)','Transpose(DynamicSlice(x,inverse-permuted indices/sizes),p)',
        sync+layout_free+'Transpose operand', ['InversePermutation','Permute overloads and clamping equivariance','PermuteDimensions output shape'])
    add('HandleDynamicSlice','constant-indices',6,'DynamicSlice(nonconstant x,constant indices)','Slice(x,clamped starts,starts+sizes,1)',
        sync+'conversion not disabled; all offsets Constant integral; layout insensitive OR both layouts and equal memory spaces; every GetFirstInteger succeeds and is >=0',
        ['source rejects negative constants even though runtime slice clamps them','min(input-output extent,offset)','memory-space legality and finite integer sums'])
    for multiplied in (False,True):
        for conversion in (False,True):
            add('HandleDynamicSlice','iota-'+('scaled' if multiplied else 'plain')+'-'+('convert' if conversion else 'same-type'),7,
                'size1 DynamicSlice(' + ('Multiply(Iota,Broadcast(scalar))' if multiplied else 'Iota') + ',index)',
                'Reshape('+('Multiply(' if multiplied else '')+('Convert(' if conversion else '')+'Clamp(0,index,min(iota_size-1,index_type_max))'+(')' if conversion else '')+(',scalar)' if multiplied else '')+')',
                sync+'input/result rank1; result extent1; element and index types S32/U32; type difference '+str(conversion)+'; '+
                ('Multiply with Broadcast scalar at operand1 (no constant requirement)' if multiplied else 'direct Iota; multiplier matcher null'),
                ['Clamp in index type then optional conversion to result type','finite-width Iota and multiplication','scalar multiplier may be runtime value','iota extent legality'])
    row=add('HandleDynamicSlice','nested', [8,9], 'DynamicSlice(DynamicSlice(x,inner),outer)',
            'mutated DynamicSlice(x,Clamp(outer,0,inner_size-outer_size)+ConvertIfNeeded(Clamp(inner,0,input_size-inner_size)))',
            sync+'original data operand DynamicSlice (direct-nested partition); every input-inner extent difference fits inner index type and input-outer difference fits outer index type',
            ['replace data operand first, then each index in loop','clamped inner cast and sum representability','MarkAsChanged after all per-index writes'])
    row['mutation_multiplicity']='one outer write then one index write per axis'
    row['source_path_partition']='direct_original_data_operand'
    row=add('HandleDynamicSlice','nested-after-scaled-probe',[8,9],
            'DynamicSlice(Multiply(DynamicSlice(x,inner),Broadcast(scalar)),outer)',
            'mutated DynamicSlice(x,Clamp(outer,0,inner_size-outer_size)+ConvertIfNeeded(Clamp(inner,0,input_size-inner_size))); multiplication discarded',
            sync+'all prior returning branches fall through; input/result rank1; result extent1; result type S32/U32; Multiply operand1 Broadcast has empty dimensions and scalar operand; stripped operand0 DynamicSlice; every source fit check succeeds',
            ['failed Iota probe leaves local operand rebound to Multiply operand0',
             'current local binding differs from original data operand graph',
             'runtime scalar multiplier is not required to be Constant',
             'direct-nested logical composition theorem does not cover the dropped multiplication',
             'earlier constant-index conversion/shape/layout paths must fall through',
             'replace data operand before each index update; partial status/frame outcomes'])
    row['mutation_multiplicity']='one outer write then one index write per axis'
    row['source_path_partition']='failed_scaled_iota_probe_local_binding'
    row['source_path_predecessor']='failed Iota test after local operand assignment; not a direct-nested original graph'
    row['discarded_original_operation']='Multiply with broadcast runtime scalar'
    body='\n'.join(source[row['line']-1:row['end_line']])
    offset=body.index('HloInstruction* multiplier = match_multiply_with_scalar(operand);')
    anchors=['operand = operand->mutable_operand(0);',
             'if (operand->opcode() == HloOpcode::kIota)',
             'if (operand->opcode() == HloOpcode::kDynamicSlice)']
    row['local_binding_evidence']=[dict(anchor=a,line=row['line']+body[:body.index(a,offset)].count('\n')) for a in anchors]


    for encoding in ('scalar-list','tuple','concatenate'):
        add('HandleDynamicUpdateSlice','pad-'+encoding,0,'DynamicUpdateSlice(Broadcast(scalar),update,constant indices)','Pad(update,scalar,clamped low/high edges)',
            sync+'enable_dynamic_update_slice_to_pad_replacement; scalar Broadcast base; indices encoded as '+encoding+'; source compatibility logic accepts encoding; all axis starts ConstantScalar with GetFirstInteger; no MoveToHost custom call through reshape/bitcast/copy chain around update',
            ['legacy encoding reachability under legal HLO needs review','host offloading pattern excludes a later memory-space transfer','clamp each start to [0,base_extent-update_extent]','interior padding0'])
    add('HandleDynamicUpdateSlice','full-update',1,'DynamicUpdateSlice(base,update,i)','update',sync+'SameShape(result,update)', ['clamping and complete overwrite','layout and metadata equality'])
    for low in (False,True):
        add('HandleDynamicUpdateSlice','pad-concat-'+('low' if low else 'high'),2,'DynamicUpdateSlice(Pad(x),update,constant indices)',
            'Concat('+('update,x' if low else 'x,update')+',padded axis)',
            sync+'operand_count==rank+2; no interior/negative padding; exactly one axis has padding only '+('low>0' if low else 'high>0')+'; x extent there>0; update extent equals padded width and clamped start is '+('0' if low else 'x extent')+'; other axes update=x extents and clamped start0; layout insensitive OR all three layouts equal',
            ['constant-index extraction per axis','input/update ranks','MakeConcatHlo and explicit result shape assignment'])
    add('HandleDynamicUpdateSlice','zero-full-axis-indices',3,'DynamicUpdateSlice(base,update,indices)','cloned DUS with full-axis indices zero',
        sync+'at least one update extent equals output extent and index not (Constant AND IsAll(0))',
        ['mutable_operands returns copied InstructionVector','zero type from first index operand','CloneWithNewOperands'])
    add('HandleDynamicUpdateSlice','empty-update',4,'DynamicUpdateSlice(base,empty,i)','base',sync+'update zero-element array', ['index clamping/no out-of-bounds warning observation','effects of otherwise unused index computations'])
    row=add('HandleDynamicUpdateSlice','nested',[5,6], 'DUS(a,DUS(DS(a,id),c,inner),id)',
            'mutated DUS(a,c,Clamp(id,0,base-inner_size)+ConvertIfNeeded(Clamp(inner,0,inner_size-update_size)))',
            sync+'inner update base is DynamicSlice of same a; outer indices pointer-equal to that slice indices; every inner-update extent difference fits inner index type and base-update difference fits outer index type',
            ['replace update operand first then each index in loop','cast and sum bounds','source depends on saved inner DUS pointer after outer mutation','MarkAsChanged after all writes'])
    row['mutation_multiplicity']='one outer write then one index write per axis'

    add('HandleGather','empty-input',0,'Gather(empty,indices)','MakeScalarLike(gather,0)',
        'operand zero-element array', ['legal Gather slice sizes and result shape','empty tensor legality versus elementwise vacuity'])
    for rank_zero in (True,False):
        add('HandleGather','effective-scalar-'+('rank-zero' if rank_zero else 'unit-array'),1,'Gather(effective scalar x,indices)',
            'Broadcast('+('x' if rank_zero else 'Reshape(x,scalar)')+',output shape)',
            'operand IsEffectiveScalar; operand rank '+('0' if rank_zero else '>0'),
            ['MakeReshapeHlo status when needed','Gather clamping and unit/empty dimension cases','MakeBroadcastHlo'])
    add('HandleGather','small-select-chain',2,'Gather(rank1 operand,indices)','typed Select chain: start get_value(0); for every i choose get_value(i) when index >= MakeScalarLike(index,i) in the actual index comparison type',
        'operand rank1 and extent<=very_small_gather_size option; index_vector_dim==index rank; collapsed_slice_dims count1; prior effective-scalar/empty paths did not return',
        ['initial get_value(0); loop i from0 through operand_elements-1','each get_value uses Slice/Reshape/Broadcast','index comparison mode and clamping semantics','MakeScalarLike index literal i has no local representability guard'])
    for batch_padding in (False,True):
        add('HandleGather','pad-hoist-'+('batching' if batch_padding else 'passthrough'),3,'Gather(Pad(x,value),indices)',
            'Pad(Gather(x,'+('unpadded indices' if batch_padding else 'indices')+',adjusted slice sizes),value,remapped padding)',
            'GetGatherOperandPassthroughDims maps input/result axes; CheckPaddedDimsForGatherOfPad.should_transform; has_padded_batching_dims='+str(batch_padding),
            ['pass-through and explicit-batching dimension maps','identical padding configs on paired input/index batching axes','indices pad must contain only required batching pads','result shape and slice-size updates','indices_are_sorted flag preserved'],
            ['GetPaddedDims','CheckPaddedDimsForGatherOfPad'])
    add('HandleGather','reshape-pad-hoist',4,'Gather(Reshape(Pad(x,value)),indices)',
        'Pad(Gather(Reshape(x,unpadded shape),indices,adjusted sizes),value,remapped padding)',
        'operand Reshape; ShapeUtil::ReshapeIsBitcast(padded input,reshape output); inner Pad; every padded axis unmodified by reshape and its mapped reshape axis is Gather operand-passthrough',
        ['DimensionsUnmodifiedByReshape map and default-inserting lookups before final flags','preserve padding low/high/interior through two axis maps','adjust reshape/gather extents and gather slice sizes','external sharding utility passthrough contract'],['GetPaddedDims'])

    summaries={
        'OutputIsPermutationOfOperandElements':'operand present precondition; Reshape/Reverse/Transpose true; Sort true only when output not Tuple; other opcodes false',
        'OutputIsSubsetOfOperandElements':'operand must occur exactly once; Slice requires operand0; DynamicSlice requires data operand0; other opcodes false',
        'GetPaddedDims':'enumerate axes with any nonzero edge or interior padding; includes negative edges',
        'CheckPaddedDimsForGatherOfPad':'each padded operand axis must be passthrough or explicit batching; batching requires identical paired index padding and no extra index-padded axes; extend both in/out maps for batching dimensions'}
    unit_reshape=next(case for case in cases if case['id']=='HandleDynamicSlice/unit-reshape')
    unit_reshape['checks_inserted_axis_slice_size_one']=False
    unit_reshape['empty_inserted_axis_profile']='x[2] -> reshape[1,2] -> dynamic-slice[0,1]; new slice[1] fails reshape element-count CHECK; verifier-accepted zero extents versus positive-size XLA prose remains explicit'
    gather_select=next(case for case in cases if case['id']=='HandleGather/small-select-chain')
    gather_select['checks_literal_representability']=False
    gather_select['literal_safe_condition']='every position in range(operand_extent) is represented exactly in the signed/unsigned index comparison type'
    gather_select['literal_boundary_profile']='signed8 extent129 threshold129 narrows position128 to -128; default threshold4 and wider-index profiles differ'

    helpers=[]
    for name,summary in summaries.items():
        matches=[f for f in structural['functions'] if name+'(' in f['declarator']];assert len(matches)==1,name
        f=matches[0];body='\n'.join(source[f['line']-1:f['end_line']])
        helpers.append(dict(id=name,line=f['line'],end_line=f['end_line'],source_body_sha256=hashlib.sha256(body.encode()).hexdigest(),
                            source_behavior=summary,status='source_inspected_pending_independent_semantic_review'))
    output=dict(schema=1,status='partial_source_extraction',source_sha256=inventory['source_sha256'],denominator_frozen=False,
                selected_handlers=sorted({c['handler'] for c in cases}),cases=cases,helper_contracts=helpers,
                limitations=['inspected branch schemas not a disjoint/frozen obligation count','dynamic shape/index types, widths and layouts not exhaustively split',
                             'loop multiplicity and graph effects remain semantic obligations','helper/source review is not independent and no whole-source proof accepted'])
    validate_batch(output,inventory,source);validate_helpers(output,source);validate_loop_mutations(output,structural)
    validate_index_effects(output,source,structural)
    (ROOT/'census/tensor-index-cases.json').write_text(json.dumps(output,indent=2)+'\n')
    print(f'Extracted {len(cases)} tensor-index schemas across {len(output["selected_handlers"])} handlers')


if __name__=='__main__':main()
