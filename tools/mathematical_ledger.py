"""Inventory retained benchmark data and checked mathematical evidence; no C++ processing."""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = 'census/mathematical-corpus-v1.json'
BATCHES = ('arithmetic', 'collective-rotation', 'convolution', 'dot', 'layout',
           'reduction', 'scalar-control', 'shape', 'simple', 'tensor-index')
ALLOWED = {'propext', 'Quot.sound', 'Classical.choice'}


def read(path, root=ROOT):
    return json.loads((root/path).read_text())


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def freeze(root=ROOT):
    target = root/MANIFEST
    if target.exists():
        raise ValueError('corpus v1 already exists; revisions require a new manifest version')
    files=[]; ids=[]
    for batch in BATCHES:
        name='census/'+batch+'-cases.json'
        rows=read(name, root)['cases']
        files.append(dict(path=name, sha256=digest(root/name), count=len(rows)))
        ids.extend(row['id'] for row in rows)
    assert len(ids)==len(set(ids))==488
    record=dict(schema=1, benchmark_records_frozen=True, benchmark_record_count=len(ids),
                mathematical_obligation_denominator_frozen=False,
                mathematical_obligation_denominator=None,
                scope='retained abstract benchmark data only; no new code correspondence',
                files=files, benchmark_ids=sorted(ids))
    target.write_text(json.dumps(record,indent=2)+'\n')


def corpus(root=ROOT):
    manifest=read(MANIFEST,root); rows={}
    for file in manifest['files']:
        assert digest(root/file['path'])==file['sha256'], file['path']
        cases=read(file['path'],root)['cases']
        assert len(cases)==file['count']
        for case in cases:
            assert case['id'] not in rows
            rows[case['id']]=dict(benchmark_id=case['id'],batch=Path(file['path']).stem,
                retained_lhs=case.get('lhs'),retained_rhs=case.get('rhs'),
                unreviewed_benchmark_notes_not_assumptions=case.get('guard'),
                mathematical_target_status='needs_formal_statement_and_domain_partition',
                evidence=[],whole_record_mathematically_closed=False,
                code_correspondence='future_work')
    assert sorted(rows)==manifest['benchmark_ids']
    assert len(rows)==manifest['benchmark_record_count']==488
    return rows


def evidence(root=ROOT):
    pilot=read('census/pilot-value-proofs.json',root); result={}
    def add(name,kind,profile,labels=()):
        if name not in result:
            result[name]=dict(theorem=name,kinds=[],profile_descriptions=[],
                              historical_candidate_benchmark_labels=[],
                              label_correspondence_certified=False,
                              mathematical_acceptance='kernel_check_pending',
                              independent_statement_review='pending')
        row=result[name]
        if kind not in row['kinds']:row['kinds'].append(kind)
        if profile not in row['profile_descriptions']:row['profile_descriptions'].append(profile)
        row['historical_candidate_benchmark_labels']=sorted(set(
            row['historical_candidate_benchmark_labels'])|set(labels))
    for row in pilot['rules']:
        labels=([row['source_case']] if row.get('source_case') else [])+row.get('additional_source_cases',[])
        add(row['theorem'],'value_law',row['semantic_track'],labels)
    for kind,key in [('pure_graph_context','graph_context'),('fixed_schedule_context','effectful_graph_context')]:
        for row in pilot[key]['rules']:
            add(row['theorem'],kind,row['source_partition'],[row['source_case']])
    nested=pilot['nested_slice']
    for name in nested['logical_rule_theorems']:
        add(name,'value_law',nested['logical_profile'],[nested['source_case']])
    for name in pilot['support_theorems']:
        add(name,'support_lemma','premises and conclusion in the checked Lean declaration')
    # These are mathematical certificates. No native evidence validator is invoked.
    for key in ('numerical_refutation','shape_refutation','algebraic_refutation',
                'ordered_compare','scaled_nested_slice','reducer_index'):
        group=pilot[key]
        labels=group.get('case_ids',group.get('source_cases',[]))
        if group.get('case_id'):labels=[group['case_id']]
        for name in group.get('refutation_theorems',group.get('certificates',[])):
            add(name,'refutation_or_diagnostic_certificate',group.get('profile',group.get('scope','')),labels)
    theory=read('reports/theory-progress.json',root)
    for name in theory['axiom_dependencies']:
        labels=['HandleNegate/involution'] if name.endswith('FloatNegation.tensor_involution') else []
        add(name,'library_backed_theory',theory.get('theorem_profiles',{}).get(name,theory['scope']),labels)
    return sorted(result.values(),key=lambda row:row['theorem'])


def audit_theorems(rows,root=ROOT):
    path=root/'reports/mathematical-ledger-audit.lean'
    lines=['import TensorRewrite','import TensorRewriteTheory','']
    for row in rows:
        lines.extend(['#check @'+row['theorem'],'#print axioms '+row['theorem']])
    path.write_text('\n'.join(lines)+'\n')
    build=subprocess.run(['lake','build'],cwd=root,text=True,capture_output=True)
    assert build.returncode==0,(build.stdout+build.stderr)[-6000:]
    run=subprocess.run(['lake','env','lean',str(path)],cwd=root,text=True,capture_output=True)
    (root/'reports/mathematical-ledger-audit.log').write_text(run.stdout+run.stderr)
    assert run.returncode==0,(run.stdout+run.stderr)[-6000:]
    for row in rows:
        name=row['theorem']
        match=re.search(re.escape(name)+r"' depends on axioms: \[([^\]]*)\]",run.stdout)
        if match:axioms={v.strip() for v in match[1].split(',') if v.strip()}
        else:
            assert name+"' does not depend on any axioms" in run.stdout,name
            axioms=set()
        assert axioms<=ALLOWED,(name,axioms)
        row['mathematical_acceptance']='kernel_checked_in_declared_model'
        row['axiom_dependencies']=sorted(axioms)
    return dict(path=str(path.relative_to(root)),sha256=digest(path),exit_code=run.returncode,
                output_path='reports/mathematical-ledger-audit.log',
                output_sha256=digest(root/'reports/mathematical-ledger-audit.log'))


def assemble(cases,proofs,audit):
    for proof in proofs:
        assert proof['mathematical_acceptance']=='kernel_checked_in_declared_model'
        for label in proof['historical_candidate_benchmark_labels']:
            assert label in cases,label
            cases[label]['evidence'].append(proof['theorem'])
            cases[label]['mathematical_target_status']='partial_model_evidence_requires_partition_review'
    records=sorted(cases.values(),key=lambda row:row['benchmark_id'])
    return dict(schema=1,status='mathematical_campaign_ledger_formulation_in_progress',
        code_correspondence_performed=False,code_correspondence_future_work=True,
        benchmark_record_count=len(records),mathematical_obligation_denominator=None,
        mathematical_denominator_frozen=False,whole_benchmark_records_closed=0,
        positive_or_negative_workflow_verdict='unresolved_full_campaign_required',
        benchmark_status_counts=dict(Counter(r['mathematical_target_status'] for r in records)),
        batch_counts=dict(Counter(r['batch'] for r in records)),
        distinct_checked_declarations=len(proofs),
        declaration_kind_counts=dict(Counter(k for p in proofs for k in p['kinds'])),
        count_policy='declaration kinds can overlap; benchmark labels are retained candidates, '
                     'not certified correspondence; no proof-count/488 coverage fraction',
        corpus_manifest=MANIFEST,audit=audit,proofs=proofs,benchmark_records=records)


def main():
    parser=argparse.ArgumentParser();parser.add_argument('--freeze-corpus',action='store_true')
    args=parser.parse_args()
    if args.freeze_corpus:freeze()
    cases=corpus();proofs=evidence();audit=audit_theorems(proofs)
    result=assemble(cases,proofs,audit)
    (ROOT/'census/mathematical-ledger.json').write_text(json.dumps(result,indent=2)+'\n')
    print(str(result['benchmark_record_count'])+' benchmark records retained; '+
          str(result['distinct_checked_declarations'])+' mathematical declarations checked; '
          'full obligation partitions and verdict remain open.')


if __name__=='__main__':main()
