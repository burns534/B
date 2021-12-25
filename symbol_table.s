.text
.p2align 2
.globl _create_symbol_table
.globl _enter_scope
.globl _exit_scope
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

; identifier in x0
; pointer to result in x0
_get_entry:
    stp fp, lr, [sp, -32]!
    stp x19, x20, [sp, 16]
    mov x19, x0 ; save id
    adrp x0, symbol_table_address@page
    add x0, x0, symbol_table_address@pageoff
    ldr x0, [x0]
    ldr x20, [x0, 8] ; stack data

; searching backwards is fine because only one can exist
0:
    ldr x0, [x20], 8 ; load map
    cbz x0, 1f
    mov x1, x19 ; identifier as arg 1
    bl _m_contains ; check map at this scope
    cbz x0, 0b ; if not, check level lower

    ldr x0, [x20, -8]!
    mov x1, x19
    bl _m_get
    b 2f
1:
    mov x0, xzr
2:
    ldp x19, x20, [sp, 16]
    ldp fp, lr, [sp], 32
    ret

; identifier in x0
; entry in x1
_save_entry:
    stp fp, lr, [sp, -48]!
    stp x21, x22, [sp, 32]
    stp x19, x20, [sp, 16]

    mov x19, x0 ; identifier in x19
    mov x20, x1 ; save entry in x20
    adrp x8, symbol_table_address@page
    add x8, x8, symbol_table_address@pageoff
    ldr x21, [x8] ; symbol table in x21
    ldr x22, [x21, 8] ; load stack data

; check all scopes for the identifier, stop and save if it is found
; searching the stack backwards is fine because due to the
; behavior of this function, there can only ever be one entry
; for a given identifier in the entire symbol table
0: 
    ldr x0, [x22] ; load map
    cbz x0, 2f ; if zero, we did not find anything
    mov x1, x19  ; identifier saved from earlier
    bl _m_contains  ; check if contains identifier
    cbnz x0, 1f ; if nonzero, then insert in this map

    add x22, x22, 8 ; advance symbol table data pointer
    b 0b
1:
    ; insert at the current scope (update)
    ldr x0, [x22]
    mov x1, x19
    mov x2, x20
    bl _m_insert
    b 3f
2:
    ; nothing contained the entry so add it to the most nested scope
    mov x0, x21 ; symbol table
    bl _s_top

    stp x0, x19, [sp, -16]!
    adrp x0, debug_message@page
    add x0, x0, debug_message@pageoff
    bl _printf
    ldr x0, [sp], 16

    mov x1, x19
    mov x2, x20
    bl _m_insert
3:
    ldp x19, x20, [sp, 16]
    ldp x21, x22, [sp, 32]
    ldp fp, lr, [sp], 48
    ret

; notify symbol table to enter new scope
_enter_scope:
    stp fp, lr, [sp, -16]!
    bl _m_create
    mov x1, x0
    adrp x0, symbol_table_address@page
    add x0, x0, symbol_table_address@pageoff
    ldr x0, [x0]
    bl _s_push
    ldp fp, lr, [sp], 16
    ret

; notify symbol table to exit scope
_exit_scope:
    stp fp, lr, [sp, -16]!
    adrp x0, symbol_table_address@page
    add x0, x0, symbol_table_address@pageoff
    ldr x0, [x0]
    bl _s_pop
    bl _m_destroy ; free memory
    ldp fp, lr, [sp], 16
    ret

_create_symbol_table:
    str x19, [sp, -32]!
    stp fp, lr, [sp, 16]
    add fp, sp, 16
    bl _s_create
    mov x19, x0
    bl _m_create
    mov x1, x0
    mov x0, x19
    bl _s_push

    adrp x1, symbol_table_address@page
    add x1, x1, symbol_table_address@pageoff
    str x19, [x1]
    ldp fp, lr, [sp, 16]
    ldr x19, [sp], 32
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