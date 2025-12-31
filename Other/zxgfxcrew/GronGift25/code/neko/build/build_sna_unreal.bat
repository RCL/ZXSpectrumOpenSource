echo off

cd /D %~dp0
if not exist "bin" mkdir "bin"
if exist "bin\output.sna" del "bin\output.sna"
if exist "bin\output.sld.txt" del "bin\output.sld.txt"

..\..\bin\sjasmplus-1.18.2.win\sjasmplus --fullpath --msg=war build_sna.asm

if exist "bin\output.sna" (
    start "UnrealSpeccy" ..\..\bin\us035b2-bin-p1\unreal.exe -i pentagon.ini -d bin\output.sna
    resize_unreal_sna.bat
)

echo on

