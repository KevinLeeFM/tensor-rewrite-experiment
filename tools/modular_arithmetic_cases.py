"""Independent integer-modulo reference for the bounded unsigned native/model probes."""
NAMES=('add_zero','add_constant','add_assoc','factor','mul_zero','mul_one','mul_neg_neg','four_factors')


def values(width,name):
    maximum=2**width-1;high=2**(width-1)
    left=[0,1,maximum,high,maximum-1,3]
    right=[maximum,2,3,high,4,maximum]
    shared=[maximum,1,2,3,high,maximum-1]
    result=[]
    for x,y,z in zip(left,right,shared):
        if name in ('add_zero','mul_one'):value=x
        elif name=='add_constant':value=x+2
        elif name=='add_assoc':value=x+5
        elif name=='factor':value=(x+y)*z
        elif name=='mul_zero':value=0
        elif name=='mul_neg_neg':value=x*y
        elif name=='four_factors':value=x*y*6
        else:raise ValueError(name)
        result.append(value%(2**width))
    return result


def expected_rows():
    return [(dtype,name,mode,str(int(mode!='control')),'6',','.join(map(str,values(width,name))))
            for dtype,width in [('u8',8),('u32',32),('u64',64)] for name in NAMES
            for mode in ('control','handler','pass')]
