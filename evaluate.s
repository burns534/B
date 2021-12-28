.include "types.s"
.text
.p2align 2
.globl _evaluate

; write this as a jump table

; tokens in x0
; cursor pointer in x1
_evaluate:
    stp fp, lr, [sp, -48]!
    stp x19, x20, [sp, 32]
    str x21, [sp, 16]
    mov x19, x0 ; save tokens
    mov x20, x1 ; save cursor pointer

    bl _print_activation_stack
0:  
    ldr x21, [x20] ; load current cursor, was probably changed by one of these routines
    ; check for close bracket
    ldr x8, [x19, x21, lsl 3] ; load current token
    ldr x8, [x8] ; load token type
;; debug message
    stp x8, x21, [sp, -16]!
    adrp x0, debug_message0@page
    add x0, x0, debug_message0@pageoff
    bl _printf
    ldr x8, [sp], 16
; terminate on any of these 4 tokens
    cmp x8, TS_CLOSE_CURL_BRACE
    beq 2f
    cmp x8, TS_RETURN
    beq 2f ; if return, end
    cmp x8, TS_BREAK
    beq 2f
    cmp x8, TS_CONTINUE
    beq 2f
    cmp x8, TS_DELETE
    beq 8f
    cmp x8, TS_IDENTIFIER
    bne 1f
    mov x0, x19
    mov x1, x20
    bl _expression_eval

    ldr x21, [x20] ; load cursor
    ldr x8, [x19, x21, lsl 3]
    ldr x8, [x8] ; type
    cmp x8, TS_SEMICOLON
    bne _eval_error3

    add x21, x21, 1 ; increment past the semicolon
    str x21, [x20] ; store cursor 
    b 0b ; continue
1:
    mov x0, x19
    mov x1, x20
    bl _if_statement
    cbnz x0, 0b
    mov x0, x19
    mov x1, x20
    bl _while_statement
    cbnz x0, 0b
    adrp x0, eval_error1@page
    add x0, x0, eval_error1@pageoff
    bl _puts
    bl _exit

8:
    add x21, x21, 1 ; skip delete token

    ldr x9, [x19, x21, lsl 3] ; load next token
    ldr x8, [x9] ; type
    cmp x8, TS_IDENTIFIER
    bne _eval_error2

    ldr x0, [x9, 8] ; token identifier
    bl _get_variable_lvalue

    bl _free ; free memory

    add x21, x21, 1 ; skip past identifier

    ldr x9, [x19, x21, lsl 3] ; load next token
    ldr x8, [x9] ; type
    cmp x8, TS_SEMICOLON
    bne _eval_error3

    add x21, x21, 1 ; skip semicolon
    str x21, [x20] ; update cursor pointer

    b 0b ; continue evaluate loop

2:
    str x21, [x20] ; update cursor

    ldr x21, [sp, 16]
    ldp x19, x20, [sp, 32]
    ldp fp, lr, [sp], 48
    ret

_eval_error2:
    adrp x0, eval_error2@page
    add x0, x0, eval_error2@pageoff
    str x8, [sp]
    bl _printf

    mov x0, xzr
    bl _exit

_eval_error3:
    adrp x0, eval_error3@page
    add x0, x0, eval_error3@pageoff
    str x8, [sp]
    bl _printf

    mov x0, xzr
    bl _exit



.data
.p2align 3
jump_table:
    .quad eval_error1


.section __text,__cstring,cstring_literals
eval_error1: .asciz "error: evaluate: no valid statement found"
eval_error2: .asciz "error: evaluate: expected identifier instead found %lu\n"
eval_error3: .asciz "error: evaluate: expected semicolon instead found %lu\n"
debug_message0: .asciz "evaluate: inside loop with token, cursor: %lu, %lu\n"