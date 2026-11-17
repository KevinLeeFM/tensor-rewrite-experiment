import random,math,collections
rng=random.Random(20261117); stats=collections.Counter();fail=[]
def unpack(shape,n):
 a=[0]*len(shape)
 for i in range(len(shape)-1,-1,-1): a[i]=n%shape[i];n//=shape[i]
 assert n==0
 return a
def pack(shape,x):
 n=0
 for d,v in zip(shape,x):assert 0<=v<d;n=n*d+v
 return n
for _ in range(4000):
 rank=rng.randrange(2,7); split=rng.randrange(1,rank); moved=rng.randrange(split); count=rng.randrange(1,6); width=rng.choice([0,2,3,4]);shape=[rng.randrange(4) for i in range(rank)];shape[split]=count*width
 inner=shape[:split]+[count,width]+shape[split+1:];perm=list(range(rank+1));perm.insert(moved,perm.pop(split)); trans=[inner[i] for i in perm];chunks=shape.copy();chunks[split]=width;chunks[moved]*=count
 outer=[(shape[j]*count if moved>0 and j+1==moved else shape[j]//count if j==split else shape[j]) for j in range(rank)]
 # Well-formed outer count is an explicit frozen premise; m=0 often excludes nonempty cases.
 if math.prod(shape)!=math.prod(outer):stats['outer_count_rejected']+=1;continue
 assert math.prod(shape)==math.prod(inner)==math.prod(trans)==math.prod(chunks)
 if rng.randrange(2):outer += [1]*rng.randrange(1,4)
 stats['plans']+=1;stats['empty' if not math.prod(outer) else 'nonempty']+=1;stats[('empty' if not math.prod(outer) else 'nonempty')+'_count_'+('one' if count==1 else 'many')]+=1;stats['one_chunk' if count==1 else 'many_chunks']+=1;stats['zero_width' if width==0 else 'positive_width']+=1;stats['moved_zero' if moved==0 else 'moved_positive']+=1;stats['rank_'+str(rank)]+=1;stats['outer_higher_rank' if len(outer)>rank else 'outer_same_rank']+=1
 for n in (list(range(math.prod(outer))) if math.prod(outer)<=12 else [0,math.prod(outer)-1]+[rng.randrange(math.prod(outer)) for x in range(10)]):
  t=unpack(trans,n);x=[0]*(rank+1)
  for j,k in enumerate(perm):x[k]=t[j]
  original=unpack(shape,pack(inner,x));z=unpack(chunks,n);block=z[moved]//shape[moved];local=z[moved]%shape[moved];replacement=z.copy();replacement[moved]=local;replacement[split]=block*width+z[split]
  stats['coordinates']+=1
  if original!=replacement:fail.append(dict(shape=shape,inner=inner,outer=outer,perm=perm,n=n,original=original,replacement=replacement));break
print(dict(stats));print('mismatches',len(fail),fail[:2]);assert not fail
