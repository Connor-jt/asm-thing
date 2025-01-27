QueryPerformanceCounter PROTO


BeginPaint PROTO
FillRect PROTO
DrawTextW PROTO
GetClientRect PROTO
CreateCompatibleDC PROTO 
CreateCompatibleBitmap PROTO
SelectObject PROTO
BitBlt PROTO
DeleteObject PROTO
DeleteDC PROTO

SetTextColor PROTO
SetBkMode PROTO

ConsoleRender PROTO

EndPaint PROTO 

DebugUITickEnd PROTO
DebugUITick PROTO
DebugUIRender PROTO

GridRender PROTO
ReleaseActorSpriteHDCs PROTO
ReleaseTerrainSpriteHDCs PROTO

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
	; TODO: double bufferring !!!!!
	; https://www.robertelder.ca/doublebuffering/


	; config locals
		push r12 ; HDC
		push r13 ; hwnd
		push r14 ; paint struct
		push rbx ; new HDC
		push r15 ; new hdc bitmap

		sub rsp, 70h ; allocate room for paint struct + 20h for shadow space
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
	; create new frame buffer
		;Memhdc = CreateCompatibleDC(hdc);
			mov rcx, r12
			call CreateCompatibleDC
			mov rbx, rax
		;Membitmap = CreateCompatibleBitmap(hdc, win_width, win_height);
			mov r8d, dWinY
			mov edx, dWinX
			mov rcx, r12
			call CreateCompatibleBitmap
			mov r15, rax
		;SelectObject(Memhdc, Membitmap);
			mov rdx, rax
			mov rcx, rbx
			call SelectObject
	; reset canvas (we dont really need to do this anymore?)
		;mov r8, 13 ; hbrush 
		;mov rdx, r13 ; &paintstruct.rcPaint
		;add rdx, 12
		;mov rcx, rbx ; hdc
		;call FillRect
	; set text state
		mov rdx, 1 ; transparent
		mov rcx, rbx ; hdc
		call SetBkMode

	; draw all actors
		mov rcx, rbx ; hdc
		call GridRender
	; release draw actor resources
		call ReleaseActorSpriteHDCs
		call ReleaseTerrainSpriteHDCs
	; draw actor selection stuff
		mov rcx, rbx ; hdc
		call ActorSelectRender

	; [DEBUG] render console
		mov rcx, rbx ; hdc
		call ConsoleRender
	; [DEBUG] render performance stuff
		mov rcx, rbx ; hdc
		call DebugUIRender


	; copy contents of new buffer to display one
		;BitBlt(hdc, 0, 0, win_width, win_height, Memhdc, 0, 0, SRCCOPY);
			sub rsp, 8
			push 00CC0020h
			push 0
			push 0
			push rbx
			mov eax, dWinY
			push rax
			mov r9d, dWinX
			mov r8d, 0
			mov rdx, 0
			mov rcx, r12
			sub rsp, 20h
			call BitBlt
			add rsp, 50h
		;DeleteObject(Membitmap);
			mov rcx, r15
			call DeleteObject
		;DeleteDC    (Memhdc);
			mov rcx, rbx
			call DeleteDC
	; end paint
		mov rdx, r13   ; paintstruct*
		mov rcx, r14 ; hwnd
		call EndPaint
	; [DEBUG] log frame render time
		call DebugUITickEnd
	; return
		add rsp, 70h ; clear shadow space
		pop r15
		pop rbx
		pop r14
		pop r13
		pop r12
		ret
TestRender ENDP
END