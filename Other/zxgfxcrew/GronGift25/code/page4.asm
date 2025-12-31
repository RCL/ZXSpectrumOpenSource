	slot 3
	page 4

	org $C000
page4_start:

res_soda_legend:
	incbin "../res/gfx/imagery/soda-legend_zx.scr.rcs.zx0"

CAT_PAGE equ 4
CAT_ASSEMBLED_ADDRESS equ $6000

cat_mainthread_tick equ $6000
cat_im2_tick equ $6003

cat_code_packed:
	incbin "cat/cat_betonka_print.bin.zx0"

FLASH_SCREEN_PAGE equ 4
res_flash:
	incbin "../res/gfx/imagery/flash.scr.rcs.zx0"

res_soda_last_phase
	incbin "../res/gfx/imagery/soda_zx_last_frame.scr.rcs.zx0"

; --- board

BOARD_BLOCKANIM_PAGE equ 4
res_board_packed
	incbin "../res/gfx/imagery/board.blockanim.zx0"

; --- disco

DISCO_CODE_PAGE equ 4
DISCO_ASSEMBLED_ADDRESS equ $8000

disco_init equ DISCO_ASSEMBLED_ADDRESS
disco_tick equ DISCO_ASSEMBLED_ADDRESS+3

res_disco_code_packed
	incbin "disco/output.bin.zx0"

; this must be the last include! -------------
DISCO_SCREEN_FIRST_PAGE	equ 4

res_disco_scr_part1_length equ 65536-$
	DISPLAY "res_disco_scr_part1_length ", /A, res_disco_scr_part1_length
res_disco_scr_part1
	incbin "disco/disco_fix4.scr.rcs.zx0", 0, res_disco_scr_part1_length

PAGE4_SIZE EQU $ - page4_start
	SAVETAP "../output/page4.tap", CODE, "page4", page4_start, PAGE4_SIZE
	SAVEBIN "../output/page4.bin", page4_start, PAGE4_SIZE

