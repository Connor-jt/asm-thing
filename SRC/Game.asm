
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
GridDamageTile PROTO

.data
RMB_tile_damage_str word 'd','a','m','a','g','e',' ','a','p','p','l','i','e','d',0

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
				; create actor
					mov r9d, dMouseY
					add r9d, dCameraY
					mov r8d, dMouseX
					add r8d, dCameraX
					shr r9d, 5
					shr r8d, 5
					mov ecx, 0 ; type: soldier
					call ActorBankCreate
						
			b1:
	
	; [DEBUG] destroy tile when RMB
		; check mouse right down
			lea rcx, dKeyMap
			mov al, byte ptr [rcx+2]
			cmp al, 0
			je c08
		; check ctrl key down
			lea rcx, dHeldKeyMap
			mov al, byte ptr [rcx+11h]
			test al, al
			jz c08
				; debug print
					mov rdx, 1
					lea rcx, RMB_tile_damage_str
					call ConsolePrint
				; create actor
					mov ecx, dMouseX
					mov edx, dMouseY
					add ecx, dCameraX
					add edx, dCameraY
					shr ecx, 5
					shr edx, 5
					mov r8d, 128
					call GridDamageTile
			c08:
	; return
		add rsp, 8
		ret
GameTick ENDP

END