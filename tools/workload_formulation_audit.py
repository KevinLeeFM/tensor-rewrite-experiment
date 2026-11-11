"""Reconcile all retained mathematical records with explicit domain worksheets; no source analysis."""
from collections import Counter
import hashlib
import json
from pathlib import Path
import mathematical_ledger as ledger

ROOT = Path(__file__).resolve().parents[1]
CATALOG = 'census/workload-formulation-catalog-v11.json'


def digest(path): return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def worksheet_ids(document):
    if 'records' in document:
        return {r['benchmark_id'] for r in document['records']}
    return {name for family in document['families'] for name in family['benchmark_ids']}


def read_catalog(path=CATALOG):
    catalog = ledger.read(path)
    catalog = dict(catalog, _catalog_path=path)
    assert catalog['mathematical_denominator_frozen'] is False
    for row in catalog['worksheets']:
        assert digest(ROOT / row['path']) == row['sha256'], row['path']
        worksheet = ledger.read(row['path'])
        sources=(worksheet['retained_batches'] if 'retained_batches' in worksheet else
                 [dict(path=worksheet['retained_batch'],sha256=worksheet['retained_batch_sha256'])])
        source_ids=set()
        for source in sources:
            assert digest(ROOT / source['path']) == source['sha256'],source['path']
            source_ids.update(case['id'] for case in ledger.read(source['path'])['cases'])
        assert worksheet_ids(worksheet) <= source_ids
        assert len(worksheet_ids(worksheet)) == row['retained_record_count']
    return catalog


def assemble(cases, progress, catalog):
    records = progress['benchmark_records']
    assert len(records) == len({r['benchmark_id'] for r in records}) == len(cases) == 488
    assert {r['benchmark_id'] for r in records} == set(cases)
    assert progress['whole_benchmark_records_closed'] == 0
    assert progress['mathematical_obligation_denominator'] is None
    assert not any(r['whole_record_mathematically_closed'] for r in records)
    references = {name:[] for name in cases}
    nonproposal_worksheet_ids = set()
    for row in catalog['worksheets']:
        worksheet = ledger.read(row['path'])
        names = worksheet_ids(worksheet)
        if worksheet['status'] != 'unreviewed_mathematical_formulation_proposals_not_frozen_N_or_F':
            nonproposal_worksheet_ids.update(names)
        for name in names:
            assert name in references, name
            references[name].append(row['path'])
    output = []
    for row in records:
        name = row['benchmark_id']
        output.append(dict(benchmark_id=name,batch=row['batch'],owner=name.split('/')[0],
                           worksheet_references=references[name],
                           mathematical_target_status=row['mathematical_target_status'],
                           checked_declaration_references=row['evidence'],
                           whole_record_mathematically_closed=False))
    missing = [r['benchmark_id'] for r in output if not r['worksheet_references']]
    evidence_only = [r['benchmark_id'] for r in output if r['checked_declaration_references']
                     and not r['worksheet_references']]
    batches = sorted({r['batch'] for r in output})
    catalog_path = catalog.get('_catalog_path', CATALOG)
    return dict(status='whole_retained_corpus_formulation_audit_not_proof_coverage',
                corpus_manifest=ledger.MANIFEST,catalog=catalog_path,catalog_sha256=digest(ROOT / catalog_path),
                retained_benchmark_records=488,records_with_domain_worksheets=488-len(missing),
                records_with_only_unreviewed_proposal_worksheets=sum(
                    bool(r['worksheet_references']) and r['benchmark_id'] not in nonproposal_worksheet_ids
                    for r in output),
                records_without_domain_worksheets=missing,
                records_with_evidence_but_no_domain_worksheet=evidence_only,
                batch_counts={batch:dict(retained=sum(r['batch']==batch for r in output),
                    with_worksheet=sum(r['batch']==batch and bool(r['worksheet_references']) for r in output),
                    without_worksheet=sum(r['batch']==batch and not r['worksheet_references'] for r in output))
                    for batch in batches},
                owner_counts=dict(Counter(r['owner'] for r in output)),records=output,
                worksheet_presence_is_completed_formulation=False,
                every_record_has_received_a_complete_proof_attempt=False,
                mathematical_denominator_frozen=False,mathematical_obligation_denominator=None,
                whole_benchmark_records_closed=0,code_correspondence_performed=False,
                positive_or_negative_workflow_verdict='unresolved_full_campaign_required')


def main():
    progress = ledger.read('census/mathematical-ledger.json')
    result = assemble(ledger.corpus(),progress,read_catalog())
    result['input_ledger_sha256'] = digest(ROOT / 'census/mathematical-ledger.json')
    (ROOT / 'reports/workload-formulation-audit.json').write_text(json.dumps(result,indent=2)+'\n')
    print('All488 retained records reconciled;'+str(result['records_with_domain_worksheets'])+
          ' have domain worksheets;'+str(len(result['records_without_domain_worksheets']))+
          ' lack them. Worksheet presence is not completed formulation or proof coverage.')


if __name__ == '__main__': main()
