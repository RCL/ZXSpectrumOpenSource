

; Converts X,Y coords to screen address
; In:
;   H - coord Y (0..255)
;   L - coord X (0..192)
; Out:
;   DE - screen address
coords_to_screen_addr:
        ld a, h                 ; 4t
        and #c0                 ; 7t
        cp #c0                  ; 7t
        jr z, .out_of_screen    ; 7t
                                ; Sum: 25t
        ; block BB
        rrca                    ; 4t
        scf                     ; 4t
        rra                     ; 4t
        rrca                    ; 4t
        ld d, a                 ; 4t
                                ; Sum: 20t
        ; block CCC
        ld a, h                 ; 4t
        and #07                 ; 7t
        or d                    ; 4t
        ld d, a                 ; 4t
                                ; Sum: 19t
        ; block DDD
        ld a, h                 ; 4t
        and #38                 ; 7t
        rlca                    ; 4t
        rlca                    ; 4t
        ld e, a                 ; 4t
                                ; Sum: 23t
        ; block EEEEE
        ld a, l                 ; 4t
        and %11111000           ; 7t
        rrca                    ; 4t
        rrca                    ; 4t
        rrca                    ; 4t
        or e                    ; 4t
        ld e, a                 ; 4t
        ret                     ; Sum: 31t (93t w/o check)
                                ; Total: 25 + 20 + 19 + 23 + 31 = 118t, 31 bytes

.out_of_screen:
        ld de, 0
        scf
        ret


