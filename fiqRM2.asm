; ------------------------------------------------------------------
; routine VBL simple
; code principal de l'interruption FIQ
;
; calé entre 0x18 et 0x58
;
; ------------------------------------------------------------------


	.org	0x18

FIQ_startofcode:
; IRQ arriven 0x18, on force le mode FIRQ pour récuperer les registres donc tout tourne en mode FIRQ
			TEQP      PC,#0x0C000001					; 1 18: %11<<26 OR %01			  ; keep IRQs and FIQs off, change to FIQ mode : irq et fiq OFF (status register dans le PC) + FIQ mode activé
			MOV       R0,R0               				; 2 1C: nop to sync FIQ registers

; FIQ registers
;
;R8 = tmp
;R9 = tmp
;R10 = tmp ( obligatoire pour routine keyboard )
;R11 = 
;R12 = 
;R13 = 
;R14 = 0x3200000	- utilisation permanente

			LDRB      R8,[R14,#0x14+0]       	; 3 24 IOC : load irq_A triggers ***BUG to v0.13*** v0.14 read &14+0 was reading status at &10, which ignores IRQ mask!!!
			TST       R8,#0b01000000        	; 4 28 bit 3 = Vsync, bit 6 = T1 trigger (HSync)			
; on saute en VSYNC
			LDREQ     PC,FIQ_notHSync			; 5 2C			; FIQ_notHSync 	    ; 5 28 *v0.14 if not T1, then go to VSync/Keyboard code*
			STRB      R8,[R14,#0x14+2]       	; 6 30  IOC :  (v0.14 moved past branch) clear all interrupt triggers

; FIQ_exitcode:
fin_hsync:
			TEQP      PC,#0x0C000002			; 7 80 %000011<<26 OR %10 ;27 80 back to IRQ mode, maintain 'GT', Z clear
			MOV       R0,R0                 	; 8 84 sync IRQ registers
			SUBS      PC,R14,#4             	; 9 88 return to foreground


			nop									; 10
			nop									; 11
			nop
			nop
			nop
			nop									; 15
			nop
			nop
			nop
			nop
			nop									; 20
			nop
			nop
			nop
			nop
			nop									; 25
			nop



			nop									; 27
			nop									; 28
			nop									; 29
			nop									; 30
			nop									; 31
			nop									; 32
			nop								;33 98
			nop								;34 9C
			nop								;35 A0
			nop								;36 A4
			nop								;37 A8
			nop								;38 AC
			nop								;39 B0


.long      0                      ;40 &B4 n/r
.long      0                      ;41 &B8 n/r
.long      0                      ;42 &BC n/r

FIQ_notHSync:                    ;*NEED TO ADJUST REF. IN swi_install IF THIS MOVES FROM &C0*
.long      0x1234                      ;43 &C0 pointer to notHSync ***quad aligned***

.long      0x3620000              ;44 &C4 n/r
.long      0x3640000              ;45 &C8 n/r
.long      0                      ;46 &CC n/r


FIQ_tempstack:
.long      0x1234                 ;47 &D0 R4 ***quad aligned***
.long      0                      ;48 &D4 R5
.long      0                      ;49 &D8 R6
.long      0                      ;50 &DC R7
.long      0                      ;51 &E0 n/r
position_ligne_hsync:
.long      0                      ;52 &E4 n/r
.long      0                      ;53 &E8 n/r
.long      0                      ;54 &EC n/r
.long      0                      ;55 &F0 n/r
.long      0                      ;56 &F4 n/r
.long      0                      ;57 &F8 n/r

.byte      "rSTm"                 ;58 &FC

FIQ_endofcode:

; ----------- fin du .org