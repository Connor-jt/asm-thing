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
QueryPerformanceCounter PROTO
QueryPerformanceFrequency PROTO
RedrawWindow PROTO
InvalidateRect PROTO
UpdateWindow PROTO
PeekMessageW PROTO
Sleep PROTO

extern LoadSpriteLibrary : proc ; sprite library entry
extern TestRender : proc ; render entry


.data
cWindowClassName dw 'E','x','W','i','n','C','l','a','s','s', 0
cWindowName dw 'E','x','W','i','n','N','a','m','e', 0
; constant runtimes
dTimeFequency dq 0
public dTimeFequency

dLastTime dq 0
dCurrTime dq 0

.data?
dHInstance dq ?
dWindowClass db 80 dup(?)
dMSG db 48 dup(?)
dHwnd dq ?




.code
main PROC
	sub rsp, 28h	; align stack + 'shadow space'
	; load app resources
		call LoadSpriteLibrary

	; get timestamp frrequency & set base time
		mov rcx, OFFSET dTimeFequency
		call QueryPerformanceFrequency
		mov rcx, OFFSET dLastTime
		call QueryPerformanceCounter
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
		je    exit
		mov   dHwnd, rax
		add rsp, 60h
	; show window
		mov rdx, 10 ; SW_SHOWDEFAULT
		mov rcx, dHwnd
		call ShowWindow

	sub rsp, 30h
	mov qword ptr [rsp+20h], 1
	messageLoop:
		; push 1 ; we basically make this a constant in the stack
		mov r9, 0
		mov r8, 0
		mov rdx, 0
		lea rcx, dMSG
		call PeekMessageW
		; if no message then we can run next game tick
		cmp eax, 0
		je run_tick
	; translate
		lea rcx, dMSG
		call TranslateMessage
    ; dispatch
		lea rcx, dMSG
		call DispatchMessageW
	; if it was a wm_quit message, then close everything down
		mov eax, dword ptr [OFFSET dMSG+8]
		cmp eax, 12h
		je exit
	; return to process next message if we successfully processed a message (implying there will be more in the queue??)
	jmp messageLoop
	
	run_tick: ; so far we just do a redraw call and thats it
		mov r9, 101h
		mov r8, 0
		mov rdx, 0
		mov rcx, dHwnd
		call RedrawWindow

	; get time past since last tick
		mov rcx, OFFSET dCurrTime
		call QueryPerformanceCounter
		; ((dCurrTime - dLastTime) * 10000000) / frequency
		mov rax, dCurrTime
		sub rax, dLastTime
		mov rcx, 1000
		mul rcx
		mov rcx, dTimeFequency
		mov rdx, 0
		div rcx ; RAX = RAX / RCX, RDX = RAX % RCX
	; calc how much time we have to spare before running another tick
		; 100 = 10 fps
		;  66 = 15 fps
		;  33 = 30 fps
		;  16 = 60 fps
		mov rdx, 16
		sub rdx, rax
		jl skip_sleep ; immediately jump to next tick if we didnt make it through this one in time
		mov rcx, rdx
		call Sleep
	skip_sleep: 
		mov rcx, OFFSET dLastTime
		call QueryPerformanceCounter
	jmp messageLoop

	exit:
		mov rcx, 0
		call ExitProcess	
main ENDP

; rcx: hWin, 
; edx: uMsg, 
; r8: wParam, 
; r9: lParam
WinProc PROC hWin:QWORD, uMsg:DWORD, wParam:QWORD, lParam:QWORD 

    cmp     edx, 15
    je      handlePaintMsg
    cmp     edx, 2
    je      handleDestroyMsg
    cmp     edx, 5
    je      handle_invalid_skip
    ;je     handleResizeMsg
    cmp     edx, 1
    je      handle_invalid_skip
    ;je     handleCreateMsg

    ; default case
    sub     rsp, 20h
    call    DefWindowProcW
    add     rsp, 20h
    ret



handlePaintMsg:
	; paint
		mov rcx, dHwnd
		call TestRender
		xor rax, rax
		ret
		
handleDestroyMsg:
    sub rsp, 20h
    mov rcx, 0          ; exit with exitcode 0
    call PostQuitMessage
    add rsp, 20h
    xor rax, rax
    ret

;handleCreateMsg:
;    xor     rax, rax
;    ret
;handleResizeMsg:
;    xor     rax, rax
;    ret

handle_invalid_skip:
    xor     rax, rax
    ret
WinProc ENDP


END