QueryPerformanceCounter PROTO


BeginPaint PROTO
FillRect PROTO
DrawTextW PROTO

SetTextColor PROTO
SetBkMode PROTO

ConsoleRender PROTO

EndPaint PROTO 

DebugUITickEnd PROTO
DebugUITick PROTO
DebugUIRender PROTO


extern RenderSprite : proc ; sprite entry
extern ReleaseSpriteHDC : proc ; sprite entry
; NOTE: temporary thing
extern dSoldierSprite : db ; not sure if this is correct or not??
extern dTimeFequency : dq

.data

.code

; rcx: hwnd
TestRender PROC
	; config locals
		push r12
		push r13
		push r14
		push rbx
		sub rsp, 78h ; allocate room for paint struct + 20h for shadow space
		mov r13, rsp ; store paintstruct
		add r13, 20h
		mov r14, rcx ; store hwnd 
	; [DEBUG] FPS tracking stuff
		call DebugUITick

	; begin paint
		mov rdx, r13   ; paintstruct*
	    mov rcx, r14 ; hwnd
		call BeginPaint
		mov r12, rax ; store hdc
	; reset canvas
		mov r8, 13 ; hbrush 
		mov rdx, r13 ; &paintstruct.rcPaint
		add rdx, 12
		mov rcx, r12 ; hdc
		call FillRect
	; set text state
		mov rdx, 1 ; transparent
		mov rcx, r12 ; hdc
		call SetBkMode

	; do paint things
		mov rdx, OFFSET dSoldierSprite
		mov rcx, r12
		call RenderSprite
	; wipe all created devices
		mov rcx, OFFSET dSoldierSprite
		call ReleaseSpriteHDC

	; [DEBUG] render console
		mov rcx, r12 ; hdc
		call ConsoleRender
	; [DEBUG] render performance stuff
		call DebugUIRender

	; end paint
		mov rdx, r13   ; paintstruct*
		mov rcx, r14 ; hwnd
		call EndPaint
	; [DEBUG] log frame render time
		call DebugUITickEnd
	; return
		add rsp, 78h ; clear shadow space
		pop rbx
		pop r14
		pop r13
		pop r12
		ret
TestRender ENDP
END