.text
.p2align 2
.globl _m_create
.globl _m_insert
.globl _m_get
.globl _m_remove

.equ MAP_SIZE, 24 ; bytes
.equ DEFAULT_MAP_CAP, 8 ; quads
.equ DUMMY, -1
.equ AVAIL, 0
.equ OCUPIED, 1
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

_m_insert:
    stp x21, x22, [sp, -48]!
    stp x19, x20, [sp, 32]
    stp fp, lr, [sp, 16]
    add fp, sp, 16

    mov x19, x0 ; map
    mov x20, x1 ; key
    mov x21, x2 ; value

    ldr w0, [x19] ; load count

    ldr w1, [x19, 4] ; load cap

    ; compare
    cmp w1, w0, lsl 1
    bgt 0f

    ; resize here

    ; save keys and values arrays
    stp x22, x23, [sp, -16]!
    str x24, [sp, -16]!
    ldr x22, [x19, 8] ; keys
    ldr x23, [x19, 16] ; values

    lsl w1, w1, 1 ; double cap
    str w1, [x19, 4] ; write new cap
    sxtw x0, w1 ; sign extend for malloc
    lsl x0, x0, 3 ; quad align
    bl _malloc
    str x0, [x19, 8] ; store new keys array

    ldr w0, [x19, 4]
    sxtw x0, w0
    lsl x0, x0, 3
    bl _malloc
    str x0, [x19, 16] ; store new values array

    ; repopulate arrays from old data
    ; load capacity
    ldr w24, [x19, 4]
    sxtw x24, w24
    lsr x24, x24, 1 ; halve
1:
    sub x24, x24, 1
    cmp x24, 0
    blt 1f
    ldr x2, [x23, x24, lsl 3] ; load value
    cbz x2, 1b
    ldr x1, [x22, x24, lsl 3] ; load key
    mov x0, x19
    bl _m_insert
    b 1b
1:
    ldr x24, [sp], 16
    ldp x22, x23, [sp], 16

0:
    ; calculate hash
    mov x0, x20
    bl _m_hash
    mov x22, x0

    ; load capacity
    ldr w1, [x19, 4]
    sxtw x1, w1

    ; hash mod cap
    udiv x2, x0, x1
    msub x0, x2, x1, x0

    ; load keys
    ldr x2, [x19, 8]

0:
    ldr x3, [x2, x0, lsl 3] ; load key entry
    cmp x3, AVAIL
    ble 1f ; branch to insert
    ; save registers and calculate hash of the current key
    stp x0, x1, [sp, -32]!
    stp x2, x3, [sp, 16]
    mov x0, x3
    bl _m_hash
    mov x4, x0
    ldp x2, x3, [sp, 16]
    ldp x0, x1, [sp], 32
    cmp x4, x22 ; if hash equal, skip to insert
    beq 2f ; don't increment count

    add x0, x0, 1 ; linear probe
    udiv x3, x0, x1
    msub x0, x3, x0, x1
    b 0b
1:
    ldr w0, [x19] ; load count
    add w0, w0, 1 ; increment
    str w0, [x19] ; store count
2:
    ; insert key
    str x20, [x2, x0, lsl 3]
    ldr x2, [x19, 16] ; load values
    str x21, [x2, x0, lsl 3] ; insert value

    ldp fp, lr, [sp, 16]
    ldp x19, x20, [sp, 32]
    ldp x21, x22, [sp], 48
    ret

; map in x0
; key (char *) in x1
; result in x0
_m_get:
    str x19, [sp, -32]!
    stp fp, lr, [sp, 16]
    add fp, sp, 16

    mov x19, x0 ; save map in x19
    ; calculate hash of key
    mov x0, x1
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
    cbnz x3, 1f
    mov x0, 0
    b 3f
1:
    cmp x3, DUMMY
    beq 2f
    ldr x2, [x19, 16]
    ldr x0, [x2, x0, lsl 3]
    b 3f
2:
    ; hash = (hash + 1) % capacity
    add x0, x0, 1 ; increment
    udiv x3, x0, x1
    msub x0, x3, x1, x0 
    b 0b
3:
    ldp fp, lr, [sp, 16]
    ldr x19, [sp], 32
    ret


; map in x0
; key (char *) in x1
; result in x0, null if not
_m_remove:

    mov x19, x0 ; save map in x19

    ; calculate hash of key
    mov x0, x1
    bl _m_hash

    ; load cap
    ldr w1, [x19, 4]
    sxtw x1, w1

    ; hash mod cap
    udiv x2, x0, x1
    msub x0, x1, x2, x0

0:
    

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