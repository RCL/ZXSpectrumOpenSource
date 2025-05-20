    device ZXSPECTRUM128

    MACRO SetAYRegAndAdvance
        ld bc, #fffd
        out (c), e
        ld b, #bf
        out (c), d
        inc e
        inc h
    ENDM

    MACRO MusicRegsUpdate
        ld d, (hl)
        SetAYRegAndAdvance
    ENDM

    org #80FF

savebin_begin:

    ; we know that in our track the whole value of reg 13 is 0x0C
    ld de, $0c0d
    SetAYRegAndAdvance

    ld hl, $5800

main_loop_reset:
    xor a
main_loop:
    ;ei     ; only needed for .sna
    halt
    halt
    halt
    halt

    exx

    ld l, a
    ld h, high MusicRegs

    ; update regs 2-4
    ld e, 2
    DUP 3
        MusicRegsUpdate
    EDUP

    inc e

    ; update regs 6-11
    DUP 6
        MusicRegsUpdate
    EDUP

    exx

    inc a
    and $3f
    jp nz, main_loop

    ld a, h
    cp $5c
    jp nc, main_loop_reset

    ld d, h
    ld e, l
    inc de
    ld bc, 32 * 4 - 1
    ld (hl), $12
    ldir
    inc hl

    ld a, h
    cp $5b
    jp nz, main_loop_reset

    ld a, 2
    out (#fe), a
    jp main_loop_reset


    align 256
MusicRegs:
    incbin "../res/reg02_div4.bin"

    align 256
    incbin "../res/reg03_div4.bin"

    align 256
    incbin "../res/reg04_div4.bin"

    align 256
    incbin "../res/reg06_div4.bin"

    align 256
    incbin "../res/reg07_div4.bin"

    align 256
    incbin "../res/reg08_div4.bin"

    align 256
    incbin "../res/reg09_div4.bin"

    align 256
    incbin "../res/reg10_div4.bin"

    align 256
    incbin "../res/reg11_div4.bin"
        
RegisterFileLength EQU 128

    savebin "redredux_main.bin", savebin_begin, $-savebin_begin

PrevRegs:
    block 14