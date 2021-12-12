.text
.p2align 2
.globl _lex
.equ start_state, 0
.equ integer_state, 1
.equ string_token_state, 2
.equ string_literal_state, 3
.equ comment_state, 4
.equ error_state, 5
.equ keyword_count, 8
.equ EOF, -1


; token layout
; type + 0 (unsigned long)
; value + 8 (pointer to null terminated string)

; accept file handle in x0
; return token in x0
_lex:   
    ; use x19 for file handle
    ; use x20 for state
    ; use x21 for buffer
    ; use x22 for current char
    ; use x23 for buffer index
    mov x19, x0
    mov x20, start_state
    adrp x21, buffer@page
    add x21, x21, buffer@pageoff
    mov x23, xzr

0:
    ; read current character
    ; if punct -> change state to punc
    ; if char -> change state to string_token
    ; if num -> state is numtoken
    ; if // change state to comment
    ; if whitespace change to start symbol
    ; default, go to error state

    ; get next
    mov x0, x19
    bl _fgetc
    mov x22, x0

    ; check for eof
    cmp x22, EOF
    beq 3f

    ; check for comment state
    cmp x20, comment_state
    bne 2f ; if not comment, proceed
    ; otherwise, check for endline
2:
    ; check for space.
    bl _isspace
    cbz x0, 1f ; if not space, save to buffer
    mov x20, start_state ; if space, reset state and loop
    b 0b
1: ; save to buffer
    str x19, [x21, x23]
    add x23, x23, 1
; now try letter
    mov x0, x22
    bl _isalpha ; if is alpha, return current token

    b 0b
3:
    ret

; string in x0
; result in x0
_is_keyword:
    sub sp, sp, 48
    stp fp, lr, [sp, 32]
    stp x19, x20, [sp, 16]
    str x21, [sp]
    add fp, sp, 32
    ; use x19 for keyword array
    adrp x19, keywords@page
    add x19, x19, keywords@pageoff
    ; use x20 for counter
    mov x20, keyword_count
    lsl x20, x20, 3 ; shift
    ; use x21 for the string
    mov x21, x0
0:
    sub x20, x20, 8 ; quad alignment

    mov x0, x21 ; load candidate
    ldr x1, [x19, x20] ; load current keyword

    bl _strcmp
    cbz x0, 1f

    cbnz x20, 0b
    mov x0, 0
    b 2f
1:
    mov x0, 1
2: 
    ldr x21, [sp]
    ldp x19, x20, [sp, 16]
    ldp fp, lr, [sp, 32]
    add sp, sp, 48
    ret


.data
.p2align 3

buffer: .skip 256 ; for buffer

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
