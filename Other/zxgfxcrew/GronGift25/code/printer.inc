; --------------------
; conditional compilation

; --------------------
; Printing routine. Can be called each interrupt. Will init itself if previous execution ended
im2_print:
	;ld a,1
	;ld (im2_command_completed),a
	;ret

	if 0
im2_print_delay_frame equ $+1
	ld a, #10
	dec a
	and #0f
	ld (im2_print_delay_frame), a
	ret nz
	endif

im2_print_inited equ $+1
	ld a,0
	or a
	jr nz, im2_print_already_inited
	
	ld hl, (im2_command_args)
	ld (im2_print_current_char), hl
	ld hl, (im2_command_args + 2)
	ld (im2_print_current_xy), hl

	ld a, 3
	ld (im2_print_phase), a
	inc a
	ld (im2_print_inited), a

im2_print_already_inited:
	; check print phase
im2_print_phase equ $+1
	ld a,0

im2_print_phase3:

	; actual print of the 8-bit symbol
	; get the screen address
im2_print_current_xy equ $+1
	ld hl, 0	; h - x, l - y (x is in pixels)
	
	; refuse to print offscreen
	ld a, l
	cp 23	; since we're printing 8x16
	jp nc, im2_print_skip_character

	srl h
	srl h
	srl h

	ld a,l
	and $18
	or $40
	ld d,a
	ld a,l
	rrca
	rrca
	rrca
	and #e0
	or h
	ld e,a

	; now de - needed screen address
im2_print_current_char equ $+1
	ld hl, 0
	ld a,(hl)
	inc hl
	ld (im2_print_current_char), hl
	or a
	jp z, im2_print_done
	cp 13
	jp z, im2_print_advance_line
	sub 24
	;and $7f
	ld l,a
	ld h,0
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl
	ld bc, font
	add hl, bc

	; now copy the symbol

	; 8x16 fixed size - easy peasy
	DUP 8
		if (1)
			ldi
			dec de
		else
			ld a, (hl)
			cpl
			ld (de), a
			inc hl
		endif
		inc d
	EDUP

    ld a, e
    add $20
    ld e,a
	jr c, .not_in_next_third

    ld a, d
    sub 8
    ld d, a

.not_in_next_third:
	DUP 7
		if (1)
			ldi
			dec de
		else
			ld a, (hl)		
			cpl
			ld (de), a
			inc hl
		endif
		inc d
	EDUP
	if (1)
		ldi
		dec de
	else
		ld a, (hl)		
		cpl
		ld (de), a
		inc hl
	endif

	// set the attributes
	ld a, d
	rra
	rra
	rra
	and 3
	or #58
	ld d, a

	// both this char and above it
im2_print_attribute equ $+1
	ld a, #47	
	ld (de), a
	ld hl, -32
	add hl, de
	ld (hl), a

im2_print_skip_character
	; now advance just by a char
	ld hl,(im2_print_current_xy)
im2_print_char_pixel_x_advance equ $+1
	ld a, 8
	add h
	ld h,a
	jr nc, im2_print_advance_common	; carry will be set if we're over 256
	; intentional fallthrough

im2_print_advance_line:
	ld hl,(im2_print_current_xy)
	inc l
	inc l
	; wrap l if above 23
	ld a, l
	cp 23
	jr c, .no_wrap
	ld l, 0
.no_wrap
	ld h,0

im2_print_advance_common:
	ld (im2_print_current_xy), hl
	ld a, 3
	ld (im2_print_phase), a

	ret
	
im2_print_done:
im2_command_completed:	; should be fine to set im2_print_inited here
	xor a	
	ld (im2_print_inited), a
	ld (im2_command_to_exec), a
	inc a
	ld (im2_command_complete), a
	ret

