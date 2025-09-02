	device ZXSPECTRUM128

USE_UPKR	EQU 0

	org #6000

overall_start:

	if (USE_UPKR)
	ld ix, compressed
	ld de, #80ff
	ld a, d
	push de
	exx
	; intentional fall-through to upkr.unpack

        ; upkr 'allocates' PROBS array without really allocating
UPKR_PROBS_ORIGIN EQU #5900
	include "unpack.asm"

compressed:
	incbin "../../output/anaglyph_main.bin.upk"

	else

	ld hl, compressed
	ld de, #80ff
	push de

; ZX0 decoder by Einar Saukas & Urusergi
dzx0_standard:
        ;ld      bc, $ffff               ; preserve default offset 1
	ld 	b, e
	ld	c, e
        push    bc
        inc     bc
        ld      a, d
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
	incbin "../../output/anaglyph_main.bin.zx0"
	endif

overall_size = $ - overall_start

	SAVETAP "anaglyph_codeonly_24576.tap", CODE, "Anaglyph1k",overall_start,overall_size
	SAVEBIN "anaglyph.bin",overall_start,overall_size
	SAVESNA "anaglyph.sna", #6000