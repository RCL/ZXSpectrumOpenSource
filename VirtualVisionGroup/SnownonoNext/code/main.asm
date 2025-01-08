    device ZXSPECTRUMNEXT

    include "constants.i.asm"

                        ; pages 16-95 should be usable on any Next machine, even the first unexpanded ones with 768KB
FIRST_NEXT_PAGE_USED    EQU 16
LAST_NEXT_PAGE_USED     EQU 95
NUM_NEXT_PAGES_USED     EQU (LAST_NEXT_PAGE_USED - FIRST_NEXT_PAGE_USED + 1)


NUM_SNOWFLAKES          EQU 940     ; 50Hz mode can do more, but I want to support 60Hz

NUM_SNOWFLAKES_LO       EQU (low NUM_SNOWFLAKES)
NUM_SNOWFLAKES_HI       EQU (high NUM_SNOWFLAKES)

NO_MUSIC                EQU 0
PROFILE_FRAME           EQU 0

; Music parameters
NumRegistersSaved       EQU 12


    STRUCT  Snowflake
YPos            dw 0
YSpeed          dw 0
XPos            dw 0
    ENDS

    ; pages in a 8K Next page to address $E000-$FFFF that is in the A register
    MACRO SetPageInA
        nextreg MMU7_E000_NR_57, a
    ENDM

    ; Resets a snowflake. IX - pointer to the current snowflake structure
    ; Made a macro so exact same code can be used twice and compress better
    ; Keeps B intact
    MACRO ResetSnowflake
        xor a
        ld (ix + Snowflake.XPos), a

        call rnd
        ld (ix + Snowflake.YPos), a
        call rnd
        and $3f
        ld (ix + Snowflake.YPos + 1), a

        call rnd
        ld (ix + Snowflake.XPos + 1), a

        call rnd
        ld l, a     
        and $1
        ld h, a
        add hl, hl
        ld (ix + Snowflake.YSpeed), l
        ld (ix + Snowflake.YSpeed + 1), h
    ENDM

    ; a separate macro just to see what compresses better, a row of inc or add
    MACRO AdvanceToNextSnowflake
        if (1)  ; compresses better
            inc ix
            inc ix
            inc ix
            inc ix
            inc ix
            inc ix
        else
            ld de, 6
            add ix, de
        endif
    ENDM

    org #8000

savebin_begin:

    ; don't care about returning to the OS...
    ld sp, $7fff

    ; TURBO!
    nextreg TURBO_CONTROL_NR_07, 3  ; 28 Mhz

    ; --------------------------------------------------------------------------------
    ; clear the pages
    ld a, NUM_NEXT_PAGES_USED
ClearLoop:
        add FIRST_NEXT_PAGE_USED - 1    ; because we will never hit a 0 here
        SetPageInA
        sub FIRST_NEXT_PAGE_USED - 1
        ld hl, $E000
        ld d, h
        ld e, l
        inc e
        ld bc, #1fff
        ld (hl), l
        ldir
    dec a
    jr nz, ClearLoop

    ; --------------------------------------------------------------------------------
    ; setup the snow
    ld ix, SnowflakesBuffer
    ld b, NUM_SNOWFLAKES_HI
SnowflakeResetLoopHi:
        push bc
        ld b, NUM_SNOWFLAKES_LO
SnowflakeResetLoopLo:
            ResetSnowflake
            AdvanceToNextSnowflake
        djnz SnowflakeResetLoopLo
        pop bc
    djnz SnowflakeResetLoopHi

    ; --------------------------------------------------------------------------------
    ; Interrupt set up
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
    and $04 ;   bit 2 - 0 == 50Hz, 1 == 60 Hz
    jr nz, RunningIn60Hz

    ; patch the conditional logic to ignore each 6th update so it never does that (JR NZ to JR)
    ld a, $18
    ld (Skip6thUpdateIf60HzOp), a

RunningIn60Hz:
    nextreg INTERRUPT_ENABLE_MASK_1_C5, 0       ; Disables CTC interrupt

    ld a, high InterruptVectors
    ld i, a
    im 2

    ; -----------------------------------------------------
    ; minor music setup

    ; we know that in our track the whole value of reg 13 is 0x0E
    ld a, 13
    ld bc, #fffd
    out (c), a
    inc a
    ld b, #bf
    out (c), a

    ; -----------------------------------------------------
    ; screen setup

    xor a
    out (#fe), a
    ld bc, 6144
    ld hl, #4000
    ld d, h
    ld e, l
    inc e
    ld (hl), l
    ldir
    ld (hl), #47
    ld bc, 767
    ldir

    ; the rest of the work will be done in the interrupts
    ei
EternalLoop:
    jr $

; ------------------------
; Default interrupt handler for unused interrupts
DefaultInterruptHandler:
    ei
    reti
    
VBlankInterruptHandler:
    if (PROFILE_FRAME)
        ld a, 7
        out (#fe), a
    endif

    ; -------------------------------
    ; music update
    if (!NO_MUSIC)
        ld hl, InterruptCtr
        dec (hl)
Skip6thUpdateIf60HzOp:          ; will be patched to JR in 50Hz
        jr nz, NoInterruptSkip
        ld a, 6
        ld (hl), a
        jp SnowUpdate

NoInterruptSkip:

MusicPos equ $+1
        ld hl, MusicRegs - 1
        ld de, MusicRegs + RegisterFileLength
        inc hl
        or a
        sbc hl, de
        add hl, de
        jr c, NoMusicReset

        ld hl, BufferDirChangeOp
        ld a, (hl)
        xor $18     ; This switches between JR and NOP, read the comment next to BufferDirChangeOp!
        ld (hl), a

        ld hl, MusicRegs - 1
NoMusicReset:
        ld (MusicPos), hl

        ; set AY regs
        ex de, hl
        ld hl, PrevRegs

        xor a
        MACRO MusicRegsUpdate
            ld bc, #fffd
            out (c), a
            ex af, af'
            ld a, (de)
            cp (hl)
            jr z, .SkipSameValue
            ld b, #bf
            out (c), a
            ld (hl), a
.SkipSameValue
            ex af, af'
            inc a
            inc hl
            ex de, hl
            ld bc, RegisterFileLength
            add hl, bc
            ex de, hl
        ENDM
        DUP NumRegistersSaved
            MusicRegsUpdate
        EDUP
    endif // NO_MUSIC

SnowUpdate:
    ; ----------------------------
    ; snow update + draw

    ; calculate the buffer number to work with
    ; each buffer is a full 6144 byte screen and takes a whole Next page (could have been done smarter if more memory is needed)
    
CurrentBuffer equ $+1
    ld a, NUM_NEXT_PAGES_USED
    dec a
    jr nz, CurrentBufferReady
    ld a, NUM_NEXT_PAGES_USED
CurrentBufferReady:
    ld (CurrentBuffer), a

    add FIRST_NEXT_PAGE_USED - 1
    SetPageInA

    ; blit the current buffer
BufferDirChangeOp:
    ; the below JR is turned into NOP for forward blits. But just the NOP opcode only, not the offset!  You need to examine .lst file and make sure that the offset becomes a benign instruction,
    ; which it should, given the offset range. E.g. atm it is $5f, which is LD E, A
    jr BlitForwards

BlitBackwards:
    ld b, 192
BlitBackwardLoop:
        ld d, b
        dec d
        ld e, 0
        pixelad
        set 7, h
        set 5, h

        push hl
        ld a, 192
        sub b
        ld d, a
        pixelad
        ex de, hl
        pop hl

        ld c, d
        DUP 32
            ldi
        EDUP
    
    djnz BlitBackwardLoop
    jr SnowFlakeUpdate

BlitForwards:
    ld hl, $E000
    ld de, $4000
    ld bc, $1800
    ldir		; fast enough at 28Mhz to happen while the border is being drawn, even at 60Hz

SnowFlakeUpdate:
    call rnd
    ld c, a

    ; update the snow
    ld ix, SnowflakesBuffer
    ld b, NUM_SNOWFLAKES_HI
SnowflakeUpdateLoopHi:
        push bc
        ld b, NUM_SNOWFLAKES_LO
SnowflakeUpdateLoopLo:
            ; Ypos: +0, +1
            ; Yspeed: +2, +3
            ; Xpos: +4, +5
            ld a, c
            and (ix + Snowflake.YSpeed)
            add (ix + Snowflake.XPos)
            ld (ix + Snowflake.XPos), a
            ld a, (ix + Snowflake.XPos + 1)
            bit 7, c
            jr nz, 3F ; TurnSnowflakeLeft
            adc 0
            jr 4F ; ContinueSnowFlakeUpdate
3 ; TurnSnowflakeLeft
            sbc 0
4 ; ContinueSnowFlakeUpdate
            ld (ix + Snowflake.XPos + 1), a

            ld a, (ix + Snowflake.YPos)
            add (ix + Snowflake.YSpeed)
            ld (ix + Snowflake.YPos), a
            ld a, (ix + Snowflake.YPos + 1)
            adc (ix + Snowflake.YSpeed + 1)
            ld (ix + Snowflake.YPos + 1), a

            sub 60      ; we leave first 60 pixels above the screen (more than in 128K version because there is 40x more snowflakes)
            jr c, 1F    ; NextSnowflake

            ; check if we need to reset this snowflake
            cp 192
            jr nc, 2F   ; ResetSnowflake

            ; print it!
            ld d, a
            ld e, (ix + Snowflake.XPos + 1)
            pixelad
            ; convert to $E000 range
            set 7, h
            set 5, h
            ;ld a, h
            ;add $a0
            ;ld h, a
            setae
            or (hl)
            ld (hl), a

            jr 1F       ; NextSnowflake

2 ; ResetSnowflake
            ResetSnowflake
1 ; NextSnowflake
            AdvanceToNextSnowflake
        djnz SnowflakeUpdateLoopLo
        pop bc
    djnz SnowflakeUpdateLoopHi

    ; ---------------
    ; end of interrupt
    if (PROFILE_FRAME)
        xor a
        out (#fe), a
    endif

    ei
    reti

rnd:
;   exx
        ld  hl, MusicRegs - 1 ; 0xA280   ; yw -> zt
        ld  de, MusicRegs + RegisterFileLength ;0xC0DE   ; xz -> yw
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
;   exx
        ret 

; ---------------------------------------------------
; Resources

MusicRegs:
    incbin "../res/music.bin"
MusicRegsSize EQU $-MusicRegs
RegisterFileLength EQU MusicRegsSize / NumRegistersSaved
    ASSERT RegisterFileLength*NumRegistersSaved = MusicRegsSize

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

PrevRegs:
    block 16

    align 256
SnowflakesBuffer:
    block NUM_SNOWFLAKES * Snowflake

SnowflakesBufferSize equ $ - SnowflakesBuffer

    ; we should not allow the main program to overflow since $E000-$ffff is used for the buffers
    ASSERT $ < $E000
    DISPLAY "Last address is ", /A, $

    savebin "snownononext_main.bin", savebin_begin, $-savebin_begin

    ; for quick dev iteration only
    SAVENEX OPEN "snownononext_main.nex", savebin_begin, $7F40
    SAVENEX CORE 3, 0, 0
    SAVENEX CFG 0, 0, 1, 0
    SAVENEX AUTO
    SAVENEX CLOSE
