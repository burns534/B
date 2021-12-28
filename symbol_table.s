.text
.p2align 2
.globl _create_symbol_table
.globl _enter_scope
.globl _exit_scope
.globl _get_variable_lvalue
.globl _get_variable_rvalue
.globl _get_entry
.globl _save_entry
.globl _get_symbol_table
.globl _create_function_entry
.globl _create_variable_entry

.include "types.s"

; value in x0
; result in x0
_create_variable_entry:  
    str x19, [sp, -32]!
    stp fp, lr, [sp, 16]
    add fp, sp, 16
    mov x19, x0
    mov x0, 16
    bl _malloc
    mov x1, VARIABLE_TYPE
    str x1, [x0]
    str x19, [x0, 8]
    ldp fp, lr, [sp, 16]
    ldr x19, [sp], 32
    ret

; parameter stack in x0
; entry point in x1
; result in x0
_create_function_entry:
    stp fp, lr, [sp, -32]!
    stp x0, x1, [sp, 16]

    mov x0, 24
    bl _malloc ; allocate 24 bytes for function entry
    mov x2, x0

    ldp x0, x1, [sp, 16]
    str x1, [x2, 16] ; write entry
    str x0, [x2, 8] ; write param stack
    mov x0, FUNCTION_TYPE
    str x0, [x2] ; write type

    mov x0, x2 ; return struct

    ldp fp, lr, [sp], 32
    ret

; identifier x0
_get_variable_lvalue:
    stp fp, lr, [sp, -16]!
    bl _get_entry
    add x0, x0, 8 ; offset
    ldp fp, lr, [sp], 16

_get_variable_rvalue:
    stp fp, lr, [sp, -16]!
    bl _get_entry
    ldr x0, [x0, 8] ; offset
    ldp fp, lr, [sp], 16


; identifier in x0
; pointer to result in x0
_get_entry: ; don't clobber x1!!
    stp fp, lr, [sp, -48]!
    stp x19, x20, [sp, 32]
    stp x21, x1, [sp, 16]

    mov x19, x0 ; identifier x19

    adrp x0, debug_message1@page
    add x0, x0, debug_message1@pageoff
    str x19, [sp, -16]!
    bl _printf
    add sp, sp, 16

    bl _print_activation_stack

    adrp x0, symbol_table_address@page
    add x0, x0, symbol_table_address@pageoff
    ldr x20, [x0] ; load symbol table

    mov x0, x20 ; symbol table
    mov x1, x19 ; identifier key
    bl _m_contains ; check containment
    cbz x0, 0f ; if not, search the scope stack

    mov x0, x20
    mov x1, x19
    bl _m_get

    b 10f ; return value from _m_get
0:
    ; load the top of the activation record
    bl _get_activation_stack
    bl _s_top
    ldr x8, [x0, 8] ; scope stack of top activation record
    ldr x20, [x8, 8] ; scope stack data

; will iterate through stack backwards, which is fine because duplicate symbols are not possible
; also, it must have at least one map at the bottom
0:
    ldr x21, [x20], 8 ; load table at entry, post inc 8
    cbz x21, _get_entry_runtime_error
    mov x0, x21
    mov x1, x19 ; identifier
    bl _m_contains
    cbz x0, 0b ; contains, return the entry

    mov x0, x21
    mov x1, x19
    bl _m_get
10:
    ldp x21, x1, [sp, 16] ; don't clobber x1!!
    ldp x19, x20, [sp, 32]
    ldp fp, lr, [sp], 48
    ret

_get_entry_runtime_error:
    adrp x0, get_entry_error@page
    add x0, x0, get_entry_error@pageoff
    bl _puts
    mov x0, xzr
    bl _exit

; identifier in x0
; entry in x1
_save_entry:
    stp fp, lr, [sp, -48]!
    stp x21, x22, [sp, 32]
    stp x19, x20, [sp, 16]

    mov x19, x0 ; identifier in x19
    mov x20, x1 ; save entry in x20

    ; check if activation stack is empty

    bl _get_activation_stack
    ldr w8, [x0]
    cmp w8, -1
    bne 0f

    ; if activation stack is empty, we are at global scope
    ; so, just save directly into the global table

    adrp x8, symbol_table_address@page
    add x8, x8, symbol_table_address@pageoff
    ldr x0, [x8] ; load table
    mov x1, x19 ; key (identifier)
    mov x2, x20 ; entry
    bl _m_insert

    b 10f ; return

0: ; activation stack wasn't empty, so first check global scope

    adrp x8, symbol_table_address@page
    add x8, x8, symbol_table_address@pageoff
    ldr x21, [x8] ; load table, save in x21

    mov x0, x21 ; table
    mov x1, x19 ; key
    bl _m_contains
    cbz x0, 1f
    
    mov x0, x21 ; table
    mov x1, x19 ; key
    mov x2, x20 ; entry
    bl _m_insert ; insert entry to table

    b 10f ; return

1: ; did not contain, so search the scope stack of top AR

    bl _get_activation_stack
    bl _s_top
    ldr x8, [x0, 8] ; load scope stack of top AR
    ldr x21, [x8, 8] ; load scope stack data address

0:
    ldr x22, [x21], 8 ; load map
    cbz x22, 1f ; did not find entry, so insert at the top of the stack
    mov x0, x22 ; map
    mov x1, x19 ; key
    bl _m_contains
    cbz x0, 0b

    mov x0, x22 ; map save right above ^
    mov x1, x19 ; key (identifier)
    mov x2, x20 ; entry
    bl _m_insert ; insert the entry at the appropriate lexical scope level
    b 10f ; return
1:
    bl _get_activation_stack
    bl _s_top
    ldr x0, [x0, 8] ; load scope stack of top AR
    bl _s_top ; get table at highest scope

    mov x1, x19 ; key (identifier)
    mov x2, x20 ; entry
    bl _m_insert ; insert entry at highest scope of current activation record

10:
    ldp x19, x20, [sp, 16]
    ldp x21, x22, [sp, 32]
    ldp fp, lr, [sp], 48
    ret

; notify symbol table to enter new scope
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

; notify symbol table to exit scope
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

_create_symbol_table:
    stp fp, lr, [sp, -16]!
    bl _m_create
    adrp x8, symbol_table_address@page
    add x8, x8, symbol_table_address@pageoff
    str x0, [x8] ; store at address
    ldp fp, lr, [sp], 16
    ret

_get_symbol_table:
    adrp x0, symbol_table_address@page
    add x0, x0, symbol_table_address@pageoff
    ldr x0, [x0]
    ret


.data
.p2align 3
symbol_table_address: .quad 0

.section __text,__cstring,cstring_literals
debug_message: .asciz "about to insert into %p key %s\n"
debug_message1: .asciz "trying to get entry for key %s\n"
enter_scope_message: .asciz "entering scope"
exit_scope_message: .asciz "exiting scope"
get_entry_error: .asciz "error: get_entry: entry not found\n"