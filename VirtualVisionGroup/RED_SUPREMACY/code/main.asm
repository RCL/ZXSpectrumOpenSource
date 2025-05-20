    device ZXSPECTRUMNEXT

NO_MUSIC                EQU 0
DEBUG_MUSIC_REGS        EQU 0
PROFILE_FRAME           EQU 0
SPEEDRUN                EQU 0

USE_DMA                 EQU 0

; need to move the player high enough because music makes a lot of address space, and we also need that memory for other reasons
; just remember abotu stack being at $FFFF too
MUSIC_PLAYER_LOCATION   EQU $F800

    include "constants.i.asm"

    ifndef VERSION_FOR_LOCAL_DEBUG
        ERROR "Expecting VERSION_FOR_LOCAL_DEBUG to be defined"
    endif

    if (VERSION_FOR_LOCAL_DEBUG)
        DISPLAY "Assembling version for local debug as .NEX file"
    else
        DISPLAY "Assembling version for compression"
    endif

    org #8000

savebin_begin:
    if (VERSION_FOR_LOCAL_DEBUG)
        di
        nextreg TURBO_CONTROL_NR_07, 3  ; 28 Mhz
    endif
    ; don't care about returning to the OS...
    ;ld sp, $ffff

    ; --------------------------------------------------------------------------------
    ; Video mode setup
    ; enable LoRes and ULA plus
    nextreg SPRITE_CONTROL_NR_15, 0x80
    nextreg PALETTE_CONTROL_NR_43, 1 ; enable ULAnext mode
    nextreg LORES_CONTROL_NR_6A, $20 ; display $4000 screen and set 4bpp - should agree with value LastUsedReg6A

    ; Setting transparent color to a value above the palette seems to allow non-transparent paper
    nextreg GLOBAL_TRANSPARENCY_NR_14, 0x11
    nextreg TRANSPARENCY_FALLBACK_COL_NR_4A, 0 ; fallback color = 0
    nextreg ENHANCED_ULA_INK_COLOR_MASK_42, 0xff ; ulanext color mask

    // page in 4000 and 6000
    nextreg MMU2_4000_NR_52, 10
    nextreg MMU3_6000_NR_53, 11

    ld hl, LoresPalette
    xor a
    DUP 16
        nextreg PALETTE_INDEX_NR_40, a      ; color to configure
        inc a
        ex af, af'
        ld a, (hl)
        nextreg PALETTE_VALUE_NR_41, a
        inc hl
        ex af, af'
    EDUP

    ; --------------------------------------------------------------------------------
    ; Interrupt set up
    nextreg INTERRUPT_CONTROL_C0, (((low InterruptVectors) & %11100000) | 1)    ; set bits 3 of interrupt vector table and also IM2 mode
    nextreg INTERRUPT_ENABLE_MASK_0_C4, $81 ; Enables ULA and INT interrupts only
    nextreg INTERRUPT_ENABLE_MASK_2_C6, 0
    nextreg INTERRUPT_ENABLE_MASK_1_C5, 0       ; Disables CTC interrupt

    ld hl, MusicPlayerBeforeMoving
    ld de, MUSIC_PLAYER_LOCATION
    ld bc, MusicPlayerSize
    ldir

    if (USE_DMA)
        ld      hl, DmaInitData
        ld      bc, (DmaInitSize << 8) + Z80_DMA_PORT_DATAGEAR
        otir
    endif

    ; check what mode we're in
    ld a, $5
    ld bc, TBBLUE_REGISTER_SELECT_P_243B
    out (c), a

    ld bc, TBBLUE_REGISTER_ACCESS_P_253B
    in a, (c)

    ; see https://www.specnext.com/tbblue-io-port-system/ for nextreg 5 values
    and $04 ;   bit 2 - 0 == 50Hz, 1 == 60 Hz
    jr z, RunningIn50Hz

    ; TODO set the counter to ignore each 6th update
    ld hl, Skip6thUpdateIf60HzOp
    dec (hl)    ; changes jp (C3) to jp nz (C2)

RunningIn50Hz:
    ld a, high InterruptVectors
    ld i, a
    im 2

    ; -----------------------------------------------------
    ; screen setup

    if (1)
    MACRO ClearScreenUnderHLBlack
        ld (hl), l
        ld d, h
        ld e, l
        inc e
        ld bc, 6144
        ldir
    ENDM

    MACRO ClearScreenUnderHLColorFromA
        ld (hl), a
        ld d, h
        ld e, l
        inc e
        ld bc, 6144
        ldir
    ENDM
    else
    endif

    ld hl, #6000
    ClearScreenUnderHLBlack

    ld hl, #4000
    ClearScreenUnderHLBlack

    ; the rest of the work will be done in the interrupts
    ei
EternalLoop:
    halt
    ;out (#fe), a
    ;xor 7
    jr EternalLoop

; ---------------------------------------------------
; Rect drawing helper macros

    ; Calculates addres from d == y, e == x and puts into hl
    ; Width e is in pixels, but the address is always returned for the even pixel
    ; corrupts hl, de and a'
    MACRO DrawRect_CalcScreenAddrFromDE
        ld l, e
        ld e, 0
        ld h, b
        ld b, 2
        bsra de, b  ; y * 256 / 4 == y * 64
        ld b, h
        ld h, 0
        srl l
        add hl, de
        ld de, (ScreenAddr)
        add hl, de
    ENDM

    ; expects args like the main procedure
    ; corrupts HL and A'
    MACRO DrawRect_DrawFirstLine
        push de
        push bc
        ld c, $f0   ; mask out right nibble
        DrawRect_CalcScreenAddrFromDE
        ld d, a     ; put color in d
.DrawRect_DrawFirstLine_Loop:
        ld a, (hl)
        and c
        or d
        ;or 15 ;for debug
        ld (hl), a
        add hl, 64
        djnz .DrawRect_DrawFirstLine_Loop:
        ld a, d
        pop bc
        pop de
    ENDM

    ; expects args like the main procedure
    ; corrupts HL and A'
    MACRO DrawRect_DrawLastLine
        ld l, c
        push de
        push bc
        ld c, $0f   ; mask out left nibble
        dec l
        ld h, 0
        add hl, de
        ex de, hl
        swapnib
        DrawRect_CalcScreenAddrFromDE
        ld d, a     ; put color in d
.DrawRect_DrawLastLine_Loop:
        ld a, (hl)
        and c
        or d
        ;or $70 ; for debug
        ld (hl), a
        add hl, 64
        djnz .DrawRect_DrawLastLine_Loop:
        ld a, d
        pop bc
        pop de
    ENDM

    ; expects args like the main procedure
    ; corrupts DE, HL, BC
    MACRO DrawRect_DrawEvenRect
        srl c
        ; should not be 0 at this point
        ld h, a
        swapnib
        or h
        DrawRect_CalcScreenAddrFromDE
        srl c
        jr nc, .DrawRect_DrawRectDivisibleBy4
        rl c
.DrawRect_DrawEvenRect_LoopY:
        push bc
        ld d, h
        ld e, l

        ld b, c 
.DrawRect_DrawEvenRect_LoopX:
        ld (hl), a
        inc l       ; we should not cross a 256 b boundary within a scanline
        djnz .DrawRect_DrawEvenRect_LoopX:

        ex de, hl
        pop bc
        add hl, 64
        djnz .DrawRect_DrawEvenRect_LoopY
        jr .DrawRect_DrawEvenRect_End

; special case for rects divisible by 4 to help speed in 60hz
.DrawRect_DrawRectDivisibleBy4
        ; rects that are 4 need a yet another check
        ld d, a
        ld a, c
        and a
        ld a, d
        jr z, .DrawRect_Draw4WidthRect_LoopY
.DrawRect_DrawRectDivisibleBy4_LoopY:
        push bc
        ld d, h
        ld e, l

        ld b, c
.DrawRect_DrawRectDivisibleBy4_LoopX:
        ld (hl), a
        inc l       ; we should not cross a 256 b boundary within a scanline
        ld (hl), a
        inc l       ; we should not cross a 256 b boundary within a scanline
        djnz .DrawRect_DrawRectDivisibleBy4_LoopX:

        ex de, hl
        pop bc
        add hl, 64
        djnz .DrawRect_DrawRectDivisibleBy4_LoopY
        jr .DrawRect_DrawEvenRect_End

.DrawRect_Draw4WidthRect_LoopY:
        ld (hl), a
        inc l       ; we should not cross a 256 b boundary within a scanline
        ld (hl), a
        inc l       ; we should not cross a 256 b boundary within a scanline

        add hl, 62
        djnz .DrawRect_Draw4WidthRect_LoopY
.DrawRect_DrawEvenRect_End
    ENDM

; Rect drawing routine.
; Coords are signed and don't have to be clipped.
; de - y (signed, 16-bit)
; hl - x (signed, 16-bit)
; b - height, c - width (normal unsigned)
; a - color
DrawRect:
    ; we need to make sure our coords are (0-95) for Y and 0-127 for X
    push bc
    push de

    exx
    ld hl, 0
    ld (SubtractFromWidth), hl
    ld (SubtractFromHeight), hl
    exx

    ld bc, 128

    MACRO ClipBetween0AndBCAndStoreAdjustments  AdjustmentUpTo0, MaxSizeLeft
        ; clip HL between 0 and BC
        bit 7, h
        jr z, .ValIsNotANegative
    
        ; negate
        ex de, hl
        ld hl, 0
        or a
        sbc hl, de
        ld (AdjustmentUpTo0), hl
        ld hl, 0

.ValIsNotANegative
        or a
        sbc hl, bc
        jr c, .ValIsNotAboveBC
        
        ; if above our top, we don't see it - exit now
        pop de
        pop bc
        ret

.ValIsNotAboveBC:
        push hl
        ex de, hl
        ld hl, 0
        or a
        sbc hl, de
        ld (MaxSizeLeft), hl
        pop hl
        add hl, bc
    ENDM

    ClipBetween0AndBCAndStoreAdjustments SubtractFromWidth, MaxWidthLeft

    ; we know hl is now 0-127, store X
    push hl
    exx
    pop de
    exx

    pop hl
    push hl ; this push is needed because the macro needs to be the same, and it pops 2 times when exiting
    ld bc, 96

    ; clip Y between 0 and BC - should be largerly the same code as above!

    ClipBetween0AndBCAndStoreAdjustments SubtractFromHeight, MaxHeightLeft

    ; we know hl is now 0-95, store Y
    push hl
    exx
    pop hl
    ld d, l
    exx
    pop hl  ; dummy pop - see comment above re: macro

    ; now that X and Y are properly clipped, adjust Width / Height to see
    pop bc

    ; width adjustment
    ld l, c
    ld h, 0
SubtractFromWidth equ $+1
    ld de, 0
    or a
    sbc hl, de
    ; if subtracted too much, exit
    ret c
    ret z

    ; otherwise, check if above max 
MaxWidthLeft equ $+1
    ld de, 0
    or a
    sbc hl, de
    add hl, de
    jr c, DontClampWidth

    ; clamp to max left
    ex hl, de

DontClampWidth:
    ;store width
    push hl
    exx
    pop bc
    exx

    ; height adjustment
    ld l, b
    ; h should remain 0

SubtractFromHeight equ $+1
    ld de, 0
    or a
    sbc hl, de

    ; if subtracted too much, exit
    ret c
    ret z

    ; otherwise, check if above max
MaxHeightLeft equ $+1
    ld de, 0
    or a
    sbc hl, de
    add hl, de
    jr c, DontClampHeight

    ; clamp to max left
    ex hl, de

DontClampHeight:
    ; store height
    push hl
    exx
    pop hl
    ld b, l

    ; we're done clipping intentional fall-through to DrawRect

; Rect drawing routine after the coords have already been clipped 
; d - y (0-95), e - x (0-127)
; b - height, c - width
; a - color
DrawRect_Clipped_Screenspace:
    ; we have 4 cases to consider:
    ; 1. even start, odd width
    ;   draw the last line (left nibble)
    ;   draw the rect with width - 1
    ; 2. odd start, odd width
    ;   draw the first line (right nibble)
    ;   draw rect with width - 1 one to the right
    ; 3. odd start, even width
    ;   draw the first line (right nibble)
    ;   draw the last line (left nibble)
    ;   draw rect with width - 2 on to the right
    ; 4. even start, even width
    ;   draw the rect

    ; check which case we're dealing with
    bit 0, e
    jp z, DrawRect_EvenStart

    ; we have an odd start
    bit 0, c
    jr z, DrawRect_OddStart_EvenWidth

    ; odd start, odd width
    DrawRect_DrawFirstLine
    dec c
    ret z   ; if a rect was 1 pixel wise, that's it
    inc e
    DrawRect_DrawEvenRect
    ret

DrawRect_OddStart_EvenWidth:
    DrawRect_DrawFirstLine
    dec c
    ret z
    ; for now need to increase back
    inc c
    DrawRect_DrawLastLine
    dec c
    dec c
    ret z   ; shoulnd't ever exit here
    inc e   ; cannot put it offscreen, we presume coords are properly clipped
    DrawRect_DrawEvenRect
    ret

DrawRect_EvenStart:
    bit 0, c
    jp z, DrawRect_EvenStart_EvenWidth

    ; even start, odd width
    DrawRect_DrawLastLine
    dec c
    ret z
    DrawRect_DrawEvenRect
    ret

DrawRect_EvenStart_EvenWidth:
    DrawRect_DrawEvenRect
    ret

; ---------------------------------------------------
; Interrupt routine
VBlankInterruptHandler:
    ; don't bother saving the registers, no one is using them!
    if (PROFILE_FRAME)
        ld a, 7
        out (#fe), a
        nextreg TRANSPARENCY_FALLBACK_COL_NR_4A, a
    endif

    ld hl, InterruptCtr
    dec (hl)
Skip6thUpdateIf60HzOp:          ; will be patched to JP NZ in 60Hz
    jp MainISRBody

    ; we will only end up being here again if we didn't jump before, so HL will still be intat
    ld a, 6
    ld (hl), a
    jp EndOfVBlankHandling

MainISRBody:
    ; -------------------------------
    ; music update
    if (!NO_MUSIC)
        call MUSIC_PLAYER_LOCATION
    endif // NO_MUSIC

;MainUpdate:

    if (DEBUG_MUSIC_REGS)
        ld a, h
        and $3f
        ld h, a
DelayLoop:
        dec hl
        ld a, h
        or l
        jr nz, DelayLoop
    endif

    if (PROFILE_FRAME)
        ld a, 2
        out (#fe), a
        nextreg TRANSPARENCY_FALLBACK_COL_NR_4A, a
    endif

    if (0)  ; for visual debugging
FrameDivider equ $+1
        ld a, 1
        dec a
        ld (FrameDivider), a
        jr nz, EndOfVBlankHandling
        ld a, 1
        ld (FrameDivider), a
    endif

    ; stories
StoryPointer equ $+1
    call Story1

EndOfVBlankHandling:
    ; ---------------
    ; end of interrupt
    if (PROFILE_FRAME)
        xor a
        out (#fe), a
        nextreg TRANSPARENCY_FALLBACK_COL_NR_4A, a
    endif

    ; intentional fall-through

DefaultInterruptHandler:
    ei
    reti

; ---------------------------------------------------
; Screen flip
FlipScreen:
    ; flip the screen
    ld hl, ScreenAddr + 1
    ld a, $20
    xor (hl)
    ld (hl), a

LastUsedReg6A equ $+1
    ld a, $20
    xor $10
    ld (LastUsedReg6A), a
    nextreg LORES_CONTROL_NR_6A, a
    ret

; ---------------------------------------------------
; Story 0 - was used as a placeholder

Story0:
    if (0)
        ld bc, 6144
        ld hl, #4000
        ld d, h
        ld e, l
        inc e
        ld (hl), l
        ldir

    TestDrawX equ $+1
        ld a, -30
        inc a
        ld (TestDrawX), a
        ld l, a
        add a, a
        sbc a, a
        ld h, a

        ld de, 33

        ld bc, 25*256 + 35
        ld a, 11
        ex de, hl
        jp DrawRect
    endif

; ---------------------------------------------------
; Story 1 - "Underwhelming effort"

STORY1_DURATION                 EQU 64 * 6 * 4      ;   6 patterns
STORY1_RED_FILLS_WHOLE_SCREEN   EQU 32 * 4  ; // last half of the pattern

Story1:
Story1Duration equ $+1
    if (!SPEEDRUN)
        ld hl, STORY1_DURATION
    else
        ld hl, 1
    endif

    dec hl
    ld (Story1Duration), hl
    ld a, h
    or l
    jr nz, GoOnWithStory1

    ; story change!
    ld hl, Story2
    ld (StoryPointer), hl

    ; clear the screen
    ld hl, (ScreenAddr)
    ld a, FILL_COLOR_WHITE
    ClearScreenUnderHLColorFromA
    call FlipScreen

    ; enable writing at the same screen
    ld hl, ScreenAddr + 1
    ld a, $20
    xor (hl)
    ld (hl), a
    ret

GoOnWithStory1:
    push hl

    call FlipScreen

SlideDown equ $+1
    ld a, 0
    cp 96
    jr nc, SkipIncreaseSlideDown
    inc a
    ld (SlideDown), a
SkipIncreaseSlideDown:
    srl a

    push af
    
    sub 48
    ld e, a
    sbc a, a
    ld d, a
    ld a, COLOR_WHITE
    ld bc, 48 * 256 + 128
    ld hl, 0
    call DrawRect

    ld a, 96
    pop bc
    sub b

    ld e, a
    ld d, 0
    ld a, COLOR_GREY
    ld bc, 48 * 256 + 128
    ld hl, 0
    call DrawRect

DelayBeforeThreatPart equ $+1
    ld a, 255
    and a
    jr z, ThreatPart
    dec a
    ld (DelayBeforeThreatPart), a
    pop hl
    ret

ThreatPart:
    ld hl, ThreatPos

ThreatPosDivider equ $+1
    ld a, 4
    dec a
    jr nz, SkipThreatPosUpdate
    dec (hl)
    ld a, 4
SkipThreatPosUpdate:
    ld (ThreatPosDivider), a

    ld de, 32
ThreatPos equ $+1
    ld a, 127
    ld l, a
    ; sign-extend to draw behind the left edge
    add a, a
    sbc a, a
    ld h, a
    push hl
    ld bc, 32 * 256 + 255
    ld a, COLOR_RED
    call DrawRect

    pop af
    rla
    pop hl
    jp nc, NoGrowthDraw
    
    ; extend red to the whole screen (kicks in after protector is gone)
    ld de, STORY1_RED_FILLS_WHOLE_SCREEN
    or a
    sbc hl, de
    jp nc, NoGrowthDraw

RedGrowth equ $+1
    ld a, 0
    cp 64
    jr nc, NoIncRedGrowth
    inc a
    ld (RedGrowth), a

NoIncRedGrowth:
    srl a
    push af

    ld de, 64
    ld b, a
    ld c, 128   
    ld a, COLOR_RED
    ld hl, 0
    call DrawRect

    ld a, 32
    pop bc
    sub b
    ld e, a
    ld d, 0
    ld c, 128   
    ld a, COLOR_RED
    ld hl, 0
    call DrawRect

NoGrowthDraw:
DelayBeforeProtectorPart equ $+1
    ld a, 255
    and a
    jr z, ProtectorPart
    dec a
    ld (DelayBeforeProtectorPart), a
    ret

ProtectorPart:
ProtectorRand equ $+1
    ld a, 0
    add 30
    ld e, a
    ld d, 0
    ld bc, 24 * 256 + 24
    ld a, COLOR_BLUE
ProtectorPos equ $+1
    ld hl, 0
    call DrawRect

    ld hl, ProtectorPos
    inc (hl)
    ld a, (ThreatPos)
    sub (hl)        ;   ThreatPos - ProtectorPos
    cp 24
    ;jr nc, ProtectorTooFar
    ret nc ; too far

    dec (hl)
    dec (hl)

    ld hl, ThreatPos
    inc (hl)

    ld a, (hl)
    and 7
    ld (ProtectorRand), a

ProtectorTooFar:
DelayBeforeOverpowering equ $+1
    ld a, 100
    and a
    jr z, Overpowered
    dec a
    ld (DelayBeforeOverpowering), a
    ret

Overpowered:
    ld hl, ProtectorPos
    dec (hl)

    ld hl, ThreatPos
    dec (hl)
    ret

; ---------------------------------------------------
; Story 2 - "Zyj niekolorowo" (Undiversification)

Story2:
Story2Duration equ $+1
    if (!SPEEDRUN)
        ld hl, 64 * 4 * 4       ;   4 patterns
    else
        ld hl, 1
    endif
    dec hl
    ld (Story2Duration), hl
    ld a, h
    or l
    jr nz, GoOnWithStory2

    ; story change!
    ld hl, Interlude
    ld (StoryPointer), hl

    ; clear the screen
    ld hl, (ScreenAddr)
    ; a should be 0 at this point or we wouldn't get here
    ClearScreenUnderHLColorFromA
    ret

GoOnWithStory2:

RedYPos equ $+1
    ld de, -8

    ld bc, 16 * 256 + 8

RedXPos equ $+1
    ld hl, 0
    push de
    push hl
    push hl
    ld a, COLOR_RED
    call DrawRect
    pop hl

RedXIncrement equ $+1
    ld de, 4
    add hl, de
    ld (RedXPos), hl

    ld a, l
    cp 128
    jr nz, .NoInvertRedXIncrementAt128

    ld hl, 0
    or a
    sbc hl, de
    ld (RedXIncrement), hl

.NoInvertRedXIncrementAt128
    or a
    jr nz, .NoInvertRedXIncrementAt0

    ld hl, 0
    or a
    sbc hl, de
    ld (RedXIncrement), hl

.NoInvertRedXIncrementAt0
    pop de
    pop hl
    ld a, e
    and $1f
    jr nz, .NoGoingDownRedY
    
    inc hl
    ld (RedYPos), hl

.NoGoingDownRedY:

    add hl, 12
    push hl
    
    MACRO DrawColoredDot  X, Y
        pop hl
        push hl
        ld de, Y
        or a
        sbc hl, de
        jr c, .DrawLively
        ; draw dull
        ld hl, (X & $F0) + 4
        ld de, (Y & $F8) - 2
        ld a, COLOR_GREY
        ld bc, 8*256 + 8
        call DrawRect
        jr .NextDot
.DrawLively
        call rnd
        and $07
        push af
        call rnd
        and $1f
        add X - 15
        push af
        call rnd
        and $0f
        add Y - 7
        ld e, a
        ld d, 0
        pop hl
        ld l, h
        ld h, d
        pop af
        ld bc, 8*256 + 8
        call DrawRect
.NextDot:
    ENDM

    DrawColoredDot 16, 11
    DrawColoredDot 32, 15
    DrawColoredDot 48, 13
    DrawColoredDot 64, 10
    DrawColoredDot 72, 12
    DrawColoredDot 80, 14
    DrawColoredDot 96, 13

    DrawColoredDot 20, 33
    DrawColoredDot 36, 32
    DrawColoredDot 52, 34
    DrawColoredDot 68, 36
    DrawColoredDot 76, 35
    DrawColoredDot 84, 37
    DrawColoredDot 100, 34

    DrawColoredDot 22, 58
    DrawColoredDot 38, 56
    DrawColoredDot 54, 61
    DrawColoredDot 70, 59
    DrawColoredDot 78, 57
    DrawColoredDot 86, 60
    DrawColoredDot 102, 56

    DrawColoredDot 16, 83
    DrawColoredDot 32, 86
    DrawColoredDot 48, 82
    DrawColoredDot 64, 85
    DrawColoredDot 72, 87
    DrawColoredDot 80, 84
    DrawColoredDot 96, 81

    pop hl
    ret

; ---------------------------------------------------
; Interlude - Machine gun burst

Interlude:
InterludeDuration equ $+1
    if (!SPEEDRUN)
        ld hl, 32 * 4 + 4 * 4       ;   1/2 pattern + 2 notes
    else
        ld hl, 1
    endif
    dec hl
    ld (InterludeDuration), hl
    ld a, h
    or l
    jr nz, GoOnWithInterludeDuration

    ; story change!
    ld hl, Story3
    ld (StoryPointer), hl

    ; prepare for double-buffering
    ld hl, ScreenAddr + 1
    ld a, $20
    xor (hl)
    ld (hl), a

    ret

GoOnWithInterludeDuration:
    ; we know hl holds the frame ctr
    ; compare against known numbers
    ld de, 8 * 4 + 4 * 4

    MACRO WaitAndPrintShot  ShotIdx
        or a
        sbc hl, de
        add hl, de
        ret nc      ; // too early

        push hl
        push de

        ld hl, 8 + ShotIdx*32
        ld de, 56 - ShotIdx*8
        if 0
        push hl
        push de
        push hl
        push de
        endif
        ld bc, 16*256 + 16
        ld a, COLOR_RED
        call DrawRect

        if 0
        pop de
        pop hl
        add hl, 6
        add de, -3
        ld bc, 22*256 + 4
        ld a, COLOR_RED
        call DrawRect

        pop de
        pop hl
        add hl, -3
        add de, 6
        ld bc, 4*256 + 22
        ld a, COLOR_RED
        call DrawRect
        endif   

        pop de
        pop hl
        add de, -8
    ENDM

    WaitAndPrintShot 0
    WaitAndPrintShot 1
    WaitAndPrintShot 2
    WaitAndPrintShot 3

    ret

; ---------------------------------------------------
; Story 3 - Border "security"

NUM_TRAVELERS   EQU 80
TRAVELER_SIZE   EQU 4

STORY3_BARPOS   EQU 72
STORY3_BARWIDTH EQU 8

STORY3_DURATION EQU 64 * 8 * 4 - 4 * 4      ;   8 patterns - 4 notes

Story3:
Story3Duration equ $+1
    if (1);!SPEEDRUN)
        ld hl, STORY3_DURATION
    else
        ld hl, 1
    endif
    dec hl
    ld (Story3Duration), hl
    ld a, h
    or l
    jr nz, GoOnWithStory3

    ; story change!
    ld hl, Story4
    ld (StoryPointer), hl

    ; clear the screen
    ld hl, (ScreenAddr)
    ld a, FILL_COLOR_BLUE
    ClearScreenUnderHLColorFromA
    ret

GoOnWithStory3:
    ; onset of bars
    ld de, STORY3_DURATION - (64 * 4 * 4 - 4 * 4)
    or a
    sbc hl, de
    add hl, de
    jr nc, .NoSlideDownUpdate

    ld a, l
    and 3
    jr nz, .NoSlideDownUpdate

    ld hl, Story3SlideDown
    ld a, 96
    cp (hl)
    jr c, .NoSlideDownUpdate

    inc (hl)

.NoSlideDownUpdate
    push hl
    call FlipScreen

    ; clear the screen
    ld hl, (ScreenAddr)
    ld a, FILL_COLOR_GREY
    ClearScreenUnderHLColorFromA

Story3SlideDown EQU $+1
    ld a, 0
    sub 97
    ld e, a
    add a, a
    sbc a, a
    ld d, a
    ld hl, STORY3_BARPOS
    ld bc, 96 * 256 + STORY3_BARWIDTH
    ld a, COLOR_RED
    call DrawRect

    pop hl
    ld a, l
    and 7
NumTravelersToUpdate equ $+1
    ld a, 1
    jr nz, .SkipIncreasingTravelers
    cp NUM_TRAVELERS
    jr nc, .SkipIncreasingTravelers
    inc a
    ld (NumTravelersToUpdate), a

    ; this loop actually compressed better than DUP'd macro when writing
.SkipIncreasingTravelers:
    ld b, a
    ld ix, Travelers
TravelerUpdateLoop:
        push bc

        bit 7, (ix + Traveler.X)
        jr nz, .ReinitTraveler
        ld a, (ix + Traveler.XSpeed)
        and a
        jr nz, .UpdateTraveler
.ReinitTraveler:
        call rnd
        and $0f
        add 128
        ld (ix + Traveler.X), a
        call rnd
        and $3f
        push af
        call rnd
        and $1f
        pop bc
        add b
        ld (ix + Traveler.Y), a
        call rnd
        and 3
        inc a
        neg
        ld (ix + Traveler.XSpeed), a
        call rnd
        and $7
        cp COLOR_GREY
        jp z, .SetWhiteColor
        cp COLOR_RED
        jp z, .SetWhiteColor
        jr .SetTravelerColor
.SetWhiteColor
        ld a, COLOR_WHITE
.SetTravelerColor
        ld (ix + Traveler.Color), a
.UpdateTraveler
        ld a, (ix + Traveler.Color)
        cp COLOR_WHITE
        push af
        jr z, .PrintTraveler
        ; check bars
        ld a, (Story3SlideDown)
        cp (ix + Traveler.Y)
        ; if Y > bar location, just print the traveler
        jr c, .PrintTraveler:

        ; check if hit the bar
        ld a, (ix + Traveler.X)
        cp STORY3_BARPOS
        jr c, .PrintTraveler:
        cp STORY3_BARPOS + STORY3_BARWIDTH
        jr nc, .PrintTraveler
        ; reflect
        ld a, (ix + Traveler.XSpeed)
        sra a
        neg
        inc a
        ld (ix + Traveler.XSpeed), a
.PrintTraveler:
        ld a, (ix + Traveler.X)
        add (ix + Traveler.XSpeed)
        ld (ix + Traveler.X), a

        ld a, (ix + Traveler.X)
        ld l, a
        ld h, 0     
        ld e, (ix + Traveler.Y) 
        ld d, h
        ld bc, TRAVELER_SIZE * 256 + TRAVELER_SIZE
        pop af
        call DrawRect
        ld de, Traveler
        add ix, de

        pop bc
        dec b
        jp nz, TravelerUpdateLoop
    ret

; ---------------------------------------------------
; Story 4 - Inequality

STORY4_DURATION     EQU 64 * 3 * 4      ;   3 patterns

Story4:
Story4Duration equ $+1
    if (!SPEEDRUN)
        ld hl, STORY4_DURATION
    else
        ld hl, 1
    endif
    dec hl
    ld (Story4Duration), hl
    ld a, h
    or l
    jr nz, GoOnWithStory4

    ; story change!
    ld hl, Story5
    ld (StoryPointer), hl

    ; again disable double-buffering
    ld hl, ScreenAddr + 1
    ld a, $20
    xor (hl)
    ld (hl), a

    ; clear the screen
    ld hl, (ScreenAddr)
    ld a, FILL_COLOR_WHITE
    ClearScreenUnderHLColorFromA
    ret

GoOnWithStory4:
    ld a, l
    and $3
    jr nz, .Story4NoBarsUpdate

    ; slow moving
    ld hl, .Story4SlideRight
    or (hl) ; stop at 0
    jr z, .Story4NoBarsUpdate
    inc (hl)

.Story4NoBarsUpdate
    call FlipScreen

    ; clear the screen
    ld hl, (ScreenAddr)
    ld a, FILL_COLOR_WHITE
    ClearScreenUnderHLColorFromA

    ; sign
    ld de, 8
    ld hl, 32
    ld bc, 56*256 + 64
    ld a, COLOR_DARKBLUE
    call DrawRect

    ld de, 20
    ld hl, 44
    ld bc, 12*256 + 40
    ld a, COLOR_WHITE
    call DrawRect

    ld de, 40
    ld hl, 44
    ld bc, 12*256 + 40
    ld a, COLOR_WHITE
    call DrawRect

.Increase equ $ + 2
.IncreaseOfIncrease equ $+1
    ld de, 0xff0a       ; // IncreaseOfIncrease is -1, Increase as 10

    ld a, e
    test $80
    jr z, .IncreasePositive
    add 3

.IncreasePositive:
    sra a
    sra a

    ; FirstX += (Increase >> 2)
    ; SecondX -= (Increase >> 2)
    push af
    ld hl, .FirstX
    add (hl)
    ld (hl), a
    pop af
    ld hl, .SecondX
    neg
    add (hl)
    ld (hl), a

    ; Increase += IncreaseOfIncrease
    ;if (Increase == -10 || Increase == 10)
    ;{
    ;   IncreaseOfIncrease = -IncreaseOfIncrease;
    ;}
    ld a, e
    add d
    ld e, a
    cp 10
    jr z, .NegIncreaseOfIncrease
    cp -10
    jr nz, .StoreIncreases
.NegIncreaseOfIncrease
    ld a, d
    neg
    ld d, a
.StoreIncreases
    ld (.IncreaseOfIncrease), de

    ld a, COLOR_LIGHTBLUE1
.FirstX equ $+1
    ld hl, 20
    ld de, 70
    ld bc, 12*256 + 40
    call DrawRect

.Story4SlideRight EQU $+1
    ld a, -128
    ld l, a
    add a, a
    sbc a, a
    ld h, a

    push hl ; 89
    push hl ; 74
    push hl ; 59
    push hl ; 44
    push hl ; 29
    push hl ; 14
    push hl ; 0

    ld de, 0
    push de
    ld bc, 46 * 256 + 48
    ld a, COLOR_RED
    call DrawRect

    pop de
    pop hl
    push de
    ld bc, 7*256 + 128
    ld a, COLOR_RED
    call DrawRect

    ;ld de, 14
    pop de
    add de, 14
    pop hl
    push de
    ld bc, 7*256 + 128
    ld a, COLOR_RED
    call DrawRect

    ;ld de, 29
    pop de
    add de, 15
    pop hl
    push de
    ld bc, 7*256 + 128
    ld a, COLOR_RED
    call DrawRect

    ;ld de, 44
    pop de
    add de, 15
    pop hl
    push de
    ld bc, 7*256 + 128
    ld a, COLOR_RED
    call DrawRect

    ;ld de, 59
    pop de
    add de, 15
    pop hl
    push de
    ld bc, 7*256 + 128
    ld a, COLOR_RED
    call DrawRect

    ;ld de, 74
    pop de
    add de, 15
    pop hl
    push de
    ld bc, 7*256 + 128
    ld a, COLOR_RED
    call DrawRect

    ;ld de, 89
    pop de
    add de, 15
    pop hl
    ld bc, 7*256 + 128
    ld a, COLOR_RED
    call DrawRect

    ld a, COLOR_LIGHTBLUE2
.SecondX equ $+1
    ld hl, 68
    ld de, 70
    ld bc, 12*256 + 40
    jp DrawRect

; ---------------------------------------------------
; Story 5 - Red march (Stomping the disorganized)

STORY5_DURATION         EQU 64 * 4 * 4      ; 4 patterns

Story5:
Story5Duration equ $+1
    if (!SPEEDRUN)
        ld hl, STORY5_DURATION
    else
        ld hl, 1
    endif
    dec hl
    ld (Story5Duration), hl
    ld a, h
    or l
    jr nz, GoOnWithStory5

    ; story change!
    ld hl, Story6
    ld (StoryPointer), hl

    ld hl, (ScreenAddr)
    ld a, FILL_COLOR_GREY
    ClearScreenUnderHLColorFromA
    ret

GoOnWithStory5:

.RemainingLeft equ $+1
    ld a, 20
    and a
    jp z, .DoneDrawingLeft
    dec a
    ld (.RemainingLeft), a

    push hl

    dup 4
        call rnd
        and $7f
        push af
        call rnd
        and $1F
        ld l, a
        ld h, 0
        pop de
        ld e, d
        ld d, 0
        ld bc, 8*256 + 8
        and $02
        jr z, 1F
        ld a, COLOR_LIGHTBLUE1
        jr 2F
1
        ld a, COLOR_BLUE
2
        call DrawRect
    edup

    pop hl

.DoneDrawingLeft:
    ld a, l
    and $1f
    ret nz

.MarchX equ $+1
    ld hl, 148
    push hl

    ld b, 10
    ld de, -12
.S5LoopY
    push bc
    push de
    push hl

    ld b, 4
.S5LoopX
    push bc
    push de
    push hl

    push de
    push hl
    ld a, COLOR_WHITE
    ld bc, 8*256 + 16
    call DrawRect
    pop hl
    pop de

    add hl, -8

    ld a, COLOR_RED
    ld bc, 8*256 + 16
    call DrawRect
    
    pop hl
    pop de

    add hl, 32
    add de, 4

    pop bc
    djnz .S5LoopX

    pop hl
    pop de

    add de, 12
    pop bc
    djnz .S5LoopY

    pop hl

    add hl, -8
    ld (.MarchX), hl
    ret

; ---------------------------------------------------
; Story 6 - "Red wave"

Story6:
Story6Duration equ $+1
    ld hl, 64 * 4 * 4       ;   4 patterns
    ;ld hl, 1
    dec hl
    ld (Story6Duration), hl
    ld a, h
    or l
    jr nz, GoOnWithStory6

    ; story change!
    ld hl, Finale
    ld (StoryPointer), hl

    ; clear the screen
    ld hl, (ScreenAddr)
    ld a, FILL_COLOR_RED
    ClearScreenUnderHLColorFromA
    ret

GoOnWithStory6:
.CoordY equ $+1
    if (0)
        ld hl, 94
        ld a, h
        or l
        jr z, .Reddify
        ex de, hl
    else
        ld a, 96
        test $80
        jr nz, .Reddify
        dec a
        dec a
        ld (.CoordY), a
        ld e, a
    endif

    ld b, 64
    ld hl, 0
    ld d, h
.S6DrawLoopX:
    push bc
    exx
    call rnd
    exx
    cp 128
    jr c, .S6SkipDraw
    cp 224
    ld a, COLOR_BLUE
    jr c, .S6Draw
    ld a, COLOR_RED
.S6Draw:
    push de
    push hl
    ld bc, 2*256 + 2
    call DrawRect
    pop hl
    pop de
.S6SkipDraw
    pop bc
    add hl, 2
    djnz .S6DrawLoopX
    ;add de, -2
    ;ld (.CoordY), de
    ret

.Reddify:
    ld a, l
    and $1f
    jr nz, .SkipMove
    ld hl, (ScreenAddr)
    push hl
    pop de
    ld a, (hl)
    inc l
    if (1)
        ld bc, 6144
        ldir
    else
        ld b, 128
.S6ScrollLoop
        ld c, b
        dup 48
            ldi
        edup
        djnz .S6ScrollLoop
    endif
    ld (de), a
.SkipMove

    ld b, 12
.S6BigLoop:
    push bc
    ld hl, (ScreenAddr)
.ScrAddrOffset equ $+1
    ld de, 0
    add hl, de

    if (0)
        exx
        call rnd
        exx
        cp 250
        jr c, .S6SkipRotate

        push de
        push hl

        push hl
        pop de
        ld a, (hl)
        inc l
        ld bc, 64
        ldir
        ld (de), a
        
        pop hl
        pop de
.S6SkipRotate:
    endif


    ld b, 64
.S6RedLoop:
    ld a, FILL_COLOR_RED
    cp (hl)
    jr z, .S6SkipRed
    exx
    call rnd
    exx
    cp 252
    jr c, .S6SkipRed
    ld a, (hl)
    sub $11
    ld (hl), a
.S6SkipRed
    inc hl
    inc de
    djnz .S6RedLoop
    ld a, d
    cp $18
    ex de, hl
    jr c, .StoreOffset
    ld hl, 0
.StoreOffset:
    ld (.ScrAddrOffset), hl

    pop bc
    djnz .S6BigLoop
    ret

; ---------------------------------------------------
; Finale - Their flag

Finale:
FinaleDuration equ $+1
    ld hl, 16 * 4       ;   16 notes
    ;ld hl, 1
    dec hl
    ld (FinaleDuration), hl
    ld a, h
    or l
    jr nz, GoOnWithFinale

    ; the end
    jr $

GoOnWithFinale:
    ld de, 12 * 4
    or a
    sbc hl, de
    add hl, de
    ret nc

    push hl

    ld hl, 46
    ld de, 32
    ld bc, 32*256 + 32
    ld a, COLOR_WHITE
    call DrawRect

    pop hl
    ld de, 8 * 4
    or a
    sbc hl, de
    add hl, de
    ret nc

    push hl

    ld hl, 52
    ld de, 38
    ld bc, 20*256 + 20
    xor a
    call DrawRect

    pop hl
    ld de, 4 * 4
    or a
    sbc hl, de
    add hl, de      ; not needed but compresses better
    ret nc

    ld hl, 56
    ld de, 42
    ld bc, 4*256 + 4
    ld a, COLOR_WHITE
    call DrawRect

    ld hl, 64
    ld de, 42
    ld bc, 4*256 + 4
    ld a, COLOR_WHITE
    call DrawRect

    ld hl, 56
    ld de, 50
    ld bc, 4*256 + 4
    ld a, COLOR_WHITE
    call DrawRect

    ld hl, 64
    ld de, 50
    ld bc, 4*256 + 4
    ld a, COLOR_WHITE
    call DrawRect
    ret

; ---------------------------------------------------
; 8-bit Xor-Shift random number generator.
; Created by Patrik Rak in 2008 and revised in 2011/2012.
; See http://www.worldofspectrum.org/forums/showthread.php?t=23070
; from https://gist.github.com/raxoft/c074743ea3f926db0037

; returns random A
rnd     ld  hl,0xA280   ; yw -> zt
        ld  de,0xC0DE   ; xz -> yw
        ld  (rnd+4),hl  ; x = y, z = w
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
        ld  (rnd+1),hl
        ret 

; ---------------------------------------------------
; Resources

InterruptCtr:
    db 6

    .align 32
InterruptVectors:           ; sorted from highest pri to low (by hardware convention)
    dw DefaultInterruptHandler  ; 0 line interrupt
    dw DefaultInterruptHandler  ; 1 UART0 Rx
    dw DefaultInterruptHandler  ; 2 UART1 Rx
    dw DefaultInterruptHandler  ; 3 CTC channel 0
    dw DefaultInterruptHandler  ; 4 CTC channel 1
    dw DefaultInterruptHandler  ; 5 CTC channel 2
    dw DefaultInterruptHandler  ; 6 CTC channel 3
    dw DefaultInterruptHandler  ; 7 CTC channel 4
    dw DefaultInterruptHandler  ; 8 CTC channel 5
    dw DefaultInterruptHandler  ; 9 CTC channel 6
    dw DefaultInterruptHandler  ; A CTC channel 7
    dw VBlankInterruptHandler   ; B ULA
    dw DefaultInterruptHandler  ; C UART0 Tx
    dw DefaultInterruptHandler  ; D UART1 Tx
    dw DefaultInterruptHandler  ; E
    dw DefaultInterruptHandler  ; F

    macro LORES_COLOR_RGB R, G, B
        db (((R & 7) << 5) | ((G & 7) << 2) | (B & 3))
    endm

COLOR_BLACK         EQU 0
COLOR_RED           EQU 1
COLOR_GREY          EQU 2
COLOR_BLUE          EQU 3
COLOR_WHITE         EQU 4
COLOR_YELLOW        EQU 5
COLOR_DARKBLUE      EQU 6
COLOR_LIGHTBLUE1    EQU 7
COLOR_LIGHTBLUE2    EQU 8

; same colors but for the whole byte, e.g. when screen filling
FILL_COLOR_RED          EQU ((COLOR_RED << 4) | COLOR_RED)
FILL_COLOR_WHITE        EQU ((COLOR_WHITE << 4) | COLOR_WHITE)
FILL_COLOR_YELLOW       EQU ((COLOR_YELLOW << 4) | COLOR_YELLOW)
FILL_COLOR_BLUE         EQU ((COLOR_BLUE << 4) | COLOR_BLUE)
FILL_COLOR_GREY         EQU ((COLOR_GREY << 4) | COLOR_GREY)
FILL_COLOR_DARKBLUE     EQU ((COLOR_DARKBLUE << 4) | COLOR_DARKBLUE)
FILL_COLOR_LIGHTBLUE1   EQU ((COLOR_LIGHTBLUE1 << 4) | COLOR_LIGHTBLUE1)
FILL_COLOR_LIGHTBLUE2   EQU ((COLOR_LIGHTBLUE2 << 4) | COLOR_LIGHTBLUE2)

; since we first display $4000, begin writing with $6000
ScreenAddr  dw $6000

    if (USE_DMA)    ; Never actually got used
; byte to fill memory with
DmaSourceByte:
    db      0

DmaInitData:
    hex C3 C3 C3 C3 C3 C3       ; reset DMA from any possible state (6x reset command)
    db  %10'0'0'0010            ; WR5 = stop on end of block, /CE only
    db  %1'0'000000             ; WR3 = all disabled (important only for real DMA chips)
    db  %0'01'11'1'01           ; WR0 = A->B transfer
    dw  DmaSourceByte           ; + port address A (byte to fill memory with)
    db  0                       ; + size.LO = always zero
    db  %0'1'10'0'100           ; WR1 = A address fixed, memory
    db  2                       ; + custom 2T timing
    db  %0'1'01'0'000           ; WR2 = B address ++, memory
    db  2                       ; + custom 2T timing
    db  %1'01'0'01'01           ; WR4 = continuous mode
    db  0                       ; + port address B.LO = always zero
DmaInitSize: EQU $ - DmaInitData

DmaClearPixels:
DmaClearAddrHiByte equ $+1
    db  %1'01'0'10'01, $00      ; WR4: addresB.HI = $00 (no other change)
    db  %0'10'00'1'01, $01      ; WR0: size.HI = $100 (no other change) for 256x192x8bpp
    hex CF 87                   ; LOAD + ENABLE (transfer is executed)
dmaClearPixelsSize: EQU $ - dmaClearPixels

    endif ; USE_DMA

LoresPalette:
    ; Black
    db 0
    ; red
    LORES_COLOR_RGB 7, 0, 0     ; 1
    ; grey
    LORES_COLOR_RGB 4, 4, 2     ; 2
    ; blue
    LORES_COLOR_RGB 0, 0, 3     ; 3
    ; white
    LORES_COLOR_RGB 7, 7, 3     ; 4
    ; yellow
    LORES_COLOR_RGB 7, 7, 0     ; 5
    ; dark blue
    LORES_COLOR_RGB 0, 0, 1     ; 6
    ; light blue 1
    LORES_COLOR_RGB 0, 3, 2     ; 7
    ; light blue 2
    LORES_COLOR_RGB 0, 7, 3     ; 8

    block 7

    STRUCT Traveler
X       db 0
XSpeed  db 0
Y       db 0
Color   db 0
    ENDS

Travelers:
    block 64 * Traveler

; ---------------------------------------------------------------------------------------------------------------------------------
; Handling of the music
; 

    ; Checks if reg value is the same as the previous and if not, outputs it to an AY register
    ; Expects: A to hold the register value, A' to hold the reg number, HL' to hold the prev value pointer for the correct register (will increment it)
    MACRO Output8BitAYRegValueIfNotSame
      exx
      ld bc, $fffd
      ex af, af'
      out (c), a
      inc a
      ex af, af'
      cp (hl)
      jr z, .SkipSameValue1
      ld b, $bf
      out (c), a  
      ld (hl), a
.SkipSameValue1
      inc hl
      exx
    ENDM

    ; Macro to get a value for a singular AY register
    ; Since the values are stored one per each update, we just use the global offset
    ; HL is the addres in that block of values
    ; DE is a size of a file of values for a 8-bit register
    MACRO Update8BitAYRegisterValue
      ld a, (hl)
      Output8BitAYRegValueIfNotSame
      add hl, de
    ENDM

    ; tones are stored as two registers together for better compression
    ; Since the values are stored one per each update, we just use the global offset
    ; HL is the addres in that block of values
    MACRO UpdateAYToneValue
      ld a, (hl)
      Output8BitAYRegValueIfNotSame
      inc hl
      ld a, (hl)
      Output8BitAYRegValueIfNotSame
      add hl, de
    ENDM

MusicPlayerBeforeMoving:
    disp MUSIC_PLAYER_LOCATION

    ; map pages 16-22 for the tones (take 48678 bytes), starting from $0000
    ld a, 16
    nextreg MMU0_0000_NR_50, a
    inc a
    nextreg MMU1_2000_NR_51, a
    inc a
    nextreg MMU2_4000_NR_52, a
    inc a
    nextreg MMU3_6000_NR_53, a
    inc a
    nextreg MMU4_8000_NR_54, a
    inc a
    nextreg MMU5_A000_NR_55, a
    push af

    ; start with 0th AY register and beginning of PrevRegs block
    xor a
    ex af, af'
    ld hl, PrevRegs
    exx

UpdateCount EQU $+1
    ld hl, $ffff
    inc hl

    ld de, 7616
    or a
    sbc hl, de
    add hl, de
    ;jp nc, MainUpdate
    ret nc
    ld (UpdateCount), hl

    push de
    push hl

    ; for tones, we need to multiply the hl by two
    ; the memory is mapped from 0, so we don't need any offset
    add hl, hl
    ;ld de, 16256 - 1   ; -1 because we increment HL when getting the second tone value
    ld de, 15232 - 1    ; -1 because we increment HL when getting the second tone value

    UpdateAYToneValue   ; A
    UpdateAYToneValue   ; B
    UpdateAYToneValue   ; C

    pop hl
    pop de
    ;ld de, 8128
    ;ld de, 7616

    ; map next 8 pages for the regs
    pop af
    inc a
    nextreg MMU0_0000_NR_50, a
    inc a
    nextreg MMU1_2000_NR_51, a
    inc a
    nextreg MMU2_4000_NR_52, a
    inc a
    nextreg MMU3_6000_NR_53, a
    inc a
    nextreg MMU4_8000_NR_54, a
    inc a
    nextreg MMU5_A000_NR_55, a
    inc a
    nextreg MMU6_C000_NR_56, a
    push af

    Update8BitAYRegisterValue   ; reg 6
    Update8BitAYRegisterValue   ; reg 7
    Update8BitAYRegisterValue   ; reg 8
    Update8BitAYRegisterValue   ; reg 9
    Update8BitAYRegisterValue   ; reg 10
    Update8BitAYRegisterValue   ; reg 11

    ; need to jump one value as we skip reg 12
    ex af, af'
    inc a
    ex af, af'

    Update8BitAYRegisterValue   ; reg 13

    ; map next 3 pages for the code, starting from $8000 - back
    pop af

    if (!VERSION_FOR_LOCAL_DEBUG)
        inc a
        nextreg MMU4_8000_NR_54, a
        inc a
        nextreg MMU5_A000_NR_55, a
        inc a
        nextreg MMU6_C000_NR_56, a
    else
        ; default banks
        nextreg MMU4_8000_NR_54, 4
        nextreg MMU5_A000_NR_55, 5
        nextreg MMU6_C000_NR_56, 0
    endif

    ; page the screens back
    nextreg MMU2_4000_NR_52, 10
    nextreg MMU3_6000_NR_53, 11
    
    if (DEBUG_MUSIC_REGS)
        ; deep debug!
        ld b, 13
        ld hl, PrevRegs
ScrAddress EQU $+1
        ld de, $4000
DebugLoop:
        ld a, (hl)
        ld (de), a
        inc hl
        inc de
        ld a, d
        cp $58
        jr c, .NoResetDE
        ld d, $40
.NoResetDE
        djnz DebugLoop
        ld (ScrAddress), de

        ld hl, (UpdateCount)
        inc hl
    endif

    ret
    ; return to the caller
    ;jp MainUpdate

PrevRegs:
    db $ff, $ff, $ff, $ff
    db $ff, $ff, $ff, $ff
    db $ff, $ff, $ff, $ff
    db $ff, $ff
    ent ; restore the address
MusicPlayerSize EQU $-MusicPlayerBeforeMoving

    ; we should not allow the main program to overflow into the music player area
    ASSERT $ < MUSIC_PLAYER_LOCATION
    DISPLAY "Last address is ", /A, $

    savebin "sup_main.bin", savebin_begin, $-savebin_begin

    if (VERSION_FOR_LOCAL_DEBUG)
        ; include uncompressed music at the right pages
        ; TonesABC - pages 16-21
        SLOT 0
        PAGE 16

        SLOT 1
        PAGE 17

        SLOT 2
        PAGE 18

        SLOT 3
        PAGE 19

        SLOT 4
        PAGE 20

        SLOT 5
        PAGE 21

        org $0000
        incbin "../res/tonesABC.bin"

        ; Reg 6-13 - pages 22 - 28
        SLOT 0
        PAGE 22

        SLOT 1
        PAGE 23

        SLOT 2
        PAGE 24

        SLOT 3
        PAGE 25

        SLOT 4
        PAGE 26

        SLOT 5
        PAGE 27

        SLOT 6
        PAGE 28

        org $0000
        incbin "../res/regs6-13.bin"

        SAVENEX OPEN "sup_main.nex", savebin_begin, $FFFF
        SAVENEX CORE 3, 0, 0
        SAVENEX CFG 0, 0, 1, 0
        SAVENEX AUTO
        SAVENEX CLOSE
    endif
