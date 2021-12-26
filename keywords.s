.equ keyword_bytes, 8 * 12

.data
.p2align 3
keywords:
    .quad break
    .quad continue
    .quad delete
    .quad else

    .quad for
    .quad func
    .quad if
    .quad new

    .quad return
    .quad struct
    .quad var
    .quad while

break: .asciz "break"
continue: .asciz "continue"
delete: .asciz "delete"
else: .asciz "else"

for: .asciz "for"
func: .asciz "func"
if: .asciz "if"
new: .asciz "new"

return: .asciz "return"
struct: .asciz "struct"
var: .asciz "var"
while: .asciz "while"