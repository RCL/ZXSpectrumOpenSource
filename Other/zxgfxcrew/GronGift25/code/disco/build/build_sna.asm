

        device  zxspectrum128


BORDER_PROFILING EQU 1
STANDALONE_BUILD EQU 1
IM2_MODE	 EQU 0

        org #4000
        incbin "materials/disco_fix4.scr"


        org #8000
__entry_point:

        xor a : out (254), a
        call disco_init

demo_loop:
        ei
        halt

        ld a, 1 : out (254), a
        call disco_thread_tick
        xor a : out (254), a

        jr demo_loop

        include "main.asm"
        display "Code length: ", /D, $-__entry_point, " (", $-__entry_point, ")", " bytes"


        if _ERRORS == 0
            savesna "bin/output.sna", __entry_point
            ;savetap "bin/output.tap", __entry_point
            ;labelslist "bin/user.l"
            ;labelslist "../../bin/unreal-0.37.9-ts/user.l"
            ;bplist "../../bin/unreal-0.37.9-ts/bpx.ini" unreal
        endif


