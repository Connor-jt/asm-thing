
malloc PROTO


.data

Grid qword 4096 dup(0) ; 64x64 ; 32kb !!
; and then the sections & quads are dynamically allocated memory (8000 bytes each)

; LAYERS:
;	grid		: topmost layer  64x64
;	section		: middle layer   32x32
;	quadrant	: data layer     32x32


; Grid data
; 11111111 00000000 00000000 00000000 \ 00000000 : tile type
; 00000000 11111111 00000000 00000000 \ 00000000 : health
; 00000000 00000000 00000000 00001100 \ 00000000 : tile_state (00: uninitialized, 01: clear path, 10: destructible block, 11: indestructible block)
; 00000000 00000000 00000000 00000011 \ 00000000 : tile_actors (00: no actors, 01: has actor, 10: has actor_cluster)
; 00000000 00000000 00000000 00000000 \ FFFFFFFF : actor handle | actor cluster handle
; +7       +6       +5       +4         +0


; 
.code

; [OUTPUT] rax: mempointer
; rcx: count
LazyAlignMalloc PROC
	; NOTE: since we stopped correctly managing RSP alignment at some point, we have to dynamically align RSP to 16 bytes here
	push r12
	mov r12, rsp
	and r12, 8
	sub rsp, r12
	call malloc
	add rsp, r12
	pop r12
	ret
LazyAlignMalloc ENDP


; func try claim tile

; func release tile

; func check tile ; returns actor handle, with modified not_actor bit (highest most bit)

; [OUTPUT] r8d: quad array index
; [OUTPUT] r9d: section array index
; [OUTPUT] ecx: grid array index
; edx: Y
; ecx: X
GridCoordsToIndex PROC
	; transform coords, so coord 0,0 becomes the center most tile
	; todo: make 0,0 not the perfect center so we dont have to constantly realloc blocks
	; TODO: optimize this a bit more, since its going to be a very heavily used function!!!!
		add ecx, 8000h
		add edx, 8000h
	; get quadrant layer coords (indexes the tile)
		mov r8d, ecx
		mov eax, edx
		and r8d, 31
		and eax, 31
		; combine Y into X
		shl eax, 5
		or  r8d, eax 
	; get section layer coords (indexes the quadrant)
		shr ecx, 5
		shr edx, 5
		mov r9d, ecx
		mov eax, edx
		and r9d, 31 
		and eax, 31
		; combine Y into X
		shl eax,  5
		or  r9d, eax 
	; get grid layer coords
		shr ecx, 5
		shr edx, 5
		;and ecx, 63 ; likely not necessary
		; combine Y into X
		shl edx, 6
		or  ecx, edx
	ret
GridCoordsToIndex ENDP

; [output] rax: tile data
; edx: Y
; ecx: X
GridAccessTilePtr PROC
	call GridCoordsToIndex
	; check grid index (section) is valid
		lea rax, Grid
		mov rdx, qword ptr [rax+rcx*8]
		cmp rdx, 0
		je return_fail
	; check section index (quad) is valid
		mov rdx, qword ptr [rdx+r9*8]
		cmp rdx, 0
		je return_fail
	; get content of quad index (tile)
		lea rax, qword ptr [rdx+r8*8]
		ret
	return_fail:
		xor rax, rax
		ret 
GridAccessTilePtr ENDP

; [output] rax: tile data
; edx: Y
; ecx: X
GridAccessOrCreateTilePtr PROC
	call GridCoordsToIndex
	push r12
	push r13
	push r14
	push r15
	mov r12d, r8d ; quad index
	mov r13d, r9d ; section index
	mov r14d, ecx ; grid index

	; check grid index (section) is valid, create a new section if not
		lea r15, Grid
		mov rax, qword ptr [r15+r14*8]
		cmp rax, 0
		jne c00
			mov ecx, 8192 ; byte size of a section
			call LazyAlignMalloc
			mov qword ptr [r15+r14*8], rax
			cmp rax, 0
			je return_fail
		c00:
	; check section index (quad) is valid, create a new quad if not
		mov r15, rax
		mov rax, qword ptr [r15+r13*8]
		cmp rax, 0
		jne c00
			mov ecx, 8192 ; byte size of a quadrant
			call LazyAlignMalloc
			mov qword ptr [r15+r13*8], rax
			cmp rax, 0
			je return_fail
		c00:
	; get content of quad index (tile)
		pop r15
		pop r14
		pop r13
		pop r12
		lea rax, qword ptr [rdx+r12*8]
		ret
	return_fail:
		pop r15
		pop r14
		pop r13
		pop r12
		xor rax, rax
		ret 
GridAccessOrCreateTilePtr ENDP

; [output] rax: tile data
; edx: Y
; ecx: X
GridAccessTile PROC
	call GridAccessTilePtr
	cmp rax, 0 
	; if ptr is not null, then return the tile content
	je return
		mov rax, qword ptr [rax]
	return:
		ret 
GridAccessTile ENDP

; edx: Y
; ecx: X
;GridIsTileClear PROC
;	; get tile data
;		sub rsp, 8
;		call GridAccessTile
;	; if tile is non-walkable then fail
;		mov rcx, rdx
;		and rcx, 00FC000000000000h
;		cmp rcx, 00FC000000000000h
;		jne tile_occupied
;	; get actor on tile bits
;		and rdx, 0003000000000000h
;		cmp rdx, 0
;		jne tile_occupied
;	; else tile is free to use
;		mov rax, 1
;		jmp return
;	tile_occupied:
;		xor rax, rax
;	return:
;		add rsp, 8
;		ret
;GridIsTileClear ENDP

; edx: Y
; ecx: X
GridTilePathingCost PROC
	; get tile data
		call GridAccessTile
	; if tile is uninitialized, then assume its a default destructible block (add 1 health because we are not sure what block it is?)
		cmp rax, 0
		je return_basic_block
	; check if tile has actors on it
		test rax, 0300000000h
		jnz return_impassible 
	; check tile state (and return if its uninitialized)
		mov rcx, rax 
		and rcx, 0C00000000h
		jz return_basic_block
	; check if tile is clear
		cmp rcx, 0400000000h
		je return_clear_path
	; check if tile has health
		cmp rcx, 0800000000h
		je return_destructible_block
	; check if tile is an indestructible blocker 
	; NOTE: this is the default fallback case, so we dont actually need to check
		;cmp rcx, 0C00000000h
		;je return_impassible
	return_impassible:
		mov eax, 63
		ret
	return_destructible_block:
		shr rax, 48
		and rax, 8
		cmp rax, 63
		jg return_impassible
		ret
	return_clear_path:
		xor eax,eax
		ret
	return_basic_block:
		mov eax, 1
		ret
GridIsTileClear ENDP
	



; malloc new section
; dealloc section (we may not actually use this)


END