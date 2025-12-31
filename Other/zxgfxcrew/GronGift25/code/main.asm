	device ZXSPECTRUM128

; --------------------
; conditional compilation

; show border bars for the IM2 code duration
PROFILE_IM2_CODE		equ 0
PROFILE_MAINTHREAD_CODE	equ 0

; where our working area starts
WORK_AREA_START		equ $6000
; preferential address to work with (fast RAM)
WORK_AREA_PREFERRED equ $8000
; page - no reason to have it other than 0, but still, for clarity of script code
WORK_AREA_PAGE equ 0
; --------------------
; special kernel pages

; page where the remainder of kernel resources (most crucially, script), is located.
; expected to be paged in most of the time during the kernel code
PAGE_HIGH_KERNEL_RESOURCES	EQU 7

; page where the music player and music track is expected to be found
PAGE_MUSIC			EQU 0

; --------------------
; the below defines are specific to the project
PAGE_IMAGES			EQU 4

	org #5B00
kernel_start:
kernel_main_thread_code_start:
	; entry point table
	jp actual_start
	jp print_text_on_im2

actual_start:
	di
	ld de, IM2Table	; to avoid contended memory, put the interrupt table after $8000 but before the block0_overflow starting address, which is $9e32
	ld hl, (high SpaceForIM2Jump) * 256 + (high SpaceForIM2Jump)
	ld sp, top_of_the_stack
	ld a,d
	ld i,a
	ld a,h

fill_im2:
	ld (de),a
	inc e
	jr nz, fill_im2
	inc d
	ld (de),a

	ld (hl),#c3
	inc l
	ld (hl),low im2_handler
	inc l
	ld (hl),high im2_handler
	im 2
	ei

	xor a
	out (#fe), a

	; will be initialized from the script
	;call kernel_init_music

	; we expect to have PAGE_HIGH_KERNEL_RESOURCES paged in at all times. Effects should page theirs and back
	ld a, PAGE_HIGH_KERNEL_RESOURCES
	call bank_switch_push

    ld hl, slideshow_script_first_start
	jr script_loop

restart_script_loop:
	;call kernel_init_music
	ld hl, 0
	di
	ld (active_im2_effect_ptr), hl
	ei
	ld (active_mainthread_effect_ptr), hl

	ld hl, slideshow_script_loop
script_loop:
	ld a,(hl)
	inc hl
	or a ; SCRIPT_LOOP
	jr z, restart_script_loop

	dec a
	jp z, script_print

	dec a
	jp z, script_showimg

	dec a
	jp z, cmd_wait_timer

	dec a
	jp z, cmd_wait_timer_relative

	dec a
	jr z, cmd_reset_ticks

	dec a
	jr z, cmd_set_mainthread_effect

	dec a
	jr z, cmd_set_im2_effect

	dec a
	jp z, cmd_call

	dec a
	jp z, cmd_call_with_param

	dec a
	jp z, cmd_play_diffanim

	dec a
	jp z, cmd_modify_anim_speed

	dec a
	jp z, cmd_jump

	dec a
	jp z, cmd_unzx0

	dec a
	jr z, cmd_poke

	dec a
	jr z, cmd_ldir

	; unsupported command
	jr script_loop

cmd_reset_ticks:
	di
	ld de, 0
	ld (global_frame_counter), de
	ld (last_frame_waited_for), de
	ei
	jr script_loop

cmd_set_mainthread_effect:
	ld a, (hl)
	inc hl
	ld (active_mainthread_effect_page), a
	ld e, (hl)
	inc hl
	ld d, (hl)
	inc hl
	ld (active_mainthread_effect_ptr), de
	jr script_loop

cmd_set_im2_effect:
	ld a, (hl)
	inc hl
	ld e, (hl)
	inc hl
	ld d, (hl)
	inc hl
	di
	ld (active_im2_effect_page), a
	ld (active_im2_effect_ptr), de
	ei
	jr script_loop

cmd_poke:
	ld a, (hl)
	inc hl
	ld e, (hl)
	inc hl
	ld d, (hl)
	inc hl
	ex af, af'
	ld a, (hl)
	inc hl
	ex af, af'
	call bank_switch_push
	ex af, af
	ld (de), a
	call bank_switch_pop
	jp script_loop

cmd_wait_timer:
	ld e, (hl)
	inc hl
	ld d, (hl)
	inc hl

	ld (last_frame_waited_for), de
	; intentional passthrough

wait_for_de_frame:
	push hl
cmd_wait_timer_loop:
		push de
		call run_mainthread_effect
		pop de

		; check if space is pressed
		ld a, $7f
		in a, ($fe)
		and $01
		jr z, .space_pressed

		ld hl, (global_frame_counter)
		or a
		sbc hl, de
		jr c, cmd_wait_timer_loop

.space_pressed
		if (0)	// not waiting here allows to speedrun the demo, which IMO works better
		; wait for the user to release space
		ld a, $7f
		in a, ($fe)
		and $01
		jr z, .space_pressed
		endif

	pop hl
	jp script_loop

cmd_wait_timer_relative:
	ld e, (hl)
	inc hl
	ld d, (hl)
	inc hl

	push hl
	ld hl, (last_frame_waited_for)
	add hl, de
	ld (last_frame_waited_for), hl
	ex de, hl
	pop hl
	jr wait_for_de_frame

cmd_ldir:
	ld a, (hl)
	inc hl
	; source
	ld e, (hl)
	inc hl
	ld d, (hl)
	inc hl
	push de

	; dest
	ld e, (hl)
	inc hl
	ld d, (hl)
	inc hl

	ld c, (hl)
	inc hl
	ld b, (hl)
	inc hl

	push bc
	call bank_switch_push
	pop bc

	ex (sp), hl
	ldir

	pop hl
	call bank_switch_pop
	jp script_loop

cmd_call_with_param:
	ld e, (hl)
	inc hl
	ld d, (hl)
	inc hl
	; intentioanl fall-through

cmd_call:
	ld a, (hl)
	inc hl
	ld c, (hl)
	inc hl
	ld b, (hl)
	inc hl
	ld (.call_addr), bc

	push hl
	call bank_switch_push	; will keep BC and HL intact
.call_addr equ $+1
	call $0
	call bank_switch_pop
	pop hl
	jp script_loop

cmd_modify_anim_speed
	ld a, (hl)
	inc hl
	ld (diffanim_player.anim_frame_delay), a
	jp script_loop

cmd_play_diffanim:
	ld a, (hl)
	inc hl
	ld (diffanim_player.anim_page), a

	ld e,(hl)
	inc hl
	ld d,(hl)
	inc hl
	ld (diffanim_player.data_start_addr), de
	ld (diffanim_player.data_current_addr), de

	ld a, (hl)
	inc hl
	ld (diffanim_player.anim_num_frames), a

	ld a, (hl)
	inc hl
	ld (diffanim_player.anim_frame_delay), a

	xor a
	ld (diffanim_player.anim_cur_frame), a
	ld (active_mainthread_effect_page), a
	inc a
	ld (diffanim_player.anim_cur_delay), a

	ld de, diffanim_player
	ld (active_mainthread_effect_ptr), de
	jp script_loop	

cmd_jump:
	ld e, (hl)
	inc hl
	ld d, (hl)
	ex de, hl
	jp script_loop

script_showimg:
	ld a, (hl)
	inc hl

	; get the picture address
	ld e,(hl)
	inc hl
	ld d,(hl)
	inc hl

	call bank_switch_push

	push hl
	ex de, hl
	ld de, WORK_AREA_PREFERRED
	call dzx0_fast
	call bank_switch_pop
	call drcs.drcs_onscreen

	call zoom_in.random_transition

	pop hl
	jp script_loop

cmd_unzx0:
	ld a, (hl)
	inc hl

	; get the source address
	ld c, (hl)
	inc hl
	ld b, (hl)
	inc hl

	; get the dest address
	ld e,(hl)
	inc hl
	ld d,(hl)
	inc hl
	
	push hl
	ld h, b
	ld l, c

	call bank_switch_push
	call dzx0_fast
	call bank_switch_pop
	pop hl
	jp script_loop

script_print:
    ; fetch x and y
	ld d, (hl)
	inc hl
	ld e, (hl)
	inc hl

	; get attribute value
	ld a, (hl)
	inc hl
	and a
	jr nz, .do_not_reload_attr

	ld a, (im2_print_attribute)

.do_not_reload_attr

	; schedule the text to be printed by the IM2 printer
	call print_text_on_im2

	; advance hl past the string
skip_text:
	ld a,(hl)
	inc hl
	or a
	jr nz, skip_text

	jp script_loop

; Prints text and calls effect while waiting
;  expects:
;    DE - coords
;    HL - text
;    A - color
print_text_on_im2
	push af
	ld a, PAGE_HIGH_KERNEL_RESOURCES
	call bank_switch_push
	pop af
	ld (im2_command_args+2), de
	ld (im2_print_attribute), a
	ld (im2_command_args), hl
	ld a, IM2_COMMAND_PRINT
	call schedule_and_wait_for_im2_command
	jp bank_switch_pop

; --------------------------------------------------------------------
; Switches the bank (with a history)
; Transhes BC only
; Can be called from both interrupt and non_interrupt code
; Main thread version needs to disable the interrupts, and needs to do it in as small window as possible
; to avoid missing one.
; --------------------------------------------------------------------
bank_switch_push:

.implementation equ $+1
	jp .main_thread_version 

	block 4		; padding to make main_thread_ver and im2 ver be within the same 256 page

; called on the main thread, needs to minimize code within disabled interrupt scope
.main_thread_version
	di
	ld bc, (bank_stack_head)
	inc bc
	ld (bank_stack_head), bc
	ei

	jr .common_path

; IM2 handler will reroute the calls here, so DI is assumed
.im2_version:
	ld bc, (bank_stack_head)
	inc bc
	ld (bank_stack_head), bc

.common_path:
	; todo: check overflow
	ld (bc), a

	; preserve shadow screen
	and $7
	ld b, a
	ld a, (status_shadow_screen_48k_rom)
	or b

	ld bc, #7ffd
	out (c), a
	ret

; --------------------------------------------------------------------
; Restores the bank (from the history)
; Transhes BC only
; Can be called from both interrupt and non_interrupt code
; Main thread version needs to disable the interrupts, and needs to do it in as small window as possible
; to avoid missing one.
; --------------------------------------------------------------------
bank_switch_pop:

.implementation equ $+1
	jp .main_thread_version

; called on the main thread, needs to minimize code within disabled interrupt scope
.main_thread_version:
	di
	ld bc, (bank_stack_head)
	dec bc
	ld (bank_stack_head), bc
	ei

	jr .common_path

; IM2 handler will reroute the calls here, so DI is assumed
.im2_version:
	ld bc, (bank_stack_head)
	dec bc
	ld (bank_stack_head), bc

.common_path:
	; todo: check overflow
	ld a, (bc)

	; preserve shadow screen
	and $7
	ld b, a
	ld a, (status_shadow_screen_48k_rom)
	or b

	ld bc, #7ffd
	out (c), a
	ret

bank_stack_head
	dw bank_stack

bank_stack
	block 16

; --------------------------------------------------------------------
; a - the command. Command arguments are supposed to be already set up
schedule_and_wait_for_im2_command:
	; debugging code - first check that no active commmand is running
	ex af, af'
	ld a, (im2_command_complete)
	or a
	jr nz, no_active_command
	; lock up here so we can debug this
	di
	halt
	; unreachable
no_active_command:
	; reset the completion - for safety do it first (could also disbale the interrupts, but don't want to mess with the music)
	xor a
	ld (im2_command_complete), a	
	ex af, af'
	ld (im2_command_to_exec), a


wait_for_im2_command:
	ld a, (im2_command_complete)
	or a
	ret nz
	push hl
	call run_mainthread_effect
	pop hl
	jr wait_for_im2_command

; --------------------------------------------------------------------
; Runs mainthread effect if any - no synch with vblank, this is left to the effect itself

run_mainthread_effect:
active_mainthread_effect_ptr equ $+1
	ld hl, 0
	ld a, h
	or l
	ret z

active_mainthread_effect_page equ $+1
	ld a, 0
	call bank_switch_push
	if (!PROFILE_MAINTHREAD_CODE)
		ld de, bank_switch_pop
		push de

		jp (hl)
	else
		ld a, 4
		out ($fe), a
		ld (.call_addr), hl
.call_addr equ $+1
		call 0
		ld a, 5
		out ($fe), a
		jp bank_switch_pop
	endif

; --------------------------------------------------------------------
; Differential animation player
diffanim_player:
.anim_cur_delay equ $+1
	ld a, 0
	dec a
	ld (.anim_cur_delay), a
	jr z, .show_frame
	halt
	ret

.show_frame:
.anim_frame_delay equ $+1
	ld a, 0
	ld (.anim_cur_delay), a

.anim_page equ $+1
	ld a, 0
	call bank_switch_push

	// data ptr
.data_current_addr equ $+1
	ld hl, 0

.frame_decode_loop
	ld e, (hl)
	inc hl
	ld d, (hl)
	inc hl
	ld a, d
	or e
	jr z, .done_decoding_anim

	ldi		// copy the attribute
	dec de

	; convert attrib addr to screen
	; // fixme: put into a table
	ld a, d
	and 3
	rlca
	rlca
	rlca
	or $40
	ld d, a

	DUP 7
		ldi
		inc d
		dec de
	EDUP
	ldi
	jp .frame_decode_loop

.done_decoding_anim
	// we come here with hl pointing at the data
	ld (.data_current_addr), hl

.anim_cur_frame equ $+1	
	ld a, 0
	inc a
.anim_num_frames equ $+1
	cp 0
	jr c, .no_reinit_anim

; decide whether to loop or not
.anim_loop equ $+1
	ld a, 1
	and a
	jr nz, .restart_anim

	// disable ourselves
	ld h, a
	ld l, a
	ld (active_mainthread_effect_ptr), hl
	jr .exit

.restart_anim
	xor a
.data_start_addr equ $+1
	ld hl, 0
	ld (.data_current_addr), hl
	xor a
.no_reinit_anim
	ld (.anim_cur_frame), a

.exit:
	jp bank_switch_pop

; --------------------------------------------------------------------
; Kernel part of music init
; Disables the interrupts (and music switch) while doing this, so
; it is only supposed to be called on the main thread.

kernel_init_music:
	di
	ld a, PAGE_MUSIC
	call bank_switch_push
	call overlay_music_init
	call bank_switch_pop
	ei
	ret	

; --------------------------------------------------------------------
; ZX0 depacker - important enough to be in the kernel
zx0_depack:
	include "zx0/dzx0_fast.asm"

KERNEL_MAIN_THREAD_CODE_SIZE EQU $ - kernel_main_thread_code_start

kernel_im2_code_start:
im2_handler:
	di
	push af
	push bc
	push de
	push hl
	push ix
	push iy
	exx
	ex af,af'
	push af
	push bc
	push de
	push hl

	assert( high bank_switch_push.im2_version == high bank_switch_push.main_thread_version )
	ld a, low bank_switch_push.im2_version
	ld (bank_switch_push.implementation), a

	assert( high bank_switch_pop.im2_version == high bank_switch_pop.main_thread_version )
	ld a, low bank_switch_pop.im2_version
	ld (bank_switch_pop.implementation), a

	; -----------------------------------------------------------------------------
	; Frame update (not measured)

.global_frame_counter equ $+1
	ld hl, 0
	inc hl
	ld (.global_frame_counter), hl

	; -----------------------------------------------------------------------------
	; First, execute IM2 commands, if any

	if PROFILE_IM2_CODE
		; measure IM2 command execution (blue)
		ld a, 1
		out (#fe), a
	endif

	; execute effect if any
.active_im2_effect_ptr equ $+1
	ld hl, 0
	ld a, h
	or l
	jr z, .no_im2_effect
.active_im2_effect_page equ $+1
	ld a, PAGE_HIGH_KERNEL_RESOURCES
	call bank_switch_push

	ld de, .after_im2_effect
	push de
	jp (hl)

.after_im2_effect:
	call bank_switch_pop

.no_im2_effect
	; IM2 code expecs to find its resources here
	ld a, PAGE_HIGH_KERNEL_RESOURCES
	call bank_switch_push

	; atm only supporting print command
im2_command_to_exec equ $+1
	ld a,0
	or a
	call nz, im2_print

im2_play_music:

	; -----------------------------------------------------------------------------
	; Music replay

	if PROFILE_IM2_CODE
		; measure music replay (red)
		ld a, 2
		out (#fe), a
	endif

	ld a, PAGE_MUSIC
	call bank_switch_push
	call overlay_music_play	; one of pt3 player entry points
	call bank_switch_pop

	if PROFILE_IM2_CODE
		; measure attribute effect execution (magenta)
		ld a, 3
		out (#fe), a
	endif

	if PROFILE_IM2_CODE
		; end of frame - black
		xor a
		out (#fe), a
	endif

	call bank_switch_pop

	assert( high bank_switch_push.im2_version == high bank_switch_push.main_thread_version )
	ld a, low bank_switch_push.main_thread_version
	ld (bank_switch_push.implementation), a

	assert( high bank_switch_pop.im2_version == high bank_switch_pop.main_thread_version )
	ld a, low bank_switch_pop.main_thread_version
	ld (bank_switch_pop.implementation), a

	pop hl
	pop de
	pop bc
	pop af
	ex af,af'
	exx
	pop iy
	pop ix
	pop hl
	pop de
	pop bc
	pop af	
		
	ei
	reti

; This memory is used to request the handler do something.
; Command parameters are supposed to be written first, then the command, after which the client code can loop waiting for the completion

; does "3D" printing of the text
IM2_COMMAND_PRINT equ 1

im2_command_args:
	dw 0
	dw 0

im2_command_complete:
	db 1		; must be set to 1 when no active command is running

status_shadow_screen_48k_rom
	db $10		; 48K ROM

; provide global aliases for convenience
global_frame_counter equ im2_handler.global_frame_counter
active_im2_effect_ptr equ im2_handler.active_im2_effect_ptr
active_im2_effect_page equ im2_handler.active_im2_effect_page

KERNEL_IM2_CODE_SIZE EQU $ - kernel_im2_code_start


bss_start:

; last frame we waited for
last_frame_waited_for:
	dw 0

; if 1, we're inside the interrupt handler
interrupt_handler_active:
	db 0

bss_end:

IM2Table 			equ $be00
SpaceForIM2Jump 		equ $bf01

bottom_of_the_stack equ $bf02
top_of_the_stack equ $bfbe
	assert(top_of_the_stack - bottom_of_the_stack >= 128)

KERNEL_SIZE = $ - kernel_start
FIRST_AVAILABLE_ADDRESS EQU $
	assert (FIRST_AVAILABLE_ADDRESS < $6000)
LAST_AVAILABLE_ADDRESS EQU IM2Table-1

	SAVEBIN "../output/kernel.bin", kernel_start, KERNEL_SIZE

	DISPLAY "---- Kernel memory breakdown ----"
	DISPLAY "Kernel starts at ", kernel_start, " and takes ", /A, KERNEL_SIZE, " bytes."
	DISPLAY "    Of which, main thread code takes ", /A, KERNEL_MAIN_THREAD_CODE_SIZE, " bytes,"
	DISPLAY "    interrupt code takes ", /A, KERNEL_IM2_CODE_SIZE, " bytes,"
	DISPLAY "Stack takes ", /A, top_of_the_stack - bottom_of_the_stack, " bytes (top of the stck is at ", /A, top_of_the_stack, ")"
	DISPLAY "First available address for the effects is ", /A, FIRST_AVAILABLE_ADDRESS
	DISPLAY "Last available address for the effect is ", /A, LAST_AVAILABLE_ADDRESS
	DISPLAY "Maximum continuous effect size is ", /A, LAST_AVAILABLE_ADDRESS - FIRST_AVAILABLE_ADDRESS + 1
	DISPLAY "---------------------------------"

	// pages
	include "page0.asm"
	include "page1.asm"
	include "page3.asm"
	include "page4.asm"
	include "page6.asm"
	include "page7.asm"

	DISPLAY "---- Page memory breakdown ----"
	DISPLAY "Page0 takes ", /A, PAGE0_SIZE, " bytes, free: ", /A, 16384 - PAGE0_SIZE, " bytes."
	DISPLAY "Page1 takes ", /A, PAGE1_SIZE, " bytes, free: ", /A, 16384 - PAGE1_SIZE, " bytes."
	DISPLAY "Page3 takes ", /A, PAGE3_SIZE, " bytes, free: ", /A, 16384 - PAGE3_SIZE, " bytes."
	DISPLAY "Page4 takes ", /A, PAGE4_SIZE, " bytes, free: ", /A, 16384 - PAGE4_SIZE, " bytes."
	DISPLAY "Page6 takes ", /A, PAGE6_SIZE, " bytes, free: ", /A, 16384 - PAGE6_SIZE, " bytes."
	DISPLAY "Page7 takes ", /A, PAGE7_SIZE, " bytes, free: ", /A, 16384 - PAGE7_SIZE - 6912, " bytes (considering second screen use)."
	DISPLAY "---------------------------------"

	SAVESNA "../output/grongift.sna", #5B00
