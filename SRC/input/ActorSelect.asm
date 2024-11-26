

extern dKeyMap : byte
extern dHeldKeyMap : byte
extern dMouseX : dword
extern dMouseY : dword


.data

dOriginalMouseX dword 0
dOriginalMouseY dword 0

dMouseHeldDownFor dword 0
dShouldShowSelectBounds byte 0

.code 


ActorSelectTick PROC
	sub rsp, 8
	; if left mouse pressed
		lea rcx, dKeyMap
		mov al, byte ptr [rcx+1]
		cmp al, 0
		je b17
			; check flag that indicates we should be tracking how long its been held for
			mov dMouseHeldDownFor, 1
			mov dOriginalMouseX, dMouseX
			mov dOriginalMouseY, dMouseY
		b17:

	; if mouse previously held
		cmp dMouseHeldDownFor, 0
		je b18
			; check whether mouse is still held down
			lea rcx, dHeldKeyMap
			mov al, byte ptr [rcx+1]
			cmp al, 0
			je b19
			; if held still
				inc dMouseHeldDownFor
				; if tracker greater 4 (3), we need to write down some variables that allow us to paint our selection border elsewhere?
				cmp dMouseHeldDownFor, 3
				jle b18	
					mov dShouldShowSelectBounds, 1
					jmp b18
			b19: 
			; if no longer held
				; either select unit or rectangle select

				mov dMouseHeldDownFor, 0
				mov dShouldShowSelectBounds, 0
		b18:

	; return
		add rsp, 8
		ret
ActorSelectTick ENDP