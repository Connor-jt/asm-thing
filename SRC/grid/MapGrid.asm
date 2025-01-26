
GlobalAlloc PROTO
ActorTakeDamage PROTO
ActorBankRender PROTO
DrawTerrainSprite PROTO
ActorPtrFromHandle PROTO


extern dCameraX : dword
extern dCameraY : dword

extern dWinX : dword
extern dWinY : dword

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

; 0100000800000000h
; 
.code

; [OUTPUT] rax: mempointer
; rdx: count
; rcx: flags (https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-globalalloc)
LazyAlignMalloc PROC
	; NOTE: since we stopped correctly managing RSP alignment at some point, we have to dynamically align RSP to 16 bytes here
	push r12
	mov r12, rsp
	and r12, 8
	add r12, 20h ; shadow space
	sub rsp, r12
	call GlobalAlloc 
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
		and ecx, 63
		and edx, 63
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
			mov edx, 8192 ; byte size of a section
			mov ecx, 40h ; zero initialize mem
			call LazyAlignMalloc
			mov qword ptr [r15+r14*8], rax
			cmp rax, 0
			je return_fail
		c00:
	; check section index (quad) is valid, create a new quad if not
		mov r15, rax
		mov rax, qword ptr [r15+r13*8]
		cmp rax, 0
		jne c01
			mov edx, 8192 ; byte size of a quadrant
			xor ecx, ecx ; do not zero initialize mem
			call LazyAlignMalloc
			mov qword ptr [r15+r13*8], rax
			cmp rax, 0
			je return_fail
			; initialize memory
			xor ecx, ecx
			mov rdx, 0105000800000000h ; we have to do this because we cant move 64 bit consts into memory address
			c07:
				mov qword ptr [rax+rcx*8], rdx
				inc ecx
				cmp ecx, 1024
				jge c01
			jmp c07
		c01:
	; get content of quad index (tile)
		lea rax, qword ptr [rax+r12*8]
		pop r15
		pop r14
		pop r13
		pop r12
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
GridClearActorAt PROC
	; get grid pointer at
		call GridAccessTilePtr
		cmp rax, 0
		je return
	; clear actor bits
		mov rdx, 0FFFFFFFC00000000h ; cant directly AND with 64bit consts 
		and qword ptr [rax], rdx
	return:
		ret
GridClearActorAt ENDP

; r8d: actor handle
; edx: Y
; ecx: X
GridWriteActorAt PROC
	; get the tile pointer, or create if not yet created
		push r8
		call GridAccessOrCreateTilePtr
		pop r8
		cmp rax, 0
		je return
	; pack data to write to tile
		mov ecx, r8d ; clear higher bits
		mov r8, 100000000h
		or rcx, r8
	; write actor to tile
		mov rdx, qword ptr [rax]
		mov r8, 0FFFFFFFC00000000h
		and rdx, r8 ; clear actor bits
		or rdx, rcx ; write new actor bits
		mov qword ptr [rax], rdx
	return:
		ret
GridWriteActorAt ENDP



; r8d: damage
; edx: Y
; ecx: X
GridDamageTile PROC
	push r13
	mov r13d, r8d
	call GridAccessOrCreateTilePtr
	cmp rax, 0
	je return
		; get health
		; subtract damage from health
		; if less than eq to 0 then we change the tile state to clear path
		; also clamp the health at 0, no negatives
		push r12
		mov r12, rax
		mov rax, qword ptr [r12]
		; if has actors
			mov r8, 0300000000h
			test rax, r8
			jnz damage_actor 
		; skip if not damageable (unintialized 0b00 or destructible 0b10)
			mov r8, 0400000000h
			test rax, r8
			jnz return_pop
		; damage_tile
			; get health
				mov rcx, rax
				shr rcx, 48
				and ecx, 255
			; subtract
				sub ecx, r13d
			; if health depleted, change tile state to cleared and type to path
				jg c04
					; clear type & state
						mov r8, 00FFFFF3FFFFFFFFh
						and rax, r8 
					; set type (2) & state (1)
						mov r8, 0200000400000000h
						or  rax, r8 
					xor ecx, ecx ; clamp health to min 0
				c04:
			; set new health value
				and rcx, 255
				shl rcx, 48
				mov r8, 0FF00FFFFFFFFFFFFh
				and rax, r8
				or rax, rcx
			; write changes
				mov qword ptr [r12], rax
			jmp return_pop
		damage_actor: ; TODO: support for multi actor tiles
			mov r8d, r13d ; damage amount
			mov ecx, eax ; eax is the lower half of our tile data which will contain the actor reference
			call ActorTakeDamage
	return_pop:
		pop r12
	return:
		pop r13
		ret
GridDamageTile ENDP

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
		mov rdx, 0300000000h
		test rax, rdx
		jnz return_impassible 
	; check tile state (and return if its uninitialized)
		mov rcx, rax 
		mov rdx, 0C00000000h
		and rcx, rdx
		jz return_basic_block
	; check if tile is clear
		mov rdx, 0400000000h
		cmp rcx, rdx
		je return_clear_path
	; check if tile has health
		mov rdx, 0800000000h
		cmp rcx, rdx
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
GridTilePathingCost ENDP
	


; rcx: hdc
GridRender PROC
	; config locals
		push r12 ; src tile Y, then actor ptr
		push r13 ; src tile X
		push r14 ; tile Y
		push r15 ; tile X
		push rbx ; last X
		push rbp ; hdc
		; rsp+0 : last Y
		mov rbp, rcx
	; load camera values
		mov r13d, dCameraX
		mov r14d, dCameraY
	; calc amount of tiles onscreen
		; get sub-tile camera offset
			mov ebx, r13d
			mov eax, r14d
			and ebx, 31
			and eax, 31
		; add in screen size
			add ebx, dWinX
			add eax, dWinY
		; dec so we dont render an extra tile with count is perfectly even
			dec ebx
			dec eax 
		; convert pixel size to tile size
			shr ebx, 5
			shr eax, 5
	; convert camera position to tile position
		shr r13d, 5
		shr r14d, 5
	; get our last position indexes
		add ebx, r13d
		add eax, r14d
		push rax
	; reset X pos
		mov r15d, r13d
	; store Y reset for 2nd pass
		mov r12d, r14d 

	; iterate through terrain sprites
		loop_row:
			; iterate through columns
				loop_column:
					; access tile
						mov edx, r14d
						mov ecx, r15d
						call GridAccessTile
					; convert tile coords to world coords
						mov r8d, r15d ; X
						mov r9d, r14d ; Y
						shl r8d, 5
						shl r9d, 5
					; push hdc and call render
						mov rcx, rbp ; hdc
						call DrawTerrainSprite
					; increment
						inc r15d
					; break if finished
						cmp r15d, ebx
						jg finish_columns
				jmp loop_column
				finish_columns:
			; increment
				mov r15d, r13d
				inc r14d
			; break if finished
				cmp r14d, dword ptr [rsp] ; last Y
				jg finish_loop
		jmp loop_row
		finish_loop:

		
	; reset Y pos
		mov r14d, r12d
	; reset X pos
		mov r15d, r13d
	; iterate through actor sprites
		__loop_row:
			; iterate through columns
				__loop_column:
					; access tile
						mov edx, r14d
						mov ecx, r15d
						call GridAccessTile
					; render actor
						mov r8, 0300000000h
						test rax, r8
						jz c04
							mov ecx, eax ; get actor handle
							call ActorPtrFromHandle
							mov r12, rax ; actor ptr (does not matter if its null)
							mov rcx, rbp ; hdc
							call ActorBankRender
						c04: 
					; increment
						inc r15d
					; break if finished
						cmp r15d, ebx
						jg __finish_columns
				jmp __loop_column
				__finish_columns:
			; increment
				mov r15d, r13d
				inc r14d
			; break if finished
				cmp r14d, dword ptr [rsp] ; last Y
				jg __finish_loop
		jmp __loop_row
		__finish_loop:
	



	; return
		add rsp, 8
		pop rbp
		pop rbx
		pop r15
		pop r14
		pop r13
		pop r12
		ret
GridRender ENDP

END