	slot 3
	page 1

	org $C000
page1_start:

res_soda_packed
	incbin "../res/gfx/imagery/soda.blockanim.zx0"

; --- zimni pentium

PENTIUM_SCREEN_PAGE equ 1
res_pentium_screen:
	incbin "zimni_pentium/pentium.scr.rcs.zx0"

PENTIUM_PACKED_CODE_PAGE equ 1
pentium_code_packed:	
	incbin "zimni_pentium/binary.C.zx0"

; --- castle

CASTLE_SCREEN_PAGE equ 1
res_castle_screen:
	incbin "../res/gfx/imagery/grongycastle2-8.scr.rcs.zx0"

CASTLE_BLOCKANIM_PAGE equ 1
res_castle_packed:	
	incbin "../res/gfx/imagery/castle.blockanim.zx0"

; --- uvb

UVB_SCREEN_PAGE equ 1
res_uvb_screen
	incbin "gg_uvb/_gg_uvb.scr.rcs.zx0 "

PAGE1_SIZE EQU $ - page1_start
	SAVETAP "../output/page1.tap", CODE, "page1", page1_start, PAGE1_SIZE
	SAVEBIN "../output/page1.bin", page1_start, PAGE1_SIZE
