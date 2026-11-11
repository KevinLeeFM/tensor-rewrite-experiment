"""Freeze the scalar/reduction extension review without changing the original packet."""
import argparse
import json
from pathlib import Path
import zipfile
from freeze_mathematical_review import ROOT, digest, git
from freeze_mathematical_extensions_review import selected as previous_selection

NAME='mathematical-extensions-v2'
BRIEF='reviews/packets/'+NAME+'.md'
BASE='reviews/packets/'+NAME


def selected(revision):
    paths=set(previous_selection(revision))
    paths.update({'reports/pilot-values.json', BRIEF,
                  'tools/freeze_mathematical_extensions_review_v2.py',
                  'reports/mathematical-extensions-v1-packet-failure.json',
                  'reports/mathematical-extensions-preflight-v1/00.log',
                  'reports/mathematical-extensions-preflight-v1/01.log'})
    return sorted(paths)


def verify():
    descriptor=json.loads((ROOT/(BASE+'.json')).read_text())
    manifest_path=ROOT/descriptor['manifest'];archive_path=ROOT/descriptor['archive']
    assert digest(manifest_path.read_bytes())==descriptor['manifest_sha256']
    assert digest(archive_path.read_bytes())==descriptor['archive_sha256']
    manifest=json.loads(manifest_path.read_text());revision=descriptor['source_revision']
    assert manifest['source_revision']==revision
    assert selected(revision)==[r['path'] for r in manifest['files']]
    with zipfile.ZipFile(archive_path) as archive:
        assert sorted(archive.namelist())==[r['path'] for r in manifest['files']]
        for row in manifest['files']:
            data=archive.read(row['path'])
            assert len(data)==row['bytes'] and digest(data)==row['sha256']
            assert data==git('show',revision+':'+row['path']),row['path']
    assert descriptor['new_statements_for_review']==41
    assert not descriptor['independent_semantic_review_performed']
    assert not descriptor['code_correspondence_performed']
    print('Extension review packet verified against Git: '+str(len(manifest['files']))+' files.')


def main():
    parser=argparse.ArgumentParser();parser.add_argument('--ref',default='HEAD')
    parser.add_argument('--verify',action='store_true');args=parser.parse_args()
    if args.verify:verify();return
    for suffix in ('.json','-manifest.json','.zip'):
        assert not (ROOT/(BASE+suffix)).exists(),'Use a new packet version; never overwrite frozen bytes'
    revision=git('rev-parse',args.ref).decode().strip();rows=[]
    with zipfile.ZipFile(ROOT/(BASE+'.zip'),'w',zipfile.ZIP_DEFLATED) as archive:
        for path in selected(revision):
            data=git('show',revision+':'+path);archive.writestr(path,data)
            rows.append(dict(path=path,sha256=digest(data),bytes=len(data)))
    manifest_path=ROOT/(BASE+'-manifest.json')
    manifest_path.write_text(json.dumps(dict(schema=1,source_revision=revision,files=rows),indent=2)+'\n')
    descriptor=dict(schema=1,status='frozen_pending_authorized_independent_review',
                    source_revision=revision,review_brief=BRIEF,archive=BASE+'.zip',
                    archive_sha256=digest((ROOT/(BASE+'.zip')).read_bytes()),
                    manifest=BASE+'-manifest.json',manifest_sha256=digest(manifest_path.read_bytes()),
                    original_reviewed_theory_statements=89,new_statements_for_review=41,
                    current_theory_statements=130,current_ledger_declarations=390,
                    current_custom_lean_lines=4598,independent_semantic_review_performed=False,
                    code_correspondence_performed=False,whole_workload_verdict='open')
    (ROOT/(BASE+'.json')).write_text(json.dumps(descriptor,indent=2)+'\n');verify()


if __name__=='__main__':main()
