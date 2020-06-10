;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;										 ;;;	
;;;			Name: Justin Igmen			 ;;;
;;;			SID: 200364880				 ;;;
;;;			Class: ENSE 352				 ;;;
;;;			Project: Whack-a-mole		 ;;;
;;;										 ;;;	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; Directives
            PRESERVE8
            THUMB       

        		 
;;; Equates

INITIAL_MSP	EQU		0x20001000	; Initial Main Stack Pointer Value


;PORT A GPIO - Base Addr: 0x40010800
GPIOA_CRL	EQU		0x40010800	; (0x00) Port Configuration Register for Px7 -> Px0
GPIOA_CRH	EQU		0x40010804	; (0x04) Port Configuration Register for Px15 -> Px8
GPIOA_IDR	EQU		0x40010808	; (0x08) Port Input Data Register
GPIOA_ODR	EQU		0x4001080C	; (0x0C) Port Output Data Register
GPIOA_BSRR	EQU		0x40010810	; (0x10) Port Bit Set/Reset Register
GPIOA_BRR	EQU		0x40010814	; (0x14) Port Bit Reset Register
GPIOA_LCKR	EQU		0x40010818	; (0x18) Port Configuration Lock Register

;PORT B GPIO - Base Addr: 0x40010C00
GPIOB_CRL	EQU		0x40010C00	; (0x00) Port Configuration Register for Px7 -> Px0
GPIOB_CRH	EQU		0x40010C04	; (0x04) Port Configuration Register for Px15 -> Px8
GPIOB_IDR	EQU		0x40010C08	; (0x08) Port Input Data Register
GPIOB_ODR	EQU		0x40010C0C	; (0x0C) Port Output Data Register
GPIOB_BSRR	EQU		0x40010C10	; (0x10) Port Bit Set/Reset Register
GPIOB_BRR	EQU		0x40010C14	; (0x14) Port Bit Reset Register
GPIOB_LCKR	EQU		0x40010C18	; (0x18) Port Configuration Lock Register

;The onboard LEDS are on port C bits 8 and 9
;PORT C GPIO - Base Addr: 0x40011000
GPIOC_CRL	EQU		0x40011000	; (0x00) Port Configuration Register for Px7 -> Px0
GPIOC_CRH	EQU		0x40011004	; (0x04) Port Configuration Register for Px15 -> Px8
GPIOC_IDR	EQU		0x40011008	; (0x08) Port Input Data Register
GPIOC_ODR	EQU		0x4001100C	; (0x0C) Port Output Data Register
GPIOC_BSRR	EQU		0x40011010	; (0x10) Port Bit Set/Reset Register
GPIOC_BRR	EQU		0x40011014	; (0x14) Port Bit Reset Register
GPIOC_LCKR	EQU		0x40011018	; (0x18) Port Configuration Lock Register

;Registers for configuring and enabling the clocks
;RCC Registers - Base Addr: 0x40021000
RCC_CR		EQU		0x40021000	; Clock Control Register
RCC_CFGR	EQU		0x40021004	; Clock Configuration Register
RCC_CIR		EQU		0x40021008	; Clock Interrupt Register
RCC_APB2RSTR	EQU	0x4002100C	; APB2 Peripheral Reset Register
RCC_APB1RSTR	EQU	0x40021010	; APB1 Peripheral Reset Register
RCC_AHBENR	EQU		0x40021014	; AHB Peripheral Clock Enable Register

RCC_APB2ENR	EQU		0x40021018	; APB2 Peripheral Clock Enable Register  -- Used

RCC_APB1ENR	EQU		0x4002101C	; APB1 Peripheral Clock Enable Register
RCC_BDCR	EQU		0x40021020	; Backup Domain Control Register
RCC_CSR		EQU		0x40021024	; Control/Status Register
RCC_CFGR2	EQU		0x4002102C	; Clock Configuration Register 2

; Times for delay routines

;1600000 = (200 ms/24MHz PLL)
        
DELAYTIME		EQU		100000		;delay time for the waiting loop
PrelimWait 		EQU 	800000		;preliminary wait
ReactTime		EQU 	64000000	;configures reaction time
WinLoseDelay 	EQU		100000		;delay time for the win/lose loop
TimeToGoBack	EQU		2400000		;delay time between win/loop loop and waiting loop
NumCycles		EQU 	16			;configures number of cycles/levels
A 				EQU 	12345		;constant for the randomizer
C 				EQU 	67890		;constant for the randomizer
	


; Vector Table Mapped to Address 0 at Reset
            AREA    RESET, Data, READONLY
            EXPORT  __Vectors

__Vectors	DCD		INITIAL_MSP			; stack pointer value when stack is empty
        	DCD		Reset_Handler		; reset vector
			
            AREA    MYCODE, CODE, READONLY
			EXPORT	Reset_Handler
			ENTRY

Reset_Handler		PROC

		BL GPIO_ClockInit
		BL GPIO_init
	
mainLoop
		bl waiting 			;UC2 Waiting for Player
		bl normalGameplay	;Normal Game Play
		
		cmp r0, #1			;value from normalGameplay
		beq win_main
		cmp r0, #0
		beq lose_main

win_main
		bl win_mode
		B	mainLoop
lose_main	
		bl lose_mode
		B	mainLoop
		ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;Subroutines ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
;Initializes the clock
;Turns on ports A and C
	ALIGN
GPIO_ClockInit PROC

	ldr r1, =RCC_APB2ENR
	ldr r0, [r1]
	orr r0, #0x1C
	str r0, [r1]	
	
	BX LR
	ENDP
		
	
	
;Initializes I/O
;Output: 50MHz, general purpose push-pull
;Input
	ALIGN
GPIO_init  PROC
	
	; ENEL 384 board LEDs: D1 - PA9, D2 - PA10, D3 - PA11, D4 - PA12

	ldr r1, =GPIOA_CRH
	ldr r0, [r1]
	mov32 r0, #0x44433334
	str r0, [r1]

    BX LR
	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;	Subroutine: waiting
;;;	
;;;	UC2 - Waiting for Player
;;;	This function displays an LED pattern that will keep looping
;;;		until the user presses any of the four buttons
;;;	
;;;	Promise: Returns R0 which is the seed for the randomizer
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

waiting	proc
	
	add r10, #1	;counter for random
	
	ldr r1, =GPIOA_ODR	
	ldr r2, =DELAYTIME
	
	ldr r5, =GPIOB_IDR	;Red and Black PB
	ldr r6, =GPIOC_IDR	;Blue PB
	ldr r7, =GPIOA_IDR	;Green PB
	
loop
	mov r3, r2	;sets r3 as temp register for DELAYTIME
	add r10, #1	;counter for random
led_1
	add r10, #1	;counter for random
	
	ldr r8, [r5]	;gets the input from port B
	and r8, #0x300	;masks 0x300 to get just values from pin 8 and 9
	ldr r9, [r6]	;gets the input from port C
	and r9, #0x1000	;masks 0x1000 to get just values from pin 12
	adds r8, r9		;combines the outputs from r8 and r9
	ldr r9, [r7]	;gets the input from port A
	and r9, #0x20	;masks 0x20 to get just values from pin 7
	adds r0, r8, r9	;combines all the outputs together
	cmp r0, #0x1320	;checks if any button is pressed
	BNE button_pushed
;;;;;;
	mov r0, #0x1C00	;sets up light to turn on
	str r0, [r1]	;turns on the light
	subs r3, #1		;decrements the delay
	cmp r3, #0		;if zero, move on to next LED
	BNE led_1	
	mov r3, r2		;reset delay
led_2

	add r10, #1	;counter for random
	
	ldr r8, [r5]	;gets the input from port B
	and r8, #0x300	;masks 0x300 to get just values from pin 8 and 9
	ldr r9, [r6]	;gets the input from port C
	and r9, #0x1000	;masks 0x1000 to get just values from pin 12
	adds r8, r9		;combines the outputs from r8 and r9
	ldr r9, [r7]	;gets the input from port A
	and r9, #0x20	;masks 0x20 to get just values from pin 7
	adds r0, r8, r9	;combines all the outputs together
	cmp r0, #0x1320	;checks if any button is pressed
	BNE button_pushed
;;;;;;

	mov r0, #0x1A00	;sets up light to turn on
	str r0, [r1]	;turns on the light
	subs r3, #1		;decrements the delay
	cmp r3, #0		;if zero, move on to next LED
	BNE led_2
	mov r3, r2		;reset delay
led_3
	add r10, #1	;counter for random

	ldr r8, [r5]	;gets the input from port B
	and r8, #0x300	;masks 0x300 to get just values from pin 8 and 9
	ldr r9, [r6]	;gets the input from port C
	and r9, #0x1000	;masks 0x1000 to get just values from pin 12
	adds r8, r9		;combines the outputs from r8 and r9
	ldr r9, [r7]	;gets the input from port A
	and r9, #0x20	;masks 0x20 to get just values from pin 7
	adds r0, r8, r9	;combines all the outputs together
	cmp r0, #0x1320	;checks if any button is pressed
	BNE button_pushed
;;;;;;

	mov r0, #0x1600	;sets up light to turn on
	str r0, [r1]	;turns on the light
	subs r3, #1		;decrements the delay
	cmp r3, #0		;if zero, move on to next LED
	BNE led_3
	mov r3, r2		;reset delay
led_4

	add r10, #1	;counter for random
	
	ldr r8, [r5]	;gets the input from port B
	and r8, #0x300	;masks 0x300 to get just values from pin 8 and 9
	ldr r9, [r6]	;gets the input from port C
	and r9, #0x1000	;masks 0x1000 to get just values from pin 12
	adds r8, r9		;combines the outputs from r8 and r9
	ldr r9, [r7]	;gets the input from port A
	and r9, #0x20	;masks 0x20 to get just values from pin 7
	adds r0, r8, r9	;combines all the outputs together
	cmp r0, #0x1320	;checks if any button is pressed
	BNE button_pushed
;;;;;;

	mov r0, #0x0E00	;sets up light to turn on
	str r0, [r1]	;turns on the light
	subs r3, #1		;decrements the delay
	cmp r3, #0		;if zero, move on to next LED
	BNE led_4
	
	mov r3, r2		;reset delay
	;mov r4, #1
	
	B loop

button_pushed
	mov r0, r10			;sets up r0 as the output for this fucntion	
	mov r12, #0xFFFF	
	str r12, [r1]		;turn the LEDs off
	bx lr
	endp
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;	Subroutine: normalGameplay
;;;	
;;;	UC3 - Normal Game Play
;;;	This function will is the meat of this project.
;;;	Sets up reaction time
;;;	Does a preliminary delay before displaying a random LED
;;; Calls LED_picker function to pick with LED to display
;;;	Calls level_select function to determine the current level
;;;	Calls get_input to get the user input
;;; Will loop until user wins or loses
;;;	
;;;	Promise: Returns R0 which determines whether the user wins or loses
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
normalGameplay proc
	
	ldr r10, =ReactTime	;sets up register for reaction time
	mov r4, #0			;resets r4 to use for the level selection
	push {r4}			;pushes r4 in to the stack
	
game_mode	
	pop{r4}				;gets current level from the stack
	adds r4, #1			;increments level
	ldr r1, =PrelimWait	;sets up register for preliminary wait
		
PrelimWait_label		;loops until counter for Preliminary wait reaches zero
	ldr r3, =GPIOA_ODR
	
	mov r2, #0xFFFF		;turns off LEDs
	str r2, [r3] 

	subs r1, #1			;decrement for timer
	cmp r1, #0
	bne PrelimWait_label
	
	push{lr}			;pushes lr to stack to save it
	bl LED_picker		;function call = a pseudo-random LED turns on == register: r11
	pop{lr}				;gets lr to mainfunction back
	
	push{lr}			;pushes lr to stack to save it
	bl level_select		;function call = reaction time for the current level is returned
	pop{lr}				;gets lr to mainfunction back
	
	cmp r4, #100		;if the user reaches last value, user wins!
	beq win

keep_timing
	push {lr}			;pushes lr to stack to save it
	bl get_input		;function call = gets the input from user == register: r12
	pop {lr}			;gets lr to mainfunction back
		
	cmp r12, #0			;if the user did not pick an input during the current cycle, decrement the time
	beq time_some_more
	
	cmp r12, r11		;checks if the led and user input matches, if they do, move on. Otherwise, user loses
	bne lose
	
	mov r0, r10			;sets up r0 as temp register for the current reaction time
	b game_mode
	
time_some_more
	subs r10, #1		;decremtns time until 0
	cmp r10, #0
	beq lose			;user lost by running out of time
	b keep_timing	

win
	mov r0, #1			;if user wins, return 1
	bx lr

lose
	mov r0, #0			;if user loses, return 0, and current level
	pop {r1}
	bx lr	
	
	endp
				
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;	Subroutine: win_mode
;;;	
;;;	UC4 - End Success
;;;	Displays the winning signal
;;; Two pairs of LEDs turning on in a pattern
;;;	Will stay here in until timer runs out
;;; Will go back to UC2
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

win_mode proc
	ldr r3, =WinLoseDelay
	
	mov r0, #0x1400			;first LED pair
	mov r1, #0x0A00			;second LED pair
	ldr r2, =GPIOA_ODR
	ldr r5, =TimeToGoBack
	
winLoop_1
	str r0, [r2]	;turns on first pair
	adds r4, #1		;increments delay when the pair is on
	
	subs r5, #1		;decrements return to main timer
	cmp r5, #0
	beq win_done	;returns to main of timer is done
	
	cmp r4, r3		;checks if the timer for the LED pair is done, if so, move on to the next pair
	beq winLoop_2
	b winLoop_1
winLoop_2
	str r1, [r2]	;turns on second pair
	subs r4, #1		;decrements delay when the pair is on
	
	subs r5, #1		;decrements return to main timer
	cmp r5, #0
	beq win_done	;returns to main of timer is done
	
	cmp r4, #0		;checks if the timer for the LED pair is done, if so, move on to the next pair
	beq winLoop_1
	b winLoop_2
	
win_done
	bx lr
	
	endp
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;	Subroutine: lose_mode
;;;	
;;;	UC4 - End Failure
;;;	Displays binary value of the current level
;;; Will blink until timer runs out
;;; Will go back to UC2
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

lose_mode proc
	ldr r2, =GPIOA_ODR
	ldr r3, =TimeToGoBack
	ldr r4, =WinLoseDelay
	mov r5, #0
	
loseLoop_1			;determines which level the user lost
	 
	mvn r0, r1		;takes 1's complement of r1 since LEDs are active LOW
	and r6, r0, #1	;take bit 0
	and r7, r0, #2	;take bit 1
	and r8, r0, #4	;take bit 2
	and r9, r0, #8	;take bit 3
	
	lsl r6, #12		;shift to correct position -- bit 12
	lsl r7, #10		;shift to correct position -- bit 11
	lsl r8, #8		;shift to correct position -- bit 10
	lsl r9, #6		;shift to correct position -- bit 09
	
	orr r0, r6, r7	;combine all of them before storing
	orr r0, r8
	orr r0, r9
	
lose_display
	str r0, [r2]	;displays LED based on the current level
	adds r5, #1		;increments until it is equal to the delay. It will move on to the next pattern
	
	subs r3, #1		;decrements timer to go back to main
	cmp r3, #0
	beq lose_done
	
	cmp r5, r4		
	beq loseLoop_2
	b loseLoop_1
	
loseLoop_2
	mov r0, #0xFFFF	
	str r0, [r2]	;turns the LEDs off
	subs r5, #1		;decrements until it is equal to 0. It will move on to the next pattern
	
	subs r3, #1		;decrements timer to go back to main
	cmp r3, #0
	beq lose_done
	
	cmp r5, #0
	beq loseLoop_1
	b loseLoop_2
	
	
lose_done	
	bx lr
	endp
				
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;	Subroutine: LED_picker
;;;	
;;;	Turns on a pseudo-random LED based on the user's reaction time.
;;;	Uses this formula: X = Ay+C where y is the timer, A and C are contants
;;; Returns R11
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LED_picker proc
	ldr r5, =GPIOA_ODR
	
	ldr r2, =A
	ldr r3, =C
	mul r0, r2	;A*Y
	add r0, r3	;(A*Y) + C
	and r0, #3	;Masks to get the last two bits for which LED
	
	adds r0, #1	;increment bit by 1 so it's easier for me to understand
	
	;next code block determines which LED to turn on
	cmp r0, #1
	BEQ led1
	cmp r0, #2
	BEQ led2
	cmp r0, #3
	BEQ led3
	cmp r0, #4
	BEQ led4
	
led1
	mov r11, #1
	mov r0, #0x1C00
	b displayLight
led2
	mov r11, #2
	mov r0, #0x1A00
	b displayLight
led3
	mov r11, #3
	mov r0, #0x1600
	b displayLight
led4
	mov r11, #4
	mov r0, #0x0E00
	b displayLight	
	
displayLight
	str r0, [r5]	;displays the LED
	bx lr
	endp
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;	Subroutine: get_input
;;;	
;;;	Gets the value of the button the user picked
;;;	Returns R12 for comparing
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
get_input proc
	ldr r4, =GPIOB_IDR	;Red and Black PB
	ldr r5, =GPIOC_IDR	;Blue PB
	ldr r6, =GPIOA_IDR	;Green PB
	
	ldr r7, [r4]
	ldr r8, [r4]
	ldr r9, [r5]
	ldr r3, [r6]
	
	;next codeblock determines the button pressed by masking
	and r7, #0x100
	cmp r7, #0x100
	bne red_button
	
	and r8, #0x200
	cmp r8, #0x200
	bne black_button
	
	and r9, #0x1000
	cmp r9, #0x1000
	bne blue_button
	
	and r3, #0x20
	cmp r3, #0x20
	bne green_button
	
	mov r12, #0
	bx lr
	
	;next codeblock returns a vlue based on the button pressed
red_button
	mov r12, #1
	bx lr
black_button
	mov r12, #2
	bx lr
blue_button
	mov r12, #3
	bx lr
green_button
	mov r12, #4
	bx lr
	endp
		

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;	Subroutine: level_select
;;;	
;;;	Updates the current reaction time based on the level
;;;	Returns reaction time
;;; Divides the current reaction on the level
;;;	eg) level 2: ==== reactiontime/2
;;;	Also checks if level matches NumCycles, if it does, goes in to win mode
;;;	Works only up eight levels
;;;	Values above 8 is defaulted to level 8
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

level_select proc
	ldr r0, =ReactTime
	ldr r5, =NumCycles
	
	cmp r5, #0
	beq choose_a_level
	
	add r5, #1	;adds 1 to desired level
	
	cmp r4, r5	;checks if current level matches numCycles
	beq	game_win
	
choose_a_level
	;comparisons based on the level
	cmp r4, #1
	beq level_1
	
	cmp r4, #2
	beq level_2
	
	cmp r4, #3
	beq level_3
	
	cmp r4, #4
	beq level_4
		
	cmp r4, #5
	beq level_5
	
	cmp r4, #6
	beq level_6
	
	cmp r4, #7
	beq level_7
	
	cmp r4, #8
	beq level_8

	cmp r4, #9
	beq level_9
	
	cmp r4, #10
	beq level_10
	
	cmp r4, #11
	beq level_11
	
	cmp r4, #12
	beq level_12
		
	cmp r4, #13
	beq level_13
	
	cmp r4, #14
	beq level_14

	cmp r4, #15
	beq level_15

game_win
	mov r4, #100
	str r4, [sp, #4]	;r4 is stored in the stack -- offset is used so the the top of the stack is not chacnged (LR)
	bx lr
	
level_1
	sdiv r0, r4	; division
	mov r10, r0	; current reaction time is updated	==same concept for the rest of the block
	str r4, [sp, #4]	
	bx lr
	
level_2
	sdiv r0, r4
	mov r10, r0
	str r4, [sp, #4]
	bx lr	
	
level_3
	sdiv r0, r4
	mov r10, r0
	str r4, [sp, #4]
	bx lr
	
level_4
	sdiv r0, r4
	mov r10, r0
	str r4, [sp, #4]
	bx lr
	
level_5
	sdiv r0, r4
	mov r10, r0
	str r4, [sp, #4]
	bx lr
	
level_6
	sdiv r0, r4
	mov r10, r0
	str r4, [sp, #4]
	bx lr
	
level_7
	sdiv r0, r4
	mov r10, r0
	str r4, [sp, #4]
	bx lr
	
level_8
	sdiv r0, r4
	mov r10, r0
	str r4, [sp, #4]
	bx lr
	
level_9
	sdiv r0, r4
	mov r10, r0
	str r4, [sp, #4]
	bx lr
	
level_10
	sdiv r0, r4
	mov r10, r0
	str r4, [sp, #4]
	bx lr
	
level_11
	sdiv r0, r4
	mov r10, r0
	str r4, [sp, #4]
	bx lr
	
level_12
	sdiv r0, r4
	mov r10, r0
	str r4, [sp, #4]
	bx lr
	
level_13
	sdiv r0, r4
	mov r10, r0
	str r4, [sp, #4]
	bx lr
	
level_14
	sdiv r0, r4
	mov r10, r0
	str r4, [sp, #4]
	bx lr
	
level_15
	sdiv r0, r4
	mov r10, r0
	str r4, [sp, #4]
	bx lr

	endp
		
		
	align
	end