"""Finite binary32 controls via exact rational arithmetic and nearest-even encoding.

No host floating-point arithmetic is used. Exceptional-value policies are intentionally
outside this small independent oracle; universal stored-value equality is proved in Lean.
"""
from fractions import Fraction

PROFILES = [
    ('finite_order', 0, [0x4b800000,0x3f800000,0xcb800000], [0x3f800000]*3),
    ('finite_reverse', 0, [0xcb800000,0x3f800000,0x4b800000], [0x3f800000]*3),
    ('negative_zero', 0, [0x80000000], [0x3f800000]),
    ('negative_initial', 0x80000000, [0x80000000], [0x3f800000]),
    ('empty_negative_initial', 0x80000000, [], []),
    ('subnormals', 0, [1,2], [0x3f800000]*2),
    ('normal_boundary', 0, [0x007fffff,1], [0x3f800000]*2),
    ('zero_negative_product', 0, [0], [0xbf800000]),
    ('half_ulp', 0, [0x3f800000,0x33800000], [0x3f800000]*2),
    ('two_half_ulps', 0, [0x3f800000,0x33800000,0x33800000], [0x3f800000]*3),
    ('max_finite', 0, [0x7f7fffff], [0x3f800000]),
    ('mixed_products', 0, [0x3f000000,0xbf000000,0x3f800000],
     [0x40000000,0x40000000,0x3f800000]),
]


def power_two(exponent):
    return Fraction(2**exponent) if exponent >= 0 else Fraction(1,2**-exponent)


def decode(word):
    assert 0 <= word < 2**32
    exponent = (word >> 23) & 255; fraction = word & 0x7fffff
    if exponent == 255:
        raise ValueError('independent oracle accepts finite binary32 only')
    mantissa = fraction if exponent == 0 else 2**23+fraction
    scale = -149 if exponent == 0 else exponent-150
    return (-1 if word >> 31 else 1)*mantissa*power_two(scale)


def nearest_integer(value):
    quotient, remainder = divmod(value.numerator,value.denominator)
    twice = 2*remainder
    return quotient+(twice > value.denominator or
                     (twice == value.denominator and quotient % 2 == 1))


def encode(value, zero_negative=False):
    if value == 0:
        return 0x80000000 if zero_negative else 0
    sign = 0x80000000 if value < 0 else 0
    value = abs(value)
    exponent = value.numerator.bit_length()-value.denominator.bit_length()
    if value < power_two(exponent):
        exponent -= 1
    quantum = max(-149,exponent-23)
    mantissa = nearest_integer(value/power_two(quantum))
    if mantissa == 0:
        return sign
    if mantissa < 2**23:
        return sign | mantissa
    if mantissa >= 2**24:
        mantissa //= 2
        quantum += 1
    encoded_exponent = quantum+150
    if encoded_exponent >= 255:
        return sign | 0x7f800000
    return sign | (encoded_exponent << 23) | (mantissa-2**23)


def multiply(left,right):
    return encode(decode(left)*decode(right),bool((left ^ right) >> 31))


def add(left,right):
    # Under nearest-even, only adding two negative zeros gives an exact negative zero.
    return encode(decode(left)+decode(right),bool((left & right) >> 31))


def expected_rows():
    rows=[]
    for name, initial, values, weights in PROFILES:
        assert len(values)==len(weights)
        result=initial
        for value,weight in zip(values,weights):
            result=add(result,multiply(value,weight))
        rows.append((name,str(result),str(result),str(result)))
    return rows
