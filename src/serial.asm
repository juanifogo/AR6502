; 6551 ACIA
ACIA_DATA = $5000
ACIA_STATUS = $5001
ACIA_CMD = $5002
ACIA_CTRL = $5003

; 6522 VIA
PORTB = $6000           
PORTA = $6001

DDRB = $6002            ; DATA DIRECTION REGISTER B
DDRA = $6003            ; DATA DIRECTION REGISTER A

; LCD
E  = %01000000          ; Enable (PB6)
RW = %00100000          ; Read/Write (PB5)
RS = %00010000          ; Register Select (PB4)
                        ; PB3-PB0 son DB7-DB4 en el LCD
    .org $8000

reset:
    ldx #$ff            ; Inicializar el 'Stack Pointer'
    txs

    lda #%11111111      ; todo el puerto B es salida
    sta DDRB

    jsr lcd_init        ; modo de 4-bits
    lda #%00101000      ; Function set: modo 4 bits , 2 lineas, caracteres 5x8
    jsr lcd_instruction ; manda la instruccion 4 bits a la vez
    lda #%00001110      ; Display y cursor encendido, parpadeo apagado
    jsr lcd_instruction
    lda #%00000110      ; Escribir de izq-der, no desplazar display
    jsr lcd_instruction
    lda #%00000001      ; Limpiar display
    jsr lcd_instruction

    lda #%00000010       ; Cursor Home
    jsr lcd_instruction
    
    lda #$00
    sta ACIA_STATUS     ; Soft reset

    lda #$1f            ; 1 stop bit, no paridad, palabras de 8 bits, 19200 baud
    sta ACIA_CTRL

    lda #$0b            ; no interrupciones, no paridad, no eco
    sta ACIA_CMD
    
    ldx #0
send_message:
    lda mensaje,x       
    beq done
    jsr send_char      ; mandar caracter
    inx
    jmp send_message

done:

rx_wait
    lda ACIA_STATUS
    and #$08            ; chequear si hay un caracter en el buffer
    beq rx_wait         ; si no hay, esperar

    lda ACIA_DATA       ; leer el caracter
    jsr send_char       ; devolverlo al terminal
    jsr print_char      ; imprimirlo en el LCD
    jmp rx_wait         ; volver a esperar

mensaje: .asciiz "Hola mundo!"

send_char:
    sta ACIA_DATA
    pha
tx_wait:
    lda ACIA_STATUS
    and #$10            ; chequear si el buffer de tx esta vacio
    beq tx_wait         ; si no esta vacio, esperar
    pla
    rts

; chequea la busy flag hasta que este apagada
lcd_wait:
    pha
    lda #%11110000      ; PB7-PB4 OUTPUT, PB3-PB0 INPUT
    sta DDRB
lcdbusy:
    lda #RW             ; Modo lectura
    sta PORTB
    lda #(RW | E)       ; Enable
    sta PORTB
    lda PORTB           ; Leer nibble de arriba
    pha                 ; subir al stack para leerlo despues
    lda #RW             ; !Enable
    sta PORTB
    lda #(RW | E)       ; Enable
    sta PORTB
    lda PORTB           ; Leer nibble de abajo, no importa, el de arriba tenia la busy flag
    pla                 ; bajar la busy flag del stack
    and #%00001000      ; chequear si esta prendida
    bne lcdbusy         ; si lo esta volver a chequar

    lda #RW             ; Sino salimos, !Enable
    sta PORTB
    lda #%11111111      ; PB7-PB0 OUTPUT
    sta DDRB
    pla
    rts

lcd_init:
    pha 
    lda #%00000010      ; Modo de 4 bits
    sta PORTB           ; Escritura directa a PORTB, se mandan solo 4 bits
    ora #E              ; Enable
    sta PORTB
    and #%00001111      ; !Enable
    sta PORTB
    pla
    rts

lcd_instruction:
    jsr lcd_wait        ; chequear busy flag
    pha                 ; guardar la instruccion que se quiere mandar
    lsr                 ; right shift * 4
    lsr
    lsr
    lsr                 
    sta PORTB           ; PB3-PB0 --> DB7-DB4
    ora #E              ; Enable
    sta PORTB           ; mandamos el nibble de arriba de la instruccion
    eor #E              ; !Enable
    sta PORTB
    pla                 ; Recuperamos instruccion a mandar
    and #%00001111      ; apagamos el nibble de arriba de la instruccion
    sta PORTB           ; mandamos el nibble de abajo
    ora #E              ; Enable
    sta PORTB
    eor #E              ; !Enable
    sta PORTB
    rts

print_char:
    jsr lcd_wait        ; Esperamos a que el LCD este listo
    pha                 ; Guardamos el caracter a mandar en el stack
    lsr                 ; right shift * 4
    lsr
    lsr
    lsr             
    ora #RS             ; Seleccionar registro de datos
    sta PORTB           ; Mandamos el nibble de arriba
    ora #E              ; Enable
    sta PORTB
    eor #E              ; !Enable
    sta PORTB
    pla                 ; Recuperamos el caracter a enviar
    and #%00001111      ; apagamos el nibble de arriba
    ora #RS             ; Seleccionamos el registro de datos
    sta PORTB
    ora #E              ; Enable
    sta PORTB
    eor #E              ; !Enable
    sta PORTB
    rts
    
nmi:
    rti

irq:
    rti

; Vectores de Reset/Interrupciones
    .org $fffa
    .word nmi
    .word reset
    .word irq