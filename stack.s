.text
.globl _create_stack
.globl _push_stack
.globl _pop_stack
.globl _top_stack

.equ DEFAULT_STACK_CAP, 8 * 8 ; 8 quads

.p2align 3

// stack requires 16 bytes.
// layout as follows
// word count + 0
// word capacity + 4
// quad data + 8

; return stack in x0
_create_stack:
    sub sp, sp, 32
    stp fp, lr, [sp, 16]
    str x19, [sp]
    add fp, sp, 16
    mov x0, 16
    mov x1, 1
    bl _calloc
    ; initialize to default capacity
    mov w1, DEFAULT_STACK_CAP
    str w1, [x0, 4]
    ; store stack in x19
    mov x19, x0
    ; allocate data
    mov w0, w1
    bl _malloc
    str x0, [x19, 8] ; assign pointer to stack structure
    mov x0, x19 ; return pointer
    ldr x19, [sp]
    ldp fp, lr, [sp, 16]
    add sp, sp, 32
    ret

; accept stack in x0
; quad value in x1
_push_stack:
    sub sp, sp, 32
    stp fp, lr, [sp, 16]
    stp x19, x20, [sp]
    add fp, sp, 16
    mov x19, x0 ; use x19 for stack
    mov x20, x1 ; use x20 for value

    ; load stack count and check if need to resize
    ldr w8, [x19] ; load count
    ldr w9, [x19, 4] ; load cap
    cmp w9, w8, lsl 1 ; compare cap to count times two
    bgt 0f ; if it's greater, do nothing, otherwise resize
    ; resize here
    lsl w9, w9, 1 ; double cap
    str w9, [x19, 4] ; store new cap

    ; call realloc
    ldr x0, [x19, 8] ; load current data address
    sxtw x1, w9 ; sign extend new size to x1 for argument
    ; use quad alignment for new size
    lsl x1, x1, 3
    bl _realloc
    str x0, [x19, 8] ; store new pointer
0:
    ; insert here
    ; load pointer to data
    ldr x0, [x19, 8]
    ldr w1, [x19] ; load count
    sxtw x1, w1 ; sign extend w1 to x1
    str x20, [x0, x1, lsl 3] ; store value in data at count offset with quad alignment
    ; increment count and store
    add x1, x1, 1
    str w1, [x19]

    ldp x19, x20, [sp]
    ldp fp, lr, [sp, 16]
    add sp, sp, 32
    ret
; accept stack in x0
; return value in x0
_pop_stack:
    ; load current count
    ldr w8, [x0]
    ; guard to make sure stack isn't empty
    cbnz w8, 0f
    ret
0:
    sxtw x8, w8 ; sign extend word
    ; load data pointer
    ldr x9, [x0, 8]
    ; decrement count and store
    sub w10, w8, 1
    str w10, [x0]
    ; access value at address, quad alignment
    ldr x0, [x9, x8, lsl 3]
    ret
; stack in x0
; value in x0
_top_stack:
    ; load current count
    ldr w8, [x0]
    sxtw x8, w8
    ldr x9, [x0, 8]
    ldr x0, [x9, x8, lsl 3]
    ret
