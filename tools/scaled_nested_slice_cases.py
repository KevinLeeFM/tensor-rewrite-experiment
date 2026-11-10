"""Independent bounded coordinate/product reference for the failed-Iota continuation."""
PROFILES=[('scaled',7,1,True,True,False),('negative_multiplier',-3,1,True,True,False),
          ('one_multiplier',1,1,True,True,False),('zero_multiplier',0,1,True,True,False),
          ('reversed',7,1,False,False,False),('outer_two',7,2,False,False,False),
          ('s64_result',7,1,False,False,False),('direct_nested',1,1,False,True,False),
          ('constant_starts',7,1,False,True,False),
          ('constant_starts_disabled',7,1,True,True,False),
          ('intended_iota',7,1,False,True,True)]


def expected_rows():
    rows=[]
    for name,multiplier,width,drops,changed,iota in PROFILES:
        selected=[(2 if iota else 4)+i for i in range(width)]
        before=[x*multiplier for x in selected]
        for mode in ('control','handler','pass'):
            active=mode!='control'
            after=selected if active and drops else before
            rows.append((name,mode,str(int(active and changed)),','.join(map(str,before)),','.join(map(str,after))))
    return rows
