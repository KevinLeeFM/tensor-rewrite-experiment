"""Independent modulo/index reference for operand-order and broadcast native probes."""

def recipes():
    rows=[]
    for left in range(2):
        for right in range(2):rows.append(('factor_'+str(left)+str(right),'factor',left,right,0,0))
    for inner in range(2):
        for outer in range(2):rows.append(('product_'+str(inner)+str(outer),'product',inner,0,outer,0))
    for left in range(2):
        for right in range(2):
            for outer in range(2):rows.append(('four_'+str(left)+str(right)+str(outer),'four',left,right,outer,0))
    for axis in range(2):
        for inner in range(2):
            for outer in range(2):rows.append(('move_'+str(axis)+'_'+str(inner)+str(outer),'move',inner,0,outer,axis))
    rows += [(n,n,0,0,0,0) for n in ('add_broadcast','subadd_broadcast','mul_broadcast','guard_vector_constant','guard_nonbroadcast')]
    return rows


def values(width,family,axis):
    maximum=2**width-1;high=2**(width-1)
    left=[0,1,maximum,high];right=[maximum,2,3,high];shared=[maximum,1,2,3];small=[maximum,3]
    result=[]
    for index,(x,y,z) in enumerate(zip(left,right,shared)):
        b=small[index//2 if axis==0 else index%2]
        if family=='factor':value=(x+y)*z
        elif family in ('product','mul_broadcast'):value=x*6
        elif family=='four':value=x*y*6
        elif family=='move':value=x*b*2
        elif family=='add_broadcast':value=x+5
        elif family=='subadd_broadcast':value=5-x
        elif family=='guard_vector_constant':value=x*[2,3,4,5][index]*b
        elif family=='guard_nonbroadcast':value=x*2*y
        else:raise ValueError(family)
        result.append(value%(2**width))
    return result


def expected_rows():
    return [(dtype,name,mode,str(int(mode!='control' and not family.startswith('guard_'))),'4',','.join(map(str,values(width,family,axis))))
        for dtype,width in [('u8',8),('u32',32),('u64',64)] for name,family,*_,axis in recipes()
        for mode in ('control','handler','pass')]
