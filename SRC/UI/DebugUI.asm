
GetClientRect PROTO
SetTextColor PROTO
QueryPerformanceCounter PROTO
DebugUITickEnd PROTO
DrawTextW PROTO

U64ToWStr PROTO

extern dTimeFequency : dq
extern dIdleTime : dq

.data
cPrintFrameStr dw 'F','r','a','m','e',' ','T','i','m','e',' ','(','m','s',')',0
cPrintPaintStr dw 'D','r','a','w',' ','T','i','m','e',' ','(','m','s',')',0
cPrintIdleStr dw 'I','d','l','e',' ','T','i','m','e',' ','(','m','s',')',0
cPrintFpsStr dw 'F','P','S',0

dLastTime dq 0
dCurrTime dq 0

dFrameTime dq 0
dDrawTime dq 0

dLastFrameCount dq 0
dFrameCount dq 0

.code

DebugUITick PROC
	sub rsp, 28h
	; get latest time interval
		mov r12, dCurrTime
		lea rcx, dCurrTime
		call QueryPerformanceCounter
	; get time (microseconds) since last frame
		mov rax, dCurrTime
		sub rax, r12
		mov rcx, 1000000
		mul rcx
		mov rcx, dTimeFequency
		mov rdx, 0
		div rcx
		mov dFrameTime, rax
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
		jl return
	; else reset fps counter
		mov rax, dFrameCount
		mov dLastFrameCount, rax
		mov dFrameCount, 0
		mov rax, dCurrTime
		mov dLastTime, rax
	return:
		add rsp, 28h
		ret
DebugUITick ENDP

DebugUITickEnd PROC ;NOTE: this is called after the render function
	sub rsp, 28h
	; measure time since debugUI tick start
		add dFrameCount, 1
		lea rcx, dDrawTime
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
		add rsp, 28h
		ret
DebugUITickEnd ENDP


; r14: hwnd (pass through)
; r12: hdc (pass through)
DebugUIRender PROC
	; config system vars
		sub rsp, 28h
		mov rdx, 00085FF00h ; color ; #00ff85
		mov rcx, r12 ; hdc
		call SetTextColor
	; draw fps
		mov r8, 20
		mov rdx, dLastFrameCount
		lea rcx, cPrintFpsStr
		call DebugUIDrawLabel
	; draw frame time (div by 1000 to convert to ms)
		mov rax, dFrameTime
		mov rdx, 0
		mov rcx, 1000
		div rcx

		mov r8, 40
		mov rdx, rax
		lea rcx, cPrintFrameStr
		call DebugUIDrawLabel
	; draw draw time (div by 1000 to convert to ms)
		mov rax, dDrawTime
		mov rdx, 0
		mov rcx, 1000
		div rcx

		mov r8, 60
		mov rdx, rax
		lea rcx, cPrintPaintStr
		call DebugUIDrawLabel
	; draw idle time
		mov r8, 80
		mov rdx, dIdleTime
		lea rcx, cPrintIdleStr
		call DebugUIDrawLabel
	; reset vars
		add rsp, 28h
		ret
DebugUIRender ENDP

; r14: hwnd (pass through)
; r12: hdc (pass through)
; r8: height
; rdx: number
; rcx: const string
DebugUIDrawLabel PROC
	; config locals  
		push rbx ; number
		push r13 ; height / rect
		push r15 ; const string
		mov rbx, rdx
		mov r13, r8
		mov r15, rcx
	; init the rect
		sub rsp, 10h
		mov rdx, rsp
		mov rcx, r14
		sub rsp, 20h
		call GetClientRect 
		add rsp, 20h
	; calc rect stuff
		; calc left
			mov eax, dword ptr [rsp+8]
			sub eax, 200
			jl truncate_left ; do not assign negative value to left, if our window is too small
				mov dword ptr [rsp], eax
				jmp calc_top
			truncate_left:
				mov dword ptr [rsp], 0
		calc_top:
			mov dword ptr [rsp+4], r13d
		; calc bottom
			add r13d, 20
			mov dword ptr [rsp+12], r13d
		mov r13, rsp ; save rect ptr
	; draw the const text
		push 0 ; PADDING
		push 00000100h ; format 
		mov r9, r13 ; rect
		mov r8, -1 ; char count 
		mov rdx, r15 ; wstr ptr
		mov rcx, r12 ; hdc
		sub rsp, 20h
		call DrawTextW
		add rsp, 30h

	; adjust drawing position
		mov eax, dword ptr [r13]
		add eax, 120
		mov dword ptr [r13], eax
	; convert number into string
		mov rdx, rsp
		sub rsp, 30h
		mov rcx, rbx
		call U64ToWStr
	; draw the number
		push 0 ; PADDING
		push 00000100h ; format 
		mov r9, r13 ; rect
		mov r8, -1 ; char count 
		mov rdx, rax ; wstr ptr
		mov rcx, r12 ; hdc
		sub rsp, 20h
		call DrawTextW
	; cleanup & return
		add rsp, 70h ; shadowspace (20h) + p5/p6 (10h) + wstr buf (30h) + rect (10h)
		pop r15
		pop r13
		pop rbx
		ret
DebugUIDrawLabel ENDP


END