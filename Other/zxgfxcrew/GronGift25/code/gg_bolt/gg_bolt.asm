	device ZXSPECTRUM48
	org $8000

effect_start
	; init
	jp gg_bolt_init
	; IM2
	jp gg_bolt

gg_bolt
_gg_flash_blink_sector equ $+1
	jp gg_flash_blink_state_1


gg_flash_blink_state_1
_gg_flash_cnt1 equ $+1
	ld a,17
	dec a
	ld (_gg_flash_cnt1),a
	dec a
	ret nz
_gg_flash_cnt1_1 equ $+1
	ld a,16
	ld (_gg_flash_cnt1),a
	ld hl,gg_flash_blink_state_2
gg_flash_blink_state_1_1
	ld (_gg_flash_blink_sector),hl
	ret

gg_flash_blink_state_2
	ld hl,gg_atr2
	ld de,#5800+5*32+14
	ld bc,561
	ldir
	ld hl,gg_flash_blink_state_3
	jr gg_flash_blink_state_1_1

gg_flash_blink_state_3
_gg_flash_cnt2 equ $+1
	ld a,17
	dec a
	ld (_gg_flash_cnt2),a
	dec a
	ret nz
_gg_flash_cnt2_2 equ $+1
	ld a,16
	ld (_gg_flash_cnt2),a
	ld hl,gg_flash_blink_state_4
	jr gg_flash_blink_state_1_1

gg_flash_blink_state_4
	ld hl,gg_atr1
	ld de,#5800+5*32+14
	ld bc,561
	ldir
	ld hl,_gg_flash_cnt1_1
	ld a,(hl)
	dec a
	jr z,gg_flash_blink_exit	// exit in max blink speed
	ld (hl),a
	ld (_gg_flash_cnt2_2),a
	ld hl,gg_flash_blink_state_1
	jr gg_flash_blink_state_1_1

gg_flash_blink_exit
	ld hl,gg_bolt_effect
	jr gg_flash_blink_state_1_1



gg_bolt_phases
	db %1111'1110, %0000'0000, %0000'0000, %0011'1111, %1111'1111	// 09
	db %1111'1100, %0000'0000, %0000'0000, %0111'1111, %1111'1110	// 08
	db %1111'0000, %0000'0000, %0000'0000, %1111'1111, %1111'1110	// 07
	db %0011'1111, %1111'1111, %1111'1000, %0000'0000, %0000'0011	// 06
	db %0011'1111, %1111'1111, %1110'0000, %0000'0000, %0000'0011	// 05
	db %0111'1111, %1111'1111, %1000'0000, %0000'0000, %0000'1111	// 04
	db %1111'1111, %1111'1111, %0000'0000, %0000'0000, %0001'1111	// 03
	db %1111'1111, %1111'1000, %0000'0000, %0000'0000, %0011'1111	// 02
	db %1111'1111, %1110'0000, %0000'0000, %0000'0000, %1111'1111	// 01
	db %1111'1111, %1100'0000, %0000'0000, %0000'0011, %1111'1111	// 00
gg_bolt_phases_end

gg_bolt_phases_atr
	db %01'101'111, %01'101'101, %01'101'101, %01'101'001, %01'001'001	// 09
	db %01'101'111, %01'101'101, %01'101'101, %01'101'001, %01'000'001	// 08
	db %01'101'111, %01'101'101, %01'101'101, %01'001'001, %01'000'001	// 07
	db %01'000'111, %01'111'111, %01'001'111, %01'001'001, %01'001'000	// 06
	db %01'000'111, %01'111'111, %01'001'111, %01'001'001, %01'001'000	// 05
	db %01'000'111, %01'111'111, %00'101'111, %00'101'101, %00'101'001	// 04
	db %01'111'111, %01'111'111, %00'101'101, %00'101'101, %00'101'001	// 03
	db %01'111'111, %01'101'111, %01'101'101, %01'101'101, %01'101'001	// 02
	db %01'111'111, %01'101'111, %01'101'101, %01'101'101, %01'001'001	// 01
	db %01'111'111, %01'101'111, %01'101'101, %01'101'001, %01'001'001	// 00
gg_bolt_phases_atr_end

gg_bolt_fon_phases_table
	dw gg_bolt_fon_phase_00
	dw gg_bolt_fon_phase_01
	dw gg_bolt_fon_phase_02
	dw gg_bolt_fon_phase_03
	dw gg_bolt_fon_phase_04
	dw gg_bolt_fon_phase_05
	dw gg_bolt_fon_phase_06
	dw gg_bolt_fon_phase_07
	dw gg_bolt_fon_phase_08
	dw gg_bolt_fon_phase_09
	dw gg_bolt_fon_phase_10
	dw gg_bolt_fon_phase_11
	dw gg_bolt_fon_phase_12
	dw gg_bolt_fon_phase_13
	dw gg_bolt_fon_phase_14
	dw gg_bolt_fon_phase_15
	dw gg_bolt_fon_phase_16
	dw gg_bolt_fon_phase_17
	dw gg_bolt_fon_phase_18
	dw gg_bolt_fon_phase_19
	dw gg_bolt_fon_phase_20
	dw gg_bolt_fon_phase_21
	dw gg_bolt_fon_phase_22
	dw gg_bolt_fon_phase_23
	dw gg_bolt_fon_phase_24
	dw gg_bolt_fon_phase_25
	dw gg_bolt_fon_phase_26
	dw gg_bolt_fon_phase_27
	dw gg_bolt_fon_phase_28
	dw gg_bolt_fon_phase_29
	dw gg_bolt_fon_phase_30
	dw gg_bolt_fon_phase_31
	dw gg_bolt_fon_phase_32
	dw gg_bolt_fon_phase_33
	dw gg_bolt_fon_phase_34
	dw gg_bolt_fon_phase_35
	dw gg_bolt_fon_phase_36
	dw gg_bolt_fon_phase_37
	dw gg_bolt_fon_phase_38
	dw gg_bolt_fon_phase_39
gg_bolt_fon_phases_table_end



gg_bolt_jump_table
	dw #5770, #5770, #5770, #5770
	dw #5090, #5090, #5090, #5090
	dw #5190, #5190, #5190
	dw #5290, #5290, #5290
	dw #5390, #5390
	dw #5490, #5490
	dw #5590
	dw #5690

	dw #5690
	dw #5590
	dw #5490, #5490
	dw #5390, #5390
	dw #5290, #5290, #5290
	dw #5190, #5190, #5190
	dw #5090, #5090, #5090, #5090
	dw #5770, #5770, #5770, #5770
gg_bolt_jump_table_end

gg_bolt_effect

gg_bolt_fon_loop
// ld a,1
// out(#fe),a

 	// out fon
	// upper 8 strings
	ld hl,gg_bolt_phases_ret1
	exx
_gg_bolt_fon_current_phase equ $+2
	ld ix,gg_bolt_fon_phase_27
	ld hl,#40c0+32
	ld (_gg_bolt_sp),sp
gg_bolt_fon_loop0
	ld sp,hl
	exx
	jp (ix)
gg_bolt_phases_ret1
	exx
	inc h
	ld a,h
	cp #48
	jp nz,gg_bolt_fon_loop0

	// bolt header
_gg_bolt_current_phase_1 equ $+1
 	ld hl,gg_bolt_phases
	ld c,(hl)
  if high(gg_bolt_phases) == high(gg_bolt_phases_end-1)
	inc l
	ld d,(hl)
	inc l
	ld e,(hl)
	inc l
	ld a,(hl)
	inc l
  else
	inc hl
	ld d,(hl)
	inc hl
	ld e,(hl)
	inc hl
	ld a,(hl)
	inc hl
  endif
	exa
	ld a,(hl)
	exa

 	ld hl,#40a0+14
 	ld b,4
2
	ld (hl),c
	inc l
	ld (hl),d
	inc l
	ld (hl),e
	inc l
	ld (hl),a
	inc l
	exa
	ld (hl),a
	inc h
	ld (hl),a
	exa
	dec l
	ld (hl),a
	dec l
	ld (hl),e
	dec l
	ld (hl),d
	dec l
	ld (hl),c
	inc h
	djnz 2b

 	ld hl,#40c0+14
 	ld b,4
2
	ld (hl),c
	inc l
	ld (hl),d
	inc l
	ld (hl),e
	inc l
	ld (hl),a
	inc l
	exa
	ld (hl),a
	inc h
	ld (hl),a
	exa
	dec l
	ld (hl),a
	dec l
	ld (hl),e
	dec l
	ld (hl),d
	dec l
	ld (hl),c
	inc h
	djnz 2b

 
 	ld de,#58a0+14
_gg_bolt_current_phase_atr equ $+1
 	ld hl,gg_bolt_phases_atr
  if high(gg_bolt_phases_atr) == high(gg_bolt_phases_atr_end-1)
	ld a,l
 	dup 5
	 	ldi
 	edup
 	ld l,a
  else
 	dup 5
	 	ldi
 	edup
  endif

 	ld e,low(#58c0+14)
  if high(gg_bolt_phases_atr) != high(gg_bolt_phases_atr_end-1)
_gg_bolt_current_phase_atr2 equ $+1
 	ld hl,gg_bolt_phases_atr
  endif
 	dup 5
	 	ldi
 	edup


gg_bolt_fon_end_1
	// other strings
	// четыре строки под головкой болта
	ld hl,#4100

		ld sp,hl
		exx
		ld hl,$+5
		jp (ix)
gg_bolt_fon_lbl_1
		exx
		inc h

		ld sp,hl
		exx
  if (high($+5) == high(gg_bolt_fon_lbl_1)) && (high($+4) == high(gg_bolt_fon_lbl_1))
		ld l,low($+4)
  else
		ld hl,$+5
  endif
		jp (ix)
gg_bolt_fon_lbl_2
		exx
		inc h

		ld sp,hl
		exx
  if (high($+5) == high(gg_bolt_fon_lbl_2)) && (high($+4) == high(gg_bolt_fon_lbl_2))
		ld l,low($+4)
  else
		ld hl,$+5
  endif
		jp (ix)
gg_bolt_fon_lbl_3
		exx
		inc h

		ld sp,hl
		exx
  if (high($+5) == high(gg_bolt_fon_lbl_3)) && (high($+4) == high(gg_bolt_fon_lbl_3))
		ld l,low($+4)
  else
		ld hl,$+5
  endif
		jp (ix)
		exx
		inc h

	exx
	// тень под головкой болта (убираем резьбу)
	ld hl,#40e0+15
	ld a,#ff
	ld (hl),a
	inc l
	ld (hl),a
	inc l
	ld (hl),a
	inc h
	ld (hl),a
	dec l
	ld (hl),a
	dec l
	ld (hl),a
	inc h
	ld (hl),a
	inc l
	ld (hl),a
	inc l
	ld (hl),a
	inc h
	ld (hl),a
	dec l
	ld (hl),a
	dec l
	ld (hl),a
	exx

	jp gg_bolt_fon_enter_1


gg_bolt_fon_loop2

		ld sp,hl
		exx
		ld hl,$+5
		jp (ix)
gg_bolt_fon_lbl_4
		exx
		inc h

		ld sp,hl
		exx
  if (high($+5) == high(gg_bolt_fon_lbl_4)) && (high($+4) == high(gg_bolt_fon_lbl_4))
		ld l,low($+4)
  else
		ld hl,$+5
  endif
		jp (ix)
gg_bolt_fon_lbl_5
		exx
		inc h

		ld sp,hl
		exx
  if (high($+5) == high(gg_bolt_fon_lbl_5)) && (high($+4) == high(gg_bolt_fon_lbl_5))
		ld l,low($+4)
  else
		ld hl,$+5
  endif
		jp (ix)
gg_bolt_fon_lbl_6
		exx
		inc h

		ld sp,hl
		exx
  if (high($+5) == high(gg_bolt_fon_lbl_6)) && (high($+4) == high(gg_bolt_fon_lbl_6))
		ld l,low($+4)
  else
		ld hl,$+5
  endif
		jp (ix)
		exx
		inc h


gg_bolt_fon_enter_1

		ld sp,hl
		exx
		ld hl,$+5
		jp (ix)
gg_bolt_fon_lbl_7
		exx
		inc h

		ld sp,hl
		exx
  if (high($+5) == high(gg_bolt_fon_lbl_7)) && (high($+4) == high(gg_bolt_fon_lbl_7))
		ld l,low($+4)
  else
		ld hl,$+5
  endif
		jp (ix)
gg_bolt_fon_lbl_8
		exx
		inc h

		ld sp,hl
		exx
  if (high($+5) == high(gg_bolt_fon_lbl_8)) && (high($+4) == high(gg_bolt_fon_lbl_8))
		ld l,low($+4)
  else
		ld hl,$+5
  endif
		jp (ix)
gg_bolt_fon_lbl_9
		exx
		inc h

		ld sp,hl
		exx
  if (high($+5) == high(gg_bolt_fon_lbl_9)) && (high($+4) == high(gg_bolt_fon_lbl_9))
		ld l,low($+4)
  else
		ld hl,$+5
  endif
		jp (ix)
		exx


	dec hl
	inc h
	ld a,h
	and 7
	jr z,gg_bolt_fon_label_1
	inc hl
	jp gg_bolt_fon_loop2

gg_bolt_fon_label_1
	ld a,l
	sub -32
	ld l,a
	sbc a,a
	and #f8
	add a,h
	ld h,a

	add a,l
	cp #50+#5f
	inc hl
	jp nz,gg_bolt_fon_loop2

gg_bolt_fon_end

	// остатки резьбы
_gg_bolt_phase_anim equ $+1
	ld a,27
	ld d,a
	and 3

	ld e,%1001'1001
	dec a
	jr z,1f
	ld e,%1100'1100
	dec a
	jr z,1f
	ld e,%0110'0110
	dec a
	jr z,1f
	ld e,%0011'0011
1
	ld hl,#5040+15
	ld bc,8 *256+ #ff
	xor a
2
	rrc e
	jr c,1f
	ld (hl),c
	inc l
	ld (hl),c
	inc l
	ld (hl),c
	jp 3f
1
	ld (hl),a
	inc l
	ld (hl),a
	inc l
	ld (hl),a
3
	dec l
	dec l
	inc h
	djnz 2b

	// атрибуты кнопки
	ld a,d//ld a,(_gg_bolt_phase_anim)
	sub 20
	jr nc,1f
	add a,20
1
	cp 14
	ld c,%01'010'110
	jr c,1f
	ld c,%00'010'110
	cp 17
	jr c,1f
	ld c,%01'110'010
1
	ld hl,#5add
	ld (hl),c
	inc l
	ld (hl),c

	// надпись
	ld hl,gg_bolt_words
	exx
_gg_bolt_words_adr equ $+1
	ld hl,#5770

	ld bc,#ffff
	ld sp,hl
	dup 7
		push bc
	edup
	ld bc,(12+1) *256+ 7
	jp 9f

2
	ld sp,hl
	exx
	dup 7
		ld c,(hl)
		inc hl
		ld b,(hl)
		inc hl
		push bc
	edup
	exx
9
	inc h
	ld a,h
	and c//7
	jr z,3f
	djnz 2b
	jp 5f

3
	ld a,l
	sub -32
	ld l,a
	sbc a,a
	and #f8
	add a,h
	ld h,a
	djnz 2b
5

	dec b
	ld c,b//ld bc,#ffff
	ld sp,hl
	dup 7
		push bc
	edup
	exx

_gg_bolt_sp equ $+1
	ld sp,0

// ld a,2
// out(#fe),a



	ld a,d
_gg_bolt_phase_step equ $+1
	add a,39
	cp 40
	jr c,1f
	sub 40
1
	ld (_gg_bolt_phase_anim),a

	ld d,a

	ld hl,_gg_bolt_phase_step
	ld a,(hl)
	dec a
	jr z,1f
	ld (hl),a
1






	ld a,d//(_gg_bolt_phase_anim)
2
	sub 10
	jr nc,2b
	add a,10

	ld c,a
	add a,a	// *2
	add a,a	// *4
	add a,c	// *5

  if high(gg_bolt_phases) == high(gg_bolt_phases_end-1)
	ld h,high(gg_bolt_phases)
	add a,low(gg_bolt_phases)
	ld l,a
  else
	ld l,a
	ld h,b//0
	ld bc,gg_bolt_phases
	add hl,bc
  endif
	ld (_gg_bolt_current_phase_1),hl
//	ld (_gg_bolt_current_phase_2),hl

	ld bc,gg_bolt_phases_atr-gg_bolt_phases
	add hl,bc
	ld (_gg_bolt_current_phase_atr),hl
  if high(gg_bolt_phases_atr) != high(gg_bolt_phases_atr_end-1)
	ld (_gg_bolt_current_phase_atr2),hl
  endif

	ld a,d//ld a,(_gg_bolt_phase_anim)
	add a,a
  if high(gg_bolt_fon_phases_table) == high(gg_bolt_fon_phases_table_end-1)
	ld h,high(gg_bolt_fon_phases_table)
	add a,low(gg_bolt_fon_phases_table)
	ld l,a
  else
	ld l,a
	ld h,b//0
	ld bc,gg_bolt_fon_phases_table
	add hl,bc
  endif
	ld a,(hl)
  if high(gg_bolt_fon_phases_table) == high(gg_bolt_fon_phases_table_end-1)
	inc l
  else
	inc hl
  endif
	ld h,(hl)
	ld l,a
	ld (_gg_bolt_fon_current_phase),hl

	ld a,(_gg_bolt_phase_step)
	dec a
	ret nz

  if high(gg_bolt_jump_table) == high(gg_bolt_jump_table_end)
	ld a,d
	add a,a
	ld h,high(gg_bolt_jump_table)
	add a,low(gg_bolt_jump_table)
	ld l,a
  else
	ld h,a//0
	ld a,d
	add a,a
	ld l,a
//	ld h,0
	ld bc,gg_bolt_jump_table
	add hl,bc
  endif
	ld a,(hl)
  if high(gg_bolt_jump_table) == high(gg_bolt_jump_table_end)
	inc l
  else
	inc hl
  endif
	ld h,(hl)
	ld l,a
	ld (_gg_bolt_words_adr),hl

// xor a
// out(#fe),a

	ret






gg_bolt_fon_phase_39
	ld ix,gg_bolt_fon_phase_00
	ld bc,#0380
	ld de,#ffff: push de	// #ffff
	ld d,b: inc e: push de	// #0300
	ld d,c: dec e: push de	// #80ff
	ld d,e: ld e,b: push de	// #ff03
	inc d: ld e,c: push de	// #0080
	dec d: ld e,d: push de	// #ffff
	ld d,b: inc e: push de	// #0300
	dec e: ld d,e: push de	// #ffff
	ld d,e: ld e,b: push de	// #ff03
	inc d: ld e,c: push de	// #0080
	dec d: ld e,d: push de	// #ffff
	ld d,b: inc e: push de	// #0300
	ld d,c: dec e: push de	// #80ff
	ld d,e: ld e,b: push de	// #ff03
	inc d: ld e,c: push de	// #0080
	dec d: ld e,d: push de	// #ffff
	jp (hl)

gg_bolt_fon_phase_38
  if high(gg_bolt_fon_phase_39) == high(gg_bolt_fon_phase_38)
	ld lx,low(gg_bolt_fon_phase_39)
  else
	ld ix,gg_bolt_fon_phase_39
  endif
	ld bc,#01c0
	ld de,#ffff: push de	// #ffff
	ld d,b: inc e: push de	// #0100
	ld d,c: dec e: push de	// #c0ff
	ld d,e: ld e,b: push de	// #ff01
	inc d: ld e,c: push de	// #00c0
	dec d: ld e,d: push de	// #ffff
	ld d,b: inc e: push de	// #0100
	dec e: ld d,e: push de	// #ffff
	ld d,e: ld e,b: push de	// #ff01
	inc d: ld e,c: push de	// #00c0
	dec d: ld e,d: push de	// #ffff
	ld d,b: inc e: push de	// #0100
	ld d,c: dec e: push de	// #c0ff
	ld d,e: ld e,b: push de	// #ff01
	inc d: ld e,c: push de	// #00c0
	dec d: ld e,d: push de	// #ffff
	jp (hl)

gg_bolt_fon_phase_37
  if high(gg_bolt_fon_phase_38) == high(gg_bolt_fon_phase_37)
	ld lx,low(gg_bolt_fon_phase_38)
  else
	ld ix,gg_bolt_fon_phase_38
  endif
	ld bc,#00e0
	ld de,#ffff: push de	// #ffff
	inc de: push de	// #0000
	ld d,c: dec e: push de	// #e0ff
	ld d,e: inc e: push de	// #ff00
	push bc	// #00e0
	dec e: push de	// #ffff
	inc de: push de	// #0000
	push de	// #0000
	push de	// #0000
	push bc	// #00e0
	dec de: push de	// #ffff
	inc de: push de	// #0000
	ld d,c: dec e: push de	// #e0ff
	ld d,e: inc e: push de	// #ff00
	push bc	// #00e0
	dec e: push de	// #ffff
	jp (hl)

gg_bolt_fon_phase_36
  if high(gg_bolt_fon_phase_37) == high(gg_bolt_fon_phase_36)
	ld lx,low(gg_bolt_fon_phase_37)
  else
	ld ix,gg_bolt_fon_phase_37
  endif
	ld bc,#7ff0
	ld de,#ff7f: push de	// #ff7f
	inc d: ld e,d: push de	// #0000
	ld d,c: dec e: push de	// #f0ff
	ld d,b: inc e: push de	// #7f00
	ld d,e: ld e,c: push de	// #00f0
	dec d: ld e,b: push de	// #ff7f
	inc d: ld e,d: push de	// #0000
	push de	// #0000
	push de	// #0000
	ld e,c: push de	// #00f0
	dec d: ld e,b: push de	// #ff7f
	inc d: ld e,d: push de	// #0000
	ld d,c: dec e: push de	// #f0ff
	ld d,b: inc e: push de	// #7f00
	ld d,e: ld e,c: push de	// #00f0
	dec d: ld e,b: push de	// #ff7f
	jp (hl)

gg_bolt_fon_phase_35
  if high(gg_bolt_fon_phase_36) == high(gg_bolt_fon_phase_35)
	ld lx,low(gg_bolt_fon_phase_36)
  else
	ld ix,gg_bolt_fon_phase_36
  endif
	ld bc,#3ff8
	ld de,#ff3f: push de	// #ff3f
	inc d: ld e,d: push de	// #0000
	ld d,c: dec e: push de	// #f8ff
	ld d,b: inc e: push de	// #3f00
	ld d,e: ld e,c: push de	// #00f8
	dec d: ld e,b: push de	// #ff3f
	inc d: ld e,d: push de	// #0000
	dec de: push de	// #ffff
	inc e: push de	// #ff00
	inc d: ld e,c: push de	// #00f8
	dec d: ld e,b: push de	// #ff3f
	inc d: ld e,d: push de	// #0000
	ld d,c: dec e: push de	// #f8ff
	ld d,b: inc e: push de	// #3f00
	ld d,e: ld e,c: push de	// #00f8
	dec d: ld e,b: push de	// #ff3f
	jp (hl)

gg_bolt_fon_phase_34
  if high(gg_bolt_fon_phase_35) == high(gg_bolt_fon_phase_34)
	ld lx,low(gg_bolt_fon_phase_35)
  else
	ld ix,gg_bolt_fon_phase_35
  endif
	ld bc,#1ffc
	ld de,#ff1f: push de	// #ff1f
	inc d: ld e,d: push de	// #0000
	ld d,c: dec e: push de	// #fcff
	ld d,b: inc e: push de	// #1f00
	ld d,e: ld e,c: push de	// #00fc
	dec d: ld e,b: push de	// #ff1f
	inc d: ld e,d: push de	// #0000
	dec de: push de	// #ffff
	inc e: push de	// #ff00
	inc d: ld e,c: push de	// #00fc
	dec d: ld e,b: push de	// #ff1f
	inc d: ld e,d: push de	// #0000
	ld d,c: dec e: push de	// #fcff
	ld d,b: inc e: push de	// #1f00
	ld d,e: ld e,c: push de	// #00fc
	dec d: ld e,b: push de	// #ff1f
	jp (hl)

gg_bolt_fon_phase_33
  if high(gg_bolt_fon_phase_34) == high(gg_bolt_fon_phase_33)
	ld lx,low(gg_bolt_fon_phase_34)
  else
	ld ix,gg_bolt_fon_phase_34
  endif
	ld bc,#0ffe
	ld de,#ff0f: push de	// #ff0f
	inc d: ld e,d: push de	// #0000
	ld d,c: dec e: push de	// #feff
	ld d,b: inc e: push de	// #0f00
	ld d,e: ld e,c: push de	// #00fe
	dec d: ld e,b: push de	// #ff0f
	inc d: ld e,d: push de	// #0000
	push de	// #0000
	push de	// #0000
	ld e,c: push de	// #00fe
	dec d: ld e,b: push de	// #ff0f
	inc d: ld e,d: push de	// #0000
	ld d,c: dec e: push de	// #feff
	ld d,b: inc e: push de	// #0f00
	ld d,e: ld e,c: push de	// #00fe
	dec d: ld e,b: push de	// #ff0f
	jp (hl)

gg_bolt_fon_phase_32
  if high(gg_bolt_fon_phase_33) == high(gg_bolt_fon_phase_32)
	ld lx,low(gg_bolt_fon_phase_33)
  else
	ld ix,gg_bolt_fon_phase_33
  endif
	ld bc,#0700
	ld de,#ff07: push de	// #ff07
	inc d: ld e,d: push de	// #0000
	dec de: push de	// #ffff
	push bc	// #0700
	inc d: push de	// #00ff
	dec d: ld e,b: push de	// #ff07
	inc d: ld e,d: push de	// #0000
	push de	// #0000
	push de	// #0000
	dec e: push de	// #00ff
	dec d: ld e,b: push de	// #ff07
	inc d: ld e,d: push de	// #0000
	dec de: push de	// #ffff
	push bc	// #0700
	inc d: push de	// #00ff
	dec d: ld e,b: push de	// #ff07
	jp (hl)

gg_bolt_fon_phase_31
  if high(gg_bolt_fon_phase_32) == high(gg_bolt_fon_phase_31)
	ld lx,low(gg_bolt_fon_phase_32)
  else
	ld ix,gg_bolt_fon_phase_32
  endif
	ld bc,#0380
	ld de,#ff03: push de	// #ff03
	inc d: ld e,c: push de	// #0080
	dec d: ld e,d: push de	// #ffff
	ld d,b: inc e: push de	// #0300
	ld d,c: dec e: push de	// #80ff
	ld d,e: ld e,b: push de	// #ff03
	inc d: ld e,c: push de	// #0080
	dec d: ld e,d: push de	// #ffff
	inc e: push de	// #ff00
	ld d,c: dec e: push de	// #80ff
	ld d,e: ld e,b: push de	// #ff03
	inc d: ld e,c: push de	// #0080
	dec d: ld e,d: push de	// #ffff
	ld d,b: inc e: push de	// #0300
	ld d,c: dec e: push de	// #80ff
	ld d,e: ld e,b: push de	// #ff03
	jp (hl)

gg_bolt_fon_phase_30
  if high(gg_bolt_fon_phase_31) == high(gg_bolt_fon_phase_30)
	ld lx,low(gg_bolt_fon_phase_31)
  else
	ld ix,gg_bolt_fon_phase_31
  endif
	ld bc,#01c0
	ld de,#ff01: push de	// #ff01
	inc d: ld e,c: push de	// #00c0
	dec d: ld e,d: push de	// #ffff
	ld d,b: inc e: push de	// #0100
	ld d,c: dec e: push de	// #c0ff
	ld d,e: ld e,b: push de	// #ff01
	inc d: ld e,c: push de	// #00c0
	dec d: ld e,d: push de	// #ffff
	inc e: push de	// #ff00
	ld d,c: dec e: push de	// #c0ff
	ld d,e: ld e,b: push de	// #ff01
	inc d: ld e,c: push de	// #00c0
	dec d: ld e,d: push de	// #ffff
	ld d,b: inc e: push de	// #0100
	ld d,c: dec e: push de	// #c0ff
	ld d,e: ld e,b: push de	// #ff01
	jp (hl)

gg_bolt_fon_phase_29
  if high(gg_bolt_fon_phase_30) == high(gg_bolt_fon_phase_29)
	ld lx,low(gg_bolt_fon_phase_30)
  else
	ld ix,gg_bolt_fon_phase_30
  endif
	ld bc,#00e0
	ld de,#ff00: push de	// #ff00
	push bc	// #00e0
	dec e: push de	// #ffff
	inc de: push de	// #0000
	ld d,c: dec e: push de	// #e0ff
	ld d,e: inc e: push de	// #ff00
	push bc	// #00e0
	inc d: push de	// #0000
	push de	// #0000
	ld d,c: dec e: push de	// #e0ff
	ld d,e: inc e: push de	// #ff00
	push bc	// #00e0
	dec e: push de	// #ffff
	inc de: push de	// #0000
	ld d,c: dec e: push de	// #e0ff
	ld d,e: inc e: push de	// #ff00
	jp (hl)

gg_bolt_fon_phase_28
  if high(gg_bolt_fon_phase_29) == high(gg_bolt_fon_phase_28)
	ld lx,low(gg_bolt_fon_phase_29)
  else
	ld ix,gg_bolt_fon_phase_29
  endif
	ld bc,#7ff0
	ld de,#7f00: push de	// #7f00
	ld d,e: ld e,c: push de	// #00f0
	dec d: ld e,b: push de	// #ff7f
	inc d: ld e,d: push de	// #0000
	ld d,c: dec e: push de	// #f0ff
	ld d,b: inc e: push de	// #7f00
	ld d,e: ld e,c: push de	// #00f0
	ld e,d: push de	// #0000
	push de	// #0000
	ld d,c: dec e: push de	// #f0ff
	ld d,b: inc e: push de	// #7f00
	ld d,e: ld e,c: push de	// #00f0
	dec d: ld e,b: push de	// #ff7f
	inc d: ld e,d: push de	// #0000
	ld d,c: dec e: push de	// #f0ff
	ld d,b: inc e: push de	// #7f00
	jp (hl)

gg_bolt_fon_phase_27
  if high(gg_bolt_fon_phase_28) == high(gg_bolt_fon_phase_27)
	ld lx,low(gg_bolt_fon_phase_28)
  else
	ld ix,gg_bolt_fon_phase_28
  endif
	ld bc,#3ff8
	ld de,#3f00: push de	// #3f00
	ld d,e: ld e,c: push de	// #00f8
	dec d: ld e,b: push de	// #ff3f
	inc d: ld e,d: push de	// #0000
	ld d,c: dec e: push de	// #f8ff
	ld d,b: inc e: push de	// #3f00
	ld d,e: ld e,c: push de	// #00f8
	dec d: ld e,d: push de	// #ffff
	inc e: push de	// #ff00
	ld d,c: dec e: push de	// #f8ff
	ld d,b: inc e: push de	// #3f00
	ld d,e: ld e,c: push de	// #00f8
	dec d: ld e,b: push de	// #ff3f
	inc d: ld e,d: push de	// #0000
	ld d,c: dec e: push de	// #f8ff
	ld d,b: inc e: push de	// #3f00
	jp (hl)

gg_bolt_fon_phase_26
  if high(gg_bolt_fon_phase_27) == high(gg_bolt_fon_phase_26)
	ld lx,low(gg_bolt_fon_phase_27)
  else
	ld ix,gg_bolt_fon_phase_27
  endif
	ld bc,#1ffc
	ld de,#1f00: push de	// #1f00
	ld d,e: ld e,c: push de	// #00fc
	dec d: ld e,b: push de	// #ff1f
	inc d: ld e,d: push de	// #0000
	ld d,c: dec e: push de	// #fcff
	ld d,b: inc e: push de	// #1f00
	ld d,e: ld e,c: push de	// #00fc
	dec d: ld e,d: push de	// #ffff
	inc e: push de	// #ff00
	ld d,c: dec e: push de	// #fcff
	ld d,b: inc e: push de	// #1f00
	ld d,e: ld e,c: push de	// #00fc
	dec d: ld e,b: push de	// #ff1f
	inc d: ld e,d: push de	// #0000
	ld d,c: dec e: push de	// #fcff
	ld d,b: inc e: push de	// #1f00
	jp (hl)

gg_bolt_fon_phase_25
  if high(gg_bolt_fon_phase_26) == high(gg_bolt_fon_phase_25)
	ld lx,low(gg_bolt_fon_phase_26)
  else
	ld ix,gg_bolt_fon_phase_26
  endif
	ld bc,#0ffe
	ld de,#0f00: push de	// #0f00
	ld d,e: ld e,c: push de	// #00fe
	dec d: ld e,b: push de	// #ff0f
	inc d: ld e,d: push de	// #0000
	ld d,c: dec e: push de	// #feff
	ld d,b: inc e: push de	// #0f00
	ld d,e: ld e,c: push de	// #00fe
	ld e,d: push de	// #0000
	push de	// #0000
	ld d,c: dec e: push de	// #feff
	ld d,b: inc e: push de	// #0f00
	ld d,e: ld e,c: push de	// #00fe
	dec d: ld e,b: push de	// #ff0f
	inc d: ld e,d: push de	// #0000
	ld d,c: dec e: push de	// #feff
	ld d,b: inc e: push de	// #0f00
	jp (hl)

gg_bolt_fon_phase_24
  if high(gg_bolt_fon_phase_25) == high(gg_bolt_fon_phase_24)
	ld lx,low(gg_bolt_fon_phase_25)
  else
	ld ix,gg_bolt_fon_phase_25
  endif
	ld bc,#0700
	push bc
	ld de,#00ff: push de	// #00ff
	dec d: ld e,b: push de	// #ff07
	inc d: ld e,d: push de	// #0000
	dec de: push de	// #ffff
	push bc	// #0700
	inc d: push de	// #00ff
	inc e: push de	// #0000
	push de	// #0000
	dec de: push de	// #ffff
	push bc	// #0700
	inc d: push de	// #00ff
	dec d: ld e,b: push de	// #ff07
	inc d: ld e,d: push de	// #0000
	dec de: push de	// #ffff
	push bc	// #0700
	jp (hl)

gg_bolt_fon_phase_23
  if high(gg_bolt_fon_phase_24) == high(gg_bolt_fon_phase_23)
	ld lx,low(gg_bolt_fon_phase_24)
  else
	ld ix,gg_bolt_fon_phase_24
  endif
	ld bc,#0380
	ld de,#0300: push de	// #0300
	ld d,c: dec e: push de	// #80ff
	ld d,e: ld e,b: push de	// #ff03
	inc d: ld e,c: push de	// #0080
	dec d: ld e,d: push de	// #ffff
	ld d,b: inc e: push de	// #0300
	ld d,c: dec e: push de	// #80ff
	ld d,e: push de	// #ffff
	ld e,c: push de	// #ff80
	ld e,d: push de	// #ffff
	ld d,b: inc e: push de	// #0300
	ld d,c: dec e: push de	// #80ff
	ld d,e: ld e,b: push de	// #ff03
	inc d: ld e,c: push de	// #0080
	dec d: ld e,d: push de	// #ffff
	ld d,b: inc e: push de	// #0300
	jp (hl)

gg_bolt_fon_phase_22
  if high(gg_bolt_fon_phase_23) == high(gg_bolt_fon_phase_22)
	ld lx,low(gg_bolt_fon_phase_23)
  else
	ld ix,gg_bolt_fon_phase_23
  endif
	ld bc,#01c0
	ld de,#0100: push de	// #0100
	ld d,c: dec e: push de	// #c0ff
	ld d,e: ld e,b: push de	// #ff01
	inc d: ld e,c: push de	// #00c0
	dec d: ld e,d: push de	// #ffff
	ld d,b: inc e: push de	// #0100
	ld d,c: dec e: push de	// #c0ff
	ld d,e: push de	// #ffff
	ld e,c: push de	// #ffc0
	ld e,d: push de	// #ffff
	ld d,b: inc e: push de	// #0100
	ld d,c: dec e: push de	// #c0ff
	ld d,e: ld e,b: push de	// #ff01
	inc d: ld e,c: push de	// #00c0
	dec d: ld e,d: push de	// #ffff
	ld d,b: inc e: push de	// #0100
	jp (hl)

gg_bolt_fon_phase_21
  if high(gg_bolt_fon_phase_22) == high(gg_bolt_fon_phase_21)
	ld lx,low(gg_bolt_fon_phase_22)
  else
	ld ix,gg_bolt_fon_phase_22
  endif
	ld bc,#00e0
	ld d,b: ld e,b: push de	// #0000
	ld d,c: dec e: push de	// #e0ff
	ld d,e: inc e: push de	// #ff00
	push bc	// #00e0
	dec e: push de	// #ffff
	inc de: push de	// #0000
	ld d,c: dec e: push de	// #e0ff
	ld d,b: inc e: push de	// #0000
	push bc	// #00e0
	dec de: push de	// #ffff
	inc de: push de	// #0000
	ld d,c: dec e: push de	// #e0ff
	ld d,e: inc e: push de	// #ff00
	push bc	// #00e0
	dec e: push de	// #ffff
	inc de: push de	// #0000
	jp (hl)

gg_bolt_fon_phase_20
  if high(gg_bolt_fon_phase_21) == high(gg_bolt_fon_phase_20)
	ld lx,low(gg_bolt_fon_phase_21)
  else
	ld ix,gg_bolt_fon_phase_21
  endif
	ld bc,#f07f
	ld de,#0000: push de	// #0000
	ld d,b: dec e: push de	// #f0ff
	ld d,c: inc e: push de	// #7f00
	ld d,e: ld e,b: push de	// #00f0
	dec d: ld e,c: push de	// #ff7f
	inc d: ld e,d: push de	// #0000
	ld d,b: dec e: push de	// #f0ff
	inc e: ld d,e: push de	// #0000
	ld d,e: ld e,b: push de	// #00f0
	dec d: ld e,c: push de	// #ff7f
	inc d: ld e,d: push de	// #0000
	ld d,b: dec e: push de	// #f0ff
	ld d,c: inc e: push de	// #7f00
	ld d,e: ld e,b: push de	// #00f0
	dec d: ld e,c: push de	// #ff7f
	inc d: ld e,d: push de	// #0000
	jp (hl)

gg_bolt_fon_phase_19
  if high(gg_bolt_fon_phase_20) == high(gg_bolt_fon_phase_19)
	ld lx,low(gg_bolt_fon_phase_20)
  else
	ld ix,gg_bolt_fon_phase_20
  endif
	ld bc,#f83f
	ld de,#0000: push de	// #0000
	ld d,b: dec e: push de	// #f8ff
	ld d,c: inc e: push de	// #3f00
	ld d,e: ld e,b: push de	// #00f8
	dec d: ld e,c: push de	// #ff3f
	inc d: ld e,d: push de	// #0000
	ld d,b: dec e: push de	// #f8ff
	ld d,e: push de	// #ffff
	ld e,b: push de	// #fff8
	ld e,c: push de	// #ff3f
	inc d: ld e,d: push de	// #0000
	ld d,b: dec e: push de	// #f8ff
	ld d,c: inc e: push de	// #3f00
	ld d,e: ld e,b: push de	// #00f8
	dec d: ld e,c: push de	// #ff3f
	inc d: ld e,d: push de	// #0000
	jp (hl)

gg_bolt_fon_phase_18
  if high(gg_bolt_fon_phase_19) == high(gg_bolt_fon_phase_18)
	ld lx,low(gg_bolt_fon_phase_19)
  else
	ld ix,gg_bolt_fon_phase_19
  endif
	ld bc,#fc1f
	ld de,#0000: push de	// #0000
	ld d,b: dec e: push de	// #fcff
	ld d,c: inc e: push de	// #1f00
	ld d,e: ld e,b: push de	// #00fc
	dec d: ld e,c: push de	// #ff1f
	inc d: ld e,d: push de	// #0000
	ld d,b: dec e: push de	// #fcff
	ld d,e: push de	// #ffff
	ld e,b: push de	// #fffc
	ld e,c: push de	// #ff1f
	inc d: ld e,d: push de	// #0000
	ld d,b: dec e: push de	// #fcff
	ld d,c: inc e: push de	// #1f00
	ld d,e: ld e,b: push de	// #00fc
	dec d: ld e,c: push de	// #ff1f
	inc d: ld e,d: push de	// #0000
	jp (hl)

gg_bolt_fon_phase_17
  if high(gg_bolt_fon_phase_18) == high(gg_bolt_fon_phase_17)
	ld lx,low(gg_bolt_fon_phase_18)
  else
	ld ix,gg_bolt_fon_phase_18
  endif
	ld bc,#fe0f
	ld de,#0000: push de	// #0000
	ld d,b: dec e: push de	// #feff
	ld d,c: inc e: push de	// #0f00
	ld d,e: ld e,b: push de	// #00fe
	dec d: ld e,c: push de	// #ff0f
	inc d: ld e,d: push de	// #0000
	ld d,b: dec e: push de	// #feff
	inc e: ld d,e: push de	// #0000
	ld d,e: ld e,b: push de	// #00fe
	dec d: ld e,c: push de	// #ff0f
	inc d: ld e,d: push de	// #0000
	ld d,b: dec e: push de	// #feff
	ld d,c: inc e: push de	// #0f00
	ld d,e: ld e,b: push de	// #00fe
	dec d: ld e,c: push de	// #ff0f
	inc d: ld e,d: push de	// #0000
	jp (hl)

gg_bolt_fon_phase_16
  if high(gg_bolt_fon_phase_17) == high(gg_bolt_fon_phase_16)
	ld lx,low(gg_bolt_fon_phase_17)
  else
	ld ix,gg_bolt_fon_phase_17
  endif
	ld bc,#0700
	ld d,c: ld e,c: push de	// #0000
	dec de: push de	// #ffff
	push bc	// #0700
	inc d: push de	// #00ff
	dec d: ld e,b: push de	// #ff07
	inc d: ld e,d: push de	// #0000
	dec de: push de	// #ffff
	inc de: push de	// #0000
	dec e: push de	// #00ff
	dec d: ld e,b: push de	// #ff07
	inc d: ld e,d: push de	// #0000
	dec de: push de	// #ffff
	push bc	// #0700
	inc d: push de	// #00ff
	dec d: ld e,b: push de	// #ff07
	inc d: ld e,d: push de	// #0000
	jp (hl)

gg_bolt_fon_phase_15
  if high(gg_bolt_fon_phase_16) == high(gg_bolt_fon_phase_15)
	ld lx,low(gg_bolt_fon_phase_16)
  else
	ld ix,gg_bolt_fon_phase_16
  endif
	ld bc,#8003
	ld de,#0080: push de	// #0080
	dec d: ld e,d: push de	// #ffff
	ld d,c: inc e: push de	// #0300
	ld d,b: dec e: push de	// #80ff
	ld d,e: ld e,c: push de	// #ff03
	inc d: ld e,b: push de	// #0080
	dec d: ld e,d: push de	// #ffff
	push de	// #ffff
	push de	// #ffff
	ld e,c: push de	// #ff03
	inc d: ld e,b: push de	// #0080
	dec d: ld e,d: push de	// #ffff
	ld d,c: inc e: push de	// #0300
	ld d,b: dec e: push de	// #80ff
	ld d,e: ld e,c: push de	// #ff03
	inc d: ld e,b: push de	// #0080
	jp (hl)

gg_bolt_fon_phase_14
  if high(gg_bolt_fon_phase_15) == high(gg_bolt_fon_phase_14)
	ld lx,low(gg_bolt_fon_phase_15)
  else
	ld ix,gg_bolt_fon_phase_15
  endif
	ld bc,#c001
	ld de,#00c0: push de	// #00c0
	dec d: ld e,d: push de	// #ffff
	ld d,c: inc e: push de	// #0100
	ld d,b: dec e: push de	// #c0ff
	ld d,e: ld e,c: push de	// #ff01
	inc d: ld e,b: push de	// #00c0
	dec d: ld e,d: push de	// #ffff
	push de	// #ffff
	push de	// #ffff
	ld e,c: push de	// #ff01
	inc d: ld e,b: push de	// #00c0
	dec d: ld e,d: push de	// #ffff
	ld d,c: inc e: push de	// #0100
	ld d,b: dec e: push de	// #c0ff
	ld d,e: ld e,c: push de	// #ff01
	inc d: ld e,b: push de	// #00c0
	jp (hl)

gg_bolt_fon_phase_13
  if high(gg_bolt_fon_phase_14) == high(gg_bolt_fon_phase_13)
	ld lx,low(gg_bolt_fon_phase_14)
  else
	ld ix,gg_bolt_fon_phase_14
  endif
	ld bc,#00e0
	push bc
	ld de,#ffff: push de	// #ffff
	inc de: push de	// #0000
	ld d,c: dec e: push de	// #e0ff
	ld d,e: inc e: push de	// #ff00
	push bc	// #00e0
	dec e: push de	// #ffff
	inc de: push de	// #0000
	dec e: push de	// #00ff
	dec d: inc e: push de	// #ff00
	push bc	// #00e0
	dec e: push de	// #ffff
	inc de: push de	// #0000
	ld d,c: dec e: push de	// #e0ff
	ld d,e: inc e: push de	// #ff00
	push bc	// #00e0
	jp (hl)

gg_bolt_fon_phase_12
  if high(gg_bolt_fon_phase_13) == high(gg_bolt_fon_phase_12)
	ld lx,low(gg_bolt_fon_phase_13)
  else
	ld ix,gg_bolt_fon_phase_13
  endif
	ld bc,#f07f
	ld de,#00f0: push de	// #00f0
	dec d: ld e,c: push de	// #ff7f
	inc d: ld e,d: push de	// #0000
	ld d,b: dec e: push de	// #f0ff
	ld d,c: inc e: push de	// #7f00
	ld d,e: ld e,b: push de	// #00f0
	dec d: ld e,c: push de	// #ff7f
	inc d: ld e,d: push de	// #0000
	dec e: push de	// #00ff
	ld d,c: inc e: push de	// #7f00
	ld d,e: ld e,b: push de	// #00f0
	dec d: ld e,c: push de	// #ff7f
	inc d: ld e,d: push de	// #0000
	ld d,b: dec e: push de	// #f0ff
	ld d,c: inc e: push de	// #7f00
	ld d,e: ld e,b: push de	// #00f0
	jp (hl)

gg_bolt_fon_phase_11
  if high(gg_bolt_fon_phase_12) == high(gg_bolt_fon_phase_11)
	ld lx,low(gg_bolt_fon_phase_12)
  else
	ld ix,gg_bolt_fon_phase_12
  endif
	ld bc,#f83f
	ld de,#00f8: push de	// #00f8
	dec d: ld e,c: push de	// #ff3f
	inc d: ld e,d: push de	// #0000
	ld d,b: dec e: push de	// #f8ff
	ld d,c: inc e: push de	// #3f00
	ld d,e: ld e,b: push de	// #00f8
	dec d: ld e,c: push de	// #ff3f
	ld e,d: push de	// #ffff
	push de	// #ffff
	ld d,c: inc e: push de	// #3f00
	ld d,e: ld e,b: push de	// #00f8
	dec d: ld e,c: push de	// #ff3f
	inc d: ld e,d: push de	// #0000
	ld d,b: dec e: push de	// #f8ff
	ld d,c: inc e: push de	// #3f00
	ld d,e: ld e,b: push de	// #00f8
	jp (hl)

gg_bolt_fon_phase_10
  if high(gg_bolt_fon_phase_11) == high(gg_bolt_fon_phase_10)
	ld lx,low(gg_bolt_fon_phase_11)
  else
	ld ix,gg_bolt_fon_phase_11
  endif
	ld bc,#fc1f
	ld de,#00fc: push de	// #00fc
	dec d: ld e,c: push de	// #ff1f
	inc d: ld e,d: push de	// #0000
	ld d,b: dec e: push de	// #fcff
	ld d,c: inc e: push de	// #1f00
	ld d,e: ld e,b: push de	// #00fc
	dec d: ld e,c: push de	// #ff1f
	ld e,d: push de	// #ffff
	push de	// #ffff
	ld d,c: inc e: push de	// #1f00
	ld d,e: ld e,b: push de	// #00fc
	dec d: ld e,c: push de	// #ff1f
	inc d: ld e,d: push de	// #0000
	ld d,b: dec e: push de	// #fcff
	ld d,c: inc e: push de	// #1f00
	ld d,e: ld e,b: push de	// #00fc
	jp (hl)

gg_bolt_fon_phase_09
  if high(gg_bolt_fon_phase_10) == high(gg_bolt_fon_phase_09)
	ld lx,low(gg_bolt_fon_phase_10)
  else
	ld ix,gg_bolt_fon_phase_10
  endif
	ld bc,#fe0f
	ld de,#00fe: push de	// #00fe
	dec d: ld e,c: push de	// #ff0f
	inc d: ld e,d: push de	// #0000
	ld d,b: dec e: push de	// #feff
	ld d,c: inc e: push de	// #0f00
	ld d,e: ld e,b: push de	// #00fe
	dec d: ld e,c: push de	// #ff0f
	inc d: ld e,d: push de	// #0000
	dec e: push de	// #00ff
	ld d,c: inc e: push de	// #0f00
	ld d,e: ld e,b: push de	// #00fe
	dec d: ld e,c: push de	// #ff0f
	inc d: ld e,d: push de	// #0000
	ld d,b: dec e: push de	// #feff
	ld d,c: inc e: push de	// #0f00
	ld d,e: ld e,b: push de	// #00fe
	jp (hl)

gg_bolt_fon_phase_08
  if high(gg_bolt_fon_phase_09) == high(gg_bolt_fon_phase_08)
	ld lx,low(gg_bolt_fon_phase_09)
  else
	ld ix,gg_bolt_fon_phase_09
  endif
	ld bc,#0700
	ld de,#00ff: push de	// #00ff
	dec d: ld e,b: push de	// #ff07
	inc d: ld e,d: push de	// #0000
	dec de: push de	// #ffff
	push bc	// #0700
	inc d: push de	// #00ff
	dec d: ld e,b: push de	// #ff07
	inc d: ld e,d: push de	// #0000
	dec e: push de	// #00ff
	push bc	// #0700
	push de	// #00ff
	dec d: ld e,b: push de	// #ff07
	inc d: ld e,d: push de	// #0000
	dec de: push de	// #ffff
	push bc	// #0700
	inc d: push de	// #00ff
	jp (hl)

gg_bolt_fon_phase_07
  if high(gg_bolt_fon_phase_08) == high(gg_bolt_fon_phase_07)
	ld lx,low(gg_bolt_fon_phase_08)
  else
	ld ix,gg_bolt_fon_phase_08
  endif
	ld bc,#8003
	ld de,#80ff: push de	// #80ff
	ld d,e: ld e,c: push de	// #ff03
	inc d: ld e,b: push de	// #0080
	dec d: ld e,d: push de	// #ffff
	ld d,c: inc e: push de	// #0300
	ld d,b: dec e: push de	// #80ff
	ld d,e: ld e,c: push de	// #ff03
	ld e,d: push de	// #ffff
	push de	// #ffff
	ld d,c: inc e: push de	// #0300
	ld d,b: dec e: push de	// #80ff
	ld d,e: ld e,c: push de	// #ff03
	inc d: ld e,b: push de	// #0080
	dec d: ld e,d: push de	// #ffff
	ld d,c: inc e: push de	// #0300
	ld d,b: dec e: push de	// #80ff
	jp (hl)

gg_bolt_fon_phase_06
  if high(gg_bolt_fon_phase_07) == high(gg_bolt_fon_phase_06)
	ld lx,low(gg_bolt_fon_phase_07)
  else
	ld ix,gg_bolt_fon_phase_07
  endif
	ld bc,#c001
	ld de,#c0ff: push de	// #c0ff
	ld d,e: ld e,c: push de	// #ff01
	inc d: ld e,b: push de	// #00c0
	dec d: ld e,d: push de	// #ffff
	ld d,c: inc e: push de	// #0100
	ld d,b: dec e: push de	// #c0ff
	ld d,e: ld e,c: push de	// #ff01
	ld e,d: push de	// #ffff
	push de	// #ffff
	ld d,c: inc e: push de	// #0100
	ld d,b: dec e: push de	// #c0ff
	ld d,e: ld e,c: push de	// #ff01
	inc d: ld e,b: push de	// #00c0
	dec d: ld e,d: push de	// #ffff
	ld d,c: inc e: push de	// #0100
	ld d,b: dec e: push de	// #c0ff
	jp (hl)

gg_bolt_fon_phase_05
  if high(gg_bolt_fon_phase_06) == high(gg_bolt_fon_phase_05)
	ld lx,low(gg_bolt_fon_phase_06)
  else
	ld ix,gg_bolt_fon_phase_06
  endif
	ld bc,#00e0
	ld de,#e0ff: push de	// #e0ff
	ld d,e: inc e: push de	// #ff00
	push bc	// #00e0
	dec e: push de	// #ffff
	inc de: push de	// #0000
	ld d,c: dec e: push de	// #e0ff
	ld d,e: inc e: push de	// #ff00
	inc d: push de	// #0000
	dec e: push de	// #00ff
	inc e: push de	// #0000
	ld d,c: dec e: push de	// #e0ff
	ld d,e: inc e: push de	// #ff00
	push bc	// #00e0
	dec e: push de	// #ffff
	inc de: push de	// #0000
	ld d,c: dec e: push de	// #e0ff
	jp (hl)

gg_bolt_fon_phase_04
  if high(gg_bolt_fon_phase_05) == high(gg_bolt_fon_phase_04)
	ld lx,low(gg_bolt_fon_phase_05)
  else
	ld ix,gg_bolt_fon_phase_05
  endif
	ld bc,#f07f
	ld de,#f0ff: push de	// #f0ff
	ld d,c: inc e: push de	// #7f00
	ld d,e: ld e,b: push de	// #00f0
	dec d: ld e,c: push de	// #ff7f
	inc d: ld e,d: push de	// #0000
	ld d,b: dec e: push de	// #f0ff
	ld d,c: inc e: push de	// #7f00
	ld d,e: push de	// #0000
	ld e,c: push de	// #007f
	ld e,d: push de	// #0000
	ld d,b: dec e: push de	// #f0ff
	ld d,c: inc e: push de	// #7f00
	ld d,e: ld e,b: push de	// #00f0
	dec d: ld e,c: push de	// #ff7f
	inc d: ld e,d: push de	// #0000
	ld d,b: dec e: push de	// #f0ff
	jp (hl)

gg_bolt_fon_phase_03
  if high(gg_bolt_fon_phase_04) == high(gg_bolt_fon_phase_03)
	ld lx,low(gg_bolt_fon_phase_04)
  else
	ld ix,gg_bolt_fon_phase_04
  endif
	ld bc,#f83f
	ld de,#f8ff: push de	// #f8ff
	ld d,c: inc e: push de	// #3f00
	ld d,e: ld e,b: push de	// #00f8
	dec d: ld e,c: push de	// #ff3f
	inc d: ld e,d: push de	// #0000
	ld d,b: dec e: push de	// #f8ff
	ld d,c: inc e: push de	// #3f00
	dec e: ld d,e: push de	// #ffff
	ld d,e: ld e,c: push de	// #ff3f
	inc d: ld e,d: push de	// #0000
	ld d,b: dec e: push de	// #f8ff
	ld d,c: inc e: push de	// #3f00
	ld d,e: ld e,b: push de	// #00f8
	dec d: ld e,c: push de	// #ff3f
	inc d: ld e,d: push de	// #0000
	ld d,b: dec e: push de	// #f8ff
	jp (hl)

gg_bolt_fon_phase_02
  if high(gg_bolt_fon_phase_03) == high(gg_bolt_fon_phase_02)
	ld lx,low(gg_bolt_fon_phase_03)
  else
	ld ix,gg_bolt_fon_phase_03
  endif
	ld bc,#fc1f
	ld de,#fcff: push de	// #fcff
	ld d,c: inc e: push de	// #1f00
	ld d,e: ld e,b: push de	// #00fc
	dec d: ld e,c: push de	// #ff1f
	inc d: ld e,d: push de	// #0000
	ld d,b: dec e: push de	// #fcff
	ld d,c: inc e: push de	// #1f00
	dec e: ld d,e: push de	// #ffff
	ld d,e: ld e,c: push de	// #ff1f
	inc d: ld e,d: push de	// #0000
	ld d,b: dec e: push de	// #fcff
	ld d,c: inc e: push de	// #1f00
	ld d,e: ld e,b: push de	// #00fc
	dec d: ld e,c: push de	// #ff1f
	inc d: ld e,d: push de	// #0000
	ld d,b: dec e: push de	// #fcff
	jp (hl)

gg_bolt_fon_phase_01
  if high(gg_bolt_fon_phase_02) == high(gg_bolt_fon_phase_01)
	ld lx,low(gg_bolt_fon_phase_02)
  else
	ld ix,gg_bolt_fon_phase_02
  endif
	ld bc,#fe0f
	ld de,#feff: push de	// #feff
	ld d,c: inc e: push de	// #0f00
	ld d,e: ld e,b: push de	// #00fe
	dec d: ld e,c: push de	// #ff0f
	inc d: ld e,d: push de	// #0000
	ld d,b: dec e: push de	// #feff
	ld d,c: inc e: push de	// #0f00
	ld d,e: push de	// #0000
	ld e,c: push de	// #000f
	ld e,d: push de	// #0000
	ld d,b: dec e: push de	// #feff
	ld d,c: inc e: push de	// #0f00
	ld d,e: ld e,b: push de	// #00fe
	dec d: ld e,c: push de	// #ff0f
	inc d: ld e,d: push de	// #0000
	ld d,b: dec e: push de	// #feff
	jp (hl)

gg_bolt_fon_phase_00
  if high(gg_bolt_fon_phase_01) == high(gg_bolt_fon_phase_00)
	ld lx,low(gg_bolt_fon_phase_01)
  else
	ld ix,gg_bolt_fon_phase_01
  endif
	ld bc,#0700
	ld de,#ffff: push de	// #ffff
	push bc	// #0700
	inc d: push de	// #00ff
	dec d: ld e,b: push de	// #ff07
	inc d: ld e,d: push de	// #0000
	dec de: push de	// #ffff
	push bc	// #0700
	inc de: push de	// #0000
	ld e,b: push de	// #0007
	ld e,d: push de	// #0000
	dec de: push de	// #ffff
	push bc	// #0700
	inc d: push de	// #00ff
	dec d: ld e,b: push de	// #ff07
	inc d: ld e,d: push de	// #0000
	dec de: push de	// #ffff
	jp (hl)

//	include "_gg_bolt_fon_phases.a80"


gg_bolt_init
	ld hl,gg_bolt_fon_phase_27
	ld (_gg_bolt_fon_current_phase),hl

  if high(_gg_bolt_phase_step) == high(gg_bolt_fon_phase_27)
	ld l,low(_gg_bolt_phase_step)
  else
	ld hl,_gg_bolt_phase_step
  endif
	ld (hl),39

  if high(_gg_bolt_phase_anim) == high(_gg_bolt_phase_step)
	ld l,low(_gg_bolt_phase_anim)
  else
	ld hl,_gg_bolt_phase_anim
  endif
	ld (hl),27

  if high(gg_bolt_phases_atr) == high(_gg_bolt_phase_anim)
	ld l,low(gg_bolt_phases_atr)
  else
	ld hl,gg_bolt_phases_atr
  endif
	ld (_gg_bolt_current_phase_atr),hl
  if high(gg_bolt_phases_atr) != high(gg_bolt_phases_atr_end-1)
	ld (_gg_bolt_current_phase_atr2),hl
  endif

  if high(gg_bolt_phases) == high(gg_bolt_phases_atr)
	ld l,low(gg_bolt_phases)
  else
	ld hl,gg_bolt_phases
  endif
	ld (_gg_bolt_current_phase_1),hl
//	ld (_gg_bolt_current_phase_2),hl

  if high(gg_flash_blink_state_1) == high(gg_bolt_phases)
	ld l,low(gg_flash_blink_state_1)
  else
	ld hl,gg_flash_blink_state_1
  endif
	ld (_gg_flash_blink_sector),hl

	ld a,17
	ld (_gg_flash_cnt1),a
	ld (_gg_flash_cnt2),a
	dec a
	ld (_gg_flash_cnt1_1),a
	ld (_gg_flash_cnt2_2),a

	ld hl,#5770
	ld (_gg_bolt_words_adr),hl


	ret

gg_bolt_words
	incbin "_gg_bolt_words.bin"
gg_bolt_words_end

gg_atr1
	incbin "_gg_bolt_atr1.bin"
gg_atr2
	incbin "_gg_bolt_atr2.bin"

	assert( $ < $be00 )
	SAVEBIN "gg_bolt.bin", effect_start, $-effect_start
