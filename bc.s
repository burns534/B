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
.globl _skip_to_end
.globl _function_call

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
    bl _atol ; convert token string to long
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
    mov x1, x0 ; result as arg1, operand 1
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
    bl _s_top

    stp x0, x12, [sp, -16]!
    adrp x0, debug_message1@page
    add x0, x0, debug_message1@pageoff
    bl _printf
    mov x0, x21
    bl _print_stack
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
    beq 6f
    cmp x8, TS_STRING
    beq 6f
    cmp x8, TS_IDENTIFIER
    beq 6f
    cmp x8, TS_NEW
    beq 30f

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

    cmp x8, TS_OPEN_SQ_BRACE
    bne 6f

    ; retrieve entry for identifier
    ldr x8, [x19, x20, lsl 3]
    ldr x0, [x8, 8] ; identifier
    bl _get_entry
    ldr x23, [x0, 8] ; get entry value and save in x23

    add x20, x20, 2 ; skip identifier and open brace
    str x20, [x25]

    mov x0, x19
    mov x1, x25
    bl _expression_eval ; evaluate index
    ; check for close sq bracket
    ldr x20, [x25]
    ldr x8, [x19, x20, lsl 3]
    ldr x8, [x8]
    cmp x8, TS_CLOSE_SQ_BRACE
    bne _expression_eval_runtime_error3

    ldr x0, [x23, x0, lsl 3] ; load value stored at entry address with index offset

    b 12f ; branch to push to the outstack

6:
    ; otherwise, push the primary eval to outstack
    ldr x0, [x19, x20, lsl 3] ; load current token
    bl _primary_eval

    str x0, [sp, -16]!
    adrp x0, debug_message@page
    add x0, x0, debug_message@pageoff
    bl _printf
    ldr x0, [sp], 16
12:
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
    b 2f ; return from this expression eval call

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
    bl _runtime_error

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

.globl _evaluate
; tokens in x0
; cursor pointer in x1
_evaluate:
    stp fp, lr, [sp, -48]!
    stp x19, x20, [sp, 32]
    str x21, [sp, 16]
    mov x19, x0 ; save tokens
    mov x20, x1 ; save cursor pointer

    adrp x0, debug_message9@page
    add x0, x0, debug_message9@pageoff
    bl _puts

    bl _print_activation_stack
0:  
    ldr x21, [x20] ; load current cursor, was probably changed by one of these routines
    ; check for close bracket
    ldr x8, [x19, x21, lsl 3] ; load current token
    ldr x8, [x8] ; load type
;; debug message
    stp x8, x21, [sp, -16]!
    adrp x0, debug_message8@page
    add x0, x0, debug_message8@pageoff
    bl _printf
    ldr x8, [sp], 16
; terminate on any of these 4 tokens
    cmp x8, TS_CLOSE_CURL_BRACE
    beq 2f
    cmp x8, TS_RETURN
    beq 2f ; if return, end
    cmp x8, TS_BREAK
    beq 2f
    cmp x8, TS_CONTINUE
    beq 2f
    cmp x8, TS_DELETE
    beq 8f
    cmp x8, TS_IDENTIFIER
    bne 1f
    add x9, x21, 1 ; load next token
    ldr x8, [x19, x9, lsl 3]
    ldr x8, [x8] ; load type
    cmp x8, TS_OPEN_PAREN
    bne 1f

    ; function call
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
    bl _if_statement
    cbnz x0, 0b
    mov x0, x19
    mov x1, x20
    bl _while_statement
    cbnz x0, 0b
    mov x0, x19
    mov x1, x20
    bl _variable_definition
    cbnz x0, 0b
; might add for statement later
    ;mov x0, x19
    ;mov x1, x20
    ;bl _for_statement
    ;cbnz x0, 0b
    adrp x0, eval_error1@page
    add x0, x0, eval_error1@pageoff
    bl _runtime_error

8:
    add x21, x21, 1 ; skip delete token

    ldr x9, [x19, x21, lsl 3] ; load next token
    ldr x8, [x9] ; type
    cmp x8, TS_IDENTIFIER
    bne _eval_error2

    ldr x0, [x9, 8] ; token identifier
    bl _get_entry

    ldr x0, [x0, 8] ; load value for variable

    bl _free ; free memory

    add x21, x21, 1 ; skip past identifier

    ldr x9, [x19, x21, lsl 3] ; load next token
    ldr x8, [x9] ; type
    cmp x8, TS_SEMICOLON
    bne _eval_error3

    add x21, x21, 1 ; skip semicolon
    str x21, [x20] ; update cursor pointer

    b 0b ; continue evaluate loop

2:
    str x21, [x20] ; update cursor

    ldr x21, [sp, 16]
    ldp x19, x20, [sp, 32]
    ldp fp, lr, [sp], 48
    ret

_eval_error2:
    adrp x0, eval_error2@page
    add x0, x0, eval_error2@pageoff
    str x8, [sp]
    bl _printf

    mov x0, xzr
    bl _exit

_eval_error3:
    adrp x0, eval_error3@page
    add x0, x0, eval_error3@pageoff
    str x8, [sp]
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

; accept tokens in x0
; accept pointer to cursor in x1
_function_call:
    stp fp, lr, [sp, -64]!
    stp x21, x22, [sp, 48]
    stp x19, x20, [sp, 32]
    str x23, [sp, 16]

    mov x19, x0 ; tokens in x19
    mov x20, x1 ; cursor pointer x20
    ldr x21, [x20] ; load cursor
    
    bl _system_call ; this could be implemented in a better way but it's fine for now
    cbnz x1, 10f ; return if system call was performed
    ; return result will be in x0 if there was one

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

    str x21, [x20] ; update cursor

    bl _start_variable_binding ; start variable binding context

    ldr x0, [x22, 8] ; parameter stack for function
    bl _s_start_iterator ; get next parameter

; bind parameters
0:
    ldr x8, [x19, x21, lsl 3] ; load token
    ldr x8, [x8] ; type
    cmp x8, TS_CLOSE_PAREN
    beq 2f
    cmp x8, TS_COMMA
    beq 1f
; evaluate the expression
    mov x0, x19
    mov x1, x20
    bl _expression_eval

    ldr x21, [x20] ; update cursor after expression eval changed it

    bl _create_variable_entry ; create variable entry with exp result

    str x0, [sp, -16]!
    bl _print_variable_entry
    ldr x0, [sp], 16

    mov x9, x0 ; move result to arg1, x9 safe from _s_next
    ; get identifier
    ldr x0, [x22, 8] ; parameter stack
    bl _s_next ; get next parameter, clobbers x8, x0, x1

    mov x1, x9
    bl _bind_variable ; save entry
    
    b 0b
1:
    add x21, x21, 1
    str x21, [x20]
    b 0b
2:
    bl _end_variable_binding ; end variable binding context

    add x0, x21, 1 ; return to token following close paren

    bl _set_return_cursor

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

    mov x0, x22 ; return result

    str x0, [sp, -16]!
    adrp x0, debug_message3@page
    add x0, x0, debug_message3@pageoff
    bl _printf
    ldr x0, [sp], 16
10:
    ldr x23, [sp, 16]
    ldp x19, x20, [sp, 32]
    ldp x21, x22, [sp, 48]
    ldp fp, lr, [sp], 64
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
precedence_table: .quad 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 5, 5, 6, 6, 6, 6, 7, 7, 8, 8, 9, 9, 9

.section __text,__cstring,cstring_literals
unary_error: .asciz "error: invalid unary operator"
exp_eval_error: .asciz "error: expression_eval: failed on token %lu\n"
exp_eval_error1: .asciz "error: expression_eval: outstack top != 0"
exp_eval_error2: .asciz "error: expression_eval: top of opstack was not open paren"
exp_eval_error3: .asciz "error: expression_eval: expected ] and found %lu instead\n"
primary_eval_error_message: .asciz "primary expression encountered invalid token %lu\n"
eval_error1: .asciz "error: evaluate: no valid statement found"
eval_error2: .asciz "error: evaluate: expected identifier instead found %lu\n"
eval_error3: .asciz "error: evaluate: expected semicolon instead found %lu\n"
function_call_error1: .asciz "error: function call: symbol table entry not found for identifier %s\n"
function_call_error2: .asciz "error: function call: symbol table entry for identifier %s associated with variable\n"
function_call_error3: .asciz "error: function call: expected identifier instead found %lu\n"
debug_message: .asciz "primary_eval result: %lu\n"
debug_message1: .asciz "top of stack: %p\n"
debug_message2: .asciz "expression eval returning %lu\n"
debug_message3: .asciz "returning %lu from function call\n"
debug_message4: .asciz "inside expression eval loop with token %s\n"
debug_message5: .asciz "about to check for function call with token %s\n"
debug_message6: .asciz "function call with token %s\n"
debug_message7: .asciz "cursor: %lu\n"
debug_message8: .asciz "eval loop with token: %lu, cursor: %lu\n"
debug_message9: .asciz "evaluate called!"