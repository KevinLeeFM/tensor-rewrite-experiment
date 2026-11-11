"""Finite exact-integer oracle using full coordinate grids and kept-axis filtering."""
from itertools import product
from math import prod

PROFILES = [
    ('scalar', []),
    ('all_kept', [(2, False), (3, False)]),
    ('all_reduced', [(2, True), (3, True)]),
    ('mixed', [(2, False), (3, True), (2, False), (2, True)]),
    ('leading_reduced', [(3, True), (2, False)]),
    ('empty_fiber', [(2, False), (0, True)]),
    ('empty_output', [(0, False), (3, True)]),
    ('unit_reduced', [(1, True), (2, False), (1, True)]),
    ('mixed_empty', [(0, True), (2, False), (3, True)]),
]


def expected():
    counts=[];rows=[]
    for name, axes in PROFILES:
        outputs=list(product(*(range(n) for n, reduced in axes if not reduced)))
        coordinates=list(product(*(range(n) for n, _ in axes)))
        count=prod(n for n, reduced in axes if reduced)
        counts.append(dict(name=name,outputs=len(outputs),fiber=count))
        for position, output in enumerate(outputs):
            values=[]
            for index in coordinates:
                if tuple(x for x, (_, reduced) in zip(index, axes) if not reduced) != output:
                    continue
                linear=0
                for x, (extent, _) in zip(index, axes):linear=linear*extent+x
                values.append(linear+1)
            assert len(values)==count
            rows.append(dict(name=name,output=position,fiber=values,coords=values,
                             sum=5+sum(values),neg=-sum(values),constant=7+3*count,
                             min=3 if count else 5,max=7 if count else 5))
    return counts,rows
