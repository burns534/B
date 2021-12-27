.include "types.s"
.text
.p2align 2
.globl _system_call
.equ FUNCTION_NAMES_COUNT, 12

; expected to be called pointing to expression that can be evaluated
; tokens in x0
; cursor pointer in x1
; return expression evaluated parameter in x0
_get_parameter:
    ldr x9, [x1]
    ldr x8, [x0, x9, lsl 3] ; load current token
    ldr x8, [x8] ; type
    cmp x8, TS_CLOSE_PAREN
    bne 0f
    mov x0, xzr ; return zero if parenthesis found
    ret 
0:
    stp fp, lr, [sp, -32]!
    stp x19, x20, [sp, 16]

    mov x19, x0
    mov x20, x1

    bl _expression_eval ; evaluate parameter

    ldr x8, [x20]
    ldr x9, [x19, x8, lsl 3] ; load token
    ldr x9, [x9]
    cmp x9, TS_COMMA
    bne 1f

    ; if comma, advance cursor
    add x8, x8, 1
    str x8, [x20] ; update cursor

1:
    ldp x19, x20, [sp, 16]
    ldp fp, lr, [sp], 32
    ret


; tokens in x0
; cursor pointer in x1
; return system function call return value in x0
; return system call performed or not in x1
_system_call:   ; called with cursor pointing to identifier
    stp fp, lr, [sp, -64]!
    str x23, [sp, 48]
    stp x21, x22, [sp, 32]
    stp x19, x20, [sp, 16]

    mov x19, x0
    mov x20, x1
    ldr x21, [x20]

    adrp x22, function_names@page
    add x22, x22, function_names@pageoff

    ldr x8, [x19, x21, lsl 3] ; load token
    ldr x23, [x8, 8] ; load value

    mov x24, xzr ; counter

0: 
    mov x0, x23
    ldr x1, [x22, x24, lsl 3] ; arg1
    stp x0, x1, [sp, -16]!
    adrp x0, message1@page
    add x0, x0, message1@pageoff
    bl _printf
    ldp x0, x1, [sp], 16

    bl _strcmp
    cbz x0, 1f
    add x24, x24, 1 ; increment counter
    cmp x24, FUNCTION_NAMES_COUNT
    blt 0b

; here we didn't find anything so return 0
    mov x1, xzr
    b 2f
1: 
    ; use offset in x24 to load the jump address
    adrp x8, jump_table@page
    add x8, x8, jump_table@pageoff

    ; skip open parenthesis
    add x21, x21, 2
    str x21, [x20]

    ldr x8, [x8, x24, lsl 3] ; load jump address
    mov x0, x19 ; tokens
    mov x1, x20 ; token cursor
    blr x8 ; branch and link the appropriate function

    ; cursor should be on close paren so need to skip that
    ldr x8, [x20]
    add x8, x8, 1
    str x8, [x20]

    ; return value in x0
    mov x1, 1 ; true
2:
    ldp x19, x20, [sp, 16]
    ldp x21, x22, [sp, 32]
    ldr x23, [sp, 48]
    ldp fp, lr, [sp], 64
    ret

b_fprintf:
    ret

b_fputs:
    ret

; tokens x0
; token cursor x1
b_printf:
    stp fp, lr, [sp, -64]!
    stp x23, x24, [sp, 48]
    stp x21, x22, [sp, 32]
    stp x19, x20, [sp, 16]

    mov x19, x0 ; tokens
    mov x20, x1 ; cursor reference

    bl _get_parameter ; get parameter for format string
    mov x22, x0 ; save parameter

    mov x24, xzr ; keep track of stack offset

0:
    mov x0, x19
    mov x1, x20
    bl _get_parameter
    cbz x0, 2f
    mov x23, x0 ; save parameter
    mov x0, x19
    mov x1, x20
    bl _get_parameter
    cbz x0, 1f
    stp x23, x0, [sp, -16]!
    add x24, x24, 16
    b 0b
1:
    str x23, [sp, -16]!
    add x24, x24, 16
2:
    mov x0, x22
    bl _printf

    add sp, sp, x24 ; restore stack pointer

    ldp x19, x20, [sp, 16]
    ldp x21, x22, [sp, 32]
    ldp x23, x24, [sp, 48]
    ldp fp, lr, [sp], 64
    ret

b_puts:
    ret




.data
.p2align 3
function_names:
    .quad fprintf
    .quad fputs
    .quad printf
    .quad puts

    .quad fgetc
    .quad ungetc
    .quad fread
    .quad fopen

    .quad fclose
    .quad fwrite
    .quad fseek
    .quad ftell

jump_table:
    .quad b_fprintf
    .quad b_fputs
    .quad b_printf
    .quad b_puts


.section __text,__cstring,cstring_literals
fprintf: .asciz "fprintf"
fputs: .asciz "fputs"
printf: .asciz "printf"
puts: .asciz "puts"

fgetc: .asciz "fgetc"
ungetc: .asciz "ungetc"
fread: .asciz "fread"
fopen: .asciz "fopen"

fclose: .asciz "fclose"
fwrite: .asciz "fwrite"
fseek: .asciz "fseek"
ftell: .asciz "ftell"

message: .asciz "printf called!!"
message1: .asciz "system call: comparing identifier %s and table entry %s\n"