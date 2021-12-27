.text
.p2align 2
.globl _m_create
.globl _m_insert
.globl _m_contains
.globl _m_get
.globl _m_remove
.globl _m_destroy
.globl _m_strcmp
.globl _m_resize
.globl _m_insert_util
; FIXME - needs to be rewritten in an optimized way

.equ MAP_SIZE, 4 + 4 + 8 + 8 ; bytes
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
    stp fp, lr, [sp, -32]!
    str x19, [sp, 16]

    mov x0, MAP_SIZE
    bl _malloc
    mov x19, x0 ; save map to return later

    str wzr, [x0] ; write count as zero
    ; write cap
    mov w1, DEFAULT_MAP_CAP
    str w1, [x0, 4] ; write capacity

    ; allocate keys (must be zeroed)
    sxtw x0, w1 ; array of 8
    mov x1, 8 ; with 8 byte alignment
    bl _calloc

    ; write keys
    str x0, [x19, 8]

    ; allocate data, don't have to be zero
    mov x0, DEFAULT_MAP_CAP
    lsl x0, x0, 3 ; quad
    bl _malloc

    str x0, [x19, 16] ; write data array at its offset

    mov x0, x19 ; return map
    
    ldr x19, [sp, 16]
    ldp fp, lr, [sp], 32
    ret

; map in x0
_m_resize:
    stp fp, lr, [sp, -64]!
    stp x21, x22, [sp, 48]
    stp x19, x20, [sp, 32]
    stp x1, x2, [sp, 16] ; guaranteed not to clobber x0, x1, x2
    
    mov x19, x0 ; map x19
    ldr w20, [x0, 4] ; old cap in x20

    lsl w21, w20, 1 ; double capacity and save in w21
    str w21, [x0, 4] ; write new capacity in map structure

    ldr x22, [x19, 16] ; save current values pointer x22

; allocate values
    lsl w0, w21, 3 ; quad alignment
    bl _malloc
    str x0, [x19, 16] ; write as new values

    mov w0, w21
    mov x1, 8 ; 8 byte, quad alignment
    bl _calloc
    ldr x21, [x19, 8] ; save old keys
    str x0, [x19, 8] ; write as new keys
    
    lsl w20, w20, 3 ; shift capacity to use as direct offset
0:
    subs w20, w20, 8
    ldr x1, [x21, x20] ; key
    cmp x1, 0
    ble 2f
    ldr x2, [x22, x20] ; value
    mov x0, x19
    bl _m_insert_util
2:
    cbnz w20, 8
1:
    mov x0, x19 ; restore x0
    ldp x1, x2, [sp, 16]
    ldp x19, x20, [sp, 32]
    ldp x21, x22, [sp, 48]
    ldp fp, lr, [sp], 64
    ret
    
    ; could be optimized even further by allocating keys and values in the same block
    ; and using stp to store the key and value next to each other
    ; much better cache performance also
; map in x0
; key in x1
; value in x2
_m_insert_util: ; clobbers x0, x1, x2, x8, x9, x10, x11, x12, x13, x14
    stp fp, lr, [sp, -16]!
    mov x8, x0 ; map
    mov x9, x1 ; key
    mov x10, x2 ; value

    stp x8, x9, [sp, -32]!
    str x10, [sp, 16]

    adrp x0, debug_message@page
    add x0, x0, debug_message@pageoff

    bl _printf

    ldr x10, [sp, 16]
    ldp x8, x9, [sp], 32

    mov x0, x9
    bl _m_hash ; calculate hash of key, clobbers x0, x1, x2

    ldr w11, [x8, 4] ; load capacity
    lsl w11, w11, 3 ; quad alignment to avoid doing it repeatedly
    sub w11, w11, 1 ; for optimized modulo operation

    ldr x12, [x8, 8] ; keys

    and x14, xzr, x14
    subs x14, x14, 8
0:
; this calculates modulo for divisors of power 2
    adds w14, w14, 8
    and w14, w14, w11 ; hash in w14

    ldr x13, [x12, x14] ; load key
    cmp x13, 0
    blt 0b ; dummy
    beq 1f ; insert

    ; nonzero, check string
    mov x0, x9 ; key
    mov x1, x13 ; current key
    bl _m_strcmp ; clobbers x0, x1, x2, x3
    cbnz w0, 0b ; continue if not equal

1:
    str x9, [x12, x14] ; write key
    ldr x12, [x8, 16] ; values
    str x10, [x12, x14] ; write value

    ldp fp, lr, [sp], 16
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
    bl _m_resize ; does not clobber x0, x1, or x2
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
    stp fp, lr, [sp, -32]!
    stp x19, x20, [sp, 16]

    mov x19, x0 ; save map in x19
    mov x20, x1 ; save key in x20

    ; calculate hash of key
    mov x0, x1
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
    ldp x19, x20, [sp, 16]
    ldp fp, lr, [sp], 32
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
; returns hash in w0
_m_hash: ; clobbers x0, x1, x2
    movz w1, 5381 ; magic number for djb hash
0:
    ldrb w2, [x0], 1 ; not a signed byte
    cbz w2, 1f
    add w1, w1, w1, lsl 5 ; hash += (hash << 5)
    add w1, w1, w2 ; hash += *str
    b 0b
1:
    mov w0, w1
    ret

; string 1 x0
; string 2 x1
; result in x0
; would like to look into 64 bit comparisons here...
_m_strcmp: ; clobbers x0, x1, x2, x3
    ldrb w2, [x0], 1
    ldrb w3, [x1], 1
    cmp w2, w3
    bne 1f
    cbnz w2, _m_strcmp
1:  
    subs w0, w3, w2
    ret

.section __text,__cstring,cstring_literals
debug_message: .asciz "insert_util called with map: %p, key: %s, and value: %lu\n"