"""Byte/line preserving C++ discovery view, explicitly NOT macro semantics.
ABSL_ASSIGN_OR_RETURN(lhs, rhs) becomes lhs = rhs solely for syntax discovery.
Every erased invocation remains in an expansion ledger; early returns/status
checks and third macro arguments are not modeled by this transformation.
"""
import re
from source_inventory import mask_cpp


def syntax_view(source):
    masked=mask_cpp(source.decode('latin1')).encode('latin1')
    result=bytearray(source); ledger=[]
    for m in re.finditer(rb'\bABSL_ASSIGN_OR_RETURN\s*\(',masked):
        opening=m.end()-1;depth=1;i=opening+1;commas=[]
        while i<len(masked) and depth:
            c=masked[i]
            if c==40:depth+=1
            elif c==41:depth-=1
            elif c==44 and depth==1:commas.append(i)
            i+=1
        if depth or len(commas)!=1:
            ledger.append({'kind':'unsupported_macro','byte_start':m.start(),'byte_end':i})
            continue
        comma=commas[0];closing=i-1
        for j in range(m.start(),opening+1):
            if result[j] not in (10,13):result[j]=32
        result[comma]=61;result[closing]=32
        left=opening+1
        while masked[left] in b' \t\r\n':left+=1
        right=comma-1
        while masked[right] in b' \t\r\n':right-=1
        if masked[left]==40 and masked[right]==41:
            result[left]=result[right]=32
        ledger.append({'kind':'assignment_macro_syntax_only','byte_start':m.start(),'byte_end':i,
                       'line':source[:m.start()].count(b'\n')+1,
                       'source':source[m.start():i].decode(),
                       'lost_semantics':['status check','failure return','macro temporary scope']})
    for m in re.finditer(rb'\babsl_(?:nonnull|nullable)\b',masked):
        result[m.start():m.end()]=b' '*(m.end()-m.start())
        ledger.append({'kind':'pointer_annotation_syntax_only','byte_start':m.start(),'byte_end':m.end(),
                       'source':source[m.start():m.end()].decode()})
    view=bytes(result)
    assert len(view)==len(source)
    assert [i for i,c in enumerate(view) if c==10]==[i for i,c in enumerate(source) if c==10]
    return view,ledger
