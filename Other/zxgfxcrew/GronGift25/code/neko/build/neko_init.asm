

neko_init:
        ld hl, scenario
        ld (neko_thread_tick.scenario_ptr), hl
        ld hl, 1
        ld (neko_thread_tick.counter16), hl

;
; clear screen
;
        call clear_screen

;
; depack iris sprite
;
        ld hl, iris_pak
        ld de, IRIS_BUFFER_ADDR
        call zx0v1.depacker

;
; add some glitches to depacked sprite
;
        jp add_glitches


clear_screen:
        ld hl, #5800
        ld de, #5801
        ld bc, #02ff
        ld (hl), #47
        ldir
        ret



