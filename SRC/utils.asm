

; rdx: end of buffer ptr
; rcx: number
U64ToWStr PROC
	; config destination
		;sub rsp, 48 ; max characters
		mov r8, rdx
		add r8, 2
		mov word ptr [r8], 0 ; null terminate
	; config locals
		mov rax, rcx
		mov rcx, 10 
	; if num is NOT 0 then run process
		cmp rax, 0
		jne read_loop
	; otherwise insert '0' and return
		add r8, 2
		mov word ptr [r8], 30h
		jmp exit_loop
	; loop the number
		read_loop:
			; break loop if nothing left to process
			cmp rax, 0
			je exit_loop
			
			xor rdx, rdx
			div rcx ; RAX = RAX / RCX, RDX = RAX % RCX
			
			add r8, 2
			add rdx, 30h
			mov word ptr [r8], dx

			jmp read_loop
		exit_loop:
	; return
		mov rax, r8
		ret
U64ToWStr ENDP
