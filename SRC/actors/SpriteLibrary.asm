
extern LoadSprite : proc ; sprite entry



.data
cSoldierSprite dw 's','d','.','b','m','p', 0
cSoldierSpriteMask dw 's','d','m','.','b','m','p', 0

.data?
dSoldierSprite db 28 dup(?)	; 0x0 bitmap ptr
							; 0x8 mask bitmap ptr
							; 0x10 bitmap hdc
							; 0x18 bitmap dimensions (1x4byte)
public dSoldierSprite
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
END