.text
.p2align 2
.globl _parse
.equ NODE_SIZE, 36
.equ DEFAULT_CHILD_CAP, 8

_parse:
    ret

; node layout 36 bytes
; word child_count + 0
; word child_cap + 4
; quad parent + 8
; quad children + 16
; quad value + 24
; word type + 32


; type in x0
; parent in x1
; returns node in x0
.globl _create_node
_create_node:
    sub sp, sp, 32
    stp fp, lr, [sp, 16]
    stp x19, x20, [sp]
    add fp, sp, 16

    mov x19, x0 ; x19 holds type
    mov x20, x1

    mov x0, NODE_SIZE ; node size
    bl _malloc
    str w19, [x0, 32]  ; store type
    str x20, [x0, 8] ; store parent
    str wzr, [x0] ; set child count zero

    ; save node in 19
    mov x19, x0
    ; allocate children array
    mov x0, DEFAULT_CHILD_CAP
    ; store child capacity
    str w0, [x19, 4]
    mov x1, 8 ; 8 bytes, second argument for calloc
    bl _calloc
    ; save pointer in struct at children offset
    str x0, [x19, 16]

    ; add node as parent's child
    mov x0, x19
    mov x1, x20
    bl _add_child

    ; return node
    mov x0, x19

    ldp x19, x20, [sp]
    ldp fp, lr, [sp, 16]
    add sp, sp, 32
    ret

.globl _add_child
; accept child in x0
; accept node in x1
_add_child:
    ; make sure node isn't null
    cbnz x1, 0f
    ret
0:
    sub sp, sp, 32
    stp fp, lr, [sp, 16]
    stp x19, x20, [sp]
    add fp, sp, 16
    ; save child and node in x19 and x20 respectively
    mov x19, x0
    mov x20, x1

    ; load count and capacity
    ldr w8, [x1] ; count
    ldr w9, [x1, 4] ; capacity
    cmp w9, w8, lsl 1
    bgt 1f
    ; resize

1:
    ; add child
    ; load children
    ldr x0, [x20, 16]
    ; store child at offset of child count
    ldr w1, [x20] ; load child count
    sxtw x1, w1 ; sign extend count for offset
    str x19, [x0, x1, lsl 3] ; quad offset
    ; increment count and store
    add w1, w1, 1
    str w1, [x20]

    ldp x19, x20, [sp]
    ldp fp, lr, [sp, 16]
    add sp, sp, 32
    ret

;.globl _get_production
; accept symbol stack nts in x0
; accept nts in x1
; return pointer to production in x0
_get_production:
    
