DrawActorSprite	PROTO
TryDrawActorHealth PROTO
ActorTick PROTO

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
;  10h, 8 : ??? target data (either a unit handle or x,y coords)

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


dActorStatsList qword	0000000203401020h, ; basic infantry
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

; rcx: actor ptr (pass through)
; out rax: x pos
; out rdx: y pos
GetActorWorldPos PROC
	; config locals
		xor rax, rax
		xor rdx, rdx
		;xor r8,  r8
	; get actor tile position (sign extend so our negatives are fine)
		movsx rax, word ptr [rcx+8]
		movsx rdx, word ptr [rcx+10]
	; adjust for pixel position
		shl rax, 5
		shl rdx, 5
	; apply Y local tile offsets
		mov r8b, byte ptr [rdx+12]
		and r8b, 31
		add rdx, r8b
	; apply X local tile offsets
		mov r8w, word ptr [rdx+12]
		shr r8w, 5
		and r8w, 31
		add rax, r8w
	; return
		ret
GetActorWorldPos ENDP

; rcx: actor ptr (pass through)
; out rax: x pos
; out rdx: y pos
GetActorScreenPos PROC
	; get actual position
		call GetActorWorldPos
	; adjust for screen space
		sub rax, dCameraX
		sub rdx, dCameraY
	; return
		ret
GetActorScreenPos ENDP



; r8w: y tile
; dx: x tile
; cl: unit type
ActorBankCreate PROC
	; get new actor address
		lea r10, dActorList
		add r10, dLastActorIndex
		and ecx, 255
	; write in defaults from stats (do it here because it wants our ecx type)
		call GetActorStats
		mov byte ptr [rdx+6], ah ; health
		mov byte ptr [rdx+7], al ; action cooldown
	; write actor index into our handle
		mov rax, dLastActorIndex
		mov rdx, SIZEOF_Actor
		div rdx
		shl rdx, 20 ; shift handle index into the uppest 12 bits
		or  ecx, rdx
	; write reuse index into our handle (NOT SUPPORTED YET!!!!)
	; increment actor index for the next call
		add dLastActorIndex, SIZEOF_Actor
	; write handle to new actor object
		mov dword ptr [r10], ecx
	; write tile position
		mov word ptr [r10+8], dx ; x
		mov word ptr [r10+10], r8w ; y
	; write blanks
		mov byte ptr [rdx+4], 0 ; state
		mov byte ptr [rdx+5], 0 ; ??? unused
		mov qword ptr [r10+16], 0 ; target 
	; write in default 
	; [DEBUG] write in default state
		;mov word ptr [r10+4], 16 ; state
	; complete
		mov rax, r10
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
			jge block3
				call ActorTick
				; if function returned value other than 0, then delete actor
				cmp rax, 0
				jz block3
					and byte ptr [r12+2], 239
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

; rcx: hdc 
ActorBankRender PROC
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
			jge block4
				; r12: actor ptr (pass through)
				; rcx: hdc (pass through)
				call DrawActorSprite
				call TryDrawActorHealth
			block4:
		; next iteration
			add r12, SIZEOF_Actor
			jmp lloop
	loop_end:

	pop r13
	pop r12
	add rsp, 8
	ret
ActorBankRender ENDP

;; rcx: actor ptr
;ReleaseActor PROC
;	and byte ptr [rcx+2], 239
;	ret
;ReleaseActor ENDP
;
;; ecx: index
;ReleaseActorByIndex PROC
;	; get actor pointer from index
;		mov eax, ecx
;		xor edx, edx
;		mov ecx, SIZEOF_Actor
;		mul ecx
;		lea rcx, dActorList
;		add rcx, eax
;	; release actor (uncheck valid flag)
;		and byte ptr [rcx+2], 239
;	; return
;		ret
;ReleaseActorByIndex ENDP

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