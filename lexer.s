.include "types.s"
.include "keywords.s"
.text
.p2align 2
.globl _lex
; FIXME - comment after integer causes infinite loop for some reason

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
    bne 3f

    mov x0, x19
    bl _fgetc
    cmp w0, '='
    mov w24, TS_ADD_A
    beq 4f

    mov x1, x19
    bl _ungetc
    mov w24, TS_ADD
    b 1f
3:
    cmp w20, '-'
    bne 3f

    mov x0, x19
    bl _fgetc
    cmp w0, '>'
    mov w24, TS_PTR
    beq 4f
    cmp w0, '='
    mov w24, TS_SUB_A
    beq 4f

    mov x1, x19
    bl _ungetc
    mov w24, TS_SUB
    b 1f
3:
    cmp w20, '/'
    bne 3f

    mov x0, x19
    bl _fgetc
    cmp w0, '='
    mov w24, TS_DIV_A
    beq 4f

    mov x1, x19
    bl _ungetc
    mov w24, TS_DIV
    b 1f
3:
    cmp w20, '*'
    bne 3f

    mov x0, x19
    bl _fgetc
    cmp w0, '='
    mov w24, TS_MUL_A
    beq 4f

    ; otherwise, unget the character and set adr operator
    mov x1, x19
    bl _ungetc
    mov w24, TS_MUL
    b 1f
3:
    cmp w20, '^'
    bne 3f

    mov x0, x19
    bl _fgetc
    cmp w0, '='
    mov w24, TS_XOR_A
    beq 4f

    ; otherwise, unget the character and set adr operator
    mov x1, x19
    bl _ungetc
    mov w24, TS_XOR
    b 1f
3:
    cmp w20, '%'
    bne 3f

    mov x0, x19
    bl _fgetc
    cmp w0, '='
    mov w24, TS_MOD_A
    beq 4f

    ; otherwise, unget the character and set adr operator
    mov x1, x19
    bl _ungetc
    mov w24, TS_MOD
    b 1f
3:
    cmp w20, '='
    bne 3f

    mov x0, x19
    bl _fgetc
    cmp w0, '='
    mov w24, TS_EQ
    beq 4f

    ; otherwise, unget the character and set adr operator
    mov x1, x19
    bl _ungetc
    mov w24, TS_ASSIGN
    b 1f
3:
    cmp w20, '<'
    bne 3f

    mov x0, x19
    bl _fgetc
    cmp w0, '='
    mov w24, TS_LE
    beq 4f
    cmp w0, '<'
    bne 2f

    adrp x0, debug_message10@page
    add x0, x0, debug_message10@pageoff
    bl _puts

    mov x0, x19
    bl _fgetc
    cmp w0, '='
    mov w24, TS_LEFT_A
    beq 4f

    mov x1, x19
    bl _ungetc
    mov w24, TS_LEFT
    b 1f
2:
    ; otherwise, unget the character and set adr operator
    mov x1, x19
    bl _ungetc
    mov w24, TS_LT
    b 1f
3:
    cmp w20, '>'
    bne 3f

    mov x0, x19
    bl _fgetc
    cmp w0, '='
    mov w24, TS_GE
    beq 4f
    cmp w0, '>'
    bne 2f

    mov x0, x19
    bl _fgetc
    cmp w0, '='
    mov w24, TS_RIGHT_A
    beq 4f

    mov x1, x19
    bl _ungetc
    mov w24, TS_RIGHT
    beq 1f
2:
    ; otherwise, unget the character and set adr operator
    mov x1, x19
    bl _ungetc
    mov w24, TS_GT
    b 1f
3:
    cmp w20, '!'
    bne 3f

    mov x0, x19
    bl _fgetc
    cmp w0, '='
    mov w24, TS_NE
    beq 4f

    ; otherwise, unget the character and set adr operator
    mov x1, x19
    bl _ungetc
    mov w24, TS_NOT
    b 1f
3:
    cmp w20, '&'
    bne 3f

    mov x0, x19
    bl _fgetc
    cmp w0, '&'
    mov w24, TS_LOGICAL_AND
    beq 4f
    cmp w0, '='
    mov w24, TS_AND_A
    beq 4f

    ; otherwise, unget the character and set adr operator
    mov x1, x19
    bl _ungetc
    mov w24, TS_AND
    b 1f
3:
    cmp w20, '|'
    bne 3f

    mov x0, x19
    bl _fgetc
    cmp w0, '|'
    mov w24, TS_LOGICAL_OR
    beq 4f
    cmp w0, '='
    mov w24, TS_OR_A
    beq 4f
    

    ; otherwise, unget the character and set adr operator
    mov x1, x19
    bl _ungetc
    mov w24, TS_OR
    b 1f
3:
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

4:
    mov w20, w0
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
	sub	sp, sp, 16            
                                     
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

; w20 current char
; x21 buffer
; x22 buffer index
_identifier_token:
    stp fp, lr, [sp, -16]!
; identifier must start with letter or _
    cmp w20, '_'
    beq 0f
    mov w0, w20
    bl _isalpha
    cbnz w0, 0f
    mov x0, xzr
    b 10f
0:  
    strb w20, [x21, x22] ; write char to buffer
    add x22, x22, 1 ; increment buffer count

    mov x0, x19
    bl _fgetc
    mov w20, w0 ; set current char
    
    cmp w0, '_'
    beq 0b
    bl _isalpha
    cbnz x0, 0b
    mov w0, w20
    bl _isdigit
    cbnz x0, 0b
; fallthrough
    ; null terminate
    str wzr, [x21, x22]

    bl _keyword
    cmp x0, -1
    mov x1, TS_IDENTIFIER
    csel x0, x1, x0, eq
    bl _create_token
10:
    ldp fp, lr, [sp], 16
    ret


_string_token:
    cmp w20, '"' ; check if current char is double quote
    beq 0f
    ret
0:
    stp fp, lr, [sp, -16]!
1:
    ; get next character
    mov x0, x19
    bl _fgetc
    cmp w0, '"'
    beq 3f
    cmp w0, '\\' ; escape character
    bne 2f
; handle escape char
    mov x0, x19
    bl _fgetc
; could probably use a table or something here
    cmp w0, 'n'
    mov w0, 10 ; lf
    beq 2f
    cmp w0, 'r'
    mov w0, 13 ; cr
    bne 2f
    cmp w0, 't'
    mov w0, 9 ; tab
    bne 2f
    cmp w0, 'f'
    mov w0, 12 ; form feed
    bne 2f
    cmp w0, '0'
    mov w0, 0 ; null
    bne 2f
    cmp w0, '''
    bne 2f
    cmp w0, '"'
    bne 2f
    cmp w0, '\\'
    bne 2f
    cmp w0, 'b'
    mov w0, 8 ; backspace
    bne 2f
    cmp w0, 'v'
    mov w0, 11 ; vertical tab
    bne 2f
2:
    ; store in buffer and increment buffer index
    strb w0, [x21, x22]
    add x22, x22, 1
    b 1b
3:
    ; skip past the quote
    mov x0, x19
    bl _fgetc
    mov w20, w0
    ; generate token
    mov x0, TS_STRING
    bl _create_token
    ldp fp, lr, [sp], 16
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

    bl _m_strcmp
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

.section __TEXT,__cstring,cstring_literals
error_string: .asciz "error: invalid token %c\n"
debug_message10: .asciz "encountered second < char"
