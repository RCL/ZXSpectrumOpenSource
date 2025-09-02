#!/bin/sh
./clean.sh

sjasmplus --lst --sld ../code/main.asm

zx0 anaglyph_main.bin

sjasmplus --lst --sld ../code/kickstart/kickstart.asm

cat ../loader/basic_loader.tap > anaglyph.tap
cat anaglyph_codeonly_24576.tap >> anaglyph.tap

