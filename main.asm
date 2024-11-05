ExitProcess PROTO
PostQuitMessage PROTO
RegisterClassExW PROTO
GetModuleHandleW PROTO
CreateWindowExW PROTO
DefWindowProcW PROTO
ShowWindow PROTO
GetMessageW PROTO
TranslateMessage PROTO
DispatchMessageW PROTO
GetLastError PROTO
BeginPaint PROTO
FillRect PROTO
EndPaint PROTO 
LoadImageW PROTO
SelectObject PROTO
CreateCompatibleDC PROTO
BitBlt PROTO
DeleteDC PROTO

.data
cWindowClassName dw 'E','x','W','i','n','C','l','a','s','s', 0
cWindowName dw 'E','x','W','i','n','N','a','m','e', 0
cSoldierSprite dw 's','d','.','b','m','p', 0

.data?
dHInstance dq ?
dWindowClass db 80 dup(?)
dMSG db 48 dup(?)
dHwnd dq ?





.code
main PROC
	sub rsp, 28h	; align stack + 'shadow space' for all top level funcs
	; get module handle
		mov rcx, 0
		call GetModuleHandleW
		mov dHInstance, rax
	; register window class
		mov dword ptr[OFFSET dWindowClass],    80	;cbSize
		mov dword ptr[OFFSET dWindowClass+4],  0	;style
		lea rax, WinProc
		mov qword ptr[OFFSET dWindowClass+8], rax 	;lpfnWndProc
		mov dword ptr[OFFSET dWindowClass+16], 0	;cbClsExtra
		mov dword ptr[OFFSET dWindowClass+20], 0	;cbWndExtra
		mov rax, [dHInstance]
		mov qword ptr[OFFSET dWindowClass+24], rax	;hInstance
		mov qword ptr[OFFSET dWindowClass+32], 0	;hIcon
		mov qword ptr[OFFSET dWindowClass+40], 0	;hCursor
		mov qword ptr[OFFSET dWindowClass+48], 0	;hbrBackground
		mov qword ptr[OFFSET dWindowClass+56], 0	;lpszMenuName
		lea rax, cWindowClassName
		mov qword ptr[OFFSET dWindowClass+64], rax	;lpszClassName
		mov qword ptr[OFFSET dWindowClass+72], 0	;hIconSm

		lea rcx, dWindowClass
		call RegisterClassExW ; output ignored
	; create window
		push  0
		push  dHInstance
		push  0
		push  0
		push  768
		push  1024
		push  80000000h
		push  80000000h
		mov   r9d, 0CF0000h ;WS_OVERLAPPEDWINDOW
		lea   r8, cWindowName
		lea   rdx, cWindowClassName
		xor   ecx, ecx
		sub   rsp, 20h
		call  CreateWindowExW
		; if window status 0 -> fail
		cmp   rax, 0
		je    debug_exit
		mov   dHwnd, rax
		add rsp, 60h
	; show window
		mov rdx, 10 ; SW_SHOWDEFAULT
		mov rcx, dHwnd
		call ShowWindow

messageLoop:
    ; retrieve a message 
		mov r9, 0
		mov r8, 0
		mov rdx, 0
		lea rcx, dMSG
		call GetMessageW
		cmp eax, 0
		je exit
	; translate
		lea rcx, dMSG
		call TranslateMessage
    ; dispatch
		lea rcx, dMSG
		call DispatchMessageW
	jmp messageLoop

debug_exit:
	call GetLastError
	mov rdx, rax
exit:
	mov rcx, 0
	call ExitProcess	
main ENDP



; Window procedure
WinProc PROC hWin:QWORD, uMsg:DWORD, wParam:QWORD, lParam:QWORD 
; RCX:hWin, EDX:uMsg, R8:wParam, R9:lParam

    cmp     edx, 1
    je      handleCreateMsg
    cmp     edx, 15
    je      handlePaintMsg
    cmp     edx, 2
    je      handleDestroyMsg
    cmp     edx, 5
    je      handleResizeMsg

    ; default case
    sub     rsp, 20h
    call    DefWindowProcW
    add     rsp, 20h
    ret

handleCreateMsg:
    xor     rax, rax
    ret

handlePaintMsg:
	sub rsp, 70h ; allocate room for paint struct + 20h for shadow space
	mov r13, rsp ; store paintstruct
	add r13, 20h
	
	; begin paint
		mov rdx, r13   ; paintstruct*
		mov rcx, dHwnd ; hwnd
		call BeginPaint
		mov r12, rax ; store hdc
	; clear paint
		mov r8, 6 ; hbrush 
		mov rdx, r13 ; &paintstruct.rcPaint
		add rdx, 12
		mov rcx, r12 ; hdc
		call FillRect

	; do paint things
		; load bitmap
			push 30h ; fuload
			push 0 ; cy
			mov r9, 0 ; cx
			mov r8, 0 ; type
			mov rdx, OFFSET cSoldierSprite ; filename
			mov rcx, 0 ; hinst
			sub rsp, 20h
			call LoadImageW
			mov r14, rax ; save bitmap ptr
			add rsp, 30h
			call GetLastError
			mov rdx, rax
		; check whether bitmap loaded
			cmp r14, 0
			je skip_paint
		; create hdmem
			mov rcx, r12 ; hdc
			call CreateCompatibleDC
			mov r13, rax ; store hdc mem
		; load bitmap into hdmem
			mov rdx, r14 ; bitmap
			mov rcx, r13 ; hdmem
			call SelectObject
		; perform transfer
			push 0 ; align stack

			push 00CC0020h ; copy op
			push 0 ; src y
			push 0 ; src x
			push r13 ; hdc src
			push 32 ; height
			mov r9, 32 ; width
			mov r8, 0 ; y
			mov rdx, 0 ; x
			mov rcx, r12 ; hdc
			sub rsp, 20h
			call BitBlt
			add rsp, 50h
		; delete hdcmem
			mov rcx, r13
			call DeleteDC

		
skip_paint:
	; end paint
		mov rdx, r13   ; paintstruct*
		mov rcx, dHwnd ; hwnd
		call EndPaint

	add rsp, 20h ; clear shadow space



    xor     rax, rax
    ret

handleDestroyMsg:
    sub     rsp, 20h
    mov     rcx, 0          ; exit with exitcode 0
    call    PostQuitMessage
    add     rsp, 20h
    xor     rax, rax
    ret

handleResizeMsg:
    xor     rax, rax
    ret

WinProc ENDP


END