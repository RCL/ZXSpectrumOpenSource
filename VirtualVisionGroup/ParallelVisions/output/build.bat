@echo off
call clean.bat
sjasmplus --lst --sld ..\code\main.asm

rem Uncomment for faster iteration
rem exit 0

rem upkr --z80 parallelvisions_main.bin
zx0 parallelvisions_main.bin
rem zx2 parallelvisions_main.bin
rem zx5 parallelvisions_main.bin

sjasmplus --lst --sld ..\code\kickstart\kickstart.asm

copy /B ..\loader\basic_loader.tap + /B parallelvisions_codeonly_24576.tap parallelvisions.tap
