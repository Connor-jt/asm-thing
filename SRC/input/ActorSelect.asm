
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
	ForceDrawActorHealth PROTO
	GetActorScreenPos PROTO
; windows funcs
	FrameRect PROTO
	FillRect PROTO
; exports
	public dSelectedActorsList
	public dSelectedActorsCount
; extern colors
	extern Brush_ActorHoverGreen : dword
	extern Brush_ActorSelected : dword
	extern Brush_ActorHover_Destination : dword
	extern Brush_ActorHover_Step1 : dword
	extern Brush_ActorHover_Step2 : dword


.data

dSelectedActorsList dword MAX_SELECTED_ACTORS dup(0) ; 100 selected actor slots
dSelectedActorsCount dword 0
dHoveredActor dword -1
dLastHoveredActor dword -1

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
				jge loop_end
			; fetch current actor ptr
				mov rcx, qword ptr [r12+r13*4]
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
					mov rcx, r14
					call GetActorScreenPos
					mov r8d, eax
					mov r10d, edx
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
				mov r8d, Brush_ActorSelected
				lea rdx, [rsp+20h] ; not sure this is quite right?
				mov rcx, r15
				call FrameRect
			b31:
				inc r13d
			jmp lloop
		loop_end:

	; render border for hovered actor
		; skip if no hovered actor, or no prev hovered actor
			cmp dHoveredActor, -1
			je c15
				mov ecx, dHoveredActor
				mov dLastHoveredActor, ecx
			c15:
				cmp dLastHoveredActor, -1
				je skip_hover_border
				mov ecx, dLastHoveredActor
			c16:
		; fetch current actor ptr
			call ActorPtrFromHandle
			mov r12, rax
		; if actor null, skip
			test rax, rax
			jz skip_hover_border
		; render border
			; verify actor is on screen
				mov rcx, r12
				call GetActorScreenPos
				mov r8d, eax
				mov r10d, edx
			; get curr actor sprite size
				mov rcx, r12
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
				mov r8d, Brush_ActorHoverGreen
				lea rdx, [rsp+20h] ; not sure this is quite right?
				mov rcx, r15
				call FrameRect

			; check for destination
				movzx eax, byte ptr [r12+4]
				and eax, 6
				cmp eax, 2
				jne c11
					; render destination
						; get X coord
							movsx r8d, word ptr [r12+16]
							shl r8d, 5
							sub r8d, dCameraX
						; set X coords
							mov r9d, r8d
							add r8d, 10
							add r9d, 22
						; get Y coord
							movsx r10d, word ptr [r12+18]
							shl r10d, 5
							sub r10d, dCameraY
						; set Y coords
							mov r11d, r10d
							add r10d, 10
							add r11d, 22
						; construct Rect struct
							mov dword ptr [rsp+20h], r8d
							mov dword ptr [rsp+28h], r9d
							mov dword ptr [rsp+24h], r10d
							mov dword ptr [rsp+2Ch], r11d
						; drawcall square	
							mov r8d, Brush_ActorHover_Destination
							lea rdx, [rsp+20h] ; not sure this is quite right?
							mov rcx, r15
							call FillRect
					; if we have 1 queued step
						movzx r13d, byte ptr [r12+13]
						cmp r13d, 64
						jl c11
						; load player coords into thingo 
							; get coords
								movsx r8d, word ptr [r12+8]
								movsx r10d, word ptr [r12+10]
								shl r8d, 5
								shl r10d, 5
								sub r8d, dCameraX
								sub r10d, dCameraY
							; set X coords
								mov r9d, r8d
								add r8d, 12
								add r9d, 20
							; set Y coords
								mov r11d, r10d
								add r10d, 12
								add r11d, 20
						; adjust coords based on what direction the tile is
							mov eax, r13d
							shr eax, 4
							and eax, 3
							cmp eax, 2
							je bottom
							jg right
							cmp eax, 1
							je top
							;left 
								; dec X
								sub r8d, 32
								sub r9d, 32
								jmp c12
							right: 
								; inc X
								add r8d, 32
								add r9d, 32
								jmp c12
							top: 
								; dec Y
								sub r10d, 32
								sub r11d, 32
								jmp c12
							bottom: 
								; inc Y
								add r10d, 32
								add r11d, 32
							c12:
						; construct Rect struct
							mov dword ptr [rsp+20h], r8d
							mov dword ptr [rsp+28h], r9d
							mov dword ptr [rsp+24h], r10d
							mov dword ptr [rsp+2Ch], r11d
						; drawcall  square	
							mov r8d, Brush_ActorHover_Step1
							lea rdx, [rsp+20h] ; not sure this is quite right?
							mov rcx, r15
							call FillRect
					; if we also have a 2nd queued step
						cmp r13d, 128
						jl c11
						; adjust coords based on what direction the tile is
							mov eax, r13d
							shr eax, 2
							and eax, 3
							cmp eax, 2
							je __bottom
							jg __right
							cmp eax, 1
							je __top
							;left 
								; dec X
								sub dword ptr [rsp+20h], 32
								sub dword ptr [rsp+28h], 32
								jmp c13
							__right: 
								; inc X
								add dword ptr [rsp+20h], 32
								add dword ptr [rsp+28h], 32
								jmp c13
							__top: 
								; dec Y
								sub dword ptr [rsp+24h], 32
								sub dword ptr [rsp+2Ch], 32
								jmp c13
							__bottom: 
								; inc Y
								add dword ptr [rsp+24h], 32
								add dword ptr [rsp+2Ch], 32
							c13:
						; drawcall border square	
							mov r8d, Brush_ActorHover_Step2
							lea rdx, [rsp+20h] ; not sure this is quite right?
							mov rcx, r15
							call FillRect
				c11:

		; render healthbar for hovered actor
			mov rcx, r15
			call ForceDrawActorHealth
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

	; if right mouse pressed
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
						cmp dHoveredActor, -1
						je b26
					; write hovered actor
						lea rcx, dSelectedActorsList
						mov edx, dSelectedActorsCount
						mov eax, dHoveredActor
						mov dword ptr [rcx+rdx*4], eax
					; inc selected count
						inc dSelectedActorsCount
				b26:
				; cleanup
					mov dMouseHeldDownFor, 0
					mov dShouldShowSelectBounds, 0
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
	; get select rect
		call GetSelectRect
		test rax, rax
		push r8
		jnz return
	lloop:
		; break if we reached the last valid index
			cmp r12, rsi
			je return
		; if current actor is valid
			cmp dword ptr [r12], 0FFF00000h
			jle b20
				; get actor pos
					mov rcx, r12
					call GetActorScreenPos
				; if x >= rect_low_x (r8d)
				cmp eax, dword ptr [rsp] ; access our pushed r8
				jl b20
					; if x <= rect_high_x (r9d)
					cmp eax, r9d
					jg b20
						; if y > rect_low_y (r10d)
						cmp edx, r10d
						jl b20
							; if y < rect_high_y (r11d)
							cmp edx, r11d
							jg b20
								; verify we have enough room in our selection buffer
								cmp dSelectedActorsCount, MAX_SELECTED_ACTORS
								je return
								; get actor index & handle and write to thing buffer
								lea rcx, dSelectedActorsList
								mov edx, dSelectedActorsCount
								mov eax, dword ptr [r12]
								mov dword ptr [rcx+rdx*4], eax
								; inc selected count
								inc dSelectedActorsCount
			b20:
		; next iteration
			add r12, SIZEOF_Actor
			jmp lloop
	return:
		add rsp, 8 ; pop r8
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
		mov dHoveredActor, -1
	; store mouse pos
		mov r11d, dMouseX
		mov r9d, dMouseY
	lloop:
		; break if we reached the last valid index
			cmp r12, rsi
			je return
		; if current actor is valid
			cmp dword ptr [r12], 0FFF00000h
			jle b28
				; fetch actor size
					mov rcx, r12
					call GetActorSprite
					mov r10d, dword ptr [rax+18h] 
					shr r10d, 1
				; fetch actor pos
					mov rcx, r12
					call GetActorScreenPos
				; if x - size <= click_x (r11d)
				mov r8d, eax
				sub r8d, r10d
				cmp r8d, r11d
				jg b28
					; if x + size >= click_x (r11d)
					add eax, r10d
					cmp eax, r11d
					jl b28
						; if y - size <= click_y (r9d)
						mov r8d, edx
						sub r8d, r10d
						cmp r8d, r9d
						jg b28
							; if y + size >= click_y (r9d)
							add edx, r10d
							cmp edx, r9d
							jl b28
								; set hovered actor to current actor handle
								mov eax, dword ptr [r12]
								mov dHoveredActor, eax
								jmp return
			b28:
		; next iteration
			add r12, SIZEOF_Actor
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