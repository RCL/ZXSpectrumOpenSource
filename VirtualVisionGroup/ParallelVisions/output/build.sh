#!/bin/sh
./clean.sh

sjasmplus --lst --sld ../code/main.asm

zx0 parallelvisions_main.bin

sjasmplus --lst --sld ../code/kickstart/kickstart.asm

cat ../loader/basic_loader.tap > parallelvisions.tap
cat parallelvisions_codeonly_24576.tap >> parallelvisions.tap

