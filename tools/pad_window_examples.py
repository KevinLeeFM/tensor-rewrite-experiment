"""Independent oracle: materialize the padded tensor, then enumerate outer window positions."""
from itertools import product
from math import prod


# n, low, high, occupied spacing; k, stride, base spacing, kernel spacing, low, high, reversal.
WINDOWS = [(1, 1, 1, 1, 0, 0, False), (3, 1, 1, 1, 1, 1, False),
           (2, 2, 1, 2, -1, 2, False), (2, 1, 2, 1, 2, 1, False),
           (3, 2, 3, 2, -2, 1, True), (0, 2, 2, 1, -1, 0, False)]


def profiles():
    rows = [([(n, low, high, spacing)], [window])
            for n in range(4) for low in range(3) for high in range(3)
            for spacing in range(1, 4) for window in WINDOWS]
    rows.append(([], []))
    rows.extend(([(2, 1, 2, 2), (first % 3, 0, 1, 3)],
                 [WINDOWS[first], WINDOWS[(first + 3) % 6]]) for first in range(6))
    return rows


def span(extent, spacing):
    return 0 if not extent else (extent - 1) * spacing + 1


def coordinates(shape):
    return list(product(*(range(extent) for extent in shape)))


def expected():
    counts, rows = [], []
    for profile, (pads, windows) in enumerate(profiles()):
        inputs = coordinates([p[0] for p in pads])
        padded_shape = [low + span(n, spacing) + high for n, low, high, spacing in pads]
        padded_indices = coordinates(padded_shape)
        materialized = dict.fromkeys(padded_indices, -3)
        for value, index in enumerate(inputs, 1):
            materialized[tuple(low + i * spacing for i, (_, low, _, spacing)
                               in zip(index, pads))] = value
        # A table of the actual padded tensor after the outer base dilation.
        occupied = {tuple(i * w[2] for i, w in zip(index, windows)): value
                    for index, value in materialized.items()}
        output_axes = []
        for padded, w in zip(padded_shape, windows):
            kernel, stride, base, dilation, low, high, _ = w
            room = low + span(padded, base) + high
            output_axes.append([o for o in range(max(room + 1, 0))
                                if o * stride + span(kernel, dilation) <= room])
        outputs = list(product(*output_axes))
        kernels = coordinates([w[0] for w in windows])
        counts.append(dict(profile=profile, rank=len(pads), inputs=len(inputs),
                           padded=len(padded_indices), outputs=len(outputs), fused=len(outputs),
                           kernels=len(kernels)))
        for position, output in enumerate(outputs):
            trace = []
            for kernel in kernels:
                coordinate = tuple(o * w[1] + (w[0] - 1 - k if w[6] else k) * w[3] - w[4]
                                   for o, k, w in zip(output, kernel, windows))
                trace.append(occupied.get(coordinate, -3))
            result, boolean = 7, True
            for value in trace:
                result = 10 * result + value
                boolean = not (boolean and value < 0)
            rows.append(dict(profile=profile, output=position, trace=trace, fused_trace=trace,
                             source=result, target=result, bool_source=boolean, bool_target=boolean))
    return counts, rows
