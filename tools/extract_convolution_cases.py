"""Convolution source stages, loop writes and external delegation; still unproved."""
import hashlib
import json
from pathlib import Path
from extract_scalar_control_cases import validate_batch
from extract_arithmetic_cases import validate_helpers

ROOT = Path(__file__).resolve().parents[1]


def validate_convolution_batch(batch, inventory, source, structural):
    validate_batch(batch, inventory, source)
    validate_helpers(batch, source)
    calls = {(c['line'],c['call']):c for c in structural['calls']}
    for case in batch['cases']:
        if case['handler'] == 'ScalarMultiplyReduction':
            if case.get('loop_execution') != 'operand DFS zero-or-more writes; user DFS zero-or-more writes; one terminal target write':
                raise ValueError('scalar movement loop multiplicity lost')
            if len(case.get('additional_replacement_sites', [])) != 2:
                raise ValueError('scalar movement loop or terminal site omitted')
            for item in [case]+case['additional_replacement_sites'][:1]:
                if not any(c['kind']=='while_statement' for c in calls[(item['replacement_line'],item['replacement_call'])]['context']):
                    raise ValueError('scalar movement DFS loop context missing')
        if case['handler'] == 'PromoteConvolutionToF32IfNotOnednnCompatible':
            body='\n'.join(source[case['line']-1:case['end_line']])
            if case.get('continuing_rebind_anchor') != '*convolution = to_conv;' or case['continuing_rebind_anchor'] not in body:
                raise ValueError('promoted convolution continuation lost')
    external = batch['external_contracts']
    if len(external) != 1 or external[0]['id'] != 'SwapConvolutionOperandsIfBeneficial':
        raise ValueError('external convolution delegation omitted')
    entry=external[0]
    body='\n'.join((ROOT/entry['path']).read_text().splitlines()[entry['line']-1:entry['end_line']])
    if hashlib.sha256(body.encode()).hexdigest()!=entry['source_body_sha256']:
        raise ValueError('stale external convolution source')
    if entry['status']!='source_inspected_pending_independent_semantic_review':
        raise ValueError('unreviewed external delegate promoted')


def main():
    inventory=json.loads((ROOT/'census/source-sites.json').read_text())
    structural=json.loads((ROOT/'census/normalized-structural-sites.json').read_text())
    source=(ROOT/'sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc').read_text().splitlines()
    definitions={d['name']:d for d in inventory['definitions']}
    cases=[]
    def add(owner,slug,ordinals,lhs,rhs,guard,deps,helpers=()):
        d=definitions[owner]
        body='\n'.join(source[d['line']-1:d['end_line']])
        row=dict(id=owner+'/'+slug,handler=owner,line=d['line'],end_line=d['end_line'],
                 source_body_sha256=hashlib.sha256(body.encode()).hexdigest(),lhs=lhs,rhs=rhs,guard=guard,
                 dependencies=deps,helper_contract_ids=list(helpers),proof=None,status='source_extracted_pending_independent_review',
                 path_condition='legal input HLO; source-order caller guards, helper results, status propagation and earlier stages apply',
                 unit_kind='branch_or_rewrite_stage_pending_path_composition',
                 acceptance_unit='complete caller path including earlier graph mutations and any continuing rewrites',
                 type_partition_status='types, precision/numerical relation, dynamic geometry, sparsity and grouping need full partition')
        if isinstance(ordinals,tuple):
            target,anchor=ordinals
            assert anchor in body
            row.update(delegation_target=target,delegation_line=d['line']+body[:body.index(anchor)].count('\n'))
        else:
            if isinstance(ordinals,int):ordinals=[ordinals]
            owned=[s for s in inventory['sites'] if s['owner']==owner and s['kind']=='replacement']
            chosen=[owned[i] for i in ordinals]
            def identity(s):return dict(replacement_site_id=s['id'],replacement_line=s['line'],replacement_call=s['call'],replacement_source=source[s['line']-1])
            row.update(replacement_ordinals=ordinals,**identity(chosen[0]),additional_replacement_sites=[identity(s) for s in chosen[1:]])
        cases.append(row)
        return row

    for target, terminal in (('lhs',2),('rhs',3),('output',4)):
        row=add('ScalarMultiplyReduction','target-'+target,[0,1,terminal],
                'Convolution with reachable broadcast-scalar Multiply in selected operand/user traversal',
                'remove matched multiplies; combine float constants; attach one scalar Multiply to '+target,
                'HandleConvolution enable_scalar_multiply_reduction; BF16 or F32 result; nonempty collected values; target is '+target+' by ElementsIn tie/strict inequality selection',
                ['operand traversal starts only on larger tensors; user traversal starts when output larger and convolution one user',
                 'operand DFS may change multiple graph edges; no visited set; shared-node and predicate alias effects',
                 'user DFS follows sole user; ReplaceAllUsesWith then rebinding can revisit graph neighbors',
                 'Select branch traversal is included by opcode classification; no branch-equal-scalar guard is added',
                 'GetConstantValue returns optional double then stored as float; combine native float before casting to target scalar',
                 'MarkAsChanged occurs after loop mutations; error paths and final use replacement semantics'],
                ['IsOpCodeMultiplyCommutative','GetConstantValue','MakeScalarInstruction'])
        row.update(loop_execution='operand DFS zero-or-more writes; user DFS zero-or-more writes; one terminal target write',
                   site_order_interpretation='lexical source order; first two sites execute zero or more times, terminal selected by target; not one fixed three-write trace')
    for mul_side in ('lhs','rhs'):
        for bias_side in ('lhs','rhs'):
            add('TryToReorderConvAddMultiply','order-'+mul_side+'-'+bias_side,0,
                'Multiply(Add(Convolution(input,ConstantFilter),bias),Broadcast(ConstantVector)) with matcher sides '+mul_side+'/'+bias_side,
                'Add(Convolution(input,Multiply(filter,Broadcast(vector,kernel_output_feature))),Multiply(bias,broadcast))',
                'enable_conv_add_multiply_reorder; Conv,bias,broadcast one user; constant rank1; broadcast single dimension equals output feature dimension',
                ['Add node has no local one-user matcher; clones with original shapes/attributes',
                 'commutative matcher operand binding; feature broadcast maps; numerical distributivity and zero/exception effects',
                 'no explicit local fast-math guard'])
    add('FoldConvInputPad','compose',0,'Convolution(Pad(input,ConstantScalar0),filter)',
        'Convolution(input,filter) with composed input window padding/base dilation',
        'enable_folding_pad_into_convolution; no batch/feature padding; no negative pad; interior pad cannot coexist with window padding/base dilation; base dilation cannot coexist with any Pad on same axis',
        ['window edge addition; interior pad sets base_dilation=1+interior; clone original convolution attributes',
         'nonfinite zero products, finite signed dimension arithmetic and legal result geometry'])
    add('FoldConvFilterPad','dilation',0,'Convolution(input,Pad(filter,zero))',
        'Convolution(input,filter) with composed kernel window dilation/size',
        'enable_folding_pad_into_convolution; rhs Pad; IsAll(fill,0); no feature padding; no spatial edge padding; nonzero interior only when old window dilation<=1 then CHECK==1',
        ['zero-interior axes retain window size; changed axes set size to unpadded filter extent',
         'clone original attributes; numerical zeros and reversal; signed extent arithmetic'])
    row=add('PromoteConvolutionToF32IfNotOnednnCompatible','promote-and-continue',0,
            'BF16 Convolution not locally eligible for oneDNN', 'BF16 Convert(F32 Convolution(F32-converted original operands))',
            'HandleConvolution enable_onednn_support; executing_on_cpu; BF16 result; local can_rewrite false',
            ['ineligibility: batch grouping !=1, rhs Reverse, any empty array, spatial rank outside1..3, ranks unequal, negative padding/stride, base dilation!=1, or reversal',
             'convert every original operand, clone convolution, replace outer result',
             'sets caller pointer to inner F32 convolution and RETURNS FALSE; subsequent simplification still runs',
             'eligible BF16 returns TRUE without this replacement, causing caller early return',
             'precision configuration and BF16 accumulation/cast relation need source contract'])
    row['continuing_rebind_anchor']='*convolution = to_conv;'
    add('SimplifyConvToDot','pointwise-layout',0,'pointwise Convolution(input,filter)',
        'Bitcast(Dot(Bitcast(input),Bitcast(filter)))',
        'enable_conv_simplification; layout SENSITIVE; all layouts present; every kernel spatial extent1; no stride/padding/base dilation; input/output layouts equal and feature most minor; filter input feature more major than output feature; both group counts1',
        ['layout-sensitive physical address correspondence; input/output spatial order and bitcast shapes',
         'conv_width int64 product; updated descending layouts; dot contracting lhs1/rhs0',
         'window dilation harmless for unit kernel extent; original precision config retained; dynamic layout/sparsity contracts'])
    for reduction in (False,True):
        for reverse in ((False,True) if reduction else (False,)):
            for input_cast in (False,True):
                for kernel_cast in (False,True):
                    add('SimplifyConvToMultiply',('reduce' if reduction else 'pointwise')+'-'+str(int(reverse))+str(int(input_cast))+str(int(kernel_cast)),0,
                        'restricted grouped/depthwise Convolution',
                        'Multiply(transposed/converted input,BroadcastSequence(reversed/transposed/converted kernel))'+(' then ReduceAdd and Reshape' if reduction else ''),
                        'layout insensitive; no rhs sparsity; each kernel spatial extent1 OR output extent1; no stride/padding/dilation; kernel input feature extent1; input/output feature extents equal feature_group_count; reduction='+str(reduction)+'; nontrivial kernel reversal='+str(reverse)+'; input/kernel type casts='+str(input_cast)+'/'+str(kernel_cast),
                        ['no enable_conv_simplification check inside this helper; caller invokes unconditionally at last stage',
                         'no separate local batch_group_count==1 guard; legal group geometry must be traced',
                         'reverse kernel on contracted nonunit spatial axes before transposing',
                         'convert operands to convolution output type; reduction stays output type rather than dot F32 accumulation rule',
                         'original precision_config not passed to plain Multiply/ReduceAdd; numerical permission and algorithm contracts'])
    add('HandleConvolution','empty',0,'Convolution with empty input or filter','MakeScalarLike(convolution,0)',
        'after optional scalar movement; lhs OR rhs zero elements',
        ['source does not test output empty here; previous movement may already have mutated graph', 'shape/type and zero reduction semantics'])
    for target,slug,anchor,guard in (
        ('ScalarMultiplyReduction','scalar-movement','ScalarMultiplyReduction(convolution)','enable_scalar_multiply_reduction; CONTINUES regardless of successful non-error mutation'),
        ('FoldConvInputPad','input-pad','FoldConvInputPad(convolution)','after empty check; helper true stops'),
        ('FoldConvFilterPad','filter-pad','FoldConvFilterPad(convolution)','input fold false; helper true stops'),
        ('SwapConvOperands','operand-swap','SwapConvOperands(convolution)','both pad folds false; helper true stops'),
        ('PromoteConvolutionToF32IfNotOnednnCompatible','onednn','PromoteConvolutionToF32IfNotOnednnCompatible(&convolution)','enable_onednn_support; true means compatible and stops; false can mean promoted and continues'),
        ('SimplifyConvToDot','to-dot','SimplifyConvToDot(convolution)','current pointer possibly promoted; helper true stops'),
        ('SimplifyConvToMultiply','to-multiply','SimplifyConvToMultiply(convolution)','dot helper false; current pointer possibly promoted; helper true stops')):
        add('HandleConvolution',slug+'-delegation',(target,anchor),'current Convolution','helper-dependent graph',guard,
            ['compose all previous graph effects, pointer rebindings and source return conditions'])

    summaries={
        'IsOpCodeMultiplyCommutative':'opcode whitelist Multiply/Transpose/Reshape/Select; classification itself is not a linearity proof, especially for Select branches',
        'GetConstantValue':'scalar Constant floating -> native double, integral -> int64 -> double; unsupported returns nullopt; scalar movement dereferences result',
        'MakeScalarInstruction':'native float multiplier cast to target primitive; supports floating/integral dispatch, fatal otherwise',
        'SwapConvOperands':'enable_conv_operand_swap and layout insensitive; delegate external swap with virtual ConvIsLowerable callback; MarkAsChanged if true',
    }
    helpers=[]
    for name,behavior in summaries.items():
        fs=[f for f in structural['functions'] if name+'(' in f['declarator']]
        assert len(fs)==1,name
        f=fs[0]
        body='\n'.join(source[f['line']-1:f['end_line']])
        helpers.append(dict(id=name,line=f['line'],end_line=f['end_line'],source_body_sha256=hashlib.sha256(body.encode()).hexdigest(),
                            source_behavior=behavior,status='source_inspected_pending_independent_semantic_review'))
    path='sources/xla/xla/hlo/transforms/simplifiers/conv_operand_swapper.cc'
    lines=(ROOT/path).read_text().splitlines()
    external=[dict(id='SwapConvolutionOperandsIfBeneficial',path=path,line=34,end_line=173,
                   source_body_sha256=hashlib.sha256('\n'.join(lines[33:173]).encode()).hexdigest(),
                   status='source_inspected_pending_independent_semantic_review',
                   source_behavior='reject grouping>1, sparsity and block scales; preserve group/pure-contraction window axes; transpose convolution roles with reversed kernel, exchanged dilations and recomputed padding; strict kernel-product profitability; fresh PrecisionConfig with swapped operand precision only; lowerability veto removes constructed convolution; final replacement preserves sharding/frontend attrs and relays control dependencies',
                   obligations=['finite int64 arithmetic and physical/numerical convolution symmetry','fresh precision config may omit other fields; compare full precision/algorithm semantics','ConvIsLowerable is virtual, base returns true; removal and auxiliary construction effects'])]
    result=dict(schema=1,status='partial_source_extraction',source_sha256=inventory['source_sha256'],denominator_frozen=False,
                selected_handlers=sorted({c['handler'] for c in cases}),cases=cases,helper_contracts=helpers,external_contracts=external,
                limitations=['branch/stage schemas overlap; lexical mapping is not semantic completeness','loop, alias, profile and continuing graph effects remain unproved',
                             'external swapper belongs to caller obligation; source file boundary does not exclude delegated behavior','zero accepted full-source proofs'])
    validate_convolution_batch(result,inventory,source,structural)
    (ROOT/'census/convolution-cases.json').write_text(json.dumps(result,indent=2)+'\n')
    print(f'Extracted {len(cases)} convolution schemas across {len(result["selected_handlers"])} owners')


if __name__=='__main__':main()
