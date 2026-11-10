"""Independent bounded reference for reducer role and index-literal diagnostics."""
GATHER=[('s8_wrap_zero',True,129,129,0),('s8_wrap_negative',True,129,129,-1),
        ('s8_wrap_max',True,129,129,127),('s8_extent128',True,128,128,127),
        ('s8_threshold128',True,129,128,0),('s8_default4',True,129,4,0),
        ('s32_zero',False,129,129,0),('s32_high',False,129,129,200),
        ('s32_negative',False,129,129,-1)]


def expected_rows():
    rows=[]
    for roles in ('00','11','01','10'):
        update=lambda old,new:sum((old,new)[int(role)] for role in roles)
        for side in ('rhs','lhs'):
            for layout in (0,1):
                before=[1+update(3,5),4]
                for mode in ('control','handler','pass'):
                    active=mode!='control' and not layout
                    after=[update(1+3,5),4] if active else before
                    rows.append(('scatter','p'+roles+'_'+side+'_layout'+str(layout),mode,str(int(active)),','.join(map(str,before)),','.join(map(str,after))))
    for name,narrow,extent,threshold,index in GATHER:
        before=max(0,min(extent-1,index))
        for mode in ('control','handler','pass'):
            active=mode!='control' and extent<=threshold
            after=128 if active and narrow and extent==129 else before
            rows.append(('gather',name,mode,str(int(active)),str(before),str(after)))
    return rows
