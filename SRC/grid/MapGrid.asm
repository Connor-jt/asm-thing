

.data

Grid qword 4096 dup(0) ; 32kb !!

; LAYERS:
;	grid		: topmost layer  64x64
;	section		: middle layer   32x32
;	quadrant	: data layer     32x32



.code




; func try claim tile

; func release tile

; func check tile ; returns actor handle, with modified not_actor bit (highest most bit)
; dx: Y
; cx: X
GridCheckTile PROC
	; transform into GRID layer	
	


GridCheckTile ENDP


; malloc new section
; dealloc section (we may not actually use this)


END