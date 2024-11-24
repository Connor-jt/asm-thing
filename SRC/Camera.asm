
public dCameraX
public dCameraY

extern dKeyMap : byte
extern dMouseX : dword
extern dMouseY : dword


.data
dCameraX dword 0
dCameraY dword 0

dPrevMouseX dword 0
dPrevMouseY dword 0

dIsMoving dword 0

.code

CameraTick PROC
	; toggle movement state if middle mouse was pressed
		lea rcx, dKeyMap
		mov al, byte ptr [rcx+4]
		cmp al, 0
		je block10
			xor dIsMoving, 1
		block10:
	; calc X offset since last move
		mov ecx, dMouseX
		sub ecx, dPrevMouseX
		mov eax, dMouseX
		mov dPrevMouseX, eax
	; calc Y offset since last move
		mov edx, dMouseY
		sub edx, dPrevMouseY
		mov eax, dMouseY
		mov dPrevMouseY, eax
	; if camera move enabled, apply mouse movement
		cmp dIsMoving, 0
		je block11
			sub dCameraX, ecx
			sub dCameraY, edx
		block11:
	;return
		ret
CameraTick ENDP


END