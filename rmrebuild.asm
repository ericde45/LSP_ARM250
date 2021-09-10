; OK : faire la table pour 2eme pointeur mémoire écran
; OK : swapper les pointeurs pendant la vbl
; OK : faire la table des 7 premieres lignes

; démontrer : 
; 	- vinit copié dans vstart : mettre vinit a 0, vstart à 50*104, vend à 199*104+100 : résultat ?
;			- il commence à vinit, et une fois arrivé à vend il recommence à vstart ( sans recopier vinit dans vstart )

;	- vstart modifiable après démarrage affichage : vinit à 0, vstart à 0, vend à 199*104+100, attendre affichage, pendant affichage : vstart à 50*104
;		résultat : vstart à 0 : OK , vinit modifié à la fin de la vbl, avant affichage => pas de modif de vinit pendant l'affichage - inutile.

;	- si vend < vptr ? => l'affichage continue jusqu'a la fin de la vbl  - FLBK
;		vptr a dépassé vend

; d'abord vstart, puis vend ? ou inverse ?
; ligne -1 : vstart = vstart ligne suivante, vend = vend ligne courante 199


; --------------> modification du vend prise en compte immédiatement !
; ----------------------------------------------------------------------


; corriger la position de la synchro, changements de couleur en plein milieu de l'écran visibles

; pour la table
; les 2 tiers du haut sur un cylindre : 133 lignes
; le tiers du bas sur un autre cylindre : 67 lignes
;
; sur les 50 dernieres lignes : 25 lignes et 25 lignes
; entre 0 et 179 degrés
; 180 degrés / 133 lignes : projetés sur 25 lignes , donc 25 résultats
; 0<angle<90, par pas de 90/25, sinus(angle) x 133
; sinus : de 0 a 1



;pour vsync et hsync

;R8 = tmp
;R9 = tmp
;R10 = tmp ( obligatoire pour routine keyboard )
;R11 = 
;R12 = destination couleur 0 = 0x3400000 
;R13 = table_couleur0_vstart_vend : table source : couleur 0, vstart, vend, pour chaque ligne
;R14 = 0x3200000	- utilisation permanente

; verifier hypothese que on peut avoir 2 vsync.
;	- vsync 1 :
;		- vsync 2 dans routine FIRQ
;		- vstart = 0 vend =50*416
;
;	- vsync 2 :
;		- vsync 1 dans routine FIRQ
;		- vstart = 0 vend = 50*416

; stratégie 1
;	- la routine vsync met vstart à 0 et vend à 200*416, puis desactive vsync
;	- la routine vsync lance un timer 1 de 199 lignes
;	- le timer 1 modifie vstart à 0 et vend à 416
;	- le timer 1 met le timer 1 à 1 ligne ( 127)
;	- sur 56 lignes, ensuite le timer 1 remet la vsync en activité


;
; template avec rasterman integré
;
; - Vsync
; 128-1 avant première ligne
; 128-1 par ligne * 256 lignes
; 7142 avant Vsync

; - 200 lignes : 200*128 - 1


.equ Screen_Mode, 97

; valeurs fixes RM / timers
.equ	ylines,			58
.equ	vsyncreturn,	7142						; vsyncreturn=7168+16-1-56   +   vsyncreturn+=7
.equ	vsyncreturn_low,		(vsyncreturn & 0x00FF)>>0
.equ	vsyncreturn_high,		((vsyncreturn & 0xFF00)>>8)

.equ	vsyncreturn_ligne199,			7142+(197*128)+127-64					; vsyncreturn=7168+16-1-48   +   vsyncreturn+=7
.equ	vsyncreturn_low_ligne199,		(vsyncreturn_ligne199 & 0x00FF)>>0
.equ	vsyncreturn_high_ligne199,		((vsyncreturn_ligne199 & 0xFF00)>>8)


.equ	hsyncline,		128-1			; 127
.equ	hsyncline_low,			((hsyncline & 0x00FF)>>0)
.equ	hsyncline_high,			((hsyncline & 0xFF00)>>8)

.equ	position_ligne_hsync,	 	0xE4
.equ	saveR14_firq,				0xE0

.include "swis.h.asm"
	.org 0x8000
	
main:


;"XOS_ServiceCall"

;OS_SWINumberFromString 
;	ldr		R1,pointeur_XOS_ServiceCall

;	SWI 0x39




	mov		R0,#11			; OS_Module 11 : Insert module from memory and move into RMA
	ldr		R1,pointeur_module97
	SWI		0x1E
	
	MOV r0,#22	;Set MODE
	SWI OS_WriteC
	MOV r0,#Screen_Mode
	SWI OS_WriteC


	MOV r0,#23	;Disable cursor
	SWI OS_WriteC
	MOV r0,#1
	SWI OS_WriteC
	MOV r0,#0
	SWI OS_WriteC
	SWI OS_WriteC
	SWI OS_WriteC
	SWI OS_WriteC
	SWI OS_WriteC
	SWI OS_WriteC
	SWI OS_WriteC
	SWI OS_WriteC


; Set screen size for number of buffers
	MOV r0, #DynArea_Screen
	SWI OS_ReadDynamicArea
	; r1=taille actuelle de la memoire ecran
	MOV r0, #DynArea_Screen
; 416 * ( 32+258+32+258+32)
	MOV r2, #416*612

	; 416*258 * 2 ecrans
	SUBS r1, r2, r1
	SWI OS_ChangeDynamicArea
	
; taille dynamic area screen = 416*258*2

	MOV r0, #DynArea_Screen
	SWI OS_ReadDynamicArea
	
	; r0 = pointeur memoire ecrans
	
	add		R0,R0,#416*32
	str		r0,screenaddr1
	add		r0,r0,#416*290
	str		r0,screenaddr2
	

	mov		R0,#416*32
	str		r0,screenaddr1_MEMC
	add		r0,r0,#416*290
	str		r0,screenaddr2_MEMC



	SWI		0x01
	.byte	"---+++++++++++++++++++L1",10,13,0
	.p2align 2
	.rept		10
	SWI		0x01
	.byte	"1234567890123456789123456789012345678912345L2",10,13,0
	.p2align 2
	.endr
	SWI		0x01
	.byte	"---+++++++++++++++++++L3",10,13,0
	.p2align 2
	SWI		0x01
	.byte	"---+++++++++++++++++++L4",10,13,0
	.p2align 2
	SWI		0x01
	.byte	"---+++++++++++++++++++L5",10,13,0
	.p2align 2

	
	ldr		r1,screenaddr1
	bl		dessine_sur_ecran
	
	ldr		r1,screenaddr2
	bl		dessine_sur_ecran
	


	SWI		22
	MOVNV R0,R0            

;-----------
;	.ifeq		0

; swap des pointeurs :
; swap pointeur ecrans
	ldr		r8,screenaddr1
	ldr		r9,screenaddr2
	str		r9,screenaddr1
	str		r8,screenaddr2

	ldr		r8,screenaddr1_MEMC
	ldr		r9,screenaddr2_MEMC
	str		r9,screenaddr1_MEMC
	str		r8,screenaddr2_MEMC

; swap pointeurs table reflet

	ldr		R8,pointeur_table_reflet_MEMC1
	ldr		R9,pointeur_table_reflet_MEMC2
	str		R9,pointeur_table_reflet_MEMC1
	str		R8,pointeur_table_reflet_MEMC2


	ldr		R8,vstart_MEMC1
	ldr		R9,vstart_MEMC2
	str		R9,vstart_MEMC1
	str		R8,vstart_MEMC2

	ldr		R8,vend_MEMC1
	ldr		R9,vend_MEMC2
	str		R9,vend_MEMC1
	str		R8,vend_MEMC2

;	.ENDIF
;-----------
; update pointeur video hardware vinit
	ldr	r0,screenaddr1_MEMC
	mov r0,r0,lsr #4
	mov r0,r0,lsl #2
	mov r1,#0x3600000
	add r0,r0,r1
	str r0,[r0]

	bl		RM_init

	bl		RM_start
	
	mov		R8,#0x1234
	
boucle:

	bl		RM_wait_VBL

;	mov		R0,#56
;	mov		R1,#67
;	.rept	500	
;	muls	R0,R1,R0
;	.endr
; ici il faut tester une touche



	bl      RM_scankeyboard
	cmp		R0,#0x5F
	bne		boucle

	

exit:
	;bl		RM_wait_VBL
	;bl      RM_scankeyboard
	str		R8,toucheclavier

	bl		RM_wait_VBL
;-----------------------
;sortie
;-----------------------

	bl	RM_release


	

	MOV r0,#22	;Set MODE
	SWI OS_WriteC
	MOV r0,#12
	SWI OS_WriteC

	
	
	MOV R0,#0
	SWI OS_Exit



dessine_sur_ecran:

	mov		R12,R1

	;add		R1,R1,#416*70

	add		R4,R1,#32
	add		R5,R4,#415-64
; au milieu
	add		R1,R1,#208
	mov		R2,R1

	ldr		r3,couleur
	add		R6,R3,#25
	
; nombre de lignes
	mov		R0,#150

boucle_triangle_ligne:
	strb	r3,[r1]
	strb	r6,[r4]
	strb	r3,[r5]

	strb	r3,[r2]
	subs	R1,R1,#1
	adds	R2,R2,#1
	
	add		R1,R1,#416
	add		R2,R2,#416
	add		R4,R4,#416
	add		R5,R5,#416
	
	subs	R0,R0,#1
	bgt		boucle_triangle_ligne

	mov		R1,R12
	add		R1,R1,#416*100

	add		R4,R1,#32
	add		R5,R4,#415-64
; au milieu
	add		R1,R1,#208
	mov		R2,R1

	ldr		r3,couleur
	add		R6,R3,#25
; nombre de lignes
	mov		R0,#150

boucle_triangle_ligne2:
	strb	r3,[r1]
	strb	r6,[r4]
	strb	r3,[r5]

	strb	r3,[r2]
	subs	R1,R1,#1
	adds	R2,R2,#1
	
	add		R1,R1,#416
	add		R2,R2,#416
	add		R4,R4,#416
	add		R5,R5,#416
	
	subs	R0,R0,#1
	bgt		boucle_triangle_ligne2

; ligne horizontale a 200
	mov		R1,R12
	;ldr		r1,screenaddr1
	add		R1,R1,#416*199
	add		R3,R3,#5654

	mov		R0,#350

boucle_triangle_ligne3:
	strb	r3,[r1],#1
	subs	R0,R0,#1
	bgt		boucle_triangle_ligne3
	mov		pc,lr









toucheclavier:		.long 0
;----------------------------------------------------------------------------------------------------------------------
RM_init:
; ne fait que verifier la version de Risc OS...
	str		lr,save_lr
; get OS version
	MOV     R0,#129
	MOV     R1,#0
	MOV     R2,#0xFF
	SWI     OS_Byte

	STRB    R1,os_version

; Risc os 3.5 ? => sortie
	CMP     R1,#0xA5
	beq		exit
	
	ldr		lr,save_lr
	mov		pc,lr
save_lr:		.long		0

; SH decoded IRQ and FIQ masks
;
; to load/set/store IRQ and FIQ masks use:
;
; Rx=mask
; Ry=&3200000 (IOC base)
;
;
; LDRB Rx,[Ry,#&18+0]      ;load irqa mask (+0)
; STRB Rx,oldirqa          ;store original mask
; MOV  Rx,#%00100000       ;only allow timer 0 interrupt
; STRB Rx,[Ry,#&18+2]      ;(note +2 on storing)
;
; LDRB Rx,[Ry,#&28+0]      ;load irqb mask (+0)
; STRB Rx,oldirqb          ;store original mask
; MOV  Rx,#%00000010       ;only allow sound interrupt
; STRB Rx,[Ry,#&28+2]      ;(note +2 on storing)
;
;

;irqa mask = IOC (&3200000) + &18
;
;bit 0   - il6 0 printer busy / printer irq
;    1   - il7 0 serial port ringing / low battery
;    2   - if  0 printer ack / floppy index
;    3s  - ir  1 vsync
;    4   - por 0 power on
;    5c  - tm0 0 timer 0
;    6   - tm1 1 timer 1
;    7   - 1   0 n/c      (fiq downgrade?)
;
;irqb mask = IOC (&3200000) + &28
;
;bit 0   - il0 0 expansion card fiq downgrade
;    1   - il1 0 sound system buffer change
;    2   - il2 0 serial port controller
;    3   - il3 0 hdd controller / ide controller
;    4   - il4 0 floppy changed / floppy interrupt
;    5   - il5 0 expansion card interrupt
;    6   - stx 1 keyboard transmit empty
;    7cs - str 1 keyboard recieve full
;
; c = cmdline critical
; s = desktop critical
;
;fiq mask (none are critical) = IOC (&3200000) + &38
;
;bit 0  - fh0 0 floppy data request / floppy dma
;    1  - fh1 0 fdc interrupt / fh1 pin on ioc
;    2  - fl  0 econet interrupt
;    3  - c3  0 c3 on ioc
;    4  - c4  0 c4 on ioc / serial interrupt (also IRQB bit2)
;    5  - c5  0 c5 on ioc
;    6  - il0 0 expansion card interrupt
;    7  - 1   0 force fiq (always 1)
;
;cr
;
;bit 0 - c0 IIC data
;    1 - c1 IIC clock
;    2 - c2 floppy ready / density
;    3 - c3 reset enable / unique id
;    4 - c4 aux i/o connector / serial fiq
;    5 - c5 speaker
;    6 - if printer ack or floppy index
;    7 - ir vsync
;	
;----------------------------------------------------------------------------------------------------------------------
RM_start:
	str		lr,save_lr
; appel XOS car si appel OS_SWI si erreur, ça sort directement
	MOV		R0,#0x0C           ;claim FIQ
	SWI		XOS_ServiceCall
	bvs		exit


; we own FIQs


	TEQP	PC,#0xC000001					; bit 27 & 26 = 1, bit 0=1 : IRQ Disable+FIRQ Disable+FIRQ mode ( pour récupérer et sauvegarder les registres FIRQ )
;	TEQP	PC,#0b11<<26 OR 0b01			;disable IRQs and FIQs, change to FIQ mode
	MOV		R0,R0

	ADR       R0,fiqoriginal				; sauvegarde de R8-R14
	STMIA     R0,{R8-R14}

	MOV       R1,#0x3200000
	LDRB      R0,[R1,#0x18]					; lecture et sauvegarde mask IRQ A
	STR       R0,oldIRQa
	LDRB      R0,[R1,#0x28]					; lecture et sauvegarde mask IRQ B
	STR       R0,oldIRQb

; When installing, we will start on the next VSync, so set IRQ for VSync only
; and set T1 to contain 'vsyncvalue', so everything in place for VSync int...

	MOV       R0,#0b00001000
	STRB      R0,[R1,#0x18+2]    ;set IRQA mask to %00001000 = VSync only : bit 3 sur mask IRQ A = vsync
	MOV       R0,#0
	STRB      R0,[R1,#0x28+2]    ;set IRQB mask to 0					:	IRQ B mask à 0 = disabled
	STRB      R0,[R1,#0x38+2]    ;set FIQ mask to 0 (disable FIQs)		:	FIRQ  mask à 0 = disabled

; Timer 1 / IRQ A
	MOV       R0,#0xFF           ;*v0.14* set max T1 - ensure T1 doesn't trigger before first VSync!
	STRB      R0,[R1,#0x50+2]    ;T1 low byte, +2 for write			: verrou / compteur = 0xFFFF
	STRB      R0,[R1,#0x54+2]    ;T1 high byte, +2 for write
	STRB      R1,[R1,#0x58+2]    ;T1_go = reset T1					: remet le compteur a la valeur latch ( verrou)

; on prépare le compteur du Timer 1 qui tournera entre le Vsync et la 1ere ligne de hsync
	MOV       R0,#vsyncreturn_low_ligne199			;or ldr r8,vsyncval  - will reload with this on VSync...			
	STRB      R0,[R1,#0x50+2]    				;T1 low byte, +2 for write									: verrou / compteur 
	MOV       R0,#vsyncreturn_high_ligne199			;or mov r8,r8,lsr#8
	STRB      R0,[R1,#0x54+2]   					;T1 high byte, +2 for write								: verrou / compteur 


; poke our IRQ/FIQ code into &1C-&FC : copie des routines IRQ/FIRQ dans la mémoire basse en 0x18
	MOV       R0,#0
	LDR       R1,[R0,#0x18]      ;load current IRQ vector
	STR       R1,oldIRQbranch

	BIC       R1,R1,#0xFF000000
	MOV       R1,R1,LSL#2
	ADD       R1,R1,#0x18+8
	STR       R1,oldIRQaddress

;copy IRQ/FIQ code to &18 onwards
	ldr			R0,pointeur_fiqbase
	MOV       R1,#0x18	
	LDMIA     R0!,{R2-R12}
	STMIA     R1!,{R2-R12}      ;11 pokey codey
	LDMIA     R0!,{R2-R12}
	STMIA     R1!,{R2-R12}      ;22 pokey codey
	LDMIA     R0!,{R2-R12}
	STMIA     R1!,{R2-R12}      ;33 pokey codey
	LDMIA     R0!,{R2-R12}
	STMIA     R1!,{R2-R12}      ;44 pokey codey
	LDMIA     R0!,{R2-R12}
	STMIA     R1!,{R2-R12}      ;55 pokey codey
	LDMIA     R0!,{R2-R4}
	STMIA     R1!,{R2-R4}       ;58 pokey codey (58 max)

; init des registres permanents
	MOV			R14,#0x3200000         	; 6 2C set R14 to IOC address
	mov			R12,#0x3400000


.equ 	FIQ_notHSync_valeur, 0xC0
; on écrit l'adresse de la routine Vsync dans le code IRQ/FIRQ en bas de mémoire  pour revenir si vsync ou keyboard
	adr		R0,notHSync					;FNlong_adr("",0,notHSync)   ;set up VSync code after copying
	MOV     R1,#FIQ_notHSync_valeur 	;ref. works if assembling on RO3, note 'FIQ_notHSync' is 0-relative!
	STR       R0,[R1]

; sauvegarde de la première instruction pour vérifier la présence du code , pour ne pas lancer plusieurs fois RM, inutile dans mon cas.
;	MOV       R0,#0
;	LDR       R1,[R0,#0x18]      ;first IRQ instruction from our code
;	STR       R1,newIRQfirstinst

; sortie
;									mode SVC Supervisor
	TEQP      PC,#0b11				; %00<<26 OR %11;enable IRQs and FIQs, change to user mode
	MOV       R0,R0
	
	ldr		lr,save_lr
	mov		pc,lr					;exit in USER mode and with IRQs and FIQs on


;----------------------------------------------------------------------------------------------------------------------
RM_release:
	str		lr,save_lr

; we own FIQs
				  
	TEQP      PC,#0x0C000001					; %11<<26 OR %01            ;disable IRQs and FIQs, switch FIQ mode
	MOV       R0,R0

	MOV       R0,#0
	LDR       R1,oldIRQbranch
	STR       R1,[R0,#0x18]        ;restore original IRQ controller
	
	MOV       R0,#0
	MOV       R1,#0x3200000
	STRB      R0,[R1,#0x38+2]      ;set FIQ mask to 0 (disable FIQs)

	LDR       R0,oldIRQa
	STRB      R0,[R1,#0x18+2]
	LDR       R0,oldIRQb
	STRB      R0,[R1,#0x28+2]      ;restore IRQ masks

	TEQP      PC,#0b11  			; (%00<<26) OR %11          ;enable IRQs and FIQs, stay SVC mode
	MOV       R0,R0


	MOV       R0,#0x0B             ;release FIQ
	SWI       XOS_ServiceCall

	ldr		lr,save_lr
	mov		pc,lr					; return USER mode, leave IRQs and FIQs on

;----------------------------------------------------------------------------------------------------------------------
RM_wait_VBL:
	LDRB      R11,vsyncbyte   ;load our byte from FIQ address, if enabled
waitloop_vbl:
	LDRB      R12,vsyncbyte
	TEQ       R12,R11
	BEQ       waitloop_vbl
	MOVS      PC,R14

;----------------------------------------------------------------------------------------------------------------------
RM_scankeyboard:
; https://www.riscosopen.org/wiki/documentation/show/Low-Level%20Internal%20Key%20Numbers
; retour : R0 = touche sur 2 octets
	;mov		R12,#0
	;mov		R0,#0

	LDRB      R12,keybyte2
	ands			R12,R12,#0b1111
	beq		  sortie_keycheck
	LDRB      R0,keybyte1
	ands			R0,R0,#0b1111
	ORR       R0,R12,R0,LSL#4

sortie_keycheck:
	mov		pc,lr				; retour 

;----------------------------------------------------------------------------------------------------------------------
RM_clearkeybuffer:		   ;10 - temp SWI, probably not needed in future once full handler done
	MOV       R12,#0
	STRB      R12,keybyte1
	STRB      R12,keybyte2
	MOV       PC,R14      ;flags not preserved


;----------------------------------------------------------------------------------------------------------------------
; routine de verif du clavier executée pendant l'interruption.  lors de la lecture de 0x04, le bit d'interruption est remis à zéro
RM_check_keyboard:
	;CMP       R13,#256            ;retrace? - this is a backup to disable STx SRx irqs, n/r
	;MOVNE     R8,#%00000000       ;           n/r once everything is working
	;STRNEB    R8,[R14,#&28+2]     ;set IRQB mask to %11000000 = STx or SRx
	;BNE       exitVScode          ;back to IRQ mode and exit

; dans la vbl, registres sauvés en debut de VBL
	;ADR       R8,kbd_stack
	;STMIA     R8,{R4-R7}          ;some regs to play with

; R14 = IOC 
	MOV       R9,#0x3200000       ; R14 to IOC address
	LDRB      R8,[R9,#0x24+0]     ;load irq_B triggers								:IRQ B Status, bit 7 = buffer clavier vide
	TST       R8,#0b10000000       ;bit 7 = SRx, cleared by a read from 04

	; LDMEQIA     R8,{R4-R7}          ;restore regs
	BEQ         exitVScode          ;back to IRQ mode and exit
;BNE       kbd_received
;:
;.kbd_trans
;TST       R4,#%01000000       ;bit 6 = STx, cleared by a write to 04
;LDRNEB    R5,nextkeybyte
;STRNEB    R5,[R14,#&04+2]     ;clear STx
;MOVNE     R5,#%10000000       ;set mask to wait for ok-to-read
;STRNEB    R5,[R14,#&28+2]     ;set IRQB mask to %10000000 = SRx
;:
;LDMIA     R8,{R4-R7}          ;restore regs
;B         exitVScode          ;back to IRQ mode and exit
;
;
kbd_received:

; process key byte, and put ack value in nextkeybyte

	LDRB      R8,keycounter
	RSBS      R8,R8,#1            ;if =1 (NE), then this is the first byte, else (EQ)=second byte
	STRB      R8,keycounter

	LDRB      R10,[R9,#0x04+0]     ;load byte, clear SRx							: lors de la lecture de 0x04, le bit d'interruption est remis à zéro
	STRNEB    R10,keybyte1															; si pas R10 vide on stock l'octet clavier 1
	STRNEB    R9,keybyte2			;clear byte 2!!! (was key-bug until v0.20)
	
	MOVNE     R8,#0b00111111       ;if first byte, reply with bACK					: pdf TRM A4 : BACK 0011 1111 ACK for first keyboard data byte pair.
	STREQB    R10,keybyte2
	
	MOVEQ     R8,#0b00110001       ;if second byte, reply with sACK					: pdf TRM A4 : SACK 0011 0001 Last data byte ACK.
	STRB      R8,[R9,#0x04+2] 		;transmit response = sACK
	;STRB      R6,nextkeybyte

	;MOV       R5,#%01000000       ;set mask to wait for ok-to-transmit
	;STRB      R5,[R14,#&28+2]     ;set IRQB mask to %01000000 = STx
	
	;LDMIA     R8,{R4-R7}          ;restore regs
	B         exitVScode          ;back to IRQ mode and exit
	;B         kbd_trans


; bACK=%00111111
; sACK=%00110001


keycounter:  .byte 0 ;1 or 0
keybyte1:    .byte 0
keybyte2:    .byte 0
nextkeybyte: .byte 0

kbd_stack:
.long      0 ;R4
.long      0 ;R5
.long      0 ;R6
.long      0 ;R7


;currently have rem'd the disable STx SRx irqs in hsync code and checkkeyboard code

;next try only enabling receive, assume transmit is ok...

;something wrong - &FFFF (HRST) seems to be only byte received
;v0.14 worked when trying only enabling receive, assume transmit is ok...

; on arrive avec:
; sauvegarde de R14 dans saveR14_firq en 0xE0
; sauvegarde de R4-R7 dans FIQ_tempstack en 0xD0
;  R14 = pointeur sur saveR14_firq
;  R8 = load irq_A triggers ( anciennement R8) R4 
;  R5 = 0x3200000 ( anciennement R14)  - IOC -
;  R6 = ...
;  R7 = ...

;----------------------------------------------------------------------------------------------------------------------
notHSync:
	TST       R8,#0b00001000       ;retest R5 is it bit 3 = Vsync? (bit 6 = T1 trigger/HSync)				: R8 = 0x14 = IRQ Request A => bit 3=vsync, bit 6=Timer 1 / hsync
	STRNEB    R14,[R14,#0x58+2]    ;if VSync, reset T1 (latch should already have the vsyncvalue...)		: si vsync, alors on refait un GO = on remet le compteur (latch) pour le timer 1 à la valeur vsyncreturn ( mise dans les registres dans le start et  après la derniere ligne )
;
; that's the high-priority stuff done, now we can check keyboard too...
;
	BEQ       RM_check_keyboard       ;check IRQ_B for SRx/STx interrupts									: R8=0 / si 0, c'est qu'on a ni bit3=vsync, ni bit 6=Timer 1, donc c'est une IRQ B = clavier/keyboard

	STRB      R8,[R14,#0x14+2]     ; ...and clear all IRQ_A interrupt triggers								: 1 = clear, donc ré-écrire la valeur de request efface/annule la requete d'interruption

; remaskage IRQ A : Timer 1 + Vsync
	MOV       R8,#0b01000000        ; Timer 1 only. **removed VSync trigger v0.05
;	MOV       R8,#0b01001000		; EDZ : Vsync + Timer 1
;	MOV       R8,#0b00001000		; EDZ : Vsync only

	STRB      R8,[R14,#0x18+2]     ;set IRQA mask to %01000000 = T1 only									: mask IRQ A : bit 6 = Timer 1, plus de Vsync

; remaskage IRQ B : clavier/keyboard
	MOV       R8,#0b10000000       ;R8,#%11000000
	STRB      R8,[R14,#0x28+2]     ;set IRQB mask to %11000000 = STx or SRx									: mask IRQ B pour clavier

; remet le compteur inter ligne pour la frequence de Timer 1 = Hsync	
	MOV       R8,#hsyncline_low			; (hsyncline AND &00FF)>>0
	STRB      R8,[R14,#0x50+2]              ;T1 low byte, +2 for write
	MOV       R8,#hsyncline_high		; (hsyncline AND &FF00)>>8
	STRB      R8,[R14,#0x54+2]              ;T1 high byte, +2 for write

; vsyncbyte = 3 - vsyncbyte
; sert de flag de vsync, si modifié => vsync
	LDRB      R8,vsyncbyte
	RSB       R8,R8,#3
	STRB      R8,vsyncbyte


;	ADR       R8,regtable
;	LDMIA     R8,{R9,R10,R11,R12}          ;reset table registers to defaults

; on remet le nombre de ligne a decrementer avant d'arriver à vsync
	mov			R9,#position_ligne_hsync
	mov 		R8,#ylines                  ;reset yline counter
	str			R8,[R9]
	

;	b		zap_swap1

; swap des pointeurs :
; swap pointeur ecrans
	ldr		r8,screenaddr1
	ldr		r9,screenaddr2
	str		r9,screenaddr1
	str		r8,screenaddr2

	ldr		r8,screenaddr1_MEMC
	ldr		r9,screenaddr2_MEMC
	str		r9,screenaddr1_MEMC
	str		r8,screenaddr2_MEMC

; swap pointeurs table reflet

	ldr		R8,pointeur_table_reflet_MEMC1
	ldr		R9,pointeur_table_reflet_MEMC2
	str		R9,pointeur_table_reflet_MEMC1
	str		R8,pointeur_table_reflet_MEMC2

	ldr		R8,vstart_MEMC1
	ldr		R9,vstart_MEMC2
	str		R9,vstart_MEMC1
	str		R8,vstart_MEMC2

	ldr		R8,vend_MEMC1
	ldr		R9,vend_MEMC2
	str		R9,vend_MEMC1
	str		R8,vend_MEMC2

zap_swap1:
;--------------
; test avec vstart 
; vinit = 0x3600000
; vstart = 0x3620000 = 0
; vend = 0x3640000 = 26

; vstart = 0
	mov	R9,#0x3620000
	;mov	R8,#104*32
	ldr		R8,vstart_MEMC1
	add	R8,R8,R9
	str	R8,[R8]
	
; vend = ligne 200
	mov	R9,#0x3640000
	;mov	R8,#104*232			; 199*104 + 104 -4 : 200 +32 lignes en haut
	ldr	R8,vend_MEMC1
	sub	R8,R8,#4
	add	R8,R8,R9
	str	R8,[R8]
	
; update pointeur video hardware vinit
	ldr	r8,screenaddr1_MEMC
	mov r8,r8,lsr #4
	mov r8,r8,lsl #2
	mov r9,#0x3600000
	add r8,r8,r9
	str r8,[r8]

	
; vinit
;	mov	R9,#0x3600000
;	mov		R8,#0
;	add	R8,R8,R9
;	str	R8,[R8]


	.ifeq		1

; ---------------attente debug affichage

	mov   r9,#0x3400000               
	mov   r8,#777
; border	
	orr   r8,r8,#0x00000000            
	str   r8,[r9]  


	mov		R8,#10000
bouclewait:
	mov	R8,R8
	subs	R8,R8,#1
	bgt	bouclewait

	.endif
	
	ldr			R13,pointeur_table_reflet_MEMC1
	;mov			R13,#table_couleur0_vstart_vend

; couleur fond = noir
	mov			R8,#0
	str			R8,[R12]				; remise à noir du fond
	

 

; ---------------attente debug affichage

;	- vstart modifiable après démarrage affichage : vinit à 0, vstart à 0, vend à 199*104+100, attendre affichage, pendant affichage : vstart à 50*104

; vinit à zéro
; vinit
;	mov	R9,#0x3600000
	;mov	R8,#104*50			; 
;	mov		R8,#0
;	add	R8,R8,R9
;	str	R8,[R8]

; vstart à 0
; vstart = 0
;	mov	R9,#0x3620000
;	mov	R8,#104*50			; 199*104 + 104 -4 
;	mov	R8,#0
;	add	R8,R8,R9
;	str	R8,[R8]

; vend = ligne 200
;	mov	R9,#0x3640000
;	mov	R8,#104*39			; 199*104 + 104 -4 
;	sub	R8,R8,#4
;	add	R8,R8,R9
;	str	R8,[R8]





	; update pointeur video hardware vinit
;	ldr	r0,screenaddr1_MEMC
;	mov r0,r0,lsr #4
;	mov r0,r0,lsl #2
;	mov r1,#0x3600000
;	add r0,r0,r1
;	str r0,[r0]

; vinit à la ligne 199
	;mov	R8,#0x3600000
	;add	R8,R8,#(199*104)
	;ldr	R8,valeur_vinit_premiere_ligne
	;str	R8,[R8]

	;ldr	R8,valeur_vend_premiere_ligne
	;str	R8,[R8]


;	ldr	R8,valeur_vstart_premiere_ligne
;	str	R8,[R8]


	
	;MOV       R13,#ylines                  ;reset yline counter

; ----- QTM
;	LDRB      R8,qtmcontrol
;	TEQ       R8,#1
;	BNE       exitVScode                   ;back to IRQ mode and exit

;rastersound:                  ;entered in FIQ mode, must exit via IRQ mode with SUBS PC,R14,#4
;	TEQP      PC,#%11<<26 OR %10  ;enter IRQ mode, IRQs/FIQs off
;	MOV       R0,R0               ;sync
;	STMFD     R13!,{R14}          ;stack R13_IRQ
;	TEQP      PC,#%11<<26 OR %11  ;enter SVC mode, IRQs/FIQs off
;	MOV       R0,R0               ;sync

;	STR       R13,tempr13         ;
;	LDRB      R13,dma_in_progress ;
;	TEQ       R13,#0              ;
;	LDRNE     R13,tempr13         ;
;	BNE       exitysoundcode      ;
;	STRB      PC,dma_in_progress  ;

;	adr		R13,startofstack	;FNlong_adr("",13,startofstack);
;	STMFD     R13!,{R14}          ;stack R14_SVC
;	LDR       R14,tempr13         ;
;	STMFD     R13!,{R14}          ;stack R13_SVC - we are now reentrant!!!
;	BL        rastersound_1       ;call rastersound routine - enables IRQs

;	MOV       R14,#0              ;...on return IRQs/FIQs will be off
;	STRB      R14,dma_in_progress ;
;	LDMFD     R13,{R13,R14}       ;restore R14_SVC and R13_SVC

;exitysoundcode:
;	TEQP      PC,#%11<<26 OR %10  ;back to IRQ mode
;	MOV       R0,R0               ;sync

;	LDMFD     R13!,{R14}
;	SUBS      PC,R14,#4           ;return to foreground


exitVScode:
;	mode IRQ mode, 
	TEQP      PC,#0x0C000002			; %000011<<26 OR %10 ;36 A4 back to IRQ mode				: xor sur bits 27&26 = autorise IRQ et FIRQ. xor sur bit1 = 01 xor 0b10 = 11 SVC
	MOV       R0,R0                  ;37 A8 sync IRQ registers
	SUBS      PC,R14,#4              ;38 AC return to foreground
;----------------------------------------------------------------------------------------------------------------------

			
			
			

; ---------------------
; variables RM
os_version:		.long      0         ;1 byte &A0 for Arthur 0.3/1.2, &A1 for RO2, &A3 for RO3.0, &A4 for RO3.1
fiqoriginal:	
.long      0         ;R8
.long      0         ;R9
.long      0         ;R10
.long      0         ;R11
.long      0         ;R12
.long      0         ;R13
.long      0         ;R14

oldIRQa:	.long	0				; ancien vecteur IRQ A du système
oldIRQb:	.long	0				; ancien vecteur IRQ B du système
newIRQfirstinst:	.long	0	
oldIRQbranch:		.long 	0
oldIRQaddress:		.long	0

vsyncbyte:		.long 	0

; pointeurs proches	
		.p2align		4
pointeur_module97:		.long	module97
couleur:	.long	0x7f7f7f7f
couleur2:	.long	0x1e1e1e1e
screenaddr1:	.long 0
screenaddr2:	.long 0
screenaddr1_MEMC:	.long 0
screenaddr2_MEMC:	.long 0

;pointeur_XOS_ServiceCall: .long toto
;toto:
;	.byte "XOS_ServiceCall",0


	.p2align 8

; datas lointaines
		.p2align 4
module97:		.incbin	"97,ffa"


valeur_vinit_premiere_ligne:		.long	0x3600000+(98*104)
valeur_vstart_premiere_ligne:		.long	0x3620000+(98*104)
valeur_vend_premiere_ligne:		.long		0x3640000+100+(98*104)

pointeur_table_reflet_MEMC1:	.long	table_couleur0_vstart_vend_MEMC1
pointeur_table_reflet_MEMC2:	.long	table_couleur0_vstart_vend_MEMC2

vstart_MEMC1:		.long		104*32
vend_MEMC1:			.long		104*232
vstart_MEMC2:		.long		104*32+(104*290)
vend_MEMC2:			.long		104*232+(104*290)


; 58 lignes en tout
;       .long   couleur0, vstart, vend
;------------------------------------------------------------------------------------------------
table_couleur0_vstart_vend_MEMC1:
;1ere ligne : fin de l'écran du haut. : vend = 0x3640000+((200*104)-4)
	.set	numero_ligne_reflet,199
	.set 	couleur0,0
	.long   couleur0, 0x3620000 + (numero_ligne_reflet*104)+(104*32), 0x3640000+((200*104)-4)+(104*32)
	.set	couleur0, couleur0+0b100000000
	.set	numero_ligne_reflet , numero_ligne_reflet - 1
	.rept	6
		.rept	2
			.long   couleur0, 0x3620000 + (numero_ligne_reflet*104)+(104*32), 0x3640000+(((numero_ligne_reflet+1)*104)+100)+(104*32)
			.set	numero_ligne_reflet , numero_ligne_reflet - 1
		.endr
		.set	couleur0, couleur0+0b100000000
	.endr
; 12+1 = 13 lignes
; ligne 186	à 62 sur 25 lignes
;       .long   couleur0, vstart, vend
		.long   couleur0, 0x3620000 + (186*104)+(104*32), 0x3640000+((187*104)+100)+(104*32)
        .long   couleur0, 0x3620000 + (178*104)+(104*32), 0x3640000+(186*104)+100+(104*32)
        .long   couleur0, 0x3620000 + (170*104)+(104*32), 0x3640000+(178*104)+100+(104*32)
        .long   couleur0, 0x3620000 + (162*104)+(104*32), 0x3640000+(170*104)+100+(104*32)
        .long   couleur0, 0x3620000 + (155*104)+(104*32), 0x3640000+(162*104)+100+(104*32)
        .long   couleur0, 0x3620000 + (147*104)+(104*32), 0x3640000+(155*104)+100+(104*32)
        .long   couleur0, 0x3620000 + (140*104)+(104*32), 0x3640000+(147*104)+100+(104*32)
        .long   couleur0, 0x3620000 + (133*104)+(104*32), 0x3640000+(140*104)+100+(104*32)
        .long   couleur0, 0x3620000 + (126*104)+(104*32), 0x3640000+(133*104)+100+(104*32)
        .long   couleur0, 0x3620000 + (119*104)+(104*32), 0x3640000+(126*104)+100+(104*32)
        .long   couleur0, 0x3620000 + (113*104)+(104*32), 0x3640000+(119*104)+100+(104*32)
        .long   couleur0, 0x3620000 + (106*104)+(104*32), 0x3640000+(113*104)+100+(104*32)
        .long   couleur0, 0x3620000 + (101*104)+(104*32), 0x3640000+(106*104)+100+(104*32)
        .long   couleur0, 0x3620000 + (95*104)+(104*32), 0x3640000+(101*104)+100+(104*32)
        .long   couleur0, 0x3620000 + (90*104)+(104*32), 0x3640000+(95*104)+100+(104*32)
        .long   couleur0, 0x3620000 + (85*104)+(104*32), 0x3640000+(90*104)+100+(104*32)
        .long   couleur0, 0x3620000 + (81*104)+(104*32), 0x3640000+(85*104)+100+(104*32)
        .long   couleur0, 0x3620000 + (77*104)+(104*32), 0x3640000+(81*104)+100+(104*32)
        .long   couleur0, 0x3620000 + (73*104)+(104*32), 0x3640000+(77*104)+100+(104*32)
        .long   couleur0, 0x3620000 + (70*104)+(104*32), 0x3640000+(73*104)+100+(104*32)
        .long   couleur0, 0x3620000 + (68*104)+(104*32), 0x3640000+(70*104)+100+(104*32)
        .long   couleur0, 0x3620000 + (65*104)+(104*32), 0x3640000+(68*104)+100+(104*32)
        .long   couleur0, 0x3620000 + (64*104)+(104*32), 0x3640000+(65*104)+100+(104*32)
        .long   couleur0, 0x3620000 + (62*104)+(104*32), 0x3640000+(64*104)+100+(104*32)
        .long   couleur0, 0x3620000 + (61*104)+(104*32), 0x3640000+(62*104)+100+(104*32)
; 25+13 = 38 lignes affichées, reste 20 lignes
;       .long   couleur0, vstart, vend
       .long   couleur0, 0x3620000 + (60*104)+(104*32), 0x3640000+((61*104)+100)+(104*32)
       .long   couleur0, 0x3620000 + (55*104)+(104*32), 0x3640000+(60*104)+100+(104*32)
        .long   couleur0, 0x3620000 + (50*104)+(104*32), 0x3640000+(55*104)+100+(104*32)
        .long   couleur0, 0x3620000 + (45*104)+(104*32), 0x3640000+(50*104)+100+(104*32)
        .long   couleur0, 0x3620000 + (41*104)+(104*32), 0x3640000+(45*104)+100+(104*32)
        .long   couleur0, 0x3620000 + (37*104)+(104*32), 0x3640000+(41*104)+100+(104*32)
        .long   couleur0, 0x3620000 + (32*104)+(104*32), 0x3640000+(37*104)+100+(104*32)
        .long   couleur0, 0x3620000 + (28*104)+(104*32), 0x3640000+(32*104)+100+(104*32)
        .long   couleur0, 0x3620000 + (24*104)+(104*32), 0x3640000+(28*104)+100+(104*32)
        .long   couleur0, 0x3620000 + (21*104)+(104*32), 0x3640000+(24*104)+100+(104*32)
        .long   couleur0, 0x3620000 + (17*104)+(104*32), 0x3640000+(21*104)+100+(104*32)
        .long   couleur0, 0x3620000 + (14*104)+(104*32), 0x3640000+(17*104)+100+(104*32)
        .long   couleur0, 0x3620000 + (11*104)+(104*32), 0x3640000+(14*104)+100+(104*32)
        .long   couleur0, 0x3620000 + (8*104)+(104*32), 0x3640000+(11*104)+100+(104*32)
        .long   couleur0, 0x3620000 + (6*104)+(104*32), 0x3640000+(8*104)+100+(104*32)
        .long   couleur0, 0x3620000 + (4*104)+(104*32), 0x3640000+(6*104)+100+(104*32)
        .long   couleur0, 0x3620000 + (2*104)+(104*32), 0x3640000+(4*104)+100+(104*32)
        .long   couleur0, 0x3620000 + (1*104)+(104*32), 0x3640000+(2*104)+100+(104*32)
        .long   couleur0, 0x3620000 + (0*104)+(104*32), 0x3640000+(1*104)+100+(104*32)
        .long   couleur0, 0x3620000 + (0*104)+(104*32), 0x3640000+(0*104)+100+(104*32)
; 38+20=58
;------------------------------------------------------------------------------------------------
table_couleur0_vstart_vend_MEMC2:
;1ere ligne : fin de l'écran du haut. : vend = 0x3640000+((200*104)-4)
	.set	numero_ligne_reflet,199
	.set 	couleur0,0
	.long   couleur0, 0x3620000 + (numero_ligne_reflet*104)+(104*32)+(104*290), 0x3640000+((200*104)-4)+(104*32)+(104*290)
	.set	couleur0, couleur0+0b100000000
	.set	numero_ligne_reflet , numero_ligne_reflet - 1
	.rept	6
		.rept	2
			.long   couleur0, 0x3620000 + (numero_ligne_reflet*104)+(104*32)+(104*290), 0x3640000+(((numero_ligne_reflet+1)*104)+100)+(104*32)+(104*290)
			.set	numero_ligne_reflet , numero_ligne_reflet - 1
		.endr
		.set	couleur0, couleur0+0b100000000
	.endr
; 12+1 = 13 lignes
; ligne 186	à 62 sur 25 lignes
;       .long   couleur0, vstart, vend
		.long   couleur0, 0x3620000 + (186*104)+(104*32)+(104*290), 0x3640000+((187*104)+100)+(104*32)+(104*290)
        .long   couleur0, 0x3620000 + (178*104)+(104*32)+(104*290), 0x3640000+(186*104)+100+(104*32)+(104*290)
        .long   couleur0, 0x3620000 + (170*104)+(104*32)+(104*290), 0x3640000+(178*104)+100+(104*32)+(104*290)
        .long   couleur0, 0x3620000 + (162*104)+(104*32)+(104*290), 0x3640000+(170*104)+100+(104*32)+(104*290)
        .long   couleur0, 0x3620000 + (155*104)+(104*32)+(104*290), 0x3640000+(162*104)+100+(104*32)+(104*290)
        .long   couleur0, 0x3620000 + (147*104)+(104*32)+(104*290), 0x3640000+(155*104)+100+(104*32)+(104*290)
        .long   couleur0, 0x3620000 + (140*104)+(104*32)+(104*290), 0x3640000+(147*104)+100+(104*32)+(104*290)
        .long   couleur0, 0x3620000 + (133*104)+(104*32)+(104*290), 0x3640000+(140*104)+100+(104*32)+(104*290)
        .long   couleur0, 0x3620000 + (126*104)+(104*32)+(104*290), 0x3640000+(133*104)+100+(104*32)+(104*290)
        .long   couleur0, 0x3620000 + (119*104)+(104*32)+(104*290), 0x3640000+(126*104)+100+(104*32)+(104*290)
        .long   couleur0, 0x3620000 + (113*104)+(104*32)+(104*290), 0x3640000+(119*104)+100+(104*32)+(104*290)
        .long   couleur0, 0x3620000 + (106*104)+(104*32)+(104*290), 0x3640000+(113*104)+100+(104*32)+(104*290)
        .long   couleur0, 0x3620000 + (101*104)+(104*32)+(104*290), 0x3640000+(106*104)+100+(104*32)+(104*290)
        .long   couleur0, 0x3620000 + (95*104)+(104*32)+(104*290), 0x3640000+(101*104)+100+(104*32)+(104*290)
        .long   couleur0, 0x3620000 + (90*104)+(104*32)+(104*290), 0x3640000+(95*104)+100+(104*32)+(104*290)
        .long   couleur0, 0x3620000 + (85*104)+(104*32)+(104*290), 0x3640000+(90*104)+100+(104*32)+(104*290)
        .long   couleur0, 0x3620000 + (81*104)+(104*32)+(104*290), 0x3640000+(85*104)+100+(104*32)+(104*290)
        .long   couleur0, 0x3620000 + (77*104)+(104*32)+(104*290), 0x3640000+(81*104)+100+(104*32)+(104*290)
        .long   couleur0, 0x3620000 + (73*104)+(104*32)+(104*290), 0x3640000+(77*104)+100+(104*32)+(104*290)
        .long   couleur0, 0x3620000 + (70*104)+(104*32)+(104*290), 0x3640000+(73*104)+100+(104*32)+(104*290)
        .long   couleur0, 0x3620000 + (68*104)+(104*32)+(104*290), 0x3640000+(70*104)+100+(104*32)+(104*290)
        .long   couleur0, 0x3620000 + (65*104)+(104*32)+(104*290), 0x3640000+(68*104)+100+(104*32)+(104*290)
        .long   couleur0, 0x3620000 + (64*104)+(104*32)+(104*290), 0x3640000+(65*104)+100+(104*32)+(104*290)
        .long   couleur0, 0x3620000 + (62*104)+(104*32)+(104*290), 0x3640000+(64*104)+100+(104*32)+(104*290)
        .long   couleur0, 0x3620000 + (61*104)+(104*32)+(104*290), 0x3640000+(62*104)+100+(104*32)+(104*290)
; 25+13 = 38 lignes affichées, reste 20 lignes
;       .long   couleur0, vstart, vend
       .long   couleur0, 0x3620000 + (60*104)+(104*32)+(104*290), 0x3640000+((61*104)+100)+(104*290)+(104*32)
       .long   couleur0, 0x3620000 + (55*104)+(104*32)+(104*290), 0x3640000+(60*104)+100+(104*290)+(104*32)
        .long   couleur0, 0x3620000 + (50*104)+(104*32)+(104*290), 0x3640000+(55*104)+100+(104*290)+(104*32)
        .long   couleur0, 0x3620000 + (45*104)+(104*32)+(104*290), 0x3640000+(50*104)+100+(104*290)+(104*32)
        .long   couleur0, 0x3620000 + (41*104)+(104*32)+(104*290), 0x3640000+(45*104)+100+(104*290)+(104*32)
        .long   couleur0, 0x3620000 + (37*104)+(104*32)+(104*290), 0x3640000+(41*104)+100+(104*290)+(104*32)
        .long   couleur0, 0x3620000 + (32*104)+(104*32)+(104*290), 0x3640000+(37*104)+100+(104*290)+(104*32)
        .long   couleur0, 0x3620000 + (28*104)+(104*32)+(104*290), 0x3640000+(32*104)+100+(104*290)+(104*32)
        .long   couleur0, 0x3620000 + (24*104)+(104*32)+(104*290), 0x3640000+(28*104)+100+(104*290)+(104*32)
        .long   couleur0, 0x3620000 + (21*104)+(104*32)+(104*290), 0x3640000+(24*104)+100+(104*290)+(104*32)
        .long   couleur0, 0x3620000 + (17*104)+(104*32)+(104*290), 0x3640000+(21*104)+100+(104*290)+(104*32)
        .long   couleur0, 0x3620000 + (14*104)+(104*32)+(104*290), 0x3640000+(17*104)+100+(104*290)+(104*32)
        .long   couleur0, 0x3620000 + (11*104)+(104*32)+(104*290), 0x3640000+(14*104)+100+(104*290)+(104*32)
        .long   couleur0, 0x3620000 + (8*104)+(104*32)+(104*290), 0x3640000+(11*104)+100+(104*290)+(104*32)
        .long   couleur0, 0x3620000 + (6*104)+(104*32)+(104*290), 0x3640000+(8*104)+100+(104*290)+(104*32)
        .long   couleur0, 0x3620000 + (4*104)+(104*32)+(104*290), 0x3640000+(6*104)+100+(104*290)+(104*32)
        .long   couleur0, 0x3620000 + (2*104)+(104*32)+(104*290), 0x3640000+(4*104)+100+(104*290)+(104*32)
        .long   couleur0, 0x3620000 + (1*104)+(104*32)+(104*290), 0x3640000+(2*104)+100+(104*290)+(104*32)
        .long   couleur0, 0x3620000 + (0*104)+(104*32)+(104*290), 0x3640000+(1*104)+100+(104*290)+(104*32)
        .long   couleur0, 0x3620000 + (0*104)+(104*32)+(104*290), 0x3640000+(0*104)+100+(104*290)+(104*32)
; 38+20=58
;------------------------------------------------------------------------------------------------



; ligne 199 : vstart = 0, vend=(200*104)-4
;	.long	couleur0,0x3620000, 0x3640000+((200*104)-4)
; ligne 200: vstart = 10*104, vend = 104-4
;	.long	couleur0,0x3620000+(104*10), 0x3640000+((1*104)-4)




; fin
		.long	0x77					; couleur du fond
		.long	0x3640000+104				; vend : 0x3620000	
		.long	0x3600000					; vinit pour 1ere ligne

; ------------------------------------------------------------------
;
; code principal de l'interruption FIQ
;
; calé entre 0x18 et 0x58
;
; ------------------------------------------------------------------


pointeur_fiqbase:		.long	fiqbase
fiqbase:              ;copy to &18 onwards, 57 instructions max
                      ;this pointer must be relative to module

		.incbin		"build\fiqrmi.bin"


fiqend:

