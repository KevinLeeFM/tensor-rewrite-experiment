"""Validate compile provenance and replay typed source matching without accepting rewrites."""
import collections
import gzip
import hashlib
import json
from pathlib import Path
from capture_typed_dependencies import dependency_paths
from run_typed_ast import ROOT,SOURCE,COMMIT,PASS_SHA,ast_arguments,digest
from typed_call_inventory import load_inputs,validate
from typed_delegation_evidence import load_inputs as load_delegations,validate as validate_delegations


def check_files(root,records,parent):
    for record in records:
        path=root/record['path']
        assert path.parent==parent and digest(path)==record['sha256']


def check_archive(root=ROOT):
    folder=root/'reports/typed-ast-v1'
    result=json.loads((folder/'result.json').read_text())
    assert result['status']=='typed_ast_compilation_completed' and result['exit_code']==0
    assert result['source_commit']==COMMIT and result['source_sha256']==PASS_SHA
    assert digest(root/'sources/xla'/SOURCE)==PASS_SHA
    assert result['accepted_source_rewrites']==0 and result['denominator_frozen'] is False
    assert result['filter']=='xla::'
    assert result['scope']=='typed declarations/call expressions; not runtime effects, proof extraction or virtual target closure'
    assert {Path(f['path']).name for f in result['files']}=={'action.json','ast.jsons.gz','compiler.log'}
    check_files(root,result['files'],folder)
    action=json.loads((folder/'action.json').read_text())
    compiler=next(e['value'] for e in action['environmentVariables'] if e['key']=='GCC_PATH')
    command,removed=ast_arguments(action['arguments'],compiler)
    assert command==result['command'] and removed==result['removed_output_flags']
    raw_hash=hashlib.sha256();size=0
    with gzip.open(folder/'ast.jsons.gz','rb') as stream:
        for chunk in iter(lambda:stream.read(1024*1024),b''):
            raw_hash.update(chunk);size+=len(chunk)
    assert raw_hash.hexdigest()==result['raw_ast_sha256'] and size==result['raw_ast_bytes']
    query_folder=root/'reports/compile-query-typed-ast-v1'
    query=json.loads((query_folder/'result.json').read_text())
    check_files(root,query['files'],query_folder)
    assert query['selected_action_sha256']==digest(folder/'action.json')
    assert action in json.loads((query_folder/'actions.json').read_text())['actions']
    dependencies=root/'reports/dependencies-typed-ast-v1'
    deps=json.loads((dependencies/'result.json').read_text())
    assert deps['status']=='dependency_identities_captured' and deps['exit_code']==0
    assert deps['source_result_sha256']==digest(folder/'result.json')
    assert deps['compiler_sha256']==result['compiler_sha256']
    assert deps['capture_timing']=='after AST compilation; this is not a hermetic build closure'
    check_files(root,deps['files'],dependencies)
    paths=dependency_paths((dependencies/'dependencies.d').read_text())
    assert paths==[f['path'] for f in deps['dependencies']]
    assert next(f['sha256'] for f in deps['dependencies'] if f['path']==SOURCE)==PASS_SHA
    extraction=json.loads((root/'reports/typed-extraction-typed-ast-v1.json').read_text())
    assert extraction['source_ast_sha256']==digest(folder/'ast.jsons.gz')
    assert extraction['source_sha256']==PASS_SHA and extraction['filter']=='xla::'
    assert extraction['accepted_source_rewrites']==0 and extraction['independent_semantic_review'] is False
    return result,deps,extraction


def check_inventory(root=ROOT):
    roots,declarations,syntax=load_inputs(root)
    result=json.loads((root/'census/typed-call-inventory.json').read_text())
    validate(result,roots,declarations,syntax)
    assert result['unmatched_source_functions']==[]
    original={c['id']:c for c in syntax['calls']}
    variants={v['ast_id']:v for v in result['typed_variants']}
    ambiguous=[c for c in result['source_calls'] if len(original[c['source_call_id']]['local_definition_candidates'])>1]
    assert all(c['ast_variant_ids'] for c in ambiguous)
    assert all(len(c['local_target_function_ids'])<=1 for c in ambiguous)
    unnamed=[c for c in result['source_calls'] if original[c['source_call_id']]['call'] is None]
    assert all(c['ast_variant_ids'] and all(variants[i].get('callee',{}).get('name')=='operator()'
                                          for i in c['ast_variant_ids']) for c in unnamed)
    residuals=collections.Counter(c['call'] for c in result['source_calls'] if not c['ast_variant_ids'])
    assert set(residuals)<={'VLOG','ABSL_RETURN_IF_ERROR','CHECK','CHECK_EQ','TF_RET_CHECK','CHECK_OK',
                           'CHECK_LT','LOG','CHECK_GE','DCHECK','DCHECK_EQ'}
    summary=dict(schema=1,source_sha256=PASS_SHA,source_functions=len(syntax['functions']),
                 typed_function_declarations=len(result['function_definitions']),
                 source_calls=len(result['source_calls']),exact_range_matches=sum(bool(c['ast_variant_ids']) for c in result['source_calls']),
                 unmatched_macro_invocations=dict(sorted(residuals.items())),
                 ambiguous_name_candidate_sets=len(ambiguous),
                 ambiguous_sets_selecting_local_definition=sum(bool(c['local_target_function_ids']) for c in ambiguous),
                 ambiguous_sets_selecting_external_member=sum(not c['local_target_function_ids'] for c in ambiguous),
                 formerly_unnamed_operator_calls=len(unnamed),
                 sites_with_dependent_variant=sum('dependent_or_unresolved_expression' in c['typed_bindings'] for c in result['source_calls']),
                 local_static_dependency_edges=len(result['local_call_edges']),
                 accepted_source_rewrites=0,denominator_frozen=False,
                 runtime_dispatch_closed=False,independent_semantic_review=False)
    delegations=json.loads((root/'census/typed-delegation-evidence.json').read_text())
    validate_delegations(delegations,*load_delegations(root))
    summary['typed_schema_delegations']=len(delegations['delegations'])
    return summary


if __name__=='__main__':
    compiler,deps,extraction=check_archive()
    summary=check_inventory()
    summary.update(compiler_version=compiler['compiler_version'],preprocessing_dependencies=len(deps['dependencies']),
                   extraction_documents=extraction['documents'])
    (ROOT/'reports/typed-call-evidence.json').write_text(json.dumps(summary,indent=2)+'\n')
    print(json.dumps(summary,indent=2))
