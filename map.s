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

.equ MAP_SIZE, 4 + 4 + 8 + 8 ; bytes
.equ DEFAULT_MAP_CAP, 16 ; quads
.equ DUMMY, -1
.equ AVAIL, 0
; map layout
; word count + 0
; word cap + 4
; quad keys + 8
; quad data + 16

; could potentially be optimized even further by allocating keys and values in the same block
; and using stp/ldp for key and value storage/retrieval
; probably better cache performance also

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

    str wzr, [x19] ; set count to zero since insert_utils will increment

    ldr w20, [x19, 4] ; old cap in x20

    lsl w21, w20, 1 ; double capacity and save in w21
    str w21, [x19, 4] ; write new capacity in map structure

    ldr x22, [x19, 16] ; save current values pointer x22

; allocate values
    lsl w0, w21, 3 ; quad alignment
    bl _malloc
    str x0, [x19, 16] ; write as new values

    mov w0, w21 ; new capacity
    mov w1, 8 ; 8 byte, quad alignment
    bl _calloc
    ldr x21, [x19, 8] ; save old keys
    str x0, [x19, 8] ; write as new keys
    
    lsl w20, w20, 3 ; shift capacity to use as direct offset
0:
    subs w20, w20, 8
    ldr x1, [x21, x20] ; key
    cmp x1, 0
    ble 2f ; dummy or empty
    ldr x2, [x22, x20] ; value
    mov x0, x19
    bl _m_insert_util
2:
    cbnz w20, 0b ; branch if offset is still valid
1:
    mov x0, x19 ; restore x0
    ldp x1, x2, [sp, 16] ; restore x1 and x2
    ldp x19, x20, [sp, 32]
    ldp x21, x22, [sp, 48]
    ldp fp, lr, [sp], 64
    ret
    
; map in x0
; key in x1
; value in x2
_m_insert_util: ; clobbers x0, x1, x2, x8, x9, x10, x11, x12, x13, x14
    stp fp, lr, [sp, -16]!
    mov x8, x0 ; map
    mov x9, x1 ; key
    mov x10, x2 ; value

    mov x0, x9 ; move key as argument for hash
    bl _m_hash ; calculate hash of key, clobbers x0, x1, x2

    ldr w11, [x8, 4] ; load capacity
    sub w11, w11, 1 ; for optimized modulo operation

    ldr x12, [x8, 8] ; keys

    and x14, x0, x11 ; hash % capacity
0:
    ldr x13, [x12, x14, lsl 3] ; load key
    cmp x13, 0
    beq 2f
    blt 1f

    mov x0, x9 ; key
    mov x1, x13 ; current key
    bl _m_strcmp ; clobber x0, x1, x2
    cbz w0, 3f
1:
    add w14, w14, 1 ; index += 1
    and w14, w14, w11 ; index %= capacity
    b 0b

2:
    ldr w13, [x8] ; load count
    add w13, w13, 1 ; increment
    str w13, [x8] ; store updated count

3: ; insert
    str x9, [x12, x14, lsl 3] ; write key
    ldr x12, [x8, 16] ; values
    str x10, [x12, x14, lsl 3] ; write value

    ldp fp, lr, [sp], 16
    ret

; map in x0
; key in x1
; value in x2
_m_insert:
    cmp x0, x1
    bne 0f
    ret
0:
    stp fp, lr, [sp, -16]!
    ldp w3, w4, [x0] ; load count and capacity
    cmp w4, w3, lsl 1 ; if capacity > count * 2, skip resize
    bgt 0f
    bl _m_resize ; does not clobber x0, x1, or x2
0:
    bl _m_insert_util
    ldp fp, lr, [sp], 16
    ret

; map in x0
; key in x1
; result boolean in x0
_m_contains:
    ; check key isn't null
    cmp x1, x0
    bne 0f
    ret
0:  
    stp fp, lr, [sp, -16]!
    ldr x8, [x0, 8] ; load keys x8
    mov x9, x1 ; key
    ldr w10, [x0, 4] ; load capacity w10
    sub w10, w10, 1 ; for optimized modulo
    and x11, xzr, x11 ; clear x11

    ; calculate hash
    mov x0, x9 ; key
    bl _m_hash ; clobbers x0, x1, x2

    ; calculate index (hash % capacity)
    and w11, w0, w10

    stp x8, x9, [sp, -32]!
    stp x10, x11, [sp, 16]
    adrp x0, debug_message1@page
    add x0, x0, debug_message1@pageoff
    bl _printf
    ldp x10, x11, [sp, 16]
    ldp x8, x9, [sp], 32

0:
    ldr x12, [x8, x11, lsl 3] ; load key at index
    cmp x12, 0
    bgt 2f
    beq 3f ; return 0
1:
    add w11, w11, 1
    and w11, w11, w10
    b 0b
    
2: ; do strcmp to check the key
    mov x0, x12 ; current key
    mov x1, x9 ; key
    bl _m_strcmp ; clobbers x0, x1, x2, x3
    cbnz x0, 1b
    mov w0, 1
    ldp fp, lr, [sp], 16
    ret
3:
    mov w0, wzr
    ldp fp, lr, [sp], 16
    ret

; map in x0
; key (char *) in x1
; result in x0
_m_get:
; check key isn't null
    cmp x0, x1
    bne 0f
    ret
0:  
    stp fp, lr, [sp, -16]!
    mov x8, x0 ; map x8
    mov x9, x1 ; key x9
    ldr w10, [x8, 4] ; load capacity w10
    sub w10, w10, 1 ; for optimized modulo
    and x11, xzr, x11 ; clear x11

    ; calculate hash
    mov x0, x9 ; key
    bl _m_hash ; clobbers x0, x1, x2

    ; calculate index (hash % capacity)
    and w11, w0, w10

    ldr x12, [x8, 8] ; load keys into x12

0:
    ldr x13, [x12, x11, lsl 3] ; load key at index
    cmp x13, 0
    bgt 2f ; if gt, compare to key
    beq 3f ; return 0
1:
    add w11, w11, 1
    and w11, w11, w10
    b 0b
    
2: ; do strcmp to check the key
    mov x0, x13 ; current key
    mov x1, x9 ; key
    bl _m_strcmp ; clobbers x0, x1, x2, x3
    cbnz x0, 1b

    ldr x12, [x8, 16] ; load values array
    ldr x0, [x12, x11, lsl 3] ; return entry

    ldp fp, lr, [sp], 16
    ret
3:
    mov w0, wzr
    ldp fp, lr, [sp], 16
    ret

; map in x0
; key (char *) in x1
; result in x0
_m_remove:
; check key isn't null
    cmp x1, x0 ; if they're equal, this function won't work. It probably means they're both null
    bne 0f
    ret
0:  
    stp fp, lr, [sp, -16]!
    mov x8, x0 ; map x8
    mov x9, x1 ; key x9
    ldr w10, [x8, 4] ; load capacity w10
    sub w10, w10, 1 ; for optimized modulo
    and x11, xzr, x11 ; clear x11

    ; calculate hash
    mov x0, x9 ; key
    bl _m_hash ; clobbers x0, x1, x2

    ; calculate index (hash % capacity)
    and w11, w0, w10

    ldr x12, [x8, 8] ; load keys into x12
0:
    ldr x13, [x12, x11, lsl 3] ; load key at index
    cmp x13, 0
    bgt 2f ; if gt, compare to key
    beq 3f ; return 0
1:
    add w11, w11, 1
    and w11, w11, w10
    b 0b
    
2: ; do strcmp to check the key
    mov x0, x13 ; current key
    mov x1, x9 ; key
    bl _m_strcmp ; clobbers x0, x1, x2, x3
    cbnz x0, 1b

    ; write dummy key
    mov x13, DUMMY
    str x13, [x12, x11, lsl 3]

    ; decrement count
    ldr w13, [x8]
    sub w13, w13, 1
    str w13, [x8]

3:
    ldp fp, lr, [sp], 16
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
debug_message1: .asciz "w8-11: %u, %u, %u, %u\n"