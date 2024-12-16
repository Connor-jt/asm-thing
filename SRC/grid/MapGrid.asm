

.data

Grid qword 4096 dup(0) ; 64x64 ; 32kb !!

; LAYERS:
;	grid		: topmost layer  64x64
;	section		: middle layer   32x32
;	quadrant	: data layer     32x32


; Grid data
; 11111111 00000000 | 0000 00000000 : other bits??
; 00000000 11111100 | 0000 00000000 : damage taken (63 means fully walkable)
; 00000000 00000010 | 0000 00000000 : has actor_cluster
; 00000000 00000001 | 0000 00000000 : has actor
; 00000000 00000000 | FFFF FFFFFFFF : actor handle | actor cluster handle
; +7       +6         +4   +0


; 
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
		and r8,  31 ; clear the whole register
		and ax,  31
		; combine Y into X
		shl  ax, 5
		or  r8b, ax 
	; get section layer coords (indexes the quadrant)
		shr cx, 5
		shr dx, 5
		mov r9b, cx
		mov ax,  dx
		and r9,  31 ; clear the whole register
		and ax,  31
		; combine Y into X
		shl ax,  5
		or  r9b, ax 
	; get grid layer coords
		shr cx, 5
		shr dx, 5
		and rcx, 63 ; clear the rest of the bits in the register
		; combine Y into X
		shl dx, 6
		or  cx, dx 
		
	; check grid index (section) is valid
		lea rax, Grid
		mov rdx, qword ptr [rax+rcx*8]
		cmp rdx, 0
		je return_fail
	; check section index (quad) is valid
		mov rdx, qword ptr [rdx+r8*8]
		cmp rdx, 0
		je return_fail
	; check content of quad index (tile)
		mov rdx, qword ptr [rdx+r9*8]
		; if tile is non-walkable then fail
			mov rcx, rdx
			and rcx, 00FC000000000000h
			cmp rcx, 00FC000000000000h
			jne return_fail

				
		; get potential actor part

		test rdx, 0001000000000000h
		; else if content is not an actor
		jnz return_fail
		; if content is a actor
			
		jmp return_clear

	return_clear:
		mov qword ptr [rdx+r9*8], 0 
	return_fail:
		xor rax, rax
		ret
GridCheckTile ENDP


; malloc new section
; dealloc section (we may not actually use this)


END