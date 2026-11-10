"""Source reduction schemas; algebraic and window contracts remain unproved."""
import hashlib
import json
from pathlib import Path
from extract_scalar_control_cases import validate_batch
from extract_arithmetic_cases import validate_helpers
from reconcile_sites import noncall_declarations

ROOT=Path(__file__).resolve().parents[1]


def validate_reduction_batch(batch, inventory, source, structural):
    excluded=[s['id'] for s in noncall_declarations(inventory,structural) if s['owner'] in batch['selected_handlers']]
    if batch['noncall_declaration_site_ids']!=excluded:
        raise ValueError('unjustified reduction declaration exclusion')
    validate_batch(batch,inventory,source,excluded)
    validate_helpers(batch,source)
    calls={(c['line'],c['call']):c for c in structural['calls']}
    for case in batch['cases']:
        if case.get('construction_kind')=='embedded_reducer_clone':
            items=[case]+case['additional_replacement_sites']
            if [i['replacement_call'] for i in items]!=['CloneWithReplacements','ReplaceWithNewInstruction']:
                raise ValueError('reducer construction/replacement group incomplete')
            if [r['role'] for r in case['site_roles']]!=['embedded_computation_construction','graph_replacement']:
                raise ValueError('reducer clone misclassified as graph replacement')
        if case['id'].startswith(('HandleReduceWindow/empty-','HandleReduceWindow/scalar-')):
            anchor='replace_with_span(broadcast_inits)' if '/empty-' in case['id'] else 'replace_with_span(maps)'
            if case.get('lambda_invocation_anchor')!=anchor:
                raise ValueError('lambda caller guard path missing')
            body='\n'.join(source[case['line']-1:case['end_line']])
            if anchor not in body:
                raise ValueError('lambda caller source identity mismatch')
            call=calls[(case['replacement_line'],case['replacement_call'])]
            if not any(c['kind']=='lambda_expression' for c in call['context']):
                raise ValueError('local replacement lambda context missing')


def main():
    inventory=json.loads((ROOT/'census/source-sites.json').read_text())
    structural=json.loads((ROOT/'census/normalized-structural-sites.json').read_text())
    source=(ROOT/'sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc').read_text().splitlines()
    definitions={d['name']:d for d in inventory['definitions']}
    cases=[]
    def add(owner,slug,ordinals,lhs,rhs,guard,deps,helpers=(),clone=False):
        d=definitions[owner];body='\n'.join(source[d['line']-1:d['end_line']])
        row=dict(id=owner+'/'+slug,handler=owner,line=d['line'],end_line=d['end_line'],lhs=lhs,rhs=rhs,guard=guard,
                 source_body_sha256=hashlib.sha256(body.encode()).hexdigest(),
                 status='source_extracted_pending_independent_review',proof=None,
                 path_condition='legal XLA Reduce/ReduceWindow semantics plus source-order earlier returns and caller guards; helper/body cases overlap',
                 semantic_contract_status='documented identity and reassociation premises need precise domain/observation models; not new local source guards',
                 dependencies=deps,helper_contract_ids=list(helpers),
                 type_partition_status='tuple coupling, scalar type, numerical relation, dynamic shape and layout profiles not fully split')
        if isinstance(ordinals,tuple):
            target,anchor=ordinals;assert anchor in body
            row.update(delegation_target=target,delegation_line=d['line']+body[:body.index(anchor)].count('\n'))
        else:
            if isinstance(ordinals,int):ordinals=[ordinals]
            owned=[s for s in inventory['sites'] if s['owner']==owner and s['kind']=='replacement']
            chosen=[owned[i] for i in ordinals]
            def identity(s):return dict(replacement_site_id=s['id'],replacement_line=s['line'],replacement_call=s['call'],replacement_source=source[s['line']-1])
            row.update(replacement_ordinals=ordinals,**identity(chosen[0]),additional_replacement_sites=[identity(s) for s in chosen[1:]])
            if clone:
                row.update(construction_kind='embedded_reducer_clone',
                           site_roles=[dict(site_id=s['id'],role=r) for s,r in zip(chosen,['embedded_computation_construction','graph_replacement'])],
                           acceptance_unit='construct cloned embedded reducer then replace outer result; construction is not another rewrite')
        cases.append(row);return row

    add('HandleReduce','empty-delegation',('BroadcastReduce','return BroadcastReduce('),'Reduce(empty input or empty result,init)','Broadcast(init) or Tuple of broadcasts',
        'ShouldBroadcastReduce(representative input,result shape)', ['shared first shape represents all tuple components','empty result legality'],['ShouldBroadcastReduce'])
    add('HandleReduce','singleton-tuple',[0,1],'one-output variadic Reduce','Tuple(single-output Reduce with cloned untupled reducer)',
        'tuple result of size1; input_count1; reducer root Tuple', ['CloneWithReplacements removes old root','AddEmbeddedComputation mutates module','preserve dimensions and init'],clone=True)
    add('HandleReduce','same-element-count',2,'Reduce(arg,init,f)','helper Reshape(arg) or Tuple of reshapes',
        'input/result element counts equal; layout insensitive OR virtual ReshapeIsBitcast(input,result)',
        ['init identity is a documented semantic premise, not checked by this branch','reducer tuple coupling and trivial dimensions','helper call is itself a lexical replacement candidate'])
    free='layout insensitive; '
    single=free+'non-tuple reduce after earlier multi-output return; '
    add('HandleReduce','negate-sum',[3,4],'Reduce(Negate(x),0,Add)','Negate(mutated Reduce(x,0,Add)) for saved old users',
        free+'floating reduce shape; input Negate; IsScalarConstantZero(init); reducer AddAnyOrder(Parameter0,Parameter1)',
        ['snapshot users before adding Negate(reduce) to avoid self-cycle','operand write then ReplaceUsesWith saved users','signed zero and permissible rounding','MarkAsChanged before final status'])
    for maximum in (False,True):
        add('HandleReduce','arg'+('max' if maximum else 'min')+'-constant',5,'ArgMin/Max Reduce(Broadcast(Constant scalar),Iota)',
            'Tuple(Broadcast(value),Broadcast(index zero))',
            free+('MatchArgMax' if maximum else 'MatchArgMin')+'; data Broadcast(Constant scalar); reduction dimensions include Iota axis',
            ['exact reducer select/compare pattern','NaNs, extrema, ties and index wrapping','coupled identity/range contract'],['MatchArgMax' if maximum else 'MatchArgMin','MatchArgMinMax','IsScalarConstantNegInf' if maximum else 'IsScalarConstantInf'])
    row=add('HandleReduce','dot-reorder-delegation',('ReorderReduceDotToDotReduce','ReorderReduceDotToDotReduce(arg, init_value, function, reduce)'),
            'Reduce(Dot(...))','helper-dependent reordered graph',free+'helper optional<Status> engaged',
            ['caller tests optional engagement and returns OkStatus without propagating contained Status','helper can construct nodes even when cost guard later fails'])
    row['optional_status_handling']='engagement tested; contained status not propagated by caller'
    trans_guard=single+'input Transpose; unconditional option OR result rank<2 OR transpose one user OR all its users Reduce; '
    for sorted_dims in (True,False):
        add('HandleReduce','transpose-'+('sorted' if sorted_dims else 'permute-result'),6 if sorted_dims else 7,
            'Reduce(Transpose(x,p),dims)','Reduce(x,p[dims])'+('' if sorted_dims else ' followed by remapped output Transpose'),
            trans_guard+'surviving input-axis sequence sorted='+str(sorted_dims), ['DeleteDimensions','rank-polymorphic output axis renumbering','allowed reduction order'])
    add('HandleReduce','merge-delegation',('MergeReduces','return MergeReduces('),'Reduce(Reduce(x,f,init),f,init)','one combined Reduce',
        single+'input Reduce; init Identical to inner operand1; ReductionComputationsEquivalent', ['outer to inner dimension lifting','identity and allowed association'],['ReductionComputationsEquivalent'])
    add('HandleReduce','reshape-reduced-axes',8,'Reduce(Reshape(x),dims)','Reduce(x,all axes except mapped preserved output axes)',
        single+'enable_reduce_of_reshape; input Reshape; every surviving output axis unmodified by reshape', ['DimensionsUnmodifiedByReshape','set membership and output rank','MarkAsChanged'])
    add('HandleReduce','reshape-output-axes',9,'Reduce(Reshape(x),dims)','Reshape(Reduce(x,mapped dims),output shape)',
        single+'enable_reduce_of_reshape; input Reshape; earlier reshape case did not return; reshape one user OR unconditional option; every reduced axis unmodified',
        ['dimension pair lookup CHECK','MakeReduceHlo copies reduce metadata','MakeReshapeHlo'])
    add('HandleReduce','concat',10,'Reduce(Concat(xs,axis),dims)','left-associated Map(f) chain of per-operand Reduce results',
        single+'concat axis reduced; unconditional concat option OR all concat operand shapes equal ignoring layout OR scalar reduce output',
        ['one init per partial reduce; documented identity needed','nonempty concat and loop accumulator','association and element order versus approximate profile'])
    dot_guard=single+'supports_non_canonical_dots; enable_dot_strength_reduction; input Dot one user; Add reducer; some reduced dimensions are dot batch axes; '
    for remaining in (False,True):
        add('HandleReduce','dot-batch-'+('residual-reduce' if remaining else 'all-batch'),12 if remaining else 11,'Reduce(Dot(lhs,rhs),dims)',
            'Dot with reduced batch pairs made contracting'+(' followed by Reduce on other renumbered axes' if remaining else ''),
            dot_guard+'remaining nonbatch reduce dimensions '+('nonempty' if remaining else 'empty'),
            ['init identity not separately checked as zero here','precision_config/result element type retained','SetupDerivedInstruction','batch/free/contracting axis ordering'])
    for maximum in (True,False):
        add('HandleReduce','reuse-arg'+('max' if maximum else 'min'),13 if maximum else 14,'Reduce'+('Max' if maximum else 'Min')+'(arg)',
            'GetTupleElement(existing ArgMax/ArgMin of same arg,0)',
            single+'operand_count2; '+('IsScalarConstantNegInf' if maximum else 'IsScalarConstantInf')+'(init); matching binary reducer; another user of same arg matches corresponding ArgMin/Max with identical reduction dimensions',
            ['shared-user search','extreme matcher includes native lowest/max for types without infinity','arg reducer NaN/tie behavior versus scalar min/max'],['MatchArgMax' if maximum else 'MatchArgMin','MatchArgMinMax','IsScalarConstantNegInf' if maximum else 'IsScalarConstantInf'])
    for op in ('Maximum','Minimum','And','Or'):
        add('HandleReduce','scalar-broadcast-'+op.lower(),15,'Reduce(Broadcast(x),init,'+op+')',op+'(x,init)',
            single+'x scalar; all input axes reduced; exact '+op+'AnyOrder(Parameter0,Parameter1) reducer', ['idempotence under selected observation','actual opcode and operand order','empty input handled first'])
    add('HandleReduce','broadcast-base-axes',16,'Reduce(Broadcast(x,bcast_dims),dims)','Broadcast(Reduce(x,mapped dims),renumbered surviving axes)',
        single+'all reduced axes occur in broadcast dimension map', ['inverse lookup positions','remaining output dimension shifts','init and dynamic-shape semantics'])
    add('HandleReduce','broadcast-replicated-axes',17,'Reduce(Broadcast(x),init,Add)','Broadcast(Add(Broadcast(init),Multiply(x,repetition count)),new dims)',
        single+'Add reducer; TF_RET_CHECK broadcast dims sorted; every reduced axis introduced by Broadcast',
        ['int64 repetition product and conversion to element type','repeated addition versus multiplication','independent numerical error relation','retained and removed axis map'])

    for tuple_result in (True,False):
        add('BroadcastReduce','tuple' if tuple_result else 'single',0 if tuple_result else 1,'empty Reduce inputs/result',
            'Tuple of Broadcast(init_i)' if tuple_result else 'Broadcast(init0)',
            'caller ShouldBroadcastReduce and multi_output_reduce='+str(tuple_result), ['all tuple components represented by first shape','component types, shapes and init values'])
        add('ReplaceReduceWithReshape','tuple' if tuple_result else 'single',1 if tuple_result else 2,'trivial-size Reduce',
            'Tuple of Reshape(input_i)' if tuple_result else 'Reshape(input0)',
            'caller equal-element-count and layout conditions; multi_output_reduce='+str(tuple_result), ['identity of all coupled init components','one reshape per component','helper declaration is excluded from executable sites'])
    add('MergeReduces','combined-axes',0,'Reduce(Reduce(x,inner_dims),outer_dims)','Reduce(x,merged lifted axis list)',
        'caller single-output, same init and equivalent reducer guards', ['sort copies of both dimension lists','increment each outer axis for removed inner axes','std::merge and legal uniqueness'],['ReductionComputationsEquivalent'])
    add('ReorderReduceDotToDotReduce','profitable',0,'Reduce(Dot(a,b),0,Add)','Dot(Reduce(a,mapped dims),Reduce(b,mapped dims),new dnums)',
        'raise_slice_and_reduce_through_dot; input Dot; zero init; Add reducer; no lhs batch dimensions; old_flops/double(new_flops)>threshold',
        ['ConstructFromDotMaps and retained contracting dimensions','MakeDotHlo precision and result type','finite flop-count arithmetic and zero denominator in cost ratio','optional Status return is not propagated by caller'],['GetReduceFlops'])

    for empty in (True,False):
        for tuple_result in (True,False):
            slug=('empty-' if empty else 'scalar-')+('tuple' if tuple_result else 'single')
            row=add('HandleReduceWindow',slug,0 if tuple_result else 1,'ReduceWindow(inputs,inits,f)',
                    ('Tuple of ' if tuple_result else '')+('Broadcast(init_i)' if empty else 'original input_i'),
                    ('representative input or result zero-element; ' if empty else 'representative input scalar; if tuple output, reducer root Tuple; every input/output scalar checked; ')+
                    'multi_output_reduce_window='+str(tuple_result),
                    ['dispatch through local replace_with_span lambda','caller guard plus captured tuple mode determine actual replacement','documented identity premise for scalar input case'])
            row['lambda_invocation_anchor']='replace_with_span(broadcast_inits)' if empty else 'replace_with_span(maps)'
    add('HandleReduceWindow','singleton-tuple',[2,3],'one-input tuple ReduceWindow','Tuple(single-output ReduceWindow with cloned untupled reducer)',
        'multi-output; input_count1; reducer root Tuple; earlier empty/scalar paths did not return', ['embedded reducer/root construction','window, init and tuple shape preservation'],clone=True)
    rw_single='single-output after early tuple return; '
    cumsum=(rw_single+'walk operand through Reshape, same-element-type Bitcast, Convert, Slice, Copy to scalar Broadcast; zero init; Add reducer; underlying effective-scalar Constant; '
            'exactly one window axis size>1 matching operand extent, stride1, low=size-1, high0, dilations1, no reversal; other axes low/high0 and base dilation1; ')
    for iota64 in (True,False):
        for converted in (True,False):
            add('HandleReduceWindow','cumsum-'+('i64' if iota64 else 'i32')+'-'+('canonicalize-literal' if converted else 'reuse-literal'),4,
                'cumsum-like ReduceWindow of uniform converted literal','Multiply(Broadcast(converted literal),ConvertIfNeeded(Iota+1))',
                cumsum+'final scalar literal type '+('S64' if iota64 else 'not S64')+'; literal scalarization or convert list needed='+str(converted),
                ['replay every Convert in reverse chain order through Literal.Convert','count generated in S64 only for S64 literal, otherwise S32','count range/overflow and conversion','floating sum versus count multiply'])
    singleton=(rw_single+'every window size/stride/dilations1 and no reversal; reducer Add/Minimum/Maximum of parameters0/1; ')
    for op in ('Add','Minimum','Maximum'):
        add('HandleReduceWindow','singleton-crop-all-'+op.lower(),5,'ReduceWindow with unit window and cropping','Broadcast(init)',
            singleton+'reducer '+op+'; some negative window padding; operand static; some axis cropped by at least its whole size', ['signed negation and bounds','no original input survives crop'])
        for positive in (False,True):
            for negative in (False,True):
                add('HandleReduceWindow','singleton-'+op.lower()+'-'+('pad' if positive else 'no-pad')+'-'+('crop' if negative else 'no-crop'),6,
                    'ReduceWindow with unit window',op+'(operand,Broadcast(init))'+(' then Slice crop' if negative else '')+(' then Pad(init)' if positive else ''),
                    singleton+'reducer '+op+'; positive padding='+str(positive)+'; negative padding='+str(negative)+'; if cropping, operand static and no full-axis crop',
                    ['crop precedes positive Pad','init placement and commutative opcode matching','dynamic dimensions rejected for cropping','pad config keeps only positive edges'])
    add('HandleReduceWindow','full-dimensions',7,'ReduceWindow(x,init,f)','Reshape(Reduce(x,init,effective dims,f))',
        rw_single+'enable_window_reduce_to_reduce_replacement; no stride/dilation/padding; each nonunit window axis has result extent1; at least one such axis',
        ['window reversal not independently excluded by this local predicate','legal geometry ties window size to input extent','allowed reduction order and axis deletion'])
    pad_guard=(rw_single+'operand Pad or Convert(Pad); if Convert and one nontrivial window axis, padding/scan-length ratio >=0.1; '
               'not(interior padding and window base dilation); no negative Pad; Pad value equals init pointer OR both Constant and equal directly/after ConvertToShape; ranks match; ')
    for convert in (False,True):
        for combined in (True,False):
            add('HandleReduceWindow','pad-broadcast-'+('convert' if convert else 'direct')+'-'+('combined' if combined else 'existing'),8,
                'ReduceWindow('+('Convert(Pad(x))' if convert else 'Pad(x)')+')','CreateBroadcastSequence of selected operand',
                pad_guard+'Convert present='+str(convert)+'; '+('combined padded-window test true' if combined else 'combined test false; existing window test true'),
                ['effective-broadcast test requires static input/output','unit axes require every output window cover sole unpadded element, with OverflowSafeMultiply guard','nonunit axes require trivial window and equal output extent','optional Convert recreated only when dropping Pad'])
        add('HandleReduceWindow','pad-fold-'+('convert' if convert else 'direct'),9,
            'ReduceWindow('+('Convert(Pad(x))' if convert else 'Pad(x)')+')','ReduceWindow('+('Convert(x)' if convert else 'x')+',init,composed window)',
            pad_guard+'Convert present='+str(convert)+'; both effective-broadcast tests false',
            ['new edge padding = old window padding + base_dilation*Pad edge','interior Pad replaces base dilation only when prior base dilation1','shape/result/reducer retained','finite signed arithmetic and backend constraints'])

    summaries={
        'ShouldBroadcastReduce':'true if representative input or result has zero elements',
        'ReductionComputationsEquivalent':'same computation object OR two-parameter Add/Multiply/And/Or AnyOrder category matches; classification does not establish arbitrary scalar equivalence',
        'MatchArgMinMax':'exact coupled tuple/select/compare reducer pattern, including NaN test on parameter0 and smaller-index tie rule',
        'MatchArgMin':'four-operand tuple Reduce, Iota index input, IsScalarConstantInf value init, IsScalarConstantZero index init and MatchArgMinMax(false)',
        'MatchArgMax':'four-operand tuple Reduce, Iota index input, IsScalarConstantNegInf value init, IsScalarConstantZero index init and MatchArgMinMax(true)',
        'IsScalarConstantInf':'IsScalarConstant and not complex; compare against native positive infinity when available, otherwise native maximum',
        'IsScalarConstantNegInf':'IsScalarConstant and not complex; compare against native negative infinity when available, otherwise native lowest',
        'GetReduceFlops':'product of reduced axis extents minus1 times output element count; finite int64 estimate'}
    helpers=[]
    for name,summary in summaries.items():
        fs=[f for f in structural['functions'] if name+'(' in f['declarator']];assert len(fs)==1,name
        f=fs[0];body='\n'.join(source[f['line']-1:f['end_line']])
        helpers.append(dict(id=name,line=f['line'],end_line=f['end_line'],source_body_sha256=hashlib.sha256(body.encode()).hexdigest(),
                            source_behavior=summary,status='source_inspected_pending_independent_semantic_review'))
    owners=sorted({c['handler'] for c in cases})
    output=dict(schema=1,status='partial_source_extraction',source_sha256=inventory['source_sha256'],denominator_frozen=False,
                selected_handlers=owners,cases=cases,helper_contracts=helpers,
                noncall_declaration_site_ids=[s['id'] for s in noncall_declarations(inventory,structural) if s['owner'] in owners],
                documented_contract='sources/reduction-contract-manifest.json',
                limitations=['source/helper/lambda schemas overlap; not frozen obligation denominator','identity and reassociation prose is not a complete floating observation relation',
                             'primary-agent inspection only; source and algebraic correspondence pending','zero accepted full-source proofs'])
    validate_reduction_batch(output,inventory,source,structural)
    (ROOT/'census/reduction-cases.json').write_text(json.dumps(output,indent=2)+'\n')
    print(f'Extracted {len(cases)} reduction schemas across {len(owners)} handlers/helpers')


if __name__=='__main__':main()
