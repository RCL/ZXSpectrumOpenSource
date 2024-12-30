del rtzx_next.nex rtzx_main_next.nex rtzx_main_next.bin rtzx_main_next.bin.zx0 rtzx_main_next.bin.upk  rtzx_next_music.bin rtzx_next_music.bin.zx0 rtzx_next_music.bin.upk
; invoking with --fullpath breaks breakpoints because the path is relative to this folder
sjasmplus --lst --sld ..\code\main.asm

rem uncomment for fast iteration
rem exit 0

rem Compress ZX0 only, UPKR doesn't seem worth it given that .nex size is the same
zx0 rtzx_main_next.bin
rem upkr --z80 rtzx_main_next.bin
zx0 rtzx_next_music.bin
rem upkr --z80 rtzx_next_music.bin

rem 
sjasmplus --lst --sld ..\code\kickstart\kickstart.asm
