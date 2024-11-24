
LoadSprite PROTO ; sprite entry

DeleteDC PROTO

extern dWinX : dword
extern dWinY : dword

.data
cSoldierSprite word 's','d','.','b','m','p', 0
cSoldierSpriteMask word 's','d','m','.','b','m','p', 0

.data?
dSoldierSprite byte 28 dup(?)	; 0x0 bitmap ptr
							; 0x8 mask bitmap ptr
							; 0x10 bitmap hdc
							; 0x18 bitmap dimensions (1x4byte)
public dSoldierSprite
cSpriteCount dword 28 ; count * 28
.code


LoadSpriteLibrary PROC
	; config locals
		push r12 ; just to align stack
	; load soldier
		mov rcx, OFFSET cSoldierSprite
		mov rdx, OFFSET cSoldierSpriteMask
		mov r8, 32
		mov r9, OFFSET dSoldierSprite
		call LoadSprite
	; return
		pop r12
		ret
LoadSpriteLibrary ENDP

; rcx: sprite_ptr
ReleaseSpriteHDCs PROC
	; config locals
		push r12
		push r13
		sub rsp, 28h
		lea r12, dSoldierSprite 
		xor r13d, r13d
	lloop:
		; break if we reached the last valid index
			cmp r13d, cSpriteCount
			je return
		; if hdc ptr is not null, release it
			mov rcx, qword ptr [r12+10h]
			cmp rcx, 0
			je block8
				call DeleteDC
				mov qword ptr [r12+10h], 0
			block8:
		; next iteration
			add r12, 28 ; inc offset
			add r13d, 28 ; inc index
			jmp lloop
	return:
		add rsp, 28h
		push r13
		push r12
		ret
ReleaseSpriteHDCs ENDP

END