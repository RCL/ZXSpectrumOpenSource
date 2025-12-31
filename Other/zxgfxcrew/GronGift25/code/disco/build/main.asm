

        define  BALL64_COUNT  2
        define  BALL32_COUNT  4
        define  BALL16_COUNT  6


        include "disco_init.asm"
        include "disco_thread_tick.asm"

        include "render/coords_to_screen_addr.asm"
        include "render/put_sprite_64.asm"
        include "render/put_sprite_32.asm"
        include "render/put_sprite_16.asm"

        include "render/move_64_upper.asm"
        include "render/move_64_lower.asm"
        include "render/move_32_upper.asm"
        include "render/move_32_lower.asm"
        include "render/move_16_upper.asm"
        include "render/move_16_lower.asm"

        include "render/render_overlay.asm"
        include "render/diva_animation.asm"


        align 256
scr_addr_table:
        include "render/screen_address_table.asm"


        align 16
balls_runtime:
balls64:  block 8
balls32:  block 8
balls16:  block 16


balls_data:
.b64:
        db 16, 150
        db 21, 10
        db 0, 0
        db 0, 0
.b32:
        db 15, 140
        db 19, 9
        db 27, 100
        db 24, 180
.b16:
        db 14, 0
        db 18, 112
        db 21, 56
        db 24, 175
        db 27, 41
        db 30, 139
balls_data_length: equ $-balls_data



circle64:       incbin "graphics/circle64.spr"
circle32:       incbin "graphics/circle32.spr"
circle16:       incbin "graphics/circle16.spr"

c64diff_1:      incbin "graphics/circle64_diff_1.xor"
c64diff_2L:     incbin "graphics/circle64_diff_2L.xor"
c64diff_2R:     incbin "graphics/circle64_diff_2R.xor"
c64diff_3L:     incbin "graphics/circle64_diff_3L.xor"
c64diff_3R:     incbin "graphics/circle64_diff_3R.xor"

c32diff_1:      incbin "graphics/circle32_diff_1.xor"
c32diff_2:      incbin "graphics/circle32_diff_2.xor"

c16diff:        incbin "graphics/circle16_diff.xor"

diva_sprites:   incbin "graphics/diva_sprites.spr"


