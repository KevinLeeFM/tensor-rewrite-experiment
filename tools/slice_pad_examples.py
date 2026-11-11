"""Check factor parameters by enumerating output positions, never using ceiling division."""
from reduction_window_examples import expected as window_expected


def expected():
    axes=[]
    for n in range(5):
        for outputs in range(5):
            for stride in range(1,4):
                for low in range(-4,5):
                    positions=[o*stride-low for o in range(outputs)]
                    first=sum(x<0 for x in positions)
                    last=sum(x<n for x in positions)
                    valid=[x for x in positions if 0<=x<n]
                    count=len(valid)
                    start=valid[0] if valid else min(n,max(first*stride-low,0))
                    limit=valid[-1]+1 if valid else start
                    assert len(range(start,limit,stride))==count==last-first
                    axes.append(dict(n=n,outputs=outputs,stride=stride,low=low,first=first,last=last,
                                     count=count,start=start,limit=limit,shape=first+count+outputs-last,
                                     legal=True))
    counts,windows=window_expected()
    profiles=[dict(name=c['name'],outputs=c['outputs'],eligible=c['unit_affine']) for c in counts]
    rows=[]
    for w in windows:
        value=w['gather']
        rows.append(dict(name=w['name'],output=w['output'],graph=2*value+7 if value else -9,
                         gather=2*value+7 if value else -9,boolean=bool(value and value%2==0),
                         minimum=min(value,5) if value else 5,maximum=max(value,5) if value else 5,
                         zero_graph=value,zero_window=w['zero']))
    return axes,profiles,rows
