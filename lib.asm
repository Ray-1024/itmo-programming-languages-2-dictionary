%assign SYSCALL_EXIT 60
%assign SYSCALL_READ 0
%assign SYSCALL_WRITE 1
%assign STDIN 0
%assign STDOUT 1
%assign STDERR 2
%assign ASCII_NEWLINE 0xA
%assign ASCII_TAB 0x9
%assign ASCII_SPACE 0x20
%assign ASCII_ZERO_DIGIT '0'
%assign ASCII_NINE_DIGIT '9'
%assign ASCII_MINUS '-'
%assign NUMBER_MAX_LENGTH 21
%assign BASE 10
%assign NULL_TERMINATOR 0
%assign FALSE 0
%assign TRUE 1

global exit
global string_length
global print_string
global error_string
global print_newline
global print_char
global print_int
global print_uint
global string_equals
global read_char
global read_word
global read_line
global parse_int
global parse_uint
global string_copy

section .text
; Принимает код возврата и завершает текущий процесс
exit:
    mov rax, SYSCALL_EXIT
    xor rdi, rdi
    syscall

; Принимает указатель на нуль-терминированную строку, возвращает её длину
string_length:
    mov rax, -1
    .loop:
        inc rax
        cmp byte[rdi+rax], NULL_TERMINATOR
        jne .loop
    ret

; Принимает указатель на нуль-терминированную строку, выводит её в stdout
print_string:
    push rdi
    call string_length
    mov rdx, rax
    mov rax, SYSCALL_WRITE
    mov rdi, STDOUT
    pop rsi
    syscall
    ret

; Принимает указатель на нуль-терминированную строку, выводит её в stdout
error_string:
    push rdi
    call string_length
    mov rdx, rax
    mov rax, SYSCALL_WRITE
    mov rdi, STDERR
    pop rsi
    syscall
    ret

; Принимает код символа и выводит его в stdout
print_char:
    dec rsp
    mov [rsp], dil
    mov rax, SYSCALL_WRITE
    mov rdi, STDOUT
    mov rsi, rsp
    mov rdx, 1
    syscall
    inc rsp
    ret

; Переводит строку (выводит символ с кодом 0xA)
print_newline:
    mov rdi, ASCII_NEWLINE
    jmp print_char

; Выводит беззнаковое 8-байтовое число в десятичном формате
; Совет: выделите место в стеке и храните там результаты деления
; Не забудьте перевести цифры в их ASCII коды.
print_uint:
    mov rax, rdi
    mov rsi, BASE
    mov rdi, rsp
    dec rdi
    sub rsp, NUMBER_MAX_LENGTH
    mov byte[rdi], NULL_TERMINATOR
    .loop:
        xor rdx, rdx
        div rsi
        add rdx, ASCII_ZERO_DIGIT
        dec rdi
        mov [rdi], dl
        test rax, rax
        jnz .loop
    call print_string
    add rsp, NUMBER_MAX_LENGTH
    ret

; Выводит знаковое 8-байтовое число в десятичном формате
print_int:
    cmp rdi, 0
    jge .uint
    neg rdi
    push rdi
    mov rdi, ASCII_MINUS
    call print_char
    pop rdi
    .uint:
        jmp print_uint

; Принимает два указателя на нуль-терминированные строки, возвращает 1 если они равны, 0 иначе
string_equals:
    mov al,[rdi]
    cmp al, [rsi]
    jne .different
    inc rdi
    inc rsi
    test al, al
    jnz string_equals
    mov rax, TRUE
    ret
    .different:
        xor rax, rax
    ret

; Читает один символ из stdin и возвращает его. Возвращает 0 если достигнут конец потока
read_char:
    dec rsp
    mov rax, SYSCALL_READ
    mov rdi, STDIN
    mov rsi, rsp
    mov rdx, 1
    syscall
    test rax, rax
    jz .empty
    mov al, [rsp]
    inc rsp
    ret
    .empty:
        inc rsp
        xor rax, rax
        ret

; Принимает: адрес начала буфера, размер буфера
; Читает в буфер слово из stdin, пропуская пробельные символы в начале, .
; Пробельные символы это пробел 0x20, табуляция 0x9 и перевод строки 0xA.
; Останавливается и возвращает 0 если слово слишком большое для буфера
; При успехе возвращает адрес буфера в rax, длину слова в rdx.
; При неудаче возвращает 0 в rax
; Эта функция должна дописывать к слову нуль-терминатор
read_word:
    xor rcx, rcx
    xor rdx, rdx
    .loop:
        push rdi
        push rsi
        push rcx
        push rdx
        call read_char
        pop rdx
        pop rcx
        pop rsi
        pop rdi
        test rdx, rdx
        jnz .word
        cmp al, ASCII_SPACE
        je .loop
        cmp al, ASCII_NEWLINE
        je .loop
        cmp al, ASCII_TAB
        je .loop
        test al, al
        jz .error
        mov rdx, TRUE
    .word:
        cmp al, ASCII_SPACE
        je .end
        cmp al, ASCII_NEWLINE
        je .end
        cmp al, ASCII_TAB
        je .end
        test al, al
        jz .end
        mov [rdi+rcx], al
        inc rcx
        cmp rcx, rsi
        je .error
        jmp .loop
    .end:
        mov byte[rdi+rcx], NULL_TERMINATOR
        mov rax, rdi
        mov rdx, rcx
        ret
    .error:
        xor rax, rax
        ret

read_line:
    xor rcx, rcx
        xor rdx, rdx
        .loop:
            push rdi
            push rsi
            push rcx
            push rdx
            call read_char
            pop rdx
            pop rcx
            pop rsi
            pop rdi
            test rdx, rdx
            jnz .word
            cmp al, ASCII_NEWLINE
            je .loop
            test al, al
            jz .error
            mov rdx, TRUE
        .word:
            cmp al, ASCII_NEWLINE
            je .end
            test al, al
            jz .end
            mov [rdi+rcx], al
            inc rcx
            cmp rcx, rsi
            je .error
            jmp .loop
        .end:
            mov byte[rdi+rcx], NULL_TERMINATOR
            mov rax, rdi
            mov rdx, rcx
            ret
        .error:
            xor rax, rax
            ret


; Принимает указатель на строку, пытается
; прочитать из её начала беззнаковое число.
; Возвращает в rax: число, rdx : его длину в символах
; rdx = 0 если число прочитать не удалось
parse_uint:
    xor rax, rax
    xor rcx,rcx
    xor rsi, rsi
    mov r10, BASE
    .loop:
        mov sil,[rdi]
        cmp sil, ASCII_ZERO_DIGIT
        jb .end
        cmp sil, ASCII_NINE_DIGIT
        ja .end
        sub sil, ASCII_ZERO_DIGIT
        inc rdi
        inc rcx
        mul r10
        add rax, rsi
        cmp rdx, NUMBER_MAX_LENGTH
        je .end
        jmp .loop
    .end:
        mov rdx, rcx
        ret

; Принимает указатель на строку, пытается
; прочитать из её начала знаковое число.
; Если есть знак, пробелы между ним и числом не разрешены.
; Возвращает в rax: число, rdx : его длину в символах (включая знак, если он был)
; rdx = 0 если число прочитать не удалось
parse_int:
    cmp byte[rdi], ASCII_MINUS
    jne .uint
    inc rdi
    call parse_uint
    test rdx, rdx
    jz .exit
    neg rax
    inc rdx
    .exit:
        ret
    .uint:
        jmp parse_uint

; Принимает указатель на строку, указатель на буфер и длину буфера
; Копирует строку в буфер
; Возвращает длину строки если она умещается в буфер, иначе 0
string_copy:
    xor rcx, rcx
    .loop:
        cmp rcx, rdx
        je .fail
        mov al,[rdi]
        mov [rsi],al
        inc rdi
        inc rsi
        inc rcx
        test al, al
        jz .end
        jmp .loop
    .fail:
        xor rax, rax
    .end:
        ret