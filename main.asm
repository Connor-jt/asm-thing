ExitProcess PROTO
RegisterClassExA PROTO
GetModuleHandleA PROTO
CreateWindowExA PROTO
DefWindowProcA PROTO

.data
cWindowClassName db "My Window Class", 0
cWindowName db "My Window Name", 0


.data?
dHInstance dq ?
dWindowClass db 80 dup(?)
dHwnd dq ?





.code
main PROC
	sub rsp, 28h	; align stack + 'shadow space'
	
	; get module handle
		mov rcx, 0
		call GetModuleHandleA
		mov dHInstance, rax
	;

	; register window class
		mov dword ptr[OFFSET dWindowClass],    80	;cbSize
		mov dword ptr[OFFSET dWindowClass+4],  0	;style
		lea rax, WinProc
		mov qword ptr[OFFSET dWindowClass+8], rax 	;lpfnWndProc
		mov dword ptr[OFFSET dWindowClass+16], 0	;cbClsExtra
		mov dword ptr[OFFSET dWindowClass+20], 0	;cbWndExtra
		lea rax, dHInstance
		mov qword ptr[OFFSET dWindowClass+24], rax	;hInstance
		mov qword ptr[OFFSET dWindowClass+32], 0	;hIcon
		mov qword ptr[OFFSET dWindowClass+40], 0	;hCursor
		mov qword ptr[OFFSET dWindowClass+48], 0	;hbrBackground
		mov qword ptr[OFFSET dWindowClass+56], 0	;lpszMenuName
		lea rax, cWindowClassName
		mov qword ptr[OFFSET dWindowClass+64], rax	;lpszClassName
		mov qword ptr[OFFSET dWindowClass+72], 0	;hIconSm

		lea rcx, dWindowClass
		call RegisterClassExA ; output ignored
	;
	add rsp, 20h

	; create window
		push  0
		push  dHInstance
		push  0
		push  0
		push  768
		push  1024
		push  80000000h
		push  80000000h
		sub   rsp, 20h
		mov   r9d, 0CF0000h ;WS_OVERLAPPEDWINDOW
		lea   r8, cWindowName
		lea   rdx, cWindowClassName
		xor   ecx, ecx
		call  CreateWindowExA

		cmp   rax, 0
		je    exit
		mov   dHwnd, rax
	;



exit:
	mov rcx, 12345678	; the exit code
	call ExitProcess	
main ENDP



; Window procedure
WinProc PROC hWin:QWORD, uMsg:DWORD, wParam:QWORD, lParam:QWORD

; hWin in RCX
; uMsg in EDX
; wParam in R8
; lParam in R9

    ; Check the message uMsg (is in edx)
    cmp     edx, 1
    je      handleCreateMsg
    cmp     edx, 15
    je      handlePaintMsg
    cmp     edx, 2
    je      handleDestroyMsg
    cmp     edx, 5
    je      handleResizeMsg

    ; default handler   (called with input params hWin,uMsg,wParam and lParam still in registers rcx,edx,r8 and r9)
    sub     rsp, 20h
    call    DefWindowProcA    ; (https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-defwindowprocw)
    add     rsp, 20h
    ret

handleCreateMsg:
    xor     rax, rax
    ret

handlePaintMsg:
    xor     rax, rax
    ret

handleDestroyMsg:    ;(https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-postquitmessage)
    sub     rsp, 20h
    mov     rcx, 0          ; exit with exitcode 0
    ;call    PostQuitMessage
    add     rsp, 20h
    xor     rax, rax
    ret

handleResizeMsg:
    xor     rax, rax
    ret

WinProc ENDP


END