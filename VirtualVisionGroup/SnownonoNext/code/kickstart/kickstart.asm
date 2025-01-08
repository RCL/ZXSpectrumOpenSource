    device ZXSPECTRUMNEXT

USE_UPKR EQU 0

    org $2000	; origin of all .dot files

overall_start:
    
    di

    if (USE_UPKR)
    ld ix, compressed
    ld de, #8000
    push de
    exx
    ; intentional fall-through to upkr.unpack

        ; upkr 'allocates' PROBS array without really allocating
UPKR_PROBS_ORIGIN EQU #5900
    include "unpack.asm"

compressed:
    incbin "../../output/snownononext_main.bin.upk"

    else

    ld hl, compressed
    ld de, #8000
    push de

; ZX0 decoder by Einar Saukas & Urusergi
dzx0_standard:
        ld      bc, $ffff               ; preserve default offset 1
        push    bc
        inc     bc
        ld      a, d    ; we know it's $80
dzx0s_literals:
        call    dzx0s_elias             ; obtain length
        ldir                            ; copy literals
        add     a, a                    ; copy from last offset or new offset?
        jr      c, dzx0s_new_offset
        call    dzx0s_elias             ; obtain length
dzx0s_copy:
        ex      (sp), hl                ; preserve source, restore offset
        push    hl                      ; preserve offset
        add     hl, de                  ; calculate destination - offset
        ldir                            ; copy from offset
        pop     hl                      ; restore offset
        ex      (sp), hl                ; preserve offset, restore source
        add     a, a                    ; copy from literals or new offset?
        jr      nc, dzx0s_literals
dzx0s_new_offset:
        pop     bc                      ; discard last offset
        ld      c, $fe                  ; prepare negative offset
        call    dzx0s_elias_loop        ; obtain offset MSB
        inc     c
        ret     z                       ; check end marker
        ld      b, c
        ld      c, (hl)                 ; obtain offset LSB
        inc     hl
        rr      b                       ; last offset bit becomes first length bit
        rr      c
        push    bc                      ; preserve new offset
        ld      bc, 1                   ; obtain length
        call    nc, dzx0s_elias_backtrack
        inc     bc
        jr      dzx0s_copy
dzx0s_elias:
        inc     c                       ; interlaced Elias gamma coding
dzx0s_elias_loop:
        add     a, a
        jr      nz, dzx0s_elias_skip
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
dzx0s_elias_skip:
        ret     c
dzx0s_elias_backtrack:
        add     a, a
        rl      c
        rl      b
        jr      dzx0s_elias_loop

compressed:
    incbin "../../output/snownononext_main.bin.zx0"
    endif

overall_size = $ - overall_start

    SAVEBIN "snownononext.dot", $2000, $-$2000

    ; this is for a quick dev iteration only
    SAVENEX OPEN "snownononext.nex", overall_start, $7F40
    SAVENEX CORE 3, 0, 0
    SAVENEX CFG 0, 0, 1, 0
    SAVENEX AUTO
    SAVENEX CLOSE
