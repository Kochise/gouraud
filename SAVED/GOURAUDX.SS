; /// > GouraudSHADING - KOSS 2000 < ///
;

; *** Equates Zone ************************************************************

	; *** Equates for Assembly

ASSEMBLY_DAY	EQU	22
ASSEMBLY_MONTH	EQU	7
ASSEMBLY_YEAR	EQU	2000
	; Date Format :	%AAAAAAAmmmmJJJJJ
ASSEMBLY_DATE	EQU	((ASSEMBLY_YEAR-1980)<<9)|(ASSEMBLY_MONTH<<5)|(ASSEMBLY_DAY)

FILL	EQU	0

	; *** Commands for Assembly

	OPT	p=68030/68882
	comment	HEAD=7	; FastLoad

; /////////////////////////////////////////////////////////////////////////////
	SECTION	TEXT
; /////////////////////////////////////////////////////////////////////////////

	BRA	GOURAUD_ProgHEAD

	; *** Program Informations

	dc.b	"ProgHEAD"	; ProgHEADER
	dc.w	$0100	; ProgVERSION
	dc.w	ASSEMBLY_DATE	; ProgDATE
	dc.b	"GouraudSHADING",0	; ProgNAME
	dc.b	"Kochise",0	; ProgAUTHOR

; *** BasicPURPOSE ******************************************************
; *			*
; * 1. - Init the Memory		*
; * 2. + Run the Demo			*
; * 3. - Exit the Demo			*
; *			*
; ***************************************************** Set TAB to 24 ***

	; *** 1. Init the Memory ************************
	; *		*
	; * As ever, just keep the Program itself...	*
	; *		*
	; ***********************************************

GOURAUD_ProgHEAD	movea.l	(4,SP),A6	; Adresse de la BASEPAGE
	move.l	(12,A6),D0	; Taille du SEGMENT TEXT
	add.l	(20,A6),D0	; Additionne la taille du SEGMENT DATA � D0
	add.l	(28,A6),D0	; Additionne la taille du SEGMENT BSS � D0
	addi.l	#$100,D0	; Additionne la taille de la BASEPAGE � D0
	addi.l	#$400,D0	; Additionne la taille de la future PILE (Ici, 256 positions longues (1024 OCTETS))
	move.l	D0,D1	; Copie D0 dans D1 (Taille � r�server)
	move.l	D0,D7
	add.l	A6,D1	; Additionne l'adresse du d�but du programme avec D1 (La taille � r�server)
	andi.l	#-2,D1	; Rend D1 pair (Au cas o� il ne l'�tait pas)
	subq.l	#8,D1	; Garde de la place pour l'adresse de la BASEPAGE
	move.l	(4,SP),D2	; Sauvegarde l'adresse de la BASEPAGE
	movea.l	D1,SP	; Installe l'adresse de fin du programme+place nouvelle PILE dans la PILE
	move.l	D2,(4,SP)	; R�installe l'adresse de la BASEPAGE
	move.l	D0,-(SP)	; EmPILE la taille � r�server
	move.l	A6,-(SP)	; EmPILE l'adresse du programme
	clr.w	-(SP)	; R�serv�
	move.w	#$4A,-(SP)	; - M_SHRINK -
	trap	#1	; *** GEMDOS ***
	lea	(12,SP),SP

	; *** 2. Run the Demo ***************************
	; *		*
	; * 2.1. + Init the Demo	*
	; * 2.2. - Clear the Screens	*
	; * 2.3. + Precalculation of some Tables	*
	; * 2.4. + Main Loop of the demo	*
	; * 2.5. + Restore the State	*
	; *		*
	; ***********************************************

	; La D�mo
	
	pea	GOURAUD_DemoLOOP
	move.w	#$26,-(SP)
	TRAP	#14	;Supexec
	addq.l	#6,SP

	; *** 3. Exit the Demo **************************
	; *		*
	; * Always NO Error...		*
	; *		*
	; ***********************************************

	; Sortie

	clr.w	-(SP)	; - P_TERM0 -
	trap	#1	; *** GEMDOS ***

GOURAUD_DemoLOOP	BSR	GOURAUD_Init
	BSR	GOURAUD_ClearSCREEN
	BSR	GOURAUD_PreCALCULATION
	BSR	GOURAUD_MainLOOP
	BSR	GOURAUD_Restore

	RTS

; -----------------------------------------------------------------------------

; *** 2. Run the Demo ***************************************************
; *			*
; * 2.1. + Init the Demo		*
; * 2.2. - Clear the Screens		*
; * 2.3. + Precalculation of some Tables		*
; * 2.4. + Main Loop of the Demo		*
; * 2.5. + Restore the Saved State		*
; *			*
; ***********************************************************************

; ----    ---------------------------------------------------------------------

	; *** 2.1. Init the Demo ************************
	; *		*
	; * 2.1.1. - Hide the Mouse	*
	; * 2.1.2. - Select the Monitor	*
	; * 2.1.3. - MAlloc two Screens	*
	; * 2.1.4. - Save DeskTOP Screen	*
	; * 2.1.5. - Save DeskTOP VideoMODE	*
	; * 2.1.6. - Wait the Next VBL	*
	; * 2.1.7. - Change both Resolution and Screens	*
	; * 2.1.8. - Set BorderCOLOR to BLACK	*
	; *		*
	; ***********************************************

GOURAUD_Init	; * 2.1.1. - Hide the Mouse *********************

	dc.w	$A00A	; LineA HideMOUSE

	; * 2.1.2. - Select the Monitor *****************

	move.w	#89,-(SP)	; - MON_TYPE -
	trap	#14	; *** XBIOS ***
	addq.l	#2,SP
		
	move.l	$4.w,GOURAUD_MonJUMP	; RESET
	
	lea	GOURAUD_MonJUMP,A0
	JMP	([A0,D0.w*4])
	
GOURAUD_MonJUMP	ds.l	1	; Monochrome
	dc.l	GOURAUD_MonRGB	; Couleur ST
	dc.l	GOURAUD_MonVGA	; VGA
	dc.l	GOURAUD_MonRGB	; TV

GOURAUD_MonRGB	move.w	#$24,GOURAUD_ScreenMODE
	move.l	#320*200*2,GOURAUD_ScreenSIZE

	BRA	GOURAUD_NextINIT

GOURAUD_MonVGA	move.w	#$134,GOURAUD_ScreenMODE
	move.l	#320*240*2,GOURAUD_ScreenSIZE

	; * 2.1.3. - MAlloc two Screens *****************

	; Adresses Ecrans

GOURAUD_NextINIT	move.l	GOURAUD_ScreenSIZE,D0
	mulu.l	#2,D0
	addq.l	#4,D0

	clr.w	-(SP)
	move.l	D0,-(SP)
	move.w	#$44,-(SP)	; - M_XALLOC -
	TRAP	#1	; *** GEMDOS ***
	addq.l	#8,SP

	move.l	D0,GOURAUD_ScreenMEMORY

	addq.l	#4,D0
	andi.l	#-4,D0

	move.l	D0,GOURAUD_FlipSCREEN_0
	add.l	GOURAUD_ScreenSIZE,D0
	move.l	D0,GOURAUD_FlipSCREEN_1
	
	; * 2.1.4. - Save DeskTOP Screen ****************

	; Ecran Physique du GEM

	move.w	#2,-(SP)
	TRAP	#14	;Physbase
	addq.w	#2,SP

	move.l	D0,GOURAUD_DesktopSCREEN

	; * 2.1.5. - Save DeskTOP VideoMODE *************

	; Sauve le Mode Vid�o

	move.w	#-$1,-(SP)
	move.w	#$58,-(SP)
	TRAP	#14	;Vsetmode
	addq.l	#4,SP

	move.w	D0,GOURAUD_DesktopMODE

	; * 2.1.6. - Wait the Next VBL ******************

	; On attend

	move.w	#$25,-(SP)
	TRAP	#14	;Vsync
	addq.l	#2,SP

	; * 2.1.7. - Change both Resolution and Screens *

	; Nouveaux Ecrans

	move.w	GOURAUD_ScreenMODE,-(SP)
	move.w	#3,-(SP)
	move.l	GOURAUD_FlipSCREEN_0,-(SP)
	move.l	GOURAUD_FlipSCREEN_0,-(SP)
	move.w	#5,-(SP)
	TRAP	#14	;Setscreen
	lea	(14,SP),SP

	; * 2.1.8. - Set BorderCOLOR to BLACK ***********

	; Couleur de Fond NOIRE

	clr.l	$FFFF9800	;falcpal0

	RTS

; -----------------------------------------------------------------------------

	; *** 2.2. Clear the Screens ********************
	; *		*
	; * Nothing realy difficult there. I will JUST  *
	; * Fill the both Screens previously allocated  *
	; * with an Unique Color.	*
	; *		*
	; ***********************************************


GOURAUD_ClearSCREEN	; Efface les Ecrans

	movem.l	GOURAUD_FlipSCREEN_0,A0-A1
	move.l	GOURAUD_ScreenSIZE,D0
	divu.l	#32,D0:D0
	subq.l	#1,D0

	; 16 LONGs : 32 BYTEs

GOURAUD_ClearLOOP	move.w	#FILL,(A0)+
	move.w	#FILL,(A1)+

	move.w	#FILL,(A0)+
	move.w	#FILL,(A1)+

	move.w	#FILL,(A0)+
	move.w	#FILL,(A1)+

	move.w	#FILL,(A0)+
	move.w	#FILL,(A1)+

	move.w	#FILL,(A0)+
	move.w	#FILL,(A1)+

	move.w	#FILL,(A0)+
	move.w	#FILL,(A1)+

	move.w	#FILL,(A0)+
	move.w	#FILL,(A1)+

	move.w	#FILL,(A0)+
	move.w	#FILL,(A1)+

	move.w	#FILL,(A0)+
	move.w	#FILL,(A1)+

	move.w	#FILL,(A0)+
	move.w	#FILL,(A1)+

	move.w	#FILL,(A0)+
	move.w	#FILL,(A1)+

	move.w	#FILL,(A0)+
	move.w	#FILL,(A1)+

	move.w	#FILL,(A0)+
	move.w	#FILL,(A1)+

	move.w	#FILL,(A0)+
	move.w	#FILL,(A1)+

	move.w	#FILL,(A0)+
	move.w	#FILL,(A1)+

	move.w	#FILL,(A0)+
	move.w	#FILL,(A1)+

	DBF	D0,GOURAUD_ClearLOOP

	RTS

; -----------------------------------------------------------------------------

	; *** 2.3. Precalculation of some Tables ********
	; *		*
	; * Instead of RealTIME Calculation, because    *
	; * a 68030 @ 16 MHz is - SADLY - hardly enough *
	; * for the Huge work necessary for the 3D Rout *
	; * and the GouraudSHADING Algorythm, I'll use  *
	; * some Tricky PrecaluclatedTABLES.            *
	; *		*
	; * 2.3.1. - Complete 1.5 Loop Sin/CosTABLE	*
	; * 2.3.2. - Linear *6 TABLE	*
	; * 2.3.3. - L0029		*
	; * 2.3.4. - Linear *640 TABLE	*
	; *		*
	; ***********************************************

GOURAUD_PreCALCULATION	; * 2.3.1. - Complete 1.5 Loop Sin/CosTABLE *****

	lea	GOURAUD_CoSinBANK,A0
	lea	GOURAUD_CoSinTABLE,A1

	movem.w	(A0)+,D0-D2

	fmove.w	D1,FP0
	fmove.w	D2,FP1
	fdiv.x	FP1,FP0
	fmove.w	#180,FP1
	fdiv.x	FP1,FP0
	fmovecr.x	#0,FP1	; PI
	fmul.x	FP1,FP0

	fmovecr.x	#15,FP1	; 0
	fmove.w	#256,FP2

GOURAUD_CalcSinTABLE	fmove.x	FP1,FP3

	fsin.x	FP3

	fmul.x	FP2,FP3	; 256

	fmove.w	FP3,(A1)+

	fadd.x	FP0,FP1

	DBF	D0,GOURAUD_CalcSinTABLE

	; * 2.3.2. - Linear *6 TABLE ********************

	lea	GOURAUD_Lin6TABLE,A0

	move.w	#199,D0

GOURAUD_CalcLinearSIX	move.w	D0,D1
	mulu.w	#6,D1

	move.w	D1,(A0,D0.w*2)

	DBF	D0,GOURAUD_CalcLinearSIX

	; * 2.3.3. - L0029 ******************************

	lea	L0029_BANK,A0
	lea	L0029,A1

	movem.w	(A0)+,D0-D1

GOURAUD_InitL0029	move.w	D1,D2
	movem.w	(A0)+,D3-D5

GOURAUD_CalcL0029	move.w	D3,(A1)+
	add.w	D4,D3
	move.w	D3,(A1)+
	add.w	D4,D3

	add.w	D5,D3

	DBF	D2,GOURAUD_CalcL0029
	
	DBF	D0,GOURAUD_InitL0029

	; * 2.3.4. - Linear *640 TABLE ******************

	lea	GOURAUD_Linear640TABLE,A0

	move.l	#199,D0
	move.l	#$280,D1
	clr.l	D2

GOURAUD_CalcLinear640	move.l	D2,(A0)+
	add.l	D1,D2

	DBF	D0,GOURAUD_CalcLinear640

	RTS

; -----------------------------------------------------------------------------

	; *** 2.4. Main Loop of the Demo ****************
	; *		*
	; * 2.4.1. + Swap Screens	*
	; * 2.4.2. - Invert X Table	*
	; * 2.4.3. + Calc Shape's 3D Coordinates	*
	; * 2.4.4. + Fill Shape's Faces	*
	; * 2.4.5. + Mask Shape's Previous Faces	*
	; * 2.4.6. - Change View Coordinates	*
	; * 2.4.7. - Check the SpaceBAR	*
	; *		*
	; ***********************************************

GOURAUD_MainLOOP	; * 2.4.1. + Swap Screens ***********************

	BSR	GOURAUD_SwapSCREEN

	; * 2.4.2. - Invert X Table *********************

	lea	L0023,A0
	movem.l	(A0),D0-D3
	move.l	D3,(A0)+
	move.l	D2,(A0)+
	move.l	D0,(A0)+
	move.l	D1,(A0)+

	; * 2.4.3. + Calc Shape's 3D Coordinates ********

	BSR	GOURAUD_CalcSHAPE

	; * 2.4.4. + Fill Shape's Faces *****************

	BSR	GOURAUD_FillSHAPE

	; * 2.4.5. + Mask Shape's Previous Faces ********

	BSR	GOURAUD_MaskSHAPE

	; * 2.4.6. - Change View Coordinates ************

	addq.b	#3,GOURAUD_AXIS_X+1
	addq.b	#2,GOURAUD_AXIS_Y+1
	addq.b	#1,GOURAUD_AXIS_Z+1

	; * 2.4.7. - Check the SpaceBAR *****************

	cmpi.b	#$39,$FFFFFC02.w	;keybd
	BNE	GOURAUD_MainLOOP

	RTS

; ----    ---------------------------------------------------------------------

	; *** 2.4.1. Swap Screens ***********************
	; *		*
	; * 2.4.1.1. - Wait the Next VBL	*
	; * 2.4.1.2. - Flip Screens Addresses	*
	; * 2.4.1.3. - Set the New Screen	*
	; *		*
	; ***********************************************

GOURAUD_SwapSCREEN	; * 2.4.1.1. - Wait the Next VBL ****************

	move.w	#$25,-(SP)
	TRAP	#14	;Vsync
	addq.w	#2,SP

	; * 2.4.1.2. - Flip Screens Addresses ***********
	
	movem.l	GOURAUD_FlipSCREEN_0,D0-D1
	exg	D1,D0
	movem.l	D0-D1,GOURAUD_FlipSCREEN_0

	; * 2.4.1.3. - Set the New Screen ***************
	
	move.w	#-1,-(SP)
	move.l	D1,-(SP)
	move.l	D1,-(SP)
	move.w	#5,-(SP)
	TRAP	#14	;Setscreen
	lea	(12,SP),SP

	RTS

; -----------------------------------------------------------------------------

	; *** 2.5. Restore the Saved State **************
	; *		*
	; * 2.5.1. - Restore both Resolution and Screen *
	; * 2.5.2. - Set BorderCOLOR to WHITE	*
	; * 2.5.3. - Free the Screens of the Demo	*
	; *		*
	; ***********************************************

GOURAUD_Restore	; * 2.5.1. - Restore both Resolution and Screen *
	
	move.w	GOURAUD_DesktopMODE,-(SP)
	move.w	#3,-(SP)
	move.l	GOURAUD_DesktopSCREEN,-(SP)
	move.l	GOURAUD_DesktopSCREEN,-(SP)
	move.w	#5,-(SP)
	TRAP	#14	;Setscreen
	lea	(14,SP),SP

	; * 2.5.2. - Set BorderCOLOR to WHITE ***********

	move.l	#-1,$FFFF9800	;falcpal0

	; * 2.5.3. - Free the Screens of the Demo *******

	; Lib�ration des Ecrans

	move.l	GOURAUD_ScreenMEMORY,-(SP)
	move.w	#$49,-(SP)	; - M_FREE -
	TRAP	#1	; *** GEMDOS ***
	addq.l	#6,SP

	RTS

; -----------------------------------------------------------------------------
; *** The 3D Routines *********************************************************
; -----------------------------------------------------------------------------

; *** 3D Routines *******************************************************
; *			*
; *			*
; ***********************************************************************

; ----    ---------------------------------------------------------------------

GOURAUD_CalcSHAPE	lea	GOURAUD_AXIS_BANK,A0
	lea	L003F,A1

	lea	GOURAUD_CoSinTABLE,A2	; sin 000/090
	lea	(64*2,A2),A6	; cos 000/090

	lea	(6,A0),A4	; rX-rY-rZ
	lea	(12,A0),A3	; pDATA

	move.w	(A3)+,D6	; NbPoint
	move.w	D6,D7
	subq.w	#1,D7	; Loopa

	; D6*6
	move.w	(GOURAUD_Lin6TABLE.l,D6.w*2),D6
	lea	(A3,D6.w),A5	; ->Point

T_796	move.w	(A5)+,(A1)	; cX
	movem.w	(A5)+,D0-D1	; cY-cZ
	movem.w	D0-D1,(2,A1)	; cY-cZ

	move.w	(A4),D6	; rX
	move.w	(A2,D6.w*2),D4	; sin rX
	move.w	(A6,D6.w*2),D5	; cos rX

	move.w	D0,D2	; cY
	move.w	D1,D3	; cZ

	muls.w	D5,D0	; cY cos rX
	muls.w	D5,D1	; cZ cos rX
	muls.w	D4,D2	; cY sin rX
	muls.w	D4,D3	; cZ sin rX

	sub.l	D3,D0	; (cY cos rX)-(cZ sin rX)
	add.l	D2,D1	; (cZ cos rX)+(cY sin rX)

	asr.l	#8,D0	; /256
	asr.l	#8,D1	; /256

	movem.w	D0-D1,(2,A1)	; cxY-cxZ

	; ---

	move.w	(A1),D0	; cX

	move.w	(2,A4),D6	; rY
	move.w	(A2,D6.w*2),D4	; sin rY
	move.w	(A6,D6.w*2),D5	; cos rY

	move.w	D0,D2	; cX

	muls.w	D5,D1	; cxZ cos rY
	muls.w	D4,D2	; cX sin rY

	add.l	D2,D1	; (cxZ cos rY)+(cX sin rY)
	asr.l	#8,D1	; /256

	neg.w	D1
	BPL	T_7E6

	clr.w	D1

T_7E6	move.w	D1,(A1)+
	move.w	(A3)+,(A1)
	movem.w	(A3)+,D0-D1
	movem.w	D0-D1,(2,A1)

	move.w	(A4),D6
	move.w	(A2,D6.w*2),D4
	move.w	(A6,D6.w*2),D5

	move.w	D0,D2
	move.w	D1,D3

	muls.w	D5,D0
	muls.w	D5,D1
	muls.w	D4,D2
	muls.w	D4,D3

	sub.l	D3,D0
	add.l	D2,D1
	asr.l	#8,D0
	asr.l	#8,D1

	movem.w	D0-D1,(2,A1)
	move.w	(A1),D0
	move.w	(2,A4),D6
	move.w	(A2,D6.w*2),D4
	move.w	(A6,D6.w*2),D5

	move.w	D0,D2
	move.w	D1,D3

	muls.w	D5,D0
	muls.w	D5,D1
	muls.w	D4,D2
	muls.w	D4,D3

	sub.l	D3,D0
	add.l	D2,D1
	asr.l	#8,D0
	asr.l	#8,D1

	move.w	D0,(A1)
	move.w	D1,4(A1)
	move.w	(2,A1),D1
	move.w	(4,A4),D6
	move.w	(A2,D6.w*2),D4
	move.w	(A6,D6.w*2),D5

	move.w	D0,D2
	move.w	D1,D3

	muls.w	D5,D0
	muls.w	D5,D1
	muls.w	D4,D2
	muls.w	D4,D3

	sub.l	D3,D0
	add.l	D2,D1
	asr.l	#8,D0
	asr.l	#8,D1

	move.w	(4,A1),D2

	add.w	(A0),D0
	add.w	(2,A0),D1
	add.w	(4,A0),D2

	ext.l	D0
	ext.l	D1
	ext.l	D2

	asl.l	#8,D0
	asl.l	#8,D1

	divsl.l	D2,D0:D0
	divsl.l	D2,D1:D1

	addi.w	#160,D0
	addi.w	#100,D1

	movem.w	D0-D1,(A1)
	addq.w	#4,A1

	DBF	D7,T_796	; Loopa

	RTS

; -----------------------------------------------------------------------------

GOURAUD_FillSHAPE	lea	GOURAUD_AXIS_BANK,A0
	lea	L003F,A3

	lea	(12,A0),A0	; pDATA

	move.w	(A0)+,D6
	move.w	D6,D7

	add.w	D6,D6
	add.w	D7,D6
	add.w	D6,D6

	move.w	D6,D7
	add.w	D7,D7

	lea	(A0,D7.w),A2
	lea	(A0,D6.w),A4

	move.w	(A2)+,L0037
	move.w	#1,L0006

	move.w	(A2)+,L0038
	move.w	(A2),D0

	lsl.w	#1,D0
	add.w	(A2)+,D0
	lsl.w	#1,D0

	move.w	(A3,D0.w),D4
	movem.w	(2,A3,D0.w),D0-D1

	move.w	D1,D6
	move.w	D1,D7

	movea.l	L0023,A0

	move.w	D1,(A0)+
	move.w	D1,(A0)+

	BRA	L0008

T_432	move.w	(A2)+,L0038
	move.w	(A2),D0
	lsl.w	#1,D0
	add.w	(A2)+,D0
	lsl.w	#1,D0
	move.w	(A3,D0.w),D4
	movem.w	(2,A3,D0.w),D0-D1
	move.w	D1,D6
	move.w	D1,D7

L0008	move.w	(A2)+,D2
	move.w	(GOURAUD_Lin6TABLE.l,D2.w*2),D2

	move.w	(A3,D2.w),D5
	BPL	T_460

	moveq.l	#0,D5

T_460	movem.w	(2,A3,D2.w),D2/D3

	cmp.w	D3,D6
	BLT	T_46C

	move.w	D3,D6

T_46C	cmp.w	D3,D7
	BGT	T_472

	move.w	D3,D7

T_472	movem.w	D2/D3/D5,-(SP)

	BSR	T_4B6

	movem.w	(SP)+,D0-D1/D4

	subq.w	#1,L0038
	BPL	L0008

	movem.w	D6/D7,L000F
	move.w	(A2)+,D0

	sub.w	D6,D7
	BEQ	T_4A8

	subq.w	#1,D7
	lsl.w	#7,D0
	lea	(L0029.l,D0.w),A0
	movea.l	GOURAUD_FlipSCREEN_0,A6

	BSR	T_508

T_4A8	subq.w	#1,L0037
	BPL	T_432

T_4B4	RTS

; ---

T_4B6	lea	L0031,A0
	lea	L0032,A1

	cmp.w	D1,D3
	BGT	T_4D2
	BEQ	T_4B4

	exg	D0,D2
	exg	D1,D3
	exg	D4,D5

	addq.w	#2,A0
	addq.w	#2,A1

T_4D2	sub.w	D0,D2
	sub.w	D1,D3
	sub.w	D4,D5

	lsl.w	#2,D1

	adda.w	D1,A0
	adda.w	D1,A1

	ext.l	D3

	swap	D2
	divsl.l	D3,D2:D2

	swap	D5
	divsl.l	D3,D5:D5

L0009	move.w	D0,(A0)+

	swap	D0
	add.l	D2,D0

	swap	D0
	addq.w	#2,A0

	move.w	D4,(A1)+

	swap	D4
	add.l	D5,D4

	swap	D4
	addq.w	#2,A1

	DBF	D3,L0009

T_506	RTS

; ---

T_508	move.l	(GOURAUD_Linear640TABLE.l,D6.w*4),D0
	adda.l	D0,A6
	lea	(L0031.l,D6.w*4),A1

L000A	movem.w	(800,A1),D2/D3
	movem.w	(A1)+,D0-D1
	lea	(A6,D0.w*2),A5

	sub.w	D0,D1
	BEQ	T_5E0
	BMI	T_506

	ext.l	D1
	sub.w	D2,D3
	swap	D3
	clr.w	D3
	divsl.l	D1,D3:D3
	move.w	D1,D0
	lsr.w	#5,D1
	andi.w	#$1F,D0
	lsl.w	#2,D0
	neg.w	D0
	swap	D2
	move.w	#$8000,D2

	add.w	D3,D2
	swap	D2
	swap	D3

	JMP	(L000C.l,D0.w)

L000B	move.w	D2,(A5)+
	addx.l	D3,D2

	move.w	D2,(A5)+
	addx.l	D3,D2

	move.w	D2,(A5)+
	addx.l	D3,D2

	move.w	D2,(A5)+
	addx.l	D3,D2

	move.w	D2,(A5)+
	addx.l	D3,D2

	move.w	D2,(A5)+
	addx.l	D3,D2

	move.w	D2,(A5)+
	addx.l	D3,D2

	move.w	D2,(A5)+
	addx.l	D3,D2

	move.w	D2,(A5)+
	addx.l	D3,D2

	move.w	D2,(A5)+
	addx.l	D3,D2

	move.w	D2,(A5)+
	addx.l	D3,D2

	move.w	D2,(A5)+
	addx.l	D3,D2

	move.w	D2,(A5)+
	addx.l	D3,D2

	move.w	D2,(A5)+
	addx.l	D3,D2

	move.w	D2,(A5)+
	addx.l	D3,D2

	move.w	D2,(A5)+
	addx.l	D3,D2

	move.w	D2,(A5)+
	addx.l	D3,D2

	move.w	D2,(A5)+
	addx.l	D3,D2

	move.w	D2,(A5)+
	addx.l	D3,D2

	move.w	D2,(A5)+
	addx.l	D3,D2

	move.w	D2,(A5)+
	addx.l	D3,D2

	move.w	D2,(A5)+
	addx.l	D3,D2

	move.w	D2,(A5)+
	addx.l	D3,D2

	move.w	D2,(A5)+
	addx.l	D3,D2

	move.w	D2,(A5)+
	addx.l	D3,D2

	move.w	D2,(A5)+
	addx.l	D3,D2

	move.w	D2,(A5)+
	addx.l	D3,D2

	move.w	D2,(A5)+
	addx.l	D3,D2

	move.w	D2,(A5)+
	addx.l	D3,D2

	move.w	D2,(A5)+
	addx.l	D3,D2

	move.w	D2,(A5)+
	addx.l	D3,D2

	move.w	D2,(A5)+
	addx.l	D3,D2

L000C	DBF	D1,L000B

T_5E0	lea	(640,A6),A6

	DBF	D7,L000A

	movem.w	L000F,D6/D7
	movea.l	L0023,A0
	lea	L0031,A6
	movem.w	(A0)+,D4/D5

	BSR	L0013

	movem.w	L000F,D6/D7
	movea.l	L0023,A0
	movem.w	(A0),D4/D5

	cmp.w	D6,D4
	BLE	L000D

	move.w	D6,D4

L000D	cmp.w	D5,D7
	BLE	L000E

	move.w	D7,D5

L000E	movem.w	D4/D5,(A0)

	RTS

; ---

L000F	ds.l	1

L0010	clr.w	L0006
	movem.w	D6/D7,-$4(A0)
	lea	(A0,D6.w*4),A0
	lea	(A6,D6.w*4),A6
	sub.w	D6,D7

L0011	move.l	(A6)+,(A0)+

	DBRA	D7,L0011

L0012	RTS

; ---

L0013	cmp.w	D6,D7
	BLE	L0012

	tst.w	L0006
	BNE	L0010

	cmp.w	D4,D6
	BGE	L0014

	cmp.w	D7,D4
	BGE	L0015

	cmp.w	D5,D7
	BGE	L001B

	BRA	L001C

L0014	cmp.w	D5,D6
	BGE	L0015

	cmp.w	D5,D7
	BGE	L0016

	BRA	L0017

L0015	lea	(A0,D6.w*4),A0
	lea	(A6,D6.w*4),A6
	sub.w	D6,D7

	subq.w	#1,D7
	BLT	T_68A

T_684	move.l	(A6)+,(A0)+

	DBF	D7,T_684

T_68A	RTS

; ---

L0016	lea	(A0,D6.w*4),A0
	lea	(A6,D6.w*4),A6

	move.w	D5,D4
	sub.w	D6,D5

	subq.w	#1,D5
	BLT	T_6B4

T_69C	move.w	(A6)+,D1

	cmp.w	(A0),D1
	BLE	T_6A4

	move.w	(A0),D1

T_6A4	move.w	D1,(A0)+
	move.w	(A6)+,D1

	cmp.w	(A0),D1
	BGE	T_6AE

	move.w	(A0),D1

T_6AE	move.w	D1,(A0)+

	DBF	D5,T_69C

T_6B4	sub.w	D4,D7

	subq.w	#1,D7
	BLT	T_6C0

T_6BA	move.l	(A6)+,(A0)+

	DBF	D7,T_6BA

T_6C0	RTS

; ---

L0017	lea	(A0,D6.w*4),A0
	lea	(A6,D6.w*4),A6
	sub.w	D6,D7

	subq.w	#1,D7
	BLT	T_6E8

L0018	move.w	(A6)+,D1

	cmp.w	(A0),D1
	BLE	L0019

	move.w	(A0),D1

L0019	move.w	D1,(A0)+
	move.w	(A6)+,D1

	cmp.w	(A0),D1
	BGE	L001A

	move.w	(A0),D1

L001A	move.w	D1,(A0)+

	DBF	D7,L0018

T_6E8	RTS

; ---

L001B	lea	(A0,D6.w*4),A0
	lea	(A6,D6.w*4),A6

	move.w	D4,D0
	sub.w	D6,D0

	subq.w	#1,D0
	BLT	T_702

T_6FA	move.l	(A6)+,(A0)+

	DBF	D0,T_6FA

	sub.w	D5,D7

T_702	sub.w	D4,D5

	subq.w	#1,D5
	BLT	T_720

T_708	move.w	(A6)+,D1

	cmp.w	(A0),D1
	BLE	T_710

	move.w	(A0),D1

T_710	move.w	D1,(A0)+
	move.w	(A6)+,D1

	cmp.w	(A0),D1
	BGE	T_71A

	move.w	(A0),D1

T_71A	move.w	D1,(A0)+

	DBF	D5,T_708

T_720	subq.w	#1,D7
	BLT	T_72A

T_724	move.l	(A6)+,(A0)+

	DBF	D7,T_724

T_72A	RTS

; ---

L001C	lea	(A0,D6.w*4),A0
	lea	(A6,D6.w*4),A6

	move.w	D4,D0
	sub.w	D6,D0

	subq.w	#1,D0
	BLT	L001E

L001D	move.l	(A6)+,(A0)+

	DBF	D0,L001D

L001E	sub.w	D4,D7

	subq.w	#1,D7
	BLT	L0022

L001F	move.w	(A6)+,D1

	cmp.w	(A0),D1
	BLE	L0020

	move.w	(A0),D1

L0020	move.w	D1,(A0)+
	move.w	(A6)+,D1

	cmp.w	(A0),D1
	BGE	L0021

	move.w	(A0),D1

L0021	move.w	D1,(A0)+

	DBF	D7,L001F

L0022	RTS

; -----------------------------------------------------------------------------

GOURAUD_MaskSHAPE	movea.l	L0024,A0
	movea.l	L0023,A1
	movem.w	(A0)+,D4/D5

	tst.w	D4
	BEQ	GOURAUD_ClearEND

	movem.w	(A1)+,D6/D7

	tst.w	D6
	BEQ	GOURAUD_ClearEND

	cmp.w	D4,D6
	BLE	T_30C

	move.w	D6,D1
	lea	(A0,D4.w*4),A2
	sub.w	D4,D1
	move.l	(GOURAUD_Linear640TABLE.l,D4.w*4),D4
	movea.l	GOURAUD_FlipSCREEN_0,A5
	adda.l	D4,A5

T_2F0	move.w	(A2)+,D4
	lea	(A5,D4.w*2),A4

	sub.w	(A2)+,D4
	BGE	T_304

	addq.w	#1,D4
	neg.w	D4

T_2FE	move.w	#FILL,(A4)+

	DBF	D4,T_2FE

T_304	lea	(640,A5),A5

	DBF	D1,T_2F0

T_30C	cmp.w	D5,D7
	BLE	T_35C

	lea	(A0,D6.w*4),A2
	lea	(A1,D6.w*4),A3
	sub.w	D6,D5
	move.l	(GOURAUD_Linear640TABLE.l,D6.w*4),D6
	movea.l	GOURAUD_FlipSCREEN_0,A5
	adda.l	D6,A5

L0004	move.w	(A2)+,D0
	move.w	(A3)+,D1
	sub.w	D0,D1

	subq.w	#1,D1
	BLT	T_33E

	lea	(A5,D0.w*2),A4

T_338	move.w	#FILL,(A4)+

	DBF	D1,T_338

T_33E	move.w	(A2)+,D1
	move.w	(A3)+,D0
	sub.w	D0,D1

	subq.w	#1,D1
	BLT	T_352

	lea	(A5,D0.w*2),A4

L0005	move.w	#FILL,(A4)+

	DBF	D1,L0005

T_352	lea	(640,A5),A5

	DBF	D5,L0004

GOURAUD_ClearEND	RTS

; ---

T_35C	move.w	D6,D2
	move.w	D7,D3
	lea	(A0,D6.w*4),A2
	lea	(A1,D6.w*4),A3
	sub.w	D2,D3
	move.l	(GOURAUD_Linear640TABLE.l,D2.w*4),D2
	movea.l	GOURAUD_FlipSCREEN_0,A5
	adda.l	D2,A5

T_37A	move.w	(A2)+,D0
	move.w	(A3)+,D1
	sub.w	D0,D1

	subq.w	#1,D1
	BLT	T_38E

	lea	(A5,D0.w*2),A4

T_388	move.w	#FILL,(A4)+

	DBF	D1,T_388

T_38E	move.w	(A2)+,D1
	move.w	(A3)+,D0
	sub.w	D0,D1

	subq.w	#1,D1
	BLT	T_3A2

	lea	(A5,D0.w*2),A4

T_39C	move.w	#FILL,(A4)+

	DBF	D1,T_39C

T_3A2	lea	(640,A5),A5

	DBF	D3,T_37A

	lea	(A0,D7.w*4),A2
	sub.w	D7,D5
	move.l	(GOURAUD_Linear640TABLE.l,D7.w*4),D7
	movea.l	GOURAUD_FlipSCREEN_0,A5
	adda.l	D7,A5

T_3C2	move.w	(A2)+,D7
	lea	(A5,D7.w*2),A4

	sub.w	(A2)+,D7
	BGE	T_3D6

	addq.w	#1,D7
	neg.w	D7

T_3D0	move.w	#FILL,(A4)+

	DBF	D7,T_3D0

T_3D6	lea	(640,A5),A5

	DBF	D5,T_3C2

	RTS
	
; /////////////////////////////////////////////////////////////////////////////
	SECTION	DATA
; /////////////////////////////////////////////////////////////////////////////

L0023	dc.l	L0033

L0024	dc.l	L0034
	dc.l	L0035
	dc.l	L0036

GOURAUD_CoSinBANK	dc.w	383,90,64	

L0029_BANK	dc.w	6,31
	dc.w	0,0,$800
	dc.w	0,0,$801
	dc.w	0,$20,0
	dc.w	0,$20,$800
	dc.w	0,0,1
	dc.w	$1F,$20,$800
	dc.w	0,$20,$801

GOURAUD_AXIS_BANK	dc.b	0,0,0,0,3,$EA

GOURAUD_AXIS_X	dc.w	$20
GOURAUD_AXIS_Y	dc.w	$20
GOURAUD_AXIS_Z	dc.w	0

	; +12

GOURAUD_OBJECT_DATA	dc.w	8	; NbPoint

	dc.w	-200,-200,-200	; cX-cY-cZ
	dc.w	200,-200,-200
	dc.w	200,200,-200
	dc.w	-200,200,-200
	dc.w	-200,-200,200
	dc.w	200,-200,200
	dc.w	200,200,200
	dc.w	-200,200,200

	dc.w	-18,-18,-17
	dc.w	18,-18,-17
	dc.w	18,18,-17
	dc.w	-18,18,-17
	dc.w	-18,-18,17
	dc.w	18,-17,18
	dc.w	18,18,17
	dc.w	-18,17,18

	dc.w	5,3,0
	dc.w	3,2,1
	dc.w	0,0,3
	dc.w	0,1,5
	dc.w	4,0,1
	dc.w	3,1,2
	dc.w	6,5,1
	dc.w	2,3,2

	dc.w	3,7,6
	dc.w	2,3,3
	dc.w	0,4,7
	dc.w	3,0,4
	dc.w	3,4,5
	dc.w	6,7,4,5
	
; /////////////////////////////////////////////////////////////////////////////
	SECTION	BSS
; /////////////////////////////////////////////////////////////////////////////

GOURAUD_DesktopMODE	ds.w	1
GOURAUD_DesktopSCREEN	ds.l	2

GOURAUD_ScreenMODE	ds.w	1
GOURAUD_ScreenSIZE	ds.l	1

L0006	ds.w	1

L0031	ds.l	200
L0032	ds.l	200

L0033	ds.l	201
L0034	ds.l	201
L0035	ds.l	201
L0036	ds.l	201

L0037	ds.w	1
L0038	ds.w	1

GOURAUD_ScreenMEMORY	ds.b	1
GOURAUD_FlipSCREEN_0	ds.l	1
GOURAUD_FlipSCREEN_1	ds.l	1

L003F	ds.l	114

GOURAUD_CoSinTABLE	ds.w	6*64
	; DIM VTAB&(64)
	; FOR A&=V1& TO 63*V1& STEP V2&
	;   VTAB&(A&)=INT(SIN(A&*(VC&/VD&))*256)*V3&
	; NEXT A&

GOURAUD_Lin6TABLE	ds.w	200
	; DIM VTAB&(200)
	; FOR A&=0 TO 199
	;   VTAB&(A&)=A&*6
	; NEXT A&

L0029	ds.w	7*64
	; DIM VTAB&(64)
	; VX&=V1&
	; FOR A&=0 TO 31
	;   VTAB&(A&)=VX&
	;   VX&=+V2&
	;   VTAB&(A&+1)=VX&
	;   VX&=+V2&
	;   VX&=+V3&
	; NEXT A&

GOURAUD_Linear640TABLE	ds.l	200
	; DIM GOURAUD_Linear640TABLE(200)
	; FOR A%=0 to 199
	;   GOURAUD_Linear640TABLE(A%)=A%*640
	; NEXT A%
