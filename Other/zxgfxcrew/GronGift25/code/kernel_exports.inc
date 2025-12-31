; expected to be included by effects where needed

; schedules the text to be printed by the IM2 printer, does not return until it's not printed, but calls mainthread_effect meanwhile
;  expects:
;    DE - coords (D - x in pixels, E - y in blocks)
;    HL - text ptr
;    A - color
kernel_print_im2   equ $5b03
