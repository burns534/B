.include "types.s"
.text
.p2align 2
.globl _for_statement

; tokens in x0
; token cursor pointer x1
; return 1 if found
_for_statement:

    mov x0, xzr
    ret ; nothing for now

    ; first check for 'for' token
    ldr x9, [x1] ; load cursor
    ldr x8, [x0, x9, lsl 3]
    ldr x8, [x8] ; type
    cmp x8, TS_FOR
    beq 0f
    mov x0, xzr ; return false
    ret
0:
; allocate stack
    mov x19, x0 ; tokens x19
    mov x20, x0 ; cursor pointer x20

    add x22, x9, 1 ; skip 'for' token
    str x22, [x20] ; update cursor before expression eval



    ret
