.text
.build_version macos, 12, 0     sdk_version 12, 0
.p2align 2
.globl _main

_main:
    ; open the file
    ; use x19 for the filehandle
    ; first check argc == 2
    cmp x0, 2
    bne exit

    ; allocate stack here
    sub sp, sp, 32
    stp fp, lr, [sp, 16]

    ; get filename from argv
    ldr x0, [x1, 8]

    ; open file
    adrp x1, file_options@page
    add x1, x1, file_options@pageoff
    bl _fopen

    ; file handle in x0
    ;bl _parse

    ;bl _fgetc

    ;str x0, [sp]
    ;adrp x0, debug_string@page
    ;add x0, x0, debug_string@pageoff
    ;bl _printf

    ; do stuff with the parse tree

    ; restore stack here
    ldp fp, lr, [sp, 16]
    add sp, sp, 32

exit:
    ret

.data
.p2align 3
file_options: .asciz "r"
debug_string: .asciz "character: %c\n"

