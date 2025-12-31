; Thanks to Art-top for the example
	device zxspectrum128

	org 23867
clear	equ #6000
              
Basic	dw #100, EndBasic-Begin

Begin
	db #e7, #c3, #a7, #3a   ; or => db #e7, #c3, #a7, #3a - border not pi
	db #d9, #c3, #a7, #3a   ; or => db #d9, #c3, #a7, #3a - ink not pi
	db #da, #c3, #a7, #3a   ; or => db #da, #c3, #a7, #3a - paper not pi
	dw #30fd, #e: db 00: dw clear: db 00
	db #3a, #f9, #c0, #30: dw #e: db #00: dw Start: db #00, #3a ; randomize usr 0
	db #ea ; rem

Start
	res 4,(iy+1)
	ld hl,#c9f1
	ld (#5cc2), hl	; disable break

	; -------------------
	; load page 1
	ld a, 17
	call page_switch

	ld hl, $c000
	ld b, high (page1_len + 255)
	call load_file

	; -------------------
	; load page 3
	ld a, 19
	call page_switch

	ld hl, $c000
	ld b, high (page3_len + 255)
	call load_file

	; -------------------
	; load page 4
	ld a, 20
	call page_switch

	ld hl, $c000
	ld b, high (page4_len + 255)
	call load_file

	; -------------------
	; load page 6
	ld a, 22
	call page_switch

	ld hl, $c000
	ld b, high (page6_len + 255)
	call load_file

	; -------------------
	; load page 7
	ld a, 23
	call page_switch

	ld hl, $db00
	ld b, high (page7_len + 255)
	call load_file

	; -------------------
	; load page 0
	ld a, 16
	call page_switch

	ld hl, $c000
	ld b, high (page0_len + 255)
	call load_file

	; -------------------
	; load kickstart
	ld hl, $8000
	push hl
	ld b, high (kickstart_len + 255)
	; intentional fall-through
load_file:
	ld de,(#5cf4)
	ld c,5
	jp #3d13

page_switch
	ld bc, $7ffd
	ld ($5b5c), a	; BANKM
	out (c), a
	ret

	display 'Basic end: ', $

EndBasic

	define TRD_FILENAME "../../output/grongift25.trd"

	; -- saving Basic
	emptytrd TRD_FILENAME, "Grongi25"
	savetrd TRD_FILENAME, "Grongi25.B", Basic, EndBasic-Basic

	org #6000
page1_start
	incbin "../../output/page1.bin"
page1_len equ $-page1_start

	savetrd TRD_FILENAME, &"Grongi25.B", #6000, page1_len


	org #6000
page3_start
	incbin "../../output/page3.bin"
page3_len equ $-page3_start

	savetrd TRD_FILENAME, &"Grongi25.B", #6000, page3_len

	org #6000
page4_start
	incbin "../../output/page4.bin"
page4_len equ $-page4_start

	savetrd TRD_FILENAME, &"Grongi25.B", #6000, page4_len


	org #6000
page6_start
	incbin "../../output/page6.bin"
page6_len equ $-page6_start

	savetrd TRD_FILENAME, &"Grongi25.B", #6000, page6_len

	org #6000
page7_start
	incbin "../../output/page7.bin"
page7_len equ $-page7_start

	savetrd TRD_FILENAME, "Grongi25.C", #6000, page7_len

	org #6000
page0_start
	incbin "../../output/page0.bin"
page0_len equ $-page0_start

	savetrd TRD_FILENAME, &"Grongi25.C", #6000, page0_len

	org #6000
kickstart_start
	incbin "../../output/kickstart.bin"
kickstart_len equ $-kickstart_start

	savetrd TRD_FILENAME, &"Grongi25.C", #6000, kickstart_len
