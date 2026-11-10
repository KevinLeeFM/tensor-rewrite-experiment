"""Unsigned-word and mathematical signed-decoding reference for signed native probes."""
from modular_arithmetic_cases import NAMES as BASE_NAMES
NAMES=BASE_NAMES+('sub_self','sub_zero','sub_constant','neg_neg')


def inputs(width):
    maximum=2**width-1;high=2**(width-1)
    return ([high-1,high,maximum,high+1,high-2,0],
            [1,maximum,2,high-1,3,high],
            [maximum,2,3,high,high-1,1])


def signed(width,word):
    return word if word<2**(width-1) else word-2**width


def values(width,name):
    left,right,shared=inputs(width);result=[]
    for x,y,z in zip(left,right,shared):
        if name in ('add_zero','mul_one','sub_zero','neg_neg'):value=x
        elif name=='add_constant':value=x+2
        elif name=='add_assoc':value=x+5
        elif name=='factor':value=(x+y)*z
        elif name in ('mul_zero','sub_self'):value=0
        elif name=='sub_constant':value=x-3
        elif name=='mul_neg_neg':value=x*y
        elif name=='four_factors':value=x*y*6
        else:raise ValueError(name)
        result.append(value%(2**width))
    return result


def expected_rows():
    return [(dtype,name,mode,str(int(mode!='control')),'6',','.join(map(str,values(width,name))),
             ','.join(str(signed(width,v)) for v in values(width,name)))
            for dtype,width in [('s8',8),('s16',16),('s32',32),('s64',64)] for name in NAMES
            for mode in ('control','handler','pass')]
