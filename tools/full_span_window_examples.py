"""Independent oracle: filter all original input coordinates by the retained axes."""
from itertools import product
from math import prod


def plans(depth):
    if depth == 0:
        return [()]
    return [((extent, keep),) + tail for extent in range(4)
            for tail in plans(depth - 1) for keep in (True, False)]


def expected():
    counts, rows = [], []
    profiles = [plan for rank in range(4) for plan in plans(rank)]
    for profile, plan in enumerate(profiles):
        original = list(product(*(range(extent) for extent, _ in plan)))
        outputs = list(product(*(range(extent if keep else 1) for extent, keep in plan)))
        counts.append(dict(profile=profile, rank=len(plan), inputs=len(original),
                           outputs=len(outputs), kernels=prod(1 if keep else extent
                                                            for extent, keep in plan)))
        for position, output in enumerate(outputs):
            trace = [value for value, index in enumerate(original, 1)
                     if all(not keep or index[axis] == output[axis]
                            for axis, (_, keep) in enumerate(plan))]
            result = 7
            for value in trace:
                result = 10 * result + value
            rows.append(dict(profile=profile, output=position, trace=trace, fiber=trace,
                             window=result, reshape=result))
    return counts, rows
