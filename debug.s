	.section	__TEXT,__text,regular,pure_instructions
	.build_version macos, 12, 0	sdk_version 12, 1
	.globl	_print_token                    ; -- Begin function print_token
	.p2align	2
_print_token:                           ; @print_token
; %bb.0:
	sub	sp, sp, #32                     ; =32
	stp	x29, x30, [sp, #16]             ; 16-byte Folded Spill
	add	x29, sp, #16                    ; =16
	ldr	x8, [x0]
	cmp	x8, #13                         ; =13
	b.lo	LBB0_2
; %bb.1:
	sxtb	w8, w8
	ldr	x9, [x0, #8]
	stp	x8, x9, [sp]
Lloh0:
	adrp	x0, l_.str@PAGE
Lloh1:
	add	x0, x0, l_.str@PAGEOFF
	bl	_printf
	ldp	x29, x30, [sp, #16]             ; 16-byte Folded Reload
	add	sp, sp, #32                     ; =32
	ret
LBB0_2:
Lloh2:
	adrp	x9, _token_types@PAGE
Lloh3:
	add	x9, x9, _token_types@PAGEOFF
	ldr	x8, [x9, x8, lsl #3]
	ldr	x9, [x0, #8]
	stp	x8, x9, [sp]
Lloh4:
	adrp	x0, l_.str.1@PAGE
Lloh5:
	add	x0, x0, l_.str.1@PAGEOFF
	bl	_printf
	ldp	x29, x30, [sp, #16]             ; 16-byte Folded Reload
	add	sp, sp, #32                     ; =32
	ret
	.loh AdrpAdd	Lloh0, Lloh1
	.loh AdrpAdd	Lloh4, Lloh5
	.loh AdrpAdd	Lloh2, Lloh3
                                        ; -- End function
	.globl	_token_type_to_string           ; -- Begin function token_type_to_string
	.p2align	2
_token_type_to_string:                  ; @token_type_to_string
; %bb.0:
Lloh6:
	adrp	x8, _token_types@PAGE
Lloh7:
	add	x8, x8, _token_types@PAGEOFF
	ldr	x0, [x8, x0, lsl #3]
	ret
	.loh AdrpAdd	Lloh6, Lloh7
                                        ; -- End function
	.section	__TEXT,__cstring,cstring_literals
l_.str:                                 ; @.str
	.asciz	"%c:%s\n"

l_.str.1:                               ; @.str.1
	.asciz	"%s:%s\n"

	.section	__DATA,__const
	.p2align	3                               ; @token_types
_token_types:
	.quad	l_.str.2
	.quad	l_.str.3
	.quad	l_.str.4
	.quad	l_.str.5
	.quad	l_.str.6
	.quad	l_.str.7
	.quad	l_.str.8
	.quad	l_.str.9
	.quad	l_.str.10
	.quad	l_.str.11
	.quad	l_.str.12
	.quad	l_.str.13

	.section	__TEXT,__cstring,cstring_literals
l_.str.2:                               ; @.str.2
	.asciz	"break"

l_.str.3:                               ; @.str.3
	.asciz	"continue"

l_.str.4:                               ; @.str.4
	.asciz	"else"

l_.str.5:                               ; @.str.5
	.asciz	"eq"

l_.str.6:                               ; @.str.6
	.asciz	"if"

l_.str.7:                               ; @.str.7
	.asciz	"register"

l_.str.8:                               ; @.str.8
	.asciz	"return"

l_.str.9:                               ; @.str.9
	.asciz	"struct"

l_.str.10:                              ; @.str.10
	.asciz	"while"

l_.str.11:                              ; @.str.11
	.asciz	"integer"

l_.str.12:                              ; @.str.12
	.asciz	"identifier"

l_.str.13:                              ; @.str.13
	.asciz	"string"

.subsections_via_symbols
