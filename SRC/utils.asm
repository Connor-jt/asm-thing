
.code
; rdx: end of buffer ptr
; rcx: number
U64ToWStr PROC
	; config destination
		mov r8, rdx
		sub r8, 2
		mov word ptr [r8], 0 ; null terminate
	; config locals
		mov rax, rcx
		mov rcx, 10 
	; if num is NOT 0 then run process
		cmp rax, 0
		jne read_loop
	; otherwise insert '0' and return
		sub r8, 2
		mov word ptr [r8], 30h
		jmp return
	; loop the number
		read_loop:
			; break loop if nothing left to process
			cmp rax, 0
			je return
			
			xor rdx, rdx
			div rcx ; RAX = RAX / RCX, RDX = RAX % RCX
			
			sub r8, 2
			add rdx, 30h
			mov word ptr [r8], dx

			jmp read_loop
	return:
		mov rax, r8
		ret
U64ToWStr ENDP

END