.text
.p2align 2
.globl _emit_add
.globl _emit_sub
.globl _emit_mul
.globl _emit_div
.globl _static_load
.globl _stack_load
.globl _precedence
; accept file handle in x0
_emit_add:
    stp fp, lr, [sp, -16]!
    mov x1, x0
    ; file handle already in x0
    adrp x0, add_operation@page
    add x0, x0, add_operation@pageoff
    bl _fputs
    ldp fp, lr, [sp], 16
    ret
; accept file handle in x0
_emit_sub:
    stp fp, lr, [sp, -16]!
    mov x1, x0
    ; file handle already in x0
    adrp x0, sub_operation@page
    add x0, x0, sub_operation@pageoff
    bl _fputs
    ldp fp, lr, [sp], 16
    ret
; accept file handle in x0
_emit_mul:
    stp fp, lr, [sp, -16]!
    mov x1, x0
    ; file handle already in x0
    adrp x0, mul_operation@page
    add x0, x0, mul_operation@pageoff
    bl _fputs
    ldp fp, lr, [sp], 16
    ret
; accept file handle in x0
_emit_div:
    stp fp, lr, [sp, -16]!
    mov x1, x0
    ; file handle already in x0
    adrp x0, div_operation@page
    add x0, x0, div_operation@pageoff
    bl _fputs
    ldp fp, lr, [sp], 16
    ret

; file handle in x0
; identifier string in x1
; register number in x2 - should be x9 usually, x8 for setup
_static_load:
    sub sp, sp, 48
    stp fp, lr, [sp, 32]
    add fp, sp, 32
    str x1, [sp]
    str x1, [sp, 8]
    str x2, [sp, 16]
    adrp x1, static_load@page
    add x1, x1, static_load@pageoff
    bl _fprintf
    ldp fp, lr, [sp, 32]
    add sp, sp, 48
    ret

; file handle in x0
; register number x1
; memory offset x2
_stack_load:
    sub sp, sp, 32
    stp fp, lr, [sp, 16]
    add fp, sp, 16
    str x1, [sp]
    str x2, [sp, 8]
    adrp x1, stack_load@page
    add x1, x1, stack_load@pageoff
    bl _fprintf
    ldp fp, lr, [sp, 16]
    add sp, sp, 32
    ret

; accept token type (long) in x0
; return precedence in x0
_precedence:
    sub x1, x0, 14 ; TS_ASSIGN
    adrp x0, precedence_table@page
    add x0, x0, precedence_table@pageoff

    ldr x0, [x0, x1, lsl 3]
    ret

.section __TEXT,__cstring,cstring_literals
stack_load: .asciz "\tldr x%d, [sp, %d]\n" ; memory offset known from symbol table
static_load: .asciz "\tadrp\tx8, %s@PAGE\n\tadd x8, x8, %s@PAGEOFF\n\tldr x%d, [x8]\n" ; %s is symbol's derived label, found from lookup
int_lit_mov: .asciz "\tmov x%d, %d\n" ; 16 bit immediate
add_operation: .asciz "\tadd x8, x8, x9\n"
sub_operation: .asciz "\tsub x8, x8, x9\n"
mul_operation: .asciz "\tmul x8, x8, x9\n"
div_operation: .asciz "\tdiv x8, x8, x9\n"

.data
.p2align 3
precedence_table: .quad 0, 1, 1, 2, 2, 3, 3, 3
