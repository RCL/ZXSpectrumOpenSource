; this file is included in both kickstart.asm and kickstart_at_0.asm so we have the same offsets

CompressedMainCode:
	incbin "../../output/sup_main.bin.upk"
MusicRegs6_13Packed:
	incbin "../../res/regs6-13.bin.upk"
MusicTonesPacked:
	incbin "../../res/tonesABC.bin.upk"
