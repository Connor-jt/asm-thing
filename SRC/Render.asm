QueryPerformanceCounter PROTO


BeginPaint PROTO
FillRect PROTO
DrawTextW PROTO
GetClientRect PROTO

SetTextColor PROTO
SetBkMode PROTO

ConsoleRender PROTO

EndPaint PROTO 

DebugUITickEnd PROTO
DebugUITick PROTO
DebugUIRender PROTO


ActorBankRender PROTO ; sprite entry
ReleaseSpriteHDCs PROTO ; spritebank entry
ActorSelectRender PROTO ; actor select entry

extern dTimeFequency : qword

.data
dWinX dword 0
dWinY dword 0
public dWinX
public dWinY


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
	; read window size
		sub rsp, 10h
		mov rdx, rsp
		mov rcx, r14
		sub rsp, 20h
		call GetClientRect 
		mov eax, dword ptr [rsp+28h]
		mov dWinX, eax
		mov eax, dword ptr [rsp+2Ch]
		mov dWinY, eax
		add rsp, 30h

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

	; draw all actors
		mov rcx, r12 ; hdc
		call ActorBankRender
	; release draw actor resources
		call ReleaseSpriteHDCs
	; draw actor selection stuff
		mov rcx, r12 ; hdc
		call ActorSelectRender

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