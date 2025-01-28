GridTilePathingCost PROTO

.data 
neighbor_grid byte 256 dup(0)

next_neighbor_list byte 256 dup(0)

next_neighbor_skip dword 0

; nearby pathing tile grid
; 0000 0011 : source direction
; 1111 1100 : tile cost (max 63);

; next neighbor list
; 0000 1111 : x coord
; 1111 0000 : y coord

src_y dword 0
src_x dword 0

local_to_world_y dword 0
local_to_world_x dword 0

local_dest_y dword 0
local_dest_x dword 0

; temp vars ;
	temp_x dword 0
	temp_y dword 0
	temp_value dword 0
; ;

.code



; 16x16 grid of nearest neighbors??
; each one is 1 byte

; r9d: dest y
; r8d: dest x
; edx: src y
; ecx: src x
BeginPathfind PROC
	; prematurely skip if src & dst are the same
		cmp ecx, r8d
		jne b68
			cmp edx, r9d
			je return_empty
		b68:
	; reset vars
		push r12
		push r13
		push r14
		push r15
		push rbx
		push rbp
		xor r12d, r12d ; count
		xor r13d, r13d ; index
		mov r14d, -1   ; shortcut_index
		mov r15d,  1   ; current_route_cost
		xor  ebx,  ebx ; skip_count
	   ;xor  ebp,  ebp ; is shortcuting
	; clear grid
		xor eax, eax
		lea rsi, neighbor_grid
		b47: 
			mov qword ptr [rsi + rax*8], 0
			inc eax
			cmp eax, 32
			jge b48
			jmp b47
		b48:
	; if destination is outside of our local grid, find next best spot
		; if dest Y > farthest neighbor node
			mov eax, edx
			add eax, 7
			cmp r9d, eax
			jle b43
				mov r9d, eax
				jmp b44
			b43:
		; if dest Y < farthest neighbor node
			sub eax, 15
			cmp r9d, eax 
			jge b44
				mov r9d, eax
			b44:
		; if dest X > farthest neighbor node
			mov eax, ecx
			add eax, 7
			cmp r8d, eax
			jle b45
				mov r8d, eax
				jmp b46
			b45:
		; if dest X < farthest neighbor node
			sub eax, 15
			cmp r8d, eax
			jge b46
				mov r8d, eax
			b46:
	; make our vars more globally accessible
		mov src_x, ecx
		mov src_y, edx
	; get our grid top-left world position
		sub ecx, 8
		sub edx, 8
		mov local_to_world_x, ecx
		mov local_to_world_y, edx
	; get our local destination position
		sub r8d, ecx
		sub r9d, edx
		mov local_dest_x, r8d
		mov local_dest_y, r9d

	; write our origin node into the grid (actually i dont think we need to do this)
		lea rax, neighbor_grid
		mov byte ptr [rax + 136], 0FFh

	; dump our initial 4 connections onto the list
		; left 
			mov edx,  8 ; src Y
			mov ecx,  8 ; src X
			mov esi,  0 ; value
			mov r11d, 0 ; dir: left
			call ProcessTile
		; right 
			mov edx,  8 ; src Y
			mov ecx,  8 ; src X
			mov esi,  0 ; value
			mov r11d, 3 ; dir: right
			call ProcessTile
		; top 
			mov edx,  8 ; src Y
			mov ecx,  8 ; src X
			mov esi,  0 ; value
			mov r11d, 1 ; dir: top
			call ProcessTile
		; bottom 
			mov edx,  8 ; src Y
			mov ecx,  8 ; src X
			mov esi,  0 ; value
			mov r11d, 2 ; dir: bottom
			call ProcessTile
	; if its ever possible to not process any neighbors, then just skip the whole thing
		cmp r12d, 0
		je return_empty

	; begin looping through all nieghbors to search through our path thing
	b59:
		; get current neighbor
			lea rax, next_neighbor_list
			; if we have a shortcut index, then use that one and mark to skip incrementing index
			cmp r14d, -1
			je b85
				movzx ecx, byte ptr [rax + r14]
				mov ebp, r14d ; yes shortcut
				mov r14d, -1 ; clear has shortcut value
				jmp b86
			b85:
				movzx ecx, byte ptr [rax + r13]
				mov ebp, -1 ; no shortcut
			b86:
		; if this neighbor is the destination then start backtrace?????
			; check X
			mov edx, ecx
			and edx, 15
			cmp edx, local_dest_x
			jne b69
				; check Y
				mov edx, ecx
				shr edx, 4
				cmp edx, local_dest_y
				je loop_break
			b69:

		; get their info from the grid
			lea rdx, neighbor_grid
			movzx esi, byte ptr [rdx + rcx]
		; if tile matches our current route cost, then check it out
			mov edi, esi ; so we can get the direction bits later
			shr esi, 2
			cmp esi, r15d
			jne b61
				; increment skip index if this is the first item in the list
					cmp r13d, ebx
					jne b62
						inc ebx
					b62:
				; mark this tile as evaluated
					or byte ptr [rdx + rcx], 252

				; unpack coords and push them to temp r/m
					; write Y
					mov edx, ecx
					shr edx, 4
					mov temp_y, edx
					; write X
					and ecx, 15
					mov temp_x, ecx
					; write value
					mov temp_value, esi
				; begin evaluating node
					and edi, 3
					cmp edi, 2
					je b70
					jg b71
					cmp edi, 1
					je b72
					; NOTE: first 3 inputs of the func call are already set !!!!!!
					; left (00)
						mov r11d, 3			 ; dir: right
						call ProcessTile
						mov edx,  temp_y	 ; src Y
						mov ecx,  temp_x	 ; src X
						mov esi,  temp_value ; value
						mov r11d, 1			 ; dir: top
						call ProcessTile
						mov edx,  temp_y	 ; src Y
						mov ecx,  temp_x	 ; src X
						mov esi,  temp_value ; value
						mov r11d, 2			 ; dir: bottom
						call ProcessTile
						jmp b61
					b71: ; right (11)
						mov r11d, 0			 ; dir: left
						call ProcessTile
						mov edx,  temp_y	 ; src Y
						mov ecx,  temp_x	 ; src X
						mov esi,  temp_value ; value
						mov r11d, 1			 ; dir: top
						call ProcessTile
						mov edx,  temp_y	 ; src Y
						mov ecx,  temp_x	 ; src X
						mov esi,  temp_value ; value
						mov r11d, 2			 ; dir: bottom
						call ProcessTile
						jmp b61
					b72: ; top (01)
						mov r11d, 0			 ; dir: left
						call ProcessTile
						mov edx,  temp_y	 ; src Y
						mov ecx,  temp_x	 ; src X
						mov esi,  temp_value ; value
						mov r11d, 3			 ; dir: right
						call ProcessTile
						mov edx,  temp_y	 ; src Y
						mov ecx,  temp_x	 ; src X
						mov esi,  temp_value ; value
						mov r11d, 2			 ; dir: bottom
						call ProcessTile
						jmp b61
					b70: ; bottom (10)
						mov r11d, 0			 ; dir: left
						call ProcessTile
						mov edx,  temp_y	 ; src Y
						mov ecx,  temp_x	 ; src X
						mov esi,  temp_value ; value
						mov r11d, 3			 ; dir: right
						call ProcessTile
						mov edx,  temp_y	 ; src Y
						mov ecx,  temp_x	 ; src X
						mov esi,  temp_value ; value
						mov r11d, 1			 ; dir: top
						call ProcessTile
			b61:
		

		; if shortcut taken, skip increment
			cmp ebp, -1
			jne b59
		; if current index >= count, then start the search over & bump the route cost 
			inc r13d
			cmp r13d, r12d
			jl b60
				inc r15d
				mov r13d, ebx
				; if current route value is the max (63) break out of the loop
				cmp r15d, 63
				je find_best_match_loop
			b60:
	jmp b59

	find_best_match_loop:
		xor r13d, r13d ; new index
		mov r14d, 255 ; best distance tracker
		xor r15d, r15d ; best distance neighbor index
		lea rsi, next_neighbor_list
		;lea rdi, neighbor_grid
		b63:
			; get current neighbor
				movzx eax, byte ptr [rsi + r13]
			; get their info from the grid
			;	movzx eax, byte ptr [rdi + rcx]
			;	shr eax, 2
			; calculate the distance
				; Y dist
					mov ecx, eax
					shr ecx, 4
					sub ecx, local_dest_y
					jge b64
						neg ecx
					b64:
				; X dist
					and eax, 15
					sub eax, local_dest_x
					jge b65
						neg eax
					b65:
					add ecx, eax
			; check if this tile is closer than previous tiles
				cmp ecx, r14d
				jge b66
					mov r14d, ecx
					mov r15d, r13d
				b66:
			; iterate, break once we pass the last index
				inc r13
				cmp r13, r12
				jge find_best_match_break
		jmp b63
	find_best_match_break:
		mov r13d, r15d
		jmp c13
	loop_break:
		; check if we finished on a shortcut index or not
		cmp ebp, -1
		je c13
			mov r13d, ebp
		c13:


	; break indexed tile into coords
		lea rsi, neighbor_grid
		lea rax, next_neighbor_list
		movzx edx, byte ptr [rax + r13]
	; reset vars
		xor ecx, ecx ; step count
		xor eax, eax ; direction instructions
		
	retrace_loop:
		; check if we have made it back to the start
			cmp edx, 136 ; 0b10001000 (which is the middle of the grid. AKA our start point)
			je break_retrace

		; get directions from our current tile
			movzx edi, byte ptr [rsi + rdx]
			and edi, 3
		; then update our coords based on direction
			cmp edi, 2
			je b80
			jg b81
			cmp edi, 1
			je b82
			; left (00, dec X)
				dec edx
			jmp b83
			b81: ; right (11, inc X)
				inc edx
			jmp b83
			b82: ; top (01, dec Y)
				sub edx, 16
			jmp b83
			b80: ; bottom (10, inc Y)
				add edx, 16
		b83:
		; plop the directions onto the stack
			; make room
				shr eax, 2
			; invert current direction
				not edi
				and edi, 3
			; shift into place
				shl edi, 4
				or eax, edi

		inc ecx
	jmp retrace_loop
	break_retrace:

	; compile instructions into byte (or upper 6 bits rather)
		; clamp instruction count
			cmp ecx, 2
			jle b84
				mov ecx, 2
			b84:
		; shift into place
			shl ecx, 6
			and eax, 60
			or eax, ecx

	; release all resources and return, we made it !!!!  
		pop rbp
		pop rbx
		pop r15
		pop r14
		pop r13
		pop r12
		ret
	return_empty:
		xor eax,eax
		ret
BeginPathfind ENDP


; edx: y (local grid index)
; ecx: x (local grid index)
; esi: value
; r11d: direction (2 bits, 00-01-10-11)
ProcessTile PROC
	; convert direction bits into local coords
	; if our direction leads us outside of the grid bounds, then the tile does not exist, so skip
		cmp r11d, 2
		; if dir == 10 (bottom)
			je bottom
		; if dir == 11 (right)
			jg right
		cmp r11d, 1
		; if dir == 01 (top)
			je top
		; if dir == 00 (left)
	   ;left
			dec ecx
			cmp ecx, 0 ; todo: pretty sure the flag we need here is already set from the previous instruction
			jl skip_tile_processing
			jmp finish_direction_checks
		right:
			inc ecx
			cmp ecx, 16
			jge skip_tile_processing
			jmp finish_direction_checks
		top:
			dec edx
			cmp edx, 0 ; todo: pretty sure the flag we need here is already set from the previous instruction
			jl skip_tile_processing
			jmp finish_direction_checks
		bottom:
			inc edx
			cmp edx, 16
			jge skip_tile_processing
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
		mov r10d, edx
		shl r10d, 4
		or r10d, ecx
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
		; ensure that our cost fits in our (63) limit
			cmp esi, 63
			jle b67
				mov esi, 63
			b67:
		; write as neighbor (if tile has not been evaluated yet)
			cmp edi, 0
			jne b58
			; if this node is on par with our current route, then shortcut it for our next evaluation
				cmp esi, r15d
				jg b57 ; NOTE: this should also include less than, but that would be an impossible state to reach
					mov r14, r12
				b57:
			; save tile to processed neighbor list (but not if this tile has not been processed yet)
				lea rax, next_neighbor_list
				mov byte ptr [rax + r12], r10b ; array exceeded check?? (impossible?)
				inc r12
			b58:
		; write into grid
			; pack our value and put our src direction bits in there too
				shl esi, 2
				not r11d
				and r11d, 3
				or esi, r11d
			; save to grid
				lea rdi, neighbor_grid
				mov byte ptr [rdi + r10], sil
	skip_tile_processing:
		ret
ProcessTile ENDP

END