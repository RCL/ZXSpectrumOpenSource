@echo off
call clean.bat
sjasmplus --lst --sld ..\code\main.asm

rem Uncomment for faster iteration
rem exit 0

rem upkr --z80 anaglyph_main.bin
zx0 anaglyph_main.bin
rem zx2 anaglyph_main.bin
rem zx5 anaglyph_main.bin

sjasmplus --lst --sld ..\code\kickstart\kickstart.asm

copy /B ..\loader\basic_loader.tap + /B anaglyph_codeonly_24576.tap anaglyph.tap
