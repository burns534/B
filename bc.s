.include "types.s"
.text
.build_version macos, 12, 0     sdk_version 12, 0
.p2align 2
.globl _unary_eval
.globl _primary_eval
.globl _expression_eval
.globl _skip_to_end

;.globl _main
_main:
    ret

; message in x0
_runtime_error:
    bl _puts
    mov x0, 1
    bl _exit

; token in x0
; op in x1
_unary_eval:
    stp fp, lr, [sp, -16]!
    ; first primary eval the token
    stp x0, x1, [sp, -16]!
    bl _primary_eval
    ldp x0, x1, [sp], 16

    ldr x1, [x1] ; load operator type
    cmp x1, TS_NOT
    bne 0f
    mvn x0, x0 ; bitwise not
    b 3f
0:
    cmp x1, TS_ADR
    bne 1f
    ; this will have to be done by the symbol table
    b 3f
1:
    cmp x1, TS_PTR
    beq 2f
    adrp x0, unary_error@page
    add x0, x0, unary_error@pageoff
    bl _runtime_error
2:
    ; handle indirection op
    ldr x0, [x0]
3:
    ldp fp, lr, [sp], 16
    ret

; token in x0
; needs error handling since it is called blindly
_primary_eval:
    stp fp, lr, [sp, -16]!

    ldr x1, [x0] ; load token type
    ldr x0, [x0, 8] ; load token value
    cmp x1, TS_INTEGER
    bne 0f
    bl _atol ; convert token string to long
    b 10f
0:
    ; string or identifier cases, need symbol table for this
    cmp x1, TS_STRING
    bne 1f
    b 10f
1:
    cmp x1, TS_IDENTIFIER
    bne _primary_eval_runtime_error
    str x0, [sp, -16]!
    adrp x0, debug_message3@page
    add x0, x0, debug_message3@pageoff
    bl _printf
    ldr x0, [sp], 16
    bl _get_variable_lvalue ; return lvalue
10:
    str x0, [sp, -16]!
    adrp x0, debug_message9@page
    add x0, x0, debug_message9@pageoff
    bl _printf
    ldr x0, [sp], 16
    ldp fp, lr, [sp], 16
    ret

_primary_eval_runtime_error:
    adrp x0, primary_eval_error_message@page
    add x0, x0, primary_eval_error_message@pageoff
    str x1, [sp]
    bl _printf

    mov x0, 1
    b _exit

; opstack x0
; outstack x1
_eval_push:
    stp fp, lr, [sp, -48]!
    stp x21, x22, [sp, 32]
    stp x19, x20, [sp, 16]

    mov x19, x0 ; opstack
    mov x20, x1 ; outstack

    bl _s_pop ; pop operator stack
    mov x21, x0 ; save operator x21

    mov x0, x20 ; outstack
    bl _s_pop ; pop outstack
    mov x22, x0 ; save operand 2

    mov x0, x20 ; oustack
    bl _s_pop
    mov x1, x0 ; operand 1
    mov x0, x22 ; operand 2
    mov x2, x21 ; operation
    bl _binary_eval ; evaluate

    mov x1, x0 ; move result to arg1
    mov x0, x20
    bl _s_push ; push result to outstack

    ldp x19, x20, [sp, 16]
    ldp x21, x22, [sp, 32]
    ldp fp, lr, [sp], 48
    ret

; tokens in x0
; cursor pointer in x1
; return result in x0
_expression_eval:
    stp fp, lr, [sp, -80]!
    str x25, [sp, 64]
    stp x23, x24, [sp, 48]
    stp x21, x22, [sp, 32]
    stp x19, x20, [sp, 16]

    mov x19, x0 ; tokens x19
    mov x25, x1 ; cursor pointer x25
    ldr x20, [x25] ; cursor x20

    adrp x0, debug_message6@page
    add x0, x0, debug_message6@pageoff
    bl _puts

    bl _print_activation_stack
    
    bl _s_create
    mov x21, x0 ; opstack
    bl _s_create
    mov x22, x0 ; outstack
0:
    ldr x12, [x19, x20, lsl 3]
    ldr x8, [x12] ; _s_top and precedence don't disturb x12
    cmp x8, TS_EOF
    beq _expression_eval_runtime_error

    stp x8, x12, [sp, -16]!
    ldr x9, [x12, 8]
    str x9, [sp, -16]!
    adrp x0, debug_message4@page
    add x0, x0, debug_message4@pageoff
    bl _printf
    add sp, sp, 16
    ldp x8, x12, [sp], 16

; check if operator
    cmp x8, TS_ASSIGN
    blt 1f
    cmp x8, TS_MOD
    bgt 1f
; handle operator
10:
    mov x0, x21 ; opstack
    bl _s_top ; doesn't clobber x12 ?

    stp x0, x12, [sp, -16]!
    adrp x0, debug_message1@page
    add x0, x0, debug_message1@pageoff
    bl _printf
    mov x0, x21
    bl _print_stack
    ldr x0, [sp]
    bl _print_token
    ldp x0, x12, [sp], 16

    cbz x0, 11f ; if empty, break
    ldr x0, [x0] ; type
    cmp x0, TS_OPEN_PAREN
    beq 11f ; if open paren, break

    ; get precedence of top
    bl _precedence
    mov x2, x0 ; precedence doesn't clobber x2
    ldr x0, [x12] ; t->type
    bl _precedence
    cmp x2, x0
    blt 11f ; if less, break

    ; otherwise, push outstack with binary eval of top two operands and top of opstack
    mov x0, x21 ; opstack
    mov x1, x22 ; outstack
    bl _eval_push
    b 10b
11:
    mov x0, x21 ; opstack
    mov x1, x12 ; operator token
    bl _s_push
    add x20, x20, 1
    b 0b
1:
    cmp x8, TS_OPEN_PAREN
    bne 2f
; handle open paren
    mov x0, x21 ; opstack
    mov x1, x12 ; token
    bl _s_push
    b 4f
2:
    cmp x8, TS_CLOSE_PAREN
    bne 3f
; handle close paren
20:
    mov x0, x21 ; opstack
; check that the opstack isn't empty
    ldr w8, [x21]
    cmp w8, -1
    beq 0f ; if it is, we were inside a function call parameters hopefully
    bl _s_top
    ldr x8, [x0]
    ;str x0, [sp, -16]!
    ;adrp x0, debug_message1@page
    ;add x0, x0, debug_message1@pageoff
    ;bl _printf
    ;ldr x0, [sp], 16

    cbz x8, 21f
    cmp x8, TS_OPEN_PAREN
    beq 21f
    mov x0, x21
    mov x1, x22
    bl _eval_push
    b 20b
21:
    mov x0, x21 ; opstack
    bl _s_pop
    ldr x8, [x0] ; type
    cmp x8, TS_OPEN_PAREN
    bne _expression_eval_runtime_error2
    b 4f
3:
    cmp x8, TS_INTEGER
    beq 7f
    cmp x8, TS_STRING
    beq 7f
    cmp x8, TS_IDENTIFIER
    beq 6f
    cmp x8, TS_NEW
    beq 30f

    b 0f ; end loop
6:
; handle primary expression
    add x9, x20, 1 ; check tokens[cur + 1]
    ldr x9, [x19, x9, lsl 3]
    ldr x8, [x9]
    cmp x8, TS_OPEN_PAREN
    bne 5f
    ; handle function call
    str x20, [x25] ; update cursor pointer to point to identifier
    mov x0, x19 ; tokens
    mov x1, x25 ; cursor pointer
    bl _function_call

    mov x1, x0 ; write result to outstack
    mov x0, x22 ; oustack
    bl _s_push

    ; update cursor
    ldr x20, [x25]

    adrp x0, debug_message7@page
    add x0, x0, debug_message7@pageoff
    str x20, [sp, -16]!
    bl _printf
    add sp, sp, 16

    b 0b
5:

    cmp x8, TS_OPEN_SQ_BRACE
    bne 8f

    ; retrieve entry for identifier
    ;ldr x8, [x19, x20, lsl 3]
    ldr x0, [x12, 8] ; identifier
    bl _get_variable_lvalue
    mov x23, x0 ; save in x23

    str x0, [sp, -16]!
    adrp x0, debug_message10@page
    add x0, x0, debug_message10@pageoff
    bl _printf
    ldr x0, [sp], 16

    add x20, x20, 2 ; skip identifier and open brace
    str x20, [x25] ; update cursor before expression_eval call

    mov x0, x19
    mov x1, x25
    bl _expression_eval ; evaluate index
    ; check for close sq bracket
    ldr x20, [x25]
    ldr x8, [x19, x20, lsl 3]
    ldr x8, [x8]
    cmp x8, TS_CLOSE_SQ_BRACE
    bne _expression_eval_runtime_error3

    ldr x8, [x23] ; load the array pointer from lvalue
    add x0, x8, x0, lsl 3 ; offset the array

    b 12f ; branch to push to the outstack

7:
    ; check to see what next token is
    add x8, x20, 1
    ldr x8, [x19, x8, lsl 3] ; load next token
    ldr x8, [x8]
    cmp x8, TS_LOGICAL_OR ; guard against assignment to constants
    blt _expression_eval_runtime_error4

    mov x0, x12
    bl _primary_eval

    b 40f

8:
    ; otherwise, push the primary eval to outstack
    mov x0, x12
    bl _primary_eval

    str x0, [sp, -16]!
    adrp x0, debug_message@page
    add x0, x0, debug_message@pageoff
    bl _printf
    ldr x0, [sp], 16
12:
    ; check if assignment will occur
    add x8, x20, 1
    ldr x8, [x19, x8, lsl 3]
    ldr x8, [x8]
    cmp x8, TS_LOGICAL_OR
    blt 40f
    ldr x0, [x0] ; dereference lvalue
40:
    mov x1, x0
    mov x0, x22 ; outstack
    bl _s_push
4:
    add x20, x20, 1 ; increment cursor
    b 0b

30:
    add x20, x20, 1 ; increment cursor past new keyword

    mov x0, x19 ; load tokens as arg0
    str x20, [x25] ; update cursor pointer to after new keyword
    mov x1, x25 ; set pointer as arg1

    bl _expression_eval ; evaluate argument for new

    bl _malloc ; allocate requested number of bytes
    ; return pointer is in x0
    b 40b

; now evaluate the rest of the stack
0:
    mov x0, x21 ; opstack
    bl _s_top
    cbz x0, 1f

    mov x0, x21
    mov x1, x22
    bl _eval_push
    b 0b ; continue
1:
; check outstack top == 0
    ldr w8, [x22]
    cbnz w8, _expression_eval_runtime_error1

    mov x0, x22
    bl _s_pop ; return top of outstack
    mov x19, x0 ; save result

    ; deallocate stacks
    mov x0, x21
    bl _s_destroy
    mov x0, x22
    bl _s_destroy

    str x19, [sp, -16]!
    adrp x0, debug_message2@page
    add x0, x0, debug_message2@pageoff
    bl _printf
    add sp, sp, 16

    ; adjust cursor
    str x20, [x25]

    mov x0, x19 ; return value
2:
    ldp x19, x20, [sp, 16]
    ldp x21, x22, [sp, 32]
    ldp x23, x24, [sp, 48]
    ldr x25, [sp, 64]
    ldp fp, lr, [sp], 80
    ret

_expression_eval_runtime_error:
    ; throw runtime error
    adrp x0, exp_eval_error@page
    add x0, x0, exp_eval_error@pageoff
    str x8, [sp, -16]!
    bl _printf

    mov w0, 1
    bl _exit

_expression_eval_runtime_error1:
    adrp x0, exp_eval_error1@page
    add x0, x0, exp_eval_error1@pageoff
    bl _puts
    mov x0, x22
    bl _print_stack
    mov x0, xzr
    bl _exit

_expression_eval_runtime_error2:
    adrp x0, exp_eval_error2@page
    add x0, x0, exp_eval_error2@pageoff
    bl _runtime_error

_expression_eval_runtime_error3:
    str x8, [sp]
    adrp x0, exp_eval_error3@page
    add x0, x0, exp_eval_error3@pageoff
    bl _printf

    mov x0, xzr
    bl _exit

_expression_eval_runtime_error4:
    str x8, [sp]
    adrp x0, exp_eval_error4@page
    add x0, x0, exp_eval_error4@pageoff
    bl _printf

    mov x0, xzr
    bl _exit

; call with cursor pointing to the first open bracket
; tokens in x0
; cursor in x1
; returns cursor x0
_skip_to_end:
    mov x9, 1 ; nest depth
0:
    add x1, x1, 1
    ldr x8, [x0, x1, lsl 3]
    ldr x8, [x8]
    cmp x8, TS_OPEN_CURL_BRACE
    bne 1f
    add x9, x9, 1 ; increase nest depth
    b 0b
1:
    cmp x8, TS_CLOSE_CURL_BRACE
    bne 0b
    subs x9, x9, 1 ; decrease nest depth
    cbnz x9, 0b

    mov x0, x1 ; return cursor pointing to last close bracket
    ret


.section __text,__cstring,cstring_literals
unary_error: .asciz "error: invalid unary operator"
exp_eval_error: .asciz "error: expression_eval: failed on token %lu\n"
exp_eval_error1: .asciz "error: expression_eval: outstack top != 0"
exp_eval_error2: .asciz "error: expression_eval: top of opstack was not open paren"
exp_eval_error3: .asciz "error: expression_eval: expected ] and found %lu instead\n"
exp_eval_error4: .asciz "error: expression_eval: cannot assign to constant rvalue\n"
primary_eval_error_message: .asciz "error: primary eval: encountered invalid token %lu\n"
debug_message: .asciz "primary_eval result: %lu\n"
debug_message1: .asciz "top of stack: %p\n"
debug_message2: .asciz "expression eval returning %lu\n"
debug_message3: .asciz "primary_eval: token: %s\n"
debug_message4: .asciz "inside expression eval loop with token %s\n"
debug_message5: .asciz "about to check for function call with token %s\n"
debug_message6: .asciz "entered expression eval"
debug_message7: .asciz "cursor: %lu\n"
debug_message8: .asciz "didn't cause a seg fault"
debug_message9: .asciz "primary_eval returning %lu\n"
debug_message10: .asciz "got array lvalue: %lu\n"