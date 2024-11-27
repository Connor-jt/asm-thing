
LoadSprite PROTO ; sprite entry

DeleteDC PROTO

SIZEOF_Sprite EQU 28
SIZEOF_SpriteBuffer EQU 28 ; SIZEOF_Sprite * 1

.data
cSoldierSprite word 's','d','.','b','m','p', 0
cSoldierSpriteMask word 's','d','m','.','b','m','p', 0

dSoldierSprite byte SIZEOF_SpriteBuffer dup(0)	
; 0x0 bitmap ptr
; 0x8 mask bitmap ptr
; 0x10 bitmap hdc
; 0x18 bitmap dimensions (1x4byte)


.code


LoadSpriteLibrary PROC
	sub rsp, 8
	; load soldier
		lea rcx, cSoldierSprite
		lea rdx, cSoldierSpriteMask
		mov r8, 32
		lea r9, dSoldierSprite
		call LoadSprite
	; return
		add rsp, 8
		ret
LoadSpriteLibrary ENDP

; rcx: actor ptr
; [return] rax: sprite ptr
GetActorSprite PROC
	mov rax, dword ptr [rcx] 
	shr rax, 21 ; rshift the unit type
	xor rdx, rdx
	mov rcx, SIZEOF_Sprite
	mul rcx
	lea rcx, dSoldierSprite
	add rax, rcx
	ret
GetActorSprite ENDP

; rcx: sprite_ptr
ReleaseSpriteHDCs PROC
	; config locals
		push r12 ; curr offset
		push r13 ; final offset
		sub rsp, 28h
		lea r12, dSoldierSprite 
		mov r13, r12
		add r13, SIZEOF_SpriteBuffer
	lloop:
		; break if we reached the last valid index
			cmp r12, r13
			je return
		; if hdc ptr is not null, release it
			mov rcx, qword ptr [r12+10h]
			cmp rcx, 0
			je b8
				call DeleteDC
				mov qword ptr [r12+10h], 0
			b8:
		; next iteration
			add r12, SIZEOF_Sprite ; inc offset
			jmp lloop
	return:
		add rsp, 28h
		pop r13
		pop r12
		ret
ReleaseSpriteHDCs ENDP

END