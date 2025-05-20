@echo off
call clean.bat
sjasmplus -DVERSION_FOR_LOCAL_DEBUG=0 ..\code\main.asm

upkr --z80 sup_main.bin

sjasmplus --lst --sld ..\code\kickstart\kickstart2.asm
zx2 -z -x kickstart2.bin

sjasmplus ..\code\kickstart\kickstart.asm

sjasmplus -DKICKSTART_IN_NEX --lst --sld ..\code\kickstart\kickstart.asm
sjasmplus -DVERSION_FOR_LOCAL_DEBUG=1 --lst --sld ..\code\main.asm

