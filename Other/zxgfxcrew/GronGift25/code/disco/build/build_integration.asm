        device  zxspectrum128

BORDER_PROFILING EQU 0
STANDALONE_BUILD EQU 0
IM2_MODE	 EQU 1

        org #8000
__entry_point:
	jp disco_init
	assert( $ == $8003)
	halt
	jp disco_thread_tick

        include "main.asm"
        display "Code length: ", /D, $-__entry_point, " (", $-__entry_point, ")", " bytes"


        if _ERRORS == 0
            savebin "../output.bin", __entry_point, $-__entry_point
            ;savetap "bin/output.tap", __entry_point
            ;labelslist "bin/user.l"
            ;labelslist "../../bin/unreal-0.37.9-ts/user.l"
            ;bplist "../../bin/unreal-0.37.9-ts/bpx.ini" unreal
        endif
