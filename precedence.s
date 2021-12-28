.include "types.s"
.text
.p2align 2
.globl _precedence
; accept token type (long) in x0
; return precedence in x0
_precedence:
    sub x1, x0, TS_ASSIGN
    adrp x0, precedence_table@page
    add x0, x0, precedence_table@pageoff
    ldr x0, [x0, x1, lsl 3]
    ret

.data
.p2align 3
precedence_table: .quad 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 5, 5, 6, 6, 6, 6, 7, 7, 8, 8, 9, 9, 9