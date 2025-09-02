    device ZXSPECTRUM128


; desktop - 8
; projector - 32?
EYE_OFFSET              EQU 8
RIGHT_EYE_OP            EQU 0x52        ; sbc
LEFT_EYE_OP             EQU 0x5a        ; adc

USE_70CYCLE_PLOT        EQU 1
USE_RAXOFT_RANDOM       EQU 0

; how many particles are there
NUM_PARTICLES           EQU 5

; how long traces they leave (in terms of previous positions). Each position needs space for NUM_PARTICLES triplets
TRAIL_LENGTH            EQU 15

; length of history in triplets of (ScrX, ScrY, Size)
HISTORY_LENGTH          EQU TRAIL_LENGTH * NUM_PARTICLES

; what is the size of a particle in 3D (will be perspectively smaller)
PARTICLE_SIZE           EQU 4 * 256

NO_MUSIC                EQU 0
PROFILE_FRAME           EQU 0

    STRUCT  Particle
AddX        dw 0
X           dw 0
AddY        dw 0
Y           dw 0
AddZ        dw 0
Z           dw 0
    ENDS

    ; pages in a 128K page that is in the A register
    MACRO SetPageInA
        ld ($5b5c), a   ; BANKM
        ld bc, #7ffd
        out (c), a
    ENDM

    ; HL - location
    ; IX - mask for first and for second
    MACRO InitFP88WithMaskInline
        call rnd_trampo
        and ixh
        ld b, a
        call rnd_trampo
        and ixl
        sub b
        ld (hl), a
        inc hl
        sbc a, a
        ld (hl), a
        inc hl
    ENDM

    ; Inits a particle. HL - pointer to the current particle structure
    ; Made a macro so exact same code can be used twice and compress better
    ; Keeps HL and B intact

    MACRO InitAddXandX
        ; AddX
        ld ix, $0703
        InitFP88WithMaskInline
        ; X
        ;ld ix, $ffff
        ;InitFP88WithMaskInline
        inc hl      ; always start at 0
        inc hl
    ENDM

    MACRO InitAddYandY
        InitAddXandX
    ENDM

    MACRO InitAddZandZ
        InitAddXandX
    ENDM

    MACRO InitParticle
        InitAddXandX
        InitAddYandY
        InitAddZandZ
    ENDM

    ; hl - pointer to AddX followed by X
    MACRO UpdateAxisAndReverse
        ld c, (hl)
        inc hl
        ld b, (hl)
        inc hl
        ld e, (hl)
        inc hl
        ld d, (hl)

        ex de, hl
        add hl, bc      ; X += AddX
        ex de, hl
        ; write it back
        ld (hl), d
        dec hl
        ld (hl), e

        ; if axis isn't 0 or 0xff, we got out of the unit cube
        ld a, d
        and a
        jr z, .NoReversal
        cp $ff
        jr z, .NoReversal
        ; reverse bc
        ex de, hl
        ld hl, 0
        or a
        sbc hl, bc
        ex de, hl

        ; write inverted increment
        dec hl
        ld (hl), d
        dec hl
        ld (hl), e
        inc hl
        inc hl
.NoReversal
        inc hl
        inc hl
    ENDM

    MACRO PlotInlineable
        call XorPlotRoutine_trampo
    ENDM

    MACRO JmpPlotInlineable
        jp XorPlotRoutine
    ENDM

    ; in D, E - X and Y of the central point
    ; A - size
    MACRO PlotSizeInlineable
        call PlotSizeRoutine_trampo
    ENDM

    MACRO InitPlotRoutine
        if (USE_70CYCLE_PLOT)
            LD HL,PTY   ;   table location
            LD DE,#C000 ;   main screen
            LD BC,#C020
CR1
            LD (HL),D
            DEC H
            LD (HL),E
            INC L
            INC H
            INC D
            LD A,D
            AND 7
            JR NZ,$+12
            LD A,E
            SUB #E0
            LD E,A
            JR NC,$+6
            LD A,D
            SUB 8
            LD D,A
            DJNZ CR1
            LD L, #FF
            DEC H  
            DEC H
CR3         DEC C
            LD B,8
CR2         LD (HL),C
            DEC L
            DJNZ CR2
            INC C
            DEC C
            JR NZ,CR3
            DEC H
            INC A
CR4         LD (HL),A
            RLCA 
            DEC L
            DJNZ CR4
        endif
    ENDM

    ; expects ix set to the right trampoline
    MACRO DrawCubeFourAxes
        ld hl, -256
.DrawLoop:
        ld de, -256
        ld bc, -256
        push hl
        call PermuteTrampoline
        pop hl

        ld de, -256
        ld bc, 256
        push hl
        call PermuteTrampoline
        pop hl

        ld de, 256
        ld bc, -256
        push hl
        call PermuteTrampoline
        pop hl

        ld de, 256
        ld bc, 256
        push hl
        call PermuteTrampoline
        pop hl

        inc hl
        ld a, h
        dec a       ; same as CP 1
        jr nz, .DrawLoop
    ENDM

    ; Draws a cube
    MACRO DrawCube
        ld ix, Permute_XYZ_XYZ
        DrawCubeFourAxes

        ld ix, Permute_XYZ_YXZ
        DrawCubeFourAxes

        ld ix, Permute_XYZ_ZYX
        DrawCubeFourAxes
    ENDM


    org #80ff

savebin_begin:

    InitPlotRoutine

    xor a
    out (#fe), a

    MACRO SetPageFillScreenAndDrawCube Page, ColorValue
        ld a, Page
        SetPageInA

        ld a, ColorValue
        ld bc, 6144
        ld hl, #c000
        ld d, h
        ld e, l
        inc e
        ld (hl), l; $aa ;l
        ldir
        ld bc, 767
        ld (hl), a
        ldir

        DrawCube
    ENDM

    SetPageFillScreenAndDrawCube $15, $42

    ld a, RIGHT_EYE_OP
    ld (EyeOp), a
    
    SetPageFillScreenAndDrawCube $1f, $41

    ld hl, ParticleBuffer
    if (1)
    DUP NUM_PARTICLES
        InitParticle
    EDUP
    else
    ld b, NUM_PARTICLES * 3
InitLoop:
        InitAddXandX
        djnz InitLoop
    endif   

    if (!NO_MUSIC)
    ; we know that in our track the whole value of reg 13 is 0x0C
    ld a, 13
    ld bc, #fffd
    out (c), a
    dec a
    ld b, #bf
    out (c), a
    ; and we know that the register 11 is all 1f
    dec a
    ld bc, #fffd
    out (c), a
    ld a, $1f
    ld b, #bf
    out (c), a
    endif

    ; -------------------------------
    ; main loop
main_loop:
    ei          ; not really needed, but keeping as last-ditch reserve
    halt

    if (PROFILE_FRAME)
        ld a, 1
        out (#fe), a
    endif

EyeShown equ $+1
    ; bit 4 - rom select, 3 - normal/shadow screen, 0-2 page. $1d is showing right eye, drawing left, $17 is showing left eye, drawing right
    ld a, $1d
    xor $0a
    ld (EyeShown), a
    SetPageInA

    and $08         ; if zero we're showing left eye (0x4000), drawing right, and vice versa
    jp z, RenderingRightEye

    ; update the particles when drawing left eye only
    ld hl, ParticleBuffer
    DUP NUM_PARTICLES
        DUP 3
            UpdateAxisAndReverse
        EDUP
    EDUP

    ld de, HistoryLeft
    ld a, LEFT_EYE_OP
    jr MoveHistory

RenderingRightEye:
    ld de, HistoryRight
    ld a, RIGHT_EYE_OP

MoveHistory:
    ld (EyeOp), a
    push de
    ld h, d
    ld l, NUM_PARTICLES * 3
    ld bc, (HISTORY_LENGTH - NUM_PARTICLES) * 3
    ldir

    ; -------------------------------
    ; music update
    if (!NO_MUSIC)
        if (PROFILE_FRAME)
            ld a, 2
            out (#fe), a
        endif

		MACRO UpdateRegInAFromHLAdvanceA
			ld bc, #fffd
			out (c), a
			ex af, af'
			ld a, (hl)
			ld b, #bf
			out (c), a
			ex af, af'
			inc a
		ENDM

		MACRO AyTwoRegUpdate
			UpdateRegInAFromHLAdvanceA
			inc hl
			UpdateRegInAFromHLAdvanceA
			dec hl

			add hl, de
			add hl, de
		ENDM

		MACRO AyOneRegUpdate
			UpdateRegInAFromHLAdvanceA
			add hl, de
		ENDM

MusicPos equ $+1
		ld hl, -1
		ld de, RegisterFileLength
		inc hl
		xor a
		sbc hl, de
		add hl, de
		jr c, NoMusicReset

		ld hl, -1
NoMusicReset:
		ld (MusicPos), hl
		push hl

		; set AY regs   
		; xor a - relying on the code in the subtraction

		; first all the pairs
		add hl, hl  ; multiply by 2
		ld de, MusicRegPairs
		add hl, de

		ld de, RegisterFileLength
		DUP 2
			AyTwoRegUpdate
		EDUP
		inc a
		inc a
		AyTwoRegUpdate

		pop hl
		ld de, MusicRegs
		add hl, de

		ld de, RegisterFileLength
		DUP 2
			AyOneRegUpdate
		EDUP
    endif // NO_MUSIC

    if (PROFILE_FRAME)
        ld a, 3
        out (#fe), a
    endif

    ; clear the trail tails from history
    pop hl
    push hl
    MACRO PlotHistory
        ld e, (hl)
        inc hl
        ld d, (hl)
        inc hl
        ld a, (hl)
        inc hl
        push hl
        call PlotSizeRoutine_trampo
        pop hl
    ENDM
    DUP NUM_PARTICLES
        PlotHistory
    EDUP

    if (PROFILE_FRAME)
        ld a, 4
        out (#fe), a
    endif

    ; project and draw the particles, and put their history into ix
    ;pop ix
    ;ld ixl, HISTORY_LENGTH * 3 - 1

    ld hl, ParticleBuffer
    ld (NextSP), hl
    pop hl
    ld l, HISTORY_LENGTH * 3 - 1
    MACRO ProjectAndDrawParticle
        push hl
        ld (SavedSP), sp
        ld sp, (NextSP)

        pop bc
        pop bc

        pop de
        pop de

        pop hl
        pop hl

        ld (NextSP), sp
        ld sp, (SavedSP)

        call Project_trampo

        pop hl
        ; save history
        ld (hl), a
        dec hl
        ld (hl), d
        dec hl
        ld (hl), e
        dec hl
        push hl     

        PlotSizeInlineable
        pop hl
    ENDM

    DUP NUM_PARTICLES
        ProjectAndDrawParticle
    EDUP

    ; ---------------
    ; end of main loop
    if (PROFILE_FRAME)
        xor a
        out (#fe), a
    endif

    jp main_loop

; Helper function to jump one on the permute functions
PermuteTrampoline:
    jp (ix)

; Helper function to permute XYZ to XYZ
Permute_XYZ_XYZ:
    call Project_trampo
    jp PlotSizeRoutine_trampo

; Helper function to permute XYZ to YXZ
Permute_XYZ_YXZ:
    ex de, hl
    call Project_trampo
    jp PlotSizeRoutine_trampo

; Helper function to permute XYZ to ZYX
Permute_XYZ_ZYX:
    ld a, h
    ld h, b
    ld b, a
    ld a, l
    ld l, c
    ld c, a
    call Project_trampo
    ; intentional fall-through to PlotSizeRoutine

PlotSizeRoutine:
    and a
    ret z
    dec a
    jr nz, .LargerThan1     // size is larger than one

    JmpPlotInlineable

.LargerThan1
    dec a
    jr nz, .LargerThan2     // size is larger than 2

	push de
	PlotInlineable
	
	pop de
	inc d
	push de
	PlotInlineable
	
	pop de
	inc e
	push de
	PlotInlineable
	
	pop de
	dec d
	JmpPlotInlineable

.LargerThan2
	; +1, 0
	inc d
	push de
	PlotInlineable

	; +1, +1
	pop de
	inc e
	push de
	PlotInlineable

	; 0, +1
	pop de
	dec d
	push de
	PlotInlineable

	; -1, +1
	pop de
	dec d
	push de
	PlotInlineable

	; -1, 0
	pop de
	dec e
	push de
	PlotInlineable

	; -1, -1
	pop de
	dec e
	push de
	PlotInlineable

	; -1, +1
	pop de
	inc d
	JmpPlotInlineable

; ---------------------------------------------------
; Projects a 3D point
; takes
;   HL - x
;   DE - y
;   BC - z
; returns (data suitable for Plot right away)
;   if C is not set
;   D,E - screen x, screen y
;   A - size
;   should never project offscreen in this demo
CosA    EQU $f1 ;219
SinA    EQU $56 ;131
OffsetZ EQU 524
Project:
    ; calc TZ = -X*SinA + Z*CosA + OffsetZ
    ; -X*SinA
    push hl
    exx
    pop de
    ld hl, 0
    or a
    sbc hl, de
    ex de, hl
    ld bc, SinA
    call smul16_trampo
    push hl
    exx

    ; Z*CosA
    push bc
    exx
    pop de
    ld bc, CosA
    call smul16_trampo
    pop de
    add hl, de  ; hl = -X*SinA + Z*CosA 
    ld bc, OffsetZ
    add hl, bc  ; hl = -X*SinA + Z*CosA + OffsetZ == TZ
    push hl
    exx

    ; Calc TX = X*CosA + Z*SinA + EyeOffset
    ; X*CosA
    push hl
    exx
    pop de
    ld bc, CosA
    call smul16_trampo
    push hl
    exx

    ; Z*SinA
    push bc
    exx
    pop de
    ld bc, SinA
    call smul16_trampo
    ; hl = Z*SinA
    pop de
    add hl, de  ; hl = X*CosA + Z*SinA == TX
    ld de, EYE_OFFSET
    or a
EyeOp EQU $+1
    adc hl, de      ; cannot use add because that is just one byte, and sbc is two bytes

    ; Calc ScrX = 128 + (int)(128 * (TX / TZ))
    ex de, hl
    pop bc  ; pop 1st push of TZ
    push bc
    call sdiv16_trampo
    ; hl now contains TX / TZ in 8.8. We need to mul it by 128 and turn into integer
    ; this is essentially shifting it right 1 position and treating as an integer
    sra h
    rr l
    ld de, 128
    add hl, de
    ; should be safe to take just l
    ld a, l
    ex af, af'

    ; now calculate ScrY = 96 + (int)(64 * (Y / TZ)
    exx ; back to our input values
    push de
    exx
    pop de
    pop bc  ; pop 2nd push of TZ
    push bc
    call sdiv16_trampo
    ; hl now contains TY / TZ in 8.8. We need to mul it by 64 and turn into integer
    ; this is essentially shifting it right 2 positions and treating as an integer
    sra h
    rr l
    sra h
    rr l
    ld a, l
    add 96
    exx ; back to our input values
    ld e, a     ; this is ScrY
    ex af, af'
    ld d, a     ; this is ScrX

    ; the only thing left is to calculate size
    exx
    ld de, PARTICLE_SIZE
    pop bc  ; pop 3rd pushing of TZ
    call sdiv16_trampo
    ld a, h
    exx
    ret

; ---------------------------------------------------
; Xorshift algo by raxoft (Patrik Rak), from https://gist.github.com/raxoft/c074743ea3f926db0037
; corrupts hl' and de', but not bc
; returns random A
rnd:
        exx

        if (USE_RAXOFT_RANDOM)
.seed1 equ $+1
        ld  hl, 0xA280   ; yw -> zt
.seed2 equ $+1
        ld  de, 0xC0DE   ; xz -> yw
        ld  (.seed2),hl  ; x = y, z = w
        ld  a,l         ; w = w ^ ( w << 3 )
        add a,a
        add a,a
        add a,a
        xor l
        ld  l,a
        ld  a,d         ; t = x ^ (x << 1)
        add a,a
        xor d
        ld  h,a
        rra             ; t = t ^ (t >> 1) ^ w
        xor h
        xor l
        ld  h,e         ; y = z
        ld  l,a         ; w = t
        ld  (.seed1),hl

        else
        
        ; tolerable random
.rand_seed equ $+1
        ld      hl, 10569
        ld      a, r
        ld      d, a
        ld      e, (hl)
        add     hl, de
        add     a, l
        xor     h
        srl     h
        srl     h
        ld (.rand_seed), hl

        endif

        exx
        ret 

; -----------------------------------------------------------------------------------------------------------------------
; Math supporting macros
    MACRO GetAbsDEBCAndCallUnsignedProc ProcAddr
        bit 7, d
        jr z, 2F ;de_positive
        bit 7, b
        jr z, 1F ;de_negative_bc_positive
        ; // both negative
        ; // just invert them and call as unsigned
        ld hl, 0
        or a
        sbc hl, de
        push hl
        ld hl, 0
        or a
        sbc hl, bc
        ld b, h
        ld c, l
        pop de
        jr ProcAddr

1: ; de_negative_bc_positive:
        ; de negative, bc positive
        ; invert de, do unsigned, and invert back
        ld hl, 0
        or a
        sbc hl, de
        ex de, hl
        call ProcAddr
        ex de, hl
        ld hl, 0
        or a
        sbc hl, de
        ret

2: ; de_positive:
        bit 7, b
        jr z, ProcAddr  ; both positive, proceed straight to multiplication
        ; de positive, bc negative
        ; invert bc, multiply unsigned, and invert back
        ld hl, 0
        or a
        sbc hl, bc
        ld b, h
        ld c, l
        call ProcAddr
        ex de, hl
        ld hl, 0
        or a
        sbc hl, de
        ret
    ENDM



; -----------------------------------------------------------------------------------------------------------------------
; Signed Division 16/16 fp 8.8
; hl = de / bc
; fp 8.8 means we're dividing x*256 by y*256 and want to get z*256
; In order to not lose precision, premultiply x by 256 then and divide using 24-bit division
sdiv16:
    GetAbsDEBCAndCallUnsignedProc udiv16

; -----------------------------------------------------------------------------------------------------------------------
; Unsigned 16/16 fp 8.8 division
; hl = de / bc
; fp 8.8 means we're dividing x*256 by y*256 and want to get z*256.
; In order to not lose precision, premultiply x by 256 then and divide using 24-bit division
udiv16:
    ; restoring algorithm of 24/16 division, hl is the 16-bit accumulator, de:a holds the 24-bit dividend (will also become quotient)
    ; we make that 24 bit number out of 16 bit number shifted to the left
    ; shift the numerator 7 bits to the left
    xor a
    ld h, a     ; accumulator HL starts at 0
    ld l, a

    ; rearrange from de:a to a:de so we can structure the loop better
    ld a, d
    ld d, e
    ld e, l     ; l==0, so e is also 0

    ; restoring algorithm of 24/16 division, hl is the 16-bit accumulator, a:de holds the 24-bit dividend (will also become quotient)
    ; we make that 24 bit number out of 16 bit number shifted to the left
    DUP 24
        sll e       ; 8
        rl d        ; 8
        rla         ; 4
        adc hl, hl  ; 15
        ;or a       ; 0 (4) we seem to be able to avoid resetting carry here because we always keep HL < BC, and our BC is positive, so it does not have the highest bit set
        sbc hl, bc  ; 15    ; if hl > bc we need to subtract it and increase a, if hl < bc, we need to do nothing
        jr nc, 1F   ; 7 or 12
        add hl, bc  ; 11
        dec e       ; 4
1
                    ; -----
                    ; 72 or 62 cycles. Total div is going to be between 1488-1728 cycles, likely closer to 1608
                    ; Note: https://baze.sk/3sc/misc/z80bits.html#2.5 has a very similar code and I borrowed the idea to use SLL from there.
    EDUP

    ; a:de holds the quotient, of which we need the lower part
    ex de, hl
    ret

; -----------------------------------------------------------------------------------------------------------------------
; Signed multiply 16/16 fp 8.8
; hl = de * bc
; fp 8.8 means we're multiplying x*256 by y*256 and want to get z*256
; after multiply, we would get xy*65536, so divide the result by 256 (shift by 8 bits)
smul16:
    GetAbsDEBCAndCallUnsignedProc umul16

; -----------------------------------------------------------------------------------------------------------------------
; 16-bit 8.8 fixed point unsigned multiply
;   hl = bc * de
; credits: https://tutorials.eeems.ca/Z80ASM/part4.htm
; fp 8.8 means we're multiplying x*256 by y*256 and want to get z*256
; after multiply, we would get xy*65536, so divide the result by 256 (shift by 8 bits)
umul16:
    ld hl, 0

    DUP 16
      add hl, hl
      rl e
      rl d
      jr nc, 1F
      add hl, bc
      jr nc, 1F
      inc de                         ; This instruction (with the jump) is like an "ADC DE,0"
1
    EDUP
    ; we have de:hl holding a 16.16 result, and we need to take the middle 8.8 part. 
    ld l, h
    ld h, e
    ret

    if (!USE_70CYCLE_PLOT)
XorPlotRoutine:
    ; from https://zxspectrumcoding.wordpress.com/2025/05/10/a-fast-pixel-routine-for-the-zx-spectrum/
    ld A,E                ;  load Y plot point

    srl a                 ;  rotate Right --- divide in half
    scf                   ;  turn on Carry flag
    rra                   ;  rotate right with the carry flag
    scf                   ;  turn on Carry flag
    rra                   ;  rotate Right --- divide in half

    ld L,A                ;  temp store in L
    xor E                 ;  XOR the Y value
    and %11111000         ;  mask out bottom 3 bits
    xor E                 ;  XOR the Y value

    ld H,A                ;  store High byte

    ld A,D                ;  load X plot point
    xor L                 ;  XOR the temp value
    and %00000111         ;  mask out unwanted bits
    xor D                 ;  XOR the X value
    rrca                  ;  divide by 2
    rrca                  ;  divide by 4
    rrca                  ;  divide by 8

    ld L,A                ;  store Low byte
                        ;  now we have the full address
                        ;  now use LUT to find which bit to set
    ld A,D                ;  load X plot point
    and %00000111         ;  mask out unwanted bits

                        ;  use a LUT to quickly find the bit position for the X position
    ld D, high X_PositionBits  ;  load LUT address into DE
    ld E, A               ;  E now points to the LUT entry
    ld A,(DE)             ;  load answer into A

                        ;  output to screen
    xor (HL)              ;  or with contents of address HL
    ld (HL),A             ;  load address HL with Answer from A
    ret
    
    else

; "ZIP PLOT 1.4"
; Credits: Viper of TechnoLab
; Taken from KrNews #05 (July 24, 1998)
; https://zxpress.ru/article.php?id=8242
XorPlotRoutine:
    LD L,E
    LD H,high PTY
    LD B,(HL)
    DEC H
    LD A,(HL)
    DEC H
    LD L,D
    ADD A,(HL)
    LD C,A
    DEC H
    LD A,(BC)
    XOR (HL)
    LD (BC),A
    ret

    endif


;--------------------------------------------------------------------
; Trampolines - based on an idea that jumping to/calling close addresses would pack better. Didn't work.
    if (0)

rnd_trampo:
    jp rnd

Project_trampo:
    jp Project

PlotSizeRoutine_trampo:
    jp PlotSizeRoutine

smul16_trampo:
    jp smul16

sdiv16_trampo:
    jp sdiv16

XorPlotRoutine_trampo:
    jp XorPlotRoutine

    else

rnd_trampo equ rnd
Project_trampo equ Project
PlotSizeRoutine_trampo equ PlotSizeRoutine
smul16_trampo equ smul16
sdiv16_trampo equ sdiv16
XorPlotRoutine_trampo equ XorPlotRoutine

    endif
; ---------------------------------------------------
; Resources

    if (!NO_MUSIC)
MusicBegin:
MusicRegPairs:
		incbin "../res/melody_raw/Tone00.bin"
		incbin "../res/melody_raw/Tone01.bin"
		incbin "../res/melody_raw/Reg0607.bin"

MusicRegs:
		incbin "../res/melody_raw/Reg08.bin"
RegisterFileLength EQU $ - MusicRegs
		incbin "../res/melody_raw/Reg09.bin"
    endif

    if (!USE_70CYCLE_PLOT)
    align 256
X_PositionBits: defb 128,64,32,16,8,4,2,1
    endif

    ; these all are 0-inited, but we actually rely on them to be 0s
    ; don't want to get in trouble if starting on unclean memory
    align 256
HistoryLeft:
    ds 256
HistoryRight:
    ds 256

    ; these all are 0-inited, but we actually rely on them to be 0s
    ; don't want to get in trouble if starting on unclean memory
    align 256
ParticleBuffer:
    ds NUM_PARTICLES * Particle
ParticleBufferSize equ $ - ParticleBuffer

bss_start:
; only zero-init allowed after this point!!

savebin_end EQU bss_start

SavedSP:
    dw 0
NextSP:
    dw 0

    if (USE_70CYCLE_PLOT)
        align 256
        block 1024
PTY     EQU $
    endif

    ; we should not allow the main program to overflow $c000 due to the second screen use
    ASSERT $ < 49152

    savebin "anaglyph_main.bin", savebin_begin, savebin_end-savebin_begin
    SAVESNA "anaglyph_main.sna", savebin_begin
