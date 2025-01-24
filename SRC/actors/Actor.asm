
exterm ReleaseActor


.code


ActorStepHelper PROC
	; get grid tile of target position
		mov edx, r14d ; y
		mov ecx, r13d ; x
		call GridAccessTile
	; if tile has actors on it
		test rax, 0300000000h
		jnz return 
	; if tile uninitialized
		mov rcx, rax 
		and rcx, 0C00000000h
		jz damage_tile
	; if tile has health
		cmp rcx, 0800000000h
		je damage_tile
	; if tile is clear
		cmp rcx, 0400000000h
		je move_tile
	; otherwise indestructible blocker 
		jmp return
	damage_tile:
		mov r8d, 1 ; damage  ; TODO: hook up unit damage value here??
		mov edx, r14d ; y
		mov ecx, r13d ; x
		call GridDamageTile
		call ActorResetCooldown
		jmp return
	move_tile:
		; write new pos
			mov r8d, dword ptr [r12] ; handle
			mov edx, r14d ; y
			mov ecx, r13d ; x
			call GridWriteActorAt
		; return success
			mov rax, 1
			ret
	return:
		xor rax, rax
		ret
ActorStepHelper ENDP


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
					; set left facing animation
						and byte ptr [r12+4], 199
						or  byte ptr [r12+4], 24
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
					; run mov to new tile logic
						call ActorStepHelper
						cmp eax, 0
						jne b93 ; skip the rest if we did not actually move
					; clear old pos
						inc r13d ; restore og position value
						mov edx, r14d ; y
						mov ecx, r13d ; x
						call GridClearActorAt
					; set all X offset bits, so X offset is now 31
						or word ptr [r12+12], 03E0h
						jmp b93
				right:
					inc r13d
					; set right facing animation
						and byte ptr [r12+4], 199
						or  byte ptr [r12+4], 32
					; get X offset
						movzx eax, word ptr [r12+12]
						shr eax, 5
						and eax, 31
					; if not immienent tile jump, just add offset
						cmp eax, 31
						jle b95:
							add word ptr [r12+12], 32
							jmp b93
						b95:
					; run mov to new tile logic
						call ActorStepHelper
						cmp eax, 0
						jne b93 ; skip the rest if we did not actually move
					; clear old pos
						dec r13d ; restore og position value
						mov edx, r14d ; y
						mov ecx, r13d ; x
						call GridClearActorAt
					; clear all X offset bits, so X offset is now 0
						and word ptr [r12+12], 0FC1Fh
						jmp b93
				top:
					dec r14d
					; set top facing animation
						and byte ptr [r12+4], 199
						or  byte ptr [r12+4], 8
					; get Y offset
						movzx eax, word ptr [r12+12]
						and eax, 31
					; if not immienent tile jump, just sub offset
						cmp eax, 0
						jle b96:
							dec word ptr [r12+12]
							jmp b93
						b96:
					; run mov to new tile logic
						call ActorStepHelper
						cmp eax, 0
						jne b93 ; skip the rest if we did not actually move
					; clear old pos
						inc r14d ; restore og position value
						mov edx, r14d ; y
						mov ecx, r13d ; x
						call GridClearActorAt
					; set all Y offset bits, so Y offset is now 31
						or word ptr [r12+12], 31 
						jmp b93
				bottom:
					; inc Y
					inc r14d
					; set bottom facing animation
						and byte ptr [r12+4], 199
						or  byte ptr [r12+4], 48
					; get Y offset
						movzx eax, word ptr [r12+12]
						and eax, 31
					; if not immienent tile jump, just add offset
						cmp eax, 31
						jle b97:
							inc word ptr [r12+12]
							jmp b93
						b97:
					; run mov to new tile logic
						call ActorStepHelper
						cmp eax, 0
						jne b93 ; skip the rest if we did not actually move
					; clear old pos
						dec r14d ; restore og position value
						mov edx, r14d ; y
						mov ecx, r13d ; x
						call GridClearActorAt
					; set all Y offset bits, so Y offset is now 31
						and word ptr [r12+12], 0FFE0h
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
				;mov r9b, byte ptr [r12+4]
				;and r9b, 199 ; clears bits 0b00111000
				;or r9b, r8b
				;mov byte ptr [r12+4], r9b

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
	; get stats
	; write cooldown stat to actor
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