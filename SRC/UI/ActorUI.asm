

; scene externs
	extern dCameraX : dword
	extern dCameraY : dword
; window externs
	extern dWinX : dword
	extern dWinY : dword
; extern custom funcs
	GetActorStats PROTO
	GetActorSprite PROTO
; extern windows funcs
	FillRect PROTO

.code

; r12: actor ptr (pass through)
; rcx: hdc (pass through)
; rdx: actor ptr
; rcx: hdc
DrawActorHealth PROC
	; config locals
		sub rsp, 8
		push rbx ; health
		push r15 ; HDC
		mov r15, rcx
	; get unit details
		mov ecx, dword ptr [r12]
		shr ecx, 21
		call GetActorStats
		mov rbx, rax
	; skip if actor health is max
		mov al, byte ptr [r12+6]
		cmp bh, al
		je return
	; skip if unit is off-screen
		; verify actor is on screen
			mov r8d, dword ptr [r12+8]
			mov r10d, dword ptr [r12+12]
			sub r8d, dCameraX
			sub r10d, dCameraY
		; if X off-screen
			cmp r8d, 0
			jl return
			cmp r8d, dWinX
			jge return
		; if Y off-screen
			cmp r10d, 0
			jl return
			cmp r10d, dWinY
			jge return
	; get coords to draw healthbar to
		; get actor sprite size
			mov rcx, r12
			call GetActorSprite
			mov eax, dword ptr [rax+18h]
			shr eax, 1
		; config Y axis 
			sub r10d, eax ; subtract to bring it above the actor
			sub r10d, 10 ; mov it an extra 10 pixels up
			mov r11d, r10d
			add r11d, 5 ; 5 pixels height
		; determine max width of the bar
			movzx eax, bh
			shr eax, 1 
		; config x axis 
			sub r8d, eax
			mov r9d, r8d
			movzx eax, byte ptr [r12+6]
			add r9d, eax
		; create rectangle
			sub rsp, 30h
			mov dword ptr [rsp+20h],  r8d
			mov dword ptr [rsp+24h], r10d
			mov dword ptr [rsp+28h],  r9d
			mov dword ptr [rsp+2Ch], r11d
		; draw
			mov r8, 29 ; hbrush 
			mov rdx, rsp 
			add rdx, 20h
			mov rcx, r15 ; hdc
			call FillRect
			add rsp, 30h
	return:
		mov rcx, r15 ; because hdc is pass through, we need to restore its value
		pop r15
		pop rbx
		add rsp, 8
		ret
DrawActorHealth ENDP


END