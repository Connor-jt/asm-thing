
; input externs
	extern dKeyMap : byte
	extern dHeldKeyMap : byte
	extern dMouseX : dword
	extern dMouseY : dword
; actor iteration externs
	extern SIZEOF_Actor : abs
	extern dLastActorIndex : qword
	extern dActorList : byte
; scene externs
	extern dCameraX : dword
	extern dCameraY : dword
; window externs
	extern dWinX : dword
	extern dWinY : dword
; consts
	MAX_SELECTED_ACTORS EQU 100
; my func imports
	GetActorSprite PROTO
	ConsolePrint PROTO
	ConsolePrintNumber PROTO
	ActorPtrFromHandle PROTO
; windows funcs
	FrameRect PROTO
; exports
	public dSelectedActorsList
	public dSelectedActorsCount

.data

cActorSelectedStr dw 'A','c','t','o','r',' ','c','o','u','n','t',0

dSelectedActorsList qword MAX_SELECTED_ACTORS dup(0) ; 100 selected actor slots
dSelectedActorsCount dword 0
dHoveredActor qword 0

dOriginalMouseX dword 0
dOriginalMouseY dword 0

dMouseHeldDownFor dword 0
dShouldShowSelectBounds byte 0

.code 

; rcx: hdc
ActorSelectRender PROC
	; config locals
		push r12 ; cached actor list ptr
		push r13 ; item index
		push r14 ; curr actor handle
		push r15 ; hdc
		sub rsp, 38h ; 8 align, 10h rect struct, 20h shadow space
		lea r12, dSelectedActorsList
		xor r13, r13 
		mov r15, rcx
	; render borders around all selected actors
		lloop:
			; break if at the end of the array
				cmp r13d, dSelectedActorsCount
				je loop_end
			; fetch current actor ptr
				mov rcx, qword ptr [r12+r13*8]
				call ActorPtrFromHandle
				mov r14, rax
			; if returned ptr is null, goto next iteration
				test r14, r14
				jz b31
			; generate screen coords
				; r8d: low_x
				; r9d: high_x
				; r10d: low_y
				; r11d: high_y
				; verify actor is on screen
					mov r8d, dword ptr [r14+8]
					mov r10d, dword ptr [r14+12]
					sub r8d, dCameraX
					sub r10d, dCameraY
				; if X off-screen
					cmp r8d, 0
					jl b31
					cmp r8d, dWinX
					jge b31
				; if Y off-screen
					cmp r10d, 0
					jl b31
					cmp r10d, dWinY
					jge b31
				; get curr actor sprite size
					mov rcx, r14
					call GetActorSprite
					mov eax, dword ptr [rax+18h]
					shr eax, 1 ; half it
				; set X coords
					mov r9d, r8d
					sub r8d, eax
					add r9d, eax
				; set Y coords
					mov r11d, r10d
					sub r10d, eax
					add r11d, eax
			; construct Rect struct
				mov dword ptr [rsp+20h], r8d
				mov dword ptr [rsp+28h], r9d
				mov dword ptr [rsp+24h], r10d
				mov dword ptr [rsp+2Ch], r11d
			; drawcall border square	
				mov r8, 26
				lea rdx, [rsp+20h] ; not sure this is quite right?
				mov rcx, r15
				call FrameRect
			b31:
				inc r13d
			jmp lloop
		loop_end:

	; render border for hovered actor
		; skip if no hovered actor
			cmp dHoveredActor, 0
			je skip_hover_border
		; fetch current actor ptr
			mov rcx, dHoveredActor
			call ActorPtrFromHandle
		; if actor null, skip
			test rax, rax
			jz b31
		; render border
			; verify actor is on screen
				mov r8d, dword ptr [rax+8]
				mov r10d, dword ptr [rax+12]
				sub r8d, dCameraX
				sub r10d, dCameraY
			; get curr actor sprite size
				mov rcx, rax
				call GetActorSprite
				mov eax, dword ptr [rax+18h]
				shr eax, 1 ; half it
				inc eax
			; set X coords
				mov r9d, r8d
				sub r8d, eax
				add r9d, eax
			; set Y coords
				mov r11d, r10d
				sub r10d, eax
				add r11d, eax
			; construct Rect struct
				mov dword ptr [rsp+20h], r8d
				mov dword ptr [rsp+28h], r9d
				mov dword ptr [rsp+24h], r10d
				mov dword ptr [rsp+2Ch], r11d
			; drawcall border square	
				mov r8, 8
				lea rdx, [rsp+20h] ; not sure this is quite right?
				mov rcx, r15
				call FrameRect
		skip_hover_border:

	; render selection border if show select bounds is true
		cmp dShouldShowSelectBounds, 0
		je b32
			; get selection rect
				call GetSelectRect
				test rax, rax
				jnz b32
			; construct Rect struct
				mov dword ptr [rsp+20h], r8d
				mov dword ptr [rsp+28h], r9d
				mov dword ptr [rsp+24h], r10d
				mov dword ptr [rsp+2Ch], r11d
			; drawcall border square	
				mov r8, 1
				lea rdx, [rsp+20h] ; not sure this is quite right?
				mov rcx, r15
				call FrameRect
		b32:
	; return
		add rsp, 38h
		pop r15
		pop r14
		pop r13
		pop r12 
		ret
ActorSelectRender ENDP

ActorSelectTick PROC
	sub rsp, 8
	; find our currently hovered actor
		call SetHoveredActor

	; if left mouse pressed
		lea rcx, dKeyMap
		mov al, byte ptr [rcx+2]
		cmp al, 0
		je b17
			; check flag that indicates we should be tracking how long its been held for
			mov dMouseHeldDownFor, 1
			mov eax, dMouseX
			mov dOriginalMouseX, eax
			mov eax, dMouseY
			mov dOriginalMouseY, eax
		b17:

	; if mouse previously held
		cmp dMouseHeldDownFor, 0
		je b18
			; check whether mouse is still held down
			lea rcx, dHeldKeyMap
			mov al, byte ptr [rcx+2]
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
				; drag rectangle select
				jz b25 
					call SelectActorWithinRect
					jmp b26
				; single click select
				b25: 
					; verify we have enough room in our selection buffer
						cmp dSelectedActorsCount, MAX_SELECTED_ACTORS
						je b26
					; verify that we are hovering over an actor
						cmp dHoveredActor, 0
						je b26
					; write hovered actor
						lea rcx, dSelectedActorsList
						mov edx, dSelectedActorsCount
						mov rax, dHoveredActor
						mov qword ptr [rcx+rdx*8], rax
					; inc selected count
						inc dSelectedActorsCount
				b26:
				; cleanup
					mov dMouseHeldDownFor, 0
					mov dShouldShowSelectBounds, 0
				; [DEBUG] print out how many actors we have selected
					mov rdx, 1
					lea rcx, cActorSelectedStr
					call ConsolePrint
					xor rcx, rcx
					mov ecx, dSelectedActorsCount
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
	; get select rect
		call GetSelectRect
		test rax, rax
		jnz return
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
								mov rcx, rdi
								shl rcx, 32
								mov eax, dword ptr [r12]
								or rax, rcx
								lea rcx, dSelectedActorsList
								mov edx, dSelectedActorsCount
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
SetHoveredActor PROC
	; config locals
		push r12 ; ptr to current actor
		lea r12, dActorList 
		mov rsi, r12
		add rsi, dLastActorIndex ; last address
		xor rdi, rdi ; actor index
		mov dHoveredActor, 0
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
								mov rcx, rdi
								shl rcx, 32
								mov eax, dword ptr [r12]
								or rax, rcx
								mov dHoveredActor, rax
								jmp return
			b28:
		; next iteration
			add r12, SIZEOF_Actor
			inc rdi
			jmp lloop
	return:
		pop r12
		ret
SetHoveredActor ENDP

; [outputs]
; r8d:  low_x
; r9d:  high_x
; r10d: low_y
; r11d: high_y
GetSelectRect PROC
	; write rect_low_x, rect_high_x
		mov eax, dOriginalMouseX
		cmp eax, dMouseX
		je return_fail ; skip if empty size
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
		je return_fail ; skip if empty size
		jl b23 ; if og_y > y
			mov r10d, dMouseY		  ; low
			mov r11d, dOriginalMouseY ; high
			jmp b24
		b23: ; if og_y < y
			mov r10d, dOriginalMouseY ; low
			mov r11d, dMouseY         ; high
		b24:
	; return
		xor rax, rax
		ret
	return_fail:
		mov rax, 1
		ret
GetSelectRect ENDP


END