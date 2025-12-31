	DEVICE ZXSPECTRUM48
; This is a self-contained code, not intended to be compiled as part of the main program


register_default_b equ 255
register_default_c equ 15
register_default_d equ 7
register_default_e equ 3

	ORG $6000
effect_start:
	jp main_thread_tick
	jp interrupt_tick

	; main thread tick
main_thread_tick:
	halt

	if (0)
.once equ $+1
	ld a, 0
	and a
	jr nz, .skip
	inc a
	ld (.once), a

	ld hl, $59e0
	ld de, $59e1
	ld bc, 9*32-1
	ld (hl), $38
	ldir

.skip
	endif

.delay equ $+1
	ld a, 7
	dec a
.cat_period equ $+1
	and 7
	ld (.delay), a
	ret nz


.cur_sprite equ $+1
	ld hl,cat_betonka_sprites_tbl
	ld bc, cat_betonka_sprites_end
	or a
	sbc hl, bc
	add hl, bc
	jr c, .no_sprite_loop

	ld hl, cat_betonka_sprites_tbl
.no_sprite_loop:

	ld e, (hl)
	inc hl
	ld d, (hl)
	inc hl

	ld (.cur_sprite), hl

	ex de, hl
	
	ld d,register_default_d
	ld e,register_default_e
	ld b,register_default_b
	ld c,register_default_c

	xor a
	jp (hl)

cat_betonka_sprites_tbl
	dw label_spr_cat_betonka1
	dw label_spr_cat_betonka2
	dw label_spr_cat_betonka3
	dw label_spr_cat_betonka4
	dw label_spr_cat_betonka5
	dw label_spr_cat_betonka6
	dw label_spr_cat_betonka7
	dw label_spr_cat_betonka8
cat_betonka_sprites_end
cat_betonka_sprites_cnt equ 8

	include "_cat_betonka_sprites.a80"

	; interrupt code ticking
interrupt_tick:

.cooldown_timer equ $+1
	ld a, 0
	and a
	jr z, .no_cool_down

	dec a
	ld (.cooldown_timer), a
	jr .no_key_pressed

.no_cool_down
	xor a
	in a, ($fe)
	and $1f
	cp $1f
	jr z, .no_key_pressed

	; a key is pressed
	ld a, (interrupt_tick.fence_delay)
	xor 7
	ld (interrupt_tick.fence_delay), a

	ld a, (main_thread_tick.cat_period)
	xor 7
	ld (main_thread_tick.cat_period), a

	; reset the cooldown timer
	ld a, $0f
	ld (.cooldown_timer), a

.no_key_pressed:

.delay equ $+1
	ld a, 0
	dec a
.fence_delay equ $+1
	and 7
	ld (.delay), a
	ret nz

	MACRO POP8
		pop hl
		pop de
		pop bc
		pop af
		exx
		ex af, af'
		pop hl
		pop de
		pop bc
		pop af
	ENDM

	MACRO PUSH8
		push af
		push bc
		push de
		push hl
		ex af, af'
		exx
		push af
		push bc
		push de
		push hl
	ENDM

	ld (save_sp), sp

	; scroll the attributes first, so they have a chance to outrun the ray
	ld ixl, 9
	ld hl,#59e1
attr_loop:
	ld (.next_line), hl
	ld sp, hl

	POP8

	ld (.next_sp), sp
	dec sp

	PUSH8

.next_sp equ $+1
	ld sp, 0

	POP8	
	dec sp
	ld (.dest_addr), sp
	PUSH8

.dest_addr equ $+1
	ld de, 0
	dec de

.next_line equ $+1
	ld hl, 0
	ldi
	;ld a, (hl)
	;ld (de), a
	ex de, hl
	;inc hl
	inc l	; here we should be already within the scanline

	dec ixl
	jp nz, attr_loop

	; scroll the bitmap, should outrun the ray
	ld ixl, 10 * 8
	ld hl,#48c1
bitmap_loop
	ld (.next_line), hl
	ld sp, hl

	POP8
	ld (.next_sp), sp
	dec sp
	PUSH8

.next_sp equ $+1
	ld sp, 0

	POP8			
	dec sp
	ld (.dest_addr), sp
	PUSH8

.dest_addr equ $+1
	ld de, 0
	dec de

.next_line equ $+1
	ld hl, 0
	ld a, (hl)
	ld (de), a

	MACRO NextScanline	RegH, RegL
		inc RegH
		ld a, RegH
		and 7
		jp nz, .Done

		ld a, RegL
		add 32
		ld RegL, a
		jp c, .Done

		ld a, RegH
		sub 8
		ld RegH, a
.Done
	ENDM

	NextScanline H, L
	dec ixl
	jp nz, bitmap_loop

save_sp equ $+1
	ld sp, 0

	ret


	assert( $ < $be00 )
	SAVEBIN "cat_betonka_print.bin", effect_start, $-effect_start