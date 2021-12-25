.text
.p2align 2
.include "types.s"
.globl _variable_definition
.globl _function_definition
; tokens in x0 
; cursor pointer in x1
; return cursor in x0
_variable_definition:

    ; load current token and check for var, abort early if not
    ldr x2, [x1]
    ldr x8, [x0, x2, lsl 3]
    ldr x8, [x8]

    ;stp x0, x1, [sp, -16]!
    ;stp x8, lr, [sp, -16]!
    ;adrp x0, debug_message3@page
    ;add x0, x0, debug_message3@pageoff
    ;bl _printf
    ;ldp x8, lr, [sp], 16
    ;ldp x0, x1, [sp], 16

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
    bne _variable_definition_runtime_error1

    add x20, x20, 1 ; advance to next token
    
    ; check for assignment operator
    ldr x8, [x19, x20, lsl 3]
    ldr x8, [x8]
    cmp x8, TS_ASSIGN
    bne _variable_definition_runtime_error2

    add x20, x20, 1 ; advance cursor

    ;ldr x0, [x19, x20, lsl 3]
    ;bl _primary_eval ; converts primary expressions to single word
    mov x0, x19
    str x20, [x22]
    mov x1, x22
    bl _expression_eval ; evaluate rvalue
    bl _create_variable_entry ; create variable entry with value

    ; update cursor after expression eval
    ldr x20, [x22]

    ; save entry
    mov x1, x0
    ldr x0, [x21, 8] ; load identifier from token saved earlier
    bl _save_entry

    ; assert semicolon

    ldr x8, [x19, x20, lsl 3]
    ldr x8, [x8]
    cmp x8, TS_SEMICOLON
    bne _variable_definition_runtime_error3

    add x20, x20, 1 ; advance cursor to next candidate token and return in x0
    str x20, [x22] ; write cursor

    mov x0, 1 ; return true

    ldp fp, lr, [sp, 16]
    ldp x19, x20, [sp, 32]
    ldp x21, x22, [sp], 48
    ret

_variable_definition_runtime_error1:
    ; throw runtime error
    adrp x0, variable_def_error1@page
    add x0, x0, variable_def_error1@pageoff
    str x8, [sp, -16]!
    bl _printf

    mov w0, 1
    bl _exit

_variable_definition_runtime_error2:
    ; throw runtime error
    adrp x0, variable_def_error2@page
    add x0, x0, variable_def_error2@pageoff
    str x8, [sp, -16]!
    bl _printf

    mov w0, 1
    bl _exit

_variable_definition_runtime_error3:
    ; throw runtime error
    adrp x0, variable_def_error3@page
    add x0, x0, variable_def_error3@pageoff
    str x8, [sp, -16]!
    bl _printf

    mov w0, 1
    bl _exit


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

    ;str x0, [sp, -16]!
    ;adrp x0, debug_message@page
    ;add x0, x0, debug_message@pageoff
    ;bl _printf
    ;ldr x0, [sp], 16

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
50:
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

.section __text,__cstring,cstring_literals
variable_def_error1: .asciz "error: variable definition: expected identifier instead found %lu\n"
variable_def_error2: .asciz "error: variable definition: expected assign instead found %lu\n"
variable_def_error3: .asciz "error: variable definition: expected semicolon instead found %lu\n"
function_def_error: .asciz "function definition failed on token %lu\n"
debug_message: .asciz "about to save entry with key: %s\n"