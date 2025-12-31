	slot 3
	page 6

	org $c000
page6_start:

; --- telegron

TELEGRON_CODE_PAGE	equ 6

TELEGRON_RUNTIME_ADDRESS equ $8000
telegron_init equ TELEGRON_RUNTIME_ADDRESS
; expects DE as number of lines!
telegron_scroll_up equ TELEGRON_RUNTIME_ADDRESS+3
; prints next greeting
telegron_print_next_greeting equ TELEGRON_RUNTIME_ADDRESS+6
telegron_invert_font equ TELEGRON_RUNTIME_ADDRESS+9

res_telegron_code_packed
	incbin "telegron/telegron.bin.zx0"

; telegram needs two bytes to store pointer to the next greeting
telegron_persistent_state:
	dw 0

; --- neko

NEKO_CODE_PAGE equ 6

NECO_ASSEMBLED_ADDRESS equ $8000

neko_init equ $8000
neko_tick equ $8003

res_neko_code_packed
	incbin "neko/output.bin.zx0"

; --- rain
GRNRAIN_PAGE EQU 6

GRNRAIN_ASSEMBLED_ADDRESS equ $8000

grnrain_init equ GRNRAIN_ASSEMBLED_ADDRESS
grnrain_infinityrain equ GRNRAIN_ASSEMBLED_ADDRESS+3
grnrain_remap_to_regular equ GRNRAIN_ASSEMBLED_ADDRESS+6

res_grnrain_code_packed
	incbin "grnrain/codeblob.bin.zx0"

res_grnrain
	incbin "grnrain/grnrain.scr.rcs.zx0"


CAT_SCREEN_PAGE equ 6
res_cat_last_phase:
	incbin "../res/gfx/imagery/cat_betonka.png.scr.rcs.zx0"

FLASH_ANIM_PAGE EQU 6
res_flash_packed
	incbin "../res/gfx/imagery/flash.blockanim.zx0"

PAGE6_SIZE EQU $ - page6_start
	SAVETAP "../output/page6.tap", CODE, "page6", page6_start, PAGE6_SIZE
	SAVEBIN "../output/page6.bin", page6_start, PAGE6_SIZE
