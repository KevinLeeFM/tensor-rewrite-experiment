"""Integrity checks for mathematical proposals, never a semantic or proof acceptance checker."""
from collections import Counter
import hashlib
import json
from pathlib import Path
import formulate_remaining_batches as proposals
import mathematical_ledger as ledger

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = proposals.MANIFEST


def digest(path): return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def read(path): return json.loads((ROOT/path).read_text())


def check_inputs():
    manifest=read(MANIFEST)
    for row in manifest['files']:
        assert digest(ROOT/row['path'])==row['sha256'],row['path']
    assert manifest['new_record_proposals']==380 and len(manifest['worksheets'])==7
    assert manifest['classification_groups']==124 and manifest['proposed_domain_profiles']==38
    assert manifest['new_Lean_statements']==manifest['new_custom_Lean_lines']==0
    assert manifest['mathematical_obligation_denominator'] is None
    for key in ('source_guards_adopted_as_proof_assumptions','mathematical_denominator_frozen',
                'independently_reviewed','all_workload_attempts_complete','code_correspondence_performed'):
        assert manifest[key] is False,key
    assert manifest['whole_benchmark_records_closed']==0
    baseline=read(proposals.BASELINE)
    assert baseline['base_revision']==manifest['base_revision']==proposals.BASE_REVISION
    assert baseline['record_count']==len(baseline['records'])==380
    assert baseline['correspondence_certified'] is False
    domains=read(proposals.DOMAINS)
    assert domains['status']=='proposed_domains_not_adopted_operator_axioms'
    assert {key:row['meaning'] for key,row in domains['profiles'].items()}==proposals.PROFILE_DESCRIPTIONS
    assert all(not row['independently_reviewed'] and not row['accepted_as_full_semantics']
               for row in domains['profiles'].values())
    expected=proposals.expected_worksheets(baseline)
    assert set(expected)==set(manifest['worksheets'])
    for path,value in expected.items():assert read(path)==value,path
    catalog=read(proposals.CATALOG);prior=catalog['supersedes']
    assert digest(ROOT/prior['path'])==prior['sha256']
    old=read(prior['path'])
    assert catalog['worksheets']==old['worksheets']+[
        dict(path=p,sha256=digest(ROOT/p),retained_record_count=len(x['records']))
        for p,x in expected.items()]
    assert catalog['proposal_expansion']==dict(path=MANIFEST,sha256=digest(ROOT/MANIFEST))
    assert catalog['mathematical_denominator_frozen'] is False
    names={p['theorem'] for p in read('census/mathematical-ledger.json')['proofs']}
    assert {n for refs in baseline['records'].values() for n in refs} <= names
    return manifest,expected


def assemble_report(manifest,worksheets):
    records=[r for worksheet in worksheets.values() for r in worksheet['records']]
    ids=[r['benchmark_id'] for r in records]
    assert len(ids)==len(set(ids))==380
    assert all(not r['whole_record_closed'] and not r['source_guards_adopted_as_proof_assumptions']
               and not r['complete_proof_attempt_for_all_partitions_claimed'] for r in records)
    return dict(status='proposal_packet_integrity_checked_not_mathematical_semantic_acceptance',
        manifest=MANIFEST,manifest_sha256=digest(ROOT/MANIFEST),new_record_proposals=380,
        new_worksheet_count=7,classification_group_count=124,proposed_domain_profiles=38,
        per_batch_records={Path(p).name.split('-mathematical-domains-')[0]:len(x['records'])
                           for p,x in worksheets.items()},
        record_role_counts=dict(Counter(r['record_role'] for r in records)),
        risk_record_counts=dict(Counter(tag for r in records for tag in r['mathematical_risks'])),
        candidate_evidence_record_count=sum(bool(r['existing_candidate_evidence_at_base']) for r in records),
        new_checked_Lean_statements=0,new_custom_Lean_lines=0,whole_benchmark_records_closed=0,
        semantic_correctness_of_proposals_independently_reviewed=False,
        every_proposed_domain_has_a_Lean_operator_definition=False,
        complete_proof_attempts_for_all_partitions=False,
        mathematical_obligation_denominator=None,mathematical_denominator_frozen=False,
        code_correspondence_performed=False,final_workflow_verdict_resolved=False)


def validate_result(result):
    manifest,worksheets=check_inputs()
    assert result==assemble_report(manifest,worksheets)


def main():
    manifest,worksheets=check_inputs();result=assemble_report(manifest,worksheets)
    (ROOT/'reports/workload-formulation-expansion.json').write_text(json.dumps(result,indent=2)+'\n')
    print('Integrity checked:380 explicit record proposals in7 worksheets; no new Lean proof acceptance, '
          'semantic review, frozen N/F or whole-record closure.')


if __name__=='__main__':main()
