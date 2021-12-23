	.section	__TEXT,__text,regular,pure_instructions
	.build_version macos, 12, 0	sdk_version 12, 1
	.globl	_main                           ; -- Begin function main
	.p2align	2
_main:                                  ; @main
; %bb.0:
	sub	sp, sp, #64                     ; =64
	stp	x22, x21, [sp, #16]             ; 16-byte Folded Spill
	stp	x20, x19, [sp, #32]             ; 16-byte Folded Spill
	stp	x29, x30, [sp, #48]             ; 16-byte Folded Spill
	add	x29, sp, #48                    ; =48
	bl	_m_create
	mov	x19, x0
Lloh0:
	adrp	x1, l_.str@PAGE
Lloh1:
	add	x1, x1, l_.str@PAGEOFF
	mov	x2, #0
	bl	_m_insert
Lloh2:
	adrp	x1, l_.str.1@PAGE
Lloh3:
	add	x1, x1, l_.str.1@PAGEOFF
	mov	x0, x19
	mov	w2, #1
	bl	_m_insert
Lloh4:
	adrp	x1, l_.str.2@PAGE
Lloh5:
	add	x1, x1, l_.str.2@PAGEOFF
	mov	x0, x19
	mov	w2, #4
	bl	_m_insert
Lloh6:
	adrp	x1, l_.str.3@PAGE
Lloh7:
	add	x1, x1, l_.str.3@PAGEOFF
	mov	x0, x19
	mov	w2, #9
	bl	_m_insert
Lloh8:
	adrp	x1, l_.str.4@PAGE
Lloh9:
	add	x1, x1, l_.str.4@PAGEOFF
	mov	x0, x19
	mov	w2, #16
	bl	_m_insert
Lloh10:
	adrp	x1, l_.str.5@PAGE
Lloh11:
	add	x1, x1, l_.str.5@PAGEOFF
	mov	x0, x19
	mov	w2, #34
	bl	_m_insert
Lloh12:
	adrp	x1, l_.str.6@PAGE
Lloh13:
	add	x1, x1, l_.str.6@PAGEOFF
	mov	x0, x19
	mov	w2, #34
	bl	_m_insert
Lloh14:
	adrp	x1, l_.str.7@PAGE
Lloh15:
	add	x1, x1, l_.str.7@PAGEOFF
	mov	x0, x19
	mov	w2, #73
	bl	_m_insert
Lloh16:
	adrp	x1, l_.str.8@PAGE
Lloh17:
	add	x1, x1, l_.str.8@PAGEOFF
Lloh18:
	adrp	x2, l_.str.9@PAGE
Lloh19:
	add	x2, x2, l_.str.9@PAGEOFF
	mov	x0, x19
	bl	_m_insert
	ldr	w8, [x19, #4]
	cbz	w8, LBB0_3
; %bb.1:
	mov	x21, #0
Lloh20:
	adrp	x22, l_.str.11@PAGE
Lloh21:
	add	x22, x22, l_.str.11@PAGEOFF
Lloh22:
	adrp	x20, l_.str.10@PAGE
Lloh23:
	add	x20, x20, l_.str.10@PAGEOFF
LBB0_2:                                 ; =>This Inner Loop Header: Depth=1
	lsl	x8, x21, #3
	ldp	x9, x10, [x19, #8]
	ldr	x9, [x9, x8]
	cmp	x9, #0                          ; =0
	csel	x9, x9, x22, ge
	ldr	x8, [x10, x8]
	stp	x9, x8, [sp]
	mov	x0, x20
	bl	_printf
	add	x21, x21, #1                    ; =1
	ldr	w8, [x19, #4]
	cmp	x21, x8
	b.lo	LBB0_2
LBB0_3:
	mov	w0, #0
	ldp	x29, x30, [sp, #48]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #32]             ; 16-byte Folded Reload
	ldp	x22, x21, [sp, #16]             ; 16-byte Folded Reload
	add	sp, sp, #64                     ; =64
	ret
	.loh AdrpAdd	Lloh18, Lloh19
	.loh AdrpAdd	Lloh16, Lloh17
	.loh AdrpAdd	Lloh14, Lloh15
	.loh AdrpAdd	Lloh12, Lloh13
	.loh AdrpAdd	Lloh10, Lloh11
	.loh AdrpAdd	Lloh8, Lloh9
	.loh AdrpAdd	Lloh6, Lloh7
	.loh AdrpAdd	Lloh4, Lloh5
	.loh AdrpAdd	Lloh2, Lloh3
	.loh AdrpAdd	Lloh0, Lloh1
	.loh AdrpAdd	Lloh22, Lloh23
	.loh AdrpAdd	Lloh20, Lloh21
                                        ; -- End function
	.section	__TEXT,__cstring,cstring_literals
l_.str:                                 ; @.str
	.asciz	"count"

l_.str.1:                               ; @.str.1
	.asciz	"count1"

l_.str.2:                               ; @.str.2
	.asciz	"count2"

l_.str.3:                               ; @.str.3
	.asciz	"count3"

l_.str.4:                               ; @.str.4
	.asciz	"count4"

l_.str.5:                               ; @.str.5
	.asciz	"username"

l_.str.6:                               ; @.str.6
	.asciz	"username1"

l_.str.7:                               ; @.str.7
	.asciz	"username2"

l_.str.8:                               ; @.str.8
	.asciz	"another username"

l_.str.9:                               ; @.str.9
	.asciz	"kburns8"

l_.str.10:                              ; @.str.10
	.asciz	"%s: %lu\n"

l_.str.11:                              ; @.str.11
	.asciz	"DUMMY"

.subsections_via_symbols
