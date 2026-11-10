"""Match typed Clang call variants to the separate syntactic source inventory."""
import collections
import gzip
import json
from pathlib import Path
from extract_typed_ast import walk
from run_typed_ast import ROOT,SOURCE,digest

FUNCTIONS={'FunctionDecl','CXXMethodDecl','CXXConstructorDecl','CXXDestructorDecl','CXXConversionDecl'}
CALLS={'CallExpr','CXXMemberCallExpr','CXXOperatorCallExpr','CUDAKernelCallExpr'}
CONSTRUCTIONS={'CXXConstructExpr','CXXTemporaryObjectExpr','CXXUnresolvedConstructExpr'}
CASTS={'CXXStaticCastExpr','CXXReinterpretCastExpr','CXXConstCastExpr','CXXDynamicCastExpr','CStyleCastExpr'}
WRAPPERS={'ImplicitCastExpr','ParenExpr','MaterializeTemporaryExpr','ExprWithCleanups',
          'CXXBindTemporaryExpr','ConstantExpr'}


def point(location,kind='expansion'):
    if 'expansionLoc' in location or 'spellingLoc' in location:
        return location.get(kind+'Loc',location.get('expansionLoc',location.get('spellingLoc',{})))
    return location


def source_ranges(node):
    result=[]
    for mode in ('expansion','spelling'):
        start=point(node.get('range',{}).get('begin',{}),mode)
        end=point(node.get('range',{}).get('end',{}),mode)
        files=[loc.get('file') for loc in (start,end) if loc.get('file')]
        if any(f!=SOURCE and not f.endswith('/'+SOURCE) for f in files):continue
        if 'offset' not in start or 'offset' not in end:continue
        bounds=(start['offset'],end['offset']+end.get('tokLen',0))
        if bounds[1]<bounds[0]:continue
        if not any((r['byte_start'],r['byte_end'])==bounds for r in result):
            result.append(dict(byte_start=bounds[0],byte_end=bounds[1],mapping=mode,
                               explicit_main_file=bool(files)))
    return result


def callee(node,declarations):
    children=node.get('inner',[])
    expression=children[0] if children else {}
    while expression.get('kind') in WRAPPERS and expression.get('inner'):
        expression=expression['inner'][0]
    kind=expression.get('kind')
    if kind=='MemberExpr':
        identity=expression.get('referencedMemberDecl')
        declaration=declarations.get(identity,{})
        return dict(ast_decl_id=identity,name=expression.get('name'),
                    declaration_kind=declaration.get('kind','member_declaration'),
                    type=declaration.get('type',expression.get('type')),binding='selected_member_declaration')
    if kind=='DeclRefExpr':
        declaration=expression.get('referencedDecl',{})
        identity=declaration.get('id')
        binding='selected_function_declaration' if declaration.get('kind') in FUNCTIONS else 'indirect_value_callee'
        return dict(ast_decl_id=identity,name=declaration.get('name'),
                    declaration_kind=declaration.get('kind'),type=declaration.get('type'),binding=binding)
    return dict(ast_decl_id=None,name=expression.get('name'),declaration_kind=kind,
                type=expression.get('type'),binding='dependent_or_unresolved_expression')


def build(roots,declarations,syntax):
    functions=syntax['functions']
    by_end=collections.defaultdict(list)
    for function in functions:by_end[(function['byte_end'],function['name'])].append(function)
    aliases={}
    definitions=[]
    for root in roots:
        for node in walk(root):
            if node.get('kind') not in FUNCTIONS:continue
            if not any(n.get('kind')=='CompoundStmt' for n in node.get('inner',[])):continue
            matches={f['id']:f for r in source_ranges(node)
                     for f in by_end.get((r['byte_end'],node.get('name')),[])
                     if f['byte_start']<=r['byte_start']<f['byte_end']}
            if len(matches)!=1:continue
            function=next(iter(matches.values()))
            identity=node['id']
            definitions.append(dict(ast_decl_id=identity,source_function_id=function['id'],
                                    name=node.get('name'),type=node.get('type'),
                                    mangled_name=node.get('mangledName'),source_ranges=source_ranges(node)))
            while identity and identity not in aliases:
                aliases[identity]=function['id']
                identity=declarations.get(identity,{}).get('previousDecl')
    variants={}
    def visit(node,owner=None):
        owner=aliases.get(node.get('id'),owner) if node.get('kind') in FUNCTIONS else owner
        if node.get('kind') in CALLS|CONSTRUCTIONS|CASTS and node.get('id') not in variants:
            ranges=source_ranges(node)
            if ranges:
                row=dict(ast_id=node['id'],kind=node['kind'],owner_function_id=owner,
                         source_ranges=ranges,result_type=node.get('type'),accepted_source_proof=None)
                if node['kind'] in CALLS:
                    selected=callee(node,declarations)
                    selected['source_function_id']=aliases.get(selected['ast_decl_id'])
                    metadata=declarations.get(selected['ast_decl_id'],{})
                    selected['mangled_name']=metadata.get('mangledName')
                    selected['declaration_location']=metadata.get('loc')
                    selected['has_body_in_filtered_ast']=metadata.get('has_body',False)
                    row['callee']=selected
                elif node['kind'] in CONSTRUCTIONS:
                    row['constructor_type']=node.get('ctorType')
                    row['construction_kind']=node.get('constructionKind')
                else:
                    row['cast_kind']=node.get('castKind')
                variants[node['id']]=row
        for child in node.get('inner',[]):visit(child,owner)
    for root in roots:visit(root)
    by_range=collections.defaultdict(list)
    for row in variants.values():
        for r in row['source_ranges']:by_range[(r['byte_start'],r['byte_end'])].append(row)
    matches=[]
    for call in syntax['calls']:
        rows=[r for r in by_range.get((call['byte_start'],call['byte_end']),[])
              if r['owner_function_id']==call['owner_function_id']]
        # Retain every typed variant, including a dependent template pattern.
        identities=sorted({r['ast_id'] for r in rows})
        targets=sorted({r['callee']['source_function_id'] for r in rows
                        if r.get('callee',{}).get('source_function_id')})
        bindings=sorted({r.get('callee',{}).get('binding',
            'typed_cast' if r['kind'] in CASTS else 'typed_construction') for r in rows})
        matches.append(dict(source_call_id=call['id'],line=call['line'],call=call['call'],
                            ast_variant_ids=identities,local_target_function_ids=targets,
                            typed_bindings=bindings,
                            status='exact_source_range_variants' if rows else 'unmatched_source_call',
                            accepted_source_proof=None))
    covered={d['source_function_id'] for d in definitions}
    syntax_by_id={call['id']:call for call in syntax['calls']}
    edges=[dict(source_call_id=row['source_call_id'],
                caller_function_id=syntax_by_id[row['source_call_id']]['owner_function_id'],
                selected_function_id=target,
                scope='static declaration dependency; runtime dispatch and path conditions remain open')
           for row in matches for target in row['local_target_function_ids']]
    report=dict(schema=1,status='typed_static_callees_not_runtime_or_semantic_proof_closure',
                source_sha256=syntax['source_sha256'],denominator_frozen=False,accepted_source_rewrites=0,
                compiler_archive='reports/typed-ast-v1/result.json',
                function_definitions=definitions,source_function_aliases=aliases,
                unmatched_source_functions=[f['id'] for f in functions if f['id'] not in covered],
                typed_variants=list(variants.values()),source_calls=matches,local_call_edges=edges,
                limitations=['specific archived preprocessing/compiler configuration',
                    'exact source-range matching only; macro expansions and implicit calls stay explicit',
                    'template patterns can retain dependent callees alongside concrete instantiations',
                    'selected member declarations do not close runtime virtual dispatch',
                    'static calls are not execution paths, mutation effects or accepted source proofs'])
    return report


def load_inputs(root=ROOT):
    metadata=json.loads((root/'reports/typed-extraction-typed-ast-v1.json').read_text())
    for record in metadata['files']:assert digest(root/record['path'])==record['sha256']
    with gzip.open(root/'reports/typed-main-typed-ast-v1.json.gz','rt') as stream:roots=json.load(stream)
    with gzip.open(root/'reports/typed-declarations-typed-ast-v1.json.gz','rt') as stream:declarations=json.load(stream)
    syntax=json.loads((root/'census/full-call-inventory.json').read_text())
    return roots,declarations,syntax


def validate(result,roots,declarations,syntax):
    if result!=build(roots,declarations,syntax):
        raise ValueError('typed inventory differs from archived AST/source identities or promotes its scope')


def main():
    roots,declarations,syntax=load_inputs()
    result=build(roots,declarations,syntax)
    (ROOT/'census/typed-call-inventory.json').write_text(json.dumps(result,indent=2)+'\n')
    print('Typed definitions:',len(result['function_definitions']),'; unmatched functions:',len(result['unmatched_source_functions']))
    print('Source calls:',len(result['source_calls']),'; exact range matches:',sum(bool(r['ast_variant_ids']) for r in result['source_calls']))
    print('Typed call/construction variants:',len(result['typed_variants']))


if __name__=='__main__':main()
