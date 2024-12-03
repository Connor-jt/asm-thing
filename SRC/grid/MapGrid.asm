

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
	; r8b: quad array index
	; r9b: section array index
	; cx: grid array index

	; transform coords, so coord 0,0 becomes the center most tile
	; todo: make 0,0 not the perfect center so we dont have to constantly realloc blocks
		add cx, 8000h
		add dx, 8000h
	; get quadrant layer coords (indexes the tile)
		mov r8b, cx
		mov ax,  dx
		and r8b, 31
		and ax,  31
		; combine Y into X
		shl  ax, 5
		or  r8b, ax 
	; get section layer coords (indexes the quadrant)
		sar cx, 5
		sar dx, 5
		mov r9b, cx
		mov ax,  dx
		and r9b, 31
		and ax,  31
		; combine Y into X
		shl ax,  5
		or  r9b, ax 
	; get grid layer coords
		sar cx, 5
		sar dx, 5
		; combine Y into X
		shl dx, 6
		or  cx, dx 
		
		


GridCheckTile ENDP


; malloc new section
; dealloc section (we may not actually use this)


END