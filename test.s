	.section	__TEXT,__text,regular,pure_instructions
	.build_version macos, 12, 0	sdk_version 12, 0
	.globl	_error                          ; -- Begin function error
	.p2align	2
_error:                                 ; @error
; %bb.0:
	sub	sp, sp, #32                     ; =32
	stp	x29, x30, [sp, #16]             ; 16-byte Folded Spill
	add	x29, sp, #16                    ; =16
	sturb	w0, [x29, #-1]
	ldursb	w10, [x29, #-1]
	adrp	x0, l_.str@PAGE
	add	x0, x0, l_.str@PAGEOFF
	mov	x9, sp
                                        ; implicit-def: $x8
	mov	x8, x10
	str	x8, [x9]
	bl	_printf
	mov	w0, #1
	bl	_exit
                                        ; -- End function
	.globl	_print_stack                    ; -- Begin function print_stack
	.p2align	2
_print_stack:                           ; @print_stack
; %bb.0:
	sub	sp, sp, #48                     ; =48
	stp	x29, x30, [sp, #32]             ; 16-byte Folded Spill
	add	x29, sp, #32                    ; =32
	stur	x0, [x29, #-8]
	stur	wzr, [x29, #-12]
LBB1_1:                                 ; =>This Inner Loop Header: Depth=1
	ldur	w8, [x29, #-12]
	ldur	x9, [x29, #-8]
	ldr	w9, [x9]
	subs	w8, w8, w9
	b.ge	LBB1_4
; %bb.2:                                ;   in Loop: Header=BB1_1 Depth=1
	ldur	x8, [x29, #-8]
	ldr	x8, [x8, #8]
	ldursw	x9, [x29, #-12]
	ldr	x8, [x8, x9, lsl #3]
	adrp	x0, l_.str.1@PAGE
	add	x0, x0, l_.str.1@PAGEOFF
	mov	x9, sp
	str	x8, [x9]
	bl	_printf
; %bb.3:                                ;   in Loop: Header=BB1_1 Depth=1
	ldur	w8, [x29, #-12]
	add	w8, w8, #1                      ; =1
	stur	w8, [x29, #-12]
	b	LBB1_1
LBB1_4:
	adrp	x0, l_.str.2@PAGE
	add	x0, x0, l_.str.2@PAGEOFF
	bl	_puts
	ldp	x29, x30, [sp, #32]             ; 16-byte Folded Reload
	add	sp, sp, #48                     ; =48
	ret
                                        ; -- End function
	.globl	_main                           ; -- Begin function main
	.p2align	2
_main:                                  ; @main
; %bb.0:
	sub	sp, sp, #64                     ; =64
	stp	x29, x30, [sp, #48]             ; 16-byte Folded Spill
	add	x29, sp, #48                    ; =48
	mov	w8, #0
	str	w8, [sp, #12]                   ; 4-byte Folded Spill
	stur	wzr, [x29, #-4]
	stur	w0, [x29, #-8]
	stur	x1, [x29, #-16]
	bl	_create_stack
	str	x0, [sp, #24]
	mov	x0, #8
	mov	x1, #1
	bl	_calloc
	str	x0, [sp, #16]
	ldr	x0, [sp, #16]
	mov	x1, #16
	bl	_realloc
	mov	x8, x0
	ldr	w0, [sp, #12]                   ; 4-byte Folded Reload
	str	x8, [sp, #16]
	ldp	x29, x30, [sp, #48]             ; 16-byte Folded Reload
	add	sp, sp, #64                     ; =64
	ret
                                        ; -- End function
	.section	__TEXT,__cstring,cstring_literals
l_.str:                                 ; @.str
	.asciz	"error: invalid token %c\n"

l_.str.1:                               ; @.str.1
	.asciz	"%d "

l_.str.2:                               ; @.str.2
	.space	1

.subsections_via_symbols
