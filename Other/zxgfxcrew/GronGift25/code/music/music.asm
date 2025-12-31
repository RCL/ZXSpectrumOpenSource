; inteded to be included by the kernel

; --------------------------------------------------------------------
; Overlay music init - called by the player
; Expects interrupts disabled

pt3_player:
	include "pt3_player_adapted.asm"
	DISPLAY "External but modified PT3 player takes ", /A, $ - pt3_player, " bytes."

overlay_music_init:
	; reinit the player
	ld a, 1
	ld (overlay_music_play.is_inited), a
	ld hl, music_track
	jp INIT	; pt3's player entry point

overlay_music_play:
.is_inited equ $+1
	ld a, 0
	and a
	ret z
	jp PLAY


module:
music_track:
	incbin "../res/music/nq-Radiohead-Creep-fix-2.pt3"
