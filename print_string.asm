   ldx #0               ; Inicializar offset

print:
   lda message,x        ; Cargar caracter del string mediante el offset
   beq loop             ; Romper loop si se lee #0
   jsr print_char
   inx                  ; Incrementar offset
   jmp print
