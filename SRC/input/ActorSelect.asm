
; input externs
	extern dKeyMap : byte
	extern dHeldKeyMap : byte
	extern dMouseX : dword
	extern dMouseY : dword
; actor iteration externs
	extern SIZEOF_Actor : abs
; consts
	MAX_SELECTED_ACTORS EQU 100

.data

cActorSelectedStr dw 'A','c','t','o','r',' ','c','o','u','n','t',0

dSelectedActorsList qword MAX_SELECTED_ACTORS dup(0) ; 100 selected actor slots
dSelectedActorsCount dword 0

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
				; clear selected actors, unless shift is being held down
					lea rcx, dHeldKeyMap
					mov al, byte ptr [rcx+16]
					cmp al, 1
					je b27
						mov dSelectedActorsCount, 0
					b27:
				; either select unit or rectangle select
				cmp dShouldShowSelectBounds, 0
				jz b25 ; drag rectangle select
					call SelectActorWithinRect
					jmp b26
				b25: ; single click select
					call SelectActorAt
				b26:
				; cleanup
					mov dMouseHeldDownFor, 0
					mov dShouldShowSelectBounds, 0
				; [DEBUG] print out how many actors we have selected
					mov rdx, 1
					lea rcx, cActorSelectedStr
					call ConsolePrint
					mov rcx, dSelectedActorsCount
					call ConsolePrintNumber
		b18:

	; return
		add rsp, 8
		ret
ActorSelectTick ENDP

SelectActorWithinRect PROC
	; config locals
		push r12 ; ptr to current actor
		lea r12, dActorList 
		mov rsi, r12
		add rsi, dLastActorIndex ; last address
		xor rdi, rdi ; actor index
		; r8d:  low_x
		; r9d:  high_x
		; r10d: low_y
		; r11d: high_y
	; write rect_low_x, rect_high_x
		mov eax, dOriginalMouseX
		cmp eax, dMouseX
		je loop_end ; skip if empty size
		jl b21 ; if og_x > x
			mov r8d, dMouseX		 ; low
			mov r9d, dOriginalMouseX ; high
			jmp b22
		b21: ; if og_x < x
			mov r8d, dOriginalMouseX ; low
			mov r9d, dMouseX         ; high
		b22:
	; write rect_low_y, rect_high_y
		mov eax, dOriginalMouseY
		cmp eax, dMouseY
		je loop_end ; skip if empty size
		jl b23 ; if og_y > y
			mov r10d, dMouseY		  ; low
			mov r11d, dOriginalMouseY ; high
			jmp b24
		b23: ; if og_y < y
			mov r10d, dOriginalMouseY ; low
			mov r11d, dMouseY         ; high
		b24:
	; convert screen positions to world positions
		add r8d, dCameraX
		add r9d, dCameraX
		add r10d, dCameraY
		add r11d, dCameraY

	lloop:
		; break if we reached the last valid index
			cmp r12, rsi
			je return
		; if current actor is valid
			test dword ptr [r12], 0100000h
			jz b20
				mov eax, dword ptr [r12+8]
				; if x >= rect_low_x (r8d)
				cmp eax, r8d
				jl b20
					; if x <= rect_high_x (r9d)
					cmp eax, r9d
					jg b20
						; if y > rect_low_y (r10d)
						mov eax, dword ptr [r12+12]
						cmp eax, r10d
						jl b20
							; if y < rect_high_y (r11d)
							cmp eax, r11d
							jg b20
								; verify we have enough room in our selection buffer
								cmp dSelectedActorsCount, MAX_SELECTED_ACTORS
								je return
								; get actor index & handle and write to thing buffer
								mov rax, rdi
								shl rax, 32
								mov eax, dword ptr [r12]
								mov rcx, dSelectedActorsList
								mov rdx, dSelectedActorsCount
								mov qword ptr [rcx+rdx*8], rax
								; inc selected count
								inc dSelectedActorsCount
			b20:
		; next iteration
			add r12, SIZEOF_Actor
			inc rdi
			jmp lloop
	return:
		pop r12
		ret
SelectActorWithinRect ENDP

; no inputs
SelectActorAt PROC
	; config locals
		push r12 ; ptr to current actor
		lea r12, dActorList 
		mov rsi, r12
		add rsi, dLastActorIndex ; last address
		xor rdi, rdi ; actor index
	; verify we have enough room in our selection buffer
		cmp dSelectedActorsCount, MAX_SELECTED_ACTORS
		je return
	; convert mouse position to world position
		mov r8d, dMouseX
		add r8d, dCameraX
		mov r9d, dMouseY
		add r9d, dCameraY
	lloop:
		; break if we reached the last valid index
			cmp r12, rsi
			je return
		; if current actor is valid
			test dword ptr [r12], 0100000h
			jz b28
				; fetch actor size
					mov rcx, r12
					call GetActorSprite
					mov r10d, dword ptr [rax+18h] 
					shr r10d, 1
				; if x - size <= click_x (r8d)
				mov eax, dword ptr [r12+8]
				sub eax, r10d
				cmp eax, r8d
				jg b28
					; if x + size >= click_x (r8d)
					mov eax, dword ptr [r12+8]
					add eax, r10d
					cmp eax, r8d
					jl b28
						; if y - size <= click_y (r9d)
						mov eax, dword ptr [r12+12]
						sub eax, r10d
						cmp eax, r9d
						jg b28
							; if y + size >= click_y (r9d)
							mov eax, dword ptr [r12+12]
							add eax, r10d
							cmp eax, r9d
							jl b28
								; get actor index & handle and write to thing buffer
								mov rax, rdi
								shl rax, 32
								mov eax, dword ptr [r12]
								mov rcx, dSelectedActorsList
								mov rdx, dSelectedActorsCount
								mov qword ptr [rcx+rdx*8], rax
								; inc selected count
								inc dSelectedActorsCount
								jmp return
			b28:
		; next iteration
			add r12, SIZEOF_Actor
			inc rdi
			jmp lloop
	return:
		pop r12
		ret
SelectActorAt ENDP