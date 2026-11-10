/- A comment containing a nested /- comment -/ and "string". -/
namespace LexicalFixture

def «/- name --» : Nat := 1

def quotedText : String := "-- /- \" quoted text"

def rawText : String := r##"line one /-
line two --"##

def apostrophe' : Char := '\"' -- A trailing comment.

end LexicalFixture
