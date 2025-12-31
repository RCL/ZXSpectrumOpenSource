	slot 3
	page 3

	org $C000
page3_start:

; --- bolt
GG_BOLT_PAGE EQU 3
bolt_start
	include "gg_bolt/gg_bolt_engine.inc"
	DISPLAY "Bolt code takes ", /A, $-bolt_start, " bytes"

gg_bolt_scrzx0:
	incbin "gg_bolt/_gg_bolt.scr.rcs.zx0"

; --- sea
GRNSEA_PAGE  EQU 3

GRNSEA_ASSEMBLED_ADDRESS equ $8000

grnsea_init equ GRNSEA_ASSEMBLED_ADDRESS
grnsea_mainloop equ GRNSEA_ASSEMBLED_ADDRESS+3

res_grnsea_code_packed
	incbin "grnsea/codeblob.bin.zx0"

res_grnsea:
	incbin "grnsea/grnsea.scr.rcs.zx0"

; --- timer
GRNTIMER_PAGE EQU 3

GRNTIMER_ASSEMBLED_ADDRESS equ $8000
grntimer_init equ GRNTIMER_ASSEMBLED_ADDRESS
grntimer_tick equ GRNTIMER_ASSEMBLED_ADDRESS+3

res_grntimer_code_packed:
	incbin "grntimer/codeblob.bin.zx0"

res_grntimer
	incbin "grntimer/grntimer.scr.rcs.zx0"

; --- letters
GG_LETTERS_PAGE EQU 3

GG_LETTERS_ASSEMBLED_ADDRESS EQU $6000

gg_letters_mainthread equ GG_LETTERS_ASSEMBLED_ADDRESS
gg_letters_interrupt equ GG_LETTERS_ASSEMBLED_ADDRESS+3
gg_letters_init equ GG_LETTERS_ASSEMBLED_ADDRESS+6

gg_letters_packed:
	incbin "gg_letters/_gg_letters.bin.zx0"

res_gg_letters_scr
	incbin "gg_letters/_gg_letters.scr.rcs.zx0"

gg_letters_persistent_data
	db 82,97,120,111,102,116,20,12

; --- sweets
GRNSWEETS_SCREEN_PAGE equ 3
res_emptyscreen
	incbin "../res/gfx/imagery/emptyscreen.scr.rcs.zx0"

GRNSWEETS_CODE_PAGE equ 3

GRNSWEETS_ASSEMBLED_ADDRESS equ $8000
grnsweets_init equ GRNSWEETS_ASSEMBLED_ADDRESS
grnsweets_tick equ GRNSWEETS_ASSEMBLED_ADDRESS+3

res_sweets_code_packed:
	incbin "grnsweets/codeblob.bin.zx0"

; --- pentium

PENTIUM_RUNTIME_ADDR equ $8000
pentium_init equ PENTIUM_RUNTIME_ADDR
pentium_tick equ PENTIUM_RUNTIME_ADDR + 3

; --- uvb

UVB_PACKED_CODE_PAGE equ 3

UVB_RUNTIME_ADDRESS equ $6000
res_uvb_code_packed:
	include "gg_uvb/gg_uvb.asm"

; --- disco

DISCO_SCREEN_SECOND_PAGE	equ 3

res_disco_scr_part2
	incbin "disco/disco_fix4.scr.rcs.zx0", res_disco_scr_part1_length
res_disco_scr_part2_length equ $-res_disco_scr_part2
	DISPLAY "res_disco_scr_part2_length ", /A, res_disco_scr_part2_length

; --- telegron

TELEGRON_SCREEN_PAGE	equ 3

res_telegron_scr
	incbin "telegron/eye_with_bg.scr.rcs.zx0"

PAGE3_SIZE EQU $ - page3_start
	SAVETAP "../output/page3.tap", CODE, "page3", page3_start, PAGE3_SIZE
	SAVEBIN "../output/page3.bin", page3_start, PAGE3_SIZE
