	device ZXSPECTRUMNEXT

USE_UPKR	EQU 0

	include "../constants.i.asm"

	org #7000

overall_start:
	di
	nextreg TURBO_CONTROL_NR_07, 3	; 28 Mhz

	; page in pages 29, 30 into #C000-FFFF 
        nextreg MMU6_C000_NR_56, 29
	nextreg MMU7_E000_NR_57, 30

	if (USE_UPKR)
		ld ix, CompressedMusic
		ld de, #C000
		exx
		call upkr.unpack
	else
		ld hl, CompressedMusic
		ld de, #C000
		call dzx0_turbo
	endif


	; return to the default mapping (0, 1) - see https://github.com/z00m128/sjasmplus/issues/59#issuecomment-518732510
        nextreg MMU6_C000_NR_56, 0
	nextreg MMU7_E000_NR_57, 1

	ld hl, CompressedCodeLastByte
	ld de, $ffff
	ld bc, CompressedCodeSize
	lddr

	if (USE_UPKR)
		ld ix, RelocatedCodeAddr
		ld de, #8000
		exx
        	call upkr.unpack
	else
		ld hl, RelocatedCodeAddr
		ld de, #8000
		call dzx0_turbo
	endif

        ; move SP to a different area - we are not expecting to return anyway
        ld sp, #7F40
        jp #8000

	if (USE_UPKR)
UPKR_PROBS_ORIGIN EQU KickstartProbs
		include "../upkr/unpack.asm"

        ; upkr 'allocates' PROBS array without really allocating
KickstartProbs:
        	align 256
        	block 512
        else

; -----------------------------------------------------------------------------
; ZX0 decoder by Einar Saukas & introspec
; "Turbo" version (126 bytes, 21% faster)
; -----------------------------------------------------------------------------
; Parameters:
;   HL: source address (compressed data)
;   DE: destination address (decompressing)
; -----------------------------------------------------------------------------

dzx0_turbo:
        ld      bc, $ffff               ; preserve default offset 1
        ld      (dzx0t_last_offset+1), bc
        inc     bc
        ld      a, $80
        jr      dzx0t_literals
dzx0t_new_offset:
        ld      c, $fe                  ; prepare negative offset
        add     a, a
        jp      nz, dzx0t_new_offset_skip
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
dzx0t_new_offset_skip:
        call    nc, dzx0t_elias         ; obtain offset MSB
        inc     c
        ret     z                       ; check end marker
        ld      b, c
        ld      c, (hl)                 ; obtain offset LSB
        inc     hl
        rr      b                       ; last offset bit becomes first length bit
        rr      c
        ld      (dzx0t_last_offset+1), bc ; preserve new offset
        ld      bc, 1                   ; obtain length
        call    nc, dzx0t_elias
        inc     bc
dzx0t_copy:
        push    hl                      ; preserve source
dzx0t_last_offset:
        ld      hl, 0                   ; restore offset
        add     hl, de                  ; calculate destination - offset
        ldir                            ; copy from offset
        pop     hl                      ; restore source
        add     a, a                    ; copy from literals or new offset?
        jr      c, dzx0t_new_offset
dzx0t_literals:
        inc     c                       ; obtain length
        add     a, a
        jp      nz, dzx0t_literals_skip
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
dzx0t_literals_skip:
        call    nc, dzx0t_elias
        ldir                            ; copy literals
        add     a, a                    ; copy from last offset or new offset?
        jr      c, dzx0t_new_offset
        inc     c                       ; obtain length
        add     a, a
        jp      nz, dzx0t_last_offset_skip
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
dzx0t_last_offset_skip:
        call    nc, dzx0t_elias
        jp      dzx0t_copy
dzx0t_elias:
        add     a, a                    ; interlaced Elias gamma coding
        rl      c
        add     a, a
        jr      nc, dzx0t_elias
        ret     nz
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
        ret     c
        add     a, a
        rl      c
        add     a, a
        ret     c
        add     a, a
        rl      c
        add     a, a
        ret     c
        add     a, a
        rl      c
        add     a, a
        ret     c
dzx0t_elias_loop:
        add     a, a
        rl      c
        rl      b
        add     a, a
        jr      nc, dzx0t_elias_loop
        ret     nz
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
        jr      nc, dzx0t_elias_loop
        ret
	endif

CompressedMusic:
	if (USE_UPKR)
		incbin "../../output/rtzx_next_music.bin.upk"
	else
		incbin "../../output/rtzx_next_music.bin.zx0"
	endif

CompressedCode:
	if (USE_UPKR)
		incbin "../../output/rtzx_main_next.bin.upk"
	else
		incbin "../../output/rtzx_main_next.bin.zx0"
	endif
CompressedCodeSize equ ($ - CompressedCode)
CompressedCodeLastByte equ (CompressedCode + CompressedCodeSize - 1)
RelocatedCodeAddr equ ($ffff - CompressedCodeSize + 1)


overall_size = $ - overall_start

        DISPLAY "CompressedMusic starts at ", /A, CompressedMusic
        DISPLAY "CompressedCode starts at ", /A, CompressedCode, " and takes ", /A, CompressedCodeSize, " bytes (last byte is at", /A, CompressedCodeLastByte, ")."
        DISPLAY "The relocated code addr is ", /A, RelocatedCodeAddr

	;SAVETAP "rtzx_codeonly_32768.tap",CODE,"rtzx_code",overall_start,overall_size
	;SAVEBIN "rtzx.bin",overall_start,overall_size
	;SAVESNA "rtzx.sna", #8000
	SAVENEX OPEN "rtzx_next.nex", overall_start, $6FFE
	SAVENEX CORE 3, 0, 0
	SAVENEX CFG 0, 0, 1, 0
	SAVENEX AUTO
	SAVENEX CLOSE

