@echo off
call clean.bat
pushd ..\code
rem dir
sjasmplus --lst --sld --fullpath main.asm
pushd kickstart
sjasmplus loader_kickstart.asm
sjasmplus trd_builder.asm
popd
popd

copy /B ..\res\loader\loader.tap + page1.tap + page3.tap + page4.tap + page6.tap + page7.tap + page0.tap + kernel.tap   grongift25.tap

