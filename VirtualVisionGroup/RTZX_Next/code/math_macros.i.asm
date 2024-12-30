; ------------------------------------------------------------------------------------------------------------
; part of RTZX Next, intended to be included into main.asm and uses variables and constants from there.

	; hl = de * bc
	macro SMUL16
		call smul16
	endm

	; hl = hl / bc
	macro SDIV16
		call sdiv16
	endm

	; hl = hl * hl
	macro SSQUARE16
		if 0
			call ssquare16
		else
			bit 7, h
			jr z, .SQ16_NoInvert
			ld de, 0
			ex de, hl
			or a
			sbc hl, de
.SQ16_NoInvert:
			ld a, h
			and a
			jr nz, .SQ16_16bit
			
			; 8-bit case
			ex de, hl
			ld d, e
			mul
			; de holds 2.14, and we need 2.7
			ld b, 7
			bsrl de, b
			ex de, hl
			jp .SQ16_done
.SQ16_16bit:
			; 16-bit case
			; (256p + q)^2 = 65536p^2 + 512pq + q^2

			ld c, l
			push hl

			; 2*pq
			xor a
			ex de, hl
			mul
			ex de, hl
			add hl, hl
			adc a, a			
			; a:hl is now 2*pq

			ld e, c
			ld d, c
			mul			; q^2

			ld b, a
			ld c, h
			
			ld a, d		;  HSB of q^2
			add l		;  LSB of pq
			ld h, a
			ld l, e
			; essentially bc:hl is now 512*pq + q^2

			pop de
			ld e, d
			mul
			; de = p^2
			ex de, hl	; now, hl-p^2
			adc hl, bc	; hl += carry and the upper part of 512*pq + q^2

			; hl:de is now 65536p^2 + 512pq + q^2

			; hl:de holds 18.14 product
			; we only need a middle 9.7 part
			; shift everything 1 left and take l, d
			ex de, hl
			add hl, hl
			rl e
			ld l, h
			ld h, e
.SQ16_done:
		endif
	endm

	; hl = sin(a)
	macro SSIN16
		ld h, high SinTab
		ld l, a
		ld e, (hl)
		inc h
		ld d, (hl)
		ex de, hl
	endm

	; hl = cos(a)
	macro SCOS16
		ld h, high CosTab
		ld l, a
		ld e, (hl)
		inc h
		ld d, (hl)
		ex de, hl
	endm

	macro SMUL16_INTEGER_ONLY
		SMUL16
		add hl, hl
		ld a, h
	endm

	; hl = de * DIR_LIGHT_Z (-73 atm)
	macro SMUL16_DIR_LIGHT_Z
		if (0)
			ld bc, DIR_LIGHT_Z
			SMUL16
		else
			; we will mul by 73 and reverse.  (256a + b) = 73a << 8 + 73b
			ld b, d
			bit 7, d		
			jr z, .SmDlZ_PositiveDE
			xor a
			ld h, a
			ld l, a
			sbc hl, de
			ex de, hl
.SmDlZ_PositiveDE:
			ld c, e
			ld e, -DIR_LIGHT_Z
			mul
			ex de, hl
			ld d, c
			ld e, -DIR_LIGHT_Z
			mul
			ld a, h
			ld h, l
			ld l, 0
			add hl, de
			adc a, 0
			; a:hl is the 24-bit result (10.14). We need 9.7 from it. Shift 1 times left and take a, h
			add hl, hl
			adc a, 0		; a:hl is now 9.15
			ld l, h
			ld h, a
			; if d was positive, we need to invert
			bit 7, b
			jr nz, .SmDlZ_NoInvertResult
			ld de, 0
			ex de, hl
			or a
			sbc hl, de
.SmDlZ_NoInvertResult:
		endif
	endm

	macro SMUL16_DIR_LIGHT_Y
		if (0)
			ld bc, DIR_LIGHT_Y
			SMUL16
		else
			; we will mul by 73.  (256a + b) = 73a << 8 + 73b
			ld b, d
			bit 7, d		
			jr z, .SmDlY_PositiveDE
			xor a
			ld h, a
			ld l, a
			sbc hl, de
			ex de, hl
.SmDlY_PositiveDE:
			ld c, e
			ld e, DIR_LIGHT_Y
			mul
			ex de, hl
			ld d, c
			ld e, DIR_LIGHT_Y
			mul
			ld a, h
			ld h, l
			ld l, 0
			add hl, de
			adc a, 0
			; a:hl is the 24-bit result (10.14). We need 9.7 from it. Shift 1 times left and take a, h
			add hl, hl
			adc a, 0		; a:hl is now 9.15
			ld l, h
			ld h, a
			; if d was negative, we need to invert
			bit 7, b
			jr z, .SmDlY_NoInvertResult
			ld de, 0
			ex de, hl
			or a
			sbc hl, de
.SmDlY_NoInvertResult:
		endif
	endm

	; hl = de * DIR_LIGHT_X (which is the same as DIR_LIGHT_Z)
	macro SMUL16_DIR_LIGHT_X
		SMUL16_DIR_LIGHT_Z
	endm

	; hl = de * DIR_LIGHT_A (246 atm)
	macro SMUL16_DIR_LIGHT_A
		; dir light is 246
		if (1)	; not sure why the optimized version is turned off (is it buggy?), but oh well, I didn't notice that until after making the final release
			ld bc, DIR_LIGHT_A
			SMUL16
		else
			; we will mul by 246.  (256a + b) = 246a << 8 + 246b
			ld b, d
			bit 7, d		
			jr z, .SmDlA_PositiveDE
			xor a
			ld h, a
			ld l, a
			sbc hl, de
			ex de, hl
.SmDlA_PositiveDE:
			ld c, e
			ld e, DIR_LIGHT_A
			mul
			ex de, hl
			ld d, c
			ld e, DIR_LIGHT_A
			mul
			ld a, h
			ld h, l
			ld l, 0
			add hl, de
			adc a, 0
			; a:hl is the 24-bit result (10.14). We need 9.7 from it. Shift 1 times left and take a, h
			add hl, hl
			adc a, 0		; a:hl is now 9.15
			ld l, h
			ld h, a
			; if d was negative, we need to invert
			bit 7, b
			jr z, .SmDlA_NoInvertResult
			ld de, 0
			ex de, hl
			or a
			sbc hl, de
.SmDlA_NoInvertResult:
		endif
	endm

