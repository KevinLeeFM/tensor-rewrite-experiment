"""Source-specific expected graph deltas; no tensor-refinement claim from node counts."""
CASES={'filter_many':(1,'3,7,11,13'),'filter_one':(0,'3,7'),
       'filter_all':(0,'empty'),'unary':(0,'3,7'),'adjacent':(2,'3,7')}


def expected_rows():
    rows=[]
    for name,(allocations,values) in CASES.items():
        for layout in (0,1):
            for profile in ('plain','predecessor','successor'):
                for mode in ('control','handler','pass','fixedpoint'):
                    if profile!='predecessor' and mode=='fixedpoint':continue
                    controlled=profile=='predecessor'
                    steps=3 if controlled and mode=='handler' else 1
                    for step in range(1,steps+1):
                        active=mode!='control' and not (layout and name=='adjacent')
                        replaced=active and not controlled
                        delta=(allocations if controlled else (-3 if profile=='successor' and mode=='pass' else -1) if name=='adjacent' else allocations-1) if active else 0
                        rows.append((name,str(layout),profile,mode,str(step),str(int(replaced)),
                                     str(delta),str(int(not replaced)),values,values))
    return rows
