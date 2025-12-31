echo off

cd /D %~dp0
if not exist "bin" mkdir "bin"
if exist "..\output.bin" del "..\output.bin"
if exist "..\output.bin.zx0" del "..\output.bin.zx0"
if exist "..\output.sld.txt" del "..\output.sld.txt"

sjasmplus --lst --fullpath --msg=war build_integration.asm 

zx0 ..\output.bin
