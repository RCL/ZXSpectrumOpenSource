	slot 3
	page 7

	org $DB00
page7_start:

; --- kernel resources

slideshow_script_start:
	include "script.inc"
	DISPLAY "Script takes ", /A, $ - slideshow_script_start, " bytes."

PAGE_FONT equ 7
font:
	include "font_extension_pseudographics.inc"
font_to_be_inverted:
	incbin "../res/gfx/grnfont.font"

	include "printer.inc"

	include "transitions/zoom_in.asm"

	include "zx0/drcs_onscreen.asm"

; --- board

BOARD_SCREEN_PAGE equ 7
res_board_screen
	incbin "../res/gfx/imagery/grndesk00.scr.rcs.zx0"

PAGE7_SIZE EQU $ - page7_start
	SAVETAP "../output/page7.tap", CODE, "page7", page7_start, PAGE7_SIZE
	SAVEBIN "../output/page7.bin", page7_start, PAGE7_SIZE
