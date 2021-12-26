.text
.globl _create_activation_stack
.globl _pop_activation_stack
.globl _set_return_cursor
.globl _get_activation_stack
.globl _start_variable_binding
.globl _end_variable_binding
.globl _bind_variable

.p2align 2

; activation record
; quad return cursor    +0 (where to set the cursor after function call returns)
; quad scope stack      +8 (stack of maps to accomplish lexical scoping)

; _pop_activation_stack is unsafe if the stack is empty but that should never happen

_create_activation_record:
    stp fp, lr, [sp, -32]!
    stp x19, x20, [sp, 16]

    mov x0, 16
    bl _malloc

    str xzr, [x0] ; write 0 for return cursor

    mov x19, x0 ; save entry

    bl _s_create ; create scope stack
    str x0, [x19, 8] ; store map in entry
    mov x20, x0 ; save scope stack

    bl _m_create
    mov x1, x0 ; set as parameter to push
    mov x0, x20
    bl _s_push ; push scope 0 map to scope stack

    mov x0, x19 ; return entry

    ldp x19, x20, [sp, 16]
    ldp fp, lr, [sp], 32
    ret

_create_activation_stack:
    stp fp, lr, [sp, -16]!
    bl _s_create
    adrp x8, _activation_stack@page
    add x8, x8, _activation_stack@pageoff
    str x0, [x8] ; save return stack
    ldp fp, lr, [sp], 16
    ret

; pushes new activation record to the stack
_push_activation_stack:
    stp fp, lr, [sp, -16]!

    bl _create_activation_record
    mov x1, x0 ; arg1 for push

    adrp x8, _activation_stack@page
    add x8, x8, _activation_stack@pageoff
    ldr x0, [x8] ; load stack

    bl _s_push ; push activation record to top of activation stack

    ldp fp, lr, [sp], 16
    ret

; set the return cursor of the top activation record
; value in x0
_set_return_cursor:
    stp fp, lr, [sp, -32]!
    str x19, [sp, 16]

    mov x19, x0 ; save cursor x19

    adrp x8, _activation_stack@page
    add x8, x8, _activation_stack@pageoff
    ldr x0, [x8]
    bl _s_top ; get top record

    str x19, [x0] ; set cursor

    ldr x19, [sp, 16]
    ldp fp, lr, [sp], 32
    ret


; returns return cursor of top record in x0
; deallocate activation record
; deallocate stack
_pop_activation_stack:
    stp fp, lr, [sp, -32]!
    str x19, [sp, 16]

    adrp x8, _activation_stack@page
    add x8, x8, _activation_stack@pageoff
    ldr x0, [x8]
    bl _s_pop ; pop activation record

    mov x19, x0 ; save in x9

    ldr x0, [x19, 8] ; load symbol stack 
    bl _s_destroy ; deallocate symbol stack

    ldr x0, [x19] ; load cursor from activation record for return

    ldr x19, [sp, 16]
    ldp fp, lr, [sp], 32
    ret

; return stack in x0
_get_activation_stack:
    adrp x0, _activation_stack@page
    add x0, x0, _activation_stack@pageoff
    ldr x0, [x0]
    ret

; create temporary activation record for variable binding
_start_variable_binding:
    stp fp, lr, [sp, -16]!
    bl _create_activation_record
    adrp x8, _temporary_activation_record@page
    add x8, x8, _temporary_activation_record@pageoff
    str x0, [x8]
    ldp fp, lr, [sp], 16
    ret

; push temporary activation record to stack
_end_variable_binding:
    stp fp, lr, [sp, -16]!

    adrp x8, _temporary_activation_record@page
    add x8, x8, _temporary_activation_record@pageoff
    ldr x1, [x8] ; load activation record

    adrp x8, _activation_stack@page
    add x8, x8, _activation_stack@pageoff
    ldr x0, [x8]

    bl _s_push ; push to stack

    ldp fp, lr, [sp], 16
    ret

; key in x0
; entry in x1
_bind_variable:
    stp fp, lr, [sp, -32]!
    stp x19, x20, [sp, 16]

    mov x19, x0
    mov x20, x1

    adrp x8, _temporary_activation_record@page
    add x8, x8, _temporary_activation_record@pageoff
    ldr x8, [x8] ; load AR
    ldr x0, [x8, 8] ; AR's scope stack
    bl _s_top ; get table

    mov x1, x19
    mov x2, x20
    bl _m_insert

    ldp x19, x20, [sp, 16]
    ldp fp, lr, [sp], 32
    ret

.data
.p2align 3
_activation_stack: .quad 0
_temporary_activation_record: .quad 0