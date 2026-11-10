"""Reproducible, manually inspected source-schema batch; no independent review implied."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def main():
    inventory=json.loads((ROOT/'census/source-sites.json').read_text())
    definitions={d['name']:d for d in inventory['definitions']}
    cases=[]
    def add(handler, slug, lhs, rhs, guard, helpers, alternatives=None):
        d=definitions[handler]
        cases.append({'id':handler+'/'+slug,'handler':handler,'line':d['line'],'end_line':d['end_line'],
            'lhs':lhs,'rhs':rhs,'guard':guard,'helpers':helpers,
            'alternative_type_cases':alternatives or [],
            'path_condition':'earlier branches in this handler did not successfully rewrite',
            'status':'source_extracted_pending_independent_review','lean_statement':None,'proof':None})
    compat=['ReplaceInstructionIfCompatible','SameShape','DfsHloRewriteVisitor::ReplaceInstruction','HloComputation::ReplaceInstruction']
    direct=['DfsHloRewriteVisitor::ReplaceInstruction','HloComputation::ReplaceInstruction']
    for op in ('And','Or'):
        h='Handle'+op
        for side in ('lhs','rhs'):
            if op=='And':
                add(h,side+'-true',f'And({"True, x" if side=="lhs" else "x, True"})','x',
                    'both operand types PRED; IsAll('+side+',1); successful compatibility replacement',compat+['IsAll'])
                result='0'
            else:
                add(h,side+'-true',f'Or({"True, x" if side=="lhs" else "x, True"})','matched True operand',
                    'both operand types PRED; IsAll('+side+',1); successful compatibility replacement',compat+['IsAll'])
                result='x'
            add(h,side+'-zero',f'{op}({"0, x" if side=="lhs" else "x, 0"})',result,
                'IsAll('+side+',0); successful compatibility replacement',compat+['IsAll'],['PRED Boolean','legal integral bitwise types'])
    add('HandleNot','involution','Not(Not(x))','x','nested Not matcher; successful compatibility replacement',compat,['PRED Boolean','legal integral bitwise types'])
    add('HandleNegate','involution','Negate(Negate(x))','x','nested Negate matcher; successful compatibility replacement',compat,['legal integral widths','floating-point formats','complex types when legal'])
    add('HandleXor','equal-inputs','Xor(a,b)','MakeScalarLike(old,0)',
        'a == b OR (!a.HasSideEffect AND a.Identical(b, same operands/computations, layout_sensitive=true, sharding_sensitive=true))',direct+['HloInstruction::Identical','MakeScalarLike'],['PRED Boolean','legal integral bitwise types'])
    for side in ('lhs','rhs'):
        add('HandleXor',side+'-zero',f'Xor({"0, x" if side=="lhs" else "x, 0"})','x',
            'IsAll('+side+',0); successful compatibility replacement',compat+['IsAll'],['PRED Boolean','legal integral bitwise types'])
    for left in ('Lt(x,c1)','Gt(c1,x)'):
        for right in ('Lt(x,c2)','Gt(c2,x)'):
            add('TrySimplifyTautologicalCompare',left[:2]+'-'+right[:2],f'And({left},{right})','Lt(x,min(c1,c2))',
                'both constants effective scalars of type S32; both variable pointers identical',
                ['ReplaceWithNewInstruction','MakeScalarLike','HloInstruction::CreateCompare'])
    add('HandleGetTupleElement','tuple-projection','GetTupleElement(Tuple(xs),i)','xs[i]',
        'operand opcode Tuple; legal tuple index; successful compatibility replacement',compat)
    add('HandleComplex','components','Complex(Real(a),Imag(b))','a','a == b; matcher succeeds',direct)
    add('HandleReal','complex-projection','Real(Complex(r,i))','r','nested matcher succeeds',direct)
    add('HandleReal','noncomplex','Real(x)','x','operand element type is not complex',direct)
    add('HandleImag','complex-projection','Imag(Complex(r,i))','i','nested matcher succeeds',direct)
    add('HandleImag','noncomplex','Imag(x)','BroadcastZeros(output shape)','operand element type is not complex',direct+['BroadcastZeros'])
    add('HandleIota','trivial-axis','Iota(shape,axis)','MakeScalarLike(old,0)','extent of iota axis <= 1',direct+['MakeScalarLike'])
    for form in ('ConstantScalar(0)','Broadcast(ConstantScalar(0))'):
        add('HandleExp','zero-'+('broadcast' if form.startswith('Broadcast') else 'scalar'),f'Exp({form})','MakeScalarLike(old,1.0)',
            'matcher succeeds',direct+['MakeScalarLike'])
    integral_or_fast='integral output element type OR enable_fast_math'
    add('HandleSubtract','self','Subtract(x,x)','MakeScalarLike(old,0)',
        integral_or_fast+'; operand pointer identity',direct+['MakeScalarLike'])
    add('HandleSubtract','zero','Subtract(x,zero)','x','IsAll(rhs,0); successful compatibility replacement',compat+['IsAll'])
    for form in ('constant','broadcast-constant'):
        add('HandleSubtract',form,'Subtract(nonconstant x,'+form+')','Add(x,Negate(constant)) with broadcast rebuilt if present',
            'matcher selects direct or broadcast Constant; x is NonConstant; no fast-math guard on this branch',
            ['CreateUnary Negate','CreateBroadcast preserving dimensions','ReplaceWithNewInstruction'])
    add('HandleSubtract','sub-sub-self','Subtract(x,Subtract(x,y))','y',
        integral_or_fast+'; nested matcher uses same x pointer; successful compatibility replacement',compat)
    for side in ('left','right'):
        add('HandleSubtract','sub-add-self-'+side,'Subtract(x,Add(x,y)) with x at '+side,'Negate(y)',
            integral_or_fast+'; AddAnyOrder matches x pointer', ['ReplaceWithNewInstruction','CreateUnary Negate'])
        add('HandleSubtract','add-sub-self-'+side,'Subtract(Add(x,y),x) with x at '+side,'y',
            integral_or_fast+'; rhs pointer equals a matched add operand; selected remaining operand passes compatibility replacement',compat)
    def mul(slug, lhs, rhs, guard, ordinals, helpers):
        add('HandleMultiply',slug,lhs,rhs,guard,helpers)
        cases[-1]['replacement_ordinals']=ordinals
    for side,one,zero in [('rhs',0,3),('lhs',1,2)]:
        mul(side+'-one','Multiply(x,1) with 1 at '+side,'x',
            'IsAll('+side+',1); successful compatibility replacement',[one],compat+['IsAll'])
        mul(side+'-zero','Multiply(x,0) with 0 at '+side,'matched zero operand',
            'IsAll('+side+',0); integral type OR fast math; successful compatibility replacement',[zero],compat+['IsAll'])
    mul('negated-operands','Multiply(Negate(a),Negate(b))','Multiply(a,b)',
        'nested matcher succeeds; both operand replacements succeed in source order',[4,5],['ReplaceOperandWith twice','MarkAsChanged'])
    mul('abs-square','Multiply(Abs(a),Abs(a))','Multiply(a,a)',
        'lhs == rhs; Abs matcher; a element type not complex',[6,7],['ReplaceOperandWith twice','Abs numeric semantics','MarkAsChanged'])
    mul('predicate-convert','Multiply(Convert(pred),x) in either operand order','Select(pred,x,BroadcastZeros)',
        'Convert input PRED; no local finite or fast-math guard',[8],['BroadcastZeros','CreateTernary Select','candidate nonfinite mismatch requires replay'])
    reassociate='output is neither floating nor complex OR fast math'
    mul('four-factors','Multiply(Multiply(a,c1),Multiply(b,c2)) with AnyOrder matchers','Multiply(Multiply(a,b),Multiply(c1,c2))',
        reassociate+'; a,b NonConstant; c1,c2 Constant; constant product broadcast if scalar',[9],['MakeBinaryHlo','CreateBroadcast','ReplaceWithNewInstruction'])
    mul('constant-product','Multiply(Multiply(a,c1),c2) with AnyOrder matchers','Multiply(a,Multiply(c1,c2))',
        reassociate+'; a NonConstant; c1,c2 Constant; scalar product rebroadcast as needed',[10],['MakeBinaryHlo','CreateBroadcast','ReplaceWithNewInstruction'])
    mul('broadcast-factor','Multiply(Multiply(a,c),Broadcast(b)) in matched operand orders','Multiply(a,Broadcast(Multiply(b,c)))',
        reassociate+'; a NonConstant; c scalar direct/broadcast Constant; b NonConstant; c broadcast to b shape if needed',[11],['CreateBroadcast preserving dims','CreateBinary Multiply','ReplaceWithNewInstruction'])
    for form in ('direct','broadcast-scalars'):
        mul('legacy-constant-product-'+form,'Multiply(Multiply(a,c1),c2) in '+form+' pattern','Multiply(a,Multiply(c1,c2))',
            reassociate+'; exact legacy matcher; constant product broadcast if needed',[12],['MakeBinaryHlo','CreateBroadcast','ReplaceWithNewInstruction'])
    mul('exp-product','Multiply(Exp(a),Exp(b))','Exp(Add(a,b))','fast math enabled; Exp matchers',[13],['Exp floating/complex semantics','ReplaceWithNewInstruction'])
    mul('sqrt-square','Multiply(Sqrt(a),Sqrt(a))','a','UniqueHloInstruction matches same a; IsNonNegative(a,options)',[14],['IsNonNegative','sqrt rounding and exceptional values','ReplaceInstruction'])
    mul('rsqrt-square','Multiply(Rsqrt(a),Rsqrt(a))','Divide(MakeScalarLike(a,1),a)',
        'UniqueHloInstruction matches same a; IsNonNegative(a,options)',[15],['IsNonNegative','rsqrt/divide rounding and exceptional values','ReplaceWithNewInstruction'])
    add('HandleMultiply','conv-reorder-delegation','Multiply around convolution/addition','helper-dependent reordered graph',
        'earlier paths did not rewrite; TryToReorderConvAddMultiply is invoked',['TryToReorderConvAddMultiply: expand all internal cases'])
    cases[-1]['delegation_target']='TryToReorderConvAddMultiply'
    source_lines=(ROOT/'sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc').read_text().splitlines()
    cases[-1]['delegation_line']=next(i for i,line in enumerate(source_lines,1) if 'return TryToReorderConvAddMultiply(multiply)' in line)
    covered={c['handler'] for c in cases}
    sites=[]
    for site in inventory['sites']:
        if site['owner'] not in covered: continue
        entry=dict(site)
        if site['kind']=='replacement':
            entry['case_candidates']=[c['id'] for c in cases if c['handler']==site['owner']]
            entry['classification']='replacement_site; case-to-branch mapping still pending'
        elif site['call']=='mutable_operand':
            entry['classification']='mutable pointer acquisition; not itself a graph mutation'
        else:
            entry['classification']='needs_specific_inspection'
        sites.append(entry)
    output={'schema':1,'status':'partial_source_extraction','denominator_frozen':False,
        'source_sha256':inventory['source_sha256'],'cases':cases,'site_accounting':sites,
        'coverage_limits':['type variants not fully split','source-to-case review is by primary agent only',
                           'base graph replacement contract not formally verified','no accepted Lean statements or proofs']}
    (ROOT/'census/simple-cases.json').write_text(json.dumps(output,indent=2)+'\n')
    print(f'Extracted {len(cases)} source schemas across {len(covered)} handlers/helpers')
if __name__=='__main__': main()
