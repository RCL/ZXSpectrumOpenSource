del /Q snownononext.dot snownononext.nex snownononext_main.bin snownononext_main.nex snownononext_main.bin.upk snownononext_main.bin.zx0
sjasmplus --lst --sld ..\code\main.asm

rem Uncomment for faster iteration
rem exit 0

rem upkr --z80 snownonono_main.bin
zx0 snownononext_main.bin

sjasmplus --lst --sld ..\code\kickstart\kickstart.asm
