org $ff01

;;issue 78
;;print usr 65285

;If you are writing a program that might eventually run on
;an older Spectrum (up to and including the +2), you should not load I
;with values between 40h and 7Fh (even if you never use IM 2). Values
;between C0h and FFh for I should also be avoided if contended memory
;(i.e. RAM 4 to 7) is to be paged in between C000h and FFFFh. This is due
;to an interaction between the video controller and the Z80 refresh
;mechanism, and can cause otherwise inexplicable crashes, screen
;corruption or other undesirable effects. This, you should only vector
;IM 2 interrupts to between 8000h and BFFFh


HOURS:
	defb 0
MINUTES:
	defb 0
SECONDS:
	defb 0
FIFTIES:
	defb 0		;interrupt counter
	
clock_on:		;on entry point
	jr INT_ON	


clock_off:		;off entry point
	di			;disable maskable interrupts
	ld A, $3f	;cannnot load i register directly, load thru A
	ld I, A		;make the i register $3f = 63
	im 1		;mode 1 interrupts
	ei			;enable interrupts and return back to BASIC
ret

INT_ON:
	di			;disable interrupts
	ld A, $fe;<--
	;Set the interrupt vector register to the high byte of the vector table at $fe00   example i = #FE and set Mode 2 interrupts
		
	ld I, A
	im 2
	;
	ld HL, $fe00;<--	;fe00	65024
	;now set up the table of vectors
	
INT10:
	ld (HL), $fd;<--
	;store $FD in 257 locations
	
	inc L
	jr nz, INT10
	inc H
	ld (HL), $fd;<--
	;the last $FD goes in $FF00
	
	ld A, $c3		;now poke a jump instruction into location $FDFD with the address for the jump as INT_ROUTINE
	
	ld ($fdfd), A;<--
	ld HL, INT_ROUTINE
	ld ($fdfe), HL;<--
	
	ld HL, FIFTIES	; set up the 50's counter
	ld (HL), 50		; to equal 50
	ei				;turn on the interrupts and the clock should be on
ret

INT_ROUTINE:	;50 times a second the Z80 will jump here
	rst $38		;first call the keyboard routine
	push AF		; save all the main registers
	push BC
	push DE
	push HL
	call CLOCK	;call the main clock routine
	pop HL		; retrieve the register values
	pop DE
	pop BC
	pop AF
	ei			;ensure the the interrupts are enabled and return to the interrupted routine
ret

CLOCK:
	ld HL, $5818	;set the attributes over the clock
	ld DE, $5819	;digits to be bright red/white
	ld BC, 7
	ld (HL), $57	;;color of attribute
	ldir
	ld HL, FIFTIES	;decrease the HL counter
	dec (HL)
	
	jr nz, PRINT_TIME
	ld (HL), 50	
	ld A, 59
	;if not zero, just print the time restore the counter and go on to check the seconds counter
	
	dec HL
	inc (HL)
	cp (HL)
	;if the seconds are less than 60, then just print the time
	
	jr nc, PRINT_TIME
	ld (HL), 0
	;else zero the seconds counter and go on to check the minutes
	
	dec HL
	inc (HL)
	cp (HL)
	
	jr nc, PRINT_TIME
	;print time if <60 else zero the minutes and check the hours counter
	
	ld (HL), 0
	dec HL
	ld A, 23
	inc (HL)
	; compare the hours counter with the accumator for less than 24 hours
	
	cp (HL)
	jr nc, PRINT_TIME
	;print time if it is
	
	ld (HL), 0	;else reset the hours to 0

PRINT_TIME:
	ld DE, $4018	;DE is the screen print address
	ld A, (HOURS)	;A is the first pair of digits
	call PRINT_DEC	;print the hours
	ld A, $3a; = :	;print the colon
	call PRINT	
	ld A, (MINUTES)	;A is the minutes
	call PRINT_DEC	;print minutes
	ld A, $3a; = :	;print the colon
	call PRINT
	ld A, (SECONDS)	;lastly print the seconds by dropping into the decimal printer
	
PRINT_DEC:
	ld B, $2f		; B is equal to ASCII 0-1

PD10:
	inc B			
	; repeatedly subtract ten from the accumulator and count each subtraction in the B register
	sub 10
	jr nc, PD10
	add A, $3a		;restore the last subtraction to A
	push AF		;this value is unit in ASCII form
	ld A, B		; B = tens in ASCII form
	call PRINT	;print them
	pop AF		;now print the units
	
PRINT:
	ld L, A		;make HL = A
	ld H, 0
	add HL, HL	;multiply HL by 8
	add HL, HL
	add HL, HL
	ld A, H		;add in the ASCII character base
	add A, $3c	;address which = $3C00
	ld H, A
	ld B, 8		; B is a counter for 8 rows
	ld C, D		;preserve D in C

PR10:
	ld A, (HL)	; get each byte of character data
	ld (DE), A	;store it in the screen
	inc HL		;increment the character pointer
	inc D		;steps down the screen a pixel row
	djnz PR10	;loop back 8 times
	ld D, C		;restore the screen addres in DE
	inc E		;step on by one character
ret

