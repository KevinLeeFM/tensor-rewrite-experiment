"""Independent controls: enumerate original coordinates, filter inclusive prefixes, and wrap words."""
from itertools import product
from math import prod


def configurations(rank):
    if not rank:
        return [((), ())]
    return [((extent,) + shape, (stride,) + strides)
            for extent in range(3) for stride in range(1, 3)
            for shape, strides in configurations(rank - 1)]


def plans(rank):
    if not rank:
        return []
    scanned = [((extent,) + shape, (1,) + strides, 0)
               for extent in range(6) for shape, strides in configurations(rank - 1)]
    kept = [((extent,) + shape, (stride,) + strides, scan + 1)
            for extent in range(3) for stride in range(1, 3)
            for shape, strides, scan in plans(rank - 1)]
    return scanned + kept


def coordinate_list(shape):
    return list(product(*(range(extent) for extent in shape)))


def fold_decimal(values, initial):
    for value in values:
        initial = 10 * initial + value
    return initial


def expected():
    counts, rows, conversions = [], [], []
    profiles = [plan for rank in range(1, 4) for plan in plans(rank)]
    for profile, (shape, strides, scan) in enumerate(profiles):
        original = dict(zip(coordinate_list(shape), range(1, prod(shape) + 1)))
        output_axes = [list(range(extent)) if axis == scan else
                       [o for o in range(extent + 1) if o * strides[axis] < extent]
                       for axis, extent in enumerate(shape)]
        outputs = list(product(*output_axes))
        counts.append(dict(profile=profile, rank=len(shape), scan=shape[scan],
                           inputs=len(original), outputs=len(outputs), kernels=shape[scan]))
        for position, output in enumerate(outputs):
            prefix = [value for index, value in original.items() if index[scan] <= output[scan]
                      and all(axis == scan or index[axis] == output[axis] * strides[axis]
                              for axis in range(len(shape)))]
            trace = []
            for kernel in range(shape[scan]):
                index = tuple(output[axis] + kernel - (shape[axis] - 1) if axis == scan
                              else output[axis] * strides[axis] for axis in range(len(shape)))
                trace.append(original.get(index, 2))
            count = len(prefix)
            raw = count % 4
            rows.append(dict(profile=profile, output=position, index=output[scan],
                             padding=len(trace) - count, trace=trace, prefix=prefix,
                             source=fold_decimal(trace, 7), factor=fold_decimal(trace, 7),
                             neutral=fold_decimal(prefix, 0), prefix_fold=fold_decimal(prefix, 0),
                             count=count, product2=3 * count % 4,
                             product32=3 * count % 2**32, product64=3 * count % 2**64,
                             count2u=raw, count2s=raw if raw < 2 else raw - 4))
    for width in (0, 1, 2, 3, 8, 32, 64):
        modulus, half = 2**width, 2**max(width - 1, 0)
        probes = (0, 1, half - 1, half, half + 1, modulus - 1, modulus, modulus + 1)
        for count in dict.fromkeys(probes):
            raw = count % modulus
            conversions.append(dict(width=width, count=count, unsigned=raw,
                                    signed=raw if 2 * raw < modulus else raw - modulus))
    return counts, rows, conversions
