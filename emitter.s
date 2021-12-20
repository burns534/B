.text
.p2align 2
.globl _emit_add
.globl _emit_sub
.globl _emit_mul
.globl _emit_div
.globl _static_load
; accept file handle in x0
_emit_add:
    stp fp, lr, [sp, -16]!
    ; file handle already in x0
    adrp x1, add_operation@page
    add x1, x1, add_operation@pageoff
    bl _fputs
    ldp fp, lr, [sp], 16
    ret
; accept file handle in x0
_emit_sub:
    stp fp, lr, [sp, -16]!
    ; file handle already in x0
    adrp x1, sub_operation@page
    add x1, x1, sub_operation@pageoff
    bl _fputs
    ldp fp, lr, [sp], 16
    ret
; accept file handle in x0
_emit_mul:
    stp fp, lr, [sp, -16]!
    ; file handle already in x0
    adrp x1, mul_operation@page
    add x1, x1, mul_operation@pageoff
    bl _fputs
    ldp fp, lr, [sp], 16
    ret
; accept file handle in x0
_emit_div:
    stp fp, lr, [sp, -16]!
    ; file handle already in x0
    adrp x1, div_operation@page
    add x1, x1, div_operation@pageoff
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

.section __TEXT,__cstring,cstring_literals
stack_load: .asciz "ldr x%d, [sp, %d]\n" ; memory offset known from symbol table
static_load: .asciz "adrp x8, %s@PAGE\nadd x8, x8, %s@PAGEOFF\nldr x%d, [x8]\n" ; %s is symbol's derived label, found from lookup
int_lit_mov: .asciz "mov x%d, %d\n" ; 16 bit immediate
add_operation: .asciz "add x8, x8, x9\n"
sub_operation: .asciz "sub x8, x8, x9\n"
mul_operation: .asciz "mul x8, x8, x9\n"
div_operation: .asciz "div x8, x8, x9\n"
