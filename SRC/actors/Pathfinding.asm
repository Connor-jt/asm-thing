


neighbor_grid byte 256 dup(0)

next_neighbor_list byte 256 dup(0)
next_neighbor_list_count dword 0

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
	; dump our initial 4 connections onto the list
	
	; start recursive thingo search?
	call ProcessTile

	
BeginPathfind ENDP


; r11d: y
; r10d: x
; esi: value
ProcessTile PROC
	; generate local tile index
		mov eax, r11d
		shl eax, 4
		or eax, r10d
	; if this tile is marked as too expensive, dont bother reprocessing, cause we have probably already fully evaluated this node
		lea edi, neighbor_grid
		cmp byte ptr [edi + eax], 252
		jl b49
			ret
		b49:
	; get cost of traversing this tile
		call GridIsTileClear
	; 
ProcessTile ENDP

