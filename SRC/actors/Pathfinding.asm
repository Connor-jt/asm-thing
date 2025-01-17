


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
dest_y dword 0
dest_x dword 0

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

	
BeginPathfind ENDP


; edx: y
; ecx: x
; esi: value
ProcessTile PROC
	; generate local tile index
		mov eax, r11d
		shl eax, 4
		or eax, r10d
	; if this tile is marked as too expensive, dont bother reprocessing, cause we have probably already fully evaluated this node
		lea rdi, neighbor_grid
		movzx edi, byte ptr [rdi + rax]
		shr edi, 2
		cmp edi, 63
		jl b49
			ret
		b49:
	; get cost of traversing this tile
		call GridTilePathingCost
		add esi, eax
		inc esi ; add 1 to the cost, to account for the cost of actually moving to the tile
	; then add on the deviation of this node
		
		; which is simply finding the distance between this tile and the dest tile
		; and add that to our current value

	; now check if route is cheaper to this node OR if prev value was 0
		cmp esi, edi

	; 
ProcessTile ENDP

