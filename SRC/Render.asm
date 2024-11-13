QueryPerformanceCounter PROTO


BeginPaint PROTO
FillRect PROTO
DrawTextW PROTO

SetTextColor PROTO
SetBkMode PROTO

EndPaint PROTO 

U64ToWStr PROTO

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

dLastFrameCount dq 0
dFrameCount dq 0

cTesterr dw 's','d','m','.','b',' ','p','s','d','m','.','b','m','p','s','d','m','.','b',' ','p','s','d','m','.','b','m','p','s','d',' ','.','b','m','p','s',' ','m','.','m','.','b','m', 0

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
		; get latest time interval
			mov r12, dCurrTime
			mov rcx, OFFSET dCurrTime
			call QueryPerformanceCounter
		; get time (microseconds) since last frame
			mov rax, dCurrTime
			sub rax, r12
			mov rcx, 1000000
			mul rcx
			mov rcx, dTimeFequency
			mov rdx, 0
			div rcx
			mov dDrawTime, rax
		; fetch miliseconds since last FPS counter refresh
			mov rax, dCurrTime
			sub rax, dLastTime
			mov rcx, 1000
			mul rcx
			mov rcx, dTimeFequency
			mov rdx, 0
			div rcx
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
	    mov rcx, r14 ; hwnd
		call BeginPaint
		mov r12, rax ; store hdc
	; reset canvas
		mov r8, 13 ; hbrush 
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
		; config system vars
			mov rdx, 00000FFffh ; color
			mov rcx, r12 ; hdc
			call SetTextColor
			mov rdx, 1 ; transparent
			mov rcx, r12 ; hdc
			call SetBkMode
		; config wstr buffer
			mov rbx, rsp
			sub rsp, 40h
			sub rbx, 6
		; draw time
			mov rdx, rbx
			mov rcx, dDrawTime
			call U64ToWStr
			; append to str: " ps"
				mov word ptr [rbx-2], 20h
				mov word ptr [rbx],   70h
				mov word ptr [rbx+2], 73h
				mov word ptr [rbx+4],  0h
			push 0 ; PADDING
			push 100 ; bottom
			push 80 ; right
			push 40 ; top
			push 10 ; left
			mov r9, rsp; rect ptr
			push 00000100h ; format 
			mov r8, -1 ; char count 
			mov rdx, rax ; wstr ptr
			;mov rdx, OFFSET cTesterr ; wstr ptr
			mov rcx, r12 ; hdc
			sub rsp, 20h
			call DrawTextW
			add rsp, 50h
		; fps
			mov rdx, rbx
			mov rcx, dLastFrameCount
			call U64ToWStr
			; append to str: " ps"
				mov word ptr [rbx-2], 66h
				mov word ptr [rbx],   70h
				mov word ptr [rbx+2], 73h
				mov word ptr [rbx+4],  0h
			push 0 ; PADDING
			push 140 ; bottom
			push 80 ; right
			push 120 ; top
			push 210 ; left
			mov r9, rsp; rect ptr
			push 00000100h ; format 
			mov r8, -1 ; char count 
			mov rdx, rax ; wstr ptr
			;mov rdx, OFFSET cTesterr ; wstr ptr
			mov rcx, r12 ; hdc
			sub rsp, 20h
			call DrawTextW
			add rsp, 50h
		; reset vars
			add rsp, 40h

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
		mov rcx, 1000000
		mul rcx
		mov rcx, dTimeFequency
		mov rdx, 0
		div rcx
		mov dDrawTime, rax
	; return
		add rsp, 78h ; clear shadow space
		pop rbx
		pop r14
		pop r13
		pop r12
		ret
TestRender ENDP
END