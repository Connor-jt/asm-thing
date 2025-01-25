
ReleaseActor PROTO
GridAccessTile PROTO
GridDamageTile PROTO
GridWriteActorAt PROTO
BeginPathfind PROTO
GridClearActorAt PROTO
GetActorStatsFromPtr PROTO
ActorPtrFromHandle PROTO 
ReleaseActor PROTO

.code


ActorStepHelper PROC
	; get grid tile of target position
		mov edx, r14d ; y
		mov ecx, r13d ; x
		call GridAccessTile
	; if tile has actors on it
		shr rax, 32
		test rax, 03h
		jnz return ; TODO: auto attack if an enemy is on the tile
	; if tile uninitialized
		and rax, 0Ch
		jz damage_tile
	; if tile has health
		cmp rax, 08h
		je damage_tile
	; if tile is clear
		cmp rax, 04h
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
					push rcx ; store for later
					movzx r9d, word ptr [r12 + 18] ; dest Y
					movzx r8d, word ptr [r12 + 16] ; dest X
					movzx edx, word ptr [r12 + 10] ; src Y
					movzx ecx, word ptr [r12 + 8]  ; src X
					call BeginPathfind
					; if pathfind failed, complete objective
					cmp eax, 64
					jl complete_objective
					; otherwise, paste that info into our actor position state
					pop rcx
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
						jle b94
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
					; write tile change
						dec word ptr [r12 + 8]  ; src X
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
						jle b95
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
					; write tile change
						inc word ptr [r12 + 8]  ; src X
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
						jle b96
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
					; write tile change
						dec word ptr [r12 + 10] ; src Y
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
						jle b97
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
					; write tile change
						inc word ptr [r12 + 10] ; src Y
				b93:
				pop r14
				pop r13
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
	call GetActorStatsFromPtr
	; write cooldown stat to actor
	mov byte ptr [r12 + 7], al
	ret
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