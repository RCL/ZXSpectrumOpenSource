del /Q snownonono.sna snownonono.bin snownonono_main.bin snownonono_main.sna snownonono_main.bin.upk snownonono_main.bin.zx0 snownonono_main.bin.zx2 snownonono.tap snownonono_codeonly_24576.tap
sjasmplus --lst --sld ..\code\main.asm

rem Uncomment for faster iteration
rem exit 0

upkr --z80 snownonono_main.bin
zx0 snownonono_main.bin
zx2 snownonono_main.bin

sjasmplus --lst --sld ..\code\kickstart\kickstart.asm

copy /B ..\loader\basic_loader.tap + /B snownonono_codeonly_24576.tap snownonono.tap
