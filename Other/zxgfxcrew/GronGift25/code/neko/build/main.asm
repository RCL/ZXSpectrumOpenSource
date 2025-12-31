


        ;define  CAT_SCR_ADDR           #4841
        ;define  IRIS_SCR_ADDR          #400f

        define  CAT_BUFFER_ADDR         #aa00
        define  IRIS_BUFFER_ADDR        #b000

        define  IRIS_GLITCH_1_OFFSET    1872
        define  IRIS_GLITCH_2_OFFSET    3168
        define  IRIS_GLITCH_LENGTH      16*2*9

        define CAT_SPRITES_COUNT 32


        include "neko_init.asm"
        include "neko_thread_tick.asm"

        include "render/coords_to_screen_addr.asm"
        include "render/render_iris.asm"
        include "render/render_neko.asm"
        include "render/add_glitches.asm"

        module zx0v1
depacker: include "zx0v1/dzx0_turbo.asm"
        endmodule


iris_pos:       dw #c078        ; L = x, H = y

cat_pos:        dw #c010        ; L = x, H = y
cat_sprite:     db 0


cmd_wait                equ 1
cmd_move_cat_up         equ 2
cmd_move_iris_up        equ 3
cmd_stop                equ 4
cmd_animate_cat         equ 5

speed                   equ 8


scenario:
        dw cmd_move_iris_up, speed
        dw cmd_move_iris_up, speed
        dw cmd_move_iris_up, speed
        dw cmd_move_iris_up, speed
        dw cmd_move_iris_up, speed
        dw cmd_move_iris_up, speed
        dw cmd_move_iris_up, speed
        dw cmd_move_iris_up, speed
        dw cmd_move_iris_up, speed
        dw cmd_move_iris_up, speed
        dw cmd_move_iris_up, speed
        dw cmd_move_iris_up, speed
        dw cmd_move_iris_up, speed
        
        dw cmd_wait, speed * 8

        dw cmd_move_cat_up, speed-1
        dw cmd_move_cat_up, speed-1
        dw cmd_move_cat_up, speed-1
        dw cmd_move_cat_up, speed-1
        dw cmd_move_cat_up, speed-1
        dw cmd_move_cat_up, speed-1
        dw cmd_move_cat_up, speed-1
        dw cmd_move_cat_up, speed-1
        dw cmd_move_cat_up, speed-1
        dw cmd_move_cat_up, speed-1
        dw cmd_move_cat_up, speed-1
        dw cmd_move_cat_up, speed-1
        dw cmd_move_cat_up, speed-1

        dw cmd_wait, speed * 8

        dw cmd_move_iris_up, speed
        dw cmd_move_iris_up, speed
        dw cmd_move_iris_up, speed
        dw cmd_move_iris_up, speed
        dw cmd_move_iris_up, speed
        dw cmd_move_iris_up, speed
        dw cmd_move_iris_up, speed
        dw cmd_move_iris_up, speed
        dw cmd_move_iris_up, speed
        dw cmd_move_iris_up, speed
        dw cmd_move_iris_up, speed

        dw cmd_wait, speed * 20

        dup 24
          dw cmd_animate_cat, 1
        edup
        dup 7
          dw cmd_animate_cat, 4
        edup

        dw cmd_stop, 0


        align 256
neko_images:
        dw a0
        dw a3, d1, a4, a1, a2, blk, a5, blk
        dw a4, a2, blk, a5
        dw a4, a2, blk, a5
        dw a4, a2, blk, a5
        dw a4, a2, blk, a5
        dw a4, d1, d2, d3, d4, d5, blk


iris_pak:  incbin "graphics/iris.spr.zx0"

a0:     incbin "graphics/0.spr.zx0"
a1:     incbin "graphics/1.spr.zx0"
a2:     incbin "graphics/2.spr.zx0"
a3:     incbin "graphics/3.spr.zx0"
a4:     incbin "graphics/4.spr.zx0"
a5:     incbin "graphics/5.spr.zx0"
d1:     incbin "graphics/d1.spr.zx0"
d2:     incbin "graphics/d2.spr.zx0"
d3:     incbin "graphics/d3.spr.zx0"
d4:     incbin "graphics/d4.spr.zx0"
d5:     incbin "graphics/d5.spr.zx0"
blk:    incbin "graphics/blk.spr.zx0"

        db #ff


