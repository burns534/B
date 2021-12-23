.text
.build_version macos, 12, 0     sdk_version 12, 0
.p2align 2
.include "types.s"
.globl _runtime_error
.globl _precedence
.globl _unary_eval
.globl _primary_eval
.globl _binary_eval
.globl _create_symbol_table
.globl _enter_scope
.globl _exit_scope
.globl _get_entry
.globl _save_entry
.globl _variable_definition

.globl _get_symbol_table
_get_symbol_table:
    adrp x0, symbol_table_address@page
    add x0, x0, symbol_table_address@pageoff
    ldr x0, [x0]
    ret

.equ VARIABLE_TYPE, 64
.equ FUNCTION_TYPE, 65

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
    bl _get_entry
    ldr x0, [x0, 8] ; load value for identifier from variable entry
10:
    ldp fp, lr, [sp], 16
    ret

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
    adrp x0, binary_error@page
    add x0, x0, binary_error@pageoff
    bl _runtime_error

; tokens in x0
; cursor in x1
; return cursor in x0
_expression_eval:
    
    ret

; tokens in x0 
; cursor in x1
; return cursor in x0
_variable_definition:

    ; load current token and check for var, abort early if not
    ldr x8, [x0, x1, lsl 3]
    ldr x8, [x8]
    cmp x8, TS_VAR
    beq 0f
    mov x0, x1
    ret
0:
    str x21, [sp, -48]!
    stp x19, x20, [sp, 32]
    stp fp, lr, [sp, 16]
    add fp, sp, 16

    mov x19, x0
    add x20, x1, 1 ; advance cursor to next token

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

    add x0, x20, 1 ; advance cursor to next candidate token and return in x0

    ldp fp, lr, [sp, 16]
    ldp x19, x20, [sp, 32]
    ldr x21, [sp], 48
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
; cursor in x1
; returns cursor in x0
_function_definition:
    ; check for func keyword and early abort if not found
    ldr x8, [x0, x1, lsl 3]
    ldr x8, [x8]
    cmp x8, TS_FUNC
    beq 0f
    mov x0, x1
    ret
0:
    stp x21, x22, [sp, -48]!
    stp x19, x20, [sp, 32]
    stp fp, lr, [sp, 16]
    add fp, sp, 16

    mov x19, x0
    add x20, x1, 1
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

    mov x0, x20 ; return cursor

    ldp fp, lr, [sp, 16]
    ldp x19, x20, [sp, 32]
    ldp x21, x22, [sp], 48
    ret

_function_definition_runtime_error:
    adrp x0, function_def_error@page
    add x0, x0, function_def_error@pageoff
    str x8, [sp, -16]!
    bl _printf

    mov w0, 1
    bl _exit




; void
_create_symbol_table:
    str x19, [sp, -32]!
    stp fp, lr, [sp, 16]
    add fp, sp, 16
    bl _s_create
    mov x19, x0
    bl _m_create
    mov x1, x0
    mov x0, x19
    bl _s_push

    adrp x1, symbol_table_address@page
    add x1, x1, symbol_table_address@pageoff
    str x19, [x1]
    ldp fp, lr, [sp, 16]
    ldr x19, [sp], 32
    ret

_enter_scope:
    stp fp, lr, [sp, -16]!
    bl _m_create
    mov x1, x0
    adrp x0, symbol_table_address@page
    add x0, x0, symbol_table_address@pageoff
    ldr x0, [x0]
    bl _s_push
    ldp fp, lr, [sp], 16
    ret

_exit_scope:
    stp fp, lr, [sp, -16]!
    adrp x0, symbol_table_address@page
    add x0, x0, symbol_table_address@pageoff
    ldr x0, [x0]
    bl _s_pop
    ldp fp, lr, [sp], 16
    ret

; identifier in x0
; pointer to result in x0
_get_entry:
    stp x19, x20, [sp, -48]!
    str x21, [sp, 32]
    stp fp, lr, [sp, 16]
    add fp, sp, 16

    mov x19, x0 ; save id
    adrp x0, symbol_table_address@page
    add x0, x0, symbol_table_address@pageoff
    ldr x0, [x0]
    ldr x20, [x0, 8] ; stack data
    ldr w21, [x0] ; stack count
    sxtw x21, w21
    lsl x21, x21, 3 ; quad align
0:
    subs x21, x21, 8
    cmp x21, 0
    blt 1f

    ldr x0, [x20, x21] ; load map
    mov x1, x19 ; identifier as arg 1
    
    ;stp x0, x1, [sp, -16]!
    ;adrp x0, debug_message@page
    ;add x0, x0, debug_message@pageoff
    ;bl _printf
    ;ldp x0, x1, [sp], 16

    bl _m_get ; check map at this scope

    cbz x0, 0b ; if not, check level lower

1:
    ldp fp, lr, [sp, 16]
    ldr x21, [sp, 32]
    ldp x19, x20, [sp], 48
    ret

; identifier in x0
; entry in x1
_save_entry:
    stp fp, lr, [sp, -16]!
    stp x0, x1, [sp, -16]!
    adrp x0, symbol_table_address@page
    add x0, x0, symbol_table_address@pageoff
    ldr x0, [x0]
    ; get top of symbol table
    bl _s_top
    ldp x1, x2, [sp], 16 ; restore params
    bl _m_insert ; insert
    ldp fp, lr, [sp], 16
    ret

.globl _create_variable_entry
; value in x0
; result in x0
_create_variable_entry:  
    str x19, [sp, -32]!
    stp fp, lr, [sp, 16]
    add fp, sp, 16
    mov x19, x0
    mov x0, 16
    bl _malloc
    mov x1, VARIABLE_TYPE
    str x1, [x0]
    str x19, [x0, 8]
    ldp fp, lr, [sp, 16]
    ldr x19, [sp], 32
    ret

.globl _create_function_entry
; parameter stack in x0
; entry point in x1
; result in x0
_create_function_entry:
    stp fp, lr, [sp, -32]!
    stp x0, x1, [sp, 16]

    mov x0, 24
    bl _malloc ; allocate 24 bytes for function entry
    mov x2, x0

    ldp x0, x1, [sp, 16]
    str x1, [x2, 16] ; write entry
    str x0, [x2, 8] ; write param stack
    mov x0, FUNCTION_TYPE
    str x0, [x2] ; write type

    mov x0, x2 ; return struct

    ldp fp, lr, [sp], 32
    ret




.data
.p2align 3
precedence_table: .quad 0, 1, 1, 2, 2, 3, 3, 3
symbol_table_address: .quad

.section __text,__cstring,cstring_literals
unary_error: .asciz "error: invalid unary operator"
binary_error: .asciz "error: invalid binary operator"
variable_def_error: .asciz "variable definition failed on token %lu\n"
function_def_error: .asciz "function definition failed on token %lu\n"
debug_message: .asciz "I'm about to try to check map %p with identifier %s\n"
