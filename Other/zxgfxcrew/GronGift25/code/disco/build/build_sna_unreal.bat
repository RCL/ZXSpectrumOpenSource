echo off

cd /D %~dp0
if not exist "bin" mkdir "bin"
if exist "bin\output.sna" del "bin\output.sna"
if exist "bin\output.sld.txt" del "bin\output.sld.txt"

sjasmplus --fullpath --msg=war build_sna.asm
exit

if exist "bin\output.sna" (
    start "UnrealSpeccy" ..\..\bin\us035b2-bin-p1\unreal.exe -i pentagon-14mhz.ini -d bin\output.sna
    resize_unreal_sna.bat
)

echo on

