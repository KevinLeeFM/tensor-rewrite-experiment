"""Materialize independent Pad, enumerate outer windows, and build a separate reshape/Broadcast."""
from itertools import product
from math import prod


def coordinates(shape):
    return list(product(*(range(n) for n in shape)))


def span(n, step):
    return (n - 1)*step + 1 if n else 0


def axis(pad_low, pad_high, spacing, kernel, stride, base, low, high, reverse, n=1, kept=False,
         dilation=1):
    return dict(pad_low=pad_low, pad_high=pad_high, spacing=spacing, kernel=kernel, stride=stride,
                base=base, low=low, high=high, reversed=reverse, n=n, kept=kept, dilation=dilation)


def padded_extent(a):
    return a['pad_low'] + span(a['n'], a['spacing']) + a['pad_high']


def output_positions(a):
    room = span(padded_extent(a), a['base']) + a['low'] + a['high']
    return [o for o in range(max(room+1, 0))
            if o*a['stride'] + span(a['kernel'], a['dilation']) <= room]


def raw_axes():
    return [axis(l, h, d, k, s, b, lo, hi, r)
            for l in range(3) for h in range(3) for d in (1, 2) for k in range(4)
            for s in (1, 2) for b in (1, 2) for lo in range(-2, 3) for hi in range(-2, 3)
            for r in (False, True)]


def eligible(a):
    occupied = a['pad_low'] * a['base']
    return all(sum(o*a['stride'] + (a['kernel']-1-k if a['reversed'] else k) - a['low']
                   == occupied for k in range(a['kernel'])) == 1 for o in output_positions(a))


def extras():
    def keep(n, l, h): return axis(l, h, 1, 1, 1, 1, -l, -h, True, n=n, kept=True, dilation=5)
    full = axis(1, 1, 1, 3, 1, 1, 0, 0, False)
    two = axis(1, 1, 2, 2, 1, 1, 0, 0, True)
    return [[], [keep(0, 2, 1)], [keep(3, 2, 1)], [keep(3, 1, 2), full],
            [two, keep(3, 2, 1)], [two, keep(0, 2, 1)], [two, full],
            [two, keep(2, 1, 1), full], [keep(2, 2, 1), keep(3, 1, 2), full]]


def expected():
    candidates = raw_axes()
    axes = [dict(profile=p, **{k:a[k] for k in ('pad_low','pad_high','spacing','kernel','stride',
                                               'base','low','high','reversed')},
                 outputs=len(output_positions(a)), eligible=eligible(a))
            for p, a in enumerate(candidates)]
    profiles = [[a] for a in candidates if eligible(a)] + extras()
    counts, rows = [], []
    for profile, geometry in enumerate(profiles):
        original = dict(zip(coordinates([a['n'] for a in geometry]),
                            range(1, prod(a['n'] for a in geometry)+1)))
        # Materialize the full Pad tensor before dilating or sampling any outer window.
        padded = dict.fromkeys(coordinates([padded_extent(a) for a in geometry]), 0)
        for point, value in original.items():
            padded[tuple(a['pad_low']+i*a['spacing'] for a, i in zip(geometry, point))] = value
        occupied = {tuple(i*a['base'] for a, i in zip(geometry, point)): value
                    for point, value in padded.items()}
        kept = [i for i, a in enumerate(geometry) if a['kept']]
        compact = dict(zip(coordinates([geometry[i]['n'] for i in kept]), original.values()))
        outputs = list(product(*(output_positions(a) for a in geometry)))
        kernels = coordinates([a['kernel'] for a in geometry])
        counts.append(dict(profile=profile, rank=len(geometry), inputs=len(original),
                           padded=len(padded), outputs=len(outputs), kernels=len(kernels), axes=kept))
        for ordinal, output in enumerate(outputs):
            trace, shifted = [], []
            for kernel in kernels:
                point = tuple(o*a['stride']+(a['kernel']-1-k if a['reversed'] else k)*a['dilation']
                              -a['low'] for a, o, k in zip(geometry, output, kernel))
                value = occupied.get(point, 0)
                trace.append(value)
                # A valid Pad fill0 converts to1; an invalid outer position also contributes1.
                shifted.append(occupied[point]+1 if point in occupied else 1)
            state = 0
            for value in trace:
                state = value if state == 0 else state if value == 0 else state+2*value
            target = compact[tuple(output[i] for i in kept)]
            rows.append(dict(profile=profile, output=ordinal, trace=trace, shifted_trace=shifted,
                             source=state, target=target, converted=prod(shifted),
                             converted_target=target+1))
    return axes, counts, rows
