#!/usr/bin/env python3
"""Check the recorded two-case artifact inventory; not a substitute for Lean replay or review."""
import copy, hashlib, json, pathlib, sys
P = pathlib.Path(__file__).resolve().parent
IDS = {'unsigned_remainder_widen_narrow', 'dynamic_slice_arbitrary_transpose'}
VARIANTS = {'nonempty', 'empty_or_zero', 'false_replacement', 'wrong_signature', 'known_contamination', 'independent_review', 'fresh_replay'}

def check(cases):
    errors = []
    ids = [c.get('id') for c in cases]
    if len(ids) != len(set(ids)) or set(ids) != IDS:
        errors.append('case ID set missing, extra or duplicated')
    for c in cases:
        if set(c.get('variants', [])) != VARIANTS:
            errors.append(c.get('id', '?') + ': required variants mismatch')
        for name in ('freeze', 'proof', 'receipt', 'review'):
            a = c.get('artifacts', {}).get(name, {})
            f = pathlib.Path(a.get('path', '/nonexistent'))
            if not f.is_file():
                errors.append(c.get('id', '?') + ': missing ' + name)
            elif hashlib.sha256(f.read_bytes()).hexdigest() != a.get('sha256'):
                errors.append(c.get('id', '?') + ': stale ' + name)
        receipt = pathlib.Path(c.get('artifacts', {}).get('receipt', {}).get('path', '/nonexistent'))
        if receipt.is_file() and json.loads(receipt.read_text()).get('result') != 'passed':
            errors.append(c.get('id', '?') + ': replay did not pass')
    return errors

def main():
    cases = json.loads((P / 'batch-artifacts.json').read_text())['cases']
    out = {'actual_errors': check(cases), 'commissioning': {}}
    for label in ('stale_hash', 'missing_artifact', 'duplicate_case', 'missing_case', 'omitted_variant'):
        x = copy.deepcopy(cases)
        if label == 'stale_hash': x[0]['artifacts']['proof']['sha256'] = '0' * 64
        if label == 'missing_artifact': x[0]['artifacts']['proof']['path'] = '/nonexistent/heldout-proof'
        if label == 'duplicate_case': x.append(copy.deepcopy(x[0]))
        if label == 'missing_case': x.pop()
        if label == 'omitted_variant': x[0]['variants'].remove('nonempty')
        out['commissioning'][label] = check(x)
    print(json.dumps(out, indent=2))
    return int(bool(out['actual_errors']) or any(not v for v in out['commissioning'].values()))

if __name__ == '__main__': sys.exit(main())
