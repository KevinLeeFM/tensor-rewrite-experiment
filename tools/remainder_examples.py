"""Independent integer arithmetic and exact-rational binary32 controls; no host float or Lean decoder."""
from itertools import product
from math import prod
from fractions import Fraction
from ordered_float_examples import add, multiply, encode


def signed(value, width):
    if width == 0: return 0
    modulus = 2**width
    return value if value < modulus//2 else value-modulus


def trunc_rem(value, divisor):
    if divisor == 0: return value
    remainder = abs(value) % abs(divisor)
    return -remainder if value < 0 else remainder


def unsigned_rem(value, divisor):
    return value if divisor == 0 else value % divisor


def expected():
    pairs, integers, counts, rows, floats = [], [], [], [], []
    for width in range(7):
        modulus = 2**width
        for x in range(modulus):
            for y in range(modulus):
                sx, sy = signed(x,width), signed(y,width)
                u, s = unsigned_rem(x,y), trunc_rem(sx,sy)
                magnitude = (-x)%modulus if sx < 0 else x
                masked = magnitude & ((y-1)%modulus)
                target = (-masked)%modulus if sx < 0 else masked
                pairs.append(dict(width=width,x=x,y=y,unsigned=u,signed=s,
                                  unsigned_nested=unsigned_rem(u,y),signed_nested=trunc_rem(s,sy),
                                  unsigned_mask=x & ((y-1)%modulus),signed_mask=signed(target,width),
                                  unsigned_offset=unsigned_rem((x+y)%modulus,y),
                                  signed_offset=trunc_rem(signed((x+y)%modulus,width),sy)))
    for x in range(-9,10):
        for y in range(-9,10):
            value = trunc_rem(x,y)
            integers.append(dict(x=x,y=y,remainder=value,nested=trunc_rem(value,y)))
    profiles = [(width,shape,axis,divisor) for width in (0,1,2,4) for rank in (1,2,3)
                for shape in product(range(3),repeat=rank) for axis in range(rank)
                for divisor in range(2**width)]
    profiles += [(4,(8,),0,3),(4,(8,),0,10),(4,(6,),0,3),(4,(0,8),1,10)]
    for profile,(width,shape,axis,divisor) in enumerate(profiles):
        modulus = 2**width
        points = list(product(*(range(n) for n in shape)))
        divisor_nonnegative = signed(divisor,width) >= 0
        counts.append(dict(profile=profile,width=width,shape=list(shape),axis=axis,divisor=divisor,
                           outputs=prod(shape),unsigned_bound=shape[axis] <= divisor,
                           signed_bound=divisor_nonnegative and shape[axis] <= divisor,
                           unsigned_offset=all(p[axis]+divisor < modulus for p in points),
                           signed_offset=divisor_nonnegative and
                           all(2*(p[axis]+divisor) < modulus for p in points)))
        for output,point in enumerate(points):
            coordinate = point[axis]
            value, signed_value = coordinate%modulus, signed(coordinate%modulus,width)
            remainder_u = unsigned_rem(value,divisor)
            remainder_s = trunc_rem(signed_value,signed(divisor,width))
            offset = (value+divisor)%modulus
            rows.append(dict(profile=profile,output=output,coordinate=coordinate,value=value,
                             signed_value=signed_value,unsigned=remainder_u,signed=remainder_s,
                             unsigned_rhs=unsigned_rem(offset,divisor),
                             unsigned_lhs=unsigned_rem(offset,divisor),
                             signed_rhs=trunc_rem(signed(offset,width),signed(divisor,width)),
                             signed_lhs=trunc_rem(signed(offset,width),signed(divisor,width))))
    for word in (0,0x80000000,0x3dcccccd,1,0x3f800000):
        for count in (1,2,3,7,8,10):
            result = 0
            for _ in range(count): result=add(result,word)
            count_word=encode(Fraction(count))
            floats.append(dict(word=word,count=count,count_word=count_word,fold=result,
                               product=multiply(word,count_word)))
    return pairs,integers,counts,rows,floats
