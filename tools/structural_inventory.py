"""C++ syntax inventory with condition position and short-circuit context.
Not a preprocessed translation unit, reachability proof, or frozen rewrite census.
"""
import hashlib
import json
from pathlib import Path
import re
import sys
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'.parser-deps'))
from tree_sitter import Language, Parser
import tree_sitter_cpp


def extract(data, original=None, capture_all_calls=False):
    parsed_data=data
    original=data if original is None else original
    assert len(data)==len(original)
    parser=Parser(Language(tree_sitter_cpp.language()))
    tree=parser.parse(data)
    def text(node): return original[node.start_byte:node.end_byte].decode() if node else None
    def contains(outer,inner): return outer is not None and outer.start_byte<=inner.start_byte and inner.end_byte<=outer.end_byte
    def location(node): return {'line':node.start_point.row+1,'end_line':node.end_point.row+1,'byte_start':node.start_byte,'byte_end':node.end_byte}
    def enclosing_context(node):
        context=[];owner=None;owner_errors=None;parent=node.parent
        while parent:
            if parent.type=='function_definition':
                owner=text(parent.child_by_field_name('declarator'));owner_errors=parent.has_error;break
            if parent.type=='if_statement':
                condition=parent.child_by_field_name('condition')
                consequence=parent.child_by_field_name('consequence')
                alternative=parent.child_by_field_name('alternative')
                branch='condition_evaluation' if contains(condition,node) else ('then' if contains(consequence,node) else 'else' if contains(alternative,node) else 'other')
                context.append({'kind':'if','branch':branch,'condition':text(condition),'line':parent.start_point.row+1})
            if parent.type=='binary_expression':
                right=parent.child_by_field_name('right');left=parent.child_by_field_name('left')
                operator=text(parent.child_by_field_name('operator'))
                if contains(right,node) and operator in ('&&','||'):
                    context.append({'kind':'short_circuit','required_value':operator=='&&','expression':text(left),'line':parent.start_point.row+1})
            if parent.type in ('for_statement','for_range_loop','while_statement','do_statement','lambda_expression','case_statement','conditional_expression'):
                body=parent.child_by_field_name('body')
                header=data[parent.start_byte:(body.start_byte if body else min(parent.end_byte,parent.start_byte+300))].decode()
                context.append({'kind':parent.type,'header':header,'line':parent.start_point.row+1})
            parent=parent.parent
        return list(reversed(context)),owner,owner_errors
    stack=[tree.root_node];calls=[];errors=[];functions=[];assignments=[]
    while stack:
        node=stack.pop()
        stack.extend(reversed(node.named_children))
        if node.type=='ERROR' or node.is_missing:
            errors.append({'type':node.type,'missing':node.is_missing,**location(node),'source':text(node)})
        if node.type=='function_definition':
            declarator=node.child_by_field_name('declarator')
            functions.append({'declarator':text(declarator),'declarator_location':location(declarator),**location(node)})
        if node.type=='assignment_expression':
            context,owner,owner_errors=enclosing_context(node)
            assignments.append({'source':text(node),'target':text(node.child_by_field_name('left')),
                                'value':text(node.child_by_field_name('right')),
                                'operator':text(node.child_by_field_name('operator')),
                                'owner_declarator':owner,'owner_has_parse_errors':owner_errors,
                                'context':context,**location(node)})
        if node.type!='call_expression': continue
        callee=node.child_by_field_name('function')
        names=re.findall(r'[A-Za-z_]\w*',text(callee) or '')
        if not names and not capture_all_calls: continue
        name=names[-1] if names else None
        name_node=callee.child_by_field_name('field') or callee
        if capture_all_calls:
            terminal=name_node
            while terminal.type in ('qualified_identifier','template_function','template_method'):
                child=terminal.child_by_field_name('name')
                if child is None:break
                terminal=child
            name=text(terminal) if terminal.type in ('identifier','field_identifier','operator_name') else None
            name_node=terminal
        if not capture_all_calls and not re.search(r'Replace|Remove|AddInstruction|set_|mutable_|Swap|Clone|UpdateLayout|SetAndSanitize',name):continue
        context,owner,owner_errors=enclosing_context(node)
        calls.append({'call':name,'callee':text(callee),'source':text(node),'owner_declarator':owner,
                      'owner_has_parse_errors':owner_errors,'expression_line':node.start_point.row+1,
                      'kind':('unclassified_syntactic_call' if capture_all_calls else
                              'replacement' if name and 'Replace' in name else 'mutation_or_construction'),
                      'context':context,**location(node),
                      'line':name_node.start_point.row+1})
    for call in calls:
        call['overlapping_parse_errors']=[i for i,e in enumerate(errors) if e['byte_start']<call['byte_end'] and call['byte_start']<e['byte_end']]
    return {'schema':1,'source_sha256':hashlib.sha256(original).hexdigest(),
            'syntax_view_sha256':hashlib.sha256(parsed_data).hexdigest(),'status':'structural_discovery_only',
            'denominator_frozen':False,'parse_has_errors':tree.root_node.has_error,
            'errors':errors,'functions':functions,'calls':calls,'assignment_expressions':assignments,
            'limitations':['macros not expanded; this is not a typechecked C++ translation unit',
                           'early exits, loop invariants and indirect/helper effects require further analysis',
                           'condition_evaluation is not the same as condition true',
                           'assignment expressions include local/synthetic writes; no type or alias analysis; declarations/update expressions not indexed as writes',
                           'no independent semantic review or complete obligation splitting']}


def main():
    data=(ROOT/'sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc').read_bytes()
    result=extract(data)
    lexical=json.loads((ROOT/'census/source-sites.json').read_text())
    keys={(c['line'],c['call']) for c in result['calls']}
    result['lexical_only_sites']=[s for s in lexical['sites'] if (s['line'],s['call']) not in keys]
    for site in result['lexical_only_sites']:
        declarations=[f for f in result['functions'] if f['declarator_location']['line']<=site['line']<=f['declarator_location']['end_line'] and site['call'] in f['declarator']]
        site['structural_classification']='function_declarator_not_call' if declarations else 'unresolved_discrepancy'
    lexical_keys={(s['line'],s['call']) for s in lexical['sites']}
    result['structural_only_calls']=[{'line':c['line'],'call':c['call']} for c in result['calls'] if (c['line'],c['call']) not in lexical_keys]
    (ROOT/'census/structural-sites.json').write_text(json.dumps(result,indent=2)+'\n')
    from cpp_syntax_view import syntax_view
    view,ledger=syntax_view(data)
    normalized=extract(view,original=data)
    normalized['syntax_rewrites']=ledger
    normalized['limitations'].append('assignment macro syntax is normalized without modeling status/return semantics')
    keys={(c['line'],c['call']) for c in normalized['calls']}
    normalized['lexical_only_sites']=[s for s in lexical['sites'] if (s['line'],s['call']) not in keys]
    for site in normalized['lexical_only_sites']:
        declarations=[f for f in normalized['functions'] if f['declarator_location']['line']<=site['line']<=f['declarator_location']['end_line'] and site['call'] in f['declarator']]
        site['structural_classification']='function_declarator_not_call' if declarations else 'unresolved_discrepancy'
    for call in normalized['calls']:
        call['enclosing_syntax_rewrites']=[i for i,r in enumerate(ledger)
            if r['byte_start']<=call['byte_start'] and call['byte_end']<=r['byte_end']]
    for assignment in normalized['assignment_expressions']:
        assignment['overlapping_syntax_rewrites']=[i for i,r in enumerate(ledger)
            if r['byte_start']<assignment['byte_end'] and assignment['byte_start']<r['byte_end']]
    (ROOT/'census/normalized-structural-sites.json').write_text(json.dumps(normalized,indent=2)+'\n')
    print(f"{len(result['calls'])} structural candidate calls; {len(result['errors'])} parse errors/missing nodes; {len(result['lexical_only_sites'])} lexical-only sites")
    print(f"Syntax-only view: {len(normalized['calls'])} calls; {len(normalized['errors'])} errors/missing nodes; {len(ledger)} explicit syntax rewrites")
    print(f"{len(normalized['assignment_expressions'])} assignment expressions including local and syntax-normalized candidates; no alias analysis")

if __name__=='__main__':main()
