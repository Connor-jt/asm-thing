.data
; see https://learn.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes

dKeyMap byte 256 dup(0)
dHeldKeyMap byte 256 dup(0)

dMouseX dword 0
dMouseY dword 0

public dKeyMap
public dHeldKeyMap
public dMouseX
public dMouseY

.code

FlushInputs PROC
	xor rax, rax
	lea rcx, dKeyMap
	clear_input_bytes:
		mov qword ptr [rcx + rax], 0
	; check to see if loop is complete
		add rax, 8
		cmp rax, 256
		jne clear_input_bytes
	; return
		ret
FlushInputs ENDP

END