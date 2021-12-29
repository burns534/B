.include "types.s"
.text
.p2align 2
.globl _binary_eval
.equ NUM_OPERATORS, TS_MOD - TS_ASSIGN

; op2 in x0 
; op1 in x1 
; operation token in x2
; return result in x0
_binary_eval: ; cannot clobber x12 !!
    ldr x2, [x2] ; load operation type

    ;stp fp, lr, [sp, -16]!
    ;stp x0, x1, [sp, -32]!
    ;str x2, [sp, 16]
    ;adrp x0, debug_message@page
    ;add x0, x0, debug_message@pageoff
    ;bl _printf
    ;ldr x2, [sp, 16]
    ;ldp x0, x1, [sp], 32
    ;ldp fp, lr, [sp], 16

    sub x2, x2, TS_ASSIGN ; subtract assign

    cmp x2, 0
    blt _be_error
    cmp x2, NUM_OPERATORS
    bge _be_error

    adrp x8, jump_table@page
    add x8, x8, jump_table@pageoff

    ldr x8, [x8, x2, lsl 3] ; load address to jump

    br x8

_ts_assign:
    str x0, [x1] ; store rvalue in lvalue
    ret
_ts_and_a:
    ldr x2, [x1] ; load value from lvalue
    and x0, x2, x0 ; bitwise and
    str x0, [x1] ; store new value in lvalue
    ret
_ts_or_a:
    ldr x2, [x1] ; load value from lvalue
    orr x0, x2, x0 ; bitwise or
    str x0, [x1] ; store new value in lvalue
    ret
_ts_xor_a:
    ldr x2, [x1] ; load value from lvalue
    eor x0, x2, x0 ; exclusive or
    str x0, [x1] ; store new value in lvalue
    ret
_ts_add_a:
    ldr x2, [x1] ; load value from lvalue
    adds x0, x2, x0 ; signed addition
    str x0, [x1] ; store new value in lvalue
    ret
_ts_sub_a:
    ldr x2, [x1] ; load value from lvalue
    subs x0, x2, x0 ; signed subtraction
    str x0, [x1] ; store new value in lvalue
    ret
_ts_mul_a:
    ldr x2, [x1] ; load value from lvalue
    mul x0, x2, x0 ; signed multiply
    str x0, [x1] ; store new value in lvalue
    ret
_ts_div_a:
    ldr x2, [x1] ; load value from lvalue
    sdiv x0, x2, x0 ; signed divide
    str x0, [x1] ; store new value in lvalue
    ret
_ts_mod_a:
    ldr x2, [x1] ; load value from lvalue
    sdiv x3, x2, x0
    msub x0, x3, x0, x2
    str x0, [x1] ; store new value in lvalue
    ret
_ts_right_a:
    ldr x2, [x1] ; load value from lvalue
    asr x0, x2, x0 ; arithmetic shift right
    str x0, [x1] ; store new value in lvalue
    ret
_ts_left_a:
    ldr x2, [x1] ; load value from lvalue
    lsl x0, x2, x0 ; logical shift left
    str x0, [x1] ; store new value in lvalue
    ret
_ts_logical_or:
    orr x0, x1, x0 ; bitwise or
    cmp x0, 0
    cset x0, gt
    ret
_ts_logical_and:
    and x0, x1, x0 ; bitwise and
    cmp x0, 0
    cset x0, gt
    ret
_ts_or:
    orr x0, x1, x0
    ret
_ts_xor:
    eor x0, x1, x0
    ret
_ts_and:
    and x0, x1, x0
    ret
_ts_eq:
    cmp x0, x1
    cset x0, eq
    ret
_ts_ne:
    cmp x0, x1
    cset x0, ne
    ret
_ts_lt:
    cmp x1, x0
    cset x0, lt
    ret
_ts_gt:
    cmp x1, x0
    cset x0, gt
    ret
_ts_le:
    cmp x1, x0
    cset x0, le
    ret
_ts_ge:
    cmp x1, x0
    cset x0, ge
    ret
_ts_right:
    asr x0, x1, x0
    ret
_ts_left:
    lsl x0, x1, x0 
    ret
_ts_add:
    add x0, x1, x0 
    ret
_ts_sub:
    subs x0, x1, x0 
    ret
_ts_mul:
    mul x0, x1, x0 
    ret
_ts_div:
    sdiv x0, x1, x0 ;signed
    ret
_ts_mod:
    sdiv x2, x1, x0 ;signed
    msub x0, x0, x2, x1
    ret

_be_error:
    str x2, [sp]
    stp x1, x0, [sp, 8]
    adrp x0, be_error@page
    add x0, x0, be_error@pageoff
    bl _printf
    mov w0, 1
    b _exit

.section __text,__cstring,cstring_literals
be_error: .asciz "error: invalid binary operator %lu with operands %lu and %lu\n"
debug_message: .asciz "called with op2, op1, operator: %lu, %lu, %lu\n"
.data
.p2align 3
jump_table:
    .quad _ts_assign
    .quad _ts_and_a
    .quad _ts_or_a
    .quad _ts_xor_a
    .quad _ts_add_a
    .quad _ts_sub_a
    .quad _ts_mul_a
    .quad _ts_div_a
    .quad _ts_mod_a
    .quad _ts_right_a
    .quad _ts_left_a
    
    .quad _ts_logical_or

    .quad _ts_logical_and

    .quad _ts_or

    .quad _ts_xor

    .quad _ts_and

    .quad _ts_eq
    .quad _ts_ne

    .quad _ts_lt
    .quad _ts_gt
    .quad _ts_le
    .quad _ts_ge

    .quad _ts_right
    .quad _ts_left

    .quad _ts_add
    .quad _ts_sub

    .quad _ts_mul
    .quad _ts_div
    .quad _ts_mod

