    device ZXSPECTRUMNEXT

    include "../constants.i.asm"

    org $E000

overall_start:
    ; close DivMMC paging or writing to MMU0/1 won't have effect (see Page 34 of the esx api documentation talks about it under "bootstrapping a game from a dot command".
    ; https://gitlab.com/thesmog358/tbblue/-/raw/master/docs/nextzxos/NextZXOS_and_esxDOS_APIs.pdf?inline=false )

    ld hl, real_start
    rst $20

real_start:
    ; turn on turbo
    nextreg TURBO_CONTROL_NR_07, 3

    ;ld sp, $ffff

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

    ld ix, MusicTonesPacked
    ld de, #0000
    exx
    call upkr.unpack

    ; map next 7 pages for the registers (take 56896 bytes), starting from $0000
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

    ld ix, MusicRegs6_13Packed
    ld de, #0000
    exx
    call upkr.unpack

    ; map next 3 pages for the code, starting from $8000
    pop af
    inc a
    nextreg MMU4_8000_NR_54, a
    inc a
    nextreg MMU5_A000_NR_55, a
    inc a
    nextreg MMU6_C000_NR_56, a

    ld ix, CompressedMainCode
    ld de, #8000
    push de
    exx
    ; intentional fall-through to upkr.unpack

        ; upkr 'allocates' PROBS array without really allocating
UPKR_PROBS_ORIGIN EQU ProbsBuffer
    define UPKR_UNPACK_SPEED            ; also makes it compress better
    include "../upkr/unpack.asm"

    align 256
ProbsBuffer:
    block 320

    SAVEBIN "kickstart2.bin", overall_start, $ - overall_start

    ; we don't need to save the compressed data, we use it just for the offsets
    include "compressed_data_inc_for_kickstart.inc"
