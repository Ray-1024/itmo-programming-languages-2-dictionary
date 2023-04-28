%include "lib.inc"
%include "colon.inc"
%include "words.inc"
%include "dict.inc"

%assign BUFFER_SIZE 256

global _start

section .rodata
startup_message:	db "Hi, please enter the key:", 0
too_long_query_message:	db "Query too long", 0
fail_message:	db "The key doesn't exists", 0

section .bss
buffer:	resb BUFFER_SIZE

section .text
_start:
    mov rdi, startup_message
    call print_string
    call print_newline
    mov rdi, buffer
    mov rsi, BUFFER_SIZE
    call read_line
    test rax, rax
    jz .line_too_long
    push rdx
    mov rdi, buffer
    mov rsi, THIRD_WORD
    call find_word
    test rax, rax
    jz .fail
    pop rdx
    add rax, rdx
    add rax, HEADER_SIZE + 1
    mov rdi, rax
    call print_string
    call print_newline
    jmp exit
    .line_too_long:
            mov rdi, too_long_query_message
            call error_string
            call print_newline
            jmp exit
    .fail:
        mov rdi, fail_message
        call print_string
        call print_newline
        jmp exit