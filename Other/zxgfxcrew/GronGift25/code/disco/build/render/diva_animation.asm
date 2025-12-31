

diva_animation:
        ld (.saved_sp), sp
        di
        ld sp, hl
        ex de, hl

        ld bc, #0307
.loop:
        pop de : ld (hl), e : inc l : ld (hl), d : inc l
        pop de : ld (hl), e
        inc h

        ld (hl), d : dec l
        pop de : ld (hl), e : dec l : ld (hl), d
        inc h

        pop de : ld (hl), e : inc l : ld (hl), d : inc l
        pop de : ld (hl), e
        inc h

        ld (hl), d : dec l
        pop de : ld (hl), e : dec l : ld (hl), d
        inc h

        pop de : ld (hl), e : inc l : ld (hl), d : inc l
        pop de : ld (hl), e
        inc h

        ld (hl), d : dec l
        pop de : ld (hl), e : dec l : ld (hl), d
        inc h

        pop de : ld (hl), e : inc l : ld (hl), d : inc l
        pop de : ld (hl), e
        inc h

        ld (hl), d : dec l
        pop de : ld (hl), e : dec l : ld (hl), d

        ; down_hl+
        ld a, h
        and #f8
        ld h, a
        ld a, l
        sub #e0
        ld l, a

        djnz .loop

.end:
.saved_sp: equ $+1
        ld sp, 0
        ei
        ret


