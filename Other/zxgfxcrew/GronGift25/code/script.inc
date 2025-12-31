; This is a display script
; format:
; 1 byte command

CMD_LOOP equ 0
	; loop

CMD_PRINT equ 1
	; print text
	; followed by byte x (pixel coord), byte y (cell coord), attribute value (0 - no change from prev), and a 0-terminated line

CMD_SHOWIMAGE equ 2
	; show image (followed by one byte of page and two bytes of address)

CMD_WAIT_TICK equ 3
	; wait until the timer reaches a certain value (followed by a word (16-bit number) of 2-frame values).

CMD_WAIT_TICK_RELATIVE equ 4
	; follows by a byte of 2-frame values (1/50s). Adds this value to the previous time we waited for (either relative or absolute) and waits for that value

CMD_RESET_TICKS equ 5
	; begins a timer that is incremented every 2 frames (1/50s)  (no params) 
	; "Previous waited value" used by WAIT_TICK/WAIT_TICK_RELATIVE is reset to 0

CMD_SET_MAINTHREAD_EFFECT equ 6
	; followed by the page number of the effect and the address of the effect (0 to disable)

CMD_SET_IM2_EFFECT equ 7
	; followed by the page number of the effect and the address of the effect (0 to disable)
	; effect is executed first thing in the frame

CMD_CALL equ 8
	; followed by the page number of the code and the address of the code
	; executes (CALLs) the given code on the main thread in a blocking fashion

CMD_CALL_WITH_PARAMETER equ 9
	; followed by a 16-bit word to pass in DE, the page number of the code and the address of the code
	; Like CMD_CALL, but you can also pass a 16-bit parameter in DE (e.g. an address)
	; executes (CALLs) the given code on the main thread in a blocking fashion

CMD_PLAY_DIFFANIM equ 10
	; followed by a byte (page number), dword (actions address), dword (data address), byte (number of frames), byte (1/50 ticks between frames)

CMD_MODIFY_ANIM_SPEED equ 11
	; follow by a byte (1/50 ticks between the frames)
	; sets anim speed for the currently playing anim. Note that if the anim is not being played, this value will not persist

CMD_JUMP equ 12
	; followed by word containing script address to jump to (useful for debugging)

CMD_UNZX0 equ 13
	; followed by a page number and word of a source, and a word of dest
	; unpacked address is assumed to be reachable without switching the banks

CMD_POKE equ 14
	; followed by a page number and an address, then byte value. Just like in BASIC, sets the value

CMD_LDIR equ 15
	; followed by a page number, src address, dest_address, length. Page is turned on before copying

	MACRO Telegron
		db CMD_SHOWIMAGE
		db TELEGRON_SCREEN_PAGE
		dw res_telegron_scr

		db CMD_UNZX0
		db TELEGRON_CODE_PAGE
		dw res_telegron_code_packed
		dw TELEGRON_RUNTIME_ADDRESS

		db CMD_CALL
		db 0
		dw telegron_init

		db CMD_CALL_WITH_PARAMETER
		dw font_to_be_inverted
		db PAGE_FONT
		dw telegron_invert_font

		db CMD_CALL_WITH_PARAMETER
		dw telegron_persistent_state
		db TELEGRON_CODE_PAGE
		dw telegron_print_next_greeting

		db CMD_WAIT_TICK_RELATIVE
		dw 500

		db CMD_CALL_WITH_PARAMETER
		dw font_to_be_inverted
		db PAGE_FONT
		dw telegron_invert_font
	ENDM

slideshow_script_first_start:

	db CMD_RESET_TICKS

	; --- debug only
	if (0)
	db CMD_CALL
	db 0
	dw kernel_init_music

	db CMD_JUMP
	;dw slideshow_script_loop.neko
	;dw slideshow_script_loop.telegron1
	;dw slideshow_script_loop.disco
	;dw slideshow_script_loop.board
	;dw slideshow_script_loop.bolt
	;dw slideshow_script_loop.uvb
	;dw slideshow_script_loop.castle
	;dw slideshow_script_loop.pentium
	;dw slideshow_script_loop.sweets
	dw slideshow_script_loop.transition_test
	;dw slideshow_script_loop.sea
	;dw slideshow_script_loop.cat
	;dw slideshow_script_loop.soda
	;dw slideshow_script_loop.letters
	;dw slideshow_script_loop.rain
	;dw slideshow_script_loop
	;dw slideshow_script_loop.batman
	endif

	; -----------------------------
	; Timer by UriS
	db CMD_SHOWIMAGE
	db GRNTIMER_PAGE
	dw res_grntimer

	db CMD_UNZX0
	db GRNTIMER_PAGE
	dw res_grntimer_code_packed
	dw GRNTIMER_ASSEMBLED_ADDRESS

	db CMD_CALL
	db GRNTIMER_PAGE
	dw grntimer_init

	db CMD_SET_MAINTHREAD_EFFECT
	db GRNTIMER_PAGE
	dw grntimer_tick

	db CMD_WAIT_TICK_RELATIVE
	dw 50

	db CMD_PRINT, 0, 22, $1
	;   01234567890123456789012345678901
	db "Built on ", __DATE__, " at ", __TIME__, 0

	db CMD_PRINT, 0, 22, $1
	;   01234567890123456789012345678901
	db "                                ", 0

	db CMD_WAIT_TICK_RELATIVE
	dw 50

	db CMD_PRINT, 0, 22, $41
	;   01234567890123456789012345678901
	db "Final version", 0

	db CMD_WAIT_TICK_RELATIVE
	dw 5

	db CMD_PRINT, 0, 22, $41
	;   01234567890123456789012345678901
	db "             ", 0

	db CMD_WAIT_TICK_RELATIVE
	dw 95

	db CMD_PRINT, 0, 22, $7
	;   01234567890123456789012345678901
	db "Home use only", 0

	db CMD_WAIT_TICK_RELATIVE
	dw 50

	db CMD_PRINT, 0, 22, $40
	;   01234567890123456789012345678901
	db "                 ", 0

	db CMD_WAIT_TICK_RELATIVE
	dw 150

	db CMD_PRINT, 0, 22, $7
	;   01234567890123456789012345678901
	db "All images are by Grongy", 0

	db CMD_WAIT_TICK_RELATIVE
	dw 50

	db CMD_PRINT, 0, 22, $40
	;   01234567890123456789012345678901
	db "                         ", 0

	db CMD_WAIT_TICK_RELATIVE
	dw 350

	db CMD_CALL
	db 0
	dw kernel_init_music

	db CMD_WAIT_TICK_RELATIVE
	dw 1100

	db CMD_SET_MAINTHREAD_EFFECT
	db 0
	dw 0

slideshow_script_loop:

	db CMD_RESET_TICKS

.sea
	; -----------------------------
	; Sea by UriS
	db CMD_SHOWIMAGE
	db GRNSEA_PAGE
	dw res_grnsea

	db CMD_UNZX0
	db GRNSEA_PAGE
	dw res_grnsea_code_packed
	dw GRNSEA_ASSEMBLED_ADDRESS

	db CMD_CALL
	db GRNSEA_PAGE
	dw grnsea_init

	db CMD_SET_MAINTHREAD_EFFECT
	db GRNSEA_PAGE
	dw grnsea_mainloop

	db CMD_WAIT_TICK_RELATIVE
	dw 500

 	db CMD_PRINT, 55, 8, $42
  	db "Grongy", 0
  	db CMD_WAIT_TICK_RELATIVE
  	dw 10
  	db CMD_PRINT, 55, 8, $42
  	db "Grongy 25", 0

	db CMD_WAIT_TICK_RELATIVE
	dw 750

	db CMD_SET_MAINTHREAD_EFFECT
	db 0
	dw 0

.cat
	; -----------------------------
	; Cat
	db CMD_SHOWIMAGE
	db CAT_SCREEN_PAGE
	dw res_cat_last_phase

	db CMD_UNZX0
	db CAT_PAGE
	dw cat_code_packed
	dw CAT_ASSEMBLED_ADDRESS

	db CMD_SET_MAINTHREAD_EFFECT
	db WORK_AREA_PAGE
	dw cat_mainthread_tick

	db CMD_SET_IM2_EFFECT
	db WORK_AREA_PAGE
	dw cat_im2_tick

	db CMD_WAIT_TICK_RELATIVE
	dw 450

	db CMD_PRINT, 192, 1, $28
	;   01234567890123456789012345678901
	db ">>>>>", 0

	db CMD_WAIT_TICK_RELATIVE
	dw 850

	db CMD_SET_IM2_EFFECT
	db 0
	dw 0

	db CMD_SET_MAINTHREAD_EFFECT
	db 0
	dw 0

	; -----------------------------
	Telegron

.bolt
	; -----------------------------
	; gg_bolt effect by Art-Top
	db CMD_SHOWIMAGE
	db GG_BOLT_PAGE
	dw gg_bolt_scrzx0

	db CMD_UNZX0
	db GG_BOLT_PAGE
	dw gg_bolt.code_packed
	dw gg_bolt.runtime_address

	; (re)init
	db CMD_CALL
	db GG_BOLT_PAGE
	dw gg_bolt.init

	db CMD_SET_IM2_EFFECT
	db GG_BOLT_PAGE
	dw gg_bolt.im2tick

	db CMD_WAIT_TICK_RELATIVE
	dw 1500

	db CMD_SET_IM2_EFFECT
	db 0
	dw 0

.rain
	; -----------------------------
	; Rain by UriS
	db CMD_SHOWIMAGE
	db GRNRAIN_PAGE
	dw res_grnrain

	db CMD_UNZX0
	db GRNRAIN_PAGE
	dw res_grnrain_code_packed
	dw GRNRAIN_ASSEMBLED_ADDRESS

	db CMD_CALL
	db GRNRAIN_PAGE
	dw grnrain_init

	db CMD_SET_MAINTHREAD_EFFECT
	db GRNRAIN_PAGE
	dw grnrain_infinityrain

	db CMD_WAIT_TICK_RELATIVE
	dw 1250

	db CMD_SET_MAINTHREAD_EFFECT
	db 0
	dw 0

	db CMD_CALL
	db GRNRAIN_PAGE
	dw grnrain_remap_to_regular

	; -----------------------------
	Telegron

.soda
	; -----------------------------
	; Soda
	db CMD_SHOWIMAGE
	db 4
	dw res_soda_last_phase

	; little buffer is left after that
.SODA_DATA_ADDR equ WORK_AREA_PREFERRED - 1024

	db CMD_UNZX0
	db 1
	dw res_soda_packed
	dw .SODA_DATA_ADDR

	db CMD_PLAY_DIFFANIM
	db 1
	dw .SODA_DATA_ADDR
	db 32	
	db 3

	db CMD_WAIT_TICK_RELATIVE
	dw 100

	db CMD_PRINT, 112, 16, $78
	;   01234567890123456789012345678901
	db "S", 0

	db CMD_WAIT_TICK_RELATIVE
	dw 100

	db CMD_PRINT, 112, 18, $78
	;   01234567890123456789012345678901
	db "O", 0

	db CMD_WAIT_TICK_RELATIVE
	dw 100

	db CMD_PRINT, 112, 20, $78
	;   01234567890123456789012345678901
	db "D", 0

	db CMD_WAIT_TICK_RELATIVE
	dw 100

	db CMD_PRINT, 112, 22, $78
	;   01234567890123456789012345678901
	db "A", 0

	db CMD_WAIT_TICK_RELATIVE
	dw 450

	; kill the SCA playback
	db CMD_SET_MAINTHREAD_EFFECT
	db 0
	dw 0

	; -----------------------------
	; Soda legend
	db CMD_SHOWIMAGE
	db PAGE_IMAGES
	dw res_soda_legend

	db CMD_WAIT_TICK_RELATIVE
	dw 200

	; -----------------------------
	Telegron

.batman
	; -----------------------------
	; Batman
	db CMD_SHOWIMAGE
	db FLASH_SCREEN_PAGE
	dw res_flash

	; little buffer is left after that
.FLASH_DATA_ADDR equ WORK_AREA_PREFERRED

	db CMD_UNZX0
	db FLASH_ANIM_PAGE
	dw res_flash_packed
	dw .FLASH_DATA_ADDR

	db CMD_PLAY_DIFFANIM
	db 0
	dw .FLASH_DATA_ADDR
	db 25
	db 6

	db CMD_WAIT_TICK_RELATIVE
	dw 300

	db CMD_PRINT, 136, 12, $0f
	;   01234567890123456789012345678901
	db "&U^@&%^&??!", 0

	db CMD_PRINT, 152, 14, $0
	;   01234567890123456789012345678901
	db "@#@&*!!!", 0

	db CMD_WAIT_TICK_RELATIVE
	dw 200

	db CMD_PRINT, 136, 12, $0f
	;   01234567890123456789012345678901
	db "GT^%!EW#!??", 0

	db CMD_PRINT, 152, 14, $0
	;   01234567890123456789012345678901
	db "@@$..!!!", 0

	db CMD_WAIT_TICK_RELATIVE
	dw 200

	db CMD_PRINT, 136, 12, $0f
	;   01234567890123456789012345678901
	db "g2%@", 222, "2? *d", 255, "(?", 0

	db CMD_PRINT, 152, 14, $0
	;   01234567890123456789012345678901
	db "        ", 0

	db CMD_WAIT_TICK_RELATIVE
	dw 200

	db CMD_PRINT, 136, 12, $0f
	;   01234567890123456789012345678901
	db "......       ", 0

	db CMD_WAIT_TICK_RELATIVE
	dw 200

	db CMD_PRINT, 136, 12, $8f
	;   01234567890123456789012345678901
	db "f#$%t", 240, "!..", 0

	db CMD_WAIT_TICK_RELATIVE
	dw 200

	db CMD_PRINT, 136, 12, $0f
	;   01234567890123456789012345678901
	db "         ", 0

	db CMD_WAIT_TICK_RELATIVE
	dw 100

	; kill the SCA playback
	db CMD_SET_MAINTHREAD_EFFECT
	db 0
	dw 0

.letters
	; -----------------------------
	; Letters by Art-Top
	db CMD_SHOWIMAGE
	db GG_LETTERS_PAGE
	dw res_gg_letters_scr

.letters_short_loop
	db CMD_UNZX0
	db GG_LETTERS_PAGE
	dw gg_letters_packed
	dw GG_LETTERS_ASSEMBLED_ADDRESS

;.letters_short_loop
	db CMD_CALL_WITH_PARAMETER
	dw gg_letters_persistent_data
	db GG_LETTERS_PAGE
	dw gg_letters_init

	db CMD_SET_MAINTHREAD_EFFECT
	db GG_LETTERS_PAGE
	dw gg_letters_mainthread

	db CMD_SET_IM2_EFFECT
	db GG_LETTERS_PAGE
	dw gg_letters_interrupt

	db CMD_WAIT_TICK_RELATIVE
	dw 1500

	db CMD_SET_IM2_EFFECT
	db 0
	dw 0

	db CMD_SET_MAINTHREAD_EFFECT
	db 0
	dw 0

;	db CMD_JUMP
;	dw .letters_short_loop

	; -----------------------------
	Telegron

.sweets
	; -----------------------------
	; Sweets by UriS
	db CMD_SHOWIMAGE
	db GRNSWEETS_SCREEN_PAGE
	dw res_emptyscreen

	db CMD_UNZX0
	db GRNSWEETS_CODE_PAGE
	dw res_sweets_code_packed
	dw GRNSWEETS_ASSEMBLED_ADDRESS

	db CMD_CALL
	db GRNSWEETS_CODE_PAGE
	dw grnsweets_init

	db CMD_SET_MAINTHREAD_EFFECT
	db GRNSWEETS_CODE_PAGE
	dw grnsweets_tick

	db CMD_WAIT_TICK_RELATIVE
	dw 550

	db CMD_PRINT, 56, 15, $5f
	;   01234567890123456789012345678901
	db $21, $20, $cc, $ed, $ee, $e3, $ee, $20, $ed, $e8, $f8, $f2, $ff, $ea, $ee, $e2, $20, $21, 0

	db CMD_WAIT_TICK_RELATIVE
	dw 500

	db CMD_SET_IM2_EFFECT
	db 0
	dw 0

	db CMD_SET_MAINTHREAD_EFFECT
	db 0
	dw 0

.pentium
	; -----------------------------
	; Pentium by Moroz1999
	db CMD_SHOWIMAGE
	db PENTIUM_SCREEN_PAGE
	dw res_pentium_screen

	db CMD_UNZX0
	db PENTIUM_PACKED_CODE_PAGE
	dw pentium_code_packed
	dw PENTIUM_RUNTIME_ADDR

	db CMD_CALL
	db 0
	dw pentium_init

	db CMD_SET_MAINTHREAD_EFFECT
	db 0
	dw pentium_tick

	db CMD_WAIT_TICK_RELATIVE
	dw 1250

	db CMD_SET_MAINTHREAD_EFFECT
	db 0
	dw 0

	; -----------------------------
	Telegron

.castle
	; -----------------------------
	; Castle by UriS
	db CMD_SHOWIMAGE
	db CASTLE_SCREEN_PAGE
	dw res_castle_screen

.CASTLE_UNPACKED_ADDR	equ WORK_AREA_PREFERRED
	db CMD_UNZX0
	db CASTLE_BLOCKANIM_PAGE
	dw res_castle_packed
	dw .CASTLE_UNPACKED_ADDR

	db CMD_PLAY_DIFFANIM
	db CASTLE_BLOCKANIM_PAGE
	dw .CASTLE_UNPACKED_ADDR
	db 8
	db 5
	db CMD_WAIT_TICK_RELATIVE
	dw 400

	db CMD_MODIFY_ANIM_SPEED
	db 4
	db CMD_WAIT_TICK_RELATIVE
	dw 300

	db CMD_MODIFY_ANIM_SPEED
	db 3
	db CMD_WAIT_TICK_RELATIVE
	dw 200

	db CMD_MODIFY_ANIM_SPEED
	db 2
	db CMD_WAIT_TICK_RELATIVE
	dw 100

	db CMD_MODIFY_ANIM_SPEED
	db 1
	db CMD_WAIT_TICK_RELATIVE
	dw 100

	db CMD_SET_MAINTHREAD_EFFECT
	db 0
	dw 0

.uvb
	; -----------------------------
	; UVB by Art-Top & Uri
	db CMD_SHOWIMAGE
	db UVB_SCREEN_PAGE
	dw res_uvb_screen

	db CMD_UNZX0
	db UVB_PACKED_CODE_PAGE
	dw res_uvb_code_packed
	dw UVB_RUNTIME_ADDRESS

	db CMD_CALL_WITH_PARAMETER
	dw gg_letters_persistent_data
	db GG_LETTERS_PAGE
	dw gg_uvb_init

	;db CMD_SET_MAINTHREAD_EFFECT
	db CMD_SET_IM2_EFFECT
	db 0
	dw gg_uvb

	db CMD_WAIT_TICK_RELATIVE
	dw 1500

	db CMD_POKE
	db 0
	dw gg_uvb_state
	db 1

	db CMD_WAIT_TICK_RELATIVE
	dw 400

	;db CMD_SET_MAINTHREAD_EFFECT
	db CMD_SET_IM2_EFFECT
	db 0
	dw 0

	; -----------------------------
	Telegron

.board
	; -----------------------------
	; Bulletin board by UriS / sq
	db CMD_SHOWIMAGE
	db BOARD_SCREEN_PAGE
	dw res_board_screen

.BOARD_UNPACKED_ADDR	equ WORK_AREA_PREFERRED
	db CMD_UNZX0
	db BOARD_BLOCKANIM_PAGE
	dw res_board_packed
	dw .BOARD_UNPACKED_ADDR

	db CMD_PLAY_DIFFANIM
	db BOARD_BLOCKANIM_PAGE
	dw .BOARD_UNPACKED_ADDR
	db 33
	db 40

	; disable looping (make a nicer command just for that?)
	db CMD_POKE
	db 0
	dw diffanim_player.anim_loop
	db 0

	db CMD_WAIT_TICK_RELATIVE
	dw 1500

	; re-enable looping (make a nicer command just for that?)
	db CMD_POKE
	db 0
	dw diffanim_player.anim_loop
	db 1

	db CMD_SET_MAINTHREAD_EFFECT
	db 0
	dw 0

.disco
	; -----------------------------
	; Disco by Gogin
.DISCO_SCREEN_TEMP_ADDRESS equ $A000
	; stitch the screen together
	db CMD_LDIR
	db DISCO_SCREEN_FIRST_PAGE
	dw res_disco_scr_part1
	dw .DISCO_SCREEN_TEMP_ADDRESS
	dw res_disco_scr_part1_length

	db CMD_LDIR
	db DISCO_SCREEN_SECOND_PAGE
	dw res_disco_scr_part2
	dw .DISCO_SCREEN_TEMP_ADDRESS+res_disco_scr_part1_length
	dw res_disco_scr_part2_length

	; unpack	
	db CMD_SHOWIMAGE
	db 0
	dw .DISCO_SCREEN_TEMP_ADDRESS

	db CMD_UNZX0
	db DISCO_CODE_PAGE
	dw res_disco_code_packed
	dw DISCO_ASSEMBLED_ADDRESS

	db CMD_CALL
	db 0
	dw disco_init

	;db CMD_SET_IM2_EFFECT
	db CMD_SET_MAINTHREAD_EFFECT
	db 0
	dw disco_tick

	db CMD_WAIT_TICK_RELATIVE
	dw 1500

	;db CMD_SET_IM2_EFFECT
	db CMD_SET_MAINTHREAD_EFFECT
	db 0
	dw 0

.telegron1
	; -----------------------------
	Telegron

	if (0)
	; -----------------------------
	; Telegron
	; unpack	
	db CMD_SHOWIMAGE
	db TELEGRON_SCREEN_PAGE
	dw res_telegron_scr

	db CMD_UNZX0
	db TELEGRON_CODE_PAGE
	dw res_telegron_code_packed
	dw TELEGRON_RUNTIME_ADDRESS

	db CMD_CALL
	db 0
	dw telegron_init

	db CMD_CALL_WITH_PARAMETER
	dw font_to_be_inverted
	db PAGE_FONT
	dw telegron_invert_font

	db CMD_CALL_WITH_PARAMETER
	dw telegron_persistent_state
	db 0
	dw telegron_print_next_greeting

	db CMD_WAIT_TICK_RELATIVE
	dw 150

	db CMD_CALL_WITH_PARAMETER
	dw font_to_be_inverted
	db PAGE_FONT
	dw telegron_invert_font

	db CMD_JUMP
	dw .eternal_scroll
	endif

.neko
	; -----------------------------
	; Neko by Gogin
	db CMD_SHOWIMAGE
	db GRNSWEETS_SCREEN_PAGE
	dw res_emptyscreen

	db CMD_UNZX0
	db NEKO_CODE_PAGE
	dw res_neko_code_packed
	dw NECO_ASSEMBLED_ADDRESS

	db CMD_CALL
	db 0
	dw neko_init

	db CMD_SET_MAINTHREAD_EFFECT
	db 0
	dw neko_tick

	db CMD_WAIT_TICK_RELATIVE
	dw 1000

	db CMD_SET_MAINTHREAD_EFFECT
	db 0
	dw 0

	; -----------------------------
	; restart
	db CMD_LOOP


; ----------------------------------------

; below is test code. TODO: cut it out from the shipping version

.transition_test

	db CMD_SHOWIMAGE
	db CAT_SCREEN_PAGE
	dw res_cat_last_phase

	db CMD_SHOWIMAGE
	db 4
	dw res_flash

	db CMD_SHOWIMAGE
	db 4
	dw res_soda_last_phase

	db CMD_SHOWIMAGE
	db GRNRAIN_PAGE
	dw res_grnrain

	db CMD_SHOWIMAGE
	db PAGE_IMAGES
	dw res_soda_legend

	db CMD_JUMP
	dw .transition_test
