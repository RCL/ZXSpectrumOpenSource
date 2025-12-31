

disco_thread_tick:
        if (BORDER_PROFILING)
            ld a, 1 : out (254), a
        endif

        ld hl, balls16 + 0
        call move_16x16
        ld hl, balls16 + 2
        call move_16x16

        ld hl, balls32 + 0
        call move_32x32
        ld hl, balls32 + 2
        call move_32x32


        if (BORDER_PROFILING)
            ld a, 2 : out (254), a
        endif
        call render_overlay


        if (BORDER_PROFILING)
            ld a, 1 : out (254), a
        endif

        ld hl, balls16 + 4
        call move_16x16
        ld hl, balls16 + 6
        call move_16x16
        ld hl, balls16 + 8
        call move_16x16
        ld hl, balls16 + 10
        call move_16x16

        ld hl, balls32 + 4
        call move_32x32
        ld hl, balls32 + 6
        call move_32x32

        ld hl, balls64 + 2
        call move_64x64
        ld hl, balls64 + 0
        call move_64x64


        if (BORDER_PROFILING)
            ld a, 3 : out (254), a
        endif

.anim_counter: equ $+1
        ld a, 0
        inc a
        and %00001111
        ld (.anim_counter), a

        jr z, .left_eye1
        cp 1
        jr z, .right_eye1
        cp 8
        jr z, .left_eye2
        cp 9
        ret nz
.right_eye2:
        ld hl, diva_sprites + 72 * 3
        ld de, #48a7
        jp diva_animation

.left_eye2:
        ld hl, diva_sprites + 72 * 2
        ld de, #48a1
        jp diva_animation

.right_eye1:
        ld hl, diva_sprites + 72 * 1
        ld de, #48a7
        jp diva_animation

.left_eye1:
        ld hl, diva_sprites + 72 * 0
        ld de, #48a1
        jp diva_animation




move_16x16:
        ld d, (hl) : inc l
        ld e, (hl)
        push hl

        push de
        ld a, d
        ld hl, c16diff
        push hl
        call move_16_upper_v2

        pop hl,de
        ld a, e
        add a, 16+3
        ld e, a
        ld a, d
        call move_16_lower_v2

        pop hl
        ld a, (hl)
        sub 4
        ld (hl), a
        ret


move_32x32:
        ld d, (hl) : inc l
        ld e, (hl)
        push hl

        push de
        ld a, d
        ld hl, c32diff_1
        push hl
        call move_32_upper_v2

        pop hl,de
        ld a, e
        add a, 32+2
        ld e, a
        ld a, d
        call move_32_lower_v2

        pop hl
        ld a, (hl)
        sub 3
        ld (hl), a
        ret


move_64x64:
        ld d, (hl) : inc l
        ld e, (hl)
        push hl

        push de
        ld a, d
        ld hl, c64diff_1
        push hl
        call move_64_upper_v2

        pop hl,de
        ld a, e
        add a, 64+1
        ld e, a
        ld a, d
        call move_64_lower_v2

        pop hl
        ld a, (hl)
        sub 2
        ld (hl), a
        ret


