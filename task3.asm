section .data
    dir_name    db ".", 0
    new_prefix  db "renamed_", 0
    fmt         db "Renamed: %s -> %s", 10, 0
    err_open    db "Error: cannot open directory", 10, 0
    err_read    db "Error: cannot read directory", 10, 0

section .bss
    dir_fd      resq 1
    buf         resb 4096
    new_name    resb 256
    counter     resq 1

section .text
    global _start

_start:
    ; --- Получаем аргумент (имя каталога) ---
    mov rax, [rsp]          ; argc
    cmp rax, 2
    jl .use_default
    mov rdi, [rsp+16]       ; argv[1]
    jmp .open_dir
.use_default:
    lea rdi, [rel dir_name]

.open_dir:
    ; --- Открываем каталог (syscall open) ---
    mov rax, 2              ; syscall open
    mov rsi, 0              ; O_RDONLY
    xor rdx, rdx
    syscall
    test rax, rax
    js .error_open
    mov [dir_fd], rax

    ; --- Инициализируем счетчик ---
    mov qword [counter], 0

.read_loop:
    ; --- Читаем записи каталога (syscall getdents64) ---
    mov rax, 217            ; syscall getdents64
    mov rdi, [dir_fd]
    lea rsi, [rel buf]
    mov rdx, 4096
    syscall
    test rax, rax
    jle .done               ; если 0 или ошибка — выходим
    mov rbx, rax            ; rbx = количество прочитанных байт
    lea r12, [rel buf]      ; r12 = указатель на буфер

.process_entry:
    ; --- Проверяем, что есть еще записи ---
    test rbx, rbx
    jle .read_loop

    ; --- Структура linux_dirent64:
    ; offset 0:  d_ino (8 байт)
    ; offset 8:  d_off (8 байт)
    ; offset 16: d_reclen (2 байта)
    ; offset 18: d_type (1 байт)
    ; offset 19: d_name (строка) ---
    movzx r13, word [r12+16]  ; d_reclen
    lea r14, [r12+19]         ; d_name

    ; --- Пропускаем "." и ".." ---
    cmp byte [r14], '.'
    je .skip_entry

    ; --- Генерируем случайное число (rdrand) ---
    rdrand rax
    jnc .skip_rand          ; если не удалось — пропускаем (маловероятно)
    and rax, 0xFFFF         ; ограничим 16 битами
    mov r15, rax

    ; --- Формируем новое имя: "renamed_<random>" ---
    lea rdi, [rel new_name]
    lea rsi, [rel new_prefix]
    call .strcpy

    ; --- Добавляем случайное число в конец ---
    mov rax, r15
    call .itoa

    ; --- Переименовываем файл (syscall rename) ---
    mov rax, 82             ; syscall rename
    mov rdi, r14            ; old name
    lea rsi, [rel new_name] ; new name
    syscall

    ; --- Увеличиваем счетчик ---
    inc qword [counter]

.skip_entry:
    ; --- Переходим к следующей записи ---
    add r12, r13
    sub rbx, r13
    jmp .process_entry

.skip_rand:
    add r12, r13
    sub rbx, r13
    jmp .process_entry

.done:
    ; --- Закрываем каталог (syscall close) ---
    mov rax, 3
    mov rdi, [dir_fd]
    syscall

    ; --- Выходим ---
    mov rax, 60
    xor rdi, rdi
    syscall

.error_open:
    lea rdi, [rel err_open]
    call .print
    mov rax, 60
    mov rdi, 1
    syscall

.error_read:
    lea rdi, [rel err_read]
    call .print
    mov rax, 60
    mov rdi, 1
    syscall

; --- Вспомогательная функция: strcpy ---
.strcpy:
    push rdi
    push rsi
.loop_strcpy:
    lodsb
    test al, al
    jz .done_strcpy
    stosb
    jmp .loop_strcpy
.done_strcpy:
    pop rsi
    pop rdi
    ret

; --- Вспомогательная функция: itoa (число в строку) ---
.itoa:
    push rbx
    push rcx
    push rdx
    mov rbx, 10
    xor rcx, rcx
.div_loop:
    xor rdx, rdx
    div rbx
    add dl, '0'
    push rdx
    inc rcx
    test rax, rax
    jnz .div_loop
.pop_loop:
    pop rdx
    mov [rdi], dl
    inc rdi
    loop .pop_loop
    mov byte [rdi], 0
    pop rdx
    pop rcx
    pop rbx
    ret

; --- Вспомогательная функция: print (syscall write) ---
.print:
    mov rsi, rdi
    mov rdx, 0
.len_loop:
    cmp byte [rsi+rdx], 0
    je .len_done
    inc rdx
    jmp .len_loop
.len_done:
    mov rax, 1
    mov rdi, 1
    syscall
    ret
