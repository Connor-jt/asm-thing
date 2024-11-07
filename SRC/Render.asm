

BeginPaint PROTO
FillRect PROTO
EndPaint PROTO 

.code

TestRender PROC
	; config locals
		push r12
		push r13
		sub rsp, 78h ; allocate room for paint struct + 20h for shadow space + 8 padding
		mov r13, rsp ; store paintstruct
		add r13, 20h
	; begin paint
		mov rdx, r13   ; paintstruct*
		mov rcx, dHwnd ; hwnd
		call BeginPaint
		mov r12, rax ; store hdc
	; reset canvas
		mov r8, 6 ; hbrush 
		mov rdx, r13 ; &paintstruct.rcPaint
		add rdx, 12
		mov rcx, r12 ; hdc
		call FillRect


	; do paint things
		mov rdx, OFFSET dSoldierSprite
		mov rcx, r12
		call RenderSprite
	; wipe all created devices
		mov rcx, OFFSET dSoldierSprite
		call ReleaseSpriteHDC


	; end paint
		mov rdx, r13   ; paintstruct*
		mov rcx, dHwnd ; hwnd
		call EndPaint
	; return
		add rsp, 78h ; clear shadow space
		pop r13
		pop r12
		ret
TestRender ENDP