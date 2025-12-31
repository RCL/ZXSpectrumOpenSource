; This file is to be included in the engine

	MODULE gg_bolt

runtime_address equ $8000

init	equ $8000
im2tick	equ $8003

code_packed:
	incbin "gg_bolt.bin.zx0"

	ENDMODULE
