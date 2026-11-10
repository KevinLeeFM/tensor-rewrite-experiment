"""Expected Boolean observations for the strict NaN-aware comparison diagnostic."""
KINDS=('abs','exp','square','maximum','parameter')
DIRECTIONS=('GE','LE','LT','GT')
MODES=('control','handler','pass')


def expected_rows():
    rows=[]
    for kind in KINDS:
        for direction in DIRECTIONS:
            true_fold=direction in ('GE','LE')
            before=([0,0,1,1,1,0] if true_fold else [0,1,0,0,0,1]) if kind=='parameter' else [0]+[int(true_fold)]*5
            for mode in MODES:
                changed=kind!='parameter' and mode!='control'
                after=[int(true_fold)]*6 if changed else before
                rows.append((kind,direction,mode,str(int(changed)),','.join(map(str,before)),','.join(map(str,after))))
    return rows
