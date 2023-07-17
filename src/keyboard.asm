; 6522 VIA
PORTB = $6000           
PORTA = $6001

DDRB = $6002            ; DATA DIRECTION REGISTER B
DDRA = $6003            ; DATA DIRECTION REGISTER A

PCR = $600C             ; PERIPHERAL CONTROL REGISTER
IFR = $600D             ; INTERRUPT FLAG REGISTER
IER = $600E             ; INTERRUPT ENABLE REGISTER

; LCD
E  = %01000000          ; Enable (PB6)
RW = %00100000          ; Read/Write (PB5)
RS = %00010000          ; Register Select (PB4)
                        ; PB3-PB0 son DB7-DB4 en el LCD

; RAM
kb_wptr = $0000         ; Puntero al ultimo byte escrito por el teclado
kb_rptr = $0001         ; Puntero al ultimo byte leido por el CPU
kb_flags = $0002        ; Variable con varias flags del estado del tecaldo

RELEASE = %00000001
SHIFT   = %00000010
kb_buffer = $0200       ; Buffer para el historial de teclas, 256-bytes ($0200-$02ff) 

    .org $8000

reset:
    ldx #$ff            ; Inicializar el 'Stack Pointer'
    txs

    lda #$01            ; Configurar para activar en transicion negativa
    sta PCR
    lda #$82            ; Habilitar interrupciones en el pin CA1 del VIA
    sta IER
    cli                 ; Habilitiar interrupiones en el pin IRQ  

    lda #%11111111      ; todo el puerto B es salida
    sta DDRB
    lda #%00000000      ; todo el puerto A es entrada
    sta DDRA

    jsr lcd_init        ; modo de 4-bits
    lda #%00101000      ; Function set: modo 4 bits , 2 lineas, caracteres 5x8
    jsr lcd_instruction ; manda la instruccion 4 bits a la vez
    lda #%00001110      ; Display y cursor encendido, parpadeo apagado
    jsr lcd_instruction
    lda #%00000110      ; Escribir de izq-der, no desplazar display
    jsr lcd_instruction
    lda #%00000001      ; Limpiar display
    jsr lcd_instruction

    lda #00             ; Inicializar pointers de lectura/escritura del kb_buffer
    sta kb_rptr
    sta kb_wptr
    sta kb_flags
loop:
    sei                 ; loop infinito chequando si leimos todo lo que hay en el 
    lda kb_rptr         ; buffer, sino saltamos a leerlo
    cmp kb_wptr
    cli
    bne key_pressed
    jmp loop

; lee y muestra en pantalla el siguiente caracter en el buffer
key_pressed:
    ldx kb_rptr         ; leer el buffer con el pointer de lectura como offset
    lda kb_buffer, x
    cmp #$0a            ; chequear si apretamos enter 
    beq enter_pressed   ; saltar a 2da linea
    cmp #$1b            ; chequeamos si apretamos escape
    beq esc_pressed     ; limpiar pantalla

    jsr print_char      ; si no es ninguno de esos, mostrar en pantalla
    inc kb_rptr         ; incrementar el pointer para la siguiente vez
    jmp loop

enter_pressed:
    lda #%11000000      ; poner cursor en la posicion 40
    jsr lcd_instruction ; escribir a la DDRAM
    inc kb_rptr         ; incrementamos el pointer de lectura porque no lo hicimos antes
    jmp loop            ; volver a esperar mas teclas

esc_pressed:
    lda #%00000001      ; limpiar display
    jsr lcd_instruction
    inc kb_rptr
    jmp loop

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

; IRQ apunta para aca
kb_interrupt:
    pha
    txa
    pha

    lda kb_flags        ; chequear si acabamos de soltar una tecla
    and #RELEASE
    beq read_key        ; leerla sino

    lda kb_flags        ; apagar la flag si estaba prendida
    eor #RELEASE
    sta kb_flags
    lda PORTA           ; leer la tecla que se solto
    ;shift izq
    cmp #$12            ; si es alguno de los shift, saltamos a manejarlo
    beq shift_released
    ;shift der
    cmp #$59
    beq shift_released
    jmp exit

read_key:
    lda PORTA           ; leer la tecla
    cmp #$F0            ; keycode de soltar tecla
    beq key_release     ; manejarlo si pasa
    ;shift izq
    cmp #$12            ; manejar si tocamos shift
    beq shift_pressed
    ;shift der
    cmp #$59
    beq shift_pressed

    tax                 ; guardar el keycode en x para usarlo como indice
    lda kb_flags        ; chequear si el shift ya estaba presionado
    and #SHIFT          ; si estaba, manejarlo
    bne shift_key

    lda keymap, x       ; cargar en A el map de keycode a 
    jmp push_key        ; caracter ASCII, usando X como offset (el keycode)

shift_key:              ; cargar en A el map de keycode con shift a ASCII
    lda keymap_shifted, x

push_key:               ; cual sea el caso, llegamos aca
    ldx kb_wptr         ; guardamos el caracter ASCII de A en el buffer
    sta kb_buffer, x    ; segun el pointer de escritura
    inc kb_wptr         ; incrementamos el pointer para la proxima
    jmp exit

shift_pressed:          ; prender flag de shift
    lda kb_flags
    ora #SHIFT
    sta kb_flags
    jmp exit

shift_released:         ; apagar flag de shift
    lda kb_flags
    eor #SHIFT
    sta kb_flags
    jmp exit

key_release:            ; prender flag de soltar tecla
    lda kb_flags
    ora #RELEASE
    sta kb_flags

exit:                   ; devolver al CPU a su estado original
    pla
    tax
    pla
    rti

nmi:
    rti

    .org $fd00
; mapping de keycodes a caracteres 
keymap:         
    .byte "????????????? `?" ; 00-0F
    .byte "?????q1???zsaw2?" ; 10-1F
    .byte "?cxde43?? vftr5?" ; 20-2F
    .byte "?nbhgy6???mju78?" ; 30-3F
    .byte "?,kio09??.-l",$ee,"p'?" ; 40-4F
    .byte "??{?[?????",$0a,"]?}??" ; 50-5F
    .byte "?????????1?47???" ; 60-6F
    .byte "0.2568",$1b,"??+3-*9??" ; 70-7F
    .byte "????????????????" ; 80-8F
    .byte "????????????????" ; 90-9F
    .byte "????????????????" ; A0-AF
    .byte "????????????????" ; B0-BF
    .byte "????????????????" ; C0-CF
    .byte "????????????????" ; D0-DF
    .byte "????????????????" ; E0-EF
    .byte "????????????????" ; F0-FF

; mapping de keycodes a caracteres con shift
keymap_shifted:
    .byte "????????????? ~?" ; 00-0F
    .byte '?????Q!???ZSAW"?' ; 10-1F
    .byte "?CXDE$#?? VFTR%?" ; 20-2F
    .byte "?NBHGY&???MJU/(?" ; 30-3F
    .byte "?;KIO=)??:_L",$ee,"P??" ; 40-4F
    .byte '??`?^??????*?}??' ; 50-5F
    .byte "?????????1?47???" ; 60-6F
    .byte "0.2568???+3-*9??" ; 70-7F
    .byte "????????????????" ; 80-8F
    .byte "????????????????" ; 90-9F
    .byte "????????????????" ; A0-AF
    .byte "????????????????" ; B0-BF
    .byte "????????????????" ; C0-CF
    .byte "????????????????" ; D0-DF
    .byte "????????????????" ; E0-EF
    .byte "????????????????" ; F0-FF

; Vectores de Reset/Interrupciones
    .org $fffa
    .word nmi
    .word reset
    .word kb_interrupt