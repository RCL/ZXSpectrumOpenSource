
; In:
;   HL = diff data
;   E = line number
;   A = x offset
move_16_lower_v2:
	ld ixl, a

        ld d, high scr_addr_table       ; DE = ptr to table

        ld (.saved_sp), sp
        di
        ld sp, hl                       ; SP = diff data

        ex de, hl                       ; HL = ptr to table

;
; bottom diff
;
        DUP 5
        ld d, (hl)                      ; read screen address from table
        inc h
        ld a, (hl)
	add ixl				; xoff1
        ld e, a                         ; DE = target screen addr

        pop bc
        ld a, (de) : xor c : ld (de), a : inc e
        ld a, (de) : xor b : ld (de), a

        dec l                           ; next line

        ld a, (hl)                      ; read screen address from table
	add ixl				; xoff2
        ld e, a                         ; DE = target screen addr
        dec h
        ld d, (hl)

        pop bc
        ld a, (de) : xor c : ld (de), a : inc e
        ld a, (de) : xor b : ld (de), a

        dec l                           ; next line
	EDUP

.saved_sp: equ $+1
        ld sp, 0
        ei
        ret


