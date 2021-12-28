.include "types.s"
.text
.p2align 2
.globl _create_function_entry
.globl _save_function_entry
.globl _get_function_entry
.globl _get_variable_lvalue
.globl _enter_scope
.globl _exit_scope
.globl _create_tables
.globl _get_variable_table
.globl _get_function_table


; parameter stack in x0
; entry point in x1
; result in x0
_create_function_entry:
    stp fp, lr, [sp, -32]!
    stp x0, x1, [sp, 16]

    mov x0, 16
    bl _malloc ; allocate 16 bytes for function entry
    mov x2, x0

    ldp x0, x1, [sp, 16]
    str x0, [x2] ; write parameter stack reference
    str x1, [x2, 8] ; write entry point

    mov x0, x2 ; return function entry

    ldp fp, lr, [sp], 32
    ret

; identifier x0
; entry x1
_save_function_entry:
    stp fp, lr, [sp, -16]!
    mov x2, x1
    mov x1, x0
    adrp x0, function_table@page
    add x0, x0, function_table@pageoff
    ldr x0, [x0]
    bl _m_insert
    ldp fp, lr, [sp], 16
    ret

; identifier x0
_get_function_entry:
    stp fp, lr, [sp, -16]!
    mov x1, x0 ; arg1
    adrp x0, function_table@page
    add x0, x0, function_table@pageoff
    ldr x0, [x0]
    bl _m_get
    ldp fp, lr, [sp], 16
    ret


; identifier x0
_get_variable_lvalue:
    stp fp, lr, [sp, -48]!
    str x21, [sp, 32]
    stp x19, x20, [sp, 16]

    mov x19, x0 ; key x19

    adrp x0, variable_table@page
    add x0, x0, variable_table@pageoff
    ldr x20, [x0] ; load map

    mov x0, x20
    mov x1, x19 ; key
    bl _m_contains
    cbz x0, 0f

    mov x0, x20
    mov x1, x19
    bl _m_get_lvalue ; get value

    str x0, [sp, -16]!
    adrp x0, debug_message0@page
    add x0, x0, debug_message0@pageoff
    bl _printf
    ldr x0, [sp], 16

    b 10f
0:
    bl _get_activation_stack
    bl _s_top
    cbz x0, 1f ; if no activation stack, then we're at global scope
    ldr x8, [x0, 8] ; scope stack of top AR
    ldr x20, [x8, 8] ; data of the scope stack

0:
    ldr x21, [x20], 8
    cbz x21, 0f ; create the entry

    mov x0, x21 ; map
    mov x1, x19 ; key
    bl _m_contains ; check if this scope level has the variable
    cbz x0, 0b ; if not, continue

    mov x0, x21
    mov x1, x19
    bl _m_get_lvalue
    b 10f

0:
    ldr x0, [x20, -16] ; get highest lexical scope
    b 2f
1:
    mov x0, x20 ; variable table
2:
    mov x1, x19 ; key
    mov x2, xzr ; initialize to zero
    bl _m_insert ; insert identifier, returns lvalue in x0

10:
    ldp x19, x20, [sp, 16]
    ldr x21, [sp, 32]
    ldp fp, lr, [sp], 48
    ret

; enter new lexical scope
_enter_scope:
    stp fp, lr, [sp, -32]!
    str x19, [sp, 16]

    adrp x0, enter_scope_message@page
    add x0, x0, enter_scope_message@pageoff
    bl _puts

    bl _get_activation_stack
    bl _s_top ; get top activation record
    ldr x19, [x0, 8] ; get its scope stack and save in x19

    bl _m_create
    mov x1, x0 ; new table
    mov x0, x19 ; scope stack
    bl _s_push
 
    ldr x19, [sp, 16]
    ldp fp, lr, [sp], 32
    ret

; exit lexical scope
_exit_scope:
    stp fp, lr, [sp, -16]!

    adrp x0, exit_scope_message@page
    add x0, x0, exit_scope_message@pageoff
    bl _puts

    bl _get_activation_stack
    bl _s_top ; get top activation record
    ldr x0, [x0, 8] ; get its scope stack

    bl _s_pop ; pop the scope stack
    bl _m_destroy ; destroy result

    ldp fp, lr, [sp], 16
    ret

_create_tables:
    stp fp, lr, [sp, -16]!
; create global variable table
    bl _m_create
    adrp x8, variable_table@page
    add x8, x8, variable_table@pageoff
    str x0, [x8] ; store at address
; create global function table
    bl _m_create
    adrp x8, function_table@page
    add x8, x8, function_table@pageoff
    str x0, [x8] ; store at address
    ldp fp, lr, [sp], 16
    ret



_get_variable_table:
    adrp x0, variable_table@page
    add x0, x0, variable_table@pageoff
    ldr x0, [x0]
    ret

_get_function_table:
    adrp x0, function_table@page
    add x0, x0, function_table@pageoff
    ldr x0, [x0]
    ret


.data
.p2align 3
variable_table: .quad 0
function_table: .quad 0

.section __text,__cstring,cstring_literals
enter_scope_message: .asciz "entering scope"
exit_scope_message: .asciz "exiting scope"
get_entry_error: .asciz "error: get_entry: entry not found\n"
debug_message0: .asciz "get_variable_lvalue: m_get_lvalue returned %p\n"