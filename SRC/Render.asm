

BeginPaint PROTO
FillRect PROTO
EndPaint PROTO 

extern RenderSprite : proc ; sprite entry
extern ReleaseSpriteHDC : proc ; sprite entry
; NOTE: temporary thing
extern dSoldierSprite : db 

.code

; rcx: hwnd
TestRender PROC
	; config locals
		push r12
		push r13
		push r14
		sub rsp, 70h ; allocate room for paint struct + 20h for shadow space
		mov r13, rsp ; store paintstruct
		add r13, 20h
		mov r14, rcx ; store hwnd 
	; begin paint
		mov rdx, r13   ; paintstruct*
	   ;mov rcx, r14 ; hwnd (redundant mov)
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
		mov rcx, r14 ; hwnd
		call EndPaint
	; return
		add rsp, 70h ; clear shadow space
		pop r14
		pop r13
		pop r12
		ret
TestRender ENDP
END