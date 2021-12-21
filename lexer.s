.text
.p2align 2
.globl _lex
.equ keyword_bytes, 8 * 8 ; need to add extrn
.include "types.s"


; token layout
; type + 0 (unsigned long)
; value + 8 (pointer to null terminated string)

; accept file handle in x0
; return token in x0
_lex:   
    sub sp, sp, 64
    stp fp, lr, [sp, 48]
    stp x19, x20, [sp, 32]
    stp x21, x22, [sp, 16]
    stp x23, x24, [sp]
    add fp, sp, 48
    ; use x19 for file handle
    ; use x20 for current char
    ; use x21 for buffer
    ; use x22 for buffer index
    ; use x23 for address of current char byte
    mov x19, x0
    adrp x23, current_char@page
    add x23, x23, current_char@pageoff
    ldrsb w20, [x23] ; load current character

    adrp x21, buffer@page
    add x21, x21, buffer@pageoff

    mov x22, xzr ; set buffer index to zero

    ; get character if current character is zero
    cbnz w20, 2f
    bl _fgetc
    mov w20, w0 ; store in w20
2:
    ; if eof, return null
    cmp w20, -1
    bne 1f
    mov x0, TS_EOF
    bl _create_token
    b 0f
1:
    bl _whitespace
    bl _integer_token ; try integer token
    cbnz x0, 0f
    bl _string_token
    cbnz x0, 0f
    bl _identifier_token
    cbnz x0, 0f

    ; check for operators
    cmp w20, '+'
    mov w24, TS_ADD
    beq 1f
    cmp w20, '-'
    mov w24, TS_SUB
    beq 1f
    cmp w20, '/'
    mov w24, TS_DIV
    beq 1f
    cmp w20, '*'
    mov w24, TS_MUL
    beq 1f
    cmp w20, '%'
    mov w24, TS_MOD
    beq 1f
    cmp w20, '='
    mov w24, TS_ASSIGN
    beq 1f
    cmp w20, '<'
    mov w24, TS_LT
    beq 1f
    cmp w20, '!'
    mov w24, TS_NOT
    beq 1f
    cmp w20, '?'
    mov w24, TS_EQ
    beq 1f
    cmp w20, '&'
    mov w24, TS_ADR
    beq 1f
    cmp w20, '('
    mov w24, TS_OPEN_PAREN
    beq 1f
    cmp w20, ')'
    mov w24, TS_CLOSE_PAREN
    beq 1f
    cmp w20, '{'
    mov w24, TS_OPEN_CURL_BRACE
    beq 1f
    cmp w20, '}'
    mov w24, TS_CLOSE_CURL_BRACE
    beq 1f
    cmp w20, '['
    mov w24, TS_OPEN_SQ_BRACE
    beq 1f
    cmp w20, ']'
    mov w24, TS_CLOSE_SQ_BRACE
    beq 1f
    cmp w20, '.'
    mov w24, TS_DOT
    beq 1f
    cmp w20, ';'
    mov w24, TS_SEMICOLON
    beq 1f
    cmp w20, ':'
    mov w24, TS_COLON
    beq 1f
    cmp w20, ','
    mov w24, TS_COMMA
    beq 1f

    bl _error

1:
    ; store current character in buffer
    strb w20, [x21]
    mov x22, 1 ; buffer index

    ; get next character
    mov x0, x19
    bl _fgetc
    mov w20, w0

    ; create operator token with appropriate type which is stored in w24
    ; now return token will be in x0 as it should be
    sxtw x0, w24
    bl _create_token
0:

    ; store current character for next call
    strb w20, [x23]

    ; restore registers
    ldp x23, x24, [sp]
    ldp x21, x22, [sp, 16]
    ldp x19, x20, [sp, 32]
    ldp fp, lr, [sp, 48]
    add sp, sp, 64
    ret

_error:                           
; %bb.0:
	sub	sp, sp, 32                
	stp	fp, lr, [sp, 16]          
	add	fp, sp, 16             
                                     
	sxtw x20, w20
    str	x20, [sp]

	adrp x0, error_string@page
	add	x0, x0, error_string@pageoff

	bl	_printf
	mov	w0, 1
	bl	_exit

; w20 current char
; x21 buffer
; x22 buffer index
_integer_token:
    stp fp, lr, [sp, -16]!
    mov w0, w20 ; move current character as argument
    ; only need to do this move once because w0 holds next char
    ; after first iteration
0:
    bl _isdigit
    cbz w0, 1f
    strb w20, [x21, x22] ; store char
    add x22, x22, 1 ; increment buffer index
    ; get next character
    mov x0, x19 ; file handler
    bl _fgetc
    mov w20, w0 ; put in w20
    b 0b
1:
    mov x0, xzr ; return value null if we don't create token
    cbz x22, 2f ; if buffer length is zero, return
    ; generate token
    mov x0, TS_INTEGER
    bl _create_token
2:
    ldp fp, lr, [sp], 16
    ret

_identifier_token:
    stp fp, lr, [sp, -16]!
    mov w0, w20 ; move current character as argument
    ; only need to do this move once because w0 holds next char
    ; after first iteration
0:
    cmp w20, '_'
    beq 2f
    bl _isalpha
    cbz w0, 1f
2:
    strb w20, [x21, x22] ; store char
    add x22, x22, 1 ; increment buffer index
    ; get next character
    mov x0, x19 ; file handler
    bl _fgetc
    mov w20, w0 ; put in w20
    b 0b
1:
    mov x0, xzr ; return value null if we don't create token
    cbz x22, 2f ; if buffer length is zero, return

    ; now check if it is a keyword
    bl _keyword
    ; if -1, return identifier
    cmp x0, -1
    bne 3f

    mov x0, TS_IDENTIFIER
3:
    bl _create_token
2:
    ldp fp, lr, [sp], 16
    ret

_string_token:
    cmp w20, '"' ; check if current char is double quote
    bne 3f
    stp fp, lr, [sp, -16]!
0:
    ; get next character
    mov x0, x19
    bl _fgetc
    mov w20, w0 ; set current character
    cmp w20, '"'
    beq 1f
    ; store in buffer and increment buffer index
    strb w20, [x21, x22]
    add x22, x22, 1
    b 0b
1:
    ; skip past the quote
    mov x0, x19
    bl _fgetc
    mov w20, w0
    ; generate token
    mov x0, TS_STRING
    bl _create_token
2:
    ldp fp, lr, [sp], 16
3:
    ret

; skips whitespace
_whitespace:
    stp fp, lr, [sp, -16]!
0:
    bl _comment
    cbnz x0, 0b
    mov w0, w20
    bl _isspace
    cbz x0, 1f
    mov x0, x19
    bl _fgetc
    mov w20, w0
    b 0b
1:
    ldp fp, lr, [sp], 16
    ret

; current char in w20
; return true or false in x0
_comment:
    mov x0, xzr
    cmp w20, '#'
    bne 1f
    stp fp, lr, [sp, -16]!
0:
    mov x0, x19
    bl _fgetc
    cmp w0, 10
    bne 0b

    ; get next character
    mov x0, x19
    bl _fgetc
    ; if it is a hashtag, start over
    cmp w0, '#'
    beq 0b
    ; otherwise, put it in w20
    mov w20, w0
    ldp fp, lr, [sp], 16
    mov x0, 1
1:
    ret

; uses string in buffer x21
; keyword index result in x0
_keyword:
    sub sp, sp, 32
    stp fp, lr, [sp, 16]
    stp x19, x20, [sp]
    add fp, sp, 16

    adrp x19, keywords@page
    add x19, x19, keywords@pageoff
    ; use x20 for counter
    mov x20, xzr
0:
    ; load candidate
    mov x0, x21
    ; load current keyword
    ldr x1, [x19, x20]

    bl _strcmp
    cbz w0, 1f

    ; increment counter
    add x20, x20, 8 ; quad aligned
    cmp x20, keyword_bytes
    blt 0b ; check next keyword
    ; otherwise, return -1
    mov x0, -1
    b 2f
1:
    lsr x0, x20, 3 ; shift from quad alignment to keyword index
2:
    ldp x19, x20, [sp]
    ldp fp, lr, [sp, 16]
    add sp, sp, 32
    ret

; I'm not sure this ever worked right...
; accept type in as quad in x0
; return token in x0
_create_l1_token:
    sub sp, sp, 48
    stp fp, lr, [sp, 32]
    stp x27, x28, [sp, 16]
    str x26, [sp]
    add fp, sp, 32

    adrp x26, token@page
    add x26, x26, token@pageoff
    ; sign extend type
    sxtw x0, w0
    str x0, [x26] ; store type in first quad

    ; allocate memory for buffer
    ; x21 is buffer, x22 is length
    ; null terminate string
    str xzr, [x21, x22]
    ; allocate memory plus newline
    add x27, x22, 1
    bl _malloc ; why is malloc's argument the type of the token?
    mov x28, x0 ; address of new memory location in x28
    mov x1, x21 ; buffer
    mov x2, x27 ; max copy length
    bl ___strcpy_chk ; copy buffer to new memory including null char

    str x28, [x26, 8] ; store pointer to string
    mov x22, xzr ; buffer length to zero
    mov x0, x26 ; return pointer to token memory

    ldr x26, [sp]
    ldp x27, x28, [sp, 16]
    ldp fp, lr, [sp, 32]
    add sp, sp, 48
    ret

; accept type in as quad in x0
; return token in x0
_create_token:
    stp x26, x27, [sp, -32]!
    stp fp, lr, [sp, 16]
    add fp, sp, 16

    mov x27, x0 ; save arg temporarily

    ; allocate the token memory with malloc and put in x26
    mov x0, 16
    bl _malloc
    mov x26, x0

    str x27, [x26] ; store type in token + 0

    ; allocate memory for buffer
    ; x21 is buffer, x22 is length
    ; null terminate string first
    str xzr, [x21, x22]
    ; allocate memory plus newline
    add x0, x22, 1
    bl _malloc
    mov x27, x0 ; save string address to x27
    mov x1, x21 ; buffer
    add x2, x22, 1 ; max copy length ; this may be a problem
    bl ___strcpy_chk ; copy buffer to new memory including null char

    str x27, [x26, 8] ; store pointer to string in token + 8
    mov x22, xzr ; buffer length to zero
    mov x0, x26 ; return pointer to token memory

    ldp fp, lr, [sp, 16]
    ldp x26, x27, [sp], 32
    ret

.data
.p2align 3

buffer: .skip 256 ; for buffer
current_char: .byte 0
token: .quad 0, 0 ; this was for when the parser was ll1

; 9 keywords
.p2align 3
keywords:
    .quad break
    .quad continue
    .quad else
    .quad if
    .quad register
    .quad return
    .quad struct
    .quad while

break: .asciz "break"
continue: .asciz "continue"
else: .asciz "else"
if: .asciz "if"
register: .asciz "register"
return: .asciz "return"
struct: .asciz "struct"
while: .asciz "while"

.section __TEXT,__cstring,cstring_literals
error_string: .asciz "error: invalid token %c\n"
