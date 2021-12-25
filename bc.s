.text
.build_version macos, 12, 0     sdk_version 12, 0
.p2align 2
.include "types.s"
.globl _runtime_error
.globl _precedence
.globl _unary_eval
.globl _primary_eval
.globl _binary_eval
.globl _expression_eval

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
; cursor pointer in x1
; return result in x0
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

    stp x8, x12, [sp, -16]!
    adrp x0, debug_message4@page
    add x0, x0, debug_message4@pageoff
    bl _printf
    ldp x8, x12, [sp], 16
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
    add x9, x20, 1 ; check tokens[cur + 1]
    ldr x8, [x19, x9, lsl 3]
    ldr x8, [x8]
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
; check outstack top == 0
    ldr w8, [x22]
    cbnz w8, _expression_eval_runtime_error1

    mov x0, x22
    bl _s_pop ; return top of outstack

    str x0, [sp, -16]!
    adrp x0, debug_message2@page
    add x0, x0, debug_message2@pageoff
    bl _printf
    ldr x0, [sp], 16

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

.globl _evaluate
; tokens in x0
; cursor pointer in x1
_evaluate:
    stp fp, lr, [sp, -32]!
    stp x19, x20, [sp, 16]
    mov x19, x0 ; save tokens
    mov x20, x1 ; save cursor pointer
0:  
    ldr x21, [x20] ; load current cursor, was probably changed by one of these routines
    ; check for close bracket
    ldr x8, [x19, x21, lsl 3] ; load current token
    ldr x8, [x8] ; load type
    cmp x8, TS_CLOSE_CURL_BRACE
    beq 2f

    mov x0, x19
    mov x1, x20
    bl _if_statement
    cbnz x0, 0b
    mov x0, x19
    mov x1, x20
    bl _while_statement
    cbnz x0, 0b

    ldr x8, [x19, x21, lsl 3] ; load current token
    ldr x8, [x8] ; load type
    cmp x8, TS_IDENTIFIER
    bne 1f
    add x9, x21, 1 ; load next token
    ldr x8, [x19, x9, lsl 3]
    ldr x8, [x8] ; load type
    cmp x8, TS_OPEN_PAREN
    bne 1f
    ; function call
    str x9, [x20] ; update cursor to open paren
    mov x0, x19
    mov x1, x20
    bl _function_call ; shouldve terminated on semicolon

    ldr x21, [x20] ; load cursor
    add x21, x21, 1 ; increment
    str x21, [x20] ; store cursor so it points to next statement
    
    b 0b
1:
    mov x0, x19
    mov x1, x20
    bl _variable_definition
    cbnz x0, 0b

    ldr x8, [x19, x21, lsl 3] ; load token
    ldr x8, [x8] ; load type
    cmp x8, TS_RETURN
    beq 2f ; if return, end
    cmp x8, TS_BREAK
    beq 2f
    cmp x8, TS_CONTINUE
    beq 2f

    adrp x0, eval_error1@page
    add x0, x0, eval_error1@pageoff
    bl _runtime_error

2:
    str x21, [x20] ; update cursor

    ldp x19, x20, [sp, 16]
    ldp fp, lr, [sp], 32
    ret
    
; tokens in x0
; cursor in x1
_skip_to_end:
    ldr x10, [x1] ; load cursor
    mov x9, 1 ; nest depth
0:
    add x10, x10, 1
    ldr x8, [x0, x10, lsl 3]
    ldr x8, [x8]
    cmp x8, TS_OPEN_CURL_BRACE
    bne 1f
    add x9, x9, x1 ; increase nest depth
    b 0b
1:
    cmp x8, TS_CLOSE_CURL_BRACE
    bne 0b
    subs x9, x9, 1 ; decrease nest depth
    cbnz x9, 0b

    str x10, [x1] ; write cursor
    ret

; tokens in x0
; cursor pointer in x1
; return x0 1 for true, 0 for false
_if_statement:
    ; check for if keyword
    ldr x9, [x1]
    ldr x8, [x0, x9, lsl 3] ; load current token
    ldr x8, [x8] ; load type
    cmp x8, TS_IF
    beq 0f
    mov x0, xzr
    ret
0:
; allocate stack
    stp fp, lr, [sp, -48]!
    str x21, [sp, 32]
    stp x19, x20, [sp, 16]

    mov x19, x0 ; tokens
    mov x20, x1 ; save cursor pointer
    add x9, x9, 1 ; skip if token
    str x9, [x20] ; update cursor pointer

    ; call expression eval on predicate
    bl _expression_eval
    cbz x0, 10f
; perform if statement
    ldr x21, [x20] ; load cursor
    ldr x8, [x19, x21, lsl 3] ; load token
    ldr x8, [x8] ; load type
    cmp x8, TS_OPEN_CURL_BRACE
    bne _if_statement_error1
    ; skip past it
    add x21, x21, 1
    str x21, [x20] ; update cursor pointer

    ; enter new scope
    bl _enter_scope

    mov x0, x19
    mov x1, x20
    bl _evaluate ; evaluate the code block

    bl _print_symbol_table

    ; exit scope
    bl _exit_scope

; skip past else clause if present

    add x21, x21, 1
    ldr x8, [x19, x21, lsl 3]
    ldr x8, [x8]
    cmp x8, TS_ELSE
    bne 20f ; return

    ; otherwise loop to last } for else statement
    add x21, x21, 1 ; skip else statement
    ldr x8, [x19, x21, lsl 3]
    ldr x8, [x8]
    cmp x8, TS_OPEN_CURL_BRACE
    bne _if_statement_error1

    str x21, [x20] ; update cursor

    mov x0, x19
    mov x1, x20
    bl _skip_to_end

    ldr x21, [x20] ; load cursor
    add x21, x21, 1 ; increment cursor past last close

    b 20f

10:
; handle else statement or end of if
    ldr x21, [x20] ; load cursor
    ldr x8, [x19, x21, lsl 3] ; load token
    ldr x8, [x8] ; load type
    cmp x8, TS_OPEN_CURL_BRACE
    bne _if_statement_error1

    mov x0, x19
    mov x1, x20
    bl _skip_to_end

    ldr x21, [x20]
    add x21, x21, 1 ; increment past close bracket

    ; if there's an else keyword, do that, otherwise return control
    ldr x8, [x19, x21, lsl 3]
    ldr x8, [x8] ; type
    cmp x8, TS_ELSE
    bne 20f

    add x21, x21, 1 ; skip else

    ldr x8, [x19, x21, lsl 3]
    ldr x8, [x8]
    cmp x8, TS_OPEN_CURL_BRACE
    bne _if_statement_error1

    add x21, x21, 1 ; skip open brace
    str x21, [x20] ; update cursor

    bl _enter_scope

    mov x0, x19
    mov x1, x20
    bl _evaluate

    ; exit scope
    bl _exit_scope

    ldr x21, [x20] ; load cursor
    add x21, x21, 1 ; skip close curl bracket

20:
    str x21, [x20] ; update cursor
    mov x0, 1 ; return true

    ldp x19, x20, [sp, 16]
    ldr x21, [sp, 32]
    ldp fp, lr, [sp], 48
    ret

_if_statement_error1:
    adrp x0, if_error1@page
    add x0, x0, if_error1@pageoff
    str x8, [sp]
    bl _printf

    mov x0, xzr
    bl _exit

; tokens in x0
; cursor pointer in x1
_while_statement:
    mov x0, xzr
    ret

.globl _function_call
; accept tokens in x0
; accept pointer to cursor in x1
_function_call:
    stp fp, lr, [sp, -48]!
    stp x21, x22, [sp, 32]
    stp x19, x20, [sp, 16]

    mov x19, x0 ; tokens in x19
    mov x20, x1 ; cursor pointer x20
    ldr x21, [x20] ; load cursor

    ;adrp x0, debug_message7@page
    ;add x0, x0, debug_message7@pageoff
    ;bl _printf

    ldr x0, [x19, x21, lsl 3]
    ldr x0, [x0, 8]
    str x0, [sp, -16]!
    adrp x0, debug_message6@page
    add x0, x0, debug_message6@pageoff
    bl _printf
    add sp, sp, 16

    ldr x0, [x19, x21, lsl 3] ; load identifier token
    ldr x0, [x0, 8] ; load identifier
    bl _get_entry ; get entry
    cbz x0, _function_identifier_not_found_error

    ldr x1, [x0] ; type
    cmp x1, FUNCTION_TYPE
    bne _function_identifier_invalid_error

    mov x22, x0 ; save entry

    add x21, x21, 2 ; skip open paren since it is gauranteed to be there

    bl _enter_scope ; enter scope
; bind parameters, skip for now
0:
    ldr x8, [x19, x21, lsl 3] ; load token
    ldr x8, [x8] ; type
    cmp x8, TS_CLOSE_PAREN
    beq 1f
    add x21, x21, 1
    b 0b
1:

    add x0, x21, 1 ; return to token following close paren
    bl _push_activation_stack ; push return point to return stack

    ldr x8, [x22, 16] ; load entry point
    str x8, [x20] ; set cursor to entry

    mov x0, x19
    mov x1, x20
    bl _evaluate ; will terminate when it finds return statement

    ldr x21, [x20] ; load cursor
    add x21, x21, 1 ; skip return token
    str x21, [x20]

    mov x0, x19
    mov x1, x20
    bl _expression_eval ; probably terminated on semicolon but doesn't matter where
    ; return value in x0 here
    mov x22, x0 ; save it

    bl _pop_activation_stack
    str x0, [x20] ; set cursor to return location

    ; exit scope
    bl _exit_scope

    mov x0, x22 ; return result

    str x0, [sp, -16]!
    adrp x0, debug_message3@page
    add x0, x0, debug_message3@pageoff
    bl _printf
    ldr x0, [sp], 16

    ldp x19, x20, [sp, 16]
    ldp x21, x22, [sp, 32]
    ldp fp, lr, [sp], 48
    ret

_function_identifier_not_found_error:
    adrp x0, function_call_error1@page
    add x0, x0, function_call_error1@pageoff
    ldr x1, [x19, x21, lsl 3] ; load identifier token
    ldr x1, [x1, 8] ; load identifier
    str x1, [sp]
    bl _printf

    mov x0, xzr
    bl _exit

_function_identifier_invalid_error:
    adrp x0, function_call_error2@page
    add x0, x0, function_call_error2@pageoff
    ldr x1, [x19, x21, lsl 3] ; load identifier token
    ldr x1, [x1, 8] ; load identifier
    str x1, [sp]
    bl _printf

    mov x0, xzr
    bl _exit
    ; identifier returned variable entry instead of function entry

.data
.p2align 3
precedence_table: .quad 0, 1, 1, 2, 2, 3, 3, 3


.section __text,__cstring,cstring_literals
unary_error: .asciz "error: invalid unary operator"
binary_error: .asciz "error: invalid binary operator %lu with operands %lu and %lu\n"
exp_eval_error: .asciz "expression eval failed on token %lu\n"
exp_eval_error1: .asciz "outstack top != 0"
exp_eval_error2: .asciz "top of opstack was not open paren"
primary_eval_error_message: .asciz "primary expression encountered invalid token %lu\n"
eval_error1: .asciz "no statement found"
if_error1: .asciz "error: if_statement: expected { but found %lu instead\n"
if_error2: .asciz "error: if_statement: expected } but found %lu instead\n"
function_call_error1: .asciz "error: function call: symbol table entry not found for identifier %s\n"
function_call_error2: .asciz "error: function call: symbol table entry for identifier %s associated with variable\n"
debug_message: .asciz "primary_eval result: %lu\n"
debug_message1: .asciz "top of opstack is: %lu\n"
debug_message2: .asciz "expression eval returning %lu\n"
debug_message3: .asciz "returning %lu from function call\n"
debug_message4: .asciz "inside expression eval loop with token %lu\n"
debug_message5: .asciz "about to check for function call with token %s\n"
debug_message6: .asciz "function call with token %s\n"
debug_message7: .asciz "cursor: %lu\n"
