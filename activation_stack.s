.text
.globl _create_activation_stack
.globl _push_activation_stack
.globl _pop_activation_stack

.p2align 2

; activation record
; quad link register (cursor)
; quad top of scope stack 

; cursor x0
; scope stack top x1
_create_activation_record:
    stp fp, lr, [sp, -32]!
    stp x19, x20, [sp, 16]

    mov x19, x0 ; cursor x19
    mov x20, x1 ; top x20

    mov x0, 16
    bl _malloc

    str x19, [x0]
    str x20, [x0, 8]

    ldp x19, x20, [sp, 16]
    ldp fp, lr, [sp], 32
    ret

_create_activation_stack:
    stp fp, lr, [sp, -16]!
    bl _s_create
    adrp x8, _return_stack_address@page
    add x8, x8, _return_stack_address@pageoff
    str x0, [x8] ; save return stack
    ldp fp, lr, [sp], 16
    ret

; accept return cursor in x0
_push_activation_stack:
    stp fp, lr, [sp, -16]!
    mov x9, x0

    bl _get_symbol_table ; doesn't clobber x9
    ldr w8, [x0] ; load top
    sxtw x1, w8 ; top arg1
    mov x0, x9 ; return cursor arg0
    bl _create_activation_record
    mov x1, x0 ; arg1 for push

    adrp x8, _return_stack_address@page
    add x8, x8, _return_stack_address@pageoff
    ldr x0, [x8] ; load stack

    bl _s_push

    ldp fp, lr, [sp], 16
    ret


; returns return cursor in x0
_pop_activation_stack:
    stp fp, lr, [sp, -32]!
    str x19, [sp, 16]
    adrp x8, _return_stack_address@page
    add x8, x8, _return_stack_address@pageoff
    ldr x0, [x8]
    bl _s_pop ; pop activation record

    mov x9, x0 ; save in x9
    ldr x10, [x9, 8] ; load top

    bl _get_symbol_table
; TODO - make this memory safe by deallocating the maps
    str w10, [x0] ; restore scope stack top

    add w10, w10, 1 ; increment to next slot in stack

    ldr x11, [x0, 8] ; load stack data array

    str xzr, [x11, x10, lsl 3] ; write zero to maintain contraints

    ldr x19, [x9] ; save the return cursor from activation entry

    mov x0, x9
    bl _free ; free activation record

    mov x0, x19 ; return the cursor
    
    ldr x19, [sp, 16]
    ldp fp, lr, [sp], 32
    ret

.data
.p2align 3
_return_stack_address: .quad 0