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
LoadImageW PROTO

extern LoadSpriteLibrary : proc ; sprite library entry
extern TestRender : proc ; render entry
; input imports
extern FlushInputs : proc
extern dKeyMap : db
extern dMouseX : dw
extern dMouseY : dw


.data
cWindowClassName dw 'E','x','W','i','n','C','l','a','s','s', 0
cWindowName dw 'E','x','W','i','n','N','a','m','e', 0
cCursorPath dw 'r','e','s','/','i','c','o','n','s','/','c','u','r','s','o','r','/','1','.','c','u','r', 0
; constant runtimes
dTimeFequency dq 0
public dTimeFequency

dLastTime dq 0
dCurrTime dq 0
dFrameDebt dq 0

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
		
	; load cursor
		push 10h ; fuload
		push 32 ; cy
		mov r9, 32 ; cx
		mov r8, 2 ; type (cursor)
		mov rdx, OFFSET cCursorPath ; filename
		mov rcx, 0 ; hinst
		sub rsp, 20h
		call LoadImageW
		mov qword ptr[OFFSET dWindowClass+40], rax	;hCursor
		add rsp, 30h
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
	; check for any windows messages
		; push 1 ; redundant; we basically make this a constant in the stack
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

	
	; complete tick by flushing inputs
		call FlushInputs

	; get time past since last tick
		mov rcx, OFFSET dCurrTime
		call QueryPerformanceCounter
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
		mov rdx, 100
		sub rdx, dFrameDebt
		sub rdx, rax
		jl skip_sleep ; immediately jump to next tick if we didnt make it through this one in time
		mov qword ptr [rsp+28h], rdx
		mov rcx, rdx
		call Sleep
	; measure time spent sleeping and note it down as debt time
		mov rcx, OFFSET dLastTime ; invert roles here, just because it makes it easier
		call QueryPerformanceCounter
		mov rax, dLastTime
		sub rax, dCurrTime
		mov rcx, 1000
		mul rcx
		mov rcx, dTimeFequency
		mov rdx, 0
		div rcx
		;add rax, 1 ; basically just round up the miliseconds value
		mov rcx, qword ptr [rsp+28h] ; the minimum sleep miliseconds
		sub rax, rcx ; rax is the executed sleep miliseconds
		mov dFrameDebt, rax ; so we write how many miliseconds we went over by
	jmp messageLoop

	skip_sleep: 
		mov dFrameDebt, 0
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
WinProc PROC hWin:QWORD, uMsg:DWORD, wParam:QWORD, lParam:QWORD ; for some reason this a a requirement to have

    cmp     edx, 15
    je      handlePaintMsg
	cmp		edx, 0200h
	je		handleMouseMove
	; left mouse
		cmp		edx, 0201h
		je		handleMouseLDown
		;cmp		edx, 0202h
		;je		handleMouseLUp
	; right mouse
		cmp		edx, 0204h
		je		handleMouseRDown
		;cmp		edx, 0205h
		;je		handleMouseRUp
	; middle mouse
		cmp		edx, 0207h
		je		handleMouseMDown
		;cmp		edx, 0208h
		;je		handleMouseMUp
	; key inputs
		cmp		edx, 0100h
		je		handleKeyDown
		;cmp		edx, 0101h
		;je		handleKeyUp

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
	mov rcx, dHwnd
	call TestRender
	xor rax, rax
	ret
	
;handleMouseMUp:
;	lea rcx, dKeyMap
;	mov byte ptr [rcx+4], 0
;	jmp handleMouseMove
handleMouseMDown:
	lea rcx, dKeyMap
	mov byte ptr [rcx+4], 1
	jmp handleMouseMove
;handleMouseRUp:
;	lea rcx, dKeyMap
;	mov byte ptr [rcx+2], 0
;	jmp handleMouseMove
handleMouseRDown:
	lea rcx, dKeyMap
	mov byte ptr [rcx+2], 1
	jmp handleMouseMove
;handleMouseLUp:
;	lea rcx, dKeyMap
;	mov byte ptr [rcx+1], 0
;	jmp handleMouseMove
handleMouseLDown:
	lea rcx, dKeyMap
	mov byte ptr [rcx+1], 1
	;jmp handleMouseMove ; redundant
handleMouseMove:
	xor rax, rax
	mov eax, r9d
	shr rax, 16
	mov dMouseY, rax
	movzx rax, r9w
	mov dMouseX, rax
    xor rax, rax
    ret


handleKeyDown:
	movzx rax, r8b
	lea rcx, dKeyMap
	mov byte ptr [rcx + rax], 1
    xor rax, rax
    ret
;handleKeyUp:
;	movzx rax, r8b
;	lea rcx, dKeyMap
;	mov byte ptr [rcx + rax], 0
;   xor rax, rax
;   ret

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