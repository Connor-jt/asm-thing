
DrawTextW PROTO
SetTextColor PROTO

U64ToWStr PROTO

ConsoleFadeTimer equ 15 ; 1.5 second

.data

dConsoleBuffer db 4096 dup(0) ; NOTE: this is for a WIDE str, so theres only 2048 characters of space
dConsolePosition dq 0
dConsoleStartPosition dq 0
dConsoleHasHadReset db 0

dClearNextTicks dq 0 

dConsoleWriteCount dq 0
public dConsoleWriteCount


.code
; rdx: use newline
; rcx: str ptr
ConsolePrint PROC
	inc dConsoleWriteCount
	lea r10, dConsoleBuffer
	; if we already have data in the buffer, replace the null terminator with a joiner character
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
	mov rdx, 2048 ; make sure we reset the writing point
	mov dConsoleHasHadReset, 1 ; so we know that the first byte of this buffer is probably not actually the start of a new word
	; push our start position back as well, and reset if it was not less than 2048 thingos away???
		sub dConsoleStartPosition, 2048
		jge c19
			mov dConsoleStartPosition, 0
		c19:
	jmp return_from_pop_console
ConsolePrint ENDP

; rcx: num
ConsolePrintNumber PROC
	; convert number into string
		mov rdx, rsp
		sub rsp, 38h ; + 8 alignment
		;mov rcx, rcx (pass through)
		call U64ToWStr
	; run print function
		mov rdx, 0
		mov rcx, rax
		call ConsolePrint
	; return
		add rsp, 38h
		ret
ConsolePrintNumber ENDP

; rcx: hdc
ConsoleRender PROC
	; config local vars
		push r12
		mov r12, rcx
		sub rsp, 20h
	; config system vars
		mov rdx, 0004040ffh ; color
		;mov rcx, rcx ; hdc (passes straight through)
		call SetTextColor

	; config fade timer
		lea rdx, dConsoleBuffer ; wstr ptr
		; if start & end position are the same, 
			mov rax, dConsoleStartPosition
			add rax, 2
			cmp rax, dConsolePosition
			jl c14
				mov dClearNextTicks, 0
				jmp skip_draw ; nothing to display
			c14:
		; else tick
			inc dClearNextTicks
			cmp dClearNextTicks, ConsoleFadeTimer
			jl c15
				mov dClearNextTicks, 0
				; here we clear the current line by incrementing insertion index until we reach a newline 
				mov rax, dConsoleStartPosition
				add rax, 2 ; force it to skip over current newline if we are on one
				__look_for_next_newline:
					cmp rax, dConsolePosition
					jge cleared_last_line
					mov cl, byte ptr [rdx+rax]
					cmp cl, 10	
					je break_loop
					add rax, 2
					jmp __look_for_next_newline
				break_loop:
				mov dConsoleStartPosition, rax
				jmp c15

				cleared_last_line:
					sub rax, 2
					mov dConsoleStartPosition, rax
					jmp skip_draw
			c15:

	; calculate where our start point is for the string
		mov rax, dConsolePosition
		; if the string is too long, then increase the string start pos
			cmp rax, 2048
			jle c16
				sub rax, 2048
				jmp c17
			c16:
				xor eax, eax
			c17:
		; if calculated position is higher than forced start pos, then update forced start
			cmp rax, dConsoleStartPosition
			jle c18
				mov dConsoleStartPosition, rax
				jmp c19
			c18:
		; else use console start position as our insertion point
				mov rax, dConsoleStartPosition
			c19:
		; if we are at offset 0, then we want to skip the newline entry point search
			cmp rax, 0
			jne look_for_next_newline
				cmp dConsoleHasHadReset, 0
				je skip_buffer_entry_search
		; if we dont start at the start of the buffer, then look for the nearest newline character to print our string from
		look_for_next_newline:
			mov cl, byte ptr [rdx+rax]
			add rax, 2
			cmp cl, 10	
			jne look_for_next_newline
		skip_buffer_entry_search:
	; render everything to text box
		sub rsp, 18h
		mov dword ptr [rsp+12], 240 ; bottom
		mov dword ptr [rsp+8], 210 ; right
		mov dword ptr [rsp+4], 40 ; top
		mov dword ptr [rsp], 10 ; left
		mov r9, rsp; rect ptr
		push 00000100h ; format 
		mov r8, -1 ; char count 
		add rdx, rax
		mov rcx, r12 ; hdc
		sub rsp, 20h
		call DrawTextW
	; cleanup & return
		add rsp, 60h
		pop r12
		ret
	skip_draw:
		add rsp, 20h
		pop r12
		ret
ConsoleRender ENDP

END