
exterm ReleaseActor


.code



; r12: actor ptr (pass through)
ActorTick PROC
	
	; if current objective is move_to
		mov al, byte ptr [r12+4]
		and al, 30h
		cmp al, 16
		jne skip_objective
			; check if we have any predetermined next nodes to go to
			; if not, then call the pathfinding function so we can generate a new set of directions
			; if the resulting list is null, then we have arrived at our destination??

			; move unit 
				mov r10d, dword ptr [r12+16] ; target x
				mov r11d, dword ptr [r12+20] ; target y
				sub r10d, dword ptr [r12+ 8] ; src x
				sub r11d, dword ptr [r12+12] ; src y
				mov r8b, 4 ; unit direction
			; calc X movement
				cmp r10d, 0
				; if offs_X != 0
				jz b12
					; if offs_X > 0
					jl b13
						inc dword ptr [r12+ 8] ; src x
						inc r8b
					jmp b12
					; if offs_X < 0
					b13:
						dec dword ptr [r12+ 8] ; src x
						dec r8b
				b12:
			; calc Y movement
				cmp r11d, 0
				; if offs_Y != 0
				jz b14
					; if offs_Y > 0
					jl b15
						inc dword ptr [r12+12] ; src y
						add r8b, 3
					jmp b14
					; if offs_Y < 0
					b15:
						dec dword ptr [r12+12] ; src y
						sub r8b, 3
				b14:
			; apply unit direction
				cmp r8b, 4
				jle b17	; index 4 does not actually exist, so we have to decrement each index past that
					dec r8b
				b17:
				shl r8b, 3
				mov r9b, byte ptr [r12+4]
				and r9b, 199 ; clears bits 0b00111000
				or r9b, r8b
				mov byte ptr [r12+4], r9b

			; delete unit once they reach their destination
				cmp r10d, 0
				jne b16
					cmp r11d, 0
					jne b16
						; subtract health
						dec byte ptr [r12+6] ; health
						;cmp byte ptr [r12+6], 0
						jnz skip_objective

						; die if health <= 0 
						mov rcx, r12
						call ReleaseActor
						ret	
				b16:
		skip_objective:

	; return
		ret
ActorTick ENDP


END