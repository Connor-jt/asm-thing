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
MaskBlt PROTO 
DeleteDC PROTO

.data
cWindowClassName dw 'E','x','W','i','n','C','l','a','s','s', 0
cWindowName dw 'E','x','W','i','n','N','a','m','e', 0
cSoldierSprite dw 's','d','.','b','m','p', 0
cSoldierSpriteMask dw 's','d','m','.','b','m','p', 0

.data?
; internal windows stuff
dHInstance dq ?
dWindowClass db 80 dup(?)
dMSG db 48 dup(?)
dHwnd dq ?

; game structs
dSoldierSprite db 28 dup(?) ; 0x0 bitmap ptr
							; 0x8 mask bitmap ptr
							; 0x10 bitmap hdc
							; 0x18 bitmap dimensions (1x4byte)
;



.code
main PROC
	sub rsp, 28h	; align stack + 'shadow space' for all top level funcs
	; load app resources
		mov rcx, OFFSET cSoldierSprite
		mov rdx, OFFSET cSoldierSpriteMask
		mov r8, 32
		mov r9, OFFSET dSoldierSprite
		call LoadSprite

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

; rcx: bitmap path ptr
; rdx: maskmap path ptr
; r8: bitmap size (x & y will be the same)
; r9: bitmap object ptr
LoadSprite PROC
	; config locals
		sub rsp, 8 ; align stack
		push r12
		push r13
		mov r12, r9 ; obj ptr
		mov r13, rdx ; mask map
	; configure static variables (including the input size var)
		mov qword ptr[r9+10h], 0
		mov qword ptr[r9+18h], r8
	; load bitmap
		push 10h ; fuload
		push 0 ; cy
		mov r9, 0 ; cx
		mov r8, 0 ; type
		mov rdx, rcx ; filename
		mov rcx, 0 ; hinst
		sub rsp, 20h
		call LoadImageW
		add rsp, 30h
		mov qword ptr[r12], rax
	; load maskmap
		push 10h ; fuload
		push 0 ; cy
		mov r9, 0 ; cx
		mov r8, 0 ; type
		mov rdx, r13 ; filename
		mov rcx, 0 ; hinst
		sub rsp, 20h
		call LoadImageW
		mov qword ptr[r12+8], rax
		add rsp, 30h
	; ret
		pop r13
		pop r12
		add rsp, 8
		ret
LoadSprite ENDP

; rcx: hdc
; rdx: sprite_object
RenderSprite PROC
	; config locals
		push r12
		push r13
		sub rsp, 28h
		mov r12, rcx ; hdc
		mov r13, rdx ; sprite_object

	; if bitmap invalid, skip
		cmp qword ptr [r13], 0 ; check bitmap
		je sprite_draw_end
		cmp qword ptr [r13+8], 0 ; check maskmap
		je sprite_draw_end
		cmp dword ptr [r13+18h], 0 ; check size
		je sprite_draw_end

		; if bitmap hdc mem is valid, skip
			cmp qword ptr [r13+10h], 0
			jne sprite_draw
			; create hdmem
				mov rcx, r12 ; window hdc
				call CreateCompatibleDC
				mov qword ptr[r13+10h], rax ; store bitmap hdc mem
			; load bitmap
				mov rdx, qword ptr [r13] ; bitmap
				mov rcx, rax ; hdmem
				call SelectObject

	sprite_draw:
		xor rax, rax ; TOOD: cleanup unnecessary casts
		mov eax, dword ptr [r13+18h] ; grab the size 
		mov rcx, qword ptr [r13+10h] ; + bitmap hdmem
		mov rdx, qword ptr [r13+8] ; + maskmap 

		push 0AACC0020h ; copy src foreground, maintain dst background ; copy op (00CC0020h)
		
		push 0 ; mask y
		push 0 ; mask x
		push rdx ; mask hdc src

		push 0 ; src y
		push 0 ; src x
		push rcx ; hdc src

		push rax ; height
		mov r9, rax ; width
		mov r8, 0 ; y
		mov rdx, 0 ; x
		mov rcx, r12 ; hdc
		sub rsp, 20h
		call MaskBlt
		add rsp, 60h

	sprite_draw_end:
		add rsp, 28h
		pop r13
		pop r12
		ret
RenderSprite ENDP


TestRender PROC
	; config locals
		push r12
		push r13
		sub rsp, 78h ; allocate room for paint struct + 20h for shadow space + 8 padding
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
		mov rdx, OFFSET dSoldierSprite
		mov rcx, r12
		call RenderSprite
	; wipe all created devices
		mov rcx, qword ptr [OFFSET dSoldierSprite+10h]
		call DeleteDC
		mov qword ptr [OFFSET dSoldierSprite+10h], 0


	; end paint
		mov rdx, r13   ; paintstruct*
		mov rcx, dHwnd ; hwnd
		call EndPaint

	; return
		add rsp, 78h ; clear shadow space
		pop r13
		pop r12
		ret
TestRender ENDP







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
	call TestRender
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