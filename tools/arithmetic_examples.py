"""Independent arithmetic trees, dense Broadcast graphs and finite exact/modular controls."""
from itertools import product
from functools import lru_cache

SAMPLES=[[0,0,0,0],[1,1,1,1],[-1,-1,-1,-1],[1,2,3,4],[-1,2,-3,4],
 [0,1,-1,2],[7,1,3,5],[15,1,7,9],[255,1,-1,2],[-256,257,3,-5],
 [16777216,1,-16777216,3],[3,5,7,11],[-2,-1,0,1],[1,0,0,0],
 [0,1,0,0],[0,0,1,0],[0,0,0,1],[2,3,5,7],[8,8,8,8],[127,128,255,-128]]
DOMAINS=('integer','real','complex','word_all_widths')
BASE_LABELS={
 'neg_neg':['HandleNegate/involution'],
 'add_zero_left':['HandleAdd/lhs-zero'],'add_zero_right':['HandleAdd/rhs-zero'],
 'add_comm':['HandleAdd/constant-right'],
 'add_cancel_left':['HandleAdd/cancel-subtract-lhs'],
 'add_cancel_right':['HandleAdd/cancel-subtract-rhs'],
 'sub_self':['HandleSubtract/self'],'sub_zero':['HandleSubtract/zero'],
 'sub_neg':['HandleSubtract/constant','HandleSubtract/broadcast-constant'],
 'sub_sub_same':['HandleSubtract/sub-sub-self'],
 'sub_add_same_left':['HandleSubtract/sub-add-self-left'],
 'sub_add_same_right':['HandleSubtract/sub-add-self-right'],
 'add_sub_same_left':['HandleSubtract/add-sub-self-left'],
 'add_sub_same_right':['HandleSubtract/add-sub-self-right'],
 'mul_one_left':['HandleMultiply/lhs-one'],'mul_one_right':['HandleMultiply/rhs-one'],
 'mul_zero_left':['HandleMultiply/lhs-zero'],'mul_zero_right':['HandleMultiply/rhs-zero'],
 'mul_neg_both':['HandleMultiply/negated-operands']}


def trees():
    def op(name,a,b):return a+' '+b+' '+name
    def ordered(name,reverse,a,b):return op(name,b,a) if reverse else op(name,a,b)
    pairs=[('neg_neg','x0 neg neg','x0'),('add_zero_left','zero x0 add','x0'),
      ('add_zero_right','x0 zero add','x0'),('add_comm','x0 x1 add','x1 x0 add'),
      ('add_cancel_left','x1 x0 sub x0 add','x1'),('add_cancel_right','x0 x1 x0 sub add','x1'),
      ('sub_self','x0 x0 sub','zero'),('sub_zero','x0 zero sub','x0'),
      ('sub_neg','x0 x1 sub','x0 x1 neg add'),('sub_sub_same','x0 x0 x1 sub sub','x1'),
      ('sub_add_same_left','x0 x0 x1 add sub','x1 neg'),
      ('sub_add_same_right','x0 x1 x0 add sub','x1 neg'),
      ('add_sub_same_left','x0 x1 add x0 sub','x1'),
      ('add_sub_same_right','x1 x0 add x0 sub','x1'),
      ('mul_one_left','one x0 mul','x0'),('mul_one_right','x0 one mul','x0'),
      ('mul_zero_left','zero x0 mul','zero'),('mul_zero_right','x0 zero mul','zero'),
      ('mul_neg_both','x0 neg x1 neg mul','x0 x1 mul')]
    for inner,outer in product(range(2),repeat=2):
        pairs.append((f'add_assoc_{inner}{outer}',ordered('add',outer,
            ordered('add',inner,'x0','x1'),'x2'),'x0 x1 x2 add add'))
    for outer in range(2):pairs.append((f'sub_add_constants_{outer}',
        ordered('add',outer,'x0 x1 sub','x2'),'x0 x2 add x1 sub'))
    for inner,outer in product(range(2),repeat=2):
        pairs.append((f'mul_assoc_{inner}{outer}',ordered('mul',outer,
            ordered('mul',inner,'x0','x1'),'x2'),'x0 x1 x2 mul mul'))
    for outer,left,right in product(range(2),repeat=3):
        pairs.append((f'four_factors_{outer}{left}{right}',ordered('mul',outer,
            ordered('mul',left,'x0','x2'),ordered('mul',right,'x1','x3')),'x0 x1 mul x2 x3 mul mul'))
    for left,right in product(range(2),repeat=2):pairs.append((f'factor_{left}{right}',
        op('add',ordered('mul',left,'x0','x2'),ordered('mul',right,'x1','x2')),'x0 x1 add x2 mul'))
    for reverse in range(2):pairs.append((f'predicate_multiply_{reverse}',
        ordered('mul',reverse,'p0','x0'),'x0 zero sel0'))
    return [dict(key=k,lhs=l,rhs=r) for k,l,r in pairs]


def labels(key):
    if key in BASE_LABELS:return BASE_LABELS[key]
    if key.startswith('add_assoc_'):return ['HandleAdd/constant-sum-direct-constants','HandleAdd/constant-sum-broadcast-scalars']
    if key.startswith('sub_add_constants_'):return ['HandleAdd/constant-subtract-direct-constants','HandleAdd/constant-subtract-broadcast-scalars']
    if key.startswith('mul_assoc_'):return ['HandleMultiply/constant-product','HandleMultiply/legacy-constant-product-direct','HandleMultiply/legacy-constant-product-broadcast-scalars']
    if key.startswith('four_factors_'):return ['HandleMultiply/four-factors']
    if key.startswith('factor_'):
        left,right=key[-2:];return ['HandleAdd/factor-'+('lhs' if left=='1' else 'rhs')+'-'+('lhs' if right=='1' else 'rhs')]
    if key.startswith('predicate_multiply_'):return ['HandleMultiply/predicate-convert']
    raise AssertionError(key)


def evaluate(expression,inputs,predicate,width=None):
    stack=[];normalize=(lambda x:x) if width is None else (lambda x:x%(1<<width))
    for token in expression.split():
        if token.startswith('x'):stack.append(normalize(inputs[int(token[1:])]))
        elif token=='zero':stack.append(0)
        elif token=='one':stack.append(normalize(1))
        elif token.startswith('p'):stack.append(normalize(int(predicate)))
        elif token=='neg':stack.append(normalize(-stack.pop()))
        else:
            b,a=stack.pop(),stack.pop()
            stack.append(normalize(a+b if token=='add' else a-b if token=='sub' else a*b
                         if token=='mul' else a if predicate else b))
    assert len(stack)==1
    return stack[0]


@lru_cache(maxsize=1)
def expected():
    rules=trees();profiles=[dict(domain=domain,key=r['key']) for r in rules for domain in DOMAINS]
    values=[]
    def emit(domain,width,samples):
        for number,inputs in enumerate(samples):
            for predicate in (False,True):
                for rule in rules:
                    values.append(dict(domain=domain,width=width,sample=number,values=list(inputs),
                      predicate=predicate,key=rule['key'],lhs=evaluate(rule['lhs'],inputs,predicate,
                      None if domain=='integer' else width),rhs=evaluate(rule['rhs'],inputs,predicate,
                      None if domain=='integer' else width)))
    emit('integer',0,SAMPLES)
    for width in (0,1,2):emit('word',width,product(range(1<<width),repeat=4))
    for width in (4,8):emit('word',width,SAMPLES)
    graph_counts=[];graphs=[]
    scenarios=[([2],[3,2],[1]),([2],[0,2],[1]),([],[2,2],[]),([2,3],[3,2],[1,0]),([0],[0,3],[0])]
    for domain,width in (('integer',0),('word',3)):
        norm=(lambda x:x) if domain=='integer' else (lambda x:x%(1<<width))
        for scenario,(small,output,axes) in enumerate(scenarios):
            graph_counts.append(dict(domain=domain,width=width,scenario=scenario,small=small,output=output,axes=axes))
            small_positions={p:i for i,p in enumerate(product(*(range(n) for n in small)))}
            for position,coordinate in enumerate(product(*(range(n) for n in output))):
                p=small_positions[tuple(coordinate[a] for a in axes)]
                x=norm(5*position-3);a=norm(2*p-2);b=norm(3-p);c=norm(-3)
                def emit_graph(rule,inner,outer,left,right):
                    graphs.append(dict(domain=domain,width=width,scenario=scenario,output=position,
                        rule=rule,inner=bool(inner),outer=bool(outer),lhs=norm(left),rhs=norm(right)))
                emit_graph(0,False,False,x-a,x+norm(-a))
                for inner,outer in product((False,True),repeat=2):
                    ordered=lambda a,b,reverse: (b,a) if reverse else (a,b)
                    t=norm(sum(ordered(x,a,inner)))
                    emit_graph(1,inner,outer,sum(ordered(t,b,outer)),x+norm(a+b))
                    if not inner:emit_graph(2,False,outer,sum(ordered(norm(a-x),b,outer)),norm(a+b)-x)
                    t=norm(ordered(x,a,inner)[0]*ordered(x,a,inner)[1])
                    emit_graph(3,inner,outer,ordered(t,b,outer)[0]*ordered(t,b,outer)[1],x*norm(a*b))
                    t=norm(ordered(x,c,inner)[0]*ordered(x,c,inner)[1])
                    emit_graph(4,inner,outer,ordered(t,a,outer)[0]*ordered(t,a,outer)[1],x*norm(a*c))
    return rules,profiles,values,graph_counts,graphs
