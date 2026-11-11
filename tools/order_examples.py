"""Independent exact-order graph/domain generator and signed-word observations."""
from itertools import product

TRACKS = ('integer', 'real', 'unsigned_all_widths', 'signed_all_widths')


def rules():
    result = []
    def add(key, left, right, condition='true'):
        result.append(dict(key=key, lhs=left, rhs=right, condition=condition))
    def op(operator, a, b): return a+' '+b+' '+operator
    def order(operator, reverse, a, b): return op(operator, b, a) if reverse else op(operator, a, b)
    clamp = 'x1 x0 x2 clamp'
    add('max_self', 'x0 x0 max', 'x0')
    add('min_self', 'x0 x0 min', 'x0')
    for b in (0, 1):
        add(f'max_extreme_{b}', order('max', b, 'x0', 'x1'), 'x0', 'lower')
        add(f'min_extreme_{b}', order('min', b, 'x0', 'x1'), 'x0', 'upper')
        for name in ('max', 'min'):
            repeated = 'x0' if b else 'x1'
            add(f'{name}_nested_left_{b}', op(name, f'x0 x1 {name}', repeated), f'x0 x1 {name}')
        for name in ('max', 'min'):
            repeated = 'x0' if b else 'x1'
            add(f'{name}_nested_right_{b}', op(name, repeated, f'x0 x1 {name}'),
                f'x0 x1 {name}' if b else f'x1 x0 {name}')
        add(f'max_clamp_lower_{b}', order('max', b, 'x1', clamp), clamp, 'bounds')
    for outer, inner in product((0, 1), repeat=2):
        add(f'max_min_clamp_{outer}{inner}',
            order('max', outer, 'x1', order('min', inner, 'x0', 'x2')), clamp, 'bounds')
        add(f'min_max_clamp_{outer}{inner}',
            order('min', outer, 'x2', order('max', inner, 'x0', 'x1')), clamp)
        first = 'x1 x0 gt' if outer else 'x0 x1 lt'
        second = 'x2 x0 gt' if inner else 'x0 x2 lt'
        add(f'tautological_{outer}{inner}', first+' '+second+' and', 'x0 x1 x2 min lt')
    for direction in ('lt', 'le', 'gt', 'ge', 'eq', 'ne'):
        add('compare_self_'+direction, 'x0 x0 '+direction,
            'false' if direction in ('lt', 'gt', 'ne') else 'true')
    for key, left, right in (('input_lt_zero', 'x0 zero lt', 'false'),
                             ('zero_gt_input', 'zero x0 gt', 'false'),
                             ('input_ge_zero', 'x0 zero ge', 'true'),
                             ('zero_le_input', 'zero x0 le', 'true')):
        add('compare_zero_'+key, left, right, 'nonnegative')
    add('max_compare_first', 'x0 x1 max x0 gt', 'x1 x0 gt')
    add('max_compare_second', 'x0 x1 max x1 gt', 'x0 x1 gt')
    add('min_compare_first', 'x0 x0 x1 min gt', 'x0 x1 gt')
    add('min_compare_second', 'x1 x0 x1 min gt', 'x1 x0 gt')
    add('clamp_idempotent', 'x1 '+clamp+' x2 clamp', clamp)
    add('clamp_range', 'zero x0 x1 clamp', 'x0', 'range')
    assert len(result) == len({row['key'] for row in result}) == 44
    return result


def evaluate(tokens, values):
    stack = []
    for token in tokens.split():
        if token.startswith('x'): stack.append(values[int(token[1:])])
        elif token in ('true', 'false'): stack.append(token == 'true')
        elif token == 'zero': stack.append(0)
        elif token == 'clamp':
            upper, value, lower = stack.pop(), stack.pop(), stack.pop()
            stack.append(min(max(value, lower), upper))
        else:
            right, left = stack.pop(), stack.pop()
            stack.append({'min': lambda: min(left, right), 'max': lambda: max(left, right),
                          'lt': lambda: left < right, 'le': lambda: left <= right,
                          'gt': lambda: left > right, 'ge': lambda: left >= right,
                          'eq': lambda: left == right, 'ne': lambda: left != right,
                          'and': lambda: left and right}[token]())
    assert len(stack) == 1
    return stack[0]


def admitted(condition, values):
    x, lo, hi = values
    return {'true': True, 'lower': lo <= x, 'upper': x <= lo, 'bounds': lo <= hi,
            'nonnegative': x >= 0, 'range': 0 <= x <= lo}[condition]


def samples():
    for values in product(range(-2, 3), repeat=3): yield 'integer', 0, values, values
    for signed in (False, True):
        domain = 'signed' if signed else 'unsigned'
        for width in (0, 1, 2, 4, 8):
            modulus = 2**width
            raw = list(product(range(modulus), repeat=3)) if width <= 2 else [
                (0, 0, 0), (0, 1, modulus-1), (1, 0, modulus-1),
                (modulus-1, 0, 1), (modulus//2, 0, modulus-1),
                (modulus-1, modulus//2, 1), (1, modulus-1, 0), (3, 2, 1)]
            for values in raw:
                decoded = tuple(value-modulus if signed and value >= modulus//2 and width else value
                                for value in values)
                yield domain, width, values, decoded


def rows():
    for sample, (domain, width, raw, values) in enumerate(samples()):
        for rule in rules():
            left, right = evaluate(rule['lhs'], values), evaluate(rule['rhs'], values)
            kind = 'p' if type(left) is bool else 'v'
            allow = admitted(rule['condition'], values)
            if allow: assert left == right
            yield (domain, width, sample, raw, values, rule['key'], allow,
                   kind, int(left), int(right))
