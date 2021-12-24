.text
.build_version macos, 12, 0     sdk_version 12, 0
.p2align 2
.include "types.s"
.globl _runtime_error
.globl _precedence
.globl _unary_eval
.globl _primary_eval
.globl _binary_eval
.globl _variable_definition
.globl _expression_eval

.globl _get_symbol_table
_get_symbol_table:
    adrp x0, symbol_table_address@page
    add x0, x0, symbol_table_address@pageoff
    ldr x0, [x0]
    ret

;.globl _main

_main:
    ret

; message in x0
_runtime_error:
    bl _puts
    mov x0, 1
    bl _exit

; accept token type (long) in x0
; return precedence in x0
_precedence:
    sub x1, x0, TS_ASSIGN 
    adrp x0, precedence_table@page
    add x0, x0, precedence_table@pageoff
    ldr x0, [x0, x1, lsl 3]
    ret

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
    cmp x1, TS_INTEGER
    bne 0f
    ldr x0, [x0, 8] ; load token value string
    bl _atoi
    b 10f
0:
    ; string or identifier cases, need symbol table for this
    ldr x0, [x0, 8]
    cmp x1, TS_STRING
    bne 1f
    b 10f
1:
    cmp x1, TS_IDENTIFIER
    bne _primary_eval_runtime_error
    bl _get_entry
    ldr x0, [x0, 8] ; load value for identifier from variable entry
10:
    ldp fp, lr, [sp], 16
    ret

_primary_eval_runtime_error:
    adrp x0, primary_eval_error_message@page
    add x0, x0, primary_eval_error_message@pageoff
    str x1, [sp]
    bl _printf

    mov x0, 1
    b _exit

; op2 in x0
; op1 in x1
; operation token in x2
_binary_eval:
    ldr x3, [x2] ; load operation type
    cmp x3, TS_ADD
    bne 0f
    add x0, x1, x0
    ret
0:
    cmp x3, TS_SUB
    bne 1f
    sub x0, x1, x0
    ret
1:
    cmp x3, TS_MUL
    bne 2f
    mul x0, x1, x0
    ret
2:
    cmp x3, TS_DIV
    bne 3f
    udiv x0, x1, x0
    ret
3:
    cmp x3, TS_MOD
    bne 4f
    udiv x2, x1, x0
    msub x0, x0, x2, x1
    ret
4:
    cmp x3, TS_EQ
    bne 5f
    cmp x0, x1
    cset x0, eq
    ret
5:
    cmp x3, TS_LT
    bne 6f
    cmp x1, x0
    cset x0, lt
    ret
6:
    str x3, [sp]
    stp x1, x0, [sp, 8]
    adrp x0, binary_error@page
    add x0, x0, binary_error@pageoff
    bl _printf
    mov w0, 1
    b _exit

_eval_push:
    stp fp, lr, [sp, -16]!
    mov x0, x21 ; opstack
    bl _s_pop ; pop operator stack
    mov x23, x0 ; save operator

    mov x0, x22
    bl _s_pop ; pop outstack
    mov x24, x0 ; save operand 1

    mov x0, x22
    bl _s_pop
    mov x1, x0
    mov x2, x23
    mov x0, x24
    bl _binary_eval ; evaluate

    mov x1, x0
    mov x0, x22
    bl _s_push ; push result to outstack

    ldp fp, lr, [sp], 16
    ret

; tokens in x0
; cursor in x1
; return cursor in x0
_expression_eval:
    stp fp, lr, [sp, -80]!
    str x25, [sp, 64]
    stp x23, x24, [sp, 48]
    stp x21, x22, [sp, 32]
    stp x19, x20, [sp, 16]
    mov x19, x0 ; tokens
    mov x25, x1 ; cursor *
    ldr x20, [x25] ; cursor
    bl _s_create
    mov x21, x0 ; opstack
    bl _s_create
    mov x22, x0 ; outstack
0:
    ldr x12, [x19, x20, lsl 3]
    ldr x8, [x12] ; _s_top and precedence don't disturb x12
    cmp x8, TS_EOF
    beq _expression_eval_runtime_error
; check if operator
    cmp x8, TS_EQ
    blt 1f
    cmp x8, TS_MOD
    bgt 1f
; handle operator
10:
    mov x0, x21 ; opstack
    bl _s_top
    cbz x0, 11f ; if empty, break
    cmp x0, TS_OPEN_PAREN
    beq 11f ; if open paren, break
    ; get precedence of top
    ldr x0, [x0] ; top->type
    bl _precedence
    mov x2, x0 ; precedence doesn't clobber x2
    ldr x0, [x12] ; t->type
    bl _precedence
    cmp x2, x0
    blt 11f ; if less, break

    ; otherwise, push outstack with binary eval of top two operands and top of opstack
    bl _eval_push
    b 10b
11:
    mov x0, x21 ; opstack
    mov x1, x12 ; t
    bl _s_push
    b 4f
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
    beq 6f
    cmp x8, TS_STRING
    beq 6f
    cmp x8, TS_IDENTIFIER
    beq 6f

    b 0f ; end loop
6:
; handle primary expression
    add x8, x20, 1 ; check tokens[cur + 1]
    ldr x8, [x19, x8, lsl 3]
    ldr x8, [x8]
    cmp x8, TS_OPEN_PAREN
    bne 5f
    ; handle function call
    b 4f
5:
    ; otherwise, push the primary eval to outstack
    ldr x0, [x19, x20, lsl 3] ; load current token
    bl _primary_eval

    str x0, [sp, -16]!
    adrp x0, debug_message@page
    add x0, x0, debug_message@pageoff
    bl _printf
    ldr x0, [sp], 16

    mov x1, x0
    mov x0, x22 ; outstack
    bl _s_push
4:
    add x20, x20, 1 ; increment cursor
    b 0b

; now evaluate the rest of the stack
0:
    mov x0, x21
    bl _s_top
    cbz x0, 1f

    bl _eval_push
    b 0b ; continue
1:
; check outstack count == 1
    ldr w8, [x22]
    cmp w8, 1
    bne _expression_eval_runtime_error1

    mov x0, x22
    bl _s_pop ; return top of outstack

    ; adjust cursor
    str x20, [x25]

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
    bl _runtime_error

_expression_eval_runtime_error2:
    adrp x0, _expression_eval_runtime_error2@page
    add x0, x0, _expression_eval_runtime_error2@pageoff
    bl _runtime_error

; tokens in x0 
; cursor pointer in x1
; return cursor in x0
_variable_definition:

    ; load current token and check for var, abort early if not
    ldr x2, [x1]
    ldr x8, [x0, x2, lsl 3]
    ldr x8, [x8]
    cmp x8, TS_VAR
    beq 0f
    mov x0, xzr ; return false
    ret
0:
    stp x21, x22, [sp, -48]!
    stp x19, x20, [sp, 32]
    stp fp, lr, [sp, 16]
    add fp, sp, 16

    mov x19, x0
    mov x22, x1
    ldr x20, [x22] ; load cursor
    add x20, x20, 1 ; advance cursor to next token

    ; check identifier
    ldr x21, [x19, x20, lsl 3] ; save in x21 for later
    ldr x8, [x21]
    cmp x8, TS_IDENTIFIER
    bne _variable_definition_runtime_error

    add x20, x20, 1 ; advance to next token
    
    ; check for assignment operator
    ldr x8, [x19, x20, lsl 3]
    ldr x8, [x8]
    cmp x8, TS_ASSIGN
    bne _variable_definition_runtime_error

    add x20, x20, 1 ; advance cursor

    ldr x0, [x19, x20, lsl 3]
    bl _primary_eval ; converts primary expressions to single word
    bl _create_variable_entry ; create variable entry with value

    ; save entry
    mov x1, x0
    ldr x0, [x21, 8] ; load identifier from token saved earlier
    bl _save_entry

    ; assert semicolon and advance cursor
    add x20, x20, 1

    ldr x8, [x19, x20, lsl 3]
    ldr x8, [x8]
    cmp x8, TS_SEMICOLON
    bne _variable_definition_runtime_error

    add x20, x20, 1 ; advance cursor to next candidate token and return in x0
    str x20, [x22] ; write cursor

    mov x0, 1 ; return true

    ldp fp, lr, [sp, 16]
    ldp x19, x20, [sp, 32]
    ldp x21, x22, [sp], 48
    ret

_variable_definition_runtime_error:
    ; throw runtime error
    adrp x0, variable_def_error@page
    add x0, x0, variable_def_error@pageoff
    str x8, [sp, -16]!
    bl _printf

    mov w0, 1
    bl _exit

.globl _function_definition
; tokens in x0
; cursor pointer in x1
; returns 1 if found
_function_definition:
    ; check for func keyword and early abort if not found
    ldr x2, [x1]
    ldr x8, [x0, x2, lsl 3]
    ldr x8, [x8]
    cmp x8, TS_FUNC
    beq 0f
    mov x0, xzr ; return false
    ret
0:
    stp fp, lr, [sp, -64]!
    stp x21, x22, [sp, 48]
    stp x19, x20, [sp, 32]
    str x23, [sp, 16]

    mov x19, x0
    mov x23, x1 ; save cursor pointer
    ldr x20, [x23] ; load cursor
    add x20, x20, 1
    bl _s_create
    mov x21, x0 ; create stack for parameters

    ; check for identifier
    ldr x22, [x19, x20, lsl 3] ; save for later
    ldr x8, [x22]
    cmp x8, TS_IDENTIFIER
    bne _function_definition_runtime_error

    add x20, x20, 1 ; increment cursor

    ; check for open paren
    ldr x8, [x19, x20, lsl 3]
    ldr x8, [x8]
    cmp x8, TS_OPEN_PAREN
    bne _function_definition_runtime_error

    add x20, x20, 1 ; increment cursor
    ; now try to get all the parameters
0:
    ldr x9, [x19, x20, lsl 3]
    ldr x8, [x9]
    cmp x8, TS_IDENTIFIER
    bne 1f

    mov x0, x21
    ldr x1, [x9, 8]
    bl _s_push ; save identifier

    add x20, x20, 1 ; increment cursor
    ldr x8, [x19, x20, lsl 3]
    ldr x8, [x8]
    cmp x8, TS_CLOSE_PAREN
    beq 1f

    ; otherwise advance cursor again because it should be on a comma
    add x20, x20, 1
    b 0b

1:
    add x20, x20, 1 ; skip close paren

    ldr x8, [x19, x20, lsl 3]
    ldr x8, [x8]
    cmp x8, TS_OPEN_CURL_BRACE
    bne _function_definition_runtime_error

    add x20, x20, 1 ; now create the function entry

    mov x0, x21 ; param stack
    mov x1, x20 ; entry point
    bl _create_function_entry

    mov x1, x0
    ldr x0, [x22, 8] ; load identifier
    bl _save_entry

; now advance cursor past the function body
    ; use x9 for nest depth
    mov x9, 1
0:
    ldr x8, [x19, x20, lsl 3]
    ldr x8, [x8]
    cmp x8, TS_OPEN_CURL_BRACE
    bne 1f
    add x9, x9, 1
    b 2f
1:
    cmp x8, TS_CLOSE_CURL_BRACE
    bne 2f
    subs x9, x9, 1
2:
    add x20, x20, 1 ; increment cursor
    ; check nest depth
    cbnz x9, 0b

    str x20, [x23] ; write cursor
    mov x0, 1 ; return true

    ldr x23, [sp, 16]
    ldp x19, x20, [sp, 32]
    ldp x21, x22, [sp, 48]
    ldp fp, lr, [sp], 64
    ret

_function_definition_runtime_error:
    adrp x0, function_def_error@page
    add x0, x0, function_def_error@pageoff
    str x8, [sp, -16]!
    bl _printf

    mov w0, 1
    bl _exit


; need to provide nest depth here somehow
.globl _if_statement
; tokens in x0
; cursor pointer in x1
; return x0 1 for true, 0 for false
_if_statement:
    ; check for if keyword
    ldr x8, [x1]
    ldr x8, [x0, x8, lsl 3] ; load current token
    ldr x8, [x8] ; load type
    cmp x8, TS_IF
    beq 0f
    mov x0, xzr
    ret
0:
; allocate stack
    mov x19, x0
    mov x20, x1 ; save cursor pointer
    ldr x21, [x1] ; load cursor



.globl _function_call
; accept tokens in x0
; accept pointer to cursor in x1
_function_call:

    ret




.data
.p2align 3
precedence_table: .quad 0, 1, 1, 2, 2, 3, 3, 3

.section __text,__cstring,cstring_literals
unary_error: .asciz "error: invalid unary operator"
binary_error: .asciz "error: invalid binary operator %lu with operands %lu and %lu\n"
variable_def_error: .asciz "variable definition failed on token %lu\n"
function_def_error: .asciz "function definition failed on token %lu\n"
exp_eval_error: .asciz "expression eval failed on token %lu\n"
exp_eval_error1: .asciz "outstack count is not 1"
exp_eval_error2: .asciz "top of opstack was not open paren"
primary_eval_error_message: .asciz "primary expression encountered invalid token %lu\n"
debug_message: .asciz "primary_eval result: %lu\n"
debug_message1: .asciz "top of opstack is: %lu\n"
