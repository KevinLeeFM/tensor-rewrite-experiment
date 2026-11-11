"""Independent rational and dense-coordinate controls; no compiler/source inspection."""
from fractions import Fraction
from itertools import product
from math import prod

RULES = ('one', 'reciprocal', 'fractions', 'nested_numerator', 'nested_denominator',
         'constant', 'product', 'predicate_false', 'predicate_true')
SHAPES = (([2], [3, 2], [1]), ([2], [0, 2], [1]), ([], [2, 2], []),
          ([2, 3], [3, 2], [1, 0]), ([0], [0, 3], [0]))
SYMBOLIC = ('zero_power_zero', 'negative_cube', 'negative_half', 'negative_inverse_square',
            'quotient_zero', 'principal_negative_root', 'principal_square_real',
            'log_upper_endpoint', 'log_lower_endpoint', 'empty_sqrt_square')


def reciprocal(value):
    return Fraction(1, value) if value else Fraction(0)


def divide(left, right):
    return left * reciprocal(right)


def field_rows():
    rows = []
    for sample, values in enumerate(product(range(-2, 3), repeat=4)):
        a, b, c, d = map(Fraction, values)
        left = (divide(a, 1), divide(a, divide(1, b)), divide(divide(a, b), divide(c, d)),
                divide(divide(a, b), c), divide(a, divide(b, c)), divide(a, b),
                divide(a, b), divide(0, b), divide(1, b))
        right = (a, a*b, divide(a*d, b*c), divide(a, b*c), divide(a*c, b),
                 a*divide(1, b), a*divide(1, b), divide(1, b)*0, divide(1, b)*1)
        assert left == right
        rows.append((sample, values, left, right))
    return rows


def linearize(shape, coordinate):
    result = 0
    for extent, value in zip(shape, coordinate):
        assert 0 <= value < extent
        result = result * extent + value
    return result


def graph_rows():
    counts, rows = [], []
    for scenario, (small, output, axes) in enumerate(SHAPES):
        counts.append((scenario, small, output, axes))
        coordinates = list(product(*(range(extent) for extent in output)))
        assert len(coordinates) == prod(output)
        for position, coordinate in enumerate(coordinates):
            low = tuple(coordinate[axis] for axis in axes)
            denominator = Fraction(linearize(small, low) - 1)
            numerator = Fraction(position - 2)
            value = divide(numerator, denominator)
            rows.append((scenario, position, 'divide', value, value))
            for predicate in (False, True):
                value = divide(int(predicate), denominator)
                rows.append((scenario, position, 'predicate'+str(predicate).lower(), value, value))
    return counts, rows
