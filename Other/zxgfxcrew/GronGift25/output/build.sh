#!/bin/bash
./clean.sh
pushd ../code
sjasmplus --lst --sld --fullpath ../code/main.asm
pushd kickstart
sjasmplus loader_kickstart.asm
popd
popd

cat ../res/loader/loader.tap > grongift25.tap
cat page1.tap >> grongift25.tap
cat page3.tap >> grongift25.tap
cat page4.tap >> grongift25.tap
cat page6.tap >> grongift25.tap
cat page7.tap >> grongift25.tap
cat page0.tap >> grongift25.tap
cat kernel.tap >> grongift25.tap

