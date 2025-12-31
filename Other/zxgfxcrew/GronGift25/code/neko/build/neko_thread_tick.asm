




neko_thread_tick:
        xor a : out (254), a    ; DO NOT REMOVE

;
; check J+V keys
;
        call check_hotkeys

.counter16: equ $+1
        ld hl, 1
        dec hl
        ld (.counter16), hl
        ld a, h
        or l
        ret nz

;
; process_next_command
;
.scenario_ptr: equ $+1
        ld hl, scenario
        ld a, (hl)
        dec a           ; cp 1
        jr z, .c_wait
        dec a
        jr z, .c_move_cat_up
        dec a
        jr z, .c_move_iris_up
        dec a
        jr z, .c_stop
        dec a
        jr z, .c_animate_cat

        ld a, 3
        out (254), a
        ret


.c_wait:
.move_to_next_step:
        inc hl
        inc hl
        ld e, (hl) : inc hl
        ld d, (hl) : inc hl
        ld (.scenario_ptr), hl
        ld (.counter16), de
        ret


.c_move_cat_up:
        call .move_to_next_step
        ld hl, (cat_pos)
        ld de, -#0800
        add hl, de
        ld (cat_pos), hl
        jp print_cat


.c_move_iris_up:
        call .move_to_next_step
        ld hl, (iris_pos)
        ld de, -#0800
        add hl, de
        ld (iris_pos), hl
        jp print_iris


.cmd_clear:
        call .move_to_next_step
        jp clear_screen


.c_stop:
        ;ld a, 4 : out (254), a
        ret


.c_animate_cat:
        call .move_to_next_step
        ld hl, cat_sprite
        inc (hl)
        call print_cat
        ret


print_iris:
        ld hl, (iris_pos)
        call coords_to_screen_addr
        ; DE = screen addr
        ld hl, IRIS_BUFFER_ADDR
        jp render_iris


print_cat:
        ld a, (cat_sprite)
        add a, a
        ld l, a
        ld h, high neko_images          ; HL = pointer to 'neko_images' array item

        ld a, (hl) : inc l
        ld h, (hl) : ld l, a            ; HL = address of packed image

        ld de, CAT_BUFFER_ADDR
        call zx0v1.depacker

        halt

        ld hl, (cat_pos)
        call coords_to_screen_addr
        ; DE = screen addr
        ld hl, CAT_BUFFER_ADDR
        jp render_neko


check_hotkeys:
.glitch_flag: equ $+1
        ld a, 1
        and a
        ret z

;
; press J+V to remove glitch (depack iris sprite again)
;
        ; check J key
        ld a, #bf
        in a, (#fe)
        bit 3, a
        ret nz

        ; check V key
        ld a, #fe
        in a, (#fe)
        bit 4, a
        ret nz

        ld a, 7 : out (254), a
;
; depack and render iris
;
        ld hl, iris_pak
        ld de, IRIS_BUFFER_ADDR
        call zx0v1.depacker

        call print_iris

        xor a
        ld (.glitch_flag), a
        ret


