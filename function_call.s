.include "types.s"
.text
.p2align 2
.globl _function_call

; accept tokens in x0
; accept pointer to cursor in x1
_function_call:
    stp fp, lr, [sp, -64]!
    stp x21, x22, [sp, 48]
    stp x19, x20, [sp, 32]
    str x23, [sp, 16]

    mov x19, x0 ; tokens in x19
    mov x20, x1 ; cursor pointer x20
    ldr x21, [x20] ; load cursor
    
    bl _system_call ; this could be implemented in a better way but it's fine for now
    cbnz x1, 10f ; return if system call was performed
    ; return result will be in x0 if there was one

    ldr x0, [x19, x21, lsl 3]
    ldr x0, [x0, 8]
    str x0, [sp, -16]!
    adrp x0, debug_message0@page
    add x0, x0, debug_message0@pageoff
    bl _printf
    add sp, sp, 16

    ldr x0, [x19, x21, lsl 3] ; load identifier token
    ldr x0, [x0, 8] ; load identifier
    bl _get_function_entry ; get entry
    cbz x0, _function_identifier_not_found_error

    mov x22, x0 ; save entry

    add x21, x21, 2 ; skip open paren since it is gauranteed to be there

    str x21, [x20] ; update cursor

    bl _start_variable_binding ; start variable binding context

    ldr x0, [x22] ; parameter stack for function
    bl _s_start_iterator ; get next parameter

; bind parameters
0:
    ldr x8, [x19, x21, lsl 3] ; load token
    ldr x8, [x8] ; type
    cmp x8, TS_CLOSE_PAREN
    beq 2f
    cmp x8, TS_COMMA
    beq 1f
; evaluate the expression
    mov x0, x19
    mov x1, x20
    bl _expression_eval

    ldr x21, [x20] ; update cursor after expression eval changed it

    mov x9, x0 ; move result to arg1, x9 safe from _s_next
    ; get identifier
    ldr x0, [x22] ; parameter stack
    bl _s_next ; get next parameter, clobbers x8, x0, x1

    mov x1, x9
    bl _bind_variable ; save entry
    
    b 0b
1:
    add x21, x21, 1
    str x21, [x20]
    b 0b
2:
    bl _end_variable_binding ; end variable binding context

    add x0, x21, 1 ; return to token following close paren

    bl _set_return_cursor

    ldr x8, [x22, 8] ; load entry point
    str x8, [x20] ; set cursor to entry

    mov x0, x19
    mov x1, x20
    bl _evaluate ; will terminate when it finds return statement

    ldr x21, [x20] ; load cursor
    add x21, x21, 1 ; skip return token
    str x21, [x20]

    mov x0, x19
    mov x1, x20
    bl _expression_eval ; probably terminated on semicolon but doesn't matter where
    ; return value in x0 here
    mov x22, x0 ; save it

    bl _pop_activation_stack
    str x0, [x20] ; set cursor to return location

    mov x0, x22 ; return result

    str x0, [sp, -16]!
    adrp x0, debug_message1@page
    add x0, x0, debug_message1@pageoff
    bl _printf
    ldr x0, [sp], 16
10:
    ldr x23, [sp, 16]
    ldp x19, x20, [sp, 32]
    ldp x21, x22, [sp, 48]
    ldp fp, lr, [sp], 64
    ret

_function_identifier_not_found_error:
    adrp x0, function_call_error1@page
    add x0, x0, function_call_error1@pageoff
    ldr x1, [x19, x21, lsl 3] ; load identifier token
    ldr x1, [x1, 8] ; load identifier
    str x1, [sp]
    bl _printf

    mov x0, xzr
    bl _exit


.section __text,__cstring,cstring_literals
function_call_error1: .asciz "error: function call: symbol table entry not found for identifier %s\n"
debug_message0: .asciz "function call with token %s\n"
debug_message1: .asciz "returning %lu from function call\n"
