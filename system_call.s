.include "types.s"
.text
.p2align 2
.globl _system_call
.equ FUNCTION_NAMES_COUNT, 108

; expected to be called pointing to expression that can be evaluated
; tokens in x0
; cursor pointer in x1
; return expression evaluated parameter in x1
; return success in x0
_get_parameter:
    ldr x9, [x1]
    ldr x8, [x0, x9, lsl 3] ; load current token
    ldr x8, [x8] ; type
    cmp x8, TS_CLOSE_PAREN
    bne 0f
    mov x1, xzr ; return zero if parenthesis found
    ret 
0:
    stp fp, lr, [sp, -32]!
    stp x19, x20, [sp, 16]

    mov x19, x0
    mov x20, x1

    bl _expression_eval ; evaluate parameter

    ldr x8, [x20] ; load cursor

    ldr x9, [x19, x8, lsl 3] ; load token
    ldr x9, [x9] ; type
    cmp x9, TS_COMMA
    bne 1f

    ; if comma, advance cursor
    add x8, x8, 1
    str x8, [x20] ; update cursor
1:
    mov x1, 1
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
    ;stp x0, x1, [sp, -16]!
    ;adrp x0, message1@page
    ;add x0, x0, message1@pageoff
    ;bl _printf
    ;ldp x0, x1, [sp], 16

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

; ---- NOTE -----
; all of the following procedures accept
; token array pointer in x0
; cursor pointer in x1

b_remove:
    ret
b_rename:
    ret
b_tmpfile:
    ret
b_tmpnam:
    ret

b_fclose:
    stp fp, lr, [sp, -16]!
    bl _get_parameter ; file handle
    bl _fclose
    ldp fp, lr, [sp], 16
    ret
b_fflush:
    ret
b_fopen:
    stp fp, lr, [sp, -48]!
    str x21, [sp, 32]
    stp x19, x20, [sp, 16]

    mov x19, x0; tokens
    mov x20, x1 ; cursor ref

    bl _get_parameter ; get filename
    mov x21, x0 ; save

    mov x0, x19
    mov x1, x20
    bl _get_parameter ; get mode string
    mov x1, x0 ; arg1
    mov x0, x21 ; arg0
    bl _fopen ; return file handle in x0

    ldp x19, x20, [sp, 16]
    ldr x21, [sp, 32]
    ldp fp, lr, [sp], 48
    ret
b_freopen:
    ret
b_setbuf:
    ret 
b_setvbuf:
    ret

b_fprintf:
    stp fp, lr, [sp, -64]!
    stp x23, x24, [sp, 48]
    stp x21, x22, [sp, 32]
    stp x19, x20, [sp, 16]

    mov x19, x0 ; tokens
    mov x20, x1 ; cursor reference

    bl _get_parameter ; get file pointer
    mov x21, x0

    mov x0, x19
    mov x1, x20
    bl _get_parameter ; get parameter for format string
    mov x22, x0 ; save parameter

    mov x24, xzr ; keep track of stack offset

0:
    mov x0, x19
    mov x1, x20
    bl _get_parameter
    cbz x1, 2f
    mov x23, x0 ; save parameter
    mov x0, x19
    mov x1, x20
    bl _get_parameter
    stp x23, x0, [sp, -16]!
    add x24, x24, 16
    b 0b
2:
    mov x0, x21 ; file pointer
    mov x1, x22 ; format string
    bl _fprintf

    add sp, sp, x24 ; restore stack pointer

    ldp x19, x20, [sp, 16]
    ldp x21, x22, [sp, 32]
    ldp x23, x24, [sp, 48]
    ldp fp, lr, [sp], 64
    ret

b_fscanf:
    stp fp, lr, [sp, -64]!
    stp x23, x24, [sp, 48]
    stp x21, x22, [sp, 32]
    stp x19, x20, [sp, 16]

    mov x19, x0 ; tokens
    mov x20, x1 ; cursor reference

    bl _get_parameter ; get file pointer
    mov x21, x0

    mov x0, x19
    mov x1, x20
    bl _get_parameter ; get parameter for format string
    mov x22, x0 ; save parameter

    mov x24, xzr ; keep track of stack offset

0:
    mov x0, x19
    mov x1, x20
    bl _get_parameter
    cbz x1, 2f
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
    mov x0, x21 ; file pointer
    mov x1, x22 ; format string
    bl _fscanf

    add sp, sp, x24 ; restore stack pointer

    ldp x19, x20, [sp, 16]
    ldp x21, x22, [sp, 32]
    ldp x23, x24, [sp, 48]
    ldp fp, lr, [sp], 64
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
    cbz x1, 2f
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

b_scanf:
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
    cbz x1, 2f
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
    bl _scanf

    add sp, sp, x24 ; restore stack pointer

    ldp x19, x20, [sp, 16]
    ldp x21, x22, [sp, 32]
    ldp x23, x24, [sp, 48]
    ldp fp, lr, [sp], 64
    ret

b_sprintf:
    ret
b_sscanf:
    ret
b_vfprintf:
    ret
b_vprintf:
    ret
b_vsprintf:
    ret

b_fgetc:
    ret
b_fgets:
    ret
b_fputc:
    ret
b_fputs:
    ret
b_getc:
    ret
b_getchar:
    ret
b_gets:
    ret
b_putc:
    ret
b_putchar:
    ret
b_puts:
    ret
b_ungetc:
    ret

b_fread:
    ret
b_fwrite:
    ret

b_fgetpos:
    ret
b_fseek:
    ret
b_fsetpos:
    ret
b_ftell:
    ret
b_rewind:
    ret

b_clearerr:
    ret
b_feof:
    ret
b_ferror:
    ret
b_perror:
    ret

; stdio
b_isalnum:
    ret
b_isalpha:
    ret
b_iscntrl:
    ret
b_isdigit:
    ret
b_isgraph:
    ret
b_islower:
    ret
b_isprint:
    ret
b_ispunct:
    ret
b_isspace:
    ret
b_isupper:
    ret
b_isxdigit:
    ret

b_tolower:
    ret
b_toupper:
    ret

; cmath
b_cos:
    ret
b_sin:
    ret
b_tan:
    ret
b_acos:
    ret
b_asin:
    ret
b_atan:
    ret
b_atan2:
    ret

b_cosh:
    ret
b_sinh:
    ret
b_tanh:
    ret

b_exp:
    ret
b_frexp:
    ret
b_ldexp:
    ret
b_log:
    ret
b_log10:
    ret
b_modf:
    ret

b_pow:
    ret
b_sqrt:
    ret

b_ceil:
    ret
b_floor:
    ret
b_fmod:
    ret

b_fabs:
    ret
b_abs:
    ret

; cstring
b_memcpy:
    ret
b_memmove:
    ret
b_strcpy:
    ret
b_strncpy:
    ret

b_strcat:
    ret
b_strncat:
    ret

b_memcmp:
    ret
b_strcmp:
    ret
b_strcoll:
    ret
b_strncmp:
    ret
b_strxfrm:
    ret

b_memchr:
    ret
b_strchr:
    ret
b_strcspn:
    ret
b_strpbrk:
    ret
b_strrchr:
    ret
b_strspn:
    ret
b_strstr:
    ret
b_strtok:
    ret

b_memset:
    ret
b_strerror:
    ret
b_strlen:
    ret

; stdlib
b_atof:
    ret
b_atoi:
    ret
b_atol:
    ret
b_strtod:
    ret
b_strtol:
    ret
b_strtoul:
    ret

b_rand:
    ret
b_srand:
    ret

b_bsearch:
    ret
b_qsort:
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
; 30
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
; 41
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
; 54
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
; 64
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
; 81
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
; 95
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
; 108 I think
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
    .quad b_vfprintf
    .quad b_vprintf
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
puts: .asciz "puts"
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
; ctype
isalnum: .asciz "isalnum"
isalpha: .asciz "isalpha"
iscntrl: .asciz "iscntrl"
isdigit: .asciz "isdigit"
isgraph: .asciz "isgraph"
islower: .asciz "islower"
isprint: .asciz "isprint"
ispunct: .asciz "ispunct"
isspace: .asciz "isspace"
isupper: .asciz "isupper"
isxdigit: .asciz "isxdigit"

tolower: .asciz "tolower"
toupper: .asciz "tolower"

; cmath
cos: .asciz "cos"
sin: .asciz "sin"
tan: .asciz "tan"
acos: .asciz "acos"
asin: .asciz "asin"
atan: .asciz "atan"
atan2: .asciz "atan2"

cosh: .asciz "cosh"
sinh: .asciz "sinh"
tanh: .asciz "tanh"

exp: .asciz "exp"
frexp: .asciz "frexp"
ldexp: .asciz "ldexp"
log: .asciz "log"
log10: .asciz "log10"
modf: .asciz "modf"

pow: .asciz "pow"
sqrt: .asciz "sqrt"

ceil: .asciz "ceil"
floor: .asciz "floor"
fmod: .asciz "fmod"

fabs: .asciz "fabs"
abs: .asciz "abs"
; cstring
memcpy: .asciz "memcpy"
memmove: .asciz "memmove"
strcpy: .asciz "strcpy"
strncpy: .asciz "strncpy"

strcat: .asciz "strcat"
strncat: .asciz "strncat"

memcmp: .asciz "memcmp"
strcmp: .asciz "strcmp"
strcoll: .asciz "strcoll"
strncmp: .asciz "strncmp"
strxfrm: .asciz "strxfrm"

memchr: .asciz "memchr"
strchr: .asciz "strchr"
strcspn: .asciz "strcspn"
strpbrk: .asciz "strpbrk"
strrchr: .asciz "strrchr"
strspn: .asciz "strspn"
strstr: .asciz "strstr"
strtok: .asciz "strtok"

memset: .asciz "memset"
strerror: .asciz "strerror"
strlen: .asciz "strle"

; cstdlib
atof: .asciz "atof"
atoi: .asciz "atoi"
atol: .asciz "atol"
strtod: .asciz "strtod"
strtol: .asciz "strtol"
strtoul: .asciz "strtoul"

rand: .asciz "rand"
srand: .asciz "srand"

bsearch: .asciz "bsearch"
qsort: .asciz "qsort"

message: .asciz "printf called!!"
message1: .asciz "system call: comparing identifier %s and table entry %s\n"
debug_message: .asciz "expression evaluate returned on token %lu\n"