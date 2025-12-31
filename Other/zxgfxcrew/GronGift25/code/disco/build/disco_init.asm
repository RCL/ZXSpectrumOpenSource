

disco_init:
;
; fix bg image
;
        ld a, 042o
        ld (#5aeb), a
        ld (#5aec), a

;
; re-init runtime data
;
        ld hl, balls_data
        ld de, balls_runtime
        ld bc, balls_data_length
        ldir

;
; init balls 64x64
;
        ld b, BALL64_COUNT
        ld de, balls64
.put64_loop:
        push bc

        ld a, (de)
        inc e
        rlca : rlca : rlca : ld l, a
        ld a, (de)
        inc e
        add a, 2 : ld h, a
        push de

        call coords_to_screen_addr
        ld hl, circle64
        call put_sprite_64

        pop de
        pop bc
        djnz .put64_loop

;
; init balls 32x32
;
        ld b, BALL32_COUNT
        ld de, balls32
.put32_loop:
        push bc

        ld a, (de)
        inc e
        rlca : rlca : rlca : ld l, a
        ld a, (de)
        inc e
        add a, 3 : ld h, a
        push de

        call coords_to_screen_addr
        ld hl, circle32
        call put_sprite_32

        pop de
        pop bc
        djnz .put32_loop

;
; init balls 16x16
;
        ld b, BALL16_COUNT
        ld de, balls16
.put16_loop:
        push bc

        ld a, (de)
        inc e
        rlca : rlca : rlca : ld l, a
        ld a, (de)
        inc e
        add a, 4 : ld h, a
        push de

        call coords_to_screen_addr
        ld hl, circle16
        call put_sprite_16

        pop de
        pop bc
        djnz .put16_loop

        ret


