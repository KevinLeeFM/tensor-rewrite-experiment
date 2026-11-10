"""Offline check of archived XLA shape failures; does not execute the pass."""
import hashlib
import json
from pathlib import Path
import re
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]


def check_archive(root=ROOT):
    folder = root / 'reports/empty-slice-replay-v2'
    result = json.loads((folder / 'result.json').read_text())
    assert result['test_passed'] and result['xla_pass_run'] and result['exit_code'] == 0
    assert result['source_commit'] == json.loads((root / 'sources/manifest.json').read_text())['xla_commit']
    required = {'fixture.cc', 'BUILD', 'events.json', 'build.log', 'test.log', 'test.xml'}
    files = result['files']
    assert len(files) == len(required)
    assert {Path(f['path']).name for f in files} == required
    for item in files:
        path = root / item['path']
        assert path.parent == folder
        assert hashlib.sha256(path.read_bytes()).hexdigest() == item['sha256']
    log = (folder / 'test.log').read_text()
    rows = re.findall(r'^EMPTY_SLICE_RESULT reversed=([01]) original_verified=1 changed=1 rewritten_verified=0$', log, re.M)
    assert sorted(rows) == ['0', '1']
    assert log.count('Expected instruction to have shape equal to s32[1], actual shape is s32[0]') == 2
    assert log.count('ORIGINAL_HLO') == log.count('REWRITTEN_HLO') == 2
    assert 'EMPTY_SLICE_CONTROL original_verified=1 changed=1 rewritten_verified=1 start=1 limit=2 stride=1' in log
    assert result['nonempty_control_passed']
    assert sorted((c['reversed'], c['original_verified'], c['rewritten_verified']) for c in result['cases']) == [(False, True, False), (True, True, False)]
    events = [json.loads(line) for line in (folder / 'events.json').read_text().splitlines()]
    assert any(e.get('finished', {}).get('overallSuccess') for e in events)
    assert any(e.get('testResult', {}).get('status') == 'PASSED' for e in events)
    assert any(e.get('testSummary', {}).get('overallStatus') == 'PASSED' for e in events)
    xml = ET.parse(folder / 'test.xml')
    assert len(xml.findall('.//testcase')) == 2
    assert not xml.findall('.//failure') and not xml.findall('.//error')
    source = root / 'sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc'
    assert hashlib.sha256(source.read_bytes()).hexdigest() == result['pass_source_sha256']
    manifest = json.loads((root / 'sources/indexing-contract-manifest.json').read_text())
    assert manifest['source_commit'] == result['source_commit']
    for item in manifest['files']:
        assert hashlib.sha256((root / item['path']).read_bytes()).hexdigest() == item['sha256']


if __name__ == '__main__':
    check_archive()
    print('Archived real-XLA empty-slice shape failures and nonempty control verified; no new pass run')
