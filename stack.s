.text
.globl _create_stack
.globl _push_stack
.globl _pop_stack
.globl _top_stack

.equ DEFAULT_STACK_CAP, 8 * 8 ; 8 quads
.equ STACK_SIZE, 4 + 4 + 8

.p2align 3

; stack requires 16 bytes.
; word count + 0
; word capacity + 4
; quad data + 8

; return stack in x0
_create_stack:
    str x19, [sp, -32]!
    stp fp, lr, [sp, 16]
    add fp, sp, 16
    ; initialize memory to zero for
    mov x0, STACK_SIZE
    bl _malloc
    mov x19, x0 ; store for later in x19

    str wzr, [x0] ; set count to zero

    mov w1, DEFAULT_STACK_CAP
    str w1, [x0, 4] ; set capacity

    ; allocate data
    mov w0, w1
    bl _malloc
    str x0, [x19, 8] ; assign pointer to stack structure
    mov x0, x19 ; return stack pointer from this procedure

    ldp fp, lr, [sp, 16]
    ldr x19, [sp], 32
    ret

; accept stack in x0
; quad value in x1
_push_stack:
    stp x19, x20, [sp, -32]!
    stp fp, lr, [sp, 16]
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

    ldp fp, lr, [sp, 16]
    ldp x19, x20, [sp], 32
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
    ; load data pointer
    ldr x9, [x0, 8]
    ; decrement count and store
    sub w10, w8, 1
    str w10, [x0]
    ; sign extend word for return
    sxtw x8, w10
    ; access value at address, quad alignment
    ldr x0, [x9, x8, lsl 3]
    ret
; stack in x0
; value in x0
_top_stack:
    ; load current count
    ldr w8, [x0]
    sub w8, w8, 1
    sxtw x8, w8
    ldr x9, [x0, 8]
    ldr x0, [x9, x8, lsl 3]
    ret
