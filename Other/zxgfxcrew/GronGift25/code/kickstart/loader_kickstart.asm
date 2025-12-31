	device zxspectrum48

	org $8000

	ld hl, data
	ld de, $5b00
	push de
	ld bc, data_size
	di
	ldir
	ret
data:
	incbin "../../output/kernel.bin"
data_size equ $-data	

	SAVETAP "../../output/kernel.tap", CODE, "kernel", $8000, $-$8000
	SAVEBIN "../../output/kickstart.bin", $8000, $-$8000