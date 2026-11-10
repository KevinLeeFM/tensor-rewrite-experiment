"""Recover declared rules and verifier invocations, without executing the artifact."""
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
ARTIFACT = ROOT / 'sources/tensorright/artifact/tr-artifact'


def main():
    rows = []
    excluded = {'debug', 'maxMinToClampBefore', 'maxMinToClampAfter', 'generalize'}
    for source in sorted((ARTIFACT / 'rules').glob('*/Main.hs')):
        text = source.read_text()
        signatures = list(re.finditer(r'^(\w+)\s*::', text, re.M))
        calls = []
        for match in re.finditer(r'^\s+(verify\w*)\s+([^\n]+)', text, re.M):
            # The final argument is the rule, after an optional solver config.
            argument = re.search(r'(\w+)\s*$', match[2].split('--', 1)[0])
            if not argument:
                raise ValueError(f'Unrecognized verifier invocation: {match[0]}')
            calls.append((match[1], argument[1]))
        for index, signature in enumerate(signatures):
            end = signatures[index+1].start() if index+1 < len(signatures) else len(text)
            body = text[signature.start():end]
            if signature[1] == 'main':
                continue
            verifiers = [kind for kind, name in calls if name == signature[1]]
            label = re.search(r'\brewrite\s+"((?:\\.|[^"\\])*)"', body)
            if not verifiers and not label:
                continue
            rows.append({'id': source.parent.name + '/' + signature[1],
                         'path': str(source.relative_to(ROOT)),
                         'line': text.count('\n',0,signature.start())+1,
                         'label': label[1] if label else None,
                         'verifier_invocations': verifiers,
                         'included_by_runall': source.parent.name not in excluded,
                         'xla_mapping_status': 'unmapped'})
    result = {'schema': 1, 'status': 'static_artifact_inventory_not_reproduction',
              'rules': rows,
              'invoked_in_main_suite': sum(bool(r['verifier_invocations']) and r['included_by_runall'] for r in rows)}
    (ROOT / 'census/historical-rules.json').write_text(json.dumps(result, indent=2)+'\n')
    print(f"Recovered {len(rows)} rule records, {result['invoked_in_main_suite']} invoked in main suite")


if __name__ == '__main__':
    main()
