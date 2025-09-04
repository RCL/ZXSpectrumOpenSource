	device ZXSPECTRUM128

; desktop - 8
; projector - 32?
EYE_OFFSET				EQU 8
RIGHT_EYE_OFFSET		EQU -EYE_OFFSET		; sbc
LEFT_EYE_OFFSET			EQU EYE_OFFSET		; adc

USE_70CYCLE_PLOT		EQU 1
USE_RAXOFT_RANDOM		EQU 1

; how many particles are there
NUM_PARTICLES			EQU 12

; how long traces the particles leave (in terms of previous positions). Each position needs space for NUM_PARTICLES triplets
TRAIL_LENGTH			EQU 5

; length of history in triplets of (ScrX, ScrY, Size)
HISTORY_LENGTH			EQU TRAIL_LENGTH * NUM_PARTICLES

; what is the size of a particle in 3D (will be perspectively smaller)
PARTICLE_SIZE			EQU 5 * 256

NO_MUSIC				EQU 0
PROFILE_FRAME			EQU 0

LeftEyeFloorBuffer		EQU $6000
RightEyeFloorBuffer		EQU $6800

	STRUCT	Particle
X			dw 0
Y			dw 0
AddZ		dw 0
Z			dw 0
	ENDS

	MACRO UpdateRegAValueE
		ld bc, #fffd
		out (c), a
		ld b, #bf
		out (c), e
	ENDM

	MACRO GetValueFromBCAndUpdateRegA
		ex af, af'
		ld a, (bc)
		inc bc
		ld e, a
		ex af, af'
		push bc
		UpdateRegAValueE
		pop bc
	ENDM

	; returns A = A + 2
	MACRO UpdateTwoConsecutiveRegsRegGroup
		ld c, (hl)
		inc hl
		ld b, (hl)

		rr d
		jr nc, .SkipThisRegUpdate	; skip this reg

		GetValueFromBCAndUpdateRegA
		inc a
		GetValueFromBCAndUpdateRegA
		dec a

		ld (hl), b
		dec hl
		ld (hl), c

		inc hl
.SkipThisRegUpdate
		inc hl
		inc a
		inc a
	ENDM

	; returns A == 6
	MACRO UpdateRegs_4_5_10_RegGroup
		ld c, (hl)
		inc hl
		ld b, (hl)

		rr d
		jr nc, .SkipThisRegUpdate	; skip this reg

		GetValueFromBCAndUpdateRegA
		inc a
		GetValueFromBCAndUpdateRegA
		ld a, 10
		GetValueFromBCAndUpdateRegA
		ld a, 4

		ld (hl), b
		dec hl
		ld (hl), c

		inc hl
.SkipThisRegUpdate
		inc hl
		inc a
		inc a
	ENDM

	MACRO UpdateNextReg
		ld c, (hl)
		inc hl
		ld b, (hl)

		rr d
		jr nc, .SkipThisRegUpdate	; skip this reg

		GetValueFromBCAndUpdateRegA

		ld (hl), b
		dec hl
		ld (hl), c

		inc hl
.SkipThisRegUpdate
		inc hl
		inc a
	ENDM

BANKM 	EQU $5b5c

	; pages in a 128K page that is in the A register
	MACRO SetPageInA
		ld (BANKM), a	; BANKM
		ld bc, #7ffd
		out (c), a
	ENDM

	; Inits a particle. HL - pointer to the current particle structure
	; Made a macro so exact same code can be used twice and compress better
	; Keeps HL and B intact

	MACRO InitXCoord
		call rnd_trampo
		ld (hl), a
		inc hl
		rlca
		sbc a, a
		ld (hl), a
		inc hl
	ENDM

	MACRO InitYCoord
		call rnd_trampo
		ld e, a
		rlca
		sbc a, a
		ld d, a
		ex de, hl
		ld bc, -2 * 256
		add hl, bc
		ex de, hl
		ld (hl), e
		inc hl
		ld (hl), d
		inc hl
	ENDM

	MACRO InitZCoord
		call rnd_trampo
		and $0f
		inc a
		ld (hl), a
		inc hl
		xor a
		ld (hl), a
		inc hl
		ex de, hl
		ld h, a
		call rnd_trampo
		and $3f
		ld l, a 
		ld bc, -2 * 256
		add hl, bc
		ex de, hl
		ld (hl), e
		inc hl
		ld (hl), d
		inc hl
	ENDM

	MACRO InitParticle
		InitXCoord
		InitYCoord
		InitZCoord
	ENDM

	; hl - pointer to the particle
	MACRO UpdateParticleAndRespawn
		push hl
		; skip x and y
		ld de, 4
		add hl, de

		ld c, (hl)
		inc hl
		ld b, (hl)
		inc hl
		ld e, (hl)
		inc hl
		ld d, (hl)

		ex de, hl
		add hl, bc		; Z += AddZ
		ex de, hl
		; write it back
		ld (hl), d
		dec hl
		ld (hl), e

		ld a, d
		add 2
		cp 5		
		pop hl
		jr c, .NoReinit

		; now that hl again points at the beginning of the particle, reinit it
		InitParticle
		jr .NextParticle
.NoReinit:
		ld de, Particle
		add hl, de
.NextParticle:
	ENDM

	MACRO PlotInlineable
		call XorPlotRoutine_trampo
	ENDM

	MACRO JmpPlotInlineable
		jp XorPlotRoutine_trampo
	ENDM

	MACRO ClearPlotInlineable
		call ClearPlotRoutine_trampo
	ENDM

	MACRO JmpClearPlotInlineable
		jp ClearPlotRoutine_trampo
	ENDM

	; in D, E - X and Y of the central point
	; A - size
	MACRO PlotSizeInlineable
		call PlotSizeRoutine_trampo
	ENDM

	MACRO ClearPlotSizeInlineable
		call ClearPlotSizeRoutine_trampo
	ENDM

	MACRO InitPlotRoutine
		if (USE_70CYCLE_PLOT)
			LD HL,PTY   ;   table location
			LD DE,#C000 ;   main screen
			LD BC,#C020
CR1
	   		LD (HL),D
			DEC H
			LD (HL),E
			INC L
			INC H
			INC D
			LD A,D
			AND 7
			JR NZ,$+12
			LD A,E
			SUB #E0
			LD E,A
			JR NC,$+6
			LD A,D
			SUB 8
			LD D,A
			DJNZ CR1
			LD L, #FF
			DEC H  
			DEC H
CR3    		DEC C
			LD B,8
CR2    		LD (HL),C
			DEC L
			DJNZ CR2
			INC C
			DEC C
			JR NZ,CR3
			DEC H
			INC A
CR4    		LD (HL),A
			RLCA 
			DEC L
			DJNZ CR4
	   	endif
	ENDM

	MACRO ClearBothEyesAndRestoreFloor
		call RenderToLeft_NoOffsetSwitch
		ld hl, $c000
		ld d, h
		ld e, l
		inc de
		ld (hl), l
		ld bc, 4096
		ldir

		call RenderToRight_NoOffsetSwitch
		ld hl, $c000
		ld d, h
		ld e, l
		inc de
		ld (hl), l
		ld bc, 4096
		ldir

		ld hl, RightEyeFloorBuffer
		ld de, $D000
		ld bc, 2048
		ldir

		call RenderToLeft_NoOffsetSwitch
		ld hl, LeftEyeFloorBuffer
		ld de, $D000
		ld bc, 2048
		ldir
	ENDM


	org #80ff	; strategically located to save bytes in the unpacker

savebin_begin:

	xor a
	out (#fe), a

	MACRO SetPageFillScreen Page, ColorValue
		ld a, Page
		SetPageInA

		ld a, ColorValue
		ld bc, 6144
		ld hl, #c000
		ld d, h
		ld e, l
		inc e
		ld (hl), l; $aa ;l
		ldir
		ld bc, 767
		ld (hl), a
		ldir
	ENDM

	SetPageFillScreen $15, $42

	ld a, (RIGHT_EYE_OFFSET)
	ld (EyeOffset), a

	SetPageFillScreen $1f, $41

	InitPlotRoutine
	call InitCosSinTables

	; Intentional pause to give a break from the loading noise (if there will be noise that is)
	if (0)
	ld b, 100
DelayLoop:
	ei
	halt
	djnz DelayLoop
	endif

	; set up IM2 - from this moment the intro is on as we start counting frames.
	di
	ld a, high IRQVectorTable
	ld i,a
	im 2
	ei

	ld hl, 0
	ld (FrameCount), hl

	;jp Shortcut

	; just draw the floor first
	call DrawFloor

	; save this to a buffer as we may need it later
	ld hl, $5000
	ld de, LeftEyeFloorBuffer
	ld bc, 2048
	ldir

	call RenderToRight_NoOffsetSwitch

	ld hl, $D000
	ld de, RightEyeFloorBuffer
	ld bc, 2048
	ldir

	; wait for the music to catch up
	; initial slow music moment
	ld bc, 768
	call WaitFrameBC

DemoLoop:

	ld hl, -256
	ld (DrawForwardLines.ForwardLineX), hl
	ld hl, -2 * 256
	ld (DrawForwardLines.ForwardLineY), hl
	ld hl, -512
	ld (DrawForwardLines.ForwardLineZ), hl

	; draw the lines into the screen
	; draw during both slow and fast music moments after the loop, then wait for the slow one
	ld bc, 3 * 768;	the last frame to draw
	call DrawForwardLines

	; clear screen
	ClearBothEyesAndRestoreFloor

	xor a
	ld (DrawVerticalSpiral.Angle), a
	ld h, a
	ld l, a
	ld (DrawVerticalSpiral.SpiralHeight), hl

	; draw during the slow moment in the music, then wait until it starts to be fast
	ld bc, 4 * 768;	the last frame to draw
	call DrawVerticalSpiral

	; clear screen
	ClearBothEyesAndRestoreFloor

	ld hl, ParticleBuffer
	DUP NUM_PARTICLES
		InitParticle
	EDUP

	ld hl, HistoryLeft
	ld d, h
	ld e, l
	inc de
	ld (hl), l
	ld bc, 255
	ldir

	ld hl, HistoryRight
	ld d, h
	ld e, l
	inc de
	ld (hl), l
	ld bc, 255
	ldir

	xor a
	ld (DrawForwardSpiralAndParticles.Angle), a
	ld hl, -300
	ld (DrawForwardSpiralAndParticles.SpiralDistance), hl

	; draw during both fast and slow moments
	ld bc, 4 * 768 + 384
	call DrawForwardSpiralAndParticles

	ld hl, ParticleBuffer
	DUP NUM_PARTICLES
		InitParticle
	EDUP

	ld bc, 6 * 768
	call DrawForwardSpiralAndParticles

	; clear screen
	ClearBothEyesAndRestoreFloor

;Shortcut:

	xor a
	ld (DrawVerticalConeSpiral.Angle), a
	ld h, a
	ld l, a
	ld (DrawVerticalConeSpiral.SpiralHeight), hl

	ld bc, 7 * 768
	call DrawVerticalConeSpiral

	; clear screen
	ClearBothEyesAndRestoreFloor

;Shortcut:
	ld hl, DT_Y_START
	ld (DrawText.YCoord), hl
	ld hl, DT_X_WIDESTART
	ld (DrawText.XCoord), hl
	ld (DrawText.XCoordRestart), hl
	ld hl, TextParallelVisions
	ld (DrawText.TextHead), hl

	ld bc, 8 * 768	
	call DrawText

	ClearBothEyesAndRestoreFloor

;Shortcut:
	ld hl, DT_Y_START
	ld (DrawText.YCoord), hl
	ld hl, DT_X_TYPICALSTART
	ld (DrawText.XCoord), hl
	ld (DrawText.XCoordRestart), hl
	ld hl, TextCredits
	ld (DrawText.TextHead), hl

	ld bc, 9 * 768	
	call DrawText

	ClearBothEyesAndRestoreFloor

	ld hl, DT_Y_START
	ld (DrawText.YCoord), hl
	ld hl, DT_X_TYPICALSTART
	ld (DrawText.XCoord), hl
	ld (DrawText.XCoordRestart), hl
	ld hl, TextBoast1
	ld (DrawText.TextHead), hl

	ld bc, 9 * 768 + 256;//6912	
	call DrawText

	ClearBothEyesAndRestoreFloor

	ld hl, DT_Y_START
	ld (DrawText.YCoord), hl
	ld hl, DT_X_TYPICALSTART
	ld (DrawText.XCoord), hl
	ld (DrawText.XCoordRestart), hl
	ld hl, TextBoast2
	ld (DrawText.TextHead), hl

	ld bc, 9 * 768 + 2 * 256;//6912	
	call DrawText

	ClearBothEyesAndRestoreFloor

	ld hl, DT_Y_START
	ld (DrawText.YCoord), hl
	ld hl, DT_X_TYPICALSTART
	ld (DrawText.XCoord), hl
	ld (DrawText.XCoordRestart), hl
	ld hl, TextBoast3
	ld (DrawText.TextHead), hl

	ld bc, 10 * 768	
	call DrawText

	ClearBothEyesAndRestoreFloor

	ld hl, DT_Y_START
	ld (DrawText.YCoord), hl
	ld hl, DT_X_TYPICALSTART
	ld (DrawText.XCoord), hl
	ld (DrawText.XCoordRestart), hl
	ld hl, TextBoast4
	ld (DrawText.TextHead), hl

	ld bc, 10 * 768 + 256	
	call DrawText

	ClearBothEyesAndRestoreFloor

	ld hl, DT_Y_START
	ld (DrawText.YCoord), hl
	ld hl, DT_X_TYPICALSTART
	ld (DrawText.XCoord), hl
	ld (DrawText.XCoordRestart), hl
	ld hl, TextDemoWillLoop
	ld (DrawText.TextHead), hl

	ld bc, 11 * 768;	
	call DrawText

	ClearBothEyesAndRestoreFloor

	ld hl, 768
	ld (FrameCount), hl

	jp DemoLoop

; -------------------------------------------------------------------------------------------------------------
; Switch to drawing left eye no matter which one is being shown
RenderToLeft:
	ld bc, $15*256 + LEFT_EYE_OFFSET
	ld a, c
	ld (EyeOffset), a
	ld a, (EyeShown)
	and $08
	or b
	SetPageInA
	ret

; -------------------------------------------------------------------------------------------------------------
; Switch to drawing right eye no matter which one is being shown
RenderToRight:
	ld bc, $18*256 + RIGHT_EYE_OFFSET;	// offset is negative so if we don't use $18 here, we'll end up actually switching to $16
	ld a, c
	ld (EyeOffset), a
	ld a, (EyeShown)
	and $08
	or b
	SetPageInA
	ret

; -------------------------------------------------------------------------------------------------------------
; Switch to drawing left eye no matter which one is being shown, but do not switch the offset
RenderToLeft_NoOffsetSwitch:
	ld b, $15
	ld a, (EyeShown)
	and $08
	or b
	SetPageInA
	ret

; -------------------------------------------------------------------------------------------------------------
; Switch to drawing right eye no matter which one is being shown, but do not switch the offset
RenderToRight_NoOffsetSwitch:
	ld b, $17
	ld a, (EyeShown)
	and $08
	or b
	SetPageInA
	ret

; -------------------------------------------------------------------------------------------------------------
; Waits for a frame in BC
WaitFrameBC:
	ld hl, (FrameCount)
	or a
	sbc hl, bc
	ret nc
	jr WaitFrameBC

; -------------------------------------------------------------------------------------------------------------
; Draws the floor for both eyes at once
DrawFloor:
	ld hl, -3 * 256
.FloorLoopX:
	push hl
	ld bc, -128
.FloorLoopZ:
	push hl
	push bc
	push hl
	push bc

	ld de, 0
	ld a, LEFT_EYE_OFFSET
	call ProjectWithEyeOffset
	jr c, .SkipLeftPlot
	ex af, af'
	call RenderToLeft_NoOffsetSwitch
	ex af, af'
	PlotSizeInlineable

.SkipLeftPlot:

	pop bc
	pop hl
	ld de, 0
	ld a, RIGHT_EYE_OFFSET
	call ProjectWithEyeOffset
	jr c, .SkipRightPlot
	ex af, af'
	call RenderToRight_NoOffsetSwitch
	ex af, af'
	PlotSizeInlineable

.SkipRightPlot
	pop bc
	ld hl, 40
	add hl, bc
	ld b, h
	ld c, l
	pop hl
	ld a, b
	cp 6
	jr nz, .FloorLoopZ

	pop hl
	ld de, 18
	add hl, de
	ld a, h
	cp 3
	jr nz, .FloorLoopX
	ret

; -------------------------------------------------------------------------------------------------------------
; Draws forward lines for both eyes at once until the frame in BC
DrawForwardLines:
	push bc

.ForwardLineX equ $+1
	ld hl, -256

.ForwardLineY equ $+1
	ld de, -2 * 256

.ForwardLineZ equ $+1
	ld bc, -512

	MACRO PlotXYZWithShadowForBothEyes
		push bc
		push hl
		push de

		; first draw the actual line
		ld a, LEFT_EYE_OFFSET
		call ProjectWithEyeOffset
		jr c, .SkipLeftPlot
		ex af, af'
		call RenderToLeft_NoOffsetSwitch
		ex af, af'
		PlotSizeInlineable

.SkipLeftPlot:

		pop de
		pop hl
		pop bc

		push bc
		push hl
		
		ld a, RIGHT_EYE_OFFSET
		call ProjectWithEyeOffset
		jr c, .SkipRightPlot
		ex af, af'
		call RenderToRight_NoOffsetSwitch
		ex af, af'
		PlotSizeInlineable

.SkipRightPlot

		; now draw the shadow (with DE == 0)

		pop hl
		pop bc

		push bc
		push hl

		ld de, 0
		ld a, LEFT_EYE_OFFSET
		call ProjectWithEyeOffset
		jr c, .SkipLeftShadowPlot
		ex af, af'
		call RenderToLeft_NoOffsetSwitch
		ex af, af'
		ClearPlotSizeInlineable

.SkipLeftShadowPlot:

		pop hl
		pop bc

		push bc

		ld de, 0
		ld a, RIGHT_EYE_OFFSET
		call ProjectWithEyeOffset
		jr c, .SkipRightShadowPlot
		ex af, af'
		call RenderToRight_NoOffsetSwitch
		ex af, af'
		ClearPlotSizeInlineable
.SkipRightShadowPlot
		pop hl
	ENDM

	PlotXYZWithShadowForBothEyes
	; increment Z

	ld de, 2
	add hl, de

	ld a, h
	cp 3
	jr nz, .NoLineRestart

	; randomize new X, Y
	; X is -1, 1
	call rnd_trampo
	ld l, a
	ld h, high CosTab
	ld e, (hl)
	inc h
	ld d, (hl)
	ex de, hl
	ld (.ForwardLineX), hl

	; Y is -1, -3
	call rnd_trampo
	ld l, a
	ld h, high SinTab
	ld e, (hl)
	inc h
	ld d, (hl)
	ex de, hl
	; hl is in -1, 1, now we need to move it down to -3, -1
	ld de, -(2 * 256 + 128)
	add hl, de
	ld (.ForwardLineY), hl

	ld hl, -512
.NoLineRestart
	ld (.ForwardLineZ), hl

	pop bc
	ld hl, (FrameCount)
	or a
	sbc hl, bc
	jp c, DrawForwardLines
	ret

; -------------------------------------------------------------------------------------------------------------
; Draws vertical spiral for both eyes at once until the frame in BC
DrawVerticalSpiral:
	push bc

.Angle equ $+1
	ld a, 0
	inc a
	ld (.Angle), a

	ld l, a
	ld h, high SinTab
	ld c, (hl)
	inc h
	ld b, (hl)
	; spiral is of radius 1, so this is Z

	; Z += 64 to offset it somewhat
	ld hl, 64
	add hl, bc
	ld b, h
	ld c, l

	ld l, a
	ld h, high CosTab

	ld e, (hl)
	inc h
	ld d, (hl)
	; spiral is of radius 1, so this is X

.SpiralHeight equ $+1
	ld hl, 0
	dec hl
	ld (.SpiralHeight), hl
	ex de, hl

	PlotXYZWithShadowForBothEyes

	pop bc
	ld hl, (FrameCount)
	or a
	sbc hl, bc
	jp c, DrawVerticalSpiral
	ret

; -------------------------------------------------------------------------------------------------------------
; Draws vertical cone spiral for both eyes at once until the frame in BC
DrawVerticalConeSpiral:
	push bc

.Angle equ $+1
	ld a, 0
	inc a
	ld (.Angle), a

	ld l, a
	ld h, high SinTab
	ld c, (hl)
	inc h
	ld b, (hl)

	ld hl, (.SpiralHeight)
	sra h
	rr l
	sra h
	rr l
	sra h
	rr l
	ld (.Radius), hl
	ex de, hl

	call smul16
	push hl
	pop bc

	; Z += 64 to offset it somewhat
	ld hl, 64
	add hl, bc
	ld b, h
	ld c, l
	push bc

	ld a, (.Angle)
	ld l, a
	ld h, high CosTab

	ld e, (hl)
	inc h
	ld d, (hl)
.Radius equ $+1
	ld bc, 0
	call smul16
	ex de, hl
	pop bc

.SpiralHeight equ $+1
	ld hl, 0
	dec hl
	ld (.SpiralHeight), hl
	ex de, hl

	PlotXYZWithShadowForBothEyes

	pop bc
	ld hl, (FrameCount)
	or a
	sbc hl, bc
	jp c, DrawVerticalConeSpiral
	ret

; -------------------------------------------------------------------------------------------------------------
; Draws forward spiral and particles for both eyes at once until the frame in BC
DrawForwardSpiralAndParticles:
	push bc

.Angle equ $+1
	ld a, 0
	inc a
	ld (.Angle), a

	ld l, a
	ld h, high SinTab
	ld c, (hl)
	inc h
	ld b, (hl)
	; spiral is of radius 1, so this is Y

	; Y -= 400 to offset it somewhat
	ld hl, -480
	add hl, bc
	ld b, h
	ld c, l

	ld l, a
	ld h, high CosTab

	ld e, (hl)
	inc h
	ld d, (hl)
	; spiral is of radius 1, so this is X

.SpiralDistance equ $+1
	ld hl, -300
	inc hl
	ld a, h
	cp 5
	jr nz, .NoDisableCurve
	jr .SkipCurveDrawing
.NoDisableCurve:
	ld (.SpiralDistance), hl
		
	ex de, hl

	; swap Z and Y
	push bc
	push de
	pop bc
	pop de

	PlotXYZWithShadowForBothEyes

.SkipCurveDrawing
	ld hl, ParticleBuffer
	DUP NUM_PARTICLES
		UpdateParticleAndRespawn
	EDUP

	; move left history
	ld de, HistoryLeft
	push de
	ld h, d
	ld l, NUM_PARTICLES * 3
	ld bc, (HISTORY_LENGTH - NUM_PARTICLES) * 3
	assert (HISTORY_LENGTH - NUM_PARTICLES) * 3 < 256
	ldir

	call RenderToLeft

	; clear the trail tails from history
	pop hl
	push hl
	MACRO PlotHistory
		ld e, (hl)
		inc hl
		ld d, (hl)
		inc hl
		ld a, (hl)
		inc hl
		push hl
		call PlotSizeRoutine_trampo
		pop hl
	ENDM
	DUP NUM_PARTICLES
		PlotHistory
	EDUP

	; project and draw the particles, and put their history

	ld iy, ParticleBuffer
	pop ix
	ld ixl, HISTORY_LENGTH * 3 - 1
	MACRO ProjectAndDrawParticle
		ld l, (iy + 0)
		ld h, (iy + 1)
		ld e, (iy + 2)
		ld d, (iy + 3)
		ld c, (iy + 6)
		ld b, (iy + 7)

		call Project_trampo
		jr nc, .NoZeroHistory
		xor a
		ld d, a
		ld e, a
.NoZeroHistory
		; save history
		ld (ix + 0), a
		ld (ix - 1), d
		ld (ix - 2), e

		PlotSizeInlineable

		ld bc, Particle
		add iy, bc
		ld bc, -3
		add ix, bc
	ENDM

	DUP NUM_PARTICLES
		ProjectAndDrawParticle
	EDUP

	; move right history
	ld de, HistoryRight
	push de
	ld h, d
	ld l, NUM_PARTICLES * 3
	ld bc, (HISTORY_LENGTH - NUM_PARTICLES) * 3
	assert (HISTORY_LENGTH - NUM_PARTICLES) * 3 < 256
	ldir

	call RenderToRight

	; clear the trail tails from history
	pop hl
	push hl
	DUP NUM_PARTICLES
		PlotHistory
	EDUP

	; project and draw the particles, and put their history

	ld iy, ParticleBuffer
	pop ix
	ld ixl, HISTORY_LENGTH * 3 - 1
	DUP NUM_PARTICLES
		ProjectAndDrawParticle
	EDUP

	pop bc
	ld hl, (FrameCount)
	or a
	sbc hl, bc
	jp c, DrawForwardSpiralAndParticles
	ret

; -------------------------------------------------------------------------------------------------------------
; Draws text for both eyes at once until the frame in BC
DT_X_STEP	EQU 16
DT_Y_STEP	EQU 16
DT_Y_START	EQU (-3 * 256 -128)
DT_X_TYPICALSTART	EQU (-1 * 256)
DT_X_WIDESTART	EQU (-1 * 256 - 160)
DT_Y_LINE_OFFSET  EQU (10 * DT_Y_STEP)

DrawText:
	push bc

.TextHead equ $+1
	ld hl, TextCredits
.Reread:
	ld a, (hl)
	inc hl
	ld (.TextHead), hl
	and a
	jr nz, .NoTextChange

	push hl

	ld hl, (.YCoord)
	ld de, DT_Y_LINE_OFFSET
	add hl, de
	ld (.YCoord), hl

.XCoordRestart equ $+1
	ld hl, -1 * 256
	ld (.XCoord), hl

	call rnd
	and $1f
	ld h, a
	call rnd
	and $0f
	sub h
	ld (.AngleY), a

	pop hl


	ld a, (hl)
	inc hl
	ld (.TextHead), hl
	and a
	pop bc
	; two 0s means end of print
	jr nz, .NoEndPrint

.EndPrint:
	ld hl, (FrameCount)
	or a
	sbc hl, bc
	jr c, .EndPrint
	ret

.NoEndPrint
	push bc

.NoTextChange
	; get the ROM char using method suggested by LeMIC
	ld hl, $3e08
	sub 'A'
	add a
	add a
	add a
	ld e, a
	ld d, 0
	add hl, de

	push hl
	pop ix

.YCoord equ $+1
	ld de, -3 * 256

	ld b, 8
.YCoordLoop:
	push bc
	push de

.XCoord equ $+1
	ld hl, -1 * 256

	ld a, (ix)
	inc ix
	ld iyl, a
	ld b, 8
.XCoordLoop:
	push bc
	push de
	push hl

	ld bc, 128

	ld a, iyl
	rla
	ld iyl, a
	jp nc, .SkipPixel

	; transform by rotating angle
	push de
	; calc TZ = -X*SinA + Z*CosA + OffsetZ
	; -X*SinA
	push hl
	exx
	pop de
	ld hl, 0
	or a
	sbc hl, de
	ex de, hl	; de holds X

.AngleY equ $+1
	ld hl, SinTab
	ld c, (hl)
	inc h
	ld b, (hl)

	call smul16_trampo
	push hl
	exx

	; Z*CosA
	push bc
	exx
	pop de
	ld a, (.AngleY)
	ld l, a
	ld h, high CosTab
	ld c, (hl)
	inc h
	ld b, (hl)
	call smul16_trampo
	pop de
	add hl, de	; hl = -X*SinA + Z*CosA 
.OffsetZ equ $+1
	ld bc, 0
	add hl, bc	; hl = -X*SinA + Z*CosA + OffsetZ == TZ
	push hl
	exx

	; Calc TX = X*CosA + Z*SinA + EyeOffset
	; X*CosA
	push hl
	exx
	pop de
	ld a, (.AngleY)
	ld l, a
	ld h, high CosTab
	ld c, (hl)
	inc h
	ld b, (hl)
	call smul16_trampo
	push hl
	exx

	; Z*SinA
	push bc
	exx
	pop de
	ld hl, (.AngleY)
	ld c, (hl)
	inc h
	ld b, (hl)
	call smul16_trampo
	; hl = Z*SinA
	pop de ; X*cos a
	add hl, de	; hl = X*CosA + Z*SinA == TX

	pop bc	; TZ
	pop de	; Y

	PlotXYZWithShadowForBothEyes

.SkipPixel:
	pop hl
	ld de, DT_X_STEP
	add hl, de

	pop de
	pop bc
	dec b
	jp nz, .XCoordLoop

	pop hl
	ld de, DT_Y_STEP
	add hl, de
	ex de, hl
	pop bc
	dec b
	jp nz, .YCoordLoop

	ld hl, (.XCoord)
	ld de, 8 * DT_X_STEP
	add hl, de
	ld (.XCoord), hl

	pop bc
	ld hl, (FrameCount)
	or a
	sbc hl, bc
	jp c, DrawText
	ret

TextParallelVisions:
	db "PARALLEL", 0
	db "VISIONS", 0
	db 0

TextCredits:
	db "PATOR", 0
	db "RCL", 0
	db "VVG", 0
	db "OTOMATA", 0
	db 0

TextBoast1:
	db "THIS",0
	db "MIGHT", 0
	db "BE", 0
	db 0

TextBoast2:
	db "THE", 0
	db "FIRST", 0
	db "ANAGLYPH", 0
	db "DEMO", 0
	db 0

TextBoast3:
	db "FOR", 0
	db "THE", 0
	db "SPECCY", 0
	db 0

TextBoast4:
	db "PROVE", 0
	db "US", 0
	db "WRONG", 0
	db 0

TextDemoWillLoop:
	db "INTRO", 0
	db "WILL", 0
	db "NOW", 0
	db "LOOP", 0
	db 0

; -------------------------------------------------------------------------------------------------------------
; Initializes sin and cos tables
InitCosSinTables:
	; honestly calculate the first quorter
	xor a
	ld hl, CosTab
.FirstQuarterCalc
	; CosTab[Idx] = 256 - ((X * X) >> 8);
	push af
	push hl
	add a
	ld l, a
	ld h, 0
	add hl, hl
	ex de, hl
	ld b, d
	ld c, e
	call smul16
	ex de, hl
	ld hl, 256
	or a
	sbc hl, de
	ex de, hl
	pop hl
	ld (hl), e
	inc h
	ld (hl), d
	dec h
	inc hl
	pop af
	inc a
	cp 64
	jr c, .FirstQuarterCalc
	
	; now we're mostly copying it around
	; for next 64 elements,
	; 		CosTab[64 + Idx] = -CosTab[63 - Idx];
	; hl already holds CosTab + 64
	ld d, h
	ld e, l
	dec de
	ld b, 64
.CopySecondCosQuarter:
	push bc
	push de
	ex de, hl
	ld c, (hl)
	inc h
	ld b, (hl)
	dec h
	ld hl, 0
	or a
	sbc hl, bc
	ex de, hl
	ld (hl), e
	inc h
	ld (hl), d
	dec h
	inc hl
	pop de
	dec de
	pop bc
	djnz .CopySecondCosQuarter

	; next 128 elements,
	; 		CosTab[128 + Idx] = -CosTab[Idx];
	; hl already holds CosTab + 128
	ld de, CosTab
	ld b, 128
.CopyRemainingCosQuarters:
	push bc
	push de
	ex de, hl
	ld c, (hl)
	inc h
	ld b, (hl)
	dec h
	ld hl, 0
	or a
	sbc hl, bc
	ex de, hl
	ld (hl), e
	inc h
	ld (hl), d
	dec h
	inc hl
	pop de
	inc de
	pop bc
	djnz .CopyRemainingCosQuarters

	; now the sinus table
	; first 64 elements are
	; 		SinTab[Idx] = CosTab[192 + Idx];
	ld hl, CosTab + 192
	ld de, SinTab
	push hl
	push de
	ld bc, 64
	ldir
	pop de
	inc d
	pop hl
	inc h
	ld bc, 64
	ldir

	; the next 192 elements are
	; 		SinTab[64 + Idx] = CosTab[Idx];
	; de already holds SinTab[256+64]
	ld hl, CosTab + 256
	push hl
	push de
	ld bc, 192
	ldir
	pop de
	dec d
	pop hl
	dec h
	ld bc, 192
	ldir
	ret

; -------------------------------------------------------------------------------------------------------------
; Interrupt service routine
ISR:
	push af
	push bc
	push de
	push hl
	ex af, af'
	exx
	push af
	push bc
	push de
	push hl
	push ix
	push iy

FrameCount equ $+1
	ld hl, 0
	inc hl
	ld (FrameCount), hl

EyeShown equ $+1
	; we only flip bit 3 (normal/shadow screen) here. The current bank is kept
	ld a, $0
	xor $08
	ld (EyeShown), a
	ld b, a
	ld a, (BANKM)
	and $f7
	or b
	SetPageInA
	; -------------------------------
	; music update
	if (!NO_MUSIC)
		if (PROFILE_FRAME)
			ld a, 2
			out (#fe), a
		endif

		; always switch to 0 page when playing the music
		ld a, (BANKM)
		ld (RestorePageAfterMusic), a
		and $f8
		SetPageInA

FrameMaskPos equ $+1
		ld hl, FrameMasks
		ld de, FrameMasksEnd
		or a
		sbc hl, de
		add hl, de
		jr c, MusicNotALoop

		; loop music
		; reset all registers to 0
		ld de, 13
ClearAYLoop:
		ld bc, #fffd
		out (c), e
		ld b, #bf
		out (c), d
		dec e
		bit 7, e
		jr nz, ClearAYLoop

		ld hl, RegPosReinit
		ld de, RegPos
		ld bc, RegPosReinitSize
		ldir

		ld hl, FrameMasks + 768

MusicNotALoop:
		ld d, (hl)
		inc hl
		ld (FrameMaskPos), hl

		ld hl, RegPos
		xor a

		//0 : 0 1
		//1 : 2 3
		//2 : 4 5 10
		//3 : 6 7
		//4 : 8
		//5 : 9
		//6 : 11 [12]
		//7 : 13

		UpdateTwoConsecutiveRegsRegGroup // 0 1
		UpdateTwoConsecutiveRegsRegGroup // 2 3
		UpdateRegs_4_5_10_RegGroup	// 4 5 10
		UpdateTwoConsecutiveRegsRegGroup // 6 7
		UpdateNextReg		// 8
		UpdateNextReg		// 9
		inc a ; a == 11
		UpdateNextReg		// 11
		inc a ; a == 13
		UpdateNextReg		// 13

RestorePageAfterMusic equ $+1
		ld a, 0
		SetPageInA

		if (PROFILE_FRAME)
			ld a, 3
			out (#fe), a
		endif
	endif // NO_MUSIC

	pop iy
	pop ix
	pop hl
	pop de
	pop bc
	pop af
	ex af, af'
	exx
	pop hl
	pop de
	pop bc
	pop af
	ei
	reti

PlotSizeRoutine:
	and a
	ret z
	dec a
	jr nz, .LargerThan1		// size is larger than one

	JmpPlotInlineable

.LargerThan1
	dec a
	jr nz, .LargerThan2		// size is larger than 2

	push de
	PlotInlineable
	
	pop de
	inc d
	push de
	PlotInlineable
	
	pop de
	inc e
	push de
	PlotInlineable
	
	pop de
	dec d
	JmpPlotInlineable

.LargerThan2
	; +0, 0
	push de
	PlotInlineable

	; +1, 0
	pop de
	inc d
	push de
	PlotInlineable

	; +1, +1
	pop de
	inc e
	push de
	PlotInlineable

	; 0, +1
	pop de
	dec d
	push de
	PlotInlineable

	; -1, +1
	pop de
	dec d
	push de
	PlotInlineable

	; -1, 0
	pop de
	dec e
	push de
	PlotInlineable

	; -1, -1
	pop de
	dec e
	push de
	PlotInlineable

	; 0, -1
	pop de
	inc d
	push de
	PlotInlineable
	
	; +1, -1
	pop de
	inc d
	JmpPlotInlineable

; Should be largely the same as plot
ClearPlotSizeRoutine:
	and a
	ret z
	dec a
	jr nz, .LargerThan1		// size is larger than one

	JmpClearPlotInlineable

.LargerThan1
	dec a
	jr nz, .LargerThan2		// size is larger than 2

	push de
	ClearPlotInlineable
	
	pop de
	inc d
	push de
	ClearPlotInlineable
	
	pop de
	inc e
	push de
	ClearPlotInlineable
	
	pop de
	dec d
	JmpClearPlotInlineable

.LargerThan2
	; +0, 0
	push de
	ClearPlotInlineable

	; +1, 0
	pop de
	inc d
	push de
	ClearPlotInlineable

	; +1, +1
	pop de
	inc e
	push de
	ClearPlotInlineable

	; 0, +1
	pop de
	dec d
	push de
	ClearPlotInlineable

	; -1, +1
	pop de
	dec d
	push de
	ClearPlotInlineable

	; -1, 0
	pop de
	dec e
	push de
	ClearPlotInlineable

	; -1, -1
	pop de
	dec e
	push de
	ClearPlotInlineable

	; 0, -1
	pop de
	inc d
	push de
	ClearPlotInlineable
	
	; +1, -1
	pop de
	inc d
	JmpClearPlotInlineable

; ---------------------------------------------------
; Projects a 3D point
; takes
;   HL - x
;   DE - y
;   BC - z
;   A - eye offset
; returns (data suitable for Plot right away)
;   if C is not set
;   D,E - screen x, screen y
;   A - size
;   if C is set
;   we're offscreen!
Project:
EyeOffset equ $+1
	ld a, LEFT_EYE_OFFSET
	// intentional fallthrough
ProjectWithEyeOffset:
	; calc TZ = Z + OffsetZ (512)
	inc b
	inc b

	; calc TY = Y + OffsetY (512)
	inc d
	inc d

	; calc TX = X + EyeOffset
	push de
	ld e, a
	rlca
	sbc a, a
	ld d, a
	add hl, de

	; Calc ScrX = 128 + (int)(128 * (TX / TZ))
	push bc
	ex de, hl
	call sdiv16_trampo
	; hl now contains TX / TZ in 8.8. We need to mul it by 128 and turn into integer
	; this is essentially shifting it right 1 position and treating as an integer
	sra h
	rr l
	ld de, 128
	add hl, de
	; check if we're out of screen and return if so
	ld a, h
	and a
	pop bc
	pop de
	jr nz, .Offscreen	;	high byte can be non 0 only if we're negative or > 256, both are offscreen

	; should be safe to take just l
	ld a, l
	cp 2
	jr c, .Offscreen
	cp 254
	jr nc, .Offscreen
	ex af, af'

	; now calculate ScrY = 96 + (int)(64 * (Y / TZ)
	push bc
	call sdiv16_trampo
	; hl now contains TY / TZ in 8.8. We need to mul it by 64 and turn into integer
	; this is essentially shifting it right 2 positions and treating as an integer
	sra h
	rr l
	sra h
	rr l
	ld de, 96
	add hl, de
	ld a, h
	and a
	jr nz, .Offscreen_PopBC		; h != 0 means negative or > 256
	ld a, l
	cp 192
	jr nc, .Offscreen_PopBC		; Y can be offscreen if >= 192 too

	ld e, a		; this is ScrY
	ex af, af'
	ld d, a		; this is ScrX

	; the only thing left is to calculate size
	exx
	ld de, PARTICLE_SIZE
	pop bc	; TZ
	call sdiv16_trampo
	ld a, h
	exx
	or a	; make sure C is not set
	ret

.Offscreen_PopBC
	pop bc
.Offscreen
	scf
	ret

; ---------------------------------------------------
; Xorshift algo by raxoft (Patrik Rak), from https://gist.github.com/raxoft/c074743ea3f926db0037
; corrupts hl' and de', but not bc
; returns random A
rnd:
		exx

		if (USE_RAXOFT_RANDOM)
.seed1 equ $+1
     	ld  hl, 0xA280   ; yw -> zt
.seed2 equ $+1
        ld  de, 0xC0DE   ; xz -> yw
        ld  (.seed2),hl  ; x = y, z = w
        ld  a,l         ; w = w ^ ( w << 3 )
        add a,a
        add a,a
        add a,a
        xor l
        ld  l,a
        ld  a,d         ; t = x ^ (x << 1)
        add a,a
        xor d
        ld  h,a
        rra             ; t = t ^ (t >> 1) ^ w
        xor h
        xor l
        ld  h,e         ; y = z
        ld  l,a         ; w = t
        ld  (.seed1),hl

		else
		
		; tolerable random
.rand_seed equ $+1
		ld      hl, 10569
		ld      a, r
		ld      d, a
		ld      e, (hl)
		add     hl, de
		add     a, l
		xor     h
		srl		h
		srl		h
		ld (.rand_seed), hl

		endif

		exx
        ret 

; -----------------------------------------------------------------------------------------------------------------------
; Math supporting macros
	MACRO GetAbsDEBCAndCallUnsignedProc ProcAddr
		bit 7, d
		jr z, 2F ;de_positive
		bit 7, b
		jr z, 1F ;de_negative_bc_positive
		; // both negative
		; // just invert them and call as unsigned
		ld hl, 0
		or a
		sbc hl, de
		push hl
		ld hl, 0
		or a
		sbc hl, bc
		ld b, h
		ld c, l
		pop de
		jr ProcAddr

1: ; de_negative_bc_positive:
		; de negative, bc positive
		; invert de, do unsigned, and invert back
		ld hl, 0
		or a
		sbc hl, de
		ex de, hl
		call ProcAddr
		ex de, hl
		ld hl, 0
		or a
		sbc hl, de
		ret

2: ; de_positive:
		bit 7, b
		jr z, ProcAddr	; both positive, proceed straight to multiplication
		; de positive, bc negative
		; invert bc, multiply unsigned, and invert back
		ld hl, 0
		or a
		sbc hl, bc
		ld b, h
		ld c, l
		call ProcAddr
		ex de, hl
		ld hl, 0
		or a
		sbc hl, de
		ret
	ENDM



; -----------------------------------------------------------------------------------------------------------------------
; Signed Division 16/16 fp 8.8
; hl = de / bc
; fp 8.8 means we're dividing x*256 by y*256 and want to get z*256
; In order to not lose precision, premultiply x by 256 then and divide using 24-bit division
sdiv16:
	GetAbsDEBCAndCallUnsignedProc udiv16_fp48

; -----------------------------------------------------------------------------------------------------------------------
; Unsigned 16/16 fp 8.8 division
; hl = de / bc
; fp 8.8 means we're dividing x*256 by y*256 and want to get z*256.
; In order to not lose precision, premultiply x by 256 then and divide using 24-bit division
udiv16_fp48:
	; restoring algorithm of 24/16 division, hl is the 16-bit accumulator, de:a holds the 24-bit dividend (will also become quotient)
	; we make that 24 bit number out of 16 bit number shifted to the left
	; shift the numerator 7 bits to the left
	xor a
	ld h, a		; accumulator HL starts at 0
	ld l, a

	; rearrange from de:a to a:de so we can structure the loop better
	ld a, d
	ld d, e
	ld e, l		; l==0, so e is also 0
	; since we only care about the twelve bits of the result, we can pre-shift the dividend and run less loops

	DUP 4
		sla d
		rla
	EDUP

	; restoring algorithm of 24/16 division, hl is the 16-bit accumulator, a:de holds the 24-bit dividend (will also become quotient)
	; we make that 24 bit number out of 16 bit number shifted to the left
udiv16_unrolled_div_start
	DUP 20
		sll e		; 8
		rl d		; 8
		rla			; 4
		adc hl, hl  ; 15
		;or a		; 0 (4)	we seem to be able to avoid resetting carry here because we always keep HL < BC, and our BC is positive, so it does not have the highest bit set
		sbc hl, bc	; 15	; if hl > bc we need to subtract it and increase a, if hl < bc, we need to do nothing
		jr nc, 1F	; 7 or 12
		add hl, bc  ; 11
		dec e       ; 4
1
					; -----
					; 72 or 62 cycles. Total div is going to be between 1426-1656 cycles, likely closer to 1656
					; Note: https://baze.sk/3sc/misc/z80bits.html#2.5 has a very similar code and I borrowed the idea to use SLL from there.
	EDUP
udiv16_unrolled_size equ (($-udiv16_unrolled_div_start) / 23)

	; a:de holds the quotient, of which we need the lower part
	ex de, hl
	ret

; -----------------------------------------------------------------------------------------------------------------------
; Signed multiply 16/16 fp 4.8
; hl = de * bc
; fp 8.8 means we're multiplying x*256 by y*256 and want to get z*256
; after multiply, we would get xy*65536, so divide the result by 256 (shift by 8 bits)
smul16:
	GetAbsDEBCAndCallUnsignedProc umul16

; -----------------------------------------------------------------------------------------------------------------------
; 16-bit 4.8 fixed point unsigned multiply
;   hl = bc * de
; credits: https://tutorials.eeems.ca/Z80ASM/part4.htm
; fp 8.8 means we're multiplying x*256 by y*256 and want to get z*256
; after multiply, we would get xy*65536, so divide the result by 256 (shift by 8 bits)
umul16:
	ld hl, 0
	ld a, b
	and a
	jr nz, umul16_bc_larger_than_256
	or c
	ret z	; multiplication by 0
	; we know that bc is non-zero and 8 bit
	ld a, d
	and a
	jr nz, umul16_regular_multiply	; bc 8 bit, but de 16 -> no special case
	; at this point we know that both a 8 bit
	or e
	ret z   ; multiplication by 0

umul8:
	; do a 8-bit multiply
	xor a
	DUP 8
		rra
		rr e
		jr nc, 1F
		add c
1
	EDUP
	rra
	ld l, a
	ld h, 0
	ret



umul16_bc_larger_than_256:
	; bc is larger than 256, cannot use umul8, but still want to check if de is 0
	ld a, d
	or e
	ret z
	; intentional fall-through to regular multiply

umul16_regular_multiply:
	; we only care about 4.8 part of both, so we need to multiply 4.8 by 4.8 and get 8.16
	ld a, d
	ld d, 0
	DUP 4
		sla e			; 8
		rla				; 4
	EDUP

	DUP 12
	  add hl, hl		; 11
	  rl e				; 8
	  rla				; 4
	  jr nc, 1F			; 12
	  add hl, bc		; 11
	  adc a, d			; 4
1
	EDUP
	; we have a:e:hl holding a 16.16 result, and we need to take the middle 8.8 part. 
	ld l, h
	ld h, e
	ret


	if (!USE_70CYCLE_PLOT)
XorPlotRoutine:
	; from https://zxspectrumcoding.wordpress.com/2025/05/10/a-fast-pixel-routine-for-the-zx-spectrum/
	ld A,E                ;  load Y plot point

	srl a                 ;  rotate Right --- divide in half
	scf                   ;  turn on Carry flag
	rra                   ;  rotate right with the carry flag
	scf                   ;  turn on Carry flag
	rra                   ;  rotate Right --- divide in half

	ld L,A                ;  temp store in L
	xor E                 ;  XOR the Y value
	and %11111000         ;  mask out bottom 3 bits
	xor E                 ;  XOR the Y value

	ld H,A                ;  store High byte

	ld A,D                ;  load X plot point
	xor L                 ;  XOR the temp value
	and %00000111         ;  mask out unwanted bits
	xor D                 ;  XOR the X value
	rrca                  ;  divide by 2
	rrca                  ;  divide by 4
	rrca                  ;  divide by 8

	ld L,A                ;  store Low byte
						;  now we have the full address
						;  now use LUT to find which bit to set
	ld A,D                ;  load X plot point
	and %00000111         ;  mask out unwanted bits

						;  use a LUT to quickly find the bit position for the X position
	ld D, high X_PositionBits  ;  load LUT address into DE
	ld E, A               ;  E now points to the LUT entry
	ld A,(DE)             ;  load answer into A

						;  output to screen
	xor (HL)              ;  or with contents of address HL
	ld (HL),A             ;  load address HL with Answer from A
	ret
	
	else

; "ZIP PLOT 1.4"
; Credits: Viper of TechnoLab
; Taken from KrNews #05 (July 24, 1998)
; https://zxpress.ru/article.php?id=8242
XorPlotRoutine:
	LD L,E
	LD H,high PTY
	LD B,(HL)
	DEC H
	LD A,(HL)
	DEC H
	LD L,D
	ADD A,(HL)
	LD C,A
	DEC H
	LD A,(BC)
	XOR (HL)
	LD (BC),A
	ret

ClearPlotRoutine:
	LD L,E
	LD H,high PTY
	LD B,(HL)
	DEC H
	LD A,(HL)
	DEC H
	LD L,D
	ADD A,(HL)
	LD C,A
	DEC H
	ld a,(hl)
	cpl
	ld d, a
	ld a, (bc)
	and d
	LD (BC),A
	ret

	endif


;--------------------------------------------------------------------
; Trampolines
	if (0)

rnd_trampo:
	jp rnd

Project_trampo:
	jp Project

PlotSizeRoutine_trampo:
	jp PlotSizeRoutine

ClearPlotSizeRoutine_trampo:
	jp ClearPlotSizeRoutine

smul16_trampo:
	jp smul16

sdiv16_trampo:
	ld a, 1
	out ($fe), a
	call sdiv16
	ld a, 4
	out ($fe), a
	ret

XorPlotRoutine_trampo:
	jp XorPlotRoutine

ClearPlotRoutine_trampo:
	jp ClearPlotRoutine


	else

rnd_trampo equ rnd
Project_trampo equ Project
PlotSizeRoutine_trampo equ PlotSizeRoutine
ClearPlotSizeRoutine_trampo equ ClearPlotSizeRoutine
smul16_trampo equ smul16
sdiv16_trampo equ sdiv16
XorPlotRoutine_trampo equ XorPlotRoutine
ClearPlotRoutine_trampo equ ClearPlotRoutine

	endif
; ---------------------------------------------------
; Resources

	align 256
IRQVectorTable:
ISRHighAddr EQU (IRQVectorTable / 256) + 1
	dup 257
	db ISRHighAddr
	edup

	org ISRHighAddr * 256 + ISRHighAddr
isr:
	jp ISR

	if (!USE_70CYCLE_PLOT)
	align 256
X_PositionBits: defb 128,64,32,16,8,4,2,1
	endif

	; these all are 0-inited, but we actually rely on them to be 0s
	; don't want to get in trouble if starting on unclean memory
	align 256
HistoryLeft:
	ds 256
HistoryRight:
	ds 256

	; these all are 0-inited, but we actually rely on them to be 0s
	; don't want to get in trouble if starting on unclean memory
	align 256
ParticleBuffer:
	ds NUM_PARTICLES * Particle
ParticleBufferSize equ $ - ParticleBuffer

	if (USE_70CYCLE_PLOT)
		align 256
		block 1024
PTY 	EQU $ - 256
	endif

CosTab:
		align 256
		block 512
SinTab:
		align 256
		block 512	

	; we should not allow the main program to overflow since $c000-$ffff is used for the buffers
	ASSERT $ < 49152

	; music can overflow as this is handled in the code.

	if (!NO_MUSIC)
RegPos:
		dw RegGroup0
		dw RegGroup1
		dw RegGroup2
		dw RegGroup3
		dw RegVals8
		dw RegVals9
		dw RegGroup6
		dw RegVals13

RegPosReinit:
		dw RegGroup0 + 48
		dw RegGroup1 + 232
		dw RegGroup2 + 576
		dw RegGroup3 + 4
		dw RegVals8 + 1
		dw RegVals9 + 256
		dw RegGroup6 + 0
		dw RegVals13 + 0
RegPosReinitSize equ $-RegPosReinit

FrameMasks:
		incbin "../res/patornew/RegMasks.bin"
FrameMasksEnd equ $

RegGroup0:
		incbin "../res/patornew/RegGroup0.bin"

RegGroup1:
		incbin "../res/patornew/RegGroup1.bin"

RegGroup2:
		incbin "../res/patornew/RegGroup2.bin"

RegGroup3:
		incbin "../res/patornew/RegGroup3.bin"

RegVals8:
		incbin "../res/patornew/Reg08.bin"

RegVals9:
		incbin "../res/patornew/Reg09.bin"

RegGroup6:
		incbin "../res/patornew/RegGroup6.bin"

RegVals13:
		incbin "../res/patornew/Reg13.bin"
	endif

savebin_end EQU $


	savebin "parallelvisions_main.bin", savebin_begin, savebin_end-savebin_begin
	SAVESNA "parallelvisions_main.sna", savebin_begin
