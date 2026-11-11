"""Independent occupied-coordinate window oracle and separate logical reshape/Broadcast graph."""
from itertools import product
from math import prod
from ordered_float_examples import add


def span(extent, spacing):
    return 0 if not extent else (extent - 1) * spacing + 1


def coordinates(shape):
    return list(product(*(range(extent) for extent in shape)))


def axis(kernel, stride=1, base=1, low=0, high=0, reversed=False, n=1, kept=False, dilation=1):
    return dict(kernel=kernel, stride=stride, base=base, low=low, high=high,
                reversed=reversed, n=n, kept=kept, dilation=dilation)


def outputs(a):
    room = a['low'] + span(a['n'], a['base']) + a['high']
    kernel = span(a['kernel'], a['dilation'])
    return [o for o in range(max(room + 1, 0)) if o * a['stride'] + kernel <= room]


def axis_profiles():
    return [axis(k, s, b, low, high, rev) for k in range(5) for s in range(1, 4)
            for b in range(1, 3) for low in range(-2, 7) for high in range(-2, 5)
            for rev in (False, True)]


def eligibility(a):
    return all(sum(o * a['stride'] + (a['kernel']-1-k if a['reversed'] else k) == a['low']
                   for k in range(a['kernel'])) == 1 for o in outputs(a))


def extra_profiles():
    pair = axis(2, base=3, low=1, high=1, reversed=True)
    triple = axis(3, base=2, low=2, high=2)
    keep = lambda n: axis(1, n=n, kept=True)
    return [[], [keep(0)], [keep(3)], [keep(3), pair], [pair, keep(3)],
            [pair, keep(0)], [pair, triple], [pair, keep(2), triple],
            [axis(1, n=3, kept=True, dilation=5, reversed=True), pair]]


def expected():
    axes, counts, rows = [], [], []
    candidates = axis_profiles()
    for profile, a in enumerate(candidates):
        axes.append(dict(profile=profile, kernel=a['kernel'], stride=a['stride'], base=a['base'],
                         low=a['low'], high=a['high'], reversed=a['reversed'],
                         outputs=len(outputs(a)), eligible=eligibility(a)))
    profiles = [[a] for a in candidates if eligibility(a)] + extra_profiles()
    for profile, geometry in enumerate(profiles):
        original = dict(zip(coordinates([a['n'] for a in geometry]),
                            range(1, prod(a['n'] for a in geometry) + 1)))
        kept_axes = [i for i, a in enumerate(geometry) if a['kept']]
        compact_shape = [geometry[i]['n'] for i in kept_axes]
        compact = dict(zip(coordinates(compact_shape), original.values()))
        occupied = {tuple(i * a['base'] for i, a in zip(index, geometry)): value
                    for index, value in original.items()}
        output_coordinates = list(product(*(outputs(a) for a in geometry)))
        kernels = coordinates([a['kernel'] for a in geometry])
        counts.append(dict(profile=profile, rank=len(geometry), inputs=len(original),
                           outputs=len(output_coordinates), kernels=len(kernels),
                           compact_rank=len(kept_axes), axes=kept_axes))
        for position, output in enumerate(output_coordinates):
            trace = []
            for kernel in kernels:
                point = tuple(o * a['stride'] +
                              (a['kernel']-1-k if a['reversed'] else k) * a['dilation'] - a['low']
                              for a, o, k in zip(geometry, output, kernel))
                trace.append(occupied.get(point, 0))
            live = [i for i, value in enumerate(trace) if value]
            assert len(live) == 1
            state, boolean = 0, False
            for value in trace:
                state = value if state == 0 else state if value == 0 else state + 2*value
                boolean = boolean != (value % 2 == 0 and value != 0)
            target = compact[tuple(output[i] for i in kept_axes)]
            rows.append(dict(profile=profile, output=position, trace=trace, live=live[0],
                             source=state, target=target, bool_source=boolean,
                             bool_target=target % 2 == 0))
    tuple_geometries = [('scalar', []), ('covered', [axis(2, base=3, low=1, high=1, reversed=True)]),
                       ('empty_kernel', [axis(0, low=1, high=1)]),
                       ('empty_output', [axis(1, low=-2)]),
                       ('nontrivial', [axis(2, n=3, stride=2, base=2, dilation=2,
                                            low=2, high=1, reversed=True)])]
    tuple_counts, tuples = [], []
    for name, geometry in tuple_geometries:
        original = dict(zip(coordinates([a['n'] for a in geometry]),
                            range(1, prod(a['n'] for a in geometry) + 1)))
        occupied = {tuple(i*a['base'] for i, a in zip(index, geometry)): value
                    for index, value in original.items()}
        output_coordinates = list(product(*(outputs(a) for a in geometry)))
        tuple_counts.append(dict(name=name, outputs=len(output_coordinates)))
        for position, output in enumerate(output_coordinates):
            result = 7
            for kernel in coordinates([a['kernel'] for a in geometry]):
                point = tuple(o*a['stride'] +
                              (a['kernel']-1-k if a['reversed'] else k)*a['dilation']-a['low']
                              for a, o, k in zip(geometry, output, kernel))
                result = 10*result + occupied.get(point, -3)
            tuples.append(dict(name=name, output=position, source=result, target=result,
                               scalar=result, shifted=result+1))
    float_profiles = [('finite_order', 0, [0x4b800000, 0x3f800000, 0xcb800000]),
                      ('finite_reverse', 0, [0xcb800000, 0x3f800000, 0x4b800000]),
                      ('negative_zero', 0, [0x80000000]),
                      ('negative_initial', 0x80000000, [0x80000000]),
                      ('empty_negative_initial', 0x80000000, []), ('subnormals', 0, [1, 2]),
                      ('half_ulp', 0, [0x3f800000, 0x33800000]),
                      ('padded_negative_zero', 0x80000000, [0, 0x80000000, 0])]
    floats = []
    for name, result, values in float_profiles:
        for value in values:
            result = add(result, value)
        floats.append(dict(name=name, source=result, target=result))
    return axes, counts, rows, tuple_counts, tuples, floats
