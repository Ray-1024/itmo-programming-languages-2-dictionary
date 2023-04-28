%include "lib.inc"
%assign NODE_HEADER_LENGTH 8
%assign SUCCESS_RESULT 1

section .text

global find_word
find_word:
    test rsi, rsi
    jz .error
    push rsi
    push rdi
    add rsi, NODE_HEADER_LENGTH
    call string_equals
    pop rdi
    pop rsi
    cmp rax, SUCCESS_RESULT
    je .success
    mov rsi, [rsi]
    jmp find_word
    .success:
        mov rax, rsi
        ret
    .error:
        xor rax, rax
        ret
