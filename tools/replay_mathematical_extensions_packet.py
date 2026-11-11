"""Replay a frozen extension packet in a fresh project with disclosed dependency-cache reuse."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import tempfile
import time
import zipfile

ROOT=Path(__file__).resolve().parents[1]


def sha(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--packet',default='mathematical-extensions-v2')
    parser.add_argument('--report',default='reports/mathematical-extensions-preflight-v2.json')
    args=parser.parse_args();report_path=ROOT/args.report;logs=report_path.with_suffix('')
    assert not report_path.exists() and not logs.exists(),'Use a new report name; preserve earlier attempts'
    descriptor=json.loads((ROOT/('reviews/packets/'+args.packet+'.json')).read_text())
    assert sha(ROOT/descriptor['archive'])==descriptor['archive_sha256']
    assert sha(ROOT/descriptor['manifest'])==descriptor['manifest_sha256']
    manifest=json.loads((ROOT/descriptor['manifest']).read_text())
    scratch=Path(tempfile.mkdtemp(prefix='tensor-extension-preflight-'));logs.mkdir(parents=True)
    frozen={}
    with zipfile.ZipFile(ROOT/descriptor['archive']) as archive:
        assert sorted(archive.namelist())==sorted(r['path'] for r in manifest['files'])
        for row in manifest['files']:
            assert not Path(row['path']).is_absolute() and '..' not in Path(row['path']).parts
            data=archive.read(row['path']);assert hashlib.sha256(data).hexdigest()==row['sha256']
            target=scratch/row['path'];target.parent.mkdir(parents=True,exist_ok=True)
            target.write_bytes(data);frozen[row['path']]=data
    assert not (scratch/'.lake/build').exists()
    (scratch/'.lake').mkdir();(scratch/'.lake/packages').symlink_to(ROOT/'.lake/packages',True)
    packages=json.loads(frozen['lake-manifest.json'])['packages']
    def pins():
        result=[]
        for p in packages:
            path=ROOT/'.lake/packages'/p['name']
            rev=subprocess.check_output(['git','-C',str(path),'rev-parse','HEAD'],text=True).strip()
            status=subprocess.check_output(['git','-C',str(path),'status','--porcelain',
                                            '--untracked-files=no'],text=True)
            assert rev==p['rev'] and not status,p['name']
            result.append(dict(name=p['name'],revision=rev,tracked_clean=True))
        return result
    before=pins()
    commands=[['python3','tools/'+name+'.py'] for name in
              ['check_libraries','check_theory','check_scalar_domains','check_reduction_algebra',
               'mathematical_ledger']]
    commands += [['python3','-m','unittest','discover','-s','tests','-p',p,'-v'] for p in
                 ['test_convolution*.py','test_logical_family.py','test_mathematical_ledger.py',
                  'test_theory_accounting.py','test_scalar_domains.py','test_reduction_algebra.py']]
    rows=[]
    for i,command in enumerate(commands):
        start=time.monotonic()
        run=subprocess.run(command,cwd=scratch,text=True,capture_output=True)
        log=logs/(str(i).zfill(2)+'.log');log.write_text(run.stdout+run.stderr)
        rows.append(dict(command=command,working_directory=str(scratch),exit_code=run.returncode,
                         seconds=round(time.monotonic()-start,2),log=str(log.relative_to(ROOT)),
                         log_sha256=sha(log)))
        (logs/'commands.json').write_text(json.dumps(rows,indent=2)+'\n')
        print(' '.join(command),run.returncode,flush=True)
        if run.returncode:print((run.stdout+run.stderr)[-3000:]);raise SystemExit(run.returncode)
    results={}
    for p in ['reports/library-setup.json','reports/theory-progress.json','reports/scalar-domains.json',
              'reports/reduction-algebra.json','census/mathematical-ledger.json']:
        assert json.loads(frozen[p])==json.loads((scratch/p).read_text()),p
        results[p]=dict(equal_all_fields=True,frozen_sha256=hashlib.sha256(frozen[p]).hexdigest(),
                        replay_sha256=sha(scratch/p))
    cold_log=scratch/'reports/library-setup-build.log'
    transcript=logs/'cold-project-build.log';transcript.write_bytes(cold_log.read_bytes())
    built=sorted(set(re.findall(r'Built (TensorRewrite[\w.]*) \(',transcript.read_text())))
    assert built,'Cold compiler transcript must contain rebuilt project modules'
    assert pins()==before
    sources=[r for r in manifest['files'] if r['path'].startswith(('TensorRewrite/','tests/fixtures/'))
             and r['path'].endswith('.lean')]
    for row in sources:assert sha(scratch/row['path'])==row['sha256']
    tests=sum(int(m[1]) for r in rows if
              (m:=re.search(r'Ran (\d+) tests?',(ROOT/r['log']).read_text())))
    assert tests==35
    report=dict(schema=1,status='fresh_packet_project_replay_passed',
                independent_semantic_review_performed=False,source_revision=descriptor['source_revision'],
                packet_sha256=descriptor['archive_sha256'],scratch_directory=str(scratch),
                cold_project_build=True,project_artifacts_copied=False,
                dependency_sources_and_compiled_caches_reused=True,upstream_libraries_rebuilt=False,
                cold_compiler_transcript=str(transcript.relative_to(ROOT)),
                cold_compiler_transcript_sha256=sha(transcript),rebuilt_project_modules=built,
                packages_before_and_after=before,tests_passed=tests,source_files_unchanged=len(sources),
                results=results,commands=rows,whole_workload_verdict='open',
                code_correspondence_performed=False)
    report_path.write_text(json.dumps(report,indent=2)+'\n')
    print('Fresh packet replay passed;35 tests;five complete JSON results match.',flush=True)


if __name__=='__main__':main()
