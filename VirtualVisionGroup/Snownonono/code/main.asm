    device ZXSPECTRUM128

NUM_BUFFER_PAGES        EQU 6
NUM_SNOWFLAKES          EQU 21

NO_MUSIC                EQU 0
PROFILE_FRAME           EQU 0

    STRUCT  Snowflake
YPos            dw 0
YSpeed          dw 0
XPos            dw 0
    ENDS

    ; pages in a 128K page that is in the A register
    MACRO SetPageInA
        ld ($5b5c), a   ; BANKM
        ld bc, #7ffd
        out (c), a
    ENDM

    ; Advances a reg pair to the next scanline
    ; from https://espamatica.com/zx-spectrum-screen/#next-scanline
    MACRO NextScanline  RegH, RegL
        ld a, RegH
        and $07
        cp $07
        jr z, .ChangeOfLine
        inc RegH
        jr .Done
.ChangeOfLine
        ld a, RegL
        add $20
        ld RegL, a
        ld a, RegH
        jr nc, .NoScreenThirdChange
        add $08
.NoScreenThirdChange
        and $f8
        ld RegH, a
.Done
    ENDM

    ; Resets a snowflake. IX - pointer to the current snowflake structure
    ; Made a macro so exact same code can be used twice and compress better
    ; Keeps HL and B intact
    MACRO ResetSnowflake
        xor a
        ld (ix + Snowflake.XPos), a
        ld (ix + Snowflake.YSpeed + 1), a

        call rnd
        ld (ix + Snowflake.YPos), a
        call rnd
        and $0f
        ld (ix + Snowflake.YPos + 1), a

        call rnd
        ld (ix + Snowflake.XPos + 1), a

        call rnd
        or $20
        ld (ix + Snowflake.YSpeed), a
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

    org #6800

savebin_begin:
    if (!NO_MUSIC)
        jp CodeStart

MusicRegs:
        incbin "../res/music.bin"
MusicRegsSize EQU $-MusicRegs
NumRegistersSaved EQU 12
RegisterFileLength EQU MusicRegsSize / NumRegistersSaved
    ASSERT RegisterFileLength*NumRegistersSaved = MusicRegsSize

CodeStart:
    endif // NO_MUSIC

    ; clear all the buffers (and also tests for 48K)
    MACRO ClearPage
        ld a, (hl)
        inc hl
        exx
        ld hl, #c000
        SetPageInA

        ; fail gracefully on 48k
        dec (hl)
        ret z

        ld bc, #4000    ; it will write to ROM, but this will compress better
        ld d, h
        ld e, l
        inc e
        ld (hl), l
        ldir
        exx
    ENDM

    ; same macro without the check. Needs to be IDENTICAL (sans check) or you'll ruin the compression
    MACRO ClearPageNoCheck
        ld a, (hl)
        inc hl
        exx
        ld hl, #c000
        SetPageInA

        ld bc, #4000    ; it will write to ROM, but this will compress better
        ld d, h
        ld e, l
        inc e
        ld (hl), l
        ldir
        exx
    ENDM

    ld (iy+0), 4  ; set "Out of Memory" in advance

    ld hl, BufferPages
    DUP NUM_BUFFER_PAGES - 1
        ClearPage
    EDUP
    ClearPageNoCheck

    ; we're 128k here

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

    ld ix, SnowflakesBuffer
    DUP NUM_SNOWFLAKES
        ResetSnowflake
        AdvanceToNextSnowflake
    EDUP    

    ; we know that in our track the whole value of reg 13 is 0x0E
    ld a, 13
    ld bc, #fffd
    out (c), a
    inc a
    ld b, #bf
    out (c), a

    ; -------------------------------
    ; main loop
main_loop:
    ei          ; not really needed, but keeping as a last-ditch reserve
    halt

    if (PROFILE_FRAME)
        ld a, 7
        out (#fe), a
    endif

    ; -------------------------------
    ; music update
    if (!NO_MUSIC)
MusicPos equ $+1
        ld hl, MusicRegs - 1
        ld de, MusicRegs + RegisterFileLength
        inc hl
        or a
        sbc hl, de
        add hl, de
        jr c, NoMusicReset

        ld hl, BufferAddrChangeOp
        ld a, (hl)
        xor 1
        ld (hl), a

        ld hl, BufferScanlineOp
        ld a, (hl)
        xor 1
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

    ; ----------------------------
    ; snow update + draw

    ; calculate the buffer number to print
    ; each buffer takes about 2KB and there are 8 buffers per page
    ; so the buffer number goes from 0 to NUM_BUFFER_PAGES*8 - 1
    
CurrentBuffer equ $+1
    ld a, 0
    inc a
    cp NUM_BUFFER_PAGES*8
    jr c, CurrentBufferReady
    xor a
CurrentBufferReady:
    ld (CurrentBuffer), a

    ld e, a
    sra a
    sra a
    sra a
    ld l, a
    ld h, high BufferPages
    ld a, (hl)
    SetPageInA
    ld a, e
    and $07
    ; Since buffers are 64 x 32, they are stored in planes. First 256 bytes contain 0th scanline of all 8 buffers, next 256 bytes - 1st scanline, and so forth
    ; This allows moving down by simply incrementing h
    ; so all we need is an offset, i.e. multiplication by 32
    add a       ; x2
    add a       ; x4
    add a       ; x8
    add a       ; x16
    add a       ; x32
    ld l, a
    ld h, $c0
    ; current buffer address is ready

    call rnd
    ld b, a

    ; update the snow
    ld ix, SnowflakesBuffer
    DUP NUM_SNOWFLAKES
        ; Ypos: +0, +1
        ; Yspeed: +2, +3
        ; Xpos: +4, +5
        ld a, b
        and (ix + Snowflake.YSpeed)
        add (ix + Snowflake.XPos)
        ld (ix + Snowflake.XPos), a
        ld a, (ix + Snowflake.XPos + 1)
        bit 7, b
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

        sub 16      ; we leave the first 16 pixels above the screen
        jr c, 1F    ; NextSnowflake

        ; check if we need to reset this snowflake
        cp 64
        jr nc, 2F   ; ResetSnowflake

        ; plot it!
        ld d, a
        ld a, (ix + Snowflake.XPos + 1)
        ld e, a
        srl e
        srl e
        srl e
        and $07
        push hl
        add hl, de
        ld e, a
        ld d, high PointTable
        ld a, (de)
        or (hl)
        ld (hl), a
        pop hl
        jr 1F       ; NextSnowflake

2 ; ResetSnowflake
        ResetSnowflake
1 ; NextSnowflake
        AdvanceToNextSnowflake
    EDUP

    ; blit the current buffer
    ld bc, #3f00
BufferAddrChangeOp:
    ex af, af'  ;   xoring this opcode with 1 yields add hl, bc
    inc b

    ; vary the starting scanline to cover the whole screen
StartingScanline equ $+1
    ld a, 0
    inc a
    cp 3
    jr c, StartingScanlineReady
    xor a
StartingScanlineReady
    ld (StartingScanline), a
    add b
    ld d, a
    ld e, c

    ld b, 64
BlitYLoop:
        push de
        push hl
        ld c, #33
        DUP 32
            ldi
        EDUP
        pop hl
BufferScanlineOp:
        inc h
        pop de
        NextScanline d, e
        NextScanline d, e
        NextScanline d, e
    dec b
    jp nz, BlitYLoop

    ; ---------------
    ; end of main loop
    if (PROFILE_FRAME)
        xor a
        out (#fe), a
    endif

    jp main_loop

; ---------------------------------------------------
; Classic ZX Spectrum "Error" sound, for running in 48k (no memory for this alas)
;Rasp:
;   ld hl, $1A90
;   ld de, $0040
;   jp #03B5

; ---------------------------------------------------
; Xorshift algo by raxoft (Patrik Rak), from https://gist.github.com/raxoft/c074743ea3f926db0037

rnd:
        exx
        ld  hl, MusicRegs - 1 ; 0xA280   ; yw -> zt
        ld  de, MusicRegs + RegisterFileLength ;0xC0DE   ; xz -> yw
        ld  (rnd+5),hl  ; x = y, z = w
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
        ld  (rnd+2),hl
        exx
        ret 

; ---------------------------------------------------
; Resources

    align 256
PointTable:
    db %10000000
    db %01000000
    db %00100000
    db %00010000
    db %00001000
    db %00000100
    db %00000010
    db %00000001

    align 256   
BufferPages:
    ; #10 should be the last value or the 48k test will fail
    db #11, #13, #14, #16, #17, #10
    ASSERT $-BufferPages == NUM_BUFFER_PAGES

    align 256
SnowflakesBuffer:
    block NUM_SNOWFLAKES * Snowflake

PrevRegs:
    block 16

SnowflakesBufferSize equ $ - SnowflakesBuffer

    ; we should not allow the main program to overflow since $c000-$ffff is used for the buffers
    ASSERT $ < 49152

    org $c000
    db 1            ; needed for the 48K / 128K test

    savebin "snownonono_main.bin", savebin_begin, $-savebin_begin
    SAVESNA "snownonono_main.sna", #6800
