section .data
    fmt db "%d", 10, 0
    err db "Error: even number", 10, 0

section .text
    global main
    extern printf, atoi

main:
    push rbp
    mov rbp, rsp
    sub rsp, 16

    cmp rdi, 2
    jl .error

    mov rdi, [rsi+8]
    call atoi

    test eax, 1
    jz .error

    mov ecx, 1
    xor edx, edx
.loop:
    cmp ecx, eax
    jg .done
    add edx, ecx
    add ecx, 2
    jmp .loop
.done:
    mov rsi, rdx
    lea rdi, [rel fmt]
    xor eax, eax
    call printf
    jmp .exit
.error:
    lea rdi, [rel err]
    xor eax, eax
    call printf
.exit:
    leave
    ret
