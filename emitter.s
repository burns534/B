.text
.p2align 2
.globl _emit_bin
.globl _precedence
.include "types.s"
; symbol table can be something like
; identifier -> absolute address
; automatatically refreshes with scope
; it will be a stack of maps to handle lexical scoping
; but will crawl upwards in scope if necessary to search identifiers

; accept file handle in x0
; operator token in x1
; operand1 token x2
; operand2 token x3
_emit_bin:
    sub sp, sp, 48
    stp fp, lr, [sp, 32]
    stp x19, x20, [sp, 16]
    str x21, [sp, 8]
    add fp, sp, 32

    ; emit code for first operand
    mov x0, x19
    mov x1, x20
    mov x3, x21

    ldr x0, [x2] ; load type
    cmp x0, TS_IDENTIFIER
    bne 0f

    ; do identifier magic here and print the string
    b 1f
0:
    ; assume int literal

    adrp x0, load_literal@page
    add x0, x0, load_literal@pageoff

    ldr x1, [x2, 8] ; load value
    str x1, [sp] ; put on stack for call

    ; mov x0, x19
    bl _printf ; emit instruction
    b 2f
1:
    ; emit fixed instruction for stack push
    adrp x0, stack_push@page
    add x0, x0, stack_push@pageoff
    mov x1, x19 ; file handle
    bl _fputs

    ; emit instructions for second operand
    ldr x0, [x21] ; load type
    cmp x0, TS_IDENTIFIER
    bne 0f

    ; do identifier magic here and print the string
    b 1f
0:
    ; int literal

    adrp x1, load_literal@page
    add x1, x1, load_literal@pageoff

    ldr x0, [x21, 8] ; load value
    str x0, [sp] ; put on stack for call

    mov x0, x19
    bl _fprintf ; emit instruction

1:
    ; emit pop and actual binary operation

    ldr x0, [x20] ; token type
    sub x0, x0, TS_ASSIGN ; get index
    adrp x1, binary_operations@page
    add x1, x1, binary_operations@pageoff
    ldr x0, [x1, x0, lsl 3] ; load appropriate string address

    mov x1, x19

    bl _fputs
2:
    ldr x21, [sp, 8]
    ldp x19, x20, [sp, 16]
    ldp fp, lr, [sp, 32]
    add sp, sp, 48
    ret

_emit_identifier:
    ret

_emit_function_call:
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
    sub x1, x0, TS_ASSIGN 
    adrp x0, precedence_table@page
    add x0, x0, precedence_table@pageoff
    ldr x0, [x0, x1, lsl 3]
    ret

.section __TEXT,__cstring,cstring_literals
stack_load: .asciz "\tldr x%s, [sp, %d]\n" ; memory offset known from symbol table
static_load: .asciz "\tadrp\tx8, %s@PAGE\n\tadd x8, x8, %s@PAGEOFF\n\tldr x%d, [x8]\n" ; %s is symbol's derived label, found from lookup
stack_push: .asciz "\tstr x8, [sp, -4]!\n"
load_literal: .asciz "\tmov x8, %s\n" ; 16 bit immediate

assign_operation: .asciz ""
eq_operation: .asciz "\tldr x8, [sp], 4\n\tcmp x8, x9\n\tcset x8, eq\n"
lt_operation: .asciz "\tldr x9, [sp], 4\n\tcmp x8, x9\n\tcset x8, lt\n"
add_operation: .asciz "\tldr x9, [sp], 4\n\tadd x8, x8, x9\n"
sub_operation: .asciz "\tldr x9, [sp], 4\n\tsub x8, x8, x9\n"
mul_operation: .asciz "\tldr x9, [sp], 4\n\tmul x8, x8, x9\n"
div_operation: .asciz "\tldr x9, [sp], 4\n\tdiv x8, x8, x9\n"
mod_operation: .asciz "\tldr x9, [sp], 4\n\tdiv x10, x8, x9\n\tmsub x8, x10, x9, x8\n"
not_operation: .asciz "\tmovn x8, x8\n" ; not exactly what I want here but should behave mostly fine
adr_operation: .asciz ""

.data
.p2align 3
precedence_table: .quad 0, 1, 1, 2, 2, 3, 3, 3
binary_operations:
    .quad assign_operation
    .quad eq_operation
    .quad lt_operation
    .quad add_operation
    .quad sub_operation
    .quad div_operation
    .quad mul_operation
    .quad mod_operation