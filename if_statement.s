.include "types.s"
.text
.p2align 2
.globl _if_statement
; tokens in x0
; cursor pointer in x1
; return x0 1 for true, 0 for false
_if_statement:
    ; check for if keyword
    ldr x9, [x1]
    ldr x8, [x0, x9, lsl 3] ; load current token
    ldr x8, [x8] ; load type
    cmp x8, TS_IF
    beq 0f
    mov x0, xzr
    ret
0:
; allocate stack
    stp fp, lr, [sp, -48]!
    str x21, [sp, 32]
    stp x19, x20, [sp, 16]

    mov x19, x0 ; tokens
    mov x20, x1 ; save cursor pointer
    add x21, x9, 1 ; skip if token
    str x21, [x20] ; update cursor pointer

    ; call expression eval on predicate
    bl _expression_eval
    cbz x0, 10f
; perform if statement
    ldr x21, [x20] ; load cursor after expression_eval changed it
    ldr x8, [x19, x21, lsl 3] ; load token
    ldr x8, [x8] ; load type
    cmp x8, TS_OPEN_CURL_BRACE
    bne _if_statement_error1
    ; skip past it
    add x21, x21, 1
    str x21, [x20] ; update cursor pointer

    ; enter new scope
    bl _enter_scope

    mov x0, x19
    mov x1, x20
    bl _evaluate ; evaluate the code block

    bl _print_variable_table

; check for return expr
    ldr x21, [x20]
    ldr x8, [x19, x21, lsl 3]
    ldr x8, [x8] ; type
    cmp x8, TS_RETURN
    beq 20f

    ; exit scope
    bl _exit_scope

; skip past else clause if present

    add x21, x21, 1
    ldr x8, [x19, x21, lsl 3]
    ldr x8, [x8]
    cmp x8, TS_ELSE
    bne 20f ; return

    ; otherwise loop to last } for else statement
    add x21, x21, 1 ; skip else statement
    ldr x8, [x19, x21, lsl 3]
    ldr x8, [x8]
    cmp x8, TS_OPEN_CURL_BRACE
    bne _if_statement_error1

    mov x0, x19
    mov x1, x21
    bl _skip_to_end

    add x21, x0, 1 ; increment cursor past last close

    b 20f

10:
; handle else statement or end of if
    ldr x21, [x20] ; load cursor
    ldr x8, [x19, x21, lsl 3] ; load token
    ldr x8, [x8] ; load type
    cmp x8, TS_OPEN_CURL_BRACE
    bne _if_statement_error1

    mov x0, x19
    mov x1, x21
    bl _skip_to_end

    add x21, x0, 1 ; increment past close bracket

    ; if there's an else keyword, do that, otherwise return control
    ldr x8, [x19, x21, lsl 3]
    ldr x8, [x8] ; type
    cmp x8, TS_ELSE
    bne 20f

    add x21, x21, 1 ; skip else

    ldr x8, [x19, x21, lsl 3]
    ldr x8, [x8]
    cmp x8, TS_OPEN_CURL_BRACE
    bne _if_statement_error1

    add x21, x21, 1 ; skip open brace
    str x21, [x20] ; update cursor

    bl _enter_scope

    mov x0, x19
    mov x1, x20
    bl _evaluate

    bl _print_variable_table

; check for return expr
    ldr x21, [x20]
    ldr x8, [x19, x21, lsl 3]
    ldr x8, [x8] ; type
    cmp x8, TS_RETURN
    beq 20f

    ; exit scope
    bl _exit_scope

    ldr x21, [x20] ; load cursor
    add x21, x21, 1 ; skip close curl bracket

20:
    str x21, [x20] ; update cursor
    mov x0, 1 ; return true

    ldp x19, x20, [sp, 16]
    ldr x21, [sp, 32]
    ldp fp, lr, [sp], 48
    ret

_if_statement_error1:
    adrp x0, if_error1@page
    add x0, x0, if_error1@pageoff
    str x8, [sp]
    bl _printf

    mov x0, xzr
    bl _exit

.section __text,__cstring,cstring_literals
if_error1: .asciz "error: if_statement: expected { but found %lu instead\n"
if_error2: .asciz "error: if_statement: expected } but found %lu instead\n"