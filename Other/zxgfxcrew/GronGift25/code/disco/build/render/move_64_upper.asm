
; In:
;   HL = diff data
;   E = line number
;   A = x offset
move_64_upper_v2:
        ;ld (.xoff4), a
	ld iyl, a	;	iyl == xoff4
        inc a
        ;ld (.xoff2), a
	ld iyh, a	;	iyh == xoff2
        inc a
	ld ixl, a	;	ixl == xoff1
        ;ld (.xoff1), a
        add a, 4
        ;ld (.xoff3), a
	ld ixh, a	;	ixh == xoff3
        inc a
        ;ld (.xoff5), a
	ex af, af'	; a' == xoff5


        ld d, high scr_addr_table       ; DE = ptr to table

        ld (.saved_sp), sp
        di
        ld sp, hl                       ; SP = diff data

        ex de, hl                       ; HL = ptr to table

;
; top diff
;
	DUP 6
        ld d, (hl)                      ; read screen address from table
        inc h
        ld a, (hl)
        dec h
        add ixl				; xoff1
        ld e, a                         ; DE = target screen addr

        pop bc
        ld a, (de) : xor c : ld (de), a : inc e
        ld a, (de) : xor b : ld (de), a : inc e
        pop bc
        ld a, (de) : xor c : ld (de), a : inc e
        ld a, (de) : xor b : ld (de), a

        inc l                           ; next line
	EDUP

;
; left-mid diff
;
        dec l

        DUP 4
        ld d, (hl)                      ; read screen address from table
        inc h
        ld a, (hl)
        add iyh				; xoff2
        ld e, a                         ; DE = target screen addr

        pop bc
        ld a, (de) : xor c : ld (de), a 

        inc l                           ; next line

        ld a, (hl)                      ; read screen address from table
        add iyh				; xoff2
        ld e, a
        dec h
        ld d, (hl)                      ; DE = target screen addr

        ld a, (de) : xor b : ld (de), a 

        inc l                           ; next line
	EDUP
;
; right-mid diff
;
        ld a, l
        sub 8
        ld l, a

        DUP 4
        ld d, (hl)                      ; read screen address from table
        inc h
        ld a, (hl)
        add ixh				; xoff3
        ld e, a                         ; DE = target screen addr

        pop bc
        ld a, (de) : xor c : ld (de), a 

        inc l                           ; next line

        ld a, (hl)                      ; read screen address from table
        add ixh				; xoff3
        ld e, a
        dec h
        ld d, (hl)                      ; DE = target screen addr

        ld a, (de) : xor b : ld (de), a 

        inc l                           ; next line
	EDUP

;
; left-side diff
;
        dec l
        dec l

	DUP 9
        ld d, (hl)                      ; read screen address from table
        inc h
        ld a, (hl)
        add iyl				; xoff4
        ld e, a                         ; DE = target screen addr

        pop bc
        ld a, (de) : xor c : ld (de), a 

        inc l                           ; next line

        ld a, (hl)                      ; read screen address from table
        add iyl				; xoff4
        ld e, a
        dec h
        ld d, (hl)                      ; DE = target screen addr

        ld a, (de) : xor b : ld (de), a 

        inc l                           ; next line
	EDUP

;
; right-side diff
;
        ld a, l
        sub 18
        ld l, a


	ex af, af'
        ld ixl, a
	DUP 9
        ld d, (hl)                      ; read screen address from table
        inc h
        ld a, (hl)
	add ixl
        ld e, a                         ; DE = target screen addr

        pop bc
        ld a, (de) : xor c : ld (de), a 

        inc l                           ; next line

        ld a, (hl)                      ; read screen address from table
        add ixl
        ld e, a
        dec h
        ld d, (hl)                      ; DE = target screen addr

        ld a, (de) : xor b : ld (de), a 

        inc l                           ; next line
	EDUP


.saved_sp: equ $+1
        ld sp, 0
        ei
        ret

