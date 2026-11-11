"""Independent dense-array Slice/UpdateSlice oracle with decoded mathematical start values."""
from itertools import product
from math import prod


def coordinates(shape): return list(product(*(range(n) for n in shape)))
def starts(outer, inner, raw): return tuple(max(0,min(s,n-w)) for n,w,s in zip(outer,inner,raw))
def linear(shape, index):
    value=0
    for n,i in zip(shape,index): value=value*n+i
    return value


def profiles():
    yield (),(),()
    for extent in (0,1,2,3):
        for width in range(extent+1):
            for raw in (-2,0,1,5): yield (extent,),(width,),(raw,)
    for a,b in ((2,2),(0,2),(2,0)):
        for x in range(a+1):
            for y in range(b+1):
                for raw in product((-2,0,1,5),repeat=2): yield (a,b),(x,y),raw


def read_window(data, inner, offset):
    return {i:data[tuple(s+x for s,x in zip(offset,i))] for i in coordinates(inner)}


def write_window(base, update, offset):
    result=dict(base)
    for i,value in update.items(): result[tuple(s+x for s,x in zip(offset,i))]=value
    return result


def expected():
    headers,locate,values=[],[],[]
    for domain in ('integer','word8'):
        norm=(lambda x:x) if domain=='integer' else (lambda x:x%256)
        for number,(outer,inner,raw) in enumerate(profiles()):
            offset=starts(outer,inner,raw)
            small=tuple(min(n,1) for n in inner)
            second_raw=tuple(5 if a%2==0 else -1 for a in range(len(inner)))
            second=starts(inner,small,second_raw)
            combined=tuple(x+y for x,y in zip(offset,second))
            assert starts(outer,small,combined)==combined
            limits=tuple(x+n for x,n in zip(offset,inner))
            headers.append((domain,number,outer,inner,raw,offset,limits,combined))
            base={i:norm(13*linear(outer,i)-7) for i in coordinates(outer)}
            update={i:norm(100+3*linear(inner,i)) for i in coordinates(inner)}
            final={i:norm(900+5*linear(small,i)) for i in coordinates(small)}
            pred={i:linear(outer,i)%2==0 for i in base}
            sliced=read_window(base,inner,offset)
            sliced_pred=read_window(pred,inner,offset)
            written=write_window(base,update,offset)
            sparse=write_window({i:0 for i in base},update,offset)
            graph={
                'write':(written,written),
                'zero_axes':(write_window(base,update,starts(outer,inner,tuple(0 if n==w else s for n,w,s in zip(outer,inner,raw)))),written),
                'map':({i:norm(-v) for i,v in written.items()},write_window({i:norm(-v) for i,v in base.items()},{i:norm(-v) for i,v in update.items()},offset)),
                'self':(write_window(base,sliced,offset),base),
                'select_false':({i:base[i] if pred[i] else written[i] for i in base},write_window(base,{j:sliced[j] if sliced_pred[j] else update[j] for j in update},offset)),
                'select_true':({i:written[i] if pred[i] else base[i] for i in base},write_window(base,{j:update[j] if sliced_pred[j] else sliced[j] for j in update},offset)),
                'add_right':({i:norm(base[i]+sparse[i]) for i in base},write_window(base,{j:norm(sliced[j]+update[j]) for j in update},offset)),
                'add_left':({i:norm(sparse[i]+base[i]) for i in base},write_window(base,{j:norm(update[j]+sliced[j]) for j in update},offset)),
                'nested':(write_window(base,write_window(sliced,final,second),offset),write_window(base,final,combined))}
            for p in (False,True):
                graph['scalar_false_'+str(p).lower()]=({i:base[i] if p else written[i] for i in base},write_window(base,{j:sliced[j] if p else update[j] for j in update},offset))
                graph['scalar_true_'+str(p).lower()]=({i:written[i] if p else base[i] for i in base},write_window(base,{j:update[j] if p else sliced[j] for j in update},offset))
            order=('write','zero_axes','map','self','select_false','select_true',
                   'scalar_false_false','scalar_true_false','scalar_false_true','scalar_true_true',
                   'add_right','add_left','nested')
            for position,i in enumerate(base):
                local=tuple(x-s for x,s in zip(i,offset))
                decoded=local if all(0<=x<n for x,n in zip(local,inner)) else None
                locate.append((domain,number,position,decoded))
                for kind in order:
                    left,right=graph[kind]
                    assert left==right,(domain,number,kind)
                    values.append((domain,number,kind,position,left[i],right[i]))
            for position,i in enumerate(coordinates(inner)):
                values.append((domain,number,'slice_update',position,read_window(written,inner,offset)[i],update[i]))
                values.append((domain,number,'static',position,sliced[i],sliced[i]))
                values.append((domain,number,'static_slice_update',position,update[i],update[i]))
                values.append((domain,number,'slice_zero_axes',position,sliced[i],sliced[i]))
            for position,i in enumerate(coordinates(small)):
                left=read_window(sliced,small,second)[i];right=read_window(base,small,combined)[i]
                values.append((domain,number,'compose',position,left,right))
                left=read_window(written,small,combined)[i];right=read_window(update,small,second)[i]
                values.append((domain,number,'static_inside',position,left,right))
                values.append((domain,number,'inside',position,left,right))
    assert all(left==right for _,_,_,_,left,right in values)
    return headers,locate,values
