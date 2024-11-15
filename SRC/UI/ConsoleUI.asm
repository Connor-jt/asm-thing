
DrawTextW PROTO
SetTextColor PROTO
SetBkMode PROTO


.data

dConsoleBuffer db 4096 dup(0) ; NOTE: this is for a WIDE str, so theres only 2048 characters of space
dConsolePosition dq 0

.code
; rdx: use newline
; rcx: str ptr
ConsolePrint PROC
	lea r10, dConsoleBuffer
	; if we already have data in the buffer, replace the null terminator with a 
		cmp dConsolePosition, 0
		je skip_str_join
		mov rax, dConsolePosition
		sub rax, 2
	; join text with either newline or space
		cmp rdx, 1
		je join_with_newline
		mov word ptr [r10+rax], 32
		jmp skip_str_join
	join_with_newline:
		mov word ptr [r10+rax], 10


	skip_str_join:
	mov rdx, dConsolePosition
	xor rsi, rsi
	str_copy:
		mov ax, word ptr [rcx+rsi]
		mov word ptr [r10+rdx], ax
		; check to see if we reached the end of the buffer and make more room if need be
			add rdx, 2
			add rsi, 2
			cmp rdx, 4096
			je pop_console
		return_from_pop_console:
		; check to see if last character copied was a null terminator
			cmp ax, 0
			je finish_copy

	jmp str_copy
	finish_copy:
	mov dConsolePosition, rdx
	ret

	; copy upper 1024 bytes to lower
	pop_console:
		xor rdi, rdi
		lea r11, dConsoleBuffer
		mov r8, r11
		add r8, 2048
	copy_bytes:
		mov r9, qword ptr [r8+rdi]
		mov qword ptr [r11+rdi], r9
	; increment and break when we reach 2048 bytes moved
		add rdi, 8
		cmp rdi, 2048
		jne copy_bytes
	jmp return_from_pop_console
ConsolePrint ENDP

; rcx: hdc
ConsoleRender PROC
	; config local vars
		push r12
		mov r12, rcx
		sub rsp, 20h
	; config system vars
		mov rdx, 0000000ffh ; color
		;mov rcx, rcx ; hdc (passes straight through)
		call SetTextColor
		mov rdx, 1 ; transparent
		mov rcx, r12 ; hdc
		call SetBkMode
	; render everything to text box
		push 0 ; ALIGN
		push 240 ; bottom
		push 210 ; right
		push 40 ; top
		push 10 ; left
		mov r9, rsp; rect ptr
		push 00000100h ; format 
		mov r8, -1 ; char count 
		lea rdx, dConsoleBuffer ; wstr ptr
		mov rcx, r12 ; hdc
		sub rsp, 20h
		call DrawTextW
	; cleanup & return
		add rsp, 70h
		pop r12
		ret
ConsoleRender ENDP

END