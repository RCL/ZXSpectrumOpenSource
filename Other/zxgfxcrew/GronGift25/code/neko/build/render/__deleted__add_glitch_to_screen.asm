

; In:
;   HL = source bytes
;   DE = target screen address
add_glitch_to_screen:
        ld b, 2
.outer_loop:
        push bc

        push de

        ; de_to_attrs
        ld a, d
        and #18
        rrca 
        rrca
        rrca
        or #58
        ld d, a

        dup 15
          ldi
        edup

        pop de

        ld b, 8
.loop:
        ld a, e
        ld c, #ff
        dup 15
          ldi
        edup
        ld e, a

        ; down_de+
        inc d
        ld a, d
        and 7
        jr nz, .down_de_end
        ld a, e
        sub #e0
        ld e, a
        sbc a, a
        and #f8
        add a, d
        ld d, a
.down_de_end:

        djnz .loop

        pop bc
        djnz .outer_loop

        ret