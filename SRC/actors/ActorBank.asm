DrawActorSprite	PROTO
TryDrawActorHealth PROTO
ActorTick PROTO
GridAccessTile PROTO
GridWriteActorAt PROTO
ConsolePrint PROTO

extern dCameraX : dword
extern dCameraY : dword

public dActorList
public dLastActorIndex

SIZEOF_Actor EQU 24
PUBLIC SIZEOF_Actor

.data

dActorList byte 98256 dup(0) ; 24 bytes x 4094 actors ; we dont use the last one because the index is unusable, as its -1, which we will use for handles that are invalid
dLastActorIndex qword 0 ; index * 24
dFirstFreeIndex qword 0 ; index * 24

actor_placement_failed_str word 'a','c','t','o','r',' ','p','l','a','c','e','m','e','n','t',' ','b','l','o','c','k','e','d','!','!',0
actor_placement_success_str word 'a','c','t','o','r',' ','s','u','c','c','e','s','f','u','l','l','y',' ','c','r','e','a','t','e','d','.',0

; Actor struct
;	0h, 4 : handle
;	4h, 1 : state
;	5h, 1 : ???
;	6h, 1 : health
;	7h, 1 : action cooldown
;	8h, 2 : tile_x
;	Ah, 2 : tile_y
;	Ch, 2 : position_state
;	Eh, 2 : ???
;  10h, 4 : attack_target (NOTE: overlaps with dest X/Y)
;  10h, 2 : dest_x
;  12h, 2 : dest_y
;  14h, 4 : ???

; Actor Handle
; 11111111 11110000 00000000 00000000 : entity index (if set to -1 on the actor, it will invalidate the actor)
; 00000000 00001111 11111111 00000000 : index handle (allowing 4k reuses)
; 00000000 00000000 00000000 11111111 : actor handle type (allowing 256 types)
; +3       +2       +1       +0

; Actor State
; 11000000 : animation state (00: none, 01: stepping, 10: actioning, 11: dying)
; 00111000 : direction/death animation step
; 00000110 : objective state (00: none, 01: moveto, 10: attack, 11: ???)
; 00000001 : team (0: player, 1: enemy)

; Actor Position State
; 11000000 00000000 : queued_steps (00: none, 01: step_1 is valid, 10: step_2 is valid, 11: ???)
; 00110000 00000000 : queued_step_1
; 00001100 00000000 : queued_step_2
; 00000011 11100000 : tile_offset_x (unsigned)
; 00000000 00011111 : tile_offset_y (unsigned)
; +1       +0


dActorStatsList qword	0000000203401010h, ; basic infantry
						0h
; Actor stats struct
;	00000000000000FF : max action cooldown
;	000000000000FF00 : max health
;	0000000000FF0000 : range
;	00000000FF000000 : damage
;	000000FF00000000 : movement interval (or other movement data??)
;	0000FF0000000000 : ??? (this should contain actor flags? can move, can attack, ???)
;	00FF000000000000 : ???
;	FF00000000000000 : ???
;   +7  +5  +3  +1
;     +6  +4  +2  +0

.code

; rcx: unit type
GetActorStats PROC
	lea rax, dActorStatsList
	mov rax, qword ptr [rax+rcx*8]
	ret
GetActorStats ENDP

; r12: unit ptr (pass through)
GetActorStatsFromPtr PROC
	movzx ecx, byte ptr [r12]
	call GetActorStats
	ret
GetActorStatsFromPtr ENDP





; rcx: actor ptr (pass through)
; out rax: x pos
; out rdx: y pos
GetActorWorldPos PROC
	; get actor tile position (sign extend so our negatives are fine)
		movsx eax, word ptr [rcx+8]
		movsx edx, word ptr [rcx+10]
	; adjust for pixel position
		shl eax, 5
		shl edx, 5
	; apply Y local tile offsets
		movzx r8d, byte ptr [rcx+12]
		and r8d, 31
		add edx, r8d
	; apply X local tile offsets
		movzx r8d, word ptr [rcx+12]
		shr r8d, 5
		and r8d, 31
		add eax, r8d
	; return
		ret
GetActorWorldPos ENDP

; rcx: actor ptr (pass through)
; out eax: x pos
; out edx: y pos
GetActorScreenPos PROC
	; get actual position
		call GetActorWorldPos
	; adjust for screen space
		sub eax, dCameraX
		sub edx, dCameraY
	; return
		ret
GetActorScreenPos ENDP



; r9d: y tile
; r8d: x tile
; ecx: unit type
ActorBankCreate PROC
	; make sure the target tile is clear
		push rcx
		push r8
		push r9
		; get tile data
			mov edx, r9d
			mov ecx, r8d
			call GridAccessTile
			shr rax, 32
		; fail if actors on tile
			test rax, 03h
			jnz return_fail 
		; fail if tile is not cleared path
			and rax, 0Ch
			cmp rax, 04h
			jne return_fail
		pop r9
		pop r8
		pop rcx


	; get new actor address
		lea r10, dActorList
		add r10, dLastActorIndex
		and ecx, 255
	; write in defaults from stats (do it here because it wants our ecx type)
		call GetActorStats
		mov byte ptr [r10+7], al ; action cooldown
		shr rax, 8
		mov byte ptr [r10+6], al ; health
	; write actor index into our handle
		mov rax, dLastActorIndex
		mov edi, SIZEOF_Actor
		xor edx, edx
		div edi
		shl eax, 20 ; shift handle index into the uppest 12 bits
		or  ecx, eax
	; write reuse index into our handle (NOT SUPPORTED YET!!!!)
	; increment actor index for the next call
		add dLastActorIndex, SIZEOF_Actor
	; write handle to new actor object
		mov dword ptr [r10], ecx
	; write tile position
		mov word ptr [r10+8], r8w ; x
		mov word ptr [r10+10], r9w ; y
	; write blanks
		mov byte ptr [r10+4], 0 ; state
		mov byte ptr [r10+5], 0 ; ??? unused
		mov word ptr [r10+12], 528 ; position state
		mov word ptr [r10+14], 0 ; ??? unused
		mov dword ptr [r10+20], 0 ; ???? unused
	; place this actor into a tile???
		mov edx, r9d ; y
		mov ecx, r8d ; x
		mov r8d, dword ptr [r10] ; handle
		call GridWriteActorAt
	; debug log actor creation	
		mov rdx, 1
		lea rcx, actor_placement_success_str
		call ConsolePrint
	; complete
		mov rax, r10
		ret
	return_fail:
		; release locals
			pop r9
			pop r8
			pop rcx
		; write error to console
			mov rdx, 1
			lea rcx, actor_placement_failed_str
			call ConsolePrint
		; return
			xor eax, eax
			ret
ActorBankCreate ENDP

; no inputs
ActorBankTick PROC
	sub rsp, 8
	push r12 ; ptr to current actor
	push r13 ; last address
	lea r12, dActorList 
	mov r13, r12
	add r13, dLastActorIndex
	lloop:
		; break if we reached the last valid index
			cmp r12, r13
			je loop_end
		; if current actor is valid
			cmp dword ptr [r12], 0FFF00000h
			jle block3
				call ActorTick
			block3:
		; next iteration
			add r12, SIZEOF_Actor
			jmp lloop
	loop_end:

	pop r13
	pop r12
	add rsp, 8
	ret
ActorBankTick ENDP

; r12: actor ptr
; rcx: hdc
ActorBankRender PROC
	cmp r12, 0 ; check null ptr
	je return
	cmp dword ptr [r12], 0FFF00000h ; check invalid handle
	jle return
		sub rsp, 8
		call DrawActorSprite
		call TryDrawActorHealth
		add rsp, 8
	return:
		ret
ActorBankRender ENDP

; rcx: actor ptr
ReleaseActor PROC
	or dword ptr [rcx], 0FFF00000h
	ret
ReleaseActor ENDP

; ecx: handle
ReleaseActorByHandle PROC
	call ActorPtrFromHandle
	cmp rax, 0
	je return
		mov rcx, rax
		call ReleaseActor
	return:
		ret
ReleaseActorByHandle ENDP

; ecx: actor handle
ActorPtrFromHandle PROC
	; digest actor handle
		mov eax, ecx
		shr eax, 20 
	; generate actor ptr
		xor edx, edx
		mov esi, SIZEOF_Actor
		mul esi
		lea rsi, dActorList
		add rsi, rax
	; if the indexed actor is valid & has a matching handle
		cmp dword ptr [rsi], ecx
		jne b30
			mov rax, rsi
			ret
	; else return null
		b30:
		xor rax, rax
		ret
ActorPtrFromHandle ENDP

END