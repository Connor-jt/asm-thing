

BeginPaint PROTO
FillRect PROTO
EndPaint PROTO 

extern RenderSprite : proc ; sprite entry
extern ReleaseSpriteHDC : proc ; sprite entry
; NOTE: temporary thing
extern dSoldierSprite : db ; not sure if this is correct or not??
extern dTimeFequency : dq

.data
; FPS counting logic
dLastTime dq 0
dCurrTime dq 0
dDrawTime dq 0
dFrameTime dq 0

dLastFrameCount dd 0
dFrameCount dd 0


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
	; [DEBUG] FPS tracking stuff
		; get latest time interval
			mov r12, dCurrTime
			mov rcx, OFFSET dCurrTime
			call QueryPerformanceCounter
		; get time (microseconds) since last frame
			mov rax, dCurrTime
			sub rax, r12
			mul rax, 1000000
			mov rcx, dTimeFequency
			mov rdx, 0
			div rcx
			mov dDrawTime, rax
		; fetch miliseconds since last FPS counter refresh
			mov rax, dCurrTime
			sub rax, dLastTime
			mul rax, 1000
			mov rcx, dTimeFequency
			mov rdx, 0
			div rcx
			mov dFrameTime, rax
		; if milisec elasped is less than 1000, skip
			cmp rax, 1000
			jl fps_tracking_end
		; else reset fps counter
			mov rax, dFrameCount
			mov dLastFrameCount, rax
			mov dFrameCount, 0
			mov rax, dCurrTime
			mov dLastTime, rax
	fps_tracking_end:

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


	; [DEBUG] render performance stuff

	; end paint
		mov rdx, r13   ; paintstruct*
		mov rcx, r14 ; hwnd
		call EndPaint
	; [DEBUG] log performance stuff
		add dFrameCount, 1
		mov rcx, OFFSET dDrawTime
		call QueryPerformanceCounter
		mov rax, dDrawTime
		sub rax, dCurrTime
		mul rax, 1000000
		mov rcx, dTimeFequency
		mov rdx, 0
		div rcx
		mov dDrawTime, rax
	; return
		add rsp, 70h ; clear shadow space
		pop r14
		pop r13
		pop r12
		ret
TestRender ENDP
END