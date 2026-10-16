section .data
    usage db "Usage: ./task3_fixed <old_name> <new_name>", 10, 0
    success db "Renamed: %s -> %s", 10, 0
    error db "Error: cannot rename file", 10, 0

section .text
    global main
    extern printf, rename

main:
    push rbp
    mov rbp, rsp
    sub rsp, 16

    ; Проверяем количество аргументов
    cmp rdi, 3
    jl .usage

    ; rsi[1] = старое имя, rsi[2] = новое имя
    mov rdi, [rsi+8]        ; old_name
    mov rsi, [rsi+16]       ; new_name
    
    ; Сохраняем для вывода
    mov [rbp-8], rdi
    mov [rbp-16], rsi

    ; Вызываем rename(old, new)
    call rename
    test eax, eax
    jnz .error

    ; Выводим успех
    lea rdi, [rel success]
    mov rsi, [rbp-8]
    mov rdx, [rbp-16]
    xor eax, eax
    call printf
    jmp .exit

.usage:
    lea rdi, [rel usage]
    xor eax, eax
    call printf
    jmp .exit

.error:
    lea rdi, [rel error]
    xor eax, eax
    call printf

.exit:
    leave
    ret
