echo off

cd /D %~dp0
if not exist "bin" mkdir "bin"
if exist "bin\output.sna" del "bin\output.sna"
if exist "bin\output.sld.txt" del "bin\output.sld.txt"

rem ..\..\bin\sjasmplus-1.18.2.win\sjasmplus --fullpath --sld=bin\output.sld.txt --msg=war build_sna.asm
..\..\bin\sjasmplus-1.18.2.win\sjasmplus --fullpath --msg=war build_sna.asm

if exist "bin\output.sna" (
    start "UnrealSpeccy" ..\..\bin\unreal-0.37.9-ts\unreal.exe bin\output.sna
    resize_unreal_ts_sna.bat
)

echo on

