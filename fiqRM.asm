; ------------------------------------------------------------------
;
; code principal de l'interruption FIQ
;
; calé entre 0x18 et 0x58
;
; ------------------------------------------------------------------

; valeurs fixes RMA
.equ	vsyncreturn,	7142						; 7142 vsyncreturn=7168+16-1-48   +   vsyncreturn+=7
.equ	vsyncreturn_low,		(vsyncreturn & 0x00FF)>>0
.equ	vsyncreturn_high,		((vsyncreturn & 0xFF00)>>8)

.equ	vsyncreturn_ligne199,			7142+(197*128)+127-64-48						; vsyncreturn=7168+16-1-48   +   vsyncreturn+=7
.equ	vsyncreturn_low_ligne199,		(vsyncreturn_ligne199 & 0x00FF)>>0
.equ	vsyncreturn_high_ligne199,		((vsyncreturn_ligne199 & 0xFF00)>>8)

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
;R12 = destination couleur 0 = 0x3400000 
;R13 = table_couleur0_vstart_vend : table source : couleur 0, vstart, vend, pour chaque ligne
;R14 = 0x3200000	- utilisation permanente

			LDRB      R8,[R14,#0x14+0]       	; 4 24 IOC : load irq_A triggers ***BUG to v0.13*** v0.14 read &14+0 was reading status at &10, which ignores IRQ mask!!!
			TST       R8,#0b01000000        	; 5 28 bit 3 = Vsync, bit 6 = T1 trigger (HSync)			
; on saute en VSYNC
			LDREQ     PC,FIQ_notHSync			; 6 2C			; FIQ_notHSync 	    ; 5 28 *v0.14 if not T1, then go to VSync/Keyboard code*
			STRB      R8,[R14,#0x14+2]       	; 7 30  IOC :  (v0.14 moved past branch) clear all interrupt triggers

; les modifs MEMC et VIDC vont ici	
			ldr		R8,[R13],#4					; 8  34   couleur 0
; R12 = destination couleur 0 = 0x3400000 
			str		R8,[R12]					; 9  38   met la couleur 0

			ldmia	R13!,{r8-r9}				; 10 3C
; modif de vstart
			str		R8,[R8]			; vstart	; 11 44
; modif de vend
			str		R9,[R9]			; vend		; 13 48
			STRB      R14,[R14,#0x28+2]       	;14 40 *v0.14* set IRQB mask to %00000000 = no STx, SRx IRQs now
			ldr		  R8,position_ligne_hsync 	;15 44  nb lignes restantes avant fin d ecran
			SUBS      R8,R8,#1				  	;18 50  -1
			str		  R8,position_ligne_hsync	;19 54  
; si nb_ligne > 0				
			BGT		  fin_hsync					;20 58
; nb lignes restantes = 0 , relancer vsyncreturn
; only get here (EQ) if at last line on screen

			MOV       R8,#0b00001000 	        ;16 5C
			STRB      R8,[R14,#0x18+2]           ;17 60    set IRQA mask to %00001000 = VSync only n/r unless likely to do <256?

			MOV       R8,#vsyncreturn_low_ligne199		;18 64 (vsyncreturn AND &00FF)>>0		;32 94   or ldr r8,vsyncvalue
			STRB      R8,[R14,#0x50+2]           ;19 68 T1 low byte, +2 for write
			MOV       R8,#vsyncreturn_high_ligne199		;20 6C				; (vsyncreturn AND &FF00)>>8;34 9C   or mov r8,r8,lsr#8
			STRB      R8,[R14,#0x54+2]           ;21 70 T1 high byte, +2 for write
			STRB      R8,[R14,#0x58+2]           ;22 74 T1_go = reset T1

; FIQ_exitcode:
fin_hsync:
			TEQP      PC,#0x0C000002			;25 80 %000011<<26 OR %10 ;27 80 back to IRQ mode, maintain 'GT', Z clear
			MOV       R0,R0                 	;26 84 sync IRQ registers
			SUBS      PC,R14,#4             	;27 88 return to foreground

			nop									; 12		
			nop									; 3 20			
			nop									;23 78
			nop									;24 7C		
			nop									; 16
			nop									; 17
			nop								;33 98
			nop								;34 9C
			nop								;35 A0
			nop								;36 A4
			nop								;37 A8
			nop								;38 AC
			nop								;39 B0

			;LDRB      R8,[R14,#0x14+0]     ; 3 20 load irq_A triggers ***BUG to v0.13*** v0.14 read &14+0 was reading status at &10, which ignores IRQ mask!!!
			;TST       R8,#0b01000000       ; 4 24 bit 3 = Vsync, bit 6 = T1 trigger (HSync)
			;LDREQ     PC,FIQ_notHSync		; 5 28			; FIQ_notHSync 	    ; 5 28 *v0.14 if not T1, then go to VSync/Keyboard code*

			;STRB      R8,[R14,#0x14+2]     ; 6 2C (v0.14 moved past branch) clear all interrupt triggers


; sauvegarde R4-R7
;			MOV       R14,#FIQ_tempstack  ; 7 30
;			STMIA     R14,{R4-R7}         ; 8 34


;			MOV       R8,#0x3400000        ; 9 38
;			LDMIA     R9!,{R4-R7}         ;10 3C load 4 VIDC parameters
;			STMIA     R8,{R4-R7}          ;11 40 store 4
;			LDMIA     R10!,{R4-R7}        ;12 44
;			STMIA     R8,{R4-R7}          ;13 48 ...8
;			LDMIA     R11!,{R4-R7}        ;14 4C
;			STMIA     R8,{R4-R7}          ;15 50 ...12
;			LDMIA     R11!,{R4-R7}        ;16 54
;			STMIA     R8,{R4-R7}          ;17 58 ...16

;			LDMIA     R12!,{R4-R5}        ;18 5C load 2 MEMC paramters
;			CMP       R4,#0x3600000        ;19 60
;			STRGE     R4,[R4]             ;20 64 it's a MEMC reg, so write
;			CMP       R5,#0x3600000        ;21 68
;			STRGE     R5,[R5]             ;22 6C it's a MEMC reg, so write

; restaure R4-R7
;			LDMIA     R14,{R4-R7}         ;23 70
		
;			MOV       R14,#0x3200000       ;24 74 reset R14 to IOC address
;			STRB      R14,[R14,#0x28+2]    ;25 78 *v0.14* set IRQB mask to %00000000 = no STx, SRx IRQs now
			
;*************************************************************************

;			SUBS      R13,R13,#1             ;26 7C
;			TEQGTP    PC,#0x0C000002		 ;27 80 : %000011<<26 OR %10 ;27 80 back to IRQ mode, maintain 'GT', Z clear
;			MOV       R0,R0                  ;28 84 sync IRQ registers
;			SUBGTS    PC,R14,#4              ;29 88 return to foreground

; only get here (EQ) if at last line on screen

;			MOV       R8,#0b00001000       ;30 8C
;			STRB      R8,[R14,#0x18+2]     ;31 90 set IRQA mask to %00001000 = VSync only n/r unless likely to do <256?
;
;			MOV       R8,#vsyncreturn_low		; (vsyncreturn AND &00FF)>>0		;32 94   or ldr r8,vsyncvalue
;			STRB      R8,[R14,#0x50+2]               ;33 98 T1 low byte, +2 for write
;			MOV       R8,#vsyncreturn_high						; (vsyncreturn AND &FF00)>>8;34 9C   or mov r8,r8,lsr#8
;			STRB      R8,[R14,#0x54+2]               ;35 A0 T1 high byte, +2 for write
;			STRB      R8,[R14,#0x58+2]               ;36 A4 T1_go = reset T1

;FIQ_exitcode:
;			TEQP      PC,#0x0C000002		 ; %000011<<26 OR %10 ;37 A8 back to IRQ mode
;			MOV       R0,R0                  ;38 AC sync IRQ registers
;			SUBS      PC,R14,#4              ;39 90 return to foreground

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