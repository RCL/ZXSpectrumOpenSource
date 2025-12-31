	device ZXSPECTRUM128

SCROLL_HEIGHT equ 18
SCROLL_WIDTH equ 24

LEFT_PRINT_POSITION  equ (32 * 256 + 22)
RIGHT_PRINT_POSITION  equ ((32+80) * 256 + 22)

	include "../../kernel_exports.inc"

    org #8000
effect_start

    jp scroll_init
    jp scroll_de_lines
    jp print_next_greeting
    ; another entry point right here
invert_font_in_de
    ex de, hl
    ld bc, 3584 ;   // hardcoded value for the font size
.inv_loop
    ld a, (hl)
    cpl
    ld (hl), a
    inc hl
    dec bc
    ld a, b
    or c
    jp nz, .inv_loop
    ret

print_next_greeting
    push de
    ex de, hl
    ld a, (hl)
    inc hl
    ld h, (hl)
    ld l, a
    or h
.greeting_pos equ $+1
    jp z, .first
    jp (hl)

    MACRO PRINT_LINE  TextParm
        pop de
        ld hl, TextParm
        ld a, $47
        push de
        call kernel_print_im2
        ld de, 16
        call scroll_de_lines
    ENDM

.first
; -----------------
.nodeus
    ld de, LEFT_PRINT_POSITION
    push de
    PRINT_LINE Nodeus
    PRINT_LINE Nodeus.l1
    PRINT_LINE Nodeus.l2
    PRINT_LINE Nodeus.l3
    PRINT_LINE Nodeus.l4
    pop de

    ld hl, .uris
    ld (.greeting_pos),hl
    jp .common_exit

; -----------------
.uris
    ld de, LEFT_PRINT_POSITION
    push de
    PRINT_LINE UriS
    PRINT_LINE UriS.l1
    PRINT_LINE UriS.l2
    PRINT_LINE UriS.l3
    PRINT_LINE UriS.l4
    PRINT_LINE UriS.l5
    PRINT_LINE UriS.l6
    PRINT_LINE UriS.l7
    PRINT_LINE UriS.l8
    PRINT_LINE UriS.l9
    pop de

    ld hl, .niko
    ld (.greeting_pos),hl
    jp .common_exit

; -----------------
.niko
    ld de, (72*256) + 22
    push de
    PRINT_LINE NikO
    PRINT_LINE NikO.l1
    PRINT_LINE NikO.l2
    PRINT_LINE NikO.l3
    PRINT_LINE NikO.l4
    PRINT_LINE NikO.l5
    PRINT_LINE NikO.l6
    PRINT_LINE NikO.l7
    pop de  ; right texts need to start earlier
    ld a, d
    sub 8
    ld d, a
    push de
    PRINT_LINE NikO.l8
    pop de

    ld hl, .moroz1999
    ld (.greeting_pos),hl
    jp .common_exit

; -----------------
.moroz1999
    ld de, LEFT_PRINT_POSITION
    push de
    PRINT_LINE Moroz1999
    PRINT_LINE Moroz1999.l1
    PRINT_LINE Moroz1999.l2
    PRINT_LINE Moroz1999.l3
    PRINT_LINE Moroz1999.l4
    PRINT_LINE Moroz1999.l5
    PRINT_LINE Moroz1999.l6
    pop de

    ld hl, .arttop
    ld (.greeting_pos),hl
    jp .common_exit

; -----------------
.arttop
    ld de, (80*256) + 22
    push de
    PRINT_LINE Arttop
    PRINT_LINE Arttop.l1
    PRINT_LINE Arttop.l2
    pop de  ; right texts need to start earlier
    ld a, d
    sub 8
    ld d, a
    push de
    PRINT_LINE Arttop.l3
    pop de

    ld hl, .joev
    ld (.greeting_pos),hl
    jp .common_exit

; -----------------
.joev
    ld de, LEFT_PRINT_POSITION
    push de
    PRINT_LINE JoeV
    PRINT_LINE JoeV.l1
    PRINT_LINE JoeV.l2
    PRINT_LINE JoeV.l3
    pop de

    ld hl, .rcl
    ld (.greeting_pos),hl
    jp .common_exit

; -----------------
.rcl
    ld de, (88*256) + 22
    push de
    PRINT_LINE RCL
    PRINT_LINE RCL.l1
    PRINT_LINE RCL.l2
    PRINT_LINE RCL.l3
    PRINT_LINE RCL.l4
    PRINT_LINE RCL.l5
    PRINT_LINE RCL.l6
    pop de  ; right texts need to start earlier
    ld a, d
    sub 8
    ld d, a
    push de
    PRINT_LINE RCL.l7
    pop de

    ld hl, .lemic
    ld (.greeting_pos),hl
    jp .common_exit

; -----------------
.lemic
    ld de, (64*256) + 22
    push de
    PRINT_LINE LeMIC
    PRINT_LINE LeMIC.l1
    PRINT_LINE LeMIC.l2
    PRINT_LINE LeMIC.l3
    PRINT_LINE LeMIC.l4
    PRINT_LINE LeMIC.l5
    PRINT_LINE LeMIC.l6
    PRINT_LINE LeMIC.l7
    PRINT_LINE LeMIC.l8
    PRINT_LINE LeMIC.l9
    PRINT_LINE LeMIC.l10
    pop de  ; right texts need to start earlier
    ld a, d
    sub 8
    ld d, a
    push de
    PRINT_LINE LeMIC.l11
    pop de

    ld hl, .sq
    ld (.greeting_pos),hl
    jp .common_exit

; -----------------
.sq
    ld de, LEFT_PRINT_POSITION
    push de
    PRINT_LINE Sq
    PRINT_LINE Sq.l1
    PRINT_LINE Sq.l2
    PRINT_LINE Sq.l3
    PRINT_LINE Sq.l4
    PRINT_LINE Sq.l5
    PRINT_LINE Sq.l6
    PRINT_LINE Sq.l7
    PRINT_LINE Sq.l8
    PRINT_LINE Sq.l9
    PRINT_LINE Sq.l10
    PRINT_LINE Sq.l11
    PRINT_LINE Sq.l12
    PRINT_LINE Sq.l13
    PRINT_LINE Sq.l14
    PRINT_LINE Sq.l15
    PRINT_LINE Sq.l16
    PRINT_LINE Sq.l17
    PRINT_LINE Sq.l18
    PRINT_LINE Sq.l19
    pop de

    ld hl, .gogin
    ld (.greeting_pos),hl
    jp .common_exit

; -----------------
.gogin
    ld de, (40      *256) + 22
    push de
    PRINT_LINE Gogin
    PRINT_LINE Gogin.l1
    PRINT_LINE Gogin.l2
    PRINT_LINE Gogin.l3
    PRINT_LINE Gogin.l4
    PRINT_LINE Gogin.l5
    PRINT_LINE Gogin.l6
    pop de  ; right texts need to start earlier
    ld a, d
    sub 8
    ld d, a
    push de
    PRINT_LINE Gogin.l7
    pop de

    ld hl, .uris
    ld (.greeting_pos),hl
    jp .common_exit



.common_exit
    ; store persistent state
    pop de
    ld hl, (.greeting_pos)
    ex de, hl
    ld (hl), e
    inc hl
    ld (hl), d
    ret

    include "win1251_texts.txt"

Text:
    db "TEST1234567890", 0

scroll_de_lines
    ld a, d
    or e
    ret z

    halt

    push de
    di
    call scroll_up
    ei
    pop de
    dec de
    jr scroll_de_lines

lowpix	 INC H
	 LD A,H
	 AND #07
	 RET NZ
	 LD A,L
	 ADD A,#20
	 LD L,A
	 RET C
	 LD A,H
	 SUB #08
	 LD H,A
	 RET

; ----------------------------------------------
; inits the scroll
scroll_init:
    ld b, SCROLL_HEIGHT*8
    ld hl, $4000 + (24-SCROLL_HEIGHT)*$20 + $10
    ld ix, scroll_line_begin

.loop
    push hl
    ld (ix + offset_to_dst1), l
    ld (ix + offset_to_dst1 + 1), h

    ld de, 12
    add hl, de
    ld (ix + offset_to_dst2), l
    ld (ix + offset_to_dst2 + 1), h
    pop hl

    call lowpix

    push hl
    ld (ix + offset_to_src2), l
    ld (ix + offset_to_src2 + 1), h
    ld de, -12
    add hl, de
    ld (ix + offset_to_src1), l
    ld (ix + offset_to_src1 + 1), h
    pop hl

    ld de, scroll_line_size
    add ix, de
    djnz .loop

    ; set 0s as the source for the last line
    ld de, -scroll_line_size
    add ix, de
    ld hl, empty_zeroes
    ld (ix + offset_to_src2), l
    ld (ix + offset_to_src2 + 1), h
    ld (ix + offset_to_src1), l
    ld (ix + offset_to_src1 + 1), h

    ; also fill the attributes with a random color
    ld hl, $5800 + (24-SCROLL_HEIGHT)*$20 + (32-SCROLL_WIDTH) / 2
    ld b, SCROLL_HEIGHT
    ld a, $47
attr_clear:
    push bc

    ld d, h
    ld e, l
    inc de
    ld (hl), a
    ld bc, SCROLL_WIDTH-1
    ldir  

    ld de, 32-SCROLL_WIDTH + 1
    add hl, de

    pop bc
    djnz attr_clear

    ret



; ----------------------------------------------
; scroll_up
scroll_up
    ld (scroll_up_save_sp), sp

    MACRO PopBytes
        ld sp, $0000
        pop hl
        pop de
        pop bc
        exx
        pop hl
        pop de
        pop bc
    ENDM

    MACRO PushBytes
        ld sp, $0000
        push bc
        push de
        push hl
        exx
        push bc
        push de
        push hl
    ENDM

scroll_line_begin:
offset_to_src1 equ $+1 - scroll_line_begin
    PopBytes
offset_to_dst1 equ $+1 - scroll_line_begin
    PushBytes
offset_to_src2 equ $+1 - scroll_line_begin
    PopBytes
offset_to_dst2 equ $+1 - scroll_line_begin
    PushBytes
scroll_line_size equ $-scroll_line_begin

    DISPLAY "scroll_line_begin is ", /A, scroll_line_begin
    DISPLAY "offset_to_src1 is ", /A, offset_to_src1
    DISPLAY "offset_to_src2 is ", /A, offset_to_src2
    DISPLAY "offset_to_dst1 is ", /A, offset_to_dst1
    DISPLAY "offset_to_dst2 is ", /A, offset_to_dst2
    DISPLAY "scroll_line_size is ", /A, scroll_line_size

    DUP SCROLL_HEIGHT*8 - 1
        PopBytes
        PushBytes
        PopBytes
        PushBytes
    EDUP

scroll_up_save_sp equ $+1
    ld sp, 0
    ret

empty_zeroes
    ds 16, 0

    ;SAVESNA "telegron.sna", #8000

    SAVEBIN "../telegron.bin", effect_start, $-effect_start

            
