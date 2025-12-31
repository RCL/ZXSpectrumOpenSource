	MODULE zoom_in

; put our shadow attrs there. They track which blocks have been copied
SHADOW_ATTR_AREA	equ WORK_AREA_START + 6144

random_transition:

	ld hl, transition_tab
.pos_in_tab equ $+1
	ld a, 0
	and a
	jr nz, .no_tab_reinit

	; reshuffle tab
	ld b, 64
.rand_loop
		push bc
		call get_random_a
		and $0f
		ld e, a
		ld d, 0
		call get_random_a
		and $0f
		ld c, a
		ld b, 0

		ld hl, transition_tab
		add hl, bc
		ld c, (hl)
		push hl
		ld hl, transition_tab
		add hl, de
		ld e, (hl)
		ld (hl), c
		pop hl
		ld (hl), e
		pop bc
	djnz .rand_loop

	ld a, 16
	ld hl, transition_tab

.no_tab_reinit
	dec a
	ld (.pos_in_tab), a

	ld e, a
	ld d, 0
	add hl, de
	ld a, (hl)

	dec a
	jp z, transition_vert_lines
	dec a
	jp z, transition_zoom_in
	dec a
	jp z, transition_random
	jp transition_random_walk
	; intentional fall-through

; --------------------------------------------------------------------
; Rectangle zoom by LeMIC, with RCL's fixes.
transition_zoom_in:
	call clear_tracking_area

	ld hl, 1 * 256		; h - height in 8.8 fixed point
	ld de, 2*192		; height increment step in fixed point (2*24/32 in 8.8 fixed point)
	ld bc, 16*256 + 1	; b - counter, c - width

rectproy_loop:
	halt
	push bc
	push hl
	push de

	; store current width in bc
	ld b, h		; b - height (ysize), c is already width (xsize)

	; calc screen x,y from width / height
	ld a, 32
	sub c
	sra a
	ld h, a		; h is x, which is (32 - width) / 2

	ld a, 24
	sub b
	sra a
	ld l, a		; l is y, which is (24 - height) / 2

    call rectproy_print_attr_rectangle

	pop de
	pop hl
	pop bc

	inc c		; width += 2
	inc c
	add hl, de	; height += 2 * (24/32)
	djnz rectproy_loop

	; call one last time to cover the whole screen
	ld hl, 0
	ld bc, $1820
	// intentional fall-through

; --------------------------------------------------------------------
; Prints rectangle at HL (H - x, L - y) of BC sizes (B - height, C - width). Note that HL is XY while BC is YX!
rectproy_print_attr_rectangle:
	; calc dest addr in attributes	
	ld e, h
	ld h, 0
	ld d, #58
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, de ; HL - destination address (Y * 32 + X + #5800)

	; shadow attr address from dest
	ld a, h
	add #20		; track shadow attributes
	assert(high WORK_AREA_START == $60)
	ld d, a
	ld e, l

	; width increment
	ld a, #20
	sub c

rectproy_print_attr_rectangle_loop:
	ex af, af'
	push bc

	ex de, hl	; de - dest, hl - source
	ld b, c
	
	// copy attr and bitmap
.loop
	bit 0, (hl)
	jp nz, .skip_block

	push hl
	push de

	call copy_picture_block

	pop de
	pop hl

	set 0, (hl)
.skip_block:
	inc hl
	inc de
	//copy_attr_and_bitmap
	djnz .loop

	ex af, af'
	ld c, a	; b is 0 at this point

	add hl, bc	; incr. source
	ex de, hl
	add hl, bc	; incr. dest

	pop bc
	djnz rectproy_print_attr_rectangle_loop
	ret

;------------------------------------------------------------------------
; copies a picture block
; In: HL - address in shadow attribute area (assumed to be $2000 less than the location of the new picture)
;     DE - address in dest attribute area (assumed to be within $5800-$5aff)
copy_picture_block:
	// copy the attribute
	ld a, h
	add $20
	ld h, a
	// copy the attributes
	ld a, (hl)
	ld (de), a

	// figure out screen addr from attr address
	ld a, h
	and 3
	rlca
	rlca
	rlca
	or $40
	ld d, a
	add $40
	ld h, a

	DUP 7
		ld a, (hl)
		ld (de), a
		inc d
		inc h
	EDUP
	ld a, (hl)
	ld (de), a
	ret

; --------------------------------------------------------------------
; Random copy

transition_random:
	call clear_tracking_area

	ld bc, $ff00	; c tracks number of pixels still unset
.times_to_try
	push bc
	ld de, $5800
	ld hl, SHADOW_ATTR_AREA
.screen_pass
	bit 0, (hl)
	jp nz, .skip_block

	ld c, h			; non-zero c marks that there was an uncopied pixel
	call get_random_a
	ld b, a
	rlca
	and b
	jp nz, .skip_block

	push bc
	push de
	push hl
	call copy_picture_block
	pop hl
	pop de
	pop bc

	set 0, (hl)
.skip_block:
	inc hl
	inc de
	ld a, h
	cp high SHADOW_ATTR_AREA + $3
	jp nz, .screen_pass

	; if we didn't increment c, there were no uncopied pixels
	ld a, c
	pop bc

	and a
	ret z		; we know all pixels were copied, can skip the final ldir

	djnz .times_to_try

	; if we didn't exit earlier, there were still some uncopied pixels -> ldir them
	ld hl, WORK_AREA_PREFERRED
	ld de, $4000
	ld bc, 6912
	ldir
	ret

; --------------------------------------------------------------------
; Random walking square
transition_random_walk:
	call clear_tracking_area

	ld hl, 768
	ld (.pixels_copied), hl

	ld bc, 7680		; max times to walk
	exx

	call get_random_a
	and 31
	ld c, a
	call get_random_a
	and 15
	ld b, a
	call get_random_a
	and 7
	add b
	ld b, a

	; we have BC - random Y, random X
	ld b, 0

.loop:
	; calc address in attributes
	ld a, b
	rrca
	rrca
	rrca
	ld l, a
	and 3
	or $78
	ld h, a
	ld a, l
	and $e0
	or c
	ld l, a

	bit 0, (hl)
	jr nz, .skip_copy

	ld a, h
	sub $20
	ld d, a
	ld e, l

	set 0, (hl)
	push bc
	call copy_picture_block
	pop bc

.pixels_copied equ $+1
	ld hl, 768
	dec hl
	ld (.pixels_copied), hl
	ld a, h
	or l
	ret z	; everything was copied, rush ahead

.skip_copy

	; advance coords
	call get_random_a
	ld e, a
	and 1
	jr nz, .no_inc_X

	ld a, c
	inc a
	and $1f
	ld c, a
	jp .inc_Y

.no_inc_X
	ld a, e
	and 2
	jr nz, .no_dec_X

	ld a, c
	dec a
	and $1f
	ld c, a

.no_dec_X
.inc_Y

	ld a, e
	and 4
	jr nz, .no_inc_Y

	ld a, b
	inc a
	ld b, a
	cp 24
	jp c, .after_increments
	ld b, 0
	jp .after_increments

.no_inc_Y

	ld a, e
	and 8
	jr nz, .no_dec_Y

	ld a, b
	dec a
	ld b, a
	cp 24
	jp c, .after_increments
	ld b, 23

.no_dec_Y
.after_increments

	exx
	dec bc
	ld a, b
	or c
	exx
	jp nz, .loop

	; if we're here, something was not copied
	ld hl, WORK_AREA_PREFERRED
	ld de, $4000
	ld bc, 6912
	ldir
	ret

; --------------------------------------------------------------------
; vertical lines
transition_vert_lines:
	ld hl, WORK_AREA_START-1
	ld a, 32
.loop
	inc hl
	dec a
	ld (hl), a
	jr nz, .loop

	call get_random_a
	and $e0
	jr z, .skip_randomize

	; now randomize them
	ld b, 128
	ld hl, WORK_AREA_START
.rand_loop
		call get_random_a
		and $1f
		ld e, a
		call get_random_a
		and $1f
		ld l, a
		ld c, (hl)
		ld l, e
		ld d, (hl)
		ld (hl), c
		ld l, a
		ld (hl), d
	djnz .rand_loop

.skip_randomize:

	ld b, 32
	ld hl, WORK_AREA_START
.main_copy_loop
		halt
		push bc
		push hl
		ld l, (hl)
		ld h, $78
		ld b, 24
.column_copy_loop:
			push bc
			push hl
			ld e, l
			ld a, h
			sub $20
			ld d, a
			call copy_picture_block
			pop hl
			ld de, 32
			add hl, de
			pop bc
		djnz .column_copy_loop

		pop hl
		pop bc
		inc hl
	djnz .main_copy_loop
	ret

; --------------------------------------------------------------------
; clears tracking area
clear_tracking_area:
	ld hl, SHADOW_ATTR_AREA
	ld de, SHADOW_ATTR_AREA+1
	ld (hl), l
	ld b, 24
.clear_tracking_attr_loop:
	ld c, h		; enough to prevent it from affecting b
	DUP 32
		ldi
	EDUP
	djnz .clear_tracking_attr_loop
	ret

; --------------------------------------------------------------------
; gets random value for A
get_random_a:
	exx
rand_seed equ $+1
        ld      hl, 10569
        ld      a, r
        ld      d, a
        ld      e, (hl)
        add     hl, de
        add     a, l
        xor     h
	ld (rand_seed), hl
	exx
	ret

transition_tab:
	db 1, 1, 2, 2, 3, 3, 4, 4
	db 1, 1, 2, 2, 3, 3, 4, 4


	ENDMODULE