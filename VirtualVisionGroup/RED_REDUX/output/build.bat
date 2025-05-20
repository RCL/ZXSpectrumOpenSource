@echo off
call clean.bat
sjasmplus --lst ..\code\main.asm

zx0 redredux_main.bin
zx2 -y -z -x redredux_main.bin

sjasmplus -DPRODUCE_ZX_NEXT_DOT_FILE=1 ..\code\kickstart\kickstart.asm

sjasmplus -DPRODUCE_ZX_NEXT_DOT_FILE=0 --lst ..\code\kickstart\kickstart.asm

copy /B ..\loader\basic_loader.tap + /B redredux_codeonly_32768.tap redredux.tap
