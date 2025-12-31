

put_sprite_32:
        ld b, 32
.loop:
        ld c, h
        push de

        ld a, (de) : xor (hl) : ld (de), a
        inc hl : inc e
        ld a, (de) : xor (hl) : ld (de), a
        inc hl : inc e
        ld a, (de) : xor (hl) : ld (de), a
        inc hl : inc e
        ld a, (de) : xor (hl) : ld (de), a
        inc hl

        pop de

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

        cp #58
        ret z

        ld d, a
.down_de_end:

        djnz .loop
        ret


