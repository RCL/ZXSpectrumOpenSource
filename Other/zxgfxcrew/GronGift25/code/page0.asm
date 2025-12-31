	slot 3
	page 0

	org $C000
page0_start:

; --- keep music here so it is always in the fast memory

	include "music/music.asm"

PAGE0_SIZE EQU $ - page0_start
	SAVETAP "../output/page0.tap", CODE, "page0", page0_start, PAGE0_SIZE
	SAVEBIN "../output/page0.bin", page0_start, PAGE0_SIZE
