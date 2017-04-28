;ASCII 2
;Shendo, May 2011
;
;r0 - Unused
;r1 - Unused
;r2 - Unused
;r3 - Unused
;r4 - Unused
;r5 - Unused
;r6 - Unused
;r7 - Unused
;r8 - Unused
;r9 - Unused
;ra - Scratchpad
;rb - Scratchpad
;rc - Scratchpad
;rd - Sprite memory location
;re - Sprite X coordinate
;rf - Sprite Y coordinate
;
;ASCII Index (0xFF is the string terminator):
;00 01 02 03 04 05 06 07 08 09 		HEX
;00 01 02 03 04 05 06 07 08 09		DEC
; 0  1  2  3  4  5  6  7  8  9		SPR
;
;0A 0B 0C 0D 0E 0F 10 11 12 13 14 15 16 17 18 19 1A 1B 1C 1D 1E 1F 20 21 22 23		HEX
;10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35		DEC
; A  B  C  D  E  F  G  H  I  J  K  L  M  N  O  P  Q  R  S  T  U  V  W  X  Y  Z		SPR
;
;24 25 26 27 28 29 2A 2B 2C 2D 2E 2F 30 31 32 33 34 35 36 37 38 39 3A 3B 3C 3D		HEX
;36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61		DEC
; a  b  c  d  e  f  g  h  i  j  k  l  m  n  o  p  q  r  s  t  u  v  w  x  y  z		SPR
;
;3E 3F 40 41 42 43 44 45 46 47		HEX
;62 63 64 65 66 67 68 69 70 71		DEC
;    !  -  /  ,  .  :  (  )  &		SPR

;GRAPHIC DATA
importbin numbers_font.bin 0 320 numbers_font			;Font data (numbers)
importbin capitals_font.bin 0 832 capitals_font			;Font data (capital letters)
importbin lowcase_font.bin 0 832 lowcase_font			;Font data (lowcase letters)
importbin special_font.bin 0 320 special_font			;Font data (special characters)


start:					;Start of the application
	cls				;Clear screen for fresh start

loop:					;The main game loop
	vblnk				;Wait for VBlank
	cls				;Clear screen

	ldi re, 10			;Load string X coordinate
	ldi rf, 10			;Load string Y coordinate
	ldi rd, string_data_0		;Load string memory location

	call draw_string		;Draw string on screen

	jmp loop			;Draw another frame

;SUBROUTINES

:draw_string				;Draw string on screen
	spr #0804			;Set 8x8 pixel sprites
	ldm ra, rd			;Load characted from memory
	andi ra, #FF			;Only the lo byte is needed

	mov rb, ra			;Copy data to scratchpad
	subi rb, 255			;Remove terminator
	jz fret			;Terminator reached, break subroutine

	mov rb, ra			;Copy data to scratchpad
	muli rb, 32			;Each character is 32 bytes long
	addi rb, numbers_font		;Apply offset to font address

	drw re, rf, rb			;Draw 8x8 character on the set coordinates

	addi rd, 1			;Increase memory offset
	addi re, 9			;Increase X coordinate

	jmp draw_string

:fret					;Subroutine return function
	ret				;Return from a subroutine

;STRING DATA

:string_data_0
	db 17				;H
	db 14				;E
	db 21				;L
	db 21				;L
	db 24				;O
	db 62				;
	db 32				;W
	db 24				;O
	db 27				;R
	db 21				;L
	db 13				;D
	db 63				;!
	db 255				;/0

:string_data_1
	db 12				;C
	db 43				;h
	db 44				;i
	db 51				;p
	db 01				;1
	db 06				;6
	db 62				;
	db 255				;/0
