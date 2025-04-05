.include "m2560def.inc"  ; Definições do ATmega2560

.equ F_CPU = 16000000    ; Frequência do Arduino Mega (16 MHz)
.equ BAUD = 9600         ; Taxa de baud
.equ UBRR_VAL = (F_CPU / (16 * BAUD)) - 1  ; Valor para UBRR (baud rate register)
;.equ STACK_POINTER = 0x0200
.equ INT_EXAMPLE01 = 3  ; 1234 == 0x04D2                                                    ; DEBUG
.equ INT_EXAMPLE02 = 3                                                                      ; DEBUG
.equ RAT_EXAMPLE01 = 00                                                                     ; DEBUG
.equ RAT_EXAMPLE02 = 00                                                                     ; DEBUG
.equ SIGN_EXAMPLE = 0b00000000 ; bit 0 = primary sign | bit 1 = secondary sign              ; DEBUG
.equ EXAMPLE_HEX = 0xF2A4                                                                   ; DEBUG

.org 0x00                ; Início do código
    rjmp setup            ; Pula para a main

; Setup USART Registers -------------------------------------------------------------
config_usart:
    ; Configurar baud rate
    ldi r16, LOW(UBRR_VAL)
    sts UBRR0L, r16      ; Define parte baixa do baud rate
    ldi r16, HIGH(UBRR_VAL)
    sts UBRR0H, r16      ; Define parte alta do baud rate

    ; Habilitar TX (transmissão)
    ldi r16, (1<<TXEN0)  ; Habilita transmissor USART0
    sts UCSR0B, r16

    ; Configurar formato: 8 bits, sem paridade, 1 stop bit
    ldi r16, (1<<UCSZ01) | (1<<UCSZ00)
    sts UCSR0C, r16
    
    ret



; DEBUG TOOLS ----------------------------------------------------------------------------------
;SEND CHAR WITH NO TREATMENT
send_char_call_no_Correction: ; load r30
    ; Espera buffer estar vazio antes de enviar
    lds r31, UCSR0A
    sbrs r31, UDRE0      ; Verifica se o buffer está pronto
    rjmp send_char_call_no_Correction        ; Se não, espera

    sts UDR0, r30        ; Envia o caractere
    ret


;SEND FULL BYTE
send_full_byte_hex: ; load BYTE on r30 ; DEBUG
    push r28
    push r29
    push r30
    push r31
    ;esquerda do byte ------------------------------
    mov r29, r30
    andi r29,0xF0
    lsr r29
    lsr r29
    lsr r29
    lsr r29

    sbrs r29,3
    rjmp transform_number01
    sbrs r29,2
    rjmp next_test01
    rjmp transform_letter01
    
    next_test01:
    sbrs r29,1
    rjmp transform_number01

    transform_letter01:
        ldi r28, 55
        add r29, r28
        rjmp wait_tx_call01
    transform_number01:
        ori r29, 48 ; transform to ascii
    wait_tx_call01:
        ; Espera buffer estar vazio antes de enviar
        lds r31, UCSR0A
        sbrs r31, UDRE0      ; Verifica se o buffer está pronto
        rjmp wait_tx_call01       ; Se não, espera

        sts UDR0, r29       ; Envia o caractere

    ;direita do byte ------------------------------
    mov r29, r30
    andi r29,0x0F
    sbrs r29,3
    rjmp transform_number02
    sbrs r29,2
    rjmp next_test02
    rjmp transform_letter02
    
    next_test02:
    sbrs r29,1
    rjmp transform_number02

    transform_letter02:
        ldi r28, 55
        add r29, r28
        rjmp wait_tx_call02
    transform_number02:
        ori r29, 48 ; transform to ascii

    wait_tx_call02:
        ; Espera buffer estar vazio antes de enviar
        lds r31, UCSR0A
        sbrs r31, UDRE0      ; Verifica se o buffer está pronto
        rjmp wait_tx_call02        ; Se não, espera

        sts UDR0, r29       ; Envia o caractere


    pop r31
    pop r30
    pop r29
    pop r28

    ret


send_full_byte_binary:; load BYTE on R29 ; DEBUG
    push r28
    push r29
    push r30
    push r31

    mov r28, r29
    lsr r28
    lsr r28
    lsr r28
    lsr r28
    lsr r28
    lsr r28
    lsr r28
    andi r28, 1
    ori r28, 48
    mov r30, r28
    call send_char_call_no_Correction
    
    mov r28, r29
    lsr r28
    lsr r28
    lsr r28
    lsr r28
    lsr r28
    lsr r28
    andi r28, 1
    ori r28, 48
    mov r30, r28
    call send_char_call_no_Correction


    mov r28, r29
    lsr r28
    lsr r28
    lsr r28
    lsr r28
    lsr r28
    andi r28, 1
    ori r28, 48
    mov r30, r28
    call send_char_call_no_Correction


    mov r28, r29
    lsr r28
    lsr r28
    lsr r28
    lsr r28
    andi r28, 1
    ori r28, 48
    mov r30, r28
    call send_char_call_no_Correction


    mov r28, r29
    lsr r28
    lsr r28
    lsr r28
    andi r28, 1
    ori r28, 48
    mov r30, r28
    call send_char_call_no_Correction


    mov r28, r29
    lsr r28
    lsr r28
    andi r28, 1
    ori r28, 48
    mov r30, r28
    call send_char_call_no_Correction


    mov r28, r29
    lsr r28
    andi r28, 1
    ori r28, 48
    mov r30, r28
    call send_char_call_no_Correction

    mov r28, r29
    andi r28, 1
    ori r28, 48
    mov r30, r28
    call send_char_call_no_Correction
    
    pop r31
    pop r30
    pop r29
    pop r28

    ret

send_full_byte_decimal_primary:
    push r16
    push r17
    push r18
    push r19
    push r24
    push r25
    push r26
    push r31
    
    ; INTEGER --------------------------------------------------------------------------------
    ;; first number ---------------------------------

    ldi r25, high(10000)
    ldi r24, low(10000)
    
    ldi r26, 0
    
    repeat_div01:
    inc r26
    sub r18,r24
    sbc r19,r25
    brcc repeat_div01

    dec r26
    add r18,r24
    adc r19,r25

    ori r26, 48 ; transform to ascii
    wait_tx_sfbd01:
    ;; Espera buffer estar vazio antes de enviar
    lds r31, UCSR0A
    sbrs r31, UDRE0      ; Verifica se o buffer está pronto
    rjmp wait_tx_sfbd01        ; Se não, espera

    sts UDR0, r26      ; Envia o caractere
    

    ;; prox digito-------------------------------------

    ldi r25, high(1000)
    ldi r24, low(1000)
    
    ldi r26, 0
    
    repeat_div02:
    inc r26
    sub r18,r24
    sbc r19,r25
    brcc repeat_div02

    dec r26
    add r18,r24
    adc r19,r25
    
    ori r26, 48 ; transform to ascii
    wait_tx_sfbd02:
    ; Espera buffer estar vazio antes de enviar
    lds r31, UCSR0A
    sbrs r31, UDRE0      ; Verifica se o buffer está pronto
    rjmp wait_tx_sfbd02        ; Se não, espera

    sts UDR0, r26      ; Envia o caractere
    
    ;; prox digito -------------------------------------

    ldi r25, high(100)
    ldi r24, low(100)
    
    ldi r26, 0
    
    repeat_div03:
    inc r26
    sub r18,r24
    sbc r19,r25
    brcc repeat_div03

    dec r26
    add r18,r24
    adc r19,r25
    
    ori r26, 48 ; transform to ascii
    wait_tx_sfbd03:
    ; Espera buffer estar vazio antes de enviar
    lds r31, UCSR0A
    sbrs r31, UDRE0      ; Verifica se o buffer está pronto
    rjmp wait_tx_sfbd03        ; Se não, espera

    sts UDR0, r26      ; Envia o caractere
    
    ; prox digito -------------------------------------

    ldi r25, high(10)
    ldi r24, low(10)
    
    ldi r26, 0
    
    repeat_div04:
    inc r26
    sub r18,r24
    sbc r19,r25
    brcc repeat_div04

    dec r26
    add r18,r24
    adc r19,r25
    
    ori r26, 48 ; transform to ascii
    wait_tx_sfbd04:
    ; Espera buffer estar vazio antes de enviar
    lds r31, UCSR0A
    sbrs r31, UDRE0      ; Verifica se o buffer está pronto
    rjmp wait_tx_sfbd04        ; Se não, espera

    sts UDR0, r26      ; Envia o caractere

    ;; last digit---------------------------------------
    mov r26, r18

    ori r26, 48 ; transform to ascii
    wait_tx_sfbd05:
    ; Espera buffer estar vazio antes de enviar
    lds r31, UCSR0A
    sbrs r31, UDRE0         ; Verifica se o buffer está pronto
    rjmp wait_tx_sfbd05     ; Se não, espera

    sts UDR0, r26      ; Envia o caractere

    pop r18
    pop r19

    ldi r30, '.'
    call send_char_call_no_Correction

    push r16
    push r17
    ;; RATIONAL --------------------------------------------------------------------------
    ;; first number ------------------------------------

    ldi r25, high(1000)
    ldi r24, low(1000)
    
    ldi r26, 0
    
    repeat_div02_01:
    inc r26
    sub r16,r24
    sbc r17,r25
    brcc repeat_div02_01

    dec r26
    add r16,r24
    adc r17,r25
    
    ori r26, 48 ; transform to ascii
    wait_tx_sfbd02_01:
    ; Espera buffer estar vazio antes de enviar
    lds r31, UCSR0A
    sbrs r31, UDRE0      ; Verifica se o buffer está pronto
    rjmp wait_tx_sfbd02_01        ; Se não, espera

    sts UDR0, r26      ; Envia o caractere
    
    ;; prox digito--------------------------------------

    ldi r25, high(100)
    ldi r24, low(100)
    
    ldi r26, 0
    
    repeat_div03_01:
    inc r26
    sub r16,r24
    sbc r17,r25
    brcc repeat_div03_01

    dec r26
    add r16,r24
    adc r17,r25
    
    ori r26, 48 ; transform to ascii
    wait_tx_sfbd03_01:
    ; Espera buffer estar vazio antes de enviar
    lds r31, UCSR0A
    sbrs r31, UDRE0      ; Verifica se o buffer está pronto
    rjmp wait_tx_sfbd03_01        ; Se não, espera

    sts UDR0, r26      ; Envia o caractere
    
    ; prox digito----------------------------------------

    ldi r25, high(10)
    ldi r24, low(10)
    
    ldi r26, 0
    
    repeat_div04_01:
    inc r26
    sub r16,r24
    sbc r17,r25
    brcc repeat_div04_01

    dec r26
    add r16,r24
    adc r17,r25
    
    ori r26, 48 ; transform to ascii
    wait_tx_sfbd04_01:
    ; Espera buffer estar vazio antes de enviar
    lds r31, UCSR0A
    sbrs r31, UDRE0      ; Verifica se o buffer está pronto
    rjmp wait_tx_sfbd04_01        ; Se não, espera

    sts UDR0, r26      ; Envia o caractere

    ;; last digit----------------------------------------
    mov r26, r16

    ori r26, 48 ; transform to ascii
    wait_tx_sfbd05_01:
    ; Espera buffer estar vazio antes de enviar
    lds r31, UCSR0A
    sbrs r31, UDRE0         ; Verifica se o buffer está pronto
    rjmp wait_tx_sfbd05_01     ; Se não, espera

    sts UDR0, r26      ; Envia o caractere

    pop r31
    pop r26
    pop r25
    pop r24
    pop r19
    pop r18
    pop r17
    pop r16

    ret
send_full_byte_decimal_secondary:
    push r20
    push r21
    push r22
    push r23
    push r24
    push r25
    push r26
    push r31
    
    ; INTEGER --------------------------------------------------------------------------------
    ;; first number ---------------------------------

    ldi r25, high(10000)
    ldi r24, low(10000)
    
    ldi r26, 0
    
    repeat_div01_03:
    inc r26
    sub r22,r24
    sbc r23,r25
    brcc repeat_div01_03

    dec r26
    add r22,r24
    adc r23,r25

    ori r26, 48 ; transform to ascii
    wait_tx_sfbd01_03:
    ;; Espera buffer estar vazio antes de enviar
    lds r31, UCSR0A
    sbrs r31, UDRE0      ; Verifica se o buffer está pronto
    rjmp wait_tx_sfbd01_03        ; Se não, espera

    sts UDR0, r26      ; Envia o caractere
    

    ;; prox digito-------------------------------------

    ldi r25, high(1000)
    ldi r24, low(1000)
    
    ldi r26, 0
    
    repeat_div02_03:
    inc r26
    sub r22,r24
    sbc r23,r25
    brcc repeat_div02_03

    dec r26
    add r22,r24
    adc r23,r25
    
    ori r26, 48 ; transform to ascii
    wait_tx_sfbd02_03:
    ; Espera buffer estar vazio antes de enviar
    lds r31, UCSR0A
    sbrs r31, UDRE0      ; Verifica se o buffer está pronto
    rjmp wait_tx_sfbd02_03        ; Se não, espera

    sts UDR0, r26      ; Envia o caractere
    
    ;; prox digito -------------------------------------

    ldi r25, high(100)
    ldi r24, low(100)
    
    ldi r26, 0
    
    repeat_div03_03:
    inc r26
    sub r22,r24
    sbc r23,r25
    brcc repeat_div03_03

    dec r26
    add r22,r24
    adc r23,r25
    
    ori r26, 48 ; transform to ascii
    wait_tx_sfbd03_03:
    ; Espera buffer estar vazio antes de enviar
    lds r31, UCSR0A
    sbrs r31, UDRE0      ; Verifica se o buffer está pronto
    rjmp wait_tx_sfbd03_03        ; Se não, espera

    sts UDR0, r26      ; Envia o caractere
    
    ; prox digito -------------------------------------

    ldi r25, high(10)
    ldi r24, low(10)
    
    ldi r26, 0
    
    repeat_div04_03:
    inc r26
    sub r22,r24
    sbc r23,r25
    brcc repeat_div04_03

    dec r26
    add r22,r24
    adc r23,r25
    
    ori r26, 48 ; transform to ascii
    wait_tx_sfbd04_03:
    ; Espera buffer estar vazio antes de enviar
    lds r31, UCSR0A
    sbrs r31, UDRE0      ; Verifica se o buffer está pronto
    rjmp wait_tx_sfbd04_03        ; Se não, espera

    sts UDR0, r26      ; Envia o caractere

    ;; last digit---------------------------------------
    mov r26, r22

    ori r26, 48 ; transform to ascii
    wait_tx_sfbd05_03:
    ; Espera buffer estar vazio antes de enviar
    lds r31, UCSR0A
    sbrs r31, UDRE0         ; Verifica se o buffer está pronto
    rjmp wait_tx_sfbd05_03     ; Se não, espera

    sts UDR0, r26      ; Envia o caractere

    pop r22
    pop r23

    ldi r30, '.'
    call send_char_call_no_Correction

    push r20
    push r21
    ;; RATIONAL --------------------------------------------------------------------------
    ;; first number ------------------------------------

    ldi r25, high(1000)
    ldi r24, low(1000)
    
    ldi r26, 0
    
    repeat_div02_04:
    inc r26
    sub r20,r24
    sbc r21,r25
    brcc repeat_div02_04

    dec r26
    add r20,r24
    adc r21,r25
    
    ori r26, 48 ; transform to ascii
    wait_tx_sfbd02_04:
    ; Espera buffer estar vazio antes de enviar
    lds r31, UCSR0A
    sbrs r31, UDRE0      ; Verifica se o buffer está pronto
    rjmp wait_tx_sfbd02_04        ; Se não, espera

    sts UDR0, r26      ; Envia o caractere
    
    ;; prox digito--------------------------------------

    ldi r25, high(100)
    ldi r24, low(100)
    
    ldi r26, 0
    
    repeat_div03_04:
    inc r26
    sub r20,r24
    sbc r21,r25
    brcc repeat_div03_04

    dec r26
    add r20,r24
    adc r21,r25
    
    ori r26, 48 ; transform to ascii
    wait_tx_sfbd03_04:
    ; Espera buffer estar vazio antes de enviar
    lds r31, UCSR0A
    sbrs r31, UDRE0      ; Verifica se o buffer está pronto
    rjmp wait_tx_sfbd03_04        ; Se não, espera

    sts UDR0, r26      ; Envia o caractere
    
    ; prox digito----------------------------------------

    ldi r25, high(10)
    ldi r24, low(10)
    
    ldi r26, 0
    
    repeat_div04_04:
    inc r26
    sub r20,r24
    sbc r21,r25
    brcc repeat_div04_04

    dec r26
    add r20,r24
    adc r21,r25
    
    ori r26, 48 ; transform to ascii
    wait_tx_sfbd04_04:
    ; Espera buffer estar vazio antes de enviar
    lds r31, UCSR0A
    sbrs r31, UDRE0      ; Verifica se o buffer está pronto
    rjmp wait_tx_sfbd04_04        ; Se não, espera

    sts UDR0, r26      ; Envia o caractere

    ;; last digit----------------------------------------
    mov r26, r20

    ori r26, 48 ; transform to ascii
    wait_tx_sfbd05_04:
    ; Espera buffer estar vazio antes de enviar
    lds r31, UCSR0A
    sbrs r31, UDRE0         ; Verifica se o buffer está pronto
    rjmp wait_tx_sfbd05_04     ; Se não, espera

    sts UDR0, r26      ; Envia o caractere

    pop r31
    pop r26
    pop r25
    pop r24
    pop r23
    pop r22
    pop r21
    pop r20
    ret

send_sign_primary:
    sbrc r24, 0
    rjmp print_minus01
    print_plus01:
    ldi r30, '+'
    call send_char_call_no_Correction
    ret
    print_minus01:
    ldi r30, '-'
    call send_char_call_no_Correction
    ret
send_sign_secondary:
    sbrc r24, 1
    rjmp print_minus02
    print_plus02:
    ldi r30, '+'
    call send_char_call_no_Correction
    ret
    print_minus02:
    ldi r30, '-'
    call send_char_call_no_Correction
    ret
tester: ; DEBUG
    rjmp tester_push
    tester_push_return:


    ldi r30, ' '
    call send_char_call_no_Correction

    mov r29, r24
    call send_full_byte_binary
    ldi r30, '|'
    call send_char_call_no_Correction

    mov r30, r23
    call send_full_byte_hex
    mov r30, r22
    call send_full_byte_hex
    ldi r30, '.'
    call send_char_call_no_Correction
    mov r30, r21
    call send_full_byte_hex
    mov r30, r20
    call send_full_byte_hex
    ldi r30, '|'
    call send_char_call_no_Correction

    mov r30, r19
    call send_full_byte_hex
    mov r30, r18
    call send_full_byte_hex
    ldi r30, '.'
    call send_char_call_no_Correction
    mov r30, r17
    call send_full_byte_hex
    mov r30, r16
    call send_full_byte_hex
    ldi r30, ';'
    call send_char_call_no_Correction

    rjmp tester_pop
    tester_pop_return:
    
    ret
tester_push:; DEBUG
    push r16
    push r17
    push r18
    push r19
    push r20
    push r21
    push r22
    push r23
    push r24
    push r25
    push r26
    push r27
    push r28
    push r29
    push r30
    push r31
    rjmp tester_push_return
tester_pop:; DEBUG
    pop r31
    pop r30
    pop r29
    pop r28
    pop r27
    pop r26
    pop r25
    pop r24
    pop r23
    pop r22
    pop r21
    pop r20
    pop r19
    pop r18
    pop r17
    pop r16
    rjmp tester_pop_return
to_value_primary:
    ; Use the 4 Reg to hold full value
    ; r21:r20 = count excess
    ; r23:r22 = save initial r19:r18 value (number multiplied)
    ; r29:r28 = dec (number multiplying)
    ; r21:r20:r19:r18 = final value

    push r20
    push r21
    push r22
    push r23
    
    ; multiplier
    ldi r29, high(10000)
    ldi r28, low(10000)

    ; multiplied
    mov r23, r19
    mov r22, r18

    clr r20
    clr r21
    clr r30

    add_to_value_primary:
    subi r28,1
    sbci r29, 0
    
    cp r28, r30            ; Compare low byte
    cpc r29, r30          ; Compare high byte
    breq end_add_to_value_primary

    clc
    add r18,r22
    adc r19,r23
    adc r20, r30
    adc r21, r30

    rjmp add_to_value_primary

    end_add_to_value_primary:

    ; r23:r22:r21:r20 = r21:r20:r19:r18
    mov r23, r21
    mov r22, r20
    mov r21, r19
    mov r20, r18

    ; clear r19:r18
    clr r19
    clr r18

    ; r19:r18:r17:r16 = r19:r18:r17:r16 + r23:r22:r21:r20
    add r16, r20
    adc r17, r21
    adc r18, r22
    adc r19, r23

    pop r23
    pop r22
    pop r21
    pop r20

    ret

from_value_primary:
    ; Use 2 Reg for Rational and other 2 for Integer
    ; r19:r18:r17:r16 = initial value (numerator)
    ; r29:r28 = divisor (denominator)
    ; r21:r20 = count number (final number)
    
    push r20
    push r21
    push r22
    push r23 
    
    ; divisor
    ldi r29, high(10000)
    ldi r28, low(10000)

    clr r20
    clr r21
    ; valor de incremento
    ldi r30, 1
    ldi r31, 0

    sub_from_value_primary:
    cp r16, r28           
    cpc r17, r29          
    cpc r18, r31          
    cpc r19, r31          
    brlo end_sub_from_value_primary  
    
    clc
    add r20, r30 
    adc r21, r31
    
    clc
    sub r16, r28
    sbc r17, r29
    sbc r18, r31
    sbc r19, r31

    rjmp sub_from_value_primary
    end_sub_from_value_primary:

    clr r19
    clr r18

    mov r18, r20
    mov r19, r21

    pop r23
    pop r22
    pop r21
    pop r20

    ret

to_value_secondary:
    ; Use the 4 Reg to hold full value
    ; r21:r20 = count excess
    ; r23:r22 = save initial r19:r18 value (number multiplied)
    ; r29:r28 = dec (number multiplying)
    ; r21:r20:r19:r18 = final value
    
    push r16
    push r17
    push r18
    push r19

    mov r16, r20    
    mov r17, r21
    mov r18, r22
    mov r19, r23


    ; multiplier
    ldi r29, high(10000)
    ldi r28, low(10000)

    ; multiplied
    mov r23, r19
    mov r22, r18

    clr r20
    clr r21
    clr r30

    add_to_value_secondary:
    subi r28,1
    sbci r29, 0
    
    cp r28, r30            ; Compare low byte
    cpc r29, r30          ; Compare high byte
    breq end_add_to_value_secondary

    clc
    add r18,r22
    adc r19,r23
    adc r20, r30
    adc r21, r30

    rjmp add_to_value_secondary

    end_add_to_value_secondary:

    ; r23:r22:r21:r20 = r21:r20:r19:r18
    mov r23, r21
    mov r22, r20
    mov r21, r19
    mov r20, r18

    ; clear r19:r18
    clr r19
    clr r18

    ; r19:r18:r17:r16 = r19:r18:r17:r16 + r23:r22:r21:r20
    add r16, r20
    adc r17, r21
    adc r18, r22
    adc r19, r23


    mov r20, r16    
    mov r21, r17
    mov r22, r18
    mov r23, r19

    pop r19
    pop r18
    pop r17
    pop r16

    ret

from_value_secondary:
    ; Use 2 Reg for Rational and other 2 for Integer
    ; r19:r18:r17:r16 = initial value (numerator)
    ; r29:r28 = divisor (denominator)
    ; r21:r20 = count number (final number)
     
    push r16
    push r17
    push r18
    push r19

    mov r16, r20    
    mov r17, r21
    mov r18, r22
    mov r19, r23


    ; divisor
    ldi r29, high(10000)
    ldi r28, low(10000)

    clr r20
    clr r21
    ; valor de incremento
    ldi r30, 1
    ldi r31, 0

    sub_from_value_secondary:
    cp r16, r28           
    cpc r17, r29          
    cpc r18, r31          
    cpc r19, r31          
    brlo end_sub_from_value_secondary
    
    clc
    add r20, r30 
    adc r21, r31
    
    clc
    sub r16, r28
    sbc r17, r29
    sbc r18, r31
    sbc r19, r31

    rjmp sub_from_value_secondary
    end_sub_from_value_secondary:

    clr r19
    clr r18

    mov r18, r20
    mov r19, r21


    
    mov r20, r16    
    mov r21, r17
    mov r22, r18
    mov r23, r19

    pop r19
    pop r18
    pop r17
    pop r16

    ret

from_64bits_to_16bits:
    ; Transform the result number that uses 8 Regs to 2 Regs
    ; r23:r22:r21:r20:r19:r18:r17:r16 = initial value (numerator)
    ; r27:r26:r25:r24 = divisor (denominator)
    ; r29:r28 = count number (final number)

    ; Para parte inteira 
    ; 100.000.000 (dec) = 05.F5.E1.00 (Hex)
    ldi r24, 0x00
    ldi r25, 0xE1
    ldi r26, 0xF5
    ldi r27, 0x05

    clr r31
    clr r30
    clr r29
    clr r28

    sub_from_64_to_16_01:
    ;compare
    ldi r31, 0

    clc
    cp r16, r24
    cpc r17, r25
    cpc r18, r26
    cpc r19, r27
    cpc r20, r31
    cpc r21, r31
    cpc r22, r31
    cpc r23, r31
    brlo end_sub_from_64_to_16_01

    ; increment
    
    ldi r30, 1
    ldi r31, 0

    clc
    add r28, r30
    adc r29, r31

    ; subtract dividend, divisor

    ldi r31, 0

    clc
    sub r16, r24
    sbc r17, r25
    sbc r18, r26
    sbc r19, r27
    sbc r20, r31
    sbc r21, r31
    sbc r22, r31
    sbc r23, r31

    ; loop again
    rjmp sub_from_64_to_16_01

    end_sub_from_64_to_16_01:

    push r28
    push r29

    ; Para a parte Racional

    ; r23:r22:r21:r20:r19:r18:r17:r16 = rest (numerator)
    ; r25:r24 = divisor (denominator)
    ; r29:r28 = count number (final number)
    
    ; 10.000 (dec)
    ldi r25, high(10000)
    ldi r24, low(10000)

    clr r31
    clr r30
    clr r29
    clr r28

    sub_from_64_to_16_02:
    ;compare
    ldi r31, 0

    clc
    cp r16, r24
    cpc r17, r25
    cpc r18, r31
    cpc r19, r31
    cpc r20, r31
    cpc r21, r31
    cpc r22, r31
    cpc r23, r31
    brlo end_sub_from_64_to_16_02

    ; increment
    ldi r30, 1
    ldi r31, 0

    clc
    add r28, r30
    adc r29, r31

    ; subtract dividend, divisor
    ldi r31, 0

    clc
    sub r16, r24
    sbc r17, r25
    sbc r18, r31
    sbc r19, r31
    sbc r20, r31
    sbc r21, r31
    sbc r22, r31
    sbc r23, r31

    ; loop again
    rjmp sub_from_64_to_16_02

    end_sub_from_64_to_16_02:

    pop r19
    pop r18
    mov r17, r29
    mov r16, r28

    call to_value_primary

    ret
set_sign_for_zero:
    ldi r31, 0

    cp  r31, r16
    cpc r31, r17
    cpc r31, r18
    cpc r31, r19
    brne not_zero

    zero:
    ldi r24, 0

    not_zero:
    ret
sign_inverter:
    ori r24, 0b00000100
    ror r24
    subi r24, 1
    rol r24
    andi r24, 0b00000011
    ret
mem_to_primary:
    or r24, r25
    ret

mem_to_secondary:
    lsl r25
    or r24, r25
    ret
; OPERATIONS -----------------------------------------------------------------------------
add_numbers:

    ; add rational
    add r16,r20
    adc r17,r21
    
    ; save rational value
    push r16
    push r17
    
    ; Check if fractional overflow (≥ 10000)
    ldi r31, high(10000)
    ldi r30, low(10000)
    cp r16, r30           ; Compare low byte
    cpc r17, r31          ; Compare high byte
    brlo if_no_int_add    ; If less than 10000, skip carry addition

    ; Subtract 10000 to normalize fractional part
    sub r16, r30
    sbc r17, r31

    ; Add carry to integer part
    sec
    adc r18, r22
    adc r19, r23

    ; clear old rational value
    pop r30
    pop r30
    clr r30

    ret

    if_no_int_add:
    ; retrieve rational value
    pop r17
    pop r16

    ; add integer
    add r18,r22
    adc r19,r23

    ret
sub_numbers:
    
    ; RATIONAL SUB
    ; Check which one is bigger
    cp r16, r20              ; Compare low byte
    cpc r17, r21             ; Compare high byte
    brlo sec_minus_pri_01    ; If primary less than secondary, do secondary minus primary 

    ; sub (primary - secondary)
    pri_minus_sec_01:
    sub r16,r20
    sbc r17,r21

    rjmp sub_without_carry

    ; sub (secondary - primary)
    sec_minus_pri_01:
    sub r20,r16
    sbc r21,r17

    ldi r31, high(10000)
    ldi r30, low(10000)

    sub r30, r20
    sbc r31, r21

    mov r16, r30
    mov r17, r31 

    rjmp sub_with_carry
    
    ; INTEGER SUB - IF CARRY SET
    sub_with_carry:
    ; Check which one is bigger 
    cp r18, r22              ; Compare low byte
    cpc r19, r23             ; Compare high byte
    brlo sec_minus_pri_02    ; If primary less than secondary, do secondary minus primary 

    ; sub (primary - secondary)
    pri_minus_sec_02:
    sub r18,r22
    sbc r19,r23
    subi r18, 1
    sbci r19, 0

    ret

    ; sub (secondary - primary)
    sec_minus_pri_02:
    sub r22,r18
    sbc r23,r19

    mov r18, r22
    mov r19, r23 
    
    subi r18, 1
    sbci r19, 0

    ret

    ; INTEGER SUB - IF CARRY CLEAR
    sub_without_carry:
    ; Check which one is bigger
    cp r18, r22              ; Compare low byte
    cpc r19, r23             ; Compare high byte
    brlo sec_minus_pri_03    ; If primary less than secondary, do secondary minus primary 

    ; sub (primary - secondary)
    pri_minus_sec_03:
    sub r18,r22
    sbc r19,r23

    ret

    ; sub (secondary - primary)
    sec_minus_pri_03:
    sub r22,r18
    sbc r23,r19

    mov r18, r22
    mov r19, r23 
    
    ret

mul_numbers:

    ; Int + Rational = Value
    ; r19:r18:r17:r16 = FULL PRIMARY VALUE
    ; r23:r22:r21:r20 = FULL SECONDARY VALUE

    ; this 2 functions transform the number in a full number,
    ; using 4 register as one full number
    call to_value_primary
    call to_value_secondary

    ; r27:r26:r25:r24 = Copy of Primary value (Number to add)
    ; r31:r30:r29:r28 = Copy of Secondary value (Counter Decrementing)
    ; r23:r22:r21:r20:r19:r18:r17:r16 = Result 

    mov r24, r16
    mov r25, r17
    mov r26, r18
    mov r27, r19

    mov r28, r20
    mov r29, r21
    mov r30, r22
    mov r31, r23

    ; keep primary value, just clean the excess
    clr r20
    clr r21
    clr r22
    clr r23


    ; Start multiplication
    ; r27 = Also used as number 0 to compare
    add_mul:
    ; save r17 old value to use it as zero, retrive after
    push r27
    ldi r27, 0

    ; sub 1 from count
    subi r28,1
    sbci r29, 0
    sbci r30, 0
    sbci r31, 0
    
    ; compare to see if the mult ends (count == 0?)
    cp r28, r27        
    cpc r29, r27
    cpc r30, r27
    cpc r31, r27
    breq end_add_mul  

    ; retrive old r27 value, store r31 to use the reg as 0
    pop r27
    push r31
    ldi r31, 0

    ; clear carry flag and start adding
    clc
    add r16, r24
    adc r17, r25
    adc r18, r26
    adc r19, r27
    adc r20, r31
    adc r21, r31
    adc r22, r31
    adc r23, r31

    ; retrive old r31 value 
    pop r31

    ; restart loop
    rjmp add_mul

    end_add_mul:
    ; take r27 value out of stack (call/ret instructions also use the same stack 
    ; to store the line to return, so you can't have other numbers in between)
    pop r27
    
    ; since we used 8 register to store the result, need to transform it back to 4 again
    ; that is what this function do
    call from_64bits_to_16bits

    ; this 2 function transform back the full number to the
    ; model: 2 regs for integer part, 2 regs for rational part 
    call from_value_primary
    call from_value_secondary

    ret
div_real_numbers:

    ; Int + Rational = Value
    ; r19:r18:r17:r16 = FULL PRIMARY VALUE
    ; r23:r22:r21:r20 = FULL SECONDARY VALUE
    call to_value_primary
    call to_value_secondary

    ; r19:r18:r17:r16 = Numerator
    ; r23:r22:r21:r20 = Denominator
    ; r25:r24 = Remain

    ; integer part----------------------------------------

    clr r25
    clr r24
    ; valor de incremento
    ldi r30, 1
    ldi r31, 0

    sub_div_real_integer:
    ; compare if can sub a whole number yet
    cp  r16, r20           
    cpc r17, r21          
    cpc r18, r22          
    cpc r19, r23          
    brlo end_sub_div_real_integer
    
    ; clear carry flag and add to count
    clc
    add r24, r30 
    adc r25, r31
    
    ; clear carry flag and sub the denominator from numerator
    clc
    sub r16, r20
    sbc r17, r21
    sbc r18, r22
    sbc r19, r23

    ; loop again
    rjmp sub_div_real_integer
    end_sub_div_real_integer:

    ; save integer part from division
    push r24
    push r25
    
    ; rational part -------------------------------
    ; r19:r18:r17:r16 = Numerator
    ; r23:r22:r21:r20 = Denominator
    ; r24 = Remain
    ; r25 = number of subtraction (4)

    ; 4 digits for rational, 4 divisions
    ldi r25, 3

    ; multply by 10 makes the number possible to sub, 
    ; so we multiply by 10, count the subs and that will 
    ; be the next digit after dot.
    mult_by_10_div_real_rational:
    ; save denominator
    push r20
    push r21
    push r22
    push r23
    ; save count mult
    push r25

    call from_value_primary

    ; multiply numerator by 10, to get each post-point number
    ; load secondary with 10 to multiply it by 10
    ldi r23, high(10)
    ldi r22, low(10)
    ldi r21, 0
    ldi r20, 0
    
    call mul_numbers

    call to_value_primary

    ; retrive mult count and denominator
    pop r25
    pop r23
    pop r22
    pop r21
    pop r20

    clr r24
    ; valor de incremento
    ldi r30, 1
    ldi r31, 0

    sub_div_real_rational:
    ; compare if its possible to sub
    cp  r16, r20           
    cpc r17, r21          
    cpc r18, r22          
    cpc r19, r23          
    brlo end_sub_div_real_rational
    
    ; increment count
    add r24, r30
    
    ; clear carry flag and sub denominator from numerator
    clc
    sub r16, r20
    sbc r17, r21
    sbc r18, r22
    sbc r19, r23

    ; loop again
    rjmp sub_div_real_rational
    end_sub_div_real_rational:
    ; save digit
    push r24
 
    ; check if was already 4 digits/iterations
    cp r25, r31
    breq end_mult_by_10_div_real_rational

    ; if not, sub count and repeat it
    subi r25, 1
    rjmp mult_by_10_div_real_rational
    end_mult_by_10_div_real_rational:

    ; clear register and organize the digits 
    clr r16
    clr r17
    clr r18
    clr r19

    clr r20
    clr r21
    clr r22
    clr r23
    
    ; since we only got the digit, need to multiply it 
    ; according to the correct order from right to left
    ; last digit
    pop r20
    
    ; second last digit
    ; take last and save actual rational value
    pop r16
    push r20
    push r21

    ; do the multiply to the correct order
    call from_value_primary
    ldi r23, high(10)
    ldi r22, low(10)
    ldi r21, 0
    ldi r20, 0
    
    call mul_numbers

    call to_value_primary

    ; take out the actual value and sum to the other digit
    pop r21
    pop r20
    add r20, r16
    adc r21, r17
    
    ; third last digit
    pop r16
    push r20
    push r21

    call from_value_primary
    ldi r23, high(100)
    ldi r22, low(100)
    ldi r21, 0
    ldi r20, 0
    
    call mul_numbers

    call to_value_primary

    pop r21
    pop r20
    add r20, r16
    adc r21, r17
    
    ; fourth last number
    clr r17
    pop r16
    push r20
    push r21

    call from_value_primary
    ldi r23, high(1000)
    ldi r22, low(1000)
    ldi r21, 0
    ldi r20, 0

    call mul_numbers

    call to_value_primary

    pop r21
    pop r20
    add r16, r20
    adc r17, r21

    ; return to normal mode (INT - RAT)     
    call from_value_secondary
    
    ; pop the integer part saved before to its place
    pop r19
    pop r18

    ret
div_int_numbers:
    ; Int + Rational = Value
    ; r19:r18:r17:r16 = FULL PRIMARY VALUE
    ; r23:r22:r21:r20 = FULL SECONDARY VALUE
    call to_value_primary
    call to_value_secondary

    ; r19:r18:r17:r16 = Numerator
    ; r23:r22:r21:r20 = Denominator
    ; r25:r24 = Result

    ; integer part----------------------------------------

    clr r25
    clr r24
    ; valor de incremento
    ldi r30, 1
    ldi r31, 0

    sub_div_int_integer:
    cp  r16, r20           
    cpc r17, r21          
    cpc r18, r22          
    cpc r19, r23          
    brlo end_sub_div_int_integer
    
    clc
    add r24, r30 
    adc r25, r31
    
    clc
    sub r16, r20
    sbc r17, r21
    sbc r18, r22
    sbc r19, r23

    rjmp sub_div_int_integer
    end_sub_div_int_integer:

    ; save integer
    clr r16
    clr r17
    mov r18, r24
    mov r19, r25

    ret
rest_numbers:
    ; Int + Rational = Value
    ; r19:r18:r17:r16 = FULL PRIMARY VALUE
    ; r23:r22:r21:r20 = FULL SECONDARY VALUE
    call to_value_primary
    call to_value_secondary

    ; r19:r18:r17:r16 = Numerator
    ; r23:r22:r21:r20 = Denominator

    ; integer part----------------------------------------

    ; valor de incremento
    ldi r30, 1
    ldi r31, 0

    sub_rest_integer:
    cp  r16, r20
    cpc r17, r21
    cpc r18, r22
    cpc r19, r23
    brlo end_sub_rest_integer
    
    clc
    sub r16, r20
    sbc r17, r21
    sbc r18, r22
    sbc r19, r23

    rjmp sub_rest_integer
    end_sub_rest_integer:

    call from_value_primary
    call from_value_secondary

    ret
power_numbers:
    ; r19:r18:r17:r16 = number under power
    ; r23:r22:r21:r20 = power (initial) -> same number
    ; r25:r24 = power moved (decrement count)
    
    ; copy expoent
    mov r24, r22
    mov r25, r23

    ; copy base
    mov r20, r16
    mov r21, r17
    mov r22, r18
    mov r23, r19

    ; save base and expoent
    push r20
    push r21
    push r22
    push r23
    push r24
    push r25

    keep_mul_power:
    ; retrive base and expoent
    pop r25
    pop r24
    pop r23
    pop r22
    pop r21
    pop r20

    clr r31

    ; sub from count/expoent
    subi r24, 1
    sbci r25, 0

    ; check if count==0, then end power
    cp  r24, r31 
    cpc r25, r31
    breq end_keep_mul_power
    
    ; save base and expoent
    push r20
    push r21
    push r22
    push r23
    push r24
    push r25

    ; since r23:r22:r21:r20 are the secondary number, no need to load it again
    ; do mult
    call mul_numbers

    ; loop again
    rjmp keep_mul_power
    
    end_keep_mul_power:

    ret
add_int_numbers:
    
    ; test to check signs
    sbrc r24, 0
    rjmp other_sign_test_add_int
    sbrc r24, 1
    rjmp dif_signs_add_int
    rjmp eq_signs_add_int

    other_sign_test_add_int:
    sbrc r24, 1
    rjmp eq_signs_add_int
    dif_signs_add_int: ; if diferent signs, do sub 
    call to_value_primary
    call to_value_secondary

    ; check which one is bigger to do (highest-lowest)
    cp  r16, r20
    cpc r17, r21
    cpc r18, r22
    cpc r19, r23
    brlo secondary_bigger
    primary_bigger:
    ; keep the primary sign
    call from_value_primary
    call from_value_secondary

    andi r24, 1
    push r24
    call sub_numbers
    pop r24

    call set_sign_for_zero
    ret

    secondary_bigger:
    call from_value_primary
    call from_value_secondary

    lsr r24
    push r24
    
    push r16
    push r17
    push r18
    push r19

    mov r16, r20
    mov r17, r21
    mov r18, r22
    mov r19, r23

    pop r23
    pop r22
    pop r21
    pop r20

    call sub_numbers

    pop r24
    call set_sign_for_zero

    ret
    
    eq_signs_add_int:
    andi r24, 1
    push r24
    call add_numbers
    pop r24

    call set_sign_for_zero
    ret

mul_int_numbers:
     
    sbrc r24, 0
    rjmp other_sign_test_mul_int
    sbrc r24, 1
    rjmp dif_signs_mul_int
    rjmp eq_signs_mul_int

    other_sign_test_mul_int:
    sbrc r24, 1
    rjmp eq_signs_mul_int
    dif_signs_mul_int:
    ldi r24, 1
    push r24
    
    call mul_numbers
    
    pop r24
    call set_sign_for_zero
    ret
    
    eq_signs_mul_int:
    ldi r24, 0
    push r24

    call mul_numbers
    
    pop r24
    call set_sign_for_zero
    ret

div_int_int_numbers:
      
    sbrc r24, 0
    rjmp other_sign_test_div_int_int
    sbrc r24, 1
    rjmp dif_signs_div_int_int
    rjmp eq_signs_div_int_int

    other_sign_test_div_int_int:
    sbrc r24, 1
    rjmp eq_signs_div_int_int
    dif_signs_div_int_int:
    ldi r24, 1
    push r24
    
    call div_int_numbers
    
    pop r24
    call set_sign_for_zero
    ret
    
    eq_signs_div_int_int:
    ldi r24, 0
    push r24

    call div_int_numbers
    
    pop r24
    call set_sign_for_zero
    ret

div_real_int_numbers:
     
      
    sbrc r24, 0
    rjmp other_sign_test_div_real_int
    sbrc r24, 1
    rjmp dif_signs_div_real_int
    rjmp eq_signs_div_real_int

    other_sign_test_div_real_int:
    sbrc r24, 1
    rjmp eq_signs_div_real_int
    dif_signs_div_real_int:
    ldi r24, 1
    push r24
    
    call div_real_numbers
    
    pop r24
    call set_sign_for_zero
    ret
    
    eq_signs_div_real_int:
    ldi r24, 0
    push r24

    call div_real_numbers
    
    pop r24
    call set_sign_for_zero
    ret

power_int_numbers:
    sbrc r24, 0
    rjmp minus_number_power
    plus_number_power:
    ldi r24, 0
    push r24

    call power_numbers

    pop r24

    call set_sign_for_zero
    ret

    minus_number_power:
    push r16
    push r17
    push r18
    push r19
    push r20
    push r21
    push r22
    push r23

    mov r16,r20
    mov r17,r21
    mov r18,r22
    mov r19,r23

    clr r20
    clr r21
    ldi r22, 2
    clr r23

    call rest_numbers

    ldi r31, 0

    cp  r16, r31
    cpc r17, r31
    cpc r18, r31
    cpc r19, r31
    breq is_even
    is_odd:
    pop r23
    pop r22
    pop r21
    pop r20
    pop r19
    pop r18
    pop r17
    pop r16
    ldi r24, 1
    push r24
    

    call power_numbers

    pop r24

    call set_sign_for_zero
    ret

    is_even:
    pop r23
    pop r22
    pop r21
    pop r20
    pop r19
    pop r18
    pop r17
    pop r16
    ldi r24, 0
    push r24

    call power_numbers

    pop r24

    call set_sign_for_zero
    ret
; FUNCTIONS ------------------------------------------------------------------------
send_full_number_hex_primary: ; DEBUG
    mov r30, r19
    call send_full_byte_hex
    mov r30, r18
    call send_full_byte_hex
    ldi r30, '.'
    call send_char_call_no_Correction
    mov r30, r17
    call send_full_byte_hex
    mov r30, r16
    call send_full_byte_hex
    ret

send_full_number_hex_secondary: ; DEBUG
    mov r30, r23
    call send_full_byte_hex
    mov r30, r22
    call send_full_byte_hex
    ldi r30, '.'
    call send_char_call_no_Correction
    mov r30, r21
    call send_full_byte_hex
    mov r30, r20
    call send_full_byte_hex
    ret


; MAIN CODE -------------------------------------------------------------------------
setup:
    ; config stack pointer
    ldi r16, high(RAMEND)
    sts SPH,r16
    ldi r16, low(RAMEND)
    sts SPL,r16

    call config_usart
    
    ;clear registers
    clr r17
    clr r18
    clr r19
    clr r20
    clr r21
    clr r22
    clr r23
    clr r24

    ldi r30, 13
    call send_char_call_no_Correction

main:
    ; -----------------------------------------------
    clr r24
    ; ((2 4 -) MEM) = -2
    ; Load primary number
    ldi r19, 0
    ldi r18, 2
    ldi r17, 0
    ldi r16, 0
    ori r24, 0b00000000

    ; Load secondary number
    ldi r23, 0
    ldi r22, 4
    ldi r21, 0
    ldi r20, 0
    ori r24, 0b00000000

    ; Do Math
    call sign_inverter
    call add_int_numbers

    ; Push to STACK (Save MEM)
    ; salva o sinal e o número
    push r24
    push r16
    push r17
    push r18
    push r19

    ; print serial
    call send_sign_primary
    call send_full_byte_decimal_primary
    ldi r30, '|'
    call send_char_call_no_Correction

    ; ---------------------------------------------
    clr r24

     ; (2 MEM +) == (2 -2 +) = 0
    ; Load primary number
    ldi r19, 0
    ldi r18, 2
    ldi r17, 0
    ldi r16, 0
    ori r24, 0b00000000

    ; Load secondary number MEM
    ; Ele tira da pilha na ordem que foi guardado, lembrando que é uma pilha então é FILO
    ; tira o valor do sinal da pilha e dps o valor, como é o segundo, usa mem_to_secondary para arrumar sinal
    pop r23
    pop r22
    pop r21
    pop r20
    pop r25
    push r25
    push r20
    push r21
    push r22
    push r23
    call mem_to_secondary

    ; Do Add
    call add_int_numbers

    ; print serial
    call send_sign_primary
    call send_full_byte_decimal_primary
    ldi r30, '|'
    call send_char_call_no_Correction

    ;----------------------------------------------
    clr r24

     ; (MEM -2 +) == (-2 -2 +) = -4
    ; Load primary number
    pop r23
    pop r22
    pop r21
    pop r20
    pop r25
    push r25
    push r20
    push r21
    push r22
    push r23
    call mem_to_primary

    ; Load secondary number
    ldi r19, 0
    ldi r18, 2
    ldi r17, 0
    ldi r16, 0
    ori r24, 0b00000010

    ; Do Add
    call add_int_numbers

    ; print serial
    call send_sign_primary
    call send_full_byte_decimal_primary
    ldi r30, '|'
    call send_char_call_no_Correction
    
    ;----------------------------------------------
    
    ldi r30, 13
    call send_char_call_no_Correction
    call delay

    rjmp main
    
    

; delay -------------------------------------------------------------------------------
delay:
    ldi r29,0x5f
    keep_running01:
        ldi r31,0xff
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
    keep_running02:
        ldi r30,0xff
    keep_running03:
        dec r30
        breq delay_next_register01
        rjmp keep_running03
    delay_next_register01:
        dec r31
        breq delay_next_register02
        rjmp keep_running02
    delay_next_register02:
        dec r29
        breq delay_return
        rjmp keep_running01
    delay_return:
        ret

