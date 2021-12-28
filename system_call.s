.include "types.s"
.text
.p2align 2
.globl _system_call
.equ FUNCTION_NAMES_COUNT, 12

; expected to be called pointing to expression that can be evaluated
; tokens in x0
; cursor pointer in x1
; return expression evaluated parameter in x0
_get_parameter:
    ldr x9, [x1]
    ldr x8, [x0, x9, lsl 3] ; load current token
    ldr x8, [x8] ; type
    cmp x8, TS_CLOSE_PAREN
    bne 0f
    mov x0, xzr ; return zero if parenthesis found
    ret 
0:
    stp fp, lr, [sp, -32]!
    stp x19, x20, [sp, 16]

    mov x19, x0
    mov x20, x1

    bl _expression_eval ; evaluate parameter

    ldr x8, [x20]
    ldr x9, [x19, x8, lsl 3] ; load token
    ldr x9, [x9]
    cmp x9, TS_COMMA
    bne 1f

    ; if comma, advance cursor
    add x8, x8, 1
    str x8, [x20] ; update cursor

1:
    ldp x19, x20, [sp, 16]
    ldp fp, lr, [sp], 32
    ret


; tokens in x0
; cursor pointer in x1
; return system function call return value in x0
; return system call performed or not in x1
_system_call:   ; called with cursor pointing to identifier
    stp fp, lr, [sp, -64]!
    str x23, [sp, 48]
    stp x21, x22, [sp, 32]
    stp x19, x20, [sp, 16]

    mov x19, x0
    mov x20, x1
    ldr x21, [x20]

    adrp x22, function_names@page
    add x22, x22, function_names@pageoff

    ldr x8, [x19, x21, lsl 3] ; load token
    ldr x23, [x8, 8] ; load value

    mov x24, xzr ; counter

0: 
    mov x0, x23
    ldr x1, [x22, x24, lsl 3] ; arg1
    stp x0, x1, [sp, -16]!
    adrp x0, message1@page
    add x0, x0, message1@pageoff
    bl _printf
    ldp x0, x1, [sp], 16

    bl _strcmp
    cbz x0, 1f
    add x24, x24, 1 ; increment counter
    cmp x24, FUNCTION_NAMES_COUNT
    blt 0b

; here we didn't find anything so return 0
    mov x1, xzr
    b 2f
1: 
    ; use offset in x24 to load the jump address
    adrp x8, jump_table@page
    add x8, x8, jump_table@pageoff

    ; skip open parenthesis
    add x21, x21, 2
    str x21, [x20]

    ldr x8, [x8, x24, lsl 3] ; load jump address
    mov x0, x19 ; tokens
    mov x1, x20 ; token cursor
    blr x8 ; branch and link the appropriate function

    ; cursor should be on close paren so need to skip that
    ldr x8, [x20]
    add x8, x8, 1
    str x8, [x20]

    ; return value in x0
    mov x1, 1 ; true
2:
    ldp x19, x20, [sp, 16]
    ldp x21, x22, [sp, 32]
    ldr x23, [sp, 48]
    ldp fp, lr, [sp], 64
    ret

b_fprintf:
    ret

b_fputs:
    ret

; tokens x0
; token cursor x1
b_printf:
    stp fp, lr, [sp, -64]!
    stp x23, x24, [sp, 48]
    stp x21, x22, [sp, 32]
    stp x19, x20, [sp, 16]

    mov x19, x0 ; tokens
    mov x20, x1 ; cursor reference

    bl _get_parameter ; get parameter for format string
    mov x22, x0 ; save parameter

    mov x24, xzr ; keep track of stack offset

0:
    mov x0, x19
    mov x1, x20
    bl _get_parameter
    cbz x0, 2f
    mov x23, x0 ; save parameter
    mov x0, x19
    mov x1, x20
    bl _get_parameter
    cbz x0, 1f
    stp x23, x0, [sp, -16]!
    add x24, x24, 16
    b 0b
1:
    str x23, [sp, -16]!
    add x24, x24, 16
2:
    mov x0, x22
    bl _printf

    add sp, sp, x24 ; restore stack pointer

    ldp x19, x20, [sp, 16]
    ldp x21, x22, [sp, 32]
    ldp x23, x24, [sp, 48]
    ldp fp, lr, [sp], 64
    ret

b_puts:
    ret




.data
.p2align 3
function_names:
; stdio from https://www.cplusplus.com/reference/cstdio/ 
    .quad remove
    .quad rename
    .quad tmpfile 
    .quad tmpnam

    .quad fclose
    .quad fflush
    .quad fopen
    .quad freopen
    .quad setbuf
    .quad setvbuf

    .quad fprintf
    .quad fscanf
    .quad printf
    .quad scanf
    .quad sprintf
    .quad sscanf
    .quad vfprintf
    .quad vprintf
    .quad vsprintf

    .quad fgetc
    .quad fgets
    .quad fputc
    .quad fputs
    .quad getc
    .quad getchar
    .quad gets
    .quad putc
    .quad putchar
    .quad puts
    .quad ungetc

    .quad fread
    .quad fwrite

    .quad fgetpos
    .quad fseek
    .quad fsetpos
    .quad ftell
    .quad rewind

    .quad clearerr
    .quad feof
    .quad ferror
    .quad perror
; ctype.h from https://www.cplusplus.com/reference/cctype/
    .quad isalnum
    .quad isalpha
    .quad iscntrl
    .quad isdigit
    .quad isgraph
    .quad islower
    .quad isprint
    .quad ispunct
    .quad isspace
    .quad isupper
    .quad isxdigit

    .quad tolower
    .quad toupper

; cmath https://www.cplusplus.com/reference/cmath/
    .quad cos
    .quad sin
    .quad tan
    .quad acos
    .quad asin
    .quad atan
    .quad atan2

    .quad cosh
    .quad sinh
    .quad tanh

    .quad exp
    .quad frexp
    .quad ldexp
    .quad log
    .quad log10
    .quad modf

    .quad pow
    .quad sqrt

    .quad ceil
    .quad floor
    .quad fmod

    .quad fabs
    .quad abs
; cstring https://www.cplusplus.com/reference/cstring/
    .quad memcpy
    .quad memmove
    .quad strcpy
    .quad strncpy

    .quad strcat
    .quad strncat

    .quad memcmp
    .quad strcmp
    .quad strcoll
    .quad strncmp
    .quad strxfrm

    .quad memchr
    .quad strchr
    .quad strcspn
    .quad strpbrk
    .quad strrchr
    .quad strspn
    .quad strstr
    .quad strtok

    .quad memset
    .quad strerror
    .quad strlen

; cstdlib

    .quad atof
    .quad atoi
    .quad atol
    .quad strtod
    .quad strtol
    .quad strtoul

    .quad rand
    .quad srand

    .quad bsearch
    .quad qsort

    .quad abs

jump_table:
    .quad b_remove
    .quad b_rename
    .quad b_tmpfile
    .quad b_tmpnam

    .quad b_fclose
    .quad b_fflush
    .quad b_fopen
    .quad b_freopen
    .quad b_setbuf
    .quad b_setvbuf

    .quad b_fprintf
    .quad b_fscanf
    .quad b_printf
    .quad b_scanf
    .quad b_sprintf
    .quad b_sscanf
    .quad b_fprintf
    .quad b_printf
    .quad b_vsprintf

    .quad b_fgetc
    .quad b_fgets
    .quad b_fputc
    .quad b_fputs
    .quad b_getc
    .quad b_getchar
    .quad b_gets
    .quad b_putc
    .quad b_putchar
    .quad b_puts
    .quad b_ungetc

    .quad b_fread
    .quad b_fwrite

    .quad b_fgetpos
    .quad b_fseek
    .quad b_fsetpos
    .quad b_ftell
    .quad b_rewind

    .quad b_clearerr
    .quad b_feof
    .quad b_ferror
    .quad b_perror
; stdio
    .quad b_isalnum
    .quad b_isalpha
    .quad b_iscntrl
    .quad b_isdigit
    .quad b_isgraph
    .quad b_islower
    .quad b_isprint
    .quad b_ispunct
    .quad b_isspace
    .quad b_isupper
    .quad b_isxdigit

    .quad b_tolower
    .quad b_toupper
; cmath
    .quad b_cos
    .quad b_sin
    .quad b_tan
    .quad b_acos
    .quad b_asin
    .quad b_atan
    .quad b_atan2

    .quad b_cosh
    .quad b_sinh
    .quad b_tanh

    .quad b_exp
    .quad b_frexp
    .quad b_ldexp
    .quad b_log
    .quad b_log10
    .quad b_modf

    .quad b_pow
    .quad b_sqrt

    .quad b_ceil
    .quad b_floor
    .quad b_fmod

    .quad b_fabs
    .quad b_abs
; cstring
    .quad b_memcpy
    .quad b_memmove
    .quad b_strcpy
    .quad b_strncpy
    
    .quad b_strcat
    .quad b_strncat

    .quad b_memcmp
    .quad b_strcmp
    .quad b_strcoll
    .quad b_strncmp
    .quad b_strxfrm

    .quad b_memchr
    .quad b_strchr
    .quad b_strcspn
    .quad b_strpbrk
    .quad b_strrchr
    .quad b_strspn
    .quad b_strstr
    .quad b_strtok

    .quad b_memset
    .quad b_strerror
    .quad b_strlen
; cstdlib
    .quad b_atof
    .quad b_atoi
    .quad b_atol
    .quad b_strtod
    .quad b_strtol
    .quad b_strtoul
    
    .quad b_rand
    .quad b_srand
    
    .quad b_bsearch
    .quad b_qsort

    .quad b_abs

.section __text,__cstring,cstring_literals
remove: .asciz "remove"
rename: .asciz "rename"
tmpfile: .asciz "tmpfile"
tmpnam: .asciz "tmpnam"

fclose: .asciz "fclose"
fflush: .asciz "fflush"
fopen: .asciz "fopen"
freopen: .asciz "freopen"
setbuf: .asciz "setbuf"
setvbuf: .asciz "setvbuf"

fprintf: .asciz "fprintf"
fscanf: .asciz "fscanf"
printf: .asciz "printf"
scanf: .asciz "scanf"
sprintf: .asciz "sprintf"
sscanf: .asciz "sscanf"
vfprintf: .asciz "vfprintf"
vprintf: .asciz "vprintf"
vsprintf: .asciz "vsprintf"

fgetc: .asciz "fgetc"
fgets: .asciz "fgets"
fputc: .asciz "fputc"
fputs: .asciz "fputs"
getc: .asciz "getc"
getchar: .asciz "getchar"
gets: .asciz "gets"
putc: .asciz "putc"
putchar: .asciz "putchar"
puts: .asicz "puts"
ungetc: .asciz "ungetc"

fread: .asciz "fread"
fwrite: .asciz "fwrite"

fgetpos: .asciz "fgetpos"
fseek: .asciz "fseek"
fsetpos: .asciz "fsetpos"
ftell: .asciz "ftell"
rewind: .asciz "rewind"

clearerr: .asciz "clearerr"
feof: .asciz "feof"
ferror: .asciz "ferror"
perror: .asciz "perror"



message: .asciz "printf called!!"
message1: .asciz "system call: comparing identifier %s and table entry %s\n"