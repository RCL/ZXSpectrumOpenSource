

render_overlay:
    ld bc, #ff00
    ld de, #fcc0

    ; line 4 ->
    ld hl, #440e
    ld a, (hl) : or e : ld (hl), a

    ; line 5 <-
    inc h
    ld a, (hl) : or #f8 : ld (hl), a

    ; line 6 ->
    inc h
    ld a, (hl) : or #fe : ld (hl), a

    ; line 7 <-
    inc h
    ld (hl), b

    ; line 8 ->
    ld hl, #402e
    ld (hl), b : inc l
    ld a, (hl) : or #80 : ld (hl), a

    ; line 9 <-
    inc h
    ld a, (hl) : or e : ld (hl), a : dec l
    ld (hl), #3f

    ; line 10 ->
    inc h
    ld (hl), #1f : inc l
    ld a, (hl) : or #e0 : ld (hl), a

    ; line 11 <-
    inc h
    ld a, (hl) : or #e0 : ld (hl), a : dec l
    ld (hl), #0f

    ; line 12 ->
    inc h
    ld (hl), #07 : inc l
    ld a, (hl) : or #f0 : ld (hl), a

    ; line 13 <-
    inc h
    ld a, (hl) : or #f0 : ld (hl), a : dec l
    ld (hl), #03

    ; line 14 ->
    inc h
    ld (hl), #01 : inc l
    ld a, (hl) : or #f0 : ld (hl), a

    ; line 15 <-
    inc h
    ld a, (hl) : or #f8 : ld (hl), a : dec l
    ld (hl), #01

    ; line 16 ->
    ld hl, #404e
    ld (hl), #01 : inc l
    ld a, (hl) : or #f8 : ld (hl), a

    ; line 17 <-
    inc h
    ld a, (hl) : or #f8 : ld (hl), a : dec l
    ld (hl), c

    ; line 18 ->
    inc h
    ld (hl), c : inc l
    ld a, (hl) : or #f8 : ld (hl), a

    ; line 19 <-
    inc h
    ld a, (hl) : or #f8 : ld (hl), a : dec l
    ld (hl), c

    ; line 20 ->
    inc h
    ld (hl), c : inc l
    ld a, (hl) : or #f8 : ld (hl), a

    ; line 21 <-
    inc h
    ld a, (hl) : or d : ld (hl), a : dec l
    ld (hl), c

    ; line 22 ->
    inc h
    ld (hl), c : inc l
    ld a, (hl) : or d : ld (hl), a

    ; line 23 <-
    inc h
    ld a, (hl) : or d : ld (hl), a : dec l
    ld (hl), #01

    ; line 24 ->
    ld hl, #406e
    ld (hl), #01 : inc l
    ld (hl), b

    ; line 25 <-
    inc h : inc l
    ld a, (hl) : or #80 : ld (hl), a : dec l
    ld (hl), #cf : dec l
    ld (hl), #01

    ; line 26 ->
    inc h
    ld (hl), #03 : inc l
    ld (hl), #87 : inc l
    ld a, (hl) : or #e0 : ld (hl), a

    ; line 27 <-
    inc h
    ld a, (hl) : or #f0 : ld (hl), a : dec l
    ld (hl), #87 : dec l
    ld (hl), #07

    ; line 28 ->
    inc h
    ld (hl), #0f : inc l
    ld (hl), #cf : inc l
    ld a, (hl) : or #f0 : ld (hl), a

    ; line 29 <-
    inc h
    ld a, (hl) : or #f8 : ld (hl), a : dec l
    ld (hl), b : dec l
    ld (hl), #1f

    ; line 30 ->
    inc h
    ld (hl), #3f : inc l
    ld (hl), #f9 : inc l
    ld a, (hl) : or #f8 : ld (hl), a

    ; line 31 <-
    inc h
    ld a, (hl) : or #f8 : ld (hl), a : dec l
    ld (hl), #f9 : dec l
    ld (hl), b

    ; line 32 ->
    ld hl, #408e
    ld (hl), b : inc l
    ld (hl), b : inc l
    ld a, (hl) : or #f8 : ld (hl), a

    ; line 33 <-
    inc h
    ld a, (hl) : or #f8 : ld (hl), a : dec l
    ld (hl), b : dec l
    ld (hl), b

    ; line 34 ->
    inc h
    ld (hl), b : inc l
    ld (hl), b : inc l
    ld a, (hl) : or #f8 : ld (hl), a

    ; line 35 <-
    inc h
    ld a, (hl) : or #f0 : ld (hl), a : dec l
    ld (hl), b : dec l
    ld (hl), b

    ; line 36 ->
    inc h
    ld (hl), b : inc l
    ld (hl), b : inc l
    ld a, (hl) : or #f8 : ld (hl), a

    ; line 37 <-
    inc h
    ld a, (hl) : or d : ld (hl), a : dec l
    ld (hl), b : dec l
    ld (hl), b

    ; line 38 ->
    inc h
    ld (hl), b : inc l
    ld (hl), b : inc l
    ld a, (hl) : or #fe : ld (hl), a

    ; line 39 <-
    inc h
    ld (hl), b : dec l
    ld (hl), #f3 : dec l
    ld (hl), b

    ; line 40 ->
    ld hl, #40ae
    ld (hl), b : inc l
    ld (hl), #f3 : inc l
    ld (hl), #c7

    ; line 41 <-
    inc h : inc l
    ld a, (hl) : or #80 : ld (hl), a : dec l
    ld (hl), #83 : dec l
    ld (hl), b : dec l
    ld (hl), b

    ; line 42 ->
    inc h
    ld (hl), b : inc l
    ld (hl), b : inc l
    ld (hl), #83 : inc l
    ld a, (hl) : or #80 : ld (hl), a

    ; line 43 <-
    inc h
    ld a, (hl) : or e : ld (hl), a : dec l
    ld (hl), #83 : dec l
    ld (hl), b : dec l
    ld (hl), b

    ; line 44 ->
    inc h
    ld (hl), b : inc l
    ld (hl), b : inc l
    ld (hl), #c7 : inc l
    ld a, (hl) : or e : ld (hl), a

    ; line 45 <-
    inc h
    ld a, (hl) : or e : ld (hl), a : dec l
    ld (hl), b : dec l
    ld (hl), b : dec l
    ld (hl), b

    ; line 46 ->
    inc h
    ld (hl), b : inc l
    ld (hl), b : inc l
    ld (hl), b : inc l
    ld a, (hl) : or e : ld (hl), a

    ; line 47 <-
    inc h
    ld a, (hl) : or #e0 : ld (hl), a : dec l
    ld (hl), b : dec l
    ld (hl), b : dec l
    ld (hl), b

    ; line 48 ->
    ld hl, #40ce
    ld (hl), #f8 : inc l
    ld (hl), #1f : inc l
    ld (hl), b : inc l
    ld a, (hl) : or #f0 : ld (hl), a

    ; line 49 <-
    inc h
    ld a, (hl) : or #f8 : ld (hl), a : dec l
    ld (hl), b : dec l
    ld (hl), #07 : dec l
    ld (hl), #e0

    ; line 50 ->
    inc h
    ld (hl), e : inc l
    ld (hl), #03 : inc l
    ld (hl), b : inc l
    ld a, (hl) : or d : ld (hl), a

    ; line 51 <-
    inc h
    ld a, (hl) : or d : ld (hl), a : dec l
    ld (hl), b : dec l
    ld (hl), #01 : dec l
    ld (hl), #80

    ; line 52 ->
    inc h
    ld (hl), #80 : inc l
    ld (hl), #01 : inc l
    ld (hl), b : inc l
    ld a, (hl) : or #fe : ld (hl), a

    ; line 53 <-
    inc h
    ld a, (hl) : or #fe : ld (hl), a : dec l
    ld (hl), b : dec l
    ld (hl), c : dec l
    ld (hl), c

    ; line 54 ->
    inc h
    ld (hl), c : inc l
    ld (hl), c : inc l
    ld (hl), b : inc l
    ld (hl), b

    ; line 55 <-
    inc h : inc l
    ld a, (hl) : or #80 : ld (hl), a : dec l
    ld (hl), b : dec l
    ld (hl), b : dec l
    ld (hl), c : dec l
    ld (hl), c

    ; line 56 ->
    ld hl, #40ee
    ld (hl), c : inc l
    ld (hl), c : inc l
    ld (hl), b : inc l
    ld (hl), #0f : inc l
    ld a, (hl) : or #80 : ld (hl), a

    ; line 57 <-
    inc h
    ld a, (hl) : or e : ld (hl), a : dec l
    ld (hl), #07 : dec l
    ld (hl), #fe : dec l
    ld (hl), c : dec l
    ld (hl), c

    ; line 58 ->
    inc h
    ld (hl), c : inc l
    ld (hl), c : inc l
    ld (hl), d : inc l
    ld (hl), #03 : inc l
    ld a, (hl) : or e : ld (hl), a

    ; line 59 <-
    inc h
    ld a, (hl) : or e : ld (hl), a : dec l
    ld (hl), #03 : dec l
    ld (hl), d : dec l
    ld (hl), #01 : dec l
    ld (hl), #80

    ; line 60 ->
    inc h
    ld (hl), #80 : inc l
    ld (hl), #01 : inc l
    ld (hl), d : inc l
    ld (hl), #03 : inc l
    ld a, (hl) : or e : ld (hl), a

    ; line 61 <-
    inc h
    ld a, (hl) : or e : ld (hl), a : dec l
    ld (hl), #03 : dec l
    ld (hl), d : dec l
    ld (hl), #03 : dec l
    ld (hl), e

    ; line 62 ->
    inc h
    ld (hl), #e0 : inc l
    ld (hl), #07 : inc l
    ld (hl), #fe : inc l
    ld (hl), #07 : inc l
    ld a, (hl) : or e : ld (hl), a

    ; line 63 <-
    inc h
    ld a, (hl) : or #80 : ld (hl), a : dec l
    ld (hl), #0f : dec l
    ld (hl), b : dec l
    ld (hl), #1f : dec l
    ld (hl), #f8

    ; line 64 ->
    ld hl, #480e
    ld (hl), b : inc l
    ld (hl), b : inc l
    ld (hl), b : inc l
    ld (hl), b : inc l
    ld a, (hl) : or #80 : ld (hl), a

    ; line 65 <-
    inc h : dec l
    ld (hl), b : dec l
    ld (hl), b : dec l
    ld (hl), b : dec l
    ld (hl), b

    ; line 66 ->
    inc h
    ld (hl), b : inc l
    ld (hl), b : inc l
    ld (hl), b : inc l
    ld (hl), b

    ; line 67 <-
    inc h
    ld (hl), b : dec l
    ld (hl), b : dec l
    ld (hl), b : dec l
    ld (hl), b

    ; line 68 ->
    inc h
    ld (hl), b : inc l
    ld (hl), b : inc l
    ld (hl), b : inc l
    ld (hl), b

    ; line 69 <-
    inc h
    ld (hl), b : dec l
    ld (hl), b : dec l
    ld (hl), b : dec l
    ld (hl), b

    ; line 70 ->
    inc h
    ld (hl), b : inc l
    ld (hl), #fe : inc l
    ld (hl), #07 : inc l
    ld (hl), b

    ; line 71 <-
    inc h : inc l
    ld a, (hl) : or #80 : ld (hl), a : dec l
    ld (hl), b : dec l
    ld (hl), c : dec l
    ld (hl), #f0 : dec l
    ld (hl), b

    ; line 72 ->
    ld hl, #482e
    ld (hl), #9f : inc l
    ld (hl), #e0 : inc l
    ld (hl), c : inc l
    ld (hl), #7f : inc l
    ld a, (hl) : or e : ld (hl), a

    ; line 73 <-
    inc h
    ld a, (hl) : or e : ld (hl), a : dec l
    ld (hl), #3f : dec l
    ld (hl), c : dec l
    ld (hl), e : dec l
    ld (hl), #0f

    ; line 74 ->
    inc h
    ld (hl), #0f : inc l
    ld (hl), #80 : inc l
    ld (hl), c : inc l
    ld (hl), #1f : inc l
    ld a, (hl) : or #e0 : ld (hl), a

    ; line 75 <-
    inc h
    ld a, (hl) : or #e0 : ld (hl), a : dec l
    ld (hl), #0f : dec l
    ld (hl), c : dec l
    ld (hl), c : dec l
    ld (hl), #9f

    ; line 76 ->
    inc h
    ld (hl), #fe : inc l
    ld (hl), c : inc l
    ld (hl), c : inc l
    ld (hl), #07 : inc l
    ld a, (hl) : or #e0 : ld (hl), a

    ; line 77 <-
    inc h
    ld a, (hl) : or #e0 : ld (hl), a : dec l
    ld (hl), #07 : dec l
    ld (hl), c : dec l
    ld (hl), c : dec l
    ld (hl), #fe

    ; line 78 ->
    inc h
    ld (hl), #fe : inc l
    ld (hl), c : inc l
    ld (hl), c : inc l
    ld (hl), #07 : inc l
    ld a, (hl) : or #f0 : ld (hl), a

    ; line 79 <-
    inc h
    ld a, (hl) : or #f0 : ld (hl), a : dec l
    ld (hl), #03 : dec l
    ld (hl), c : dec l
    ld (hl), c : dec l
    ld (hl), d

    ; line 80 ->
    ld hl, #484e
    ld (hl), d : inc l
    ld (hl), c : inc l
    ld (hl), c : inc l
    ld (hl), #03 : inc l
    ld a, (hl) : or #f0 : ld (hl), a

    ; line 81 <-
    inc h
    ld a, (hl) : or #f0 : ld (hl), a : dec l
    ld (hl), #03 : dec l
    ld (hl), c : dec l
    ld (hl), c : dec l
    ld (hl), d

    ; line 82 ->
    inc h
    ld (hl), d : inc l
    ld (hl), c : inc l
    ld (hl), c : inc l
    ld (hl), #03 : inc l
    ld a, (hl) : or #f0 : ld (hl), a

    ; line 83 <-
    inc h
    ld a, (hl) : or #f0 : ld (hl), a : dec l
    ld (hl), #03 : dec l
    ld (hl), c : dec l
    ld (hl), c : dec l
    ld (hl), d

    ; line 84 ->
    inc h
    ld (hl), d : inc l
    ld (hl), c : inc l
    ld (hl), c : inc l
    ld (hl), #03 : inc l
    ld a, (hl) : or #f0 : ld (hl), a

    ; line 85 <-
    inc h
    ld a, (hl) : or #e0 : ld (hl), a : dec l
    ld (hl), #07 : dec l
    ld (hl), c : dec l
    ld (hl), c : dec l
    ld (hl), #fe

    ; line 86 ->
    inc h
    ld (hl), #fe : inc l
    ld (hl), c : inc l
    ld (hl), c : inc l
    ld (hl), #07 : inc l
    ld a, (hl) : or #e0 : ld (hl), a

    ; line 87 <-
    inc h
    ld a, (hl) : or #e0 : ld (hl), a : dec l
    ld (hl), #07 : dec l
    ld (hl), c : dec l
    ld (hl), c : dec l
    ld (hl), #fe

    ; line 88 ->
    ld hl, #486e
    ld (hl), #7f : inc l
    ld (hl), c : inc l
    ld (hl), c : inc l
    ld (hl), #0f : inc l
    ld a, (hl) : or #e0 : ld (hl), a

    ; line 89 <-
    inc h
    ld a, (hl) : or e : ld (hl), a : dec l
    ld (hl), #1f : dec l
    ld (hl), c : dec l
    ld (hl), #80 : dec l
    ld (hl), #7f

    ; line 90 ->
    inc h
    ld (hl), #7f : inc l
    ld (hl), e : inc l
    ld (hl), c : inc l
    ld (hl), #3f : inc l
    ld a, (hl) : or e : ld (hl), a

    ; line 91 <-
    inc h
    ld a, (hl) : or #e0 : ld (hl), a : dec l
    ld (hl), #7f : dec l
    ld (hl), c : dec l
    ld (hl), #e0 : dec l
    ld (hl), #7f

    ; line 92 ->
    inc h
    ld (hl), #f9 : inc l
    ld (hl), #f0 : inc l
    ld (hl), c : inc l
    ld (hl), b : inc l
    ld a, (hl) : or #f0 : ld (hl), a

    ; line 93 <-
    inc h
    ld a, (hl) : or #f8 : ld (hl), a : dec l
    ld (hl), b : dec l
    ld (hl), #07 : dec l
    ld (hl), #fe : dec l
    ld (hl), #f0

    ; line 94 ->
    inc h
    ld (hl), #f0 : inc l
    ld (hl), b : inc l
    ld (hl), b : inc l
    ld (hl), b : inc l
    ld a, (hl) : or #f8 : ld (hl), a

    ; line 95 <-
    inc h
    ld a, (hl) : or d : ld (hl), a : dec l
    ld (hl), b : dec l
    ld (hl), b : dec l
    ld (hl), b : dec l
    ld (hl), #f9

    ; line 96 ->
    ld hl, #488e
    ld (hl), b : inc l
    ld (hl), b : inc l
    ld (hl), #f8 : inc l
    ld (hl), #1f : inc l
    ld a, (hl) : or d : ld (hl), a

    ; line 97 <-
    inc h
    ld a, (hl) : or d : ld (hl), a : dec l
    ld (hl), #07 : dec l
    ld (hl), #e0 : dec l
    ld (hl), b : dec l
    ld (hl), b

    ; line 98 ->
    inc h
    ld (hl), b : inc l
    ld (hl), b : inc l
    ld (hl), e : inc l
    ld (hl), #03 : inc l
    ld a, (hl) : or #fe : ld (hl), a

    ; line 99 <-
    inc h
    ld a, (hl) : or #fe : ld (hl), a : dec l
    ld (hl), #01 : dec l
    ld (hl), #80 : dec l
    ld (hl), b : dec l
    ld (hl), b

    ; line 100 ->
    inc h
    ld (hl), b : inc l
    ld (hl), b : inc l
    ld (hl), #80 : inc l
    ld (hl), #01 : inc l
    ld a, (hl) : or #fe : ld (hl), a

    ; line 101 <-
    inc h
    ld a, (hl) : or #fe : ld (hl), a : dec l
    ld (hl), c : dec l
    ld (hl), c : dec l
    ld (hl), b : dec l
    ld (hl), b

    ; line 102 ->
    inc h
    ld (hl), b : inc l
    ld (hl), #f3 : inc l
    ld (hl), c : inc l
    ld (hl), c : inc l
    ld a, (hl) : or #fe : ld (hl), a

    ; line 103 <-
    inc h
    ld a, (hl) : or #fe : ld (hl), a : dec l
    ld (hl), c : dec l
    ld (hl), c : dec l
    ld (hl), #f3 : dec l
    ld (hl), b

    ; line 104 ->
    ld hl, #48ae
    ld (hl), b : inc l
    ld (hl), b : inc l
    ld (hl), c : inc l
    ld (hl), c : inc l
    ld a, (hl) : or #fe : ld (hl), a

    ; line 105 <-
    inc h
    ld a, (hl) : or #fe : ld (hl), a : dec l
    ld (hl), c : dec l
    ld (hl), c : dec l
    ld (hl), b : dec l
    ld (hl), b

    ; line 106 ->
    inc h
    ld (hl), b : inc l
    ld (hl), #cf : inc l
    ld (hl), c : inc l
    ld (hl), c : inc l
    ld a, (hl) : or d : ld (hl), a

    ; line 107 <-
    inc h
    ld a, (hl) : or d : ld (hl), a : dec l
    ld (hl), #01 : dec l
    ld (hl), #80 : dec l
    ld (hl), #87 : dec l
    ld (hl), b

    ; line 108 ->
    inc h
    ld (hl), b : inc l
    ld (hl), #87 : inc l
    ld (hl), #80 : inc l
    ld (hl), #01 : inc l
    ld a, (hl) : or d : ld (hl), a

    ; line 109 <-
    inc h
    ld a, (hl) : or #f8 : ld (hl), a : dec l
    ld (hl), #03 : dec l
    ld (hl), e : dec l
    ld (hl), #cf : dec l
    ld (hl), b

    ; line 110 ->
    inc h
    ld (hl), b : inc l
    ld (hl), b : inc l
    ld (hl), #e0 : inc l
    ld (hl), #07 : inc l
    ld a, (hl) : or #f8 : ld (hl), a

    ; line 111 <-
    inc h
    ld a, (hl) : or #f0 : ld (hl), a : dec l
    ld (hl), #1f : dec l
    ld (hl), #f8 : dec l
    ld (hl), b : dec l
    ld (hl), b

    ; line 112 ->
    ld hl, #48ce
    ld (hl), b : inc l
    ld (hl), #f0 : inc l
    ld (hl), b : inc l
    ld (hl), b : inc l
    ld a, (hl) : or #e0 : ld (hl), a

    ; line 113 <-
    inc h
    ld a, (hl) : or e : ld (hl), a : dec l
    ld (hl), b : dec l
    ld (hl), #67 : dec l
    ld (hl), #e0 : dec l
    ld (hl), b

    ; line 114 ->
    inc h
    ld (hl), b : inc l
    ld (hl), e : inc l
    ld (hl), #27 : inc l
    ld (hl), b : inc l
    ld a, (hl) : or #80 : ld (hl), a

    ; line 115 <-
    inc h : dec l
    ld a, (hl) : or #fe : ld (hl), a : dec l
    ld (hl), #3f : dec l
    ld (hl), e : dec l
    ld (hl), b

    ; line 116 ->
    inc h
    ld (hl), b : inc l
    ld (hl), e : inc l
    ld (hl), #3f : inc l
    ld a, (hl) : or #f0 : ld (hl), a

    ; line 117 <-
    inc h
    ld a, (hl) : or e : ld (hl), a : dec l
    ld (hl), #3f : dec l
    ld (hl), e : dec l
    ld (hl), b

    ; line 118 ->
    inc h
    ld (hl), b : inc l
    ld (hl), #e0 : inc l
    ld (hl), #7f : inc l
    ld a, (hl) : or #80 : ld (hl), a

    ; line 119 <-
    inc h
    ld a, (hl) : or #80 : ld (hl), a : dec l
    ld (hl), b : dec l
    ld (hl), #f0 : dec l
    ld (hl), b

    ; line 120 ->
    ld hl, #48ee
    ld (hl), b : inc l
    ld (hl), b : inc l
    ld (hl), b

    ; line 121 <-
    inc h
    ld (hl), b : dec l
    ld (hl), b : dec l
    ld (hl), b

    ; line 122 ->
    inc h
    ld (hl), b : inc l
    ld (hl), b : inc l
    ld (hl), b

    ; line 123 <-
    inc h
    ld a, (hl) : or #fe : ld (hl), a : dec l
    ld (hl), b : dec l
    ld (hl), b

    ; line 124 ->
    inc h
    ld (hl), b : inc l
    ld (hl), b : inc l
    ld a, (hl) : or #fe : ld (hl), a

    ; line 125 <-
    inc h
    ld a, (hl) : or d : ld (hl), a : dec l
    ld (hl), b : dec l
    ld (hl), b

    ; line 126 ->
    inc h
    ld (hl), #f0 : inc l
    ld (hl), #3f : inc l
    ld a, (hl) : or #f8 : ld (hl), a

    ; line 127 <-
    inc h
    ld a, (hl) : or #f0 : ld (hl), a : dec l
    ld (hl), #0f : dec l
    ld (hl), e

    ; line 128 ->
    ld hl, #500e
    ld (hl), #80 : inc l
    ld (hl), #07 : inc l
    ld a, (hl) : or #f8 : ld (hl), a

    ; line 129 <-
    inc h
    ld a, (hl) : or #f8 : ld (hl), a : dec l
    ld (hl), #03 : dec l
    ld (hl), c

    ; line 130 ->
    inc h
    ld (hl), c : inc l
    ld (hl), #01 : inc l
    ld a, (hl) : or #f8 : ld (hl), a

    ; line 131 <-
    inc h
    ld a, (hl) : or d : ld (hl), a : dec l
    ld (hl), #01 : dec l
    ld (hl), c

    ; line 132 ->
    inc h
    ld (hl), c : inc l
    ld (hl), c : inc l
    ld a, (hl) : or d : ld (hl), a

    ; line 133 <-
    inc h
    ld a, (hl) : or d : ld (hl), a : dec l
    ld (hl), c : dec l
    ld (hl), c

    ; line 134 ->
    inc h
    ld (hl), c : inc l
    ld (hl), c : inc l
    ld a, (hl) : or d : ld (hl), a

    ; line 135 <-
    inc h
    ld a, (hl) : or d : ld (hl), a : dec l
    ld (hl), c : dec l
    ld (hl), c

    ; line 136 ->
    ld hl, #502e
    ld (hl), c : inc l
    ld (hl), c : inc l
    ld a, (hl) : or d : ld (hl), a

    ; line 137 <-
    inc h
    ld a, (hl) : or d : ld (hl), a : dec l
    ld (hl), c : dec l
    ld (hl), c

    ; line 138 ->
    inc h
    ld (hl), c : inc l
    ld (hl), #01 : inc l
    ld a, (hl) : or d : ld (hl), a

    ; line 139 <-
    inc h
    ld a, (hl) : or #f8 : ld (hl), a : dec l
    ld (hl), #01 : dec l
    ld (hl), c

    ; line 140 ->
    inc h
    ld (hl), c : inc l
    ld (hl), #03 : inc l
    ld a, (hl) : or #f8 : ld (hl), a

    ; line 141 <-
    inc h
    ld a, (hl) : or #f8 : ld (hl), a : dec l
    ld (hl), #07 : dec l
    ld (hl), #80

    ; line 142 ->
    inc h
    ld (hl), e : inc l
    ld (hl), #0f : inc l
    ld a, (hl) : or #f0 : ld (hl), a

    ; line 143 <-
    inc h
    ld a, (hl) : or #f0 : ld (hl), a : dec l
    ld (hl), #3f : dec l
    ld (hl), #f0

    ; line 144 ->
    ld hl, #504e
    ld (hl), b : inc l
    ld (hl), b : inc l
    ld a, (hl) : or #e0 : ld (hl), a

    ; line 145 <-
    inc h
    ld a, (hl) : or e : ld (hl), a : dec l
    ld (hl), b : dec l
    ld (hl), b

    ; line 146 ->
    inc h
    ld (hl), b : inc l
    ld (hl), b : inc l
    ld a, (hl) : or #80 : ld (hl), a

    ; line 147 <-
    inc h : dec l
    ld (hl), b : dec l
    ld (hl), b

    ; line 148 ->
    inc h
    ld (hl), b : inc l
    ld a, (hl) : or d : ld (hl), a

    ; line 149 <-
    inc h
    ld a, (hl) : or #e0 : ld (hl), a : dec l
    ld a, (hl) : or #9f : ld (hl), a

    ret
