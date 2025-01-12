

; scene externs
	extern dCameraX : dword
	extern dCameraY : dword
; window externs
	extern dWinX : dword
	extern dWinY : dword
; extern custom funcs
	GetActorStats PROTO
	GetActorSprite PROTO
	GetActorScreenPos PROTO
; extern windows funcs
	FillRect PROTO
; colors
	extern Brush_HealthGreen : dword
	extern Brush_HealthBackground : dword

.code



; r12: actor ptr (pass through)
; rcx: hdc (pass through)
TryDrawActorHealth PROC
	; config locals
		push rbx ; health
		push r15 ; HDC
		mov r15, rcx
	; get unit details
		mov ecx, dword ptr [r12]
		and rcx, 255 ; fetch the last 8 bits for our unit type
		call GetActorStats
		mov rbx, rax
	; skip if actor health is max
		mov al, byte ptr [r12+6]
		cmp bh, al
		je return
	; draw it
		call DrawActorHealth ; warning: mal-aligned stack
	return:
		mov rcx, r15 ; because hdc is pass through, we need to restore its value
		pop r15
		pop rbx
		ret
TryDrawActorHealth ENDP

; r12: actor ptr (pass through)
; rcx: hdc (pass through)
ForceDrawActorHealth PROC
	; config locals
		push rbx ; health
		push r15 ; HDC
		mov r15, rcx
	; get unit details
		mov ecx, dword ptr [r12]
		and rcx, 255
		call GetActorStats
		mov rbx, rax
	; draw
		call DrawActorHealth ; warning: mal-aligned stack
	; return
		mov rcx, r15 ; because hdc is pass through, we need to restore its value
		pop r15
		pop rbx
		ret
ForceDrawActorHealth ENDP

; r12: actor ptr (pass through)
; r15: hdc
; rbx: actor details
DrawActorHealth PROC ; stack mal-aligned
	; skip if unit is off-screen
		; verify actor is on screen
			mov rcx, r12
			call GetActorScreenPos
			sub r8d, eax
			sub r10d, edx
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
			sub rsp, 30h
			mov rcx, r12
			call GetActorSprite
			mov eax, dword ptr [rax+18h]
			shr eax, 1
		; config Y axis 
			sub r10d, eax ; subtract to bring it above the actor
			sub r10d, 10 ; mov it an extra 10 pixels up
			mov r11d, r10d
			add r11d, 7 ; 5 pixels height
		; determine max width of the bar
			movzx eax, bh
			shr eax, 1
			inc eax ; this is our 1px padding (left & right)
		; config x axis 
			mov r9d, r8d
			sub r8d, eax
			add r9d, eax
		; create rectangle
			mov dword ptr [rsp+20h],  r8d
			mov dword ptr [rsp+24h], r10d
			mov dword ptr [rsp+28h],  r9d
			mov dword ptr [rsp+2Ch], r11d
		; draw background
			mov r8d, Brush_HealthBackground ; hbrush 
			mov rdx, rsp 
			add rdx, 20h
			mov rcx, r15 ; hdc
			call FillRect
		; reconfig y axis
			inc dword ptr [rsp+24h]
			dec dword ptr [rsp+2Ch]
		; reconfig x axis 
			mov r8d, dword ptr [rsp+20h]
			inc r8d
			mov r9d, r8d
			movzx eax, byte ptr [r12+6]
			add r9d, eax
			mov dword ptr [rsp+20h],  r8d
			mov dword ptr [rsp+28h],  r9d
		; draw health percentage
			mov r8d, Brush_HealthGreen ; hbrush 
			mov rdx, rsp 
			add rdx, 20h
			mov rcx, r15 ; hdc
			call FillRect
			add rsp, 38h
	return:
		ret
DrawActorHealth ENDP


END