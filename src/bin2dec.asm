; 6522 VIA
PORTB = $6000           
PORTA = $6001

DDRB = $6002            ; DATA DIRECTION REGISTER B
DDRA = $6003            ; DATA DIRECTION REGISTER A

PCR = $600C             ; PERIPHERAL CONTROL REGISTER
IFR = $600D             ; INTERRUPT FLAG REGISTER
IER = $600E             ; INTERRUPT ENABLE REGISTER

; RAM
valor = $0200           ; 2 bytes
resto = $0202           ; 2 bytes
mensaje = $0204         ; 6 bytes
contador = $020A        ; 2 bytes

; LCD
E  = %10000000          ; Enable
RW = %01000000          ; Read/Write
RS = %00100000          ; Register Select

   .org $8000

reset:
   ldx #$ff             ; Inicializar el 'Stack Pointer'
   txs

   cli                  ; Habilitiar interrupiones en el pin IRQ               

   lda #$82             ; Habilitar interrupciones en el pin CA1 del VIA
   sta IER
   lda #$00             ; Configurar para activar en transicion negativa
   sta PCR

   lda #%11111111       ; todo el puerto B es salida
   sta DDRB
   lda #%11100000       ; ultimos 3 pines en el puerto A son salidas
   sta DDRA

   lda #%00111000       ; Modo 8-bit, 2 lineas, caracteres de 5x8 px 
   jsr lcd_instruction   
   lda #%00001110       ; Display y cursor encendido, parpadeo apagado
   jsr lcd_instruction
   lda #%00000110       ; Escribir de izq-der, no desplazar display
   jsr lcd_instruction
   lda #%00000001       ; Limpiar display
   jsr lcd_instruction

   lda #0
   sta contador
   sta contador + 1
loop:

   lda #%00000010       ; Cursor Home
   jsr lcd_instruction

   lda #0               ; Inicializar el string vacio (termina con 0)
   sta mensaje

   sei                  ; Desabilitar interrupciones en IRQ para que no interfiera
   lda contador         ; valor (16 bits) = contador
   sta valor
   lda contador + 1
   sta valor + 1
   cli                  ; Volver a habilitar

dividir:   
   lda #0               ; resto (16 bits) = 0
   sta resto
   sta resto + 1        
   clc

   ldx #16
divloop:
   rol valor            ; bit shift entre los 4 bytes mediante el carry bit
   rol valor + 1        ; segunda mitad de valor
   rol resto            ; se pasa el carry del valor al primero del resto
   rol resto + 1        ; segunda mitad del resto

   sec                  ; seteo el carry bit para chequear si tuve que pedirlo prestado
   lda resto            ; cargo el resto en el acumulador
   sbc #10              ; le resto 10 al acumulador, uso el carry si necesito prestado
   tay                  ; guardo temporalmente el resultado en Y
   lda resto + 1
   sbc #0
   bcc ignorar_res      ; ignoramos el resultado si tuvimos que pedir prestado (resto < 10)
   sty resto            ; si la resta se hizo sin pedir prestado (resto >= 10), resto = res
   sta resto + 1        ; la primera mitad estaba en Y, la otra en A

ignorar_res:
   dex
   bne divloop
   rol valor            ; bit shift para darle el carry al valor y completar el cociente
   rol valor + 1

   lda resto            ; sumar el resto (n-avo digito del numero de der-izq) a asscii 0
   clc
   adc #"0"
   jsr push_char        ; ponerlo al frente del string
   
   lda valor            ; continuar dividiendo si el cociente no es 0
   ora valor + 1
   bne dividir

   ldx #0               ; Inicializar indice
print:
   lda mensaje,x        ; Cargar caracter del string mediante el offset
   beq loop             ; Romper loop si se lee #0
   jsr print_char
   inx                  ; Incrementar offset
   jmp print

numero: .word 420

; Mueve el caracter en A al frente del string de 6 bytes, moviendo el resto 1 byte a la der
push_char:              
   pha                  ; pongo el nuevo primer caracter en el Stack
   ldy #0               ; uso Y como indice para el string
char_loop:
   lda mensaje,y        ; mensaje[Y] => X
   tax
   pla                  ; saco el caracter del Stack y reemplazo el que movi a X 
   sta mensaje,y
   iny                  ; incremento el indice

   txa                  ; saco el caracter de X y lo subo al stack, en la siguiente-
   pha                  ; iteracion va a reemplazar el de su derecha, y ese al de su derecha...

   bne char_loop        ; si NO era el null el que subi, sigo iterando
   
   pla
   sta mensaje,y        ; Saco el ultimo 0 del Stack y lo pongo al final
   rts

lcd_wait:
   pha                  ; Guardar ultimo valor en el stack 
   lda #%00000000       ; Todo el Puerto B son entradas
   sta DDRB

lcd_check_busy:
   lda #RW              ; Modo lectura
   sta PORTA
   lda #(RW | E)        ; Bit E encendido
   sta PORTA
   lda PORTB            ; Leer Puerto B
   and #%10000000       ; AND con una mascara para la 'Busy Flag'
   bne lcd_check_busy   ; Loop si sigue encendida
   
   lda #RW              ; Apagar bit E
   sta PORTA
   lda #%11111111       ; Todo el Puerto B son salidas
   sta DDRB
   pla                  ; Recuperamos lo que guardamo en el stack
   rts

lcd_instruction:
   jsr lcd_wait
   sta PORTB            ; Modo 8-bit, 2 renglones, caracteres de 5x8 px
   lda #0               ; resetear el puerto A
   sta PORTA
   lda #E               ; prender bit 'E'
   sta PORTA
   lda #0               ; resetear puerto A
   sta PORTA
   rts

print_char:
   jsr lcd_wait 
   sta PORTB            ; Mandamos el char al puerto B
   lda #RS              ; Seleccionar registro de memoria del display
   sta PORTA
   lda #(RS | E)        ; prendemos el bit 'E', el display lee del puerto B
   sta PORTA
   lda #RS              ; apagamos el bit 'E'
   sta PORTA
   rts

nmi:
irq:

   bit PORTA            ; bit test del puerto A, al leerlo despejamos la interrupcion
   rti

   .org $fffa
   .word nmi
   .word reset
   .word irq