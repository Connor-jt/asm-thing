


neighbor_grid byte 256 dup(0)

next_neighbor_list byte 256 dup(0)
next_neighbor_list_count dword 0
next_neighbor_best_index dword -1

current_best_value dword 0

; nearby pathing tile grid
; 0000 0011 : source direction
; 1111 1100 : tile cost (max 63);

; next best step list
; 1111 0000 : x coord
; 0000 1111 : y coord

src_y dword 0
src_x dword 0

local_to_world_y dword 0
local_to_world_x dword 0

local_dest_y dword 0
local_dest_x dword 0

.code



; 16x16 grid of nearest neighbors??
; each one is 1 byte

; r9d: dest y
; r8d: dest x
; edx: src y
; ecx: src x
BeginPathfind PROC
	; reset vars
		mov next_neighbor_list_count, 0
		xor eax, eax
		lea rsi, next_neighbor_list
		b47: 
			mov qword ptr [rsi + eax*8], 0
			inc eax
			cmp eax, 32
			jge b48
			jmp b47
		b48:
	; if destination is outside of our local grid, find next best spot
		; if dest Y > farthest neighbor node
			mov eax, edx
			add eax, 15
			cmp eax, r9d
			jle b43
				mov r9d, eax
				jmp b44
			b43:
		; if dest Y < farthest neighbor node
			sub eax, 31
			cmp eax, r9d
			jge b44
				mov r9d, eax
			b44:
		; if dest X > farthest neighbor node
			mov eax, ecx
			add eax, 15
			cmp eax, r8d
			jle b45
				mov r8d, eax
				jmp b46
			b45:
		; if dest X < farthest neighbor node
			sub eax, 31
			cmp eax, r8d
			jge b46
				mov r8d, eax
			b46:
	; make our vars more globally accessible
		mov src_x, ecx
		mov src_y, edx
		mov dest_x, r8d
		mov dest_y, r9d

	; dump our initial 4 connections onto the list
	
	; start recursive thingo search?
	mov edx ; Y coord
	mov ecx ; X coord
	call ProcessTile

	; if we maxed out our node value thing
	; then we need to run a new algorithm to figure out what tile we reached that was the closest to the destination, and just backtrack from there
	
BeginPathfind ENDP


; edx: y (local grid index)
; ecx: x (local grid index)
; esi: value
; r11d: direction (2 bits, 00-01-10-11)
ProcessTile PROC
	; convert direction bits into local coords
		cmp r11d, 0
		jne b56
			
			jmp finish_direction_checks
		b56:

	finish_direction_checks:
	; calculate the distance
		; Y dist
			mov eax, edx
			sub eax, local_dest_y
			jge b53
				neg eax
			b53:
			add esi, eax
		; X dist
			mov eax, ecx
			sub eax, local_dest_x
			jge b54
				neg eax
			b54:
			add esi, eax
	; generate local tile index
		mov r10d, ecx
		shl r10d, 4
		or r10d, edx
	; if this tile is marked as too expensive, dont bother reprocessing, cause we have probably already fully evaluated this node
		lea rdi, neighbor_grid
		movzx edi, byte ptr [rdi + r10]
		shr edi, 2
		cmp edi, 63
		jge skip_tile_processing
	; convert our local coords into world tile coords
		add edx, local_to_world_y
		add ecx, local_to_world_x
	; get cost of traversing this tile
		call GridTilePathingCost
		add esi, eax
		inc esi ; inc to account for dist of tile
	; if we have not previously processed this tile, process it
		cmp edi, 0
		je write_tile
	; else if this route is more expensive, skip
		cmp esi, edi
		jge skip_tile_processing
	; else this route is cheaper, so write it in
	write_tile:
		lea rdi, neighbor_grid
		movzx edi, byte ptr [rdi + r10]
	skip_tile_processing:
		ret
ProcessTile ENDP

