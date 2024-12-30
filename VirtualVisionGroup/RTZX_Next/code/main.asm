    device ZXSPECTRUMNEXT

    include "constants.i.asm"

; Ray grid size. Radastan 128x96 mode is used for video, but each ray hits 2x2 pixels. Essentially unchangeable without changing interpolation code.
GRID_WIDTH              EQU 64
GRID_HEIGHT             EQU 48

; Number of spheres in any scene. Some loops are unrolled this many times.
NUM_SPHERES             EQU 3

; 9.7 fixed point is used. A lot of code depends on that, so this is unchangable
FIXEDPOINT_SCALER       EQU 128

; Scene constants. Some code assumes those (particularly avoiding multiplication by DIR_Z), so not easy to change without a thorough audit
DIR_Z                   EQU (1 * FIXEDPOINT_SCALER)
MAX_DIST                EQU (64 * FIXEDPOINT_SCALER)
PLANE_Y                 EQU (-2 * FIXEDPOINT_SCALER)

; Light constants. There are macros in math.i.asm that assume those, and would need to be changed if the constants are changed.
DIR_LIGHT_X             EQU ((-577 * FIXEDPOINT_SCALER) / 1000)
DIR_LIGHT_Y             EQU ((577 * FIXEDPOINT_SCALER) / 1000)
DIR_LIGHT_Z             EQU ((-577 * FIXEDPOINT_SCALER) / 1000)
DIR_LIGHT_A             EQU 246

; Structure used to describe a sphere
    STRUCT  Sphere
X               dw 0
Y               dw 0
Z               dw 0
unused          dw 0
C               dw 0
ScreenCenterX   db 0
ScreenRadX      db 0
ScreenCenterY   db 0
ScreenRadY      db 0
    ENDS

; Since Radastan 128x96 mode is 4bpp, this is a hard limit
MAX_BRIGHTNESS              EQU 15

; Assemble for ZX Spectrum Next, using Z80N instructions. RTZX Next will no longer assemble without them as non-Z80N fallback path isn't provided.
ZX_NEXT                     EQU 1

; This is independent of the actual screen refresh. We can have 60Hz screen refresh but the logical updates (including music updates) will happen at this rate (CTC is used).
LOGICAL_FRAMES_PER_SECOND   EQU 50

; Speed profiling defines
; This profiles a single scene raycast. Set MAX_RAYS_TO_TRACE to see the absolute speed
PROFILE_RAYCAST             EQU 0
; This profiles a single fill-interpolate routine for the fullscreen interpoplation
PROFILE_QUAD_FILLERS        EQU 0
; switches the whole binary into profiling division only 
PROFILE_DIVISION_ONLY       EQU 0

; These turn on border colors around the respective procedures. Mostly useful with PROFILE_RAYCAST on and MAX_RAYS_TO_TRACE set to a small value, so frame structure can be analyzed.
PROFILE_MULTIPLY            EQU 0
PROFILE_DIVISION            EQU 0

    if (PROFILE_RAYCAST)
;MAX_RAYS_TO_TRACE          EQU 10; Z80 math code from RTZX only allows 10 rays/frame at 28 Mhz
;MAX_RAYS_TO_TRACE          EQU 20; RTZX Next party version shipped with 20 rays/frame at 28 Mhz
;MAX_RAYS_TO_TRACE          EQU 36; current result at 28 Mhz - with the rays not hitting the spheres
MAX_RAYS_TO_TRACE           EQU (GRID_WIDTH * GRID_HEIGHT)
    endif

; Adds some debug-only code to detect things that shouldn't normally happen
DEBUG                       EQU 0

; Controls subdivision of rays 
SPAN_Y_TO_STOP_SUBDIV       EQU 4
SPAN_X_TO_STOP_SUBDIV       EQU 4

PERTURB_NORMAL              EQU 1
VARY_SKYCOLOR               EQU 1

; this 24/8 optimization is actually not helpful, does not occur on the real valeus
FASTPATH_FOR_8BIT_DIVISORS  EQU 0

    ; debugging macro for assertions that fail in runtime
    macro CHANGE_BORDER  BorderColor
        ld a, BorderColor
        nextreg TRANSPARENCY_FALLBACK_COL_NR_4A, a
        out (#fe), a
    endm

    macro CHANGE_BORDER_AND_LOCKUP  BorderColor
        CHANGE_BORDER BorderColor
        dw $fd  ; CSpect break opcode
        jr $
    endm

    include "math_macros.i.asm"

    ; this is 'LoRes' 128x96x4bpp screen
    macro SET_VIDEOMODE_LORES
        nextreg SPRITE_CONTROL_NR_15, 0x80 ; enable LoRes
        nextreg PALETTE_CONTROL_NR_43, 1 ; enable ULAnext mode
        ld hl, LoresPalette
        call SetupPalette
    endm

    macro SET_VIDEOMODE_ULA
        nextreg SPRITE_CONTROL_NR_15, 0x00
        nextreg PALETTE_CONTROL_NR_43, 0 ; disable ULAnext mode
        ld hl, ULAClassicPalette
        call SetupPalette
    endm

; -----------------------------------------------------------------------------------------
; Main code begins here
; -----------------------------------------------------------------------------------------
    org #8000

savebin_begin:
    di
    nextreg TURBO_CONTROL_NR_07, 3  ; 28 Mhz

    ; Setting transparent color to a value above the palette seems to allow non-transparent paper
    nextreg GLOBAL_TRANSPARENCY_NR_14, 0x11
    nextreg TRANSPARENCY_FALLBACK_COL_NR_4A, 0 ; fallback color = 0
    nextreg ENHANCED_ULA_INK_COLOR_MASK_42, 0xff ; ulanext color mask

    ; Which LoRes screen to show ($4000 or $6000) is also affected by Timex regs, so I was thinking to set them to a known value.
    ; However the Timex regs seem to be set to a value that allows the expected control from LoRes side, so I decided not to mess with them.
    ;ld a, 0
    ;nextreg TIMEX_MODE_CONTROL_FF, a 
    ;ld bc, TIMEX_MODE_CONTROL_FF
    ;out (c), a

    ; clear screens, the first one together with the attributes
    ld hl, #5800
    ld de, #5801
    ld bc, #2ff
    ld (hl), l
    ldir

    ld hl, #4000
    ld de, #4001
    ld bc, #17ff
    ld (hl), l
    ldir

    ld hl, #6000
    ld de, #6001
    ld bc, #17ff
    ld (hl), l
    ldir

    if (!PROFILE_DIVISION_ONLY) ;    // not convenient when setting a breakpoint in sdiv16, as this will hit it first
        call PrecomputeXYDirsAndPlaneZ
    endif

    call InitMusic
    call SetupInterrupts
    ei

    ; -------------------------------------------------------------------------
    ; Various debugging/profiling modes to aid debugging/optimization
    if (PROFILE_DIVISION_ONLY)
ProfileLoop:
        call WaitVBlank
        CHANGE_BORDER 1
        ld b, 36
ProfileLoopInner:
            push bc
            CHANGE_BORDER 3
            ld hl, #0234
            ld bc, #0076; #00f6
            SDIV16
            ; expected result
            ld de, #0263; #0125

            or a
            sbc hl, de
            jr z, Passed1
            CHANGE_BORDER_AND_LOCKUP 3
Passed1:

            CHANGE_BORDER 4
            ld hl, #a406
            ld bc, #017e
            SDIV16
            ld de, #e12f

            or a
            sbc hl, de
            jr z, Passed2
            CHANGE_BORDER_AND_LOCKUP 3
Passed2:

            CHANGE_BORDER 5
            ld hl, #ff00
            ld bc, #ffc0
            SDIV16
            ld de, #0200

            or a
            sbc hl, de
            jr z, Passed3
            CHANGE_BORDER_AND_LOCKUP 3
Passed3:

            CHANGE_BORDER 6
            ld hl, #9fdc
            ld bc, #017a
            SDIV16
            ld de, #df72            

            or a
            sbc hl, de
            jr z, Passed4
            CHANGE_BORDER_AND_LOCKUP 3
Passed4:

            pop bc
        dec b
        jp nz, ProfileLoopInner
        CHANGE_BORDER 2
        jp ProfileLoop
    endif


    if (PROFILE_RAYCAST)
        SET_VIDEOMODE_LORES
        ld hl, $4000
        call ClearScreenBuffer
        call Display4000Screen
        call WriteTo4000Screen

        ld hl, Spheres_View1
        call SetAsActiveScene

        ;ld hl, SubdivInterpRoutine_FillRandomColor
        ;ld (RaytraceSubdiv_InterpRoutine), hl

ProfileLoop:
        call WaitVBlank
        call raytrace
        ;call RaytraceSubdiv
        jr ProfileLoop
    endif

    if (PROFILE_QUAD_FILLERS)
        SET_VIDEOMODE_LORES
        call Display4000Screen
        call WriteTo6000Screen

        ld iy, QuadToDraw
        xor a
        ; initialize all corners area
        ld (iy + Area5.Ray0.ScreenX), a
        ld (iy + Area5.Ray0.ScreenY), a
        ld (iy + Area5.Ray0.Value), 15

        ld (iy + Area5.Ray1.ScreenX), 63
        ld (iy + Area5.Ray1.ScreenY), a
        ld (iy + Area5.Ray1.Value), 0

        ld (iy + Area5.Ray2.ScreenX), a
        ld (iy + Area5.Ray2.ScreenY), 47
        ld (iy + Area5.Ray2.Value), 0

        ld (iy + Area5.Ray3.ScreenX), 63
        ld (iy + Area5.Ray3.ScreenY), 47
        ld (iy + Area5.Ray3.Value), 0

ProfileLoop:
        call WaitVBlank

        nextreg TRANSPARENCY_FALLBACK_COL_NR_4A, 0xFF
        ; set span x and y to be fullscreen
        ld bc, 48*256+64
        call SubdivInterpRoutine_FillInterpolate
        ld a, (perf_border_color)
        nextreg TRANSPARENCY_FALLBACK_COL_NR_4A, a  
        call FlipDoubleBuffer

        jr ProfileLoop

        // increment all values in a loop
IncDelay equ $+1
        ld a, 1
        dec a
        ld (IncDelay), a
        jr nz, ProfileLoop
        ld a, 50
        ld (IncDelay), a

        ld a, (iy + Area5.Ray1.Value)
        inc a
        and #0f
        ld (iy + Area5.Ray1.Value), a

        if 0
        ld b, 4
        push iy
        pop ix
        ld de, RayDesc
Corner_Inc_Loop:
            ld a, (ix + RayDesc.Value)
            inc a
            and #0f
            ld (ix + RayDesc.Value), a
            add ix, de
        djnz Corner_Inc_Loop
        endif

        jr ProfileLoop

QuadToDraw:
        block (Area5)
    endif

    ; -------------------------------------------------------------------------
    ; Main code continues.
    ; --- script start
    SET_VIDEOMODE_ULA

    ld hl, FirstScreen
    ld de, #6000
    call dzx0_standard

    ld hl, 1 * LOGICAL_FRAMES_PER_SECOND
    call WaitUntilHLFrame

    ld hl, #6000
    call PopUpScreen

    ld hl, SecondScreen
    ld de, $6000
    call dzx0_standard

    ld hl, (33 * LOGICAL_FRAMES_PER_SECOND) / 2
    call WaitUntilHLFrame
    
    ld hl, $6000
    call PopUpScreen

    ld hl, 34 * LOGICAL_FRAMES_PER_SECOND
    call WaitUntilHLFrame

    ; switch to LoRes
    SET_VIDEOMODE_LORES
    ld hl, $4000
    call ClearScreenBuffer
    call Display4000Screen
    call WriteTo4000Screen

    ; set it to draw to the primary screen
    ld hl, #4000
    ld (ScreenStart), hl

    ; RTZX Scene Go!
    ld hl, Spheres_From_RTZX
    call SetAsActiveScene
    call raytrace

    ld hl, 37 * LOGICAL_FRAMES_PER_SECOND
    call WaitUntilHLFrame
    ; Second scene go!
    ld hl, Spheres_View2
    call SetAsActiveScene
    call raytrace

    ld hl, 41 * LOGICAL_FRAMES_PER_SECOND
    call WaitUntilHLFrame
    ; Third scene go!
    ld hl, Spheres_View3
    call SetAsActiveScene
    call raytrace

    ld hl, 45 * LOGICAL_FRAMES_PER_SECOND
    call WaitUntilHLFrame
    ; Fourth scene go!
    ld hl, Spheres_View4
    call SetAsActiveScene
    call raytrace

    ld hl, 48 * LOGICAL_FRAMES_PER_SECOND
    call WaitUntilHLFrame

    ld hl, TitleScreen
    ld de, $6000
    call dzx0_standard

    ld hl, #4000
    call ClearScreenBuffer

    ld bc, 16 * 256 + 1
SLowDownFlipOuterLoop:
    call FlipDisplayedScreen
    push bc
    ld b, c
SLowDownFlipInnerLoop:
    call WaitVBlank
    djnz SLowDownFlipInnerLoop
    pop bc
    inc c
    djnz SLowDownFlipOuterLoop

    call Display6000Screen

    ld hl, 53 * LOGICAL_FRAMES_PER_SECOND
    call WaitUntilHLFrame

    ; set it to draw to the shadow screen
    ld hl, #6000
    ld (ScreenStart), hl

    ; realtime effect 1!
    ld hl, SubdivInterpRoutine_FillInterpolate
    ld (RaytraceSubdiv_InterpRoutine), hl
    ld hl, (Frame)
    ld (Effect1_StartFrame), hl

    ; we're showing the $6000 screen, write to $4000
    call WriteTo4000Screen

    ld hl, $6000
    call ClearScreenBuffer

RealtimeEffect1:
    call Effect1Update
    call RaytraceSubdiv
    call FlipDoubleBuffer
    ld hl, 60 * LOGICAL_FRAMES_PER_SECOND
    call IsAtFrameOrLater
    jr c, RealtimeEffect1

    ; --- realtime effect 2

    ld hl, (Frame)
    ld (Effect2_StartFrame), hl

    ; realtime effect 2!
RealtimeEffect2:
    call Effect2Update
    call RaytraceSubdiv

    call FlipDoubleBuffer

    ld hl, 68 * LOGICAL_FRAMES_PER_SECOND
    call IsAtFrameOrLater
    jr c, RealtimeEffect2

    ; ----- cha-cha in the music
    ; change to squares
    ld hl, SubdivInterpRoutine_FillAverage
    ld (RaytraceSubdiv_InterpRoutine), hl

RealtimeEffect2_1:
    call Effect2Update
    call RaytraceSubdiv
    call FlipDoubleBuffer
    ld hl, 72 * LOGICAL_FRAMES_PER_SECOND
    call IsAtFrameOrLater
    jr c, RealtimeEffect2_1

    ; ----- another cha-cha in the music
    ld hl, SubdivInterpRoutine_PlotRays
    ld (RaytraceSubdiv_InterpRoutine), hl

RealtimeEffect2_2:
    ld hl, (ScreenStart)
    call ClearScreenBuffer
    call Effect2Update
    call RaytraceSubdiv
    call FlipDoubleBuffer
    ld hl, 76 * LOGICAL_FRAMES_PER_SECOND
    call IsAtFrameOrLater
    jr c, RealtimeEffect2_2

    ; to the effect for a little bit
    ld hl, SubdivInterpRoutine_FillInterpolate
    ld (RaytraceSubdiv_InterpRoutine), hl

RealtimeEffect2_2a:
    ld hl, (ScreenStart)
    call Effect2Update
    call RaytraceSubdiv
    call FlipDoubleBuffer
    ld hl, 80 * LOGICAL_FRAMES_PER_SECOND
    call IsAtFrameOrLater
    jr c, RealtimeEffect2_2a

    ; -- show the areas
    ld hl, SubdivInterpRoutine_FillRandomColor
    ld (RaytraceSubdiv_InterpRoutine), hl

RealtimeEffect2_2b:
    call Effect2Update
    call RaytraceSubdiv
    call FlipDoubleBuffer
    ld hl, 82 * LOGICAL_FRAMES_PER_SECOND
    call IsAtFrameOrLater
    jr c, RealtimeEffect2_2b

    ; again back to the effect for a little bit
    ld hl, SubdivInterpRoutine_FillInterpolate
    ld (RaytraceSubdiv_InterpRoutine), hl

RealtimeEffect2_2c:
    ld hl, (ScreenStart)
    call Effect2Update
    call RaytraceSubdiv
    call FlipDoubleBuffer
    ld hl, 83 * LOGICAL_FRAMES_PER_SECOND
    call IsAtFrameOrLater
    jr c, RealtimeEffect2_2c


    ; -- explain the tricks
RealtimeEffect2_3_PR:
    call Effect2Update

    ld hl, SubdivInterpRoutine_FillAverage
    ld (RaytraceSubdiv_InterpRoutine), hl
    call RaytraceSubdiv

    ld hl, SubdivInterpRoutine_PlotRays
    ld (RaytraceSubdiv_InterpRoutine), hl
    call RaytraceSubdiv
    call FlipDoubleBuffer
    ld hl, 87 * LOGICAL_FRAMES_PER_SECOND
    call IsAtFrameOrLater
    jr c, RealtimeEffect2_3_PR

RealtimeEffect1_3:
    call Effect2Update
    call raytrace
    call FlipDoubleBuffer
    ld hl, 107 * LOGICAL_FRAMES_PER_SECOND
    call IsAtFrameOrLater
    jr c, RealtimeEffect1_3

    ld hl, $4000
    call ClearScreenBuffer

    ld hl, $6000
    call ClearScreenBuffer

    ld hl, SubdivInterpRoutine_FillInterpolate
    ld (RaytraceSubdiv_InterpRoutine), hl
    ; Effect 3 reuses the update of Effect 2, reset the frame to the moment we know looks good
    ld hl, (Effect2_StartFrame)
    ld de, 2 * LOGICAL_FRAMES_PER_SECOND
    or a
    sbc hl, de
    ld (Effect2_StartFrame), hl

RealtimeEffect3_1:
    call Effect3Update
    call RaytraceSubdiv
    call FlipDoubleBuffer
    ld hl, 110 * LOGICAL_FRAMES_PER_SECOND
    call IsAtFrameOrLater
    jr c, RealtimeEffect3_1

    ; -- show the final picture
    ; clear both screens
    ld hl, $4000
    call ClearScreenBuffer

    ld hl, $6000
    call ClearScreenBuffer

    ld hl, $5800
    ld de, $5801
    ld (hl), l
    ld bc, $2ff
    ldir
    SET_VIDEOMODE_ULA

    ld hl, DemosplashLogo
    ld de, $6000
    call dzx0_standard

    ld hl, $6000
    call PopUpScreenFast

    ; overall time:
    ; 1m 53 sec

    ; which is 113 sec
    ld hl, 113 * LOGICAL_FRAMES_PER_SECOND
    call WaitUntilHLFrame
    di
            ld c,#fd
            ld hl,#ffbf
            ld de,#0d00
SilenceAY:
            ld b,h
            out (c),d
            ld b,l
            out (c),e
            dec d
            jr nz,SilenceAY

    di
    halt
    ; unreachable
    jr $

; -----------------------------------------------------------------------------------------------------------------------
; Screen Switcheroo
LastUsedReg6A:
    db $20

LastScreenAddrToWrite:
    dw $4000

Display6000Screen:
    ld a, #30
    ld (LastUsedReg6A), a
    nextreg LORES_CONTROL_NR_6A, a
    ret

Display4000Screen:
    ld a, #20
    ld (LastUsedReg6A), a
    nextreg LORES_CONTROL_NR_6A, a
    ret

FlipDisplayedScreen:
    ld a, (LastUsedReg6A)
    xor #10
    ld (LastUsedReg6A), A
    nextreg LORES_CONTROL_NR_6A, a
    ret

WriteTo4000Screen:
    ld hl, $4000
    ld (ScreenStart), hl
    ld (LastScreenAddrToWrite), hl
    ret

WriteTo6000Screen:
    ld hl, $6000
    ld (ScreenStart), hl
    ld (LastScreenAddrToWrite), hl
    ret

FlipWrittenToScreen:
    ld hl, (LastScreenAddrToWrite)
    ld a, h
    xor $20
    ld h, a
    ld (ScreenStart), hl
    ld (LastScreenAddrToWrite), hl
    ret

FlipDoubleBuffer:
    call FlipDisplayedScreen
    jp FlipWrittenToScreen

; -----------------------------------------------------------------------------------------------------------------------
; Clear the shadow screen to the main one
ClearScreenBuffer:
    ; TODO: use DMA
    ld d, h
    ld e, l
    inc e
    ld (hl), l
    ld bc, #17ff
    ldir
    ret

; ------------------------------------------------------------------
; Helper structures for RaytraceSubdiv

; Descriptor of a single ray
    STRUCT  RayDesc
ScreenX byte 0
ScreenY byte 0
Attr    byte 0
Value   byte 0
    ENDS

; Descriptor of an area
; Visually, this is how it is expected:

;  Ray0          Ray1
;         Ray4
;  Ray2          Ray3
    STRUCT Area5
Ray0    RayDesc 0
Ray1    RayDesc 0
Ray2    RayDesc 0
Ray3    RayDesc 0
Ray4    RayDesc 0
    ENDS

; flags used by the attributes                   
RAYATTR_SPHEREMASK  EQU #0f
RAYATTR_PLANEHIT    EQU #10
RAYATTR_INSHADOW    EQU #20

; for flips 4000-6000
ScreenStart:
    dw #4000

; -----------------------------------------------------------------------------------------------------------------------
; One of raytrace interpolation options
; In: IY: current area, B - Span Y, C - Span X (already in 2-pixel "chunks")
SubdivInterpRoutine_FillInterpolate:
    ld hl, (ScreenStart)
    ld e, (iy + Area5.Ray0.ScreenX)
    ld d, (iy + Area5.Ray0.ScreenY)

    ; For 2x2 chunks, we need an adress like Screen + 128*D + E.
    rl e
    rr d
    rr e
    add hl, de
    push hl

    ; process power of N cases
    ld ix, #101

    ; decide on the divisors for SpanX and SpanY
    ld h, high Spans_To_256_Div_Span_Table
    ld l, b
    ld a, (hl)
    ld ixh, a

    ld l, c
    ld a, (hl)
    ld ixl, a

    ; intentional fall-through

; -----------------------------------------------------------------------------------------------------------------------
; Subroutine interpolating M x N area, where M, N are PowersOfTwo
; In: IY: current area, B - Span Y, C - Span X (already in 2-pixel "chunks"), IXH, IXL - reciprocals of thoses spans (so e.g. if B == SpanY is 8, IXH is 256 / SpanY == 32)
SIRFI_Interp_XY:
    ld a, b
    ;dec a
    ld (SIRFI_IXY_LoopYCounter), a
    ld a, c
    ;dec a
    ld (SIRFI_IXY_LoopXCounter), a
    ld a, 64
    sub c
    ld e, a
    ld d, 7     ; size of the Unrollep X Loop DUP body
    mul
    add de, SIRFI_IXY_UnrolledXLoopStart
    ld (SIRFI_IXY_UnrolledXLoop_StartJump), de

    ; calculate RightValue and RightIncrement
    ; short RightValue = static_cast<short>(Top.Rays[1].RayValue) << 8;
    ; short RightIncrement = ((static_cast<short>(Top.Rays[3].RayValue) << 8) - RightValue) / SpanY;
    exx

    ld a, (iy + Area5.Ray3.Value)
    sub (iy + Area5.Ray1.Value)
    ; a is a signed difference of Ray3.Value - Ray1.Value
    ; now we need to multiply it by 256 and divide by SpanY
    ; we can do that by multiplying A by 256/SpanY instead
    ; if a is negative, we have to treat it differently
    ld e, ixh
    jr c, .SIRFI_Interp_XY_NegRightIncrement

    ld d, a
    mul
    ld b, d
    ld c, e
    jp .SIRFI_Interp_XY_RightIncrementDone

.SIRFI_Interp_XY_NegRightIncrement:
    neg
    ld d, a
    mul
    xor a
    ld h, a
    ld l, a
    sbc hl, de
    ld b, h
    ld c, l
.SIRFI_Interp_XY_RightIncrementDone:
    ld a, (iy + Area5.Ray1.Value)
    ld h, a
    ld l, 0
    exx
    ; now hl' holds RightValue, bc' holds RightIncrement

    ; calculate LeftValue and LeftIncrement
    ld a, (iy + Area5.Ray2.Value)
    sub (iy + Area5.Ray0.Value)
    ; a is a signed difference of Ray2.Value - Ray0.Value
    ; now we need to multiply it by 256 and divide by SpanY
    ; we can do that by multiplying A by 256/SpanY instead
    ; if a is negative, we have to treat it differently
    ld e, ixh
    jr c, .SIRFI_Interp_XY_NegLeftIncrement

    ld d, a
    mul
    ld b, d
    ld c, e
    jp .SIRFI_Interp_XY_LeftIncrementDone

.SIRFI_Interp_XY_NegLeftIncrement:
    neg
    ld d, a
    mul
    xor a
    ld h, a
    ld l, a
    sbc hl, de
    ld b, h
    ld c, l
.SIRFI_Interp_XY_LeftIncrementDone:
    ld a, (iy + Area5.Ray0.Value)
    ld h, a
    ld l, 0
    ; hl holds LeftValue, bc holds LeftIncrement

    pop de  ; get back the screen addr

    push iy
SIRFI_IXY_LoopYCounter equ $+2
    ld iyh, 0

SIRFI_IXY_LoopY:
        push bc
        push hl
        push de
        
        ; hl contains LeftValue, hl' - Right Value
        ; calculate BC = (RightValue - LeftValue) / SpanX
        push hl
        push de

        exx
        ;ld a, h
        push hl
        exx
        pop de
        ex de, hl
        or a
        sbc hl, de

        ; since the colors are 0-15, we can multiply with a little more precision. 
        ; instead of dC = C * (256 / W) / 256,  we do dC = C * 4 * (256 / W) / (256 * 4)
        ;set it here, as the code below doesn't change B
        ld b, 2

        ; HL now holds (Right-Left) value
        ; now we need to multiply it by 256 and divide by SpanX
        ; we can do that by multiplying A by 256/SpanX instead

        ; if value is negative, we have to treat it differently
        jr c, .SIRFI_Interp_XY_NegXIncrement

        ex de, hl
        bsla de, b
        ld e, ixl
        mul
        bsra de, b

        ld b, d
        ld c, e
        jp .SIRFI_Interp_XY_XIncrementDone

.SIRFI_Interp_XY_NegXIncrement:
        ; "neg hl"
        ex de, hl
        xor a
        ld h, a
        ld l, a
        sbc hl, de

        ex de, hl
        bsla de, b
        ld e, ixl
        mul
        ;add de, -128

        ; another neg
        xor a
        ld h, a
        ld l, a
        sbc hl, de

        ex de, hl
        bsra de, b  ; b still holds shift value 
        ld b, d
        ld c, e
.SIRFI_Interp_XY_XIncrementDone:
        
        pop de      ; restore screen address
        pop hl      ; restore LeftValue
        push de     ; needed for cloning later

SIRFI_IXY_UnrolledXLoop_StartJump equ $+1
        jp SIRFI_IXY_LoopY.SIRFI_Interp_XY_XIncrementDone   ; just to make it similar to previous usage for better compression

SIRFI_IXY_UnrolledXLoopStart:
        DUP 64
            add hl, bc
            ld a, h
            swapnib
            or h
            ld (de), a
            inc e
        EDUP
        pop hl

        ld d,h
        ld e,l
        add de, 64
SIRFI_IXY_LoopXCounter equ $+1
        ld a, 0
        ld c, a
        xor a
        ld b, a
        ; unrolled LDIR courtesy of Dr.Max / Global Corp
        sub c
        and $1f     ; make it 0-31
        add a
        ld (SIRFI_IXY_LDI_Offset), a
SIRFI_IXY_LDI_Offset equ $+1
        jr nz, SIRFI_IXY_LDI_Loop
SIRFI_IXY_LDI_Loop:
        DUP 32
            ldi
        EDUP
        jp pe, SIRFI_IXY_LDI_Loop

        pop de
        add de, 128     ; 2 rows of 128 pixels in nibbles
        pop hl
        pop bc
        add hl, bc
        exx
        add hl, bc
        exx
    dec iyh
    jp nz, SIRFI_IXY_LoopY

    pop iy
    ret
ret

; -----------------------------------------------------------------------------------------------------------------------
; One of raytrace interpolation options
; In: IY: current area, B - Span Y, C - Span X (already in 2-pixel "chunks")
SubdivInterpRoutine_FillRandomColor:
SIRFRC_PrevColor equ $+1
    ld a, 0
    inc a
    and #07
    ld (SIRFRC_PrevColor), a
    add 7

    ld h, a
    swapnib
    or h

    ex af, af'

    ; now we have the value to fill
    ld hl, (ScreenStart)
    ld e, (iy + Area5.Ray0.ScreenX)
    ld d, (iy + Area5.Ray0.ScreenY)

    ; For 2x2 chunks, we need an adress like Screen + 128*D + E.
    rl e
    rr d
    rr e
    add hl, de

    ; calculate the trampoline value inside the loop
    ; we need to calculate the jump, so 'fill 64-width'
    ld a, 64
    sub c
    ; if we want to fill 0 (shouldn't happen) or 1 chunk width, this is beyond the JR range
    ; the largest positive offset we can put in JR is 126 (well, 127, but that would be useless)
    ; that means the largest span we can skip that way is 126/2 = 63 pixels
    ; filling 0 pixels (i.e. skipping 64) is useless anyway
    cp 64
    ret nc

    ; otherwise, multiple skipped pixels by 2, add offset for the JR, and use as a trampoline
    rlca
    ;add 2
    ld (SIRFRC_JumpTrampoline1), a
    ld (SIRFRC_JumpTrampoline2), a

    ex af, af'  ; back to A having filler value

SIRFRC_FillLoopY:
    ld e, l

SIRFRC_JumpTrampoline1 equ $+1
    jr $
    dup 64  ; the largest ever fill extent
        ld (hl), a
        inc l
    edup

    ld l, e
    add hl, #40 ; 128 pixels in nibbles

SIRFRC_JumpTrampoline2 equ $+1
    jr $
    dup 64  ; the largest ever fill extent
        ld (hl), a
        inc l
    edup
    ld l, e
    add hl, #80
    dec b
    jp nz, SIRFRC_FillLoopY
    ret

; -----------------------------------------------------------------------------------------------------------------------
; One of raytrace interpolation options
; In: IY: current area, B - Span Y, C - Span X (already in 2-pixel "chunks")
SubdivInterpRoutine_FillAverage:
    ; average the value. As diving by 5 is inconvenient, first average the first 4 rays, then avg that with the 5th (central one)
    ld a, (iy + Area5.Ray0.Value)
    add (iy + Area5.Ray1.Value)
    add (iy + Area5.Ray2.Value)
    add (iy + Area5.Ray3.Value)
    sra a
    sra a
    add (iy + Area5.Ray4.Value)
    sra a

    ld h, a
    swapnib
    or h

    ex af, af'

    ; now we have the value to fill
    ld hl, (ScreenStart)
    ld e, (iy + Area5.Ray0.ScreenX)
    ld d, (iy + Area5.Ray0.ScreenY)

    ; For 2x2 chunks, we need an adress like Screen + 128*D + E.
    rl e
    rr d
    rr e
    add hl, de

    ; calculate the trampoline value inside the loop
    ; we need to calculate the jump, so 'fill 64-width'
    ld a, 64
    sub c
    ; if we want to fill 0 (shouldn't happen) or 1 chunk width, this is beyond the JR range
    ; the largest positive offset we can put in JR is 126 (well, 127, but that would be useless)
    ; that means the largest span we can skip that way is 126/2 = 63 pixels
    ; filling 0 pixels (i.e. skipping 64) is useless anyway
    cp 64
    ret nc

    ; otherwise, multiple skipped pixels by 2, add offset for the JR, and use as a trampoline
    rlca
    ;add 2
    ld (SIRFA_JumpTrampoline1), a
    ld (SIRFA_JumpTrampoline2), a

    ex af, af'  ; back to A having filler value

SIRFA_FillLoopY:
    ld e, l

SIRFA_JumpTrampoline1 equ $+1
    jr $
    dup 64  ; the largest ever fill extent
        ld (hl), a
        inc l
    edup

    ld l, e
    add hl, #40

SIRFA_JumpTrampoline2 equ $+1
    jr $
    dup 64  ; the largest ever fill extent
        ld (hl), a
        inc l
    edup
    ld l, e
    add hl, #80
    dec b
    jp nz, SIRFA_FillLoopY
    ret

; -----------------------------------------------------------------------------------------------------------------------
; One of raytrace interpolation options
; In: IY: current area, B - Span Y, C - Span X
SubdivInterpRoutine_PlotRays:
    macro SIR_PLOTRAY   Offset_Arg
        ld e, (iy + Offset_Arg + RayDesc.ScreenX)
        ld d, (iy + Offset_Arg + RayDesc.ScreenY)

        ; For 2x2 pixels, we need an adress like #4000 + 128*D + E.
        rl e
        rr d
        rr e
    
        ex de, hl
        add hl, bc
        ex de, hl

        ld a, (iy + Offset_Arg + RayDesc.Value)
        ;or #08
        ld b, a
        swapnib
        or b
        ld (de), a
        add de, 64
        ld (de), a
    endm

    ld bc, (ScreenStart)
    SIR_PLOTRAY Area5.Ray0
    SIR_PLOTRAY Area5.Ray1
    SIR_PLOTRAY Area5.Ray2
    SIR_PLOTRAY Area5.Ray3
    SIR_PLOTRAY Area5.Ray4

    ret

; -----------------------------------------------------------------------------------------------------------------------
; Macro used in the RaytraceSubdiv routine

    macro SUBDIV_TRACE_RAY  RayOffsetFromIY
        ; first check if the ray is cached
        ld e, (iy + RayOffsetFromIY + RayDesc.ScreenY)
        ; // shift by 6 bits (i.e. multiply by 64)
        ld d, 0
        ld b, 6
        bsla de, b
        ld a, (iy + RayOffsetFromIY + RayDesc.ScreenX)
        or e
        ld e, a

        add de, RayCache
        ld a, (de)
        test #80
        jr z, 1F    ; not cached

        ; cached, store the values and attr
        and #7f
        ld (iy + RayOffsetFromIY + RayDesc.Value), a

        add de, GRID_HEIGHT * GRID_WIDTH    ;   advance to Attr part of cache
        ld a, (de)
        ld (iy + RayOffsetFromIY + RayDesc.Attr), a

        jp 2F       ; next ray
1   
        ; the ray isn't cached -> calculate
        ld (.CacheAddr), de ; store the calculated cache value so we can add to the cache later

        ; load DirX
        ld a, (ScreenX)
        ld b, a
        ld a, (iy + RayOffsetFromIY + RayDesc.ScreenX)
        cp b
        jr z, 3F        ; don't reload ScreenX      
        
        ld (ScreenX), a

        ld h, high DirXTab
        ld l, a

        ld e,(hl)
        inc h
        ld d,(hl)
        inc h

        ld (DirX), de

        ld e, (hl)
        inc h
        ld d, (hl)

        ld (DirX_Squared), de

        ; load DirY
3
        ld a, (ScreenY)
        ld b, a
        ld a, (iy + RayOffsetFromIY + RayDesc.ScreenY)

        cp b
        jr z, 4F        ; don't reload ScreenY
        
        ld (ScreenY), a

        ld h, high DirYTab
        ld l, a

        ld e,(hl)
        inc h
        ld d,(hl)
        inc h

        ld (DirY), de

        ld e, (hl)
        inc h
        ld d, (hl)
        inc h

        ld (DirY_Squared), de

        ld e, (hl)
        inc h
        ld d, (hl)

        ld (PlaneY_By_DirY), de
4
        call TraceRay
        ld (iy + RayOffsetFromIY + RayDesc.Value), a

        ; store the value in the cache as well, setting the 7th bit to mark it as cached
.CacheAddr  equ $+1
        ld hl, 0
        or #80
        ld (hl), a

        ld a, (RayAttr)
        ld (iy + RayOffsetFromIY + RayDesc.Attr), a

        add hl, GRID_HEIGHT * GRID_WIDTH
        ld (hl), a
2
    endm

; -----------------------------------------------------------------------------------------------------------------------
; Raytraces screen with a GRID_WIDTH x GRID_HEIGHT grid where each ray has MAX_BRIGHTNESS intensity value.
; Expects variables: Spheres
RaytraceSubdiv:
    if (VARY_SKYCOLOR)
        ; disable sky color for the subdivided trace, interpolation makes it look bad
        xor a
        ld (SkyColorEnabled), a
    endif

    ; clear the cache
    ld hl, RayCache
    ld de, RayCache+1
    ld bc, GRID_WIDTH * GRID_HEIGHT - 1
    ld (hl), l  ; RC must be aligned
    ldir

    xor a
    ld (TopOfTheStack), a

    ; Prepare the initial area
    ld iy, AreaStack
    ; initialize all corners area
    ld (iy + Area5.Ray0.ScreenX), a
    ld (iy + Area5.Ray0.ScreenY), a

    ld (iy + Area5.Ray1.ScreenX), 63
    ld (iy + Area5.Ray1.ScreenY), a

    ld (iy + Area5.Ray2.ScreenX), a
    ld (iy + Area5.Ray2.ScreenY), 47

    ld (iy + Area5.Ray3.ScreenX), 63
    ld (iy + Area5.Ray3.ScreenY), 47

    ld (iy + Area5.Ray4.ScreenX), 32
    ld (iy + Area5.Ray4.ScreenY), 24

RaytraceSubdivLoop:

TopOfTheStack equ $+1
    ld a, 0
    
    and #80     ; whenever TopOfTheStack is negative, return
    ret nz

    if (DEBUG)
    cp 64
    jr c, RSL_NoOverflow
    CHANGE_BORDER_AND_LOCKUP 0xE0
RSL_NoOverflow:
    endif

    ; iy is supposed to be always pointing at the current AreaStack

    SUBDIV_TRACE_RAY Area5.Ray0
    SUBDIV_TRACE_RAY Area5.Ray1
    SUBDIV_TRACE_RAY Area5.Ray2
    SUBDIV_TRACE_RAY Area5.Ray3
    SUBDIV_TRACE_RAY Area5.Ray4

    ; figure out the spans
    ld a, (iy + Area5.Ray2.ScreenY)
    sub (iy + Area5.Ray0.ScreenY)
    ;inc a
    cp (SPAN_Y_TO_STOP_SUBDIV + 1)
    ld b, a

    jr c, RSL_Interpolate_CalcSpanX

    ld a, (iy + Area5.Ray1.ScreenX)
    sub (iy + Area5.Ray0.ScreenX)
    ;inc a
    cp (SPAN_X_TO_STOP_SUBDIV + 1)
    ld c, a

    jr c, RSL_Interpolate

    ; test attributes
    ld a, (iy + Area5.Ray0.Attr)

    cp (iy + Area5.Ray1.Attr)
    jr nz, RSL_Subdivide

    cp (iy + Area5.Ray2.Attr)
    jr nz, RSL_Subdivide
    
    cp (iy + Area5.Ray3.Attr)
    jr nz, RSL_Subdivide

    cp (iy + Area5.Ray4.Attr)
    jr nz, RSL_Subdivide

    ; Also subdivide regions whose top left is on the plane.
    ; This is a content-specific hack: some regions don't reliably detect shadow inside them, so they
    ; fill the plane with the color, something we don't want
    test RAYATTR_PLANEHIT
    jr nz, RSL_Subdivide

    jr RSL_Interpolate

RSL_Interpolate_CalcSpanX:
    ld a, (iy + Area5.Ray1.ScreenX)
    sub (iy + Area5.Ray0.ScreenX)
    ;inc a
    ld c, a 

; taking an area off top of the stack and rasterizing

RSL_Interpolate:

RaytraceSubdiv_InterpRoutine equ $+1
    ;call SubdivInterpRoutine_PlotRays
    ;call SubdivInterpRoutine_FillAverage
    ;call SubdivInterpRoutine_FillRandomColor
    call SubdivInterpRoutine_FillInterpolate

    ; interpolation takes off an area from the stack
    ld hl, TopOfTheStack
    dec (hl)

    ld de, -Area5
    add iy, de
    jp RaytraceSubdivLoop

; subdividing the area and tracing further

RSL_Subdivide:

    ; out of 5 traced rays, create 4 more areas
    ;
    ;  0     a     1
    ;     b     c 
    ;  d     4     e 
    ;     f     g
    ;  2     h     3

    ;  so we have 5 rays 0, 1, 2, 3, 4
    ;  we need to add 8 more rays a, b, c, d, e, f, g, h

    macro COPY_RAY  OffsetNew, OffsetOrg
        ld a, (iy + OffsetOrg + RayDesc.ScreenX)
        ld (iy + OffsetNew + RayDesc.ScreenX), a
        ld a, (iy + OffsetOrg + RayDesc.ScreenY)
        ld (iy + OffsetNew + RayDesc.ScreenY), a
    endm

    ; quadrant 4-e-h-3  
    ; ray 0 is former ray 4
    ; ray 3 is former ray 3
    ; the rest needs to be combined / interpolated

    COPY_RAY  (1 * Area5 + Area5.Ray0), Area5.Ray4
    COPY_RAY  (1 * Area5 + Area5.Ray3), Area5.Ray3

    ld a, (iy + Area5.Ray1.ScreenX)
    ld (iy + 1 * Area5 + Area5.Ray1.ScreenX), a
    ld a, (iy + Area5.Ray4.ScreenY)
    ld (iy + 1 * Area5 + Area5.Ray1.ScreenY), a

    ld a, (iy + Area5.Ray4.ScreenX)
    ld (iy + 1 * Area5 + Area5.Ray2.ScreenX), a
    ld a, (iy + Area5.Ray3.ScreenY)
    ld (iy + 1 * Area5 + Area5.Ray2.ScreenY), a

    ld a, (iy + 1 * Area5 + Area5.Ray0.ScreenX)
    add (iy + 1 * Area5 + Area5.Ray1.ScreenX)
    sra a
    ld (iy + 1 * Area5 + Area5.Ray4.ScreenX), a

    ld a, (iy + 1 * Area5 + Area5.Ray0.ScreenY)
    add (iy + 1 * Area5 + Area5.Ray2.ScreenY)
    sra a
    ld (iy + 1 * Area5 + Area5.Ray4.ScreenY), a

    ; quadrant d-4-2-h
    ; ray 1 is former ray 4
    ; ray 2 is former ray 2
    ; the rest needs to be combined / interpolated

    COPY_RAY  (2 * Area5 + Area5.Ray1), Area5.Ray4
    COPY_RAY  (2 * Area5 + Area5.Ray2), Area5.Ray2

    ld a, (iy + Area5.Ray2.ScreenX)
    ld (iy + 2 * Area5 + Area5.Ray0.ScreenX), a
    ld a, (iy + Area5.Ray4.ScreenY)
    ld (iy + 2 * Area5 + Area5.Ray0.ScreenY), a

    ld a, (iy + Area5.Ray4.ScreenX)
    ld (iy + 2 * Area5 + Area5.Ray3.ScreenX), a
    ld a, (iy + Area5.Ray2.ScreenY)
    ld (iy + 2 * Area5 + Area5.Ray3.ScreenY), a

    ld a, (iy + 2 * Area5 + Area5.Ray0.ScreenX)
    add (iy + 2 * Area5 + Area5.Ray1.ScreenX)
    sra a
    ld (iy + 2 * Area5 + Area5.Ray4.ScreenX), a

    ld a, (iy + 2 * Area5 + Area5.Ray0.ScreenY)
    add (iy + 2 * Area5 + Area5.Ray2.ScreenY)
    sra a
    ld (iy + 2 * Area5 + Area5.Ray4.ScreenY), a

    ; quadrant a-1-4-e
    ; ray 1 is former ray 1
    ; ray 2 is former ray 4
    ; the rest needs to be combined / interpolated

    COPY_RAY  (3 * Area5 + Area5.Ray1), Area5.Ray1
    COPY_RAY  (3 * Area5 + Area5.Ray2), Area5.Ray4

    ld a, (iy + Area5.Ray4.ScreenX)
    ld (iy + 3 * Area5 + Area5.Ray0.ScreenX), a
    ld a, (iy + Area5.Ray1.ScreenY)
    ld (iy + 3 * Area5 + Area5.Ray0.ScreenY), a

    ld a, (iy + Area5.Ray1.ScreenX)
    ld (iy + 3 * Area5 + Area5.Ray3.ScreenX), a
    ld a, (iy + Area5.Ray4.ScreenY)
    ld (iy + 3 * Area5 + Area5.Ray3.ScreenY), a

    ld a, (iy + 3 * Area5 + Area5.Ray0.ScreenX)
    add (iy + 3 * Area5 + Area5.Ray1.ScreenX)
    sra a
    ld (iy + 3 * Area5 + Area5.Ray4.ScreenX), a

    ld a, (iy + 3 * Area5 + Area5.Ray0.ScreenY)
    add (iy + 3 * Area5 + Area5.Ray2.ScreenY)
    sra a
    ld (iy + 3 * Area5 + Area5.Ray4.ScreenY), a

    ; quadrant 0-a-d-4
    ; ray 0 is former ray 0
    ; ray 3 is former ray 4
    ; the rest needs to be combined / interpolated
    ; this is the repurposed former top of the stack

    ; no need to copy Ray0 onto itself, but here we have to pay attention at the order of updates!
    ld a, (iy + Area5.Ray4.ScreenX)
    ld (iy + Area5.Ray1.ScreenX), a
    ld a, (iy + Area5.Ray4.ScreenY)
    ld (iy + Area5.Ray2.ScreenY), a

    COPY_RAY  Area5.Ray3, Area5.Ray4

    ld a, (iy + Area5.Ray0.ScreenX)
    add (iy + Area5.Ray1.ScreenX)
    sra a
    ld (iy + Area5.Ray4.ScreenX), a

    ld a, (iy + Area5.Ray0.ScreenY)
    add (iy + Area5.Ray2.ScreenY)
    sra a
    ld (iy + Area5.Ray4.ScreenY), a

    ld a, (TopOfTheStack)
    add 3   ; the reason why we're adding 3 more areas and not 4 is because the current area will get repurposed for the top left one
    ld (TopOfTheStack), a

    ld de, 3 * Area5
    add iy, de

    jp RaytraceSubdivLoop

;------------------------------------------------------------------
; Tick proc of the first effect
Effect1Update:
    ld hl, (Frame)
Effect1_StartFrame equ $+1
    ld de, 0
    or a
    sbc hl, de
    ld a, l
    SCOS16
    ld (E1U_CosA), hl

    ld hl, Spheres_From_RTZX
    ld de, Spheres_table
    ld bc, Sphere * NUM_SPHERES
    ldir

    ; Spheres[0 * 4 + 1] = -1 + 2.0f * (float)(fabs(cos((double)Frame * 3.14159 / 100.0)));
    ld ix, Spheres_table

E1U_CosA equ $+1
    ld hl, 0

    ld de, -1 * FIXEDPOINT_SCALER
    add hl, de

    ex de, hl
    ld (ix + Sphere + Sphere.Y), e
    ld (ix + Sphere + Sphere.Y + 1), d

    jp CalcSpheresC

;------------------------------------------------------------------
; Tick proc of the third effect
Effect3Update:
    ld hl, Spheres_View3
    ld de, Spheres_table
    ld bc, Sphere * NUM_SPHERES
    ldir
    jp Effect2Update_MainBody

;------------------------------------------------------------------
; Tick proc of the second effect
Effect2Update:
    ld hl, Spheres_View4
    ld de, Spheres_table
    ld bc, Sphere * NUM_SPHERES
    ldir
    ; intentional fall-through

Effect2Update_MainBody:
    ld hl, (Frame)
Effect2_StartFrame equ $+1
    ld de, 0
    or a
    sbc hl, de
    ex de, hl
    ld b, 2
    bsra de, b
    ld a, e

    push af
    SSIN16
    ld (E2U_SinA), hl
    pop af
    SCOS16
    ld (E2U_CosA), hl

    ; Spheres[0 * 4 + 1] = -1 + 2.0f * (float)(fabs(cos((double)Frame * 3.14159 / 100.0)));
    ld ix, Spheres_table
    ld b, 3
E2U_SphereUpdateLoop:
    ;   float X = (Spheres[Idx * 4 + 0] - AxisX);
    ;   float Z = (Spheres[Idx * 4 + 2] - AxisZ);   
    ;   Spheres[Idx * 4 + 0] = (X * CosA + Z * SinA) + AxisX;
    ;   Spheres[Idx * 4 + 2] = (-X * SinA + Z * CosA) + AxisZ;

    push bc

    ; offset both X and Z
    ld e, (ix + Sphere.X)
    ld d, (ix + Sphere.X + 1)
    ld hl, FIXEDPOINT_SCALER / 4
    ex de, hl
    sub hl, de
    ld (E2U_X), hl

    ld e, (ix + Sphere.Z)
    ld d, (ix + Sphere.Z + 1)
    ld hl, 5 * FIXEDPOINT_SCALER
    ex de, hl
    sub hl, de
    ld (E2U_Z), hl

    ; calc X
    ; first term
E2U_X equ $+1
    ld de, 0
E2U_CosA equ $+1
    ld bc, 0
    SMUL16
    push hl

    ; second term
E2U_Z equ $+1
    ld de, 0
E2U_SinA equ $+1
    ld bc, 0
    SMUL16

    ld de, FIXEDPOINT_SCALER / 4
    add hl, de

    pop de
    add hl, de
    ex de,hl
    ; X is done
    ld (ix + Sphere.X), e
    ld (ix + Sphere.X + 1), d

    ; Y
    ; first term
    ld de, (E2U_X)
    xor a
    ld h, a
    ld l, a
    sbc hl, de
    ld bc, (E2U_SinA)
    SMUL16
    push hl

    ld de, (E2U_Z)
    ld bc, (E2U_CosA)
    SMUL16

    ld de, 5 * FIXEDPOINT_SCALER
    add hl, de

    pop de
    add hl, de
    ex de, hl

    ; Z is done
    ld (ix + Sphere.Z), e
    ld (ix + Sphere.Z + 1), d

    ld bc, Sphere
    add ix, bc

    pop bc
    djnz E2U_SphereUpdateLoop

    jp CalcSpheresC

;------------------------------------------------------------------
; Shows a screen
PopUpScreen:
    if 0
    ld de, $4000
    ld bc, 6912
    ldir

    ld bc, $300
    ldir
    ret
    endif

    if 0
    push hl
    add hl, $1800
    ;ld hl, $7800
    ld de, $5800
    ld bc, $300
    ldir
    pop hl
    endif

    ; store attr addresses in shadow hl and de
    push hl
    add hl, $1800
    ld de, #5800
    exx
    pop hl

    ; main hl, de will track bitmap addresses
    ld de, #4000
    ld a, 24
PrintScreen_Loop:
        ; take the current attribute and splatter it all over the screen up until de
        exx
        push hl
        push de
        ld b, a
VertFill_Attr_Loop:
            push bc
            push hl
            ld bc, 32
            ldir
            pop hl
            pop bc
            djnz VertFill_Attr_Loop
        pop de
        pop hl
        add hl, 32
        add de, 32
        exx

        ld b, 8
PrintScreen_Bitmap_Loop:
        call WaitVBlank
        call WaitVBlank
        push af
        push bc
        push de

        ; multiply a by 8 to get the number of lines to draw        
        dec a
        rlca
        rlca
        rlca
        add b
        ld b, a
        ; duplicate each line from bottom to de
VertFillWithOneLineLoop:
            push bc
            push hl
            push de

            ld bc, 32
            ldir

            pop de
            pop hl
            pop bc
            ex de, hl
            pixeldn
            ex de, hl
            djnz VertFillWithOneLineLoop

        pop de
        pop bc
        pop af
        pixeldn
        ex de, hl
        pixeldn
        ex de, hl
        djnz PrintScreen_Bitmap_Loop

        dec a
        jr nz, PrintScreen_Loop
    ret

;------------------------------------------------------------------
; Shows a screen
PopUpScreenFast:
    ; store attr addresses in shadow hl and de
    push hl
    add hl, $1800
    ld de, #5800
    exx
    pop hl

    ; main hl, de will track bitmap addresses
    ld de, #4000
    ld a, 24
PUSF_PrintScreen_Loop:
        ; take the current attribute and splatter it all over the screen up until de
        exx
        push hl
        push de
        ld b, a
PUSF_VertFill_Attr_Loop:
            push bc
            push hl
            ld bc, 32
            ldir
            pop hl
            pop bc
            djnz PUSF_VertFill_Attr_Loop
        pop de
        pop hl
        add hl, 32
        add de, 32
        exx

        ld b, 8
PUSF_PrintScreen_Bitmap_Loop:
        call WaitVBlank
        push af
        push bc
        push de

        ; multiply a by 8 to get the number of lines to draw        
        dec a
        rlca
        rlca
        rlca
        add b
        ld b, a
        ; duplicate each line from bottom to de
PUSF_VertFillWithOneLineLoop:
            push bc
            push hl
            push de

            ld bc, 32
            ldir

            pop de
            pop hl
            pop bc
            ex de, hl
            pixeldn
            ex de, hl
            djnz PUSF_VertFillWithOneLineLoop

        pop de
        pop bc
        pop af
        pixeldn
        ex de, hl
        pixeldn
        ex de, hl
        djnz PUSF_PrintScreen_Bitmap_Loop

        dec a
        jr nz, PUSF_PrintScreen_Loop
    ret

;------------------------------------------------------------------
; Copies spheres from under HL to Spheres_table
SetAsActiveScene:
    ld de, Spheres_table
    ld bc, Sphere * NUM_SPHERES
    ldir

    ; -- intentional fall-through
    ;jr CalcSpheresC

;------------------------------------------------------------------
; Calcs spheres C values  (float C = Sphere[0] * Sphere[0] + Sphere[1] * Sphere[1] + Sphere[2] * Sphere[2] - 1)
CalcSpheresC:
    ld ix, Spheres_table
    ld b, 3
CSC_Loop:
    push bc

    ld l, (ix + Sphere.X)
    ld h, (ix + Sphere.X + 1)
    SSQUARE16

    push hl

    ld l, (ix + Sphere.Y)
    ld h, (ix + Sphere.Y + 1)
    SSQUARE16

    push hl

    ld l, (ix + Sphere.Z)
    ld h, (ix + Sphere.Z + 1)
    ld (CSC_CurrentSphereZ), hl
    SSQUARE16
    
    pop de
    add hl, de

    pop de
    add hl, de

    add hl, -FIXEDPOINT_SCALER  ; -1
    ld (ix+8), l
    ld (ix+9), h

    ; calculate sphere center in screen coordinates
    ; float CenterX = 32.0 + 64.0 * Sphere[0] / Sphere[2];
    ; float CenterY = 24.0 - 48.0 * Sphere[1] / Sphere[2];

    ld l, (ix + Sphere.X)
    ld h, (ix + Sphere.X + 1)
CSC_CurrentSphereZ equ $+1
    ld bc, 0
    push bc
    push bc
    push bc
    SDIV16
    ; multiply by 64 by shifting 6 bits left
    ex de, hl
    ld b, 6
    bsla de, b
    ld hl, 32 * FIXEDPOINT_SCALER + FIXEDPOINT_SCALER / 2
    add hl, de
    ; hl is now 9.7 CenterX. We only need the integer part
    add hl, hl
    ld (ix + Sphere.ScreenCenterX), h

    pop bc
    ld l, (ix + Sphere.Y)
    ld h, (ix + Sphere.Y + 1)
    SDIV16
    ; multiply by 48 by adding x32 and x16, that is, shifting 4 bits left and then 5
    ex de, hl
    ld b, 4
    bsla de, b
    ld h, d
    ld l, e
    add hl, hl
    add hl, de
    ld de, 24 * FIXEDPOINT_SCALER + FIXEDPOINT_SCALER / 2
    ex de, hl
    or a
    sbc hl, de
    ; hl is now 9.7 CenterY. We only need the integer part
    add hl, hl
    ld (ix + Sphere.ScreenCenterY), h

    ; calculate sphere radius in screen coordinates
    ; float RadX = 1 + 64.0 / Sphere[2];
    ; float RadY = 1 + 48.0 / Sphere[2];
    pop bc
    ld hl, 64 * FIXEDPOINT_SCALER
    SDIV16
    add hl, hl
    inc h
    ld (ix + Sphere.ScreenRadX), h

    pop bc
    ld hl, 48 * FIXEDPOINT_SCALER
    SDIV16
    add hl, hl
    inc h
    ld (ix + Sphere.ScreenRadY), h

    ld bc, Sphere
    add ix, bc

    pop bc
    ;djnz CSC_Loop
    dec b
    jp nz, CSC_Loop

    ; sort spheres by Z ascending, so we can use early out processing hits
    ; sorting 3 items (credits: https://stackoverflow.com/questions/4793251/sorting-int-array-with-only-3-elements)
    ; if (el1 > el2) Swap(el1,el2)
    ; if (el2 > el3) Swap(el2,el3)
    ; if (el1 > el2) Swap(el1,el2)

    ld ix, Spheres_table
    ; Compare 1 and 2
    ld e, (ix + Sphere.Z)
    ld d, (ix + Sphere.Z + 1)
    ld c, (ix + Sphere + Sphere.Z)
    ld b, (ix + Sphere + Sphere.Z + 1)
    ex de, hl
    or a
    sbc hl, bc
    jr c, CSC_Sph2_Is_Not_Farther_Than_Sph1

    ; swap 1 and 2
    ld hl, Spheres_table
    ld de, Spheres_table + Sphere
    call CSC_Swap_Spheres_HL_and_DE

CSC_Sph2_Is_Not_Farther_Than_Sph1:
    ; Compare 2 and 3
    ld e, (ix + Sphere.Z)
    ld d, (ix + Sphere.Z + 1)
    ld c, (ix + 2*Sphere + Sphere.Z)
    ld b, (ix + 2*Sphere + Sphere.Z + 1)
    ex de, hl
    or a
    sbc hl, bc
    jr c, CSC_Sph3_Is_Not_Farther_Than_Sph2

    ; swap 2 and 3
    ld hl, Spheres_table + Sphere
    ld de, Spheres_table + 2*Sphere
    call CSC_Swap_Spheres_HL_and_DE

CSC_Sph3_Is_Not_Farther_Than_Sph2:
    ; Compare 1 and 2 again
    ld e, (ix + Sphere.Z)
    ld d, (ix + Sphere.Z + 1)
    ld c, (ix + Sphere + Sphere.Z)
    ld b, (ix + Sphere + Sphere.Z + 1)
    ex de, hl
    or a
    sbc hl, bc
    ret c

    ld hl, Spheres_table
    ld de, Spheres_table + Sphere
    ; intentional fall-through

CSC_Swap_Spheres_HL_and_DE:
    ld bc, Sphere*256 + 255
CSC_SwapLoop:
        ld a, (de)
        ldi
        dec hl
        ld (hl), a
        inc hl
    djnz CSC_SwapLoop
    ret

;------------------------------------------------------------------
; Waits as many frames as HL
WaitHLFrames:
    ld de, (Frame)
    add hl, de
WaitHLFrames_Loop:
    call WaitVBlank
    push hl
    call IsAtFrameOrLater
    pop hl
    jr c, WaitHLFrames_Loop
    ret

;------------------------------------------------------------------
; Waits until absolute frame (in HL)
WaitUntilHLFrame:
    call WaitVBlank
    push hl
    call IsAtFrameOrLater
    pop hl
    jr c, WaitUntilHLFrame
    ret

;------------------------------------------------------------------
; Polls for a frame number (in HL)
; Returns: Carry if not, NC if yes
IsAtFrameOrLater:
    ex de, hl
    ld hl, (Frame)
    or a
    sbc hl, de
    ret

;------------------------------------------------------------------
; Inits the music
InitMusic:
    ; page in pages 29, 30 into #C000-FFFF 
    nextreg MMU6_C000_NR_56, 29
    nextreg MMU7_E000_NR_57, 30

    call mus_init

    ; return to the default mapping (0, 1) - see https://github.com/z00m128/sjasmplus/issues/59#issuecomment-518732510
    nextreg MMU6_C000_NR_56, 0
    nextreg MMU7_E000_NR_57, 1
    ret

;------------------------------------------------------------------
; Inits the music
PlayMusic:
    ; page in pages 29, 30 into #C000-FFFF 
    nextreg MMU6_C000_NR_56, 29
    nextreg MMU7_E000_NR_57, 30

    call trb_play

    ; return to the default mapping (0, 1) - see https://github.com/z00m128/sjasmplus/issues/59#issuecomment-518732510
    nextreg MMU6_C000_NR_56, 0
    nextreg MMU7_E000_NR_57, 1
    ret

;------------------------------------------------------------------
; Precomputes directional vectors for every screen pixel
PrecomputeXYDirsAndPlaneZ:
    ld b, GRID_HEIGHT
    ld de, DirYTab

PrecomputeYLoop:
    push bc
    push de
    push de

    ; invert b to account for screen Y being in opposite direction than Y axis
    ld a, GRID_HEIGHT
    sub b
    ld b, a

    ; calculate RayDirY = (short)sdiv16((Y - GRID_HEIGHT / 2) * FIXEDPOINT_SCALER, GRID_HEIGHT * FIXEDPOINT_SCALER);
    ; except our Y = GRID_HEIGHT - YCounter, so the above becomes
    ; RayDirY = (short)sdiv16((GRID_HEIGHT / 2 - YCounter) * FIXEDPOINT_SCALER, GRID_HEIGHT * FIXEDPOINT_SCALER)

    ld a, GRID_HEIGHT / 2
    sub b
    ld h, a
    ld l, 0
    sra h       ; hard-coded for FIXEDPOINT_SCALER being 7
    rr l
    ld bc, GRID_HEIGHT * FIXEDPOINT_SCALER
    call sdiv16

    ex de, hl
    pop hl
    ld (hl), e
    inc h
    ld (hl), d
    inc h
    push de
    push hl

    ; also store squared
    ex de, hl
    SSQUARE16

    ex de, hl
    pop hl
    ld (hl), e
    inc h
    ld (hl), d
    inc h

    ; special case only for DirY - divide PLANE_Y by DirY and store that
    pop bc
    push hl

    ld hl, PLANE_Y
    bit 7, b
    jr z, PrecomputeY_JustStorePlane    ; skip dividing by positive DirY as that results in "horizon" line
    call sdiv16

PrecomputeY_JustStorePlane:
    ex de, hl
    pop hl
    ld (hl), e
    inc h
    ld (hl), d

    pop de
    inc e
    pop bc
    ;djnz PrecomputeYLoop
    dec b
    jp nz, PrecomputeYLoop

    ld b, GRID_WIDTH
    ld de, DirXTab

PrecomputeXLoop:
    push bc
    push de

    ; calculate RayDirX = (short)sdiv16((X - GRID_WIDTH / 2) * FIXEDPOINT_SCALER, GRID_WIDTH * FIXEDPOINT_SCALER);
    ; except our X = GRID_WIDTH - XCounter, so the above becomes
    ; RayDirX = (short)sdiv16((GRID_WIDTH / 2 - YCounter) * FIXEDPOINT_SCALER, GRID_WIDTH * FIXEDPOINT_SCALER)

    ld a, GRID_WIDTH / 2
    sub b
    ld h, a
    ld l, 0
    sra h       ; hard-coded for FIXEDPOINT_SCALER being 7
    rl l
    ld bc, GRID_WIDTH * FIXEDPOINT_SCALER
    call sdiv16

    ex de, hl
    pop hl
    ld (hl), e
    inc h
    ld (hl), d
    inc h
    push hl

    ; also store squared
    ex de, hl
    SSQUARE16

    pop de
    ex de, hl
    ld (hl), e
    inc h
    ld (hl), d
    dec h
    dec h
    dec h
    inc l
    ex de, hl

    pop bc
    djnz PrecomputeXLoop

    ret


;------------------------------------------------------------------
; In: HL - palette table
SetupPalette:
    ; default palette is just standard 8 colors, first without bright, then with bright (see https://remysharp.com/2020/09/18/about-the-lores-layer-spectrum)
    ; so essentially:   0000BRGB    

    ld c, (hl)  ; number of colors in a palette
    inc hl
    ld b, c
palette_upload_loop:
    ld a, c
    sub b
    nextreg PALETTE_INDEX_NR_40, a      ; which color we're going to configure

    ld a, (hl)
    nextreg PALETTE_VALUE_NR_41, a      ; 8-bit palette value for that color

    inc hl
    djnz palette_upload_loop

    ; clear the remainder
    xor a
    sub c
    ld b, a
    ld a, c
SetupPalette_ClearLoop:
    nextreg PALETTE_INDEX_NR_40, a      ; which color we're going to configure

    nextreg PALETTE_VALUE_NR_41, 0      ; 8-bit palette value for that color
    inc a
    djnz SetupPalette_ClearLoop

    ret

LoresPalette:
    db 16
    db 0x00, 0x04, 0x08, 0x0C, 0x10, 0x14, 0x18, 0x1C
    db 0x3C, 0x5C, 0x7C, 0x9C, 0xBC, 0xDC, 0xFC, 0xFF

    ; from https://wiki.specnext.dev/Palettes
    ; "The palette entry numbers for standard ULA mode are: 0-7 for the standard ink colors, 8-15 for BRIGHT ink colors, 16-23 for standard paper and border colors, and 24-31 for BRIGHT paper colors."

ULAClassicPalette:
    db 32
    ;   RRRGGGBB
    ; standard ink
    db %00000000
    db %00000010
    db %10100000
    db %10100010
    db %00010100
    db %00010110
    db %10110100
    db %10110110

    ; bright ink
    db %00000000
    db %00000011
    db %11100000
    db %11100011
    db %00011100
    db %00011111
    db %11111100
    db %11111111

    ; standard paper
    db %00000000
    db %00000010
    db %10100000
    db %10100010
    db %00010100
    db %00010110
    db %10110100
    db %10110110

    ; bright paper
    db %00000000
    db %00000011
    db %11100000
    db %11100011
    db %00011100
    db %00011111
    db %11111100
    db %11111111

;------------------------------------------------------------------
; Sets up interrupt routines for both 50Hz and 60Hz video modes (respecting user's choice, which can be limited by the available display)
; We expect interrupts to be disabled at the moment of entering this function
; For 50Hz we do everything in the ULA VBlank interrupt
; For 60Hz we set up a separate CTC interrupt at (about) 50Hz for music and pacing, while keeping ULA interrupt for the VBlank synch
SetupInterrupts:
    ; common part
    ; (see https://gitlab.com/SpectrumNext/ZX_Spectrum_Next_FPGA/-/blob/master/cores/zxnext/nextreg.txt?ref_type=heads and ZX Next Dev Guide)
    nextreg INTERRUPT_CONTROL_C0, (((low InterruptVectors) & %11100000) | 1)    ; set bits 3 of interrupt vector table and also IM2 mode
    nextreg INTERRUPT_ENABLE_MASK_0_C4, $81 ; Enables ULA and INT interrupts only
    nextreg INTERRUPT_ENABLE_MASK_2_C6, 0

    ; check what mode we're in
    ld a, $5
    ld bc, TBBLUE_REGISTER_SELECT_P_243B
    out (c), a

    ld bc, TBBLUE_REGISTER_ACCESS_P_253B
    in a, (c)

    ; see https://www.specnext.com/tbblue-io-port-system/ for nextreg 5 values
    and $40 ;   bit 2 - 0 == 50Hz, 1 == 60 Hz
    jr nz, SetupInterruptsFor60Hz       ; 60 Hz setup is a bit more involved as we use CTC to provide for a consistent 50Hz music and pacing update. 50Hz can run faster with just the ULA VBlank interrupt doing everything

    ; 50 Hz setup
    ld hl, VBlankInterruptHandler50Hz
    ld (InterruptVector_VBlankIrq), hl

    ; rewrite WaitVBlank routine to only be "halt; ret". HALT is $76, RET is $C9
    ld hl, $c976
    ld (WaitVBlank), hl

    nextreg INTERRUPT_ENABLE_MASK_1_C5, 0       ; Disables CTC interrupt
    jr SetupInterrupts_Epilogue

SetupInterruptsFor60Hz:
    ; setup for 60Hz

    ; Explanation what we do in the 60Hz mode:
    ; 1) we set up a 804Hz CTC interrupt for (logical) framecount and music updates. Framecount and music is only updated on each 16th interrupt (804/16 = 50.25Hz)
    ; 2) we also set up the regular ULA Vblank interrupt. It runs 60Hz and only updates the ULAVBlanks counter.
    ; 3) where we would use a single HALT to wait for the frame start, we now need a loop that does a HALT, checks if the ULAVBlank counter was updated, and loops if not
    ; (the purpose of that loop is to skip non-VBlank interrupts)

    nextreg INTERRUPT_ENABLE_MASK_1_C5, $1      ; Enables CTC interrupt

    ld hl, VBlankInterruptHandler60Hz
    ld (InterruptVector_VBlankIrq), hl

    ; set up CTC channel 0
    ; https://gitlab.com/SpectrumNext/ZX_Spectrum_Next_FPGA/-/blob/master/cores/zxnext/ports.txt?ref_type=heads#L291
    ; The interrupt frequency is going to be Fsys/((16 or 256)*period) with the constant 16 or 256 divider selectable
    ; also: 

    ld bc, $183b    ;   CTC0 port

    ld a, 1
    out (c), a      ; disable CTC0 interrupt

    ld a, %10100101 ; enable intertupt, timer mode, 256 prescaler, 0,0,0, time const follows, reset control word
    out (c), a

    ; we will run the CTC0 interrupt on 28,000,000 / (256*137) ~= 800 Hz. So we will need to advance the frames every 16th interrupt only
    ld a, 136
    out (c), a

SetupInterrupts_Epilogue:
    ld a, high InterruptVectors
    ld i, a
    im 2
    ret

    .align 32
InterruptVectors:           ; sorted from highest pri to low (by hardware convention)
    dw DefaultInterruptHandler  ; 0 line interrupt
    dw DefaultInterruptHandler  ; 1 UART0 Rx
    dw DefaultInterruptHandler  ; 2 UART1 Rx
    dw CTCInterruptHander       ; 3 CTC channel 0
    dw DefaultInterruptHandler  ; 4 CTC channel 1
    dw DefaultInterruptHandler  ; 5 CTC channel 2
    dw DefaultInterruptHandler  ; 6 CTC channel 3
    dw DefaultInterruptHandler  ; 7 CTC channel 4
    dw DefaultInterruptHandler  ; 8 CTC channel 5
    dw DefaultInterruptHandler  ; 9 CTC channel 6
    dw DefaultInterruptHandler  ; A CTC channel 7
InterruptVector_VBlankIrq:
    dw VBlankInterruptHandler60Hz   ; B ULA
    dw DefaultInterruptHandler  ; C UART0 Tx
    dw DefaultInterruptHandler  ; D UART1 Tx
    dw DefaultInterruptHandler  ; E
    dw DefaultInterruptHandler  ; F

; ------------------------
; Default interrupt handler for unused interrupts
DefaultInterruptHandler:
    ei
    reti

; ------------------------
; Interrupt handler called on CTC0 channel (counter, 800Hz, to provide consistent pacing between 50/60Hz screens)
CTCInterruptHander:
    di
    push af
    ; the interrupt handler is running at 800Hz (798Hz really), to get 50Hz we need to divide this by 16
InterruptFreqDivider equ $+1
    ld a, 16
    and #0f
    dec a
    ld (InterruptFreqDivider), a
    jr nz, CTCInterruptHander_SkipThisInterrupt

    call PacingUpdate50Hz

CTCInterruptHander_SkipThisInterrupt:
    pop af
    ei
    reti

; ------------------------
; Interrupt handler called on CTC0 channel (counter, 800Hz, to provide consistent pacing between 50/60Hz screens)
PacingUpdate50Hz:
    ; expects af to be already pushed
    push bc
    push de
    push hl
    ex af,af'
    exx
    push af
    push bc
    push de
    push hl

    push ix
    push iy

Frame equ $+1
    ld hl, 0
    inc hl
    ld (Frame), hl

    if (!PROFILE_RAYCAST && !PROFILE_DIVISION_ONLY && !PROFILE_QUAD_FILLERS)
        call PlayMusic
    endif

    pop iy
    pop ix

    pop hl
    pop de
    pop bc
    pop af
    exx
    ex af,af'
    pop hl
    pop de
    pop bc
    ret

; ------------------------
; Interrupt handler called on VBlank at 50Hz
VBlankInterruptHandler50Hz:
    push af

    if 0

VBIH50Hz_SkipEvery6Th equ $+1
        ld a, 6
        dec a
        ld (VBIH50Hz_SkipEvery6Th), a
        jr nz, VBIH50Hz_NormalUpdate
        ld a, 6
        ld (VBIH50Hz_SkipEvery6Th), a
        jr VBIH50Hz_NoUpdate
VBIH50Hz_NormalUpdate:
        call PacingUpdate50Hz
VBIH50Hz_NoUpdate:

    else

        call PacingUpdate50Hz

    endif

    pop af
    ei
    reti

; ------------------------
; Interrupt handler called on VBlank at 60Hz
VBlankInterruptHandler60Hz:
    push af
ULAVBlanks equ $+1
    ld a, 0
    inc a
    ld (ULAVBlanks), a
    pop af
    ei
    reti

; ------------------------
; Waits for VBlank, skipping non-VBlank interrupts
WaitVBlank:
    push af
    xor a
    ld (ULAVBlanks), a
WVB_Loop:
    halt
    ld a, (ULAVBlanks)
    and a
    jr z, WVB_Loop
    pop af
    ret

; -----------------------------------------------------------------------------------------------------------------------
; Signed Division 16/16 fp 9.7
; hl = hl / bc
; fp I.F means we're dividing x*2^F by y*2^F and want to get z*2^F.
; In order to not lose precision, premultiply x by 2^F then and divide using 32-bits
sdiv16:

    if (PROFILE_DIVISION)
        nextreg TRANSPARENCY_FALLBACK_COL_NR_4A, 0xFF
        call sdiv16_real
        ld a, (perf_border_color)
        nextreg TRANSPARENCY_FALLBACK_COL_NR_4A, a
        ret
sdiv16_real:
    endif

    bit 7, h
    jr z, sdiv16_dividend_positive
    bit 7, b
    jr z, sdiv16_dividend_negative_divisor_positive
    ; both negative
    ; just invert them and divide as unsigned
    ld de, 0
    ex de, hl
    or a
    sbc hl, de
    push hl 
    xor a
    ld h, a
    ld l, a
    sbc hl, bc
    ld b, h
    ld c, l
    pop hl
    jp udiv16

sdiv16_dividend_negative_divisor_positive:
    ; dividend negative, divisor positive
    ; invert the dividend, divide unsigned, and invert back
    ld de, 0
    ex de, hl
    or a
    sbc hl, de
    call udiv16
    ld de, 0
    ex de, hl
    or a
    sbc hl, de
    ret

sdiv16_dividend_positive:
    bit 7, b
    jr z, udiv16    ; both positive, proceed straight to division
    ; dividend positive, divisor negative
    ; invert the divisor, divide unsigned, and invert back
    ld a, b
    cpl
    ld b, a
    ld a, c
    cpl
    ld c, a
    inc bc
    call udiv16
    ld de, 0
    ex de, hl
    or a
    sbc hl, de
    ret

; -----------------------------------------------------------------------------------------------------------------------
; Unsigned 16/16 fp 9.7 division
; hl = hl / bc
; fp I.F means we're dividing x*2^F by y*2^F and want to get z*2^F.
; In order to not lose precision, premultiply x by 2^F then and divide using 32-bits
udiv16:
    if (FASTPATH_FOR_8BIT_DIVISORS)
        ; check if we're dividing by a 8-bit number and take a faster route if so
        xor a
        or b
        jr nz, udiv16_b_isnot_0 
        bit 7, c
        jp z, udiv16_by_8   ;    we can use 24/8 unsigned division

udiv16_b_isnot_0:
    endif

    xor a

    ex de, hl
    ld h, a     ; accumulator HL starts at 0
    ld l, a

    ; We need to shift a 9.7fp number left by 7, but we instead shift by 8 and use 23 iterations. We only need 23 bits anyway (9.7 fp << 7)
    ;sra d
    ;rr e
    ;rra

    ld a, d
    ;jr udiv16_all23
    test #fc
    jr nz, udiv16_first_6_bit_set

    ; from the obvservations, a lot of our dividends are in $03xx range

    ; first 6 bits are 0, do a faster division
    ld a, b
    ld b, 6
    bsla de, b
    ld b, a
    ld a, d
    ld d, e
    ld e, l
    jp udiv16_unrolled_div_start + 6*udiv16_unrolled_size

udiv16_first_6_bit_set:
    test #f0
    jr nz, udiv16_all23

    ; first 4 bits are 0, do a faster division
    ld a, b
    ld b, 4
    bsla de, b
    ld b, a
    ld a, d
    ld d, e
    ld e, l
    jp udiv16_unrolled_div_start + 4*udiv16_unrolled_size

udiv16_all23:
    ; rearrange from de:a to a:de so we can structure the loop better
    ld d, e
    ld e, l     ; l==0, so e is also 0

    ; restoring algorithm of 24/16 division, hl is the 16-bit accumulator, a:de holds the 24-bit dividend (will also become quotient)
    ; we make that 24 bit number out of 16 bit number shifted to the left
    ; shift the numerator 7 bits to the left
udiv16_unrolled_div_start
    dup 23      
        sll e       ; 8
        rl d        ; 8
        rla         ; 4
        adc hl, hl  ; 15
        ;or a       ; 0 (4) we seem to be able to avoid resetting carry here because we always keep HL < BC, and our BC is positive, so it does not have the highest bit set
        sbc hl, bc  ; 15    ; if hl > bc we need to subtract it and increase a, if hl < bc, we need to do nothing
        jr nc, 1F   ; 7 or 12
        add hl, bc  ; 11
        dec e       ; 4
1
                    ; -----
                    ; 72 or 62 cycles. Total div is going to be between 1426-1656 cycles, likely closer to 1656
                    ; Note: https://baze.sk/3sc/misc/z80bits.html#2.5 has a very similar code and I borrowed the idea to use SLL from there.
    edup
udiv16_unrolled_size equ (($-udiv16_unrolled_div_start) / 23)

    ; a:de holds the quotient, of which we need the lower part
    ex de, hl
    ret

    if (FASTPATH_FOR_8BIT_DIVISORS)
udiv16_by_8:
    ; fp I.F means we're dividing x*2^F by y*2^F and want to get z*2^F.
    ; In order to not lose precision, premultiply x by 2^F then and divide using 24-bits

    ; Here we know that our divisor is 8 bit, so we can use 23-bit by 8 division
    ; For the algo itself, see https://baze.sk/3sc/misc/z80bits.html#2.4
    ; We need to shift a 9.7fp number left by 7, but we instead shift by 8 and use 23 iterations. We only need 23 bits anyway (9.7 fp << 7)

    ; In: E:HL - dividend, C - divisor, A - 0
    ; Out: E:HL - quotient (A - remainder)
    ld e, h
    ld h, l
    ld l, a

    dup 23
        add hl, hl      ; 15
        rl e            ; 8
        rla             ; 4
        cp c            ; 4
        jr c, 1F        ; 7/12
        sub c           ; 4
        inc l           ; 4
1
                        ; -----
                        ; 46 or 43 cycles. Total div is going to be between 989-1058 cycles, likely closer to the larger value
                        ; Note: https://baze.sk/3sc/misc/z80bits.html#2.5 has a very similar code and I borrowed the idea to use SLL from there.
    edup

    ; now e:hl is the dividend, but we only need 9.7 bits from it
    ret
    endif

; -----------------------------------------------------------------------------------------------------------------------
; Signed square 16/16 fp 9.7
; hl = hl * hl
ssquare16:
    ; TODO: optimize
    ex de, hl
    ld b, d
    ld c, e

    ; intentional fall-through
    ;jr smul16  

; -----------------------------------------------------------------------------------------------------------------------
; Signed multiply 16/16 fp 9.7
; hl = de * bc
; fp I.F means we're multiplying x*2^F by y*2^F and want to get z*2^F
; after multiply, we would get xy*2^(F+F), so divide the result by 2^F (shift by 7 bits)
smul16:

    if (PROFILE_MULTIPLY)
        nextreg TRANSPARENCY_FALLBACK_COL_NR_4A, 0xE0
        call smul16_real
        ld a, (perf_border_color)
        nextreg TRANSPARENCY_FALLBACK_COL_NR_4A, a
        ret
smul16_real:
    endif

    bit 7, d
    jp z, smul16_de_positive
    bit 7, b
    jp z, smul16_de_negative_bc_positive
    ; // both negative
    ; // just invert them and multiply as unsigned
    xor a
    ld h, a
    ld l, a
    sbc hl, de
    push hl
    xor a   ; it's already 0 but we still need to reset C
    ld h, a
    ld l, a
    sbc hl, bc
    ld b, h
    ld c, l
    pop de
    jp umul16

smul16_de_negative_bc_positive:
    ; de negative, bc positive
    ; invert de, multiply unsigned, and invert back 
    xor a
    ld h, a
    ld l, a
    sbc hl, de
    ex de, hl
    call umul16
    ld de, 0
    ex de, hl
    or a
    sbc hl, de
    ret

smul16_de_positive:
    bit 7, b
    jp z, umul16    ; both positive, proceed straight to multiplication
    ; de positive, bc negative
    ; invert bc, multiply unsigned, and invert back
    xor a
    ld h, a
    ld l, a
    sbc hl, bc
    ld b, h
    ld c, l
    call umul16
    ld de, 0
    ex de, hl
    or a
    sbc hl, de
    ret

; -----------------------------------------------------------------------------------------------------------------------
; 16-bit 9.7 fixed point unsigned multiply
;   hl = bc * de
; credits: https://tutorials.eeems.ca/Z80ASM/part4.htm
; fp I.F means we're multiplying x*2^F by y*2^F and want to get z*2^F
; after multiply, we would get xy*2^(F+F), so divide the result by 2^F (shift by 7 bits)
umul16:
    ld a, b
    and a
    if (!ZX_NEXT)
        jp nz, umul16_bc_larger_than_256
        or c
        ld h, a
        ld l, a
        ret z   ; multiplication by 0
    else
        jp nz, umul16_regular_multiply  ; for Next, don't bother checking mul by 0 to avoid introducing overhead on the hot path
    endif
    ; we know that bc is non-zero and 8 bit
    ld a, d
    and a
    jp nz, umul16_regular_multiply  ; bc 8 bit, but de 16 -> no special case
    ; at this point we know that both a 8 bit
    if (!ZX_NEXT)               ; for Next, don't bother checking mul by 0 to avoid introducing overhead on the hot path
        or e
        ld h, a
        ld l, a
        ret z   ; multiplication by 0
    endif
    ;jr umul16_regular_multiply

umul8:
    ; do a 8-bit multiply
    if (ZX_NEXT)
        ld d, c
        mul
        ; we know that de holds 2.14 fixed point value. We need to make a 9.7 out of it. Shift 7 times right
        ld b, 7
        bsrl de, b
        ex de, hl
    else
        ld h, c
        ld l, 0
        dup 8
            add hl,hl
            jr nc, 1F
            add hl, de
1
        edup

        ; we know that hl holds 2.14 fixed point value. We need to make a 9.7 out of it. Shift 1 times left and take the middle
        xor a
        add hl, hl
        rla
        ; don't care about d
        ld l, h
        ld h, a
    endif

    ret

    if (!ZX_NEXT)               ; for Next, don't bother checking mul by 0 to avoid introducing overhead on the hot path
umul16_bc_larger_than_256:
        ; bc is larger than 256, cannot use umul8, but still want to check if de is 0
        ld a, d
        or e
        ld h, a
        ld l, a
        ret z
        ; intentional fall-through to regular multiply
    endif

umul16_regular_multiply:

    if ZX_NEXT

        ; taken from https://github.com/mikedailly/mod_player/blob/master/mod_player/maths.asm

        ; de = y1 y0
        ; hl = x1 x0

        ld h, b
        ld l, c
        
        ld      b,l                 ; x0
        ld      c,e                 ; y0
        ld      e,l                 ; x0
        ld      l,d
        push    hl                  ; x1 y1
        ld      l,c                 ; y0

        ; bc = x0 y0
        ; de = y1 x0
        ; hl = x1 y0
        ; stack = x1 y1

        mul                         ; y1*x0
        ex      de,hl
        mul                         ; x1*y0

        xor     a                   ; zero A
        add     hl,de               ; sum cross products p2 p1
        adc     a,a                 ; capture carry p3

        ld      e,c                 ; x0
        ld      d,b                 ; y0
        mul                         ; y0*x0

        ld      b,a                 ; carry from cross products
        ld      c,h                 ; LSB of MSW from cross products

        ld      a,d
        add     a,l
        ld      h,a
        ld      l,e                 ; LSW in HL p1 p0

        pop     de
        mul                         ; x1*y1

        ex      de,hl
        adc     hl,bc

        ; hl:de holds 18.14 product
        ; we only need a middle 9.7 part
        if 1
            ; change to de:hl, shift everything left and take e, h
            ex de, hl   ; 4
            add hl, hl  ; 11
            rl e        ; 8
            ld l, h     ; 4
            ld h, e     ; 4
        else
            ; shift everything 1 left and take l, d
            sla e       ; 8
            rl d        ; 8
            rl l        ; 8
            ld h, l     ; 4
            ld l, d     ; 4
        endif

    ret

    else
        dup 16
            add hl, hl
            rl e
            rl d
            jr nc, 1F
            add hl, bc
            jr nc, 1F
            inc de                         ; This instruction (with the jump) is like an "ADC DE,0"
1
        edup
        ; we have de:hl holding a 18.14 result, and we need to take the middle 9.7 part. 
        ; Shift everything one bit left and then take e, h
        sla l
        rl h
        rl e
        ; don't care about d
        ld l, h
        ld h, e
        endif
    ret

; -----------------------------------------------------------------------------------------------------------------------
; Generates a random 16-bit number
; Returns in hl
; Has no parameters, isolated
Rnd16:
    ; Original description:
    ;Tested and passes all CAcert tests
    ;Uses a very simple 32-bit LCG and 32-bit LFSR
    ;it has a period of 18,446,744,069,414,584,320
    ;roughly 18.4 quintillion.
    ;LFSR taps: 0,2,6,7  = 11000101
    ;291cc
seed1_0 = $ + 1
    ld hl, 12345
seed1_1 = $ + 1
    ld de, 6789
    ld b, h
    ld c, l
    add hl, hl
    rl e
    rl d
    add hl, hl
    rl e
    rl d
    inc l
    add hl, bc
    ld (seed1_0), hl
    ld hl, (seed1_1)
    adc hl, de
    ld (seed1_1), hl
    ex de, hl
seed2_0=$+1
    ld hl, 9876
seed2_1=$+1
    ld bc, 54321
    add hl, hl
    rl c
    rl b
    ld (seed2_1), bc
    sbc a, a
    and %11000101
    xor l
    ld l, a
    ld (seed2_0), hl
    ex de,hl
    add hl, bc
    ret 

; -----------------------------------------------------------------------------------------------------------------------
; Traces a single ray
; Expects variables: Spheres, DirX, DirY, DirX_Squared, DirY_Squared
; Returns a as the light intensity value, also sets RayAttr
TraceRay:
    ld hl, (DirX_Squared)
    ld bc, (DirY_Squared)
    add hl, bc
    ld bc, DIR_Z    ; dir z being 1 is the same squared
    add hl, bc
    add hl, hl
    ld (TraceRay_A), hl

    ld hl, MAX_DIST
    ld (Dist), hl

    xor a
    ld (SphereHit), a
    ld (SphereIndex), a
    ld (RayAttr), a

TR_CurrentSphere_Offset DEFL 0
    dup NUM_SPHERES
        ; check if ScreenX and ScreenY are less than Screen Radiuses
        ld de, (ScreenX)
        ld hl, Spheres_table + TR_CurrentSphere_Offset + Sphere.ScreenCenterX
        ld a, e
        sub (hl)
        jp ns, 2_F
        neg
2
        inc l
        cp (hl)
        jp nc, 1_F      ; Distance to sphere's ScreenX is larger than ScreenRadiusX, skip this sphere

        inc l
        ld a, d
        sub (hl)
        jp ns, 3_F
        neg
3
        inc l
        cp (hl)
        jp nc, 1_F      ; Distance to sphere's ScreenY is larger than ScreenRadiusY, skip this sphere

        ; Calculate B = (smul16(DirX, Sphere[0]) + smul16(DirY, Sphere[1]) + Sphere[2]/*smul16(DirZ, Sphere[2])*/) << 1;
        ld bc, (DirX)
        ld de, (Spheres_table + TR_CurrentSphere_Offset)
        SMUL16
        push hl
        ld bc, (DirY)
        ld de, (Spheres_table + TR_CurrentSphere_Offset + Sphere.Y)
        SMUL16
        ld de, (Spheres_table + TR_CurrentSphere_Offset + Sphere.Z)
        add hl, de
        pop de
        add hl, de
        add hl, hl
        ld (TraceRay_B), hl     ; OPT: can self-modify the code instead

        ; calculate B^2
        SSQUARE16
        push hl 

        ; calculate 2*A*C
        ld bc, (TraceRay_A)
        ld de, (Spheres_table + TR_CurrentSphere_Offset + Sphere.C)
        SMUL16
        add hl, hl

        ; calculate D = B^2 - 2*A*C
        ex de, hl
        pop hl
        or a
        sbc hl, de

        ; D < 0?  Then move on to next sphere
        jp c, 1F    ; next sphere

        ; calculate B-D
        ex de, hl
        ld hl, (TraceRay_B)
        or a
        sbc hl, de

        ; before dividing, calculate if T even has a chance to be positive
        ld a, (TraceRay_A+1)
        xor h
        rlca    ; explanation: the sign bit would be set only if TraceRay_A and B-D both have the same sign
        jr c, 1F    ; next sphere

        ; calculate T = sdiv16((B - D), A);
        ld bc, (TraceRay_A)
        SDIV16

        ; T < 0? Again, next sphere 
        ; this is commented out because we have a check above
            ;bit 7, h
        ;jr nz, 1F

        ; if T < Dist, this is our sphere
        ld bc, (Dist)
        or a
        sbc hl, bc
        add hl, bc
        ; nc if hl >= bc, so T >= Dist, so not a hit
        jr nc, 1F

        ; hit a sphere!
        ld (Dist), hl
        ld a, (SphereIndex)
        inc a
        ld (SphereHit), a
        ld (RayAttr), a
        ; this shortcut doesn't work if sphere's aren't sorted by Z
        jp TraceRay_CheckPlaneIntersection
1
        ld hl, SphereIndex
        inc (hl)
TR_CurrentSphere_Offset = TR_CurrentSphere_Offset + Sphere
    edup

TraceRay_CheckPlaneIntersection:

    if 0
        ld bc, (DirY)
        bit 7, b
        jr z, CheckMaxDist
        ld hl, PLANE_Y
        SDIV16
    else
        ld hl, (PlaneY_By_DirY)
    endif

    ; T < 0? No hit
    bit 7, h
    jr nz, CheckMaxDist

    ; if T < Dist, we have a hit
    ld bc, (Dist)
    or a
    sbc hl, bc
    add hl, bc
    jr nc, CheckMaxDist

    ; count as a hit on plane, and save plane normal
    ld (Dist), hl
    xor a
    ld (SphereHit), a
    ld a, RAYATTR_PLANEHIT
    ld (RayAttr), a

    if PERTURB_NORMAL
Normal_Perturb equ $+1
    ld a, 0
    add 13
    and #0f
    ld (Normal_Perturb), a
    endif

    ld hl, 0
    ld (NZ), hl
    ld l, a
    ld (NX), hl
    ld hl, 128
    ld (NY), hl

CheckMaxDist:
    ld hl, MAX_DIST
    ld bc, (Dist)
    or a
    sbc hl, bc
    jr nz, NoSkyHit

    if VARY_SKYCOLOR
SkyColorEnabled equ $+1
        ld a, 0
        and a
        ret z

SkyCounter equ $+1      
        ld a, 1
        dec a
        ld (SkyCounter), a
        ret z

Sky_color equ $+1
        ld a, 1
        dec a
        and 3
        ld (Sky_color), a
        sra a
    else
        xor a
    endif
    ret

NoSkyHit:
    ; Calculate the hit point
    ; bc still holds dist
    ld de, (DirX)
    SMUL16
    ld (PtX), hl

    ld de, (DirY)
    ld bc, (Dist)
    SMUL16
    ld (PtY), hl

    ; PtZ is always Dist

    ld a, (SphereHit)
    and a
    jr z, CalcLighting      ;   if all we hit is a plane, we're ready to calculate the lighting

    ; otherwise, calculate the normal
    ; need to multiply SphereHit (remember it's Index + 1) by 10, that is, 8+2
    ld hl, Spheres_table
    dec a
    ; small opt - remove if size matters
    jr z, TraceRay_SphereNormalCalc_NoOffsetNeeded
    ASSERT Sphere == 14, Revise the multiplication routine
    ld d, a
    ld e, Sphere
    mul
    ld l, e

TraceRay_SphereNormalCalc_NoOffsetNeeded:
    ; using the fact that our spheres have R = 1, so the vector from the center of the sphere to a point on it is also the normal to that point
    ld c, (hl)
    inc l
    ld b, (hl)
    inc l
    ex de, hl
    ld hl, (PtX)
    or a
    sbc hl, bc
    ld (NX), hl
    ex de, hl

    ld c, (hl)
    inc l
    ld b, (hl)
    inc l
    ex de, hl
    ld hl, (PtY)
    or a
    sbc hl, bc
    ld (NY), hl
    ex de, hl

    ld c, (hl)
    inc l
    ld b, (hl)
    ld hl, (PtZ)
    or a
    sbc hl, bc
    ld (NZ), hl

    ; intentional fall-through
; -----------------------------------------------------------------------------------------------------------------------
; Calculates lighting
; Expects variables: Spheres, DirX, DirY, DirX_Squared, DirY_Squared, PtX, PtY, PtZ, NX, NY, NZ
; Returns a as the light intensity value
CalcLighting:
    ; trace against the sphere to determine if we're in the shadow

    ; sphere hit variable is used to avoid tracing with the sphere that we hit
    xor a
    ld (SphereIndex), a
    ld (InShadow), a

CL_CurrentSphere_Offset DEFL 0
    dup NUM_SPHERES
        ld a, (SphereIndex)
        ;cp 1
        ;jp z, 1F   ; for a test, never trace with Sphere 2
        inc a ; sphere hit is incremented by one
        ld b, a
        ld a, (SphereHit)
        cp b
        jp z, 1F    ; // skip tracing with this sphere

        ; first we need to calculate hit point relative to this sphere
        ld hl, (PtX)
        ld de, (Spheres_table + CL_CurrentSphere_Offset + Sphere.X)
        or a
        sbc hl, de
        ld (Rel_PtX), hl
        SSQUARE16
        push hl

        ld hl, (PtY)
        ld de, (Spheres_table + CL_CurrentSphere_Offset + Sphere.Y)
        or a
        sbc hl, de
        ld (Rel_PtY), hl
        SSQUARE16
        push hl

        ld hl, (PtZ)
        ld de, (Spheres_table + CL_CurrentSphere_Offset + Sphere.Z)
        or a
        sbc hl, de
        ld (3_F + 1), hl
        SSQUARE16
        push hl

        ; Calculate B = -((smul16(Rel_PtX, DirLightX) + smul16(Rel_PtX, DirLightY) + smul16(Rel_PtX, DirLightZ)) << 1);
3   ; Rel_PtZ
        ld de, 0
        SMUL16_DIR_LIGHT_Z
        push hl

        ld de, (Rel_PtX)
        SMUL16_DIR_LIGHT_X
        push hl

        ld de, (Rel_PtY)
        SMUL16_DIR_LIGHT_Y

        pop de
        add hl, de

        pop de
        add hl, de

        add hl, hl

        ex de, hl
        xor a
        ld h, a
        ld l, a
        sbc hl, de
        ; B is ready
        ; kludgy reference to LocalTraceB, which is '2' label
        ld (2_F + 1), hl

        ; calculate C = smul16(PtX, PtX) + smul16(PtY, PtY) + smul16(PtZ, PtZ) - Sphere[3];
        pop hl
        pop de
        add hl, de

        pop de
        add hl, de

        ld de, 1 * FIXEDPOINT_SCALER ;(Spheres_table + CL_CurrentSphere_Offset + 6)

        or a
        sbc hl, de
        ; C is ready
        ;ld (TraceRay_C), hl

        ; calculate D = smul16(B, B) - (smul16(Light_A, C) << 1);
        ; hl already holds C
        ex de, hl
        SMUL16_DIR_LIGHT_A
        add hl, hl
        push hl 

        ; kludgy reference to LocalTraceB, which is '2' label
        ld hl, (2_F + 1)    ; see display strings for the value
        ;ex de, hl
        SSQUARE16

        pop de
        or a
        sbc hl, de

        ; D is ready
        bit 7, h
        jp nz, 1F   ;   // sphere was not hit

        ; calculate T = sdiv16((B + D), Light_A);
        ; hl already holds d
2   ; LocalTraceB
        ld de, 0
        add hl, de

        ; hl - holds B+D is now being divided by bc, holding DIR_LIGHT_A
        ;ld bc, DIR_LIGHT_A
        ;call sdiv16
        ; as light A is 246, we can approximate division by division by 256 (i.e. signed shift right)
        ; but since all we need is a sign, we don't even need that heh...               

        ; if (T > 0), we hit a sphere
        bit 7, h
        jp nz, 1F

        ; hit a sphere!
        ld a, 1
        ld (InShadow), a
        ld a, (RayAttr)
        or RAYATTR_INSHADOW
        ld (RayAttr), a
        jp CalcLighting_CalculateRegularTerm

1   ; next sphere
        ld hl, SphereIndex
        inc (hl)
CL_CurrentSphere_Offset = CL_CurrentSphere_Offset + Sphere
    edup

CalcLighting_CalculateRegularTerm:
    ; regular lighting, NdotL = smul16(NX, DirLightX) + smul16(NY, DirLightY) + smul16(NZ, DirLightZ);
    ; normal is expected to be normalized
    ld de, (NX)
    SMUL16_DIR_LIGHT_X
    push hl

    ld de, (NY)
    SMUL16_DIR_LIGHT_Y
    push hl

    ld de, (NZ)
    SMUL16_DIR_LIGHT_Z
    pop de
    add hl, de
    pop de
    add hl, de

    xor a
    bit 7, h
    ret nz      ; no light, NdotL is < 0

    ld b, h                                                                                                                                                                         
    ld c, l

    ; calculate ZFade =  max(0, MAX_BRIGHTNESS - Z)
    ld hl, MAX_BRIGHTNESS * 128 ; MAX_BRIGHTNESS in 9.7 fixedpoint
    ld de, (PtZ)
    xor a
    sbc hl, de
    ; in case we have Z > 16, return 0
    ret c

    ; here we'll check the shadow
    ld a, (InShadow)
    and a
    jr z, CalcLighting_NotInShadow

    sra h
    rr l
    sra h
    rr l

CalcLighting_NotInShadow:   
    ; multiply ZFade by NdotL
    ; and take its integer value
    ex de, hl
    SMUL16_INTEGER_ONLY

    ;ld a, h
    ;sla l
    ;rla
    
    ; but everything above MAX_BRIGHTNESS is out
    cp MAX_BRIGHTNESS + 1
    ret c

    ld a, MAX_BRIGHTNESS
    ret

; -----------------------------------------------------------------------------------------------------------------------
; Raytraces screen with a GRID_WIDTH x GRID_HEIGHT grid where each ray has MAX_BRIGHTNESS intensity value.
; Expects variables: Spheres
; Sets variables: DirX, DirY, DirX_Squared, DirY_Squared
raytrace:
    if (VARY_SKYCOLOR)
        ; enable sky color for the full 64x48 trace, looks good there
        ld a, 1
        ld (SkyColorEnabled), a
    endif

    ld b, GRID_HEIGHT

raytrace_y_loop:
    ld a, b
    dec a
    ld (ScreenY), a     ; ScreenY = (24 - YCounter)

    push bc
    ld h, high DirYTab
    ld l, a

    ld e, (hl)
    inc h
    ld d, (hl)
    inc h

    ld (DirY), de
    
    ld e, (hl)
    inc h
    ld d, (hl)
    inc h
    ld (DirY_Squared), de

    ld e, (hl)
    inc h
    ld d, (hl)
    ld (PlaneY_By_DirY), de

    ld b, GRID_WIDTH
    ld hl, DirXTab

raytrace_x_loop:
    ld a, GRID_WIDTH
    sub b
    ld (ScreenX), a

    push bc
    push hl

    ld e, (hl)
    inc h
    ld d, (hl)
    inc h

    ld (DirX), de
    
    ld e, (hl)
    inc h
    ld d, (hl)
    ld (DirX_Squared), de

    call TraceRay
    ; a good place to decrement global ray count and print
    ld hl, (ScreenStart)
    ld de,(ScreenX) ; ScreenY will be in D
    ; We have 256*D + E
    ; For 2x2 pixels, we need an adress like #4000 + 128*D + E.
    rl e    ; guaranteed to put 0 to Carry as we don't have 128+ coords
    rr d
    rr e
    add hl, de
    cp 5
    jr nc, raytrace_PlotFullPixel
    cp 3
    jr nc, raytrace_PlotCheckerboard
    ; ploat just top left
    ld (hl), a
    add hl, #40
    ld (hl), 0
    jp raytrace_Epilogue

raytrace_PlotCheckerboard:    
    ld (hl), a
    add hl, #40
    swapnib
    ld (hl), a
    jp raytrace_Epilogue

raytrace_PlotFullPixel:
    ld c, a
    swapnib ; Z80N, equivalent to 4 RLCA
    or c
    ld (hl), a
    ; we need to advance hl by 64
    add hl, #40 ; thanks Z80N
    ld (hl), a

raytrace_Epilogue:
    if (PROFILE_RAYCAST)
        ld a, (perf_border_color)
        and #0f
        inc a
frame_color equ $+1
        xor #0f
        nextreg TRANSPARENCY_FALLBACK_COL_NR_4A, a
        ld (perf_border_color), a

MaxRaysToTrace equ $+1
        ld bc, MAX_RAYS_TO_TRACE
        dec bc
        ld (MaxRaysToTrace),bc
        ld a, b
        or c
        jr z, stop_tracing
    endif

    pop hl
    pop bc
    inc l
    dec b
    jp nz, raytrace_x_loop

    pop bc
    dec b
    jp nz, raytrace_y_loop
    ret

    if (PROFILE_RAYCAST)
stop_tracing:
    ld bc, MAX_RAYS_TO_TRACE
    ld (MaxRaysToTrace),bc
    pop bc
    pop bc
    pop bc
    ret
    endif

    if (PROFILE_RAYCAST || PROFILE_MULTIPLY || PROFILE_DIVISION || PROFILE_QUAD_FILLERS)
perf_border_color db 0
    endif

;-------------------------------------------------------------------------------
    ; ZX0 depacker
    include "dzx0_standard.asm"

; ---------------------
Spheres_From_RTZX:
Spheres_View1:
    Sphere -176, 0, 384, 128, 1266
    Sphere 48, 128, 640, 128, 3218
    Sphere 400, 0, 896, 128, 11490

Spheres_View2:
    Sphere 0, 3 * FIXEDPOINT_SCALER / 2, 3 * FIXEDPOINT_SCALER, 128, 0
    Sphere 0, 0, 5 * FIXEDPOINT_SCALER, 128, 0
    Sphere 0, -3 * FIXEDPOINT_SCALER / 2, 7 * FIXEDPOINT_SCALER, 128, 0

Spheres_View3:
    Sphere 2 * FIXEDPOINT_SCALER, -FIXEDPOINT_SCALER / 2, 6 * FIXEDPOINT_SCALER, 128, 0
    Sphere 0, 0, 4 * FIXEDPOINT_SCALER, 128, 0
    Sphere -2 * FIXEDPOINT_SCALER, -FIXEDPOINT_SCALER / 2, 6 * FIXEDPOINT_SCALER, 128, 0

Spheres_View4:
    Sphere -1 * FIXEDPOINT_SCALER, 0, 3 * FIXEDPOINT_SCALER, 128, 0
    Sphere 0, 0, 5 * FIXEDPOINT_SCALER, 128, 0
    Sphere 1 * FIXEDPOINT_SCALER, 0, 7 * FIXEDPOINT_SCALER, 128, 0

; ---------------------
; raytrace variables (will be set before being used, so safe to leave outside the saved area)
ScreenX:
    db #FF
ScreenY:    ; must be immediately following ScreenX
    db #FF

; ray X direction
DirX:
    dw 0

; ray X direction squared (precalc for speed)
DirX_Squared:
    dw 0

; ray Y direction
DirY:
    dw 0

; ray Y direction squared (precalc for speed)
DirY_Squared:
    dw 0

; Plane_Y divided by ray Y
PlaneY_By_DirY:
    dw 0

; TraceRay vars
; first term
TraceRay_A:
    dw 0
TraceRay_B:
    dw 0
TraceRay_C:
    dw 0

; current dist
Dist:
    dw 0
SphereHit:
    db 0
SphereIndex:
    db 0
InShadow:
    db 0

; used by RaytraceSubdiv to figure out info about the ray. See RAYATTR_ defines for the meaning
RayAttr:
    db 0

; point that we hit
PtX:
    dw 0
PtY:
    dw 0
PtZ equ Dist        ; since we trace with DirZ == 1, PtZ = Dist * DirZ is equal to Dist
;   dw 0

; normal at the hit
NX:
    dw 0
NY:
    dw 0
NZ:
    dw 0

; hit point relative to a sphere (used in ligthing calculations)
Rel_PtX:
    dw 0
Rel_PtY:
    dw 0
;Rel_PtZ:   - changed to inline storage
;   dw 0

    align 256
Spheres_table:
    block Sphere*3

    align 256
SinTab:
    db #00, #03, #06, #09, #0c, #0f, #12, #15, #18, #1c, #1f, #22, #25, #28, #2b, #2e
    db #30, #33, #36, #39, #3c, #3f, #41, #44, #47, #49, #4c, #4e, #51, #53, #55, #58 
    db #5a, #5c, #5e, #60, #62, #64, #66, #68, #6a, #6c, #6d, #6f, #70, #72, #73, #75 
    db #76, #77, #78, #79, #7a, #7b, #7c, #7c, #7d, #7e, #7e, #7f, #7f, #7f, #7f, #7f 
    db #7f, #7f, #7f, #7f, #7f, #7f, #7e, #7e, #7d, #7c, #7c, #7b, #7a, #79, #78, #77 
    db #76, #75, #73, #72, #70, #6f, #6d, #6c, #6a, #68, #66, #64, #62, #60, #5e, #5c 
    db #5a, #58, #55, #53, #51, #4e, #4c, #49, #47, #44, #41, #3f, #3c, #39, #36, #33 
    db #30, #2e, #2b, #28, #25, #22, #1f, #1c, #18, #15, #12, #0f, #0c, #09, #06, #03 
    db #00, #fd, #fa, #f7, #f4, #f1, #ee, #eb, #e8, #e4, #e1, #de, #db, #d8, #d5, #d2 
    db #d0, #cd, #ca, #c7, #c4, #c1, #bf, #bc, #b9, #b7, #b4, #b2, #af, #ad, #ab, #a8 
    db #a6, #a4, #a2, #a0, #9e, #9c, #9a, #98, #96, #94, #93, #91, #90, #8e, #8d, #8b 
    db #8a, #89, #88, #87, #86, #85, #84, #84, #83, #82, #82, #81, #81, #81, #81, #81 
    db #81, #81, #81, #81, #81, #81, #82, #82, #83, #84, #84, #85, #86, #87, #88, #89 
    db #8a, #8b, #8d, #8e, #90, #91, #93, #94, #96, #98, #9a, #9c, #9e, #a0, #a2, #a4 
    db #a6, #a8, #ab, #ad, #af, #b2, #b4, #b7, #b9, #bc, #bf, #c1, #c4, #c7, #ca, #cd 
    db #d0, #d2, #d5, #d8, #db, #de, #e1, #e4, #e8, #eb, #ee, #f1, #f4, #f7, #fa, #fd 
    db #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00 
    db #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00 
    db #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00 
    db #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00 
    db #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00 
    db #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00 
    db #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00 
    db #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00 
    db #00, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff 
    db #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff 
    db #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff 
    db #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff 
    db #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff 
    db #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff 
    db #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff 
    db #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff 
CosTab:
    db #80, #7f, #7f, #7f, #7f, #7f, #7e, #7e, #7d, #7c, #7c, #7b, #7a, #79, #78, #77 
    db #76, #75, #73, #72, #70, #6f, #6d, #6c, #6a, #68, #66, #64, #62, #60, #5e, #5c 
    db #5a, #58, #55, #53, #51, #4e, #4c, #49, #47, #44, #41, #3f, #3c, #39, #36, #33 
    db #30, #2e, #2b, #28, #25, #22, #1f, #1c, #18, #15, #12, #0f, #0c, #09, #06, #03 
    db #00, #fd, #fa, #f7, #f4, #f1, #ee, #eb, #e8, #e4, #e1, #de, #db, #d8, #d5, #d2 
    db #d0, #cd, #ca, #c7, #c4, #c1, #bf, #bc, #b9, #b7, #b4, #b2, #af, #ad, #ab, #a8 
    db #a6, #a4, #a2, #a0, #9e, #9c, #9a, #98, #96, #94, #93, #91, #90, #8e, #8d, #8b 
    db #8a, #89, #88, #87, #86, #85, #84, #84, #83, #82, #82, #81, #81, #81, #81, #81 
    db #81, #81, #81, #81, #81, #81, #82, #82, #83, #84, #84, #85, #86, #87, #88, #89 
    db #8a, #8b, #8d, #8e, #90, #91, #93, #94, #96, #98, #9a, #9c, #9e, #a0, #a2, #a4 
    db #a6, #a8, #ab, #ad, #af, #b2, #b4, #b7, #b9, #bc, #bf, #c1, #c4, #c7, #ca, #cd 
    db #d0, #d2, #d5, #d8, #db, #de, #e1, #e4, #e8, #eb, #ee, #f1, #f4, #f7, #fa, #fd 
    db #00, #03, #06, #09, #0c, #0f, #12, #15, #18, #1c, #1f, #22, #25, #28, #2b, #2e 
    db #30, #33, #36, #39, #3c, #3f, #41, #44, #47, #49, #4c, #4e, #51, #53, #55, #58 
    db #5a, #5c, #5e, #60, #62, #64, #66, #68, #6a, #6c, #6d, #6f, #70, #72, #73, #75 
    db #76, #77, #78, #79, #7a, #7b, #7c, #7c, #7d, #7e, #7e, #7f, #7f, #7f, #7f, #7f 
    db #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00 
    db #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00 
    db #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00 
    db #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00 
    db #00, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff 
    db #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff 
    db #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff 
    db #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff 
    db #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff 
    db #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff 
    db #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff 
    db #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff, #ff 
    db #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00 
    db #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00 
    db #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00 
    db #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00 

    align 256
    if 0
SpansToPOTTable:
    db 0, 0                                                             ; 0 - 1
    db 1                                                                ; 2
    db 2, 2                                                             ; 3 4
    db 3, 3, 3, 3                                                       ; 5-8
    db 4, 4, 4, 4, 4, 4, 4, 4                                           ; 9-16
    dup 16                                                              ; 17-32 (16 numbers)
        db 5
    edup
    dup 32                                                              ; 33 - 64 (32 numbers)
        db 6
    edup
    else

Divisor DEFL 2
Spans_To_256_Div_Span_Table:
    db 255, 255 ; spans of length 0 and 1 are all but impossible
    dup 64
        db 256/Divisor
Divisor = Divisor + 1
    edup
    endif

FirstScreen:
    incbin "../res/NextFirstScreen.scr.zx0"

SecondScreen:
    incbin "../res/NextSecondScreen.scr.zx0"

TitleScreen:
    incbin "../res/TitleScreen.pgm.bin.zx0"

DemosplashLogo:
    incbin "../res/Demosplash.scr.zx0"

    align 256
DirYTab:
PlaneYByDirYTab equ DirYTab + 1024      ; DirYByPlaneYTab is supposed to be adjacent to DirYTab
    block 1024
    block 512
DirXTab:
    block 1024

; cache of the rays already traced (only used for RaytraceSubdiv)
RayCache:
    block GRID_WIDTH * GRID_HEIGHT  ; values (zeroed every start).  Bit 7 set means it is cached
    block GRID_WIDTH * GRID_HEIGHT  ; attributes (not zeroed, overwritten each time).

; stack of the areas to vist
AreaStack:
    block (Area5 * 64)

    DISPLAY "Last address is ", $
    savebin "rtzx_main_next.bin", savebin_begin, $-savebin_begin

; --------------------------------------------------------
; music memory

    SLOT 6
    PAGE 29
    ORG #C000

MusicStart:
    include "player/fast_psg_player.asm"

CompressedPsgSize equ 15122

    ORG 65536-CompressedPsgSize
CompressedPSG:
music equ CompressedPSG
    incbin "../res/ascendant_cut.psg.l0", 0, CompressedPsgSize-8192

    SLOT 7
    PAGE 30
    ORG #E000
    incbin "../res/ascendant_cut.psg.l0", CompressedPsgSize-8192, 8192

    savebin "rtzx_next_music.bin", MusicStart, $-MusicStart

    SAVENEX OPEN "rtzx_main_next.nex", savebin_begin, $7F40
    SAVENEX CORE 3, 0, 0
    SAVENEX CFG 0, 0, 1, 0
    SAVENEX AUTO
    SAVENEX CLOSE
