
public dCameraX
public dCameraY

extern dKeyMap : byte
extern dHeldKeyMap : byte
extern dMouseX : dword
extern dMouseY : dword


.data
dCameraX dword 0
dCameraY dword 0

dPrevMouseX dword 0
dPrevMouseY dword 0

.code

CameraTick PROC
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
		lea rax, dHeldKeyMap
		mov al, byte ptr [rax+4]
		cmp al, 0
		je block11
			sub dCameraX, ecx
			sub dCameraY, edx
		block11:
	;return
		ret
CameraTick ENDP


END