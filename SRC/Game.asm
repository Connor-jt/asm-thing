
extern dKeyMap : byte
extern dHeldKeyMap : byte
extern dMouseX : dword
extern dMouseY : dword

extern dCameraX : dword
extern dCameraY : dword

ConsolePrint PROTO
ActorBankCreate PROTO
CameraTick PROTO
ActorBankTick PROTO

.data
cLMouseDownStr word 'L','e','f','t',' ','m','o','u','s','e',' ','w','a','s',' ','p','r','e','s','s','e','d','!','!',0

dMouseHeldDownFor dword 0

.code

GameTick PROC
	sub rsp, 8
	; run camera related functions
		call CameraTick
	; run actor logic 
		call ActorBankTick



	; if left mouse pressed
		; check flag that indicates we should be tracking how long its been held for

	; if mouse previously held
		; if no longer held
			; either place unit or rectangle select
		; if held still
			; increment tracker
			; if tracker greater than like 2, we need to write down some variables that allow us to paint our selection border elsewhere?
	; NOTE: we will have to move the unit selection stuff to a new file
		
	; check mouse left down
		lea rcx, dKeyMap
		mov al, byte ptr [rcx+1]
		cmp al, 0
		je block1
	; + shift button down
		lea rcx, dHeldKeyMap
		mov al, byte ptr [rcx+16]
		cmp al, 0
		je block1
			; debug print
				mov rdx, 1
				lea rcx, cLMouseDownStr
				call ConsolePrint
			; create actor
				mov r8d, dMouseY
				add r8d, dCameraY
				mov edx, dMouseX
				add edx, dCameraX
				mov ecx, 0
				call ActorBankCreate
		block1:
	; return
		add rsp, 8
		ret
GameTick ENDP

END