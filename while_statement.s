.text
.include "types.s"
.p2align 2
.globl _while_statement

; accept tokens in x0
; accept pointer to cursor in x1
; return 1 in x0 if found
_while_statement:
    ; first check for while token
    ldr x9, [x1] ; load cursor
    ldr x8, [x0, x9, lsl 3]
    ldr x8, [x8] ; type
    cmp x8, TS_WHILE
    beq 0f
    mov x0, xzr ; return false
    ret
0:
    stp fp, lr, [sp, -64]!
    str x23, [sp, 48]
    stp x21, x22, [sp, 32]
    stp x19, x20, [sp, 16]

    mov x19, x0 ; tokens x19
    mov x20, x1 ; cursor pointer x20

    add x22, x9, 1 ; skip while token and save for branch later
    str x22, [x20] ; update cursor pointer

    ; call evaluate on predicate
    bl _expression_eval
    cbz x0, 10f ; if zero, don't even start

    ldr x21, [x20] ; load cursor after expression eval
    ldr x8, [x19, x21, lsl 3] ; load token
    ldr x8, [x8] ; load type
    cmp x8, TS_OPEN_CURL_BRACE
    bne _while_statement_error1

; loop to find the end of the while loop
    mov x0, x19
    mov x1, x21 ; cursor itself
    bl _skip_to_end

    ; now x0 is pointing to the last close brace
    add x23, x0, 1 ; increment past it and save this as the exit point

    bl _enter_scope ; enter new temporary scope for the loop

6:
    ; cursor points to open bracket after predicate evaluation
    ldr x21, [x20] ; load cursor
    add x21, x21, 1
    str x21, [x20] ; skip this before calling evaluate

    mov x0, x19 ; tokens
    mov x1, x20 ; token cursor
    bl _evaluate ; perform the loop

; handle continue and break here
    ldr x21, [x20] ; load cursor after evaluate

    str x21, [sp, -16]!
    adrp x0, debug_message9@page
    add x0, x0, debug_message9@pageoff 
    bl _printf
    add sp, sp, 16

    ldr x8, [x19, x21, lsl 3] ; check why it stopped
    ldr x8, [x8] ; type
    cmp x8, TS_BREAK
    beq 8f
    ; now it couldve been continue or a bracket
    ; but it doesn't matter
    str x22, [x20] ; set cursor back to predicate

    mov x0, x19
    mov x1, x20
    bl _expression_eval ; evaluate predicate again
    cbnz x0, 6b ; start loop again if predicate is true
    ;; falthrough
8:
    ; handle break command
    bl _exit_scope ; exit the scope
    str x23, [x20] ; set cursor to exit point
    ; fallthrough
10:

    ldp x19, x20, [sp, 16]
    ldp x21, x22, [sp, 32]
    ldr x23, [sp, 48]
    ldp fp, lr, [sp], 64
    mov x0, 1 ; return true
    ret

_while_statement_error1:
    adrp x0, ws_error1@page
    add x0, x0, ws_error1@pageoff
    str x8, [sp]
    bl _printf

    mov x0, xzr
    bl _exit


.section __text,__cstring,cstring_literals
ws_error1: .asciz "error: while_statement: expected } found %lu instead\n"
debug_message9: .asciz "cursor after evaluate: %lu\n"