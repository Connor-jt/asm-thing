
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
ActorSelectTick PROTO
ActorInstructionsTick PROTO

.data
cLMouseDownStr word 'L','e','f','t',' ','m','o','u','s','e',' ','w','a','s',' ','p','r','e','s','s','e','d','!','!',0


.code

GameTick PROC
	sub rsp, 8
	; run camera related functions
		call CameraTick
	; run actor logic 
		call ActorBankTick
	; run actor selection logic
		call ActorSelectTick
	; run selected actor interaction logic
		call ActorInstructionsTick

	
	; [DEBUG] spawn actor when SHIFT + LMB
		; check mouse left down
			lea rcx, dKeyMap
			mov al, byte ptr [rcx+1]
			cmp al, 0
			je b1
		; + shift button down
			lea rcx, dHeldKeyMap
			mov al, byte ptr [rcx+16]
			cmp al, 0
			je b1
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
			b1:
	; return
		add rsp, 8
		ret
GameTick ENDP

END