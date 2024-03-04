; serialPortProject
; Nathan Lord
; Last modified 12/6/23
; Function: Loop through A-Z and give ASCII values corresponding
;  Receive valid data in hex for values and loop will continue from there

#define __SFR_OFFSET 0
#include "avr/io.h"

; Define global fucntions for extern C
.global start
.global SerialLoop

; intialize the ports at start of program, only ran once
start:
  call initUART0
  call initUART1
  ret

; beginning of main loop
SerialLoop:
  ldi R23, 0x41 ; ASCII code for 'A', start of loop and reinitialization 
  ldi R25, 0x30 ; For ASCII value conversion
  ldi R26, 0x07 ; ; For ASCII value conversion

; main loop for going through A-Z
loopAgain:
  ; Output to backpack display and project
  mov R16, R23 ; load for character
  call putChar ; put to backpack
  call Delay01s
  call Delay01s
  call putProj ; put to project
  call Delay01s
  ldi R16, 0x3d ; load for = sign
  call putChar ; put to backpack
  call Delay01s
  ; Using bottom and top two load registers to convert to hex values, then output to the screen
  call BottomHalf 
  mov R16, R27
  call putChar ; put to backpack
  call TopHalf
  mov R16, R28
  call putChar ; put to backpack

  ; Check for received data on UART1, if there is data it is put in R16
  call getProj

  ; If bit is not set(no new data) go to noCodeReceived
  sbrs R17, RXC1
  jmp noCodeReceived

  ; Check to make sure it is between A-Z inclusive otherwise ignore and go to noCodeReceived
  cpi R16, 0x41 
  brlo noCodeReceived 
  cpi R16, 0x5B 
  brsh noCodeReceived 

  ; The new code is good and currently in R16, 
  ; move to R23 as R23 is where value is kept track for loop and incremented
  ; jump to loopAgain so the data can be ouput and check for new data
  mov R23, R16 ; set the new data to R23
  call lfcr
  rjmp loopAgain
  
; If there is no code received R23 is incremented and made sure it is not Z(5B),
; return to loopAgain to output next value
; If it is at the end it jumps to SerialLoop to reset R23 to A and starts over
noCodeReceived:
  call Delay1s
  call lfcr
  inc R23
  cpi R23, 0x5B ; compare to see if it should jump to SerialLoop once outputs `Z`
  brne loopAgain ; zero flag is a zero it will jump up
  call lfcr
  rjmp SerialLoop ; jump back to the beginning program
  
; The two inits are for the ports initialization with correct FCPU, baud, and bps
initUART0:
  FCPU = 16000000
  baud = 9600
  bps = (FCPU/16/baud)-1
  
  ; Turn TX/RX Serial Port 0
  ldi R16, (1<<RXEN0) | (1<<TXEN0)
  sts UCSR0B, R16

  ; Set baud rate
  ldi R16, bps&255 ; low 8 bits
  ldi R17, bps>>8 ; high 8 bits
  sts UBRR0L, R16
  sts UBRR0H, R17

  ldi R16, 0b00000110 ; 8 data bits, no parities, one stop bit
  sts UCSR0C, R16
  ret

initUART1:
  FCPU = 16000000
  baud = 1200 ; running at a slower bps than the Arduino
  bps = (FCPU/16/baud)-1

  ; Turn TX/RX Serial Port 0
  ldi R16, (1<<RXEN1) | (1<<TXEN1)
  sts UCSR1B, R16

  ; Set baud rate
  ldi R16, bps&255 ; low 8 bits
  ldi R17, bps>>8 ; high 8 bits
  sts UBRR1L, R16
  sts UBRR1H, R17

  ldi R16, 0b00000110 ; 8 data bits, no parities, one stop bit
  sts UCSR1C, R16
  ret

; For converting R23 into correct hex values
; Low nibble
BottomHalf:
  mov R24, R23
  swap R24
  andi R24, 0x0F
  add R24, R25
  cpi R24, 0x3A
  brcs NoAdd1
  add R24, R26
NoAdd1:
  mov R27, R24
  ret

; High nibble
TopHalf:
  mov R24, R23
  andi R24, 0x0F
  add R24, R25
  cpi R24, 0x3A
  brcs NoAdd2
  add R24, R26
NoAdd2:
  mov R28, R24
  ret

; Outputting character to backpack
putChar:
  lds R18, UCSR0A ; Load from Data Space

  ; Skip line if flag is 1, ready to receive
  sbrs R18, UDRE0 ; UART data register empty bit flag,
  jmp putChar ; 
  sts UDR0, R16
  ret

; Outputting hex values to the TR1863 so it gets displayed to the project
putProj:
  lds R19, UCSR1A ; Load from Data Space

  ; Skip line if flag is 1, ready to receive
  sbrs R19, UDRE1 ; UART data register empty bit flag,
  jmp putProj

  ; Proceed to send the character
  sts UDR1, R16 ; Load the character into the UART1 data register
  ret

; Checks if there is data, if there is data it is loaded into R16
getProj:
  lds R17, UCSR1A ; Load from Data Space
  ; Skip line if flag is 1, indicating data is ready to be read
  sbrs R17, RXC1 ; UART receive complete bit flag
  ret 
  ; Load the received character from the UART1 data register to R16
  lds R16, UDR1 
  ret

; Three delay functions for 1, .25, .1 seconds
; Set to delay for 1 second using three nested loops
Delay1s:
  ldi R18, 82
  ldi R19, 43
  ldi R20, 254
  jmp L1

; Delay for .25s
Delay025s:
  ldi R18, 21
  ldi R19, 75
  ldi R20, 188
  jmp L1

; Delay for .1s
Delay01s:
  ldi R18, 9
  ldi R19, 30
  ldi R20, 226
  jmp L1

L1:
  dec R20
  brne L1
  dec R19
  brne L1
  dec R18
  brne L1
  ret

; Line carriage return
lfcr:
  ldi R16, 0x0D ; carriage return
  call putChar
  ldi R16, 0x0A ; line feed
  call putChar
  ret
