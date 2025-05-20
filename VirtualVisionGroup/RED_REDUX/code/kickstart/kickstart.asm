    if (PRODUCE_ZX_NEXT_DOT_FILE)
        device ZXSPECTRUMNEXT
        org $2000
    else
        device ZXSPECTRUM128
        org #6000
    endif

overall_start:

    ld hl, compressed
    ld de, #80ff
    push de

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
ZX2_Y_LIMIT_LENGTH  EQU 1

dzx2_nano:

    ; [RCL] - use the strategically chosen org address
    IF (ZX2_Z_IGNORE_DEFAULT)
        ld      b, e ;$ff               ; allocate default offset
    ELSE
        ;ld      bc, $ffff               ; preserve default offset 1
    ld  b, e
    ld  c, e
    ENDIF

        push    bc
        ld      a, d            ; [RCL] we know de is $80ff
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

compressed:
    incbin "../../output/redredux_main.bin.zx2"

overall_size = $ - overall_start

    if (PRODUCE_ZX_NEXT_DOT_FILE)
        SAVEBIN "RED_REDUX.dot",overall_start,overall_size
    else
        SAVETAP "redredux_codeonly_32768.tap",CODE,"RED_REDUX",overall_start,overall_size
        SAVEBIN "redredux.bin",overall_start,overall_size
        SAVESNA "redredux.sna", #8000
    endif