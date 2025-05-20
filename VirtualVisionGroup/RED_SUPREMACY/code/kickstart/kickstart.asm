    device ZXSPECTRUMNEXT

    include "../constants.i.asm"

        ifndef KICKSTART_IN_NEX
            org $2000
        else
            org $6000   ; debugging only
        endif

overall_start:
    di
    ld sp, $ffff

    ld hl, TheRestOfCompressedData
    ld de, $E000 + UncompressedKickstart2Size
    ld bc, TheRestOfCompressedDataSize
    ldir

    ;ld hl, KickstartStage2     ; hl should already be pointing at KickstartStage2 at this point
    ld de, $E000
    push de

    ; intentional fall-through

; -----------------------------------------------------------------------------
; ZX2 decoder by Einar Saukas
; "Nano" version (49-56 bytes)
; -----------------------------------------------------------------------------
; Parameters:
;   HL: source address (compressed data)
;   DE: destination address (decompressing)
; -----------------------------------------------------------------------------

ZX2_Z_IGNORE_DEFAULT    EQU 1
ZX2_X_SKIP_INCREMENT    EQU 1
ZX2_Y_LIMIT_LENGTH  EQU 0

dzx2_nano:

    IF (ZX2_Z_IGNORE_DEFAULT)
        ld      b, $ff                  ; allocate default offset
    ELSE
        ld      bc, $ffff               ; preserve default offset 1
    ENDIF

        push    bc
        ld      a, $80
dzx2n_literals:
        call    dzx2n_elias             ; obtain length
        ldir                            ; copy literals
        add     a, a                    ; copy from last offset or new offset?
        jr      c, dzx2n_new_offset
dzx2n_reuse:
        call    dzx2n_elias             ; obtain length
dzx2n_copy:
        ex      (sp), hl                ; preserve source, restore offset
        push    hl                      ; preserve offset
        add     hl, de                  ; calculate destination - offset
        ldir                            ; copy from offset
        pop     hl                      ; restore offset
        ex      (sp), hl                ; preserve offset, restore source
        add     a, a                    ; copy from literals or new offset?
        jr      nc, dzx2n_literals
dzx2n_new_offset:
        pop     bc                      ; discard last offset
        ld      c, (hl)                 ; obtain offset LSB
        inc     hl
        inc     c
        ret     z                       ; check end marker
        push    bc                      ; preserve new offset

    IF (ZX2_X_SKIP_INCREMENT)
        jr      dzx2n_reuse
    ELSE
        call    dzx2n_elias             ; obtain length
        inc     bc
        jr      dzx2n_copy
    ENDIF

dzx2n_elias:
        ld      bc, 1                   ; interlaced Elias gamma coding
dzx2n_elias_loop:
        add     a, a
        jr      nz, dzx2n_elias_skip
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
dzx2n_elias_skip:
        ret     nc
        add     a, a
        rl      c

    IF (ZX2_Y_LIMIT_LENGTH)
    ELSE
        rl      b
    ENDIF

        jr      dzx2n_elias_loop
; -----------------------------------------------------------------------------

TheRestOfCompressedData:
    ; include the rest of the data - it will be decompressed by kickstart at E000
    include "compressed_data_inc_for_kickstart.inc"
TheRestOfCompressedDataSize EQU $ - TheRestOfCompressedData

KickstartStage2:
    incbin "../../output/kickstart2.bin.zx2"

        ifndef KICKSTART_IN_NEX
            SAVEBIN "sup.dot", $2000, $-$2000
        else
                ; this is for test only
                SAVENEX OPEN "sup_debug_kickstart.nex", overall_start, $7F40
                SAVENEX CORE 3, 0, 0
                SAVENEX CFG 0, 0, 1, 0
                SAVENEX AUTO
                SAVENEX CLOSE
        endif

    ; we don't need to save this in the .dot - it is just for the correct size inclusion
UncompressedKickstart2:
    incbin "../../output/kickstart2.bin"
UncompressedKickstart2Size EQU $ - UncompressedKickstart2
