

add_glitches:
        ld hl, IRIS_BUFFER_ADDR + IRIS_GLITCH_1_OFFSET
        ld de, IRIS_BUFFER_ADDR + IRIS_GLITCH_1_OFFSET + 1
        ld bc, IRIS_GLITCH_LENGTH - 1
        ld (hl), %00001001
        ldir

        ld hl, IRIS_BUFFER_ADDR + IRIS_GLITCH_2_OFFSET
        ld de, IRIS_BUFFER_ADDR + IRIS_GLITCH_2_OFFSET + 1
        ld bc, IRIS_GLITCH_LENGTH - 1
        ld (hl), %00010010
        ldir

        ld a, 1
        ld (check_hotkeys.glitch_flag), a

        ret
        