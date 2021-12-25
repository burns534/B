.text
.p2align 2
.globl _m_create
.globl _m_insert
.globl _m_contains
.globl _m_get
.globl _m_remove
.globl _m_destroy

.equ MAP_SIZE, 24 ; bytes
.equ DEFAULT_MAP_CAP, 8 ; quads
.equ DUMMY, -1
.equ AVAIL, 0
; map layout
; word count + 0
; word cap + 4
; quad keys + 8
; quad data + 16

; returns map in x0
_m_create:
    str x19, [sp, -32]!
    stp fp, lr, [sp, 16]
    add fp, sp, 16
    mov x0, MAP_SIZE
    bl _malloc
    ; write count
    str wzr, [x0]
    ; write cap
    mov w1, DEFAULT_MAP_CAP
    str w1, [x0, 4]
    ; save
    mov x19, x0

    ; allocate keys
    lsl w1, w1, 3
    mov w0, w1
    bl _malloc

    ; write keys
    str x0, [x19, 8]

    ; allocate data
    mov w0, w1
    bl _malloc

    ; write data

    str x0, [x19, 16]

    mov x0, x19 ; return map
    
    ldp fp, lr, [sp, 16]
    ldr x19, [sp], 32
    ret

; map in x0
.globl _m_resize
_m_resize:
    stp x21, x22, [sp, -48]!
    stp x19, x20, [sp, 32]
    stp fp, lr, [sp, 16]
    add fp, sp, 16

    mov x19, x0 ; save map in x19
    ldr w20, [x0, 4] ; old cap in x20
    sxtw x20, w20
    lsl w21, w20, 1 ; new cap
    str w21, [x0, 4] ; write new cap
    ldr x22, [x19, 16] ; save old values

    lsl x0, x21, 3
    bl _malloc
    str x0, [x19, 16]; write as new values

    lsl x0, x21, 3
    bl _malloc
    ldr x21, [x19, 8] ; save old keys
    str x0, [x19, 8] ; write as new keys
    
    lsl x20, x20, 3
0:
    subs x20, x20, 8
    ldr x1, [x21, x20]
    cmp x1, 0
    ble 2f
    ldr x2, [x22, x20]
    mov x0, x19
    bl _m_insert_util
2:
    cmp x20, 8
    bge 0b
1:
    ldp fp, lr, [sp, 16]
    ldp x19, x20, [sp, 32]
    ldp x21, x22, [sp], 48
    ret
    
; map in x0
; key in x1
; value in x2
.globl _m_insert_util
_m_insert_util:
    str x19, [sp, -48]!
    stp x20, x21, [sp, 32]
    stp fp, lr, [sp, 16]
    add fp, sp, 16

    mov x19, x0
    mov x20, x1
    mov x21, x2

    mov x0, x1
    bl _m_hash
    mov x4, x0 ; this is not disturbed by hash

    ldr w1, [x19, 4]
    sxtw x1, w1

    udiv x2, x0, x1
    msub x0, x1, x2, x0

    ldr x2, [x19, 8] ; load keys in x2
0:
    ldr x3, [x2, x0, lsl 3]
    cbz x3, 2f
    cmp x3, DUMMY
    beq 1f
; FIXME this needs to be strcmp
    ; check if equal
    stp x0, x1, [sp, -32]!
    stp x2, x3, [sp, 16]
    mov x0, x3
    bl _m_hash
    mov x5, x0
    ldp x2, x3, [sp, 16]
    ldp x0, x1, [sp], 32
    cmp x5, x4
    beq 2f
1:
    add x0, x0, 1
    udiv x3, x0, x1
    msub x0, x3, x1, x0
    b 0b
2:
    str x20, [x2, x0, lsl 3]
    ldr x2, [x19, 16]
    str x21, [x2, x0, lsl 3]

    ldp fp, lr, [sp, 16]
    ldp x20, x21, [sp, 32]
    ldr x19, [sp], 48
    ret



; map in x0
; key in x1
; value in x2
_m_insert:
    stp fp, lr, [sp, -16]!
    ldr w3, [x0, 4]
    ldr w4, [x0]
    add w4, w4, 1 ;update count
    str w4, [x0]
    cmp w3, w4, lsl 1
    bgt 0f

    stp x0, x1, [sp, -32]!
    str x2, [sp, 16]
    bl _m_resize
    ldr x2, [sp, 16]
    ldp x0, x1, [sp], 32
0:
    bl _m_insert_util
    ldp fp, lr, [sp], 16
    ret

; map in x0
; key in x1
; result in x0 1 if true
_m_contains:
    stp fp, lr, [sp, -48]!
    stp x21, x22, [sp, 32]
    stp x19, x20, [sp, 16]

    mov x19, x0 ; save map in x19
    mov x20, x1 ; save key in x20

    mov x0, x1
    bl _m_hash ; calculate hash

    ldr w21, [x19, 4] ; load capacity, save in x21
    sxtw x21, w21 ; sign extend for division

    ; hash mod cap
    udiv x8, x0, x21
    msub x8, x21, x8, x0
    ; load keys
    ldr x22, [x19, 8] 
0:
    ldr x9, [x22, x8, lsl 3]
    cbz x9, 1f ; does not contain
    cmp x9, DUMMY
    beq 2f
    ; otherwise, check if equal
    mov x0, x9 ; current key
    mov x1, x20 ; key 
    str x8, [sp, -16]!
    bl _strcmp
    ldr x8, [sp], 16
    cbz x0, 3f
2:
    add x8, x8, 1 ; hash = (hash + 1) % capacity
    udiv x9, x8, x21
    msub x8, x21, x9, x8
    b 0b
1:
    mov x0, xzr
    b 4f
3:
    mov x0, 1
4:
    ldp x19, x20, [sp, 16]
    ldp x21, x22, [sp, 32]
    ldp fp, lr, [sp], 48
    ret

; map in x0
; key (char *) in x1
; result in x0
_m_get:
    stp x19, x20, [sp, -32]!
    stp fp, lr, [sp, 16]
    add fp, sp, 16

    mov x19, x0 ; save map in x19
    ; calculate hash of key
    mov x0, x1
    mov x20, x1 ; save for later
    bl _m_hash

    ldr w1, [x19, 4] ; cap
    sxtw x1, w1

    ; hash mod cap
    udiv x2, x0, x1
    msub x0, x2, x1, x0
    ; load keys
    ldr x2, [x19, 8]
0:
    ldr x3, [x2, x0, lsl 3]
    cbz x3, 3f
    cmp x3, DUMMY
    beq 2f

; check if equal
    stp x0, x1, [sp, -32]!
    stp x2, x3, [sp, 16]
    ;stp x3, x5, [sp, -16]!
    ;adrp x0, debug_message@page
    ;add x0, x0, debug_message@pageoff
    ;bl _printf
    ;ldp x3, x5, [sp], 16
    mov x0, x3
    mov x1, x20
    bl _strcmp
    mov x4, x0
    ldp x2, x3, [sp, 16]
    ldp x0, x1, [sp], 32
    cbnz x4, 2f ; if not equal, continue

    ldr x2, [x19, 16]
    ldr x0, [x2, x0, lsl 3]
    b 4f
2:
    ; hash = (hash + 1) % capacity
    add x0, x0, 1 ; increment
    udiv x3, x0, x1
    msub x0, x3, x1, x0 
    b 0b
3:
    mov x0, xzr
4:
    ldp fp, lr, [sp, 16]
    ldp x19, x20, [sp], 32
    ret


; map in x0
; key (char *) in x1
_m_remove:
    ; if count is zero return immediately
    ldr w2, [x0]
    cbnz w2, 0f
    ret
0:
    stp x19, x20, [sp, -32]!
    stp fp, lr, [sp, 16]
    add fp, sp, 16

    mov x19, x0 ; save map in x19

    ; calculate hash of key
    mov x0, x1
    mov x20, x1 ; save key for later
    bl _m_hash

    ; load cap
    ldr w1, [x19, 4]
    sxtw x1, w1

    ; hash mod cap
    udiv x2, x0, x1
    msub x0, x1, x2, x0

    ; load keys
    ldr x2, [x19, 8]
0:
    ldr x3, [x2, x0, lsl 3]
    cbz x3, 2f ; does not contain kvp
    cmp x3, DUMMY
    beq 2f ; continue

    ; here check if equal
    stp x0, x1, [sp, -32]!
    stp x2, x3, [sp, 16]

    mov x0, x20
    mov x1, x3
    bl _strcmp
    mov x4, x0
    ldp x2, x3, [sp, 16]
    ldp x0, x1, [sp], 32
    cbz x4, 1f ; equal -> remove
2:
    add x0, x0, 1
    udiv x3, x0, x1
    msub x0, x3, x1, x0
    b 0b
1:
    ; write dummy at current key position to delete
    mov x3, DUMMY
    str x3, [x2, x0, lsl 3]
    ; decrement count
    ldr w1, [x19]
    sub w1, w1, 1
    str w1, [x19]
2:
    ldp fp, lr, [sp, 16]
    ldp x19, x20, [sp], 32
    ret

; map in x0
_m_destroy:
    stp fp, lr, [sp, -32]!
    str x19, [sp, 16]
    mov x19, x0
    ldr x0, [x0, 8] ; keys
    bl _free
    ldr x0, [x19, 16]
    bl _free
    mov x0, x19
    bl _free
    ldr x19, [sp, 16]
    ldp fp, lr, [sp], 32
    ret

; accepts string in x0
; returns hash in x0
_m_hash:
    mov x1, 5381 ; magic number for djb hash
0:
    ldrsb w2, [x0], 1
    cbz w2, 1f
    sxtw x2, w2 ; sign extend word
    add x1, x1, x1, lsl 5 ; hash += (hash << 5)
    add x1, x1, x2 ; hash += *str
    b 0b
1:
    mov x0, x1
    ret

.section __text,__cstring,cstring_literals
debug_message: .asciz "s1, s2: %s, %s\n"