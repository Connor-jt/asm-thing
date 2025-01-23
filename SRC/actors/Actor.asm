
exterm ReleaseActor


.code



; r12: actor ptr (pass through)
ActorTick PROC
	; if action cooldown is active, skip objectives till the cooldown is over
		cmp byte ptr[r12+7], 0
		jne b91
			dec byte ptr[r12+7]
			jmp skip_objective
		b91:
	; check objective type
		movzx eax, byte ptr [r12+4]
		shr eax, 1
		and eax, 3
		cmp eax, 1
		jl skip_objective  ; 00: means no objective
		je move_objective  ; 01: means moveto
		cmp eax, 2
		je skip_objective  ; 10: means attack
		jmp skip_objective ; 11: means UNDEFINED objective

		move_objective:
			; check for predetermined next nodes to go to
			movzx ecx, byte ptr [r12+13]
			cmp ecx, 64
			; if no predetermined steps, run pathfind
			jge b92
				push ecx ; store for later
				movzx r9d, word ptr [r12 + 18] ; dest Y
				movzx r8d, word ptr [r12 + 16] ; dest X
				movzx edx, word ptr [r12 + 10] ; src Y
				movzx ecx, word ptr [r12 + 8]  ; src X
				call BeginPathfind
				; if pathfind failed, complete objective
				cmp eax, 64
				jl complete_objective
				; otherwise, paste that info into our actor position state
				pop ecx
				and ecx, 3 ; clear bits
				or ecx, eax ; write bits
				mov byte ptr [r12+13], cl
			b92:

			; strip out next step from direction bits
				shr ecx, 4
				and ecx, 3
			; config vars
				push r13 ; x 
				push r14 ; y
				movzx r13d, word ptr [r12 + 8]  ; src X
				movzx r14d, word ptr [r12 + 10] ; src Y
			; handle direction
				cmp ecx, 2
				je bottom
				jg right
				cmp ecx, 1
				je top
				;left
					dec r13d
					; get X offset
						movzx eax, word ptr [r12+12]
						shr eax, 5
						and eax, 31
					; if not immienent tile jump, just sub offset
						cmp eax, 0
						jle b94:
							sub word ptr [r12+12], 32
							jmp b93
						b94:
					; check grid map to make sure the tile is clear
						mov edx, r14d ; y
						mov ecx, r13d ; x
						call GridAccessTile
					; check if tile has actors on it
						test rax, 0300000000h
						jnz b93 
					; check tile state (and return if its uninitialized)
						mov rcx, rax 
						and rcx, 0C00000000h
						jz left_damage_tile
					; check if tile has health
						cmp rcx, 0800000000h
						je left_damage_tile
					; check if tile is clear
						cmp rcx, 0400000000h
						je left_move_tile
					; otherwise indestructible blocker 
						jmp b93
					left_damage_tile:
						; and then reset action cooldown
						mov r8d, 1 ; damage  ; TODO: hook up unit damage value here??
						mov edx, r14d ; y
						mov ecx, r13d ; x
						call GridDamageTile
						call ActorResetCooldown
						jmp b93
					left_move_tile:
						;and word ptr [r12+12], 0FC1Fh ; clear all X offset bits, so X offset is now 0
						; set all X offset bits, so X offset is now 31
							or word ptr [r12+12], 03E0h 
						; write new pos
							mov r8d, dword ptr [r12]
							mov edx, r14d
							mov ecx, r13d
							call GridWriteActorAt
						; clear old pos
							inc r13d ; restore og position value
							mov edx, r14d
							mov ecx, r13d
							call GridClearActorAt
						jmp b93
				right:
					; inc X
				top:
					; dec Y
				bottom:
					; inc Y
				b93:
				pop r14
				pop r13


			;; move unit 
			;	mov r10d, dword ptr [r12+16] ; target x
			;	mov r11d, dword ptr [r12+20] ; target y
			;	sub r10d, dword ptr [r12+ 8] ; src x
			;	sub r11d, dword ptr [r12+12] ; src y
			;	mov r8b, 4 ; unit direction
			;; calc X movement
			;	cmp r10d, 0
			;	; if offs_X != 0
			;	jz b12
			;		; if offs_X > 0
			;		jl b13
			;			inc dword ptr [r12+ 8] ; src x
			;			inc r8b
			;		jmp b12
			;		; if offs_X < 0
			;		b13:
			;			dec dword ptr [r12+ 8] ; src x
			;			dec r8b
			;	b12:
			;; calc Y movement
			;	cmp r11d, 0
			;	; if offs_Y != 0
			;	jz b14
			;		; if offs_Y > 0
			;		jl b15
			;			inc dword ptr [r12+12] ; src y
			;			add r8b, 3
			;		jmp b14
			;		; if offs_Y < 0
			;		b15:
			;			dec dword ptr [r12+12] ; src y
			;			sub r8b, 3
			;	b14:


			; apply unit direction
				;cmp r8b, 4
				;jle b17	; index 4 does not actually exist, so we have to decrement each index past that
				;	dec r8b
				;b17:
				;shl r8b, 3
				mov r9b, byte ptr [r12+4]
				and r9b, 199 ; clears bits 0b00111000
				or r9b, r8b
				mov byte ptr [r12+4], r9b

			; delete unit once they reach their destination
			;	cmp r10d, 0
			;	jne b16
			;		cmp r11d, 0
			;		jne b16
			;			; subtract health
			;			dec byte ptr [r12+6] ; health
			;			;cmp byte ptr [r12+6], 0
			;			jnz skip_objective
			;
			;			; die if health <= 0 
			;			mov rcx, r12
			;			call ReleaseActor
			;			ret	
			;	b16:
			jmp skip_objective

		complete_objective:
			and byte ptr [r12+4], 249 ; clear objective bits
		skip_objective:

	; return
		ret
ActorTick ENDP

; r12: actor ptr (pass through)
ActorResetCooldown PROC
	
ActorResetCooldown ENDP

; r8d: damage amount
; ecx: actor handle
ActorTakeDamage PROC
	; fetch actor pointer
		call ActorPtrFromHandle
		cmp rax, 0
		je return
	; get health
		movzx edx, byte ptr [rax + 6]
	; dewal damage, call unit death if no health left
		sub edx, r8d
		jle kill_actor
		mov byte ptr [rax + 6], dl 
		jmp return
	kill_actor:
		mov rcx, rax
		call ReleaseActor
	return:
		ret
ActorTakeDamage ENDP

END