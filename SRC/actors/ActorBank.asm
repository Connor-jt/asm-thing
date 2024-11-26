DrawActorSprite	PROTO
ActorTick PROTO

public dActorList
public dLastActorIndex

SIZEOF_Actor EQU 24
PUBLIC SIZEOF_Actor

.data

dActorList byte 120000 dup(0) ; 24 bytes x 5000 actors
dLastActorIndex qword 0 ; index * 24
dFirstFreeIndex qword 0 ; index * 24

; Actor struct
;	0h, 4 : handle
;	4h, 2 : state
;	6h, 1 : health
;	7h, 1 : action cooldown
;	8h, 4 : position_x
;	Ch, 4 : position_y
;  10h, 8 : target (either a unit handle or x,y coords)

; Actor Handle
; 11111111 11100000 00000000 00000000 : entity type (allowing 2k types)
; 00000000 00010000 00000000 00000000 : is valid
; 00000000 00001111 11111111 11111111 : index handle (allowing 1 mil reuses)
; +3       +2       +1       +0

; Actor State
; 11000000 00000000 : animation state (00: none, 01: stepping, 10: actioning, 11: dying)
; 00111000 00000000 : direction/death animation step
; 00000111 00000000 : ???
; 00000000 11000000 : ???
; 00000000 00110000 : objective state (00: none, 01: moveto, 10: attack, 11: ???)
; 00000000 00001111 : team
; +1       +0


dActorStatsList qword	0000000203401020h, ; basic infantry
						0h
; Actor stats struct
;	00000000000000FF : max action cooldown
;	000000000000FF00 : max health
;	0000000000FF0000 : range
;	00000000FF000000 : damage
;	000000FF00000000 : movement interval
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

; r8d: y coord
; edx: x coord
; ecx: unit type
ActorBankCreate PROC
	; get new actor address
		lea r10, dActorList
		add r10, dLastActorIndex
		add dLastActorIndex, SIZEOF_Actor
	; write handle
		mov eax, ecx
		shl eax, 21
		or eax, 0100000h ; sets the 'is_valid' flag
		mov dword ptr [r10], eax ; handle
	; write position
		mov dword ptr [r10+8], edx ; x
		mov dword ptr [r10+12], r8d ; y
	; write in defaults from stats
		call GetActorStats
		mov rdx, r10
		mov byte ptr [rdx+6], ah ; health
		mov byte ptr [rdx+7], al ; action cooldown
	; write blanks
		;mov word ptr [rdx+4], 0 ; state
		mov qword ptr [rdx+16], 0 ; target 
	; [DEBUG] write in default state
		mov word ptr [rdx+4], 16 ; state
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
			test dword ptr [r12], 0100000h
			jz block3
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
			test dword ptr [r12], 0100000h
			jz block4
				; r12: actor ptr (pass through)
				; rcx: hdc (pass through)
				call DrawActorSprite
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

; actor ptr from handle function

END