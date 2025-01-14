
LoadImageW PROTO
CreateCompatibleDC PROTO
SelectObject PROTO
MaskBlt PROTO 

GetActorSprite PROTO


extern dWinX : dword
extern dWinY : dword

extern dCameraX : dword
extern dCameraY : dword



.code


; r9: bitmap object ptr
; r8: bitmap size (x & y will be the same)
; rdx: maskmap path ptr
; rcx: bitmap path ptr
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




; r13: sprite_object (pass through)
; rcx: hdc
SetSpriteDevice PROC
	sub rsp, 28h
	; if bitmap hdc mem is valid, skip
		cmp qword ptr [r13+10h], 0
		jne return
		; create hdmem
			;mov rcx, rcx ; window hdc (redundant)
			call CreateCompatibleDC
			mov qword ptr[r13+10h], rax ; store bitmap hdc mem
		; load bitmap
			mov rdx, qword ptr [r13] ; bitmap
			mov rcx, rax ; hdmem
			call SelectObject
	return:
		add rsp, 28h
		ret
SetSpriteDevice ENDP

; r12: actor ptr (paas through)
; rcx: hdc
DrawActorSprite PROC
	push r13
	push r14
	push r15
	; rcx : hdc
	; rax : temp
	; rdx : temp
	; rsi : temp
	; rdi : temp
	; r12 : actor ptr
	; r8 : left overlap
	; r9 : right overlap
	; r10 : top overlap
	; r11 : bot overlap
	; r13 : sprite ptr
	; r14 : pox Y (adjusted)
	; r15 : pos X (adjusted)
		mov r14, rcx ; temp preserve value of rcx
	; get actor type sprite address
		mov rcx, r12
		call GetActorSprite
		mov r13, rax 
	; validate sprite
		cmp qword ptr [r13], 0 ; check bitmap
		je skip_draw
		cmp qword ptr [r13+8], 0 ; check maskmap
		je skip_draw
		cmp dword ptr [r13+18h], 0 ; check size
		je skip_draw
	; load sprite HDC 
		mov rcx, r14 
		call SetSpriteDevice
		mov rcx, r14 
	; calc actor half width
		mov eax, dword ptr [r13+18h]
		shr eax, 1
	; calc actor screen position
		mov r15d, dword ptr [r12+8] 
		mov r14d, dword ptr [r12+12]
		sub r15d, eax ; x 
		sub r14d, eax ; y
	; translate to local screen position
		sub r15d, dCameraX
		sub r14d, dCameraY
	; validate whether sprite is on screen
		; horizontal
			xor r8d, r8d ; left overlap
			mov r9d, dword ptr [r13+18h] ; right overlap = sprite size
			; validate right side
				mov eax, r15d ; x pos
				add eax, dword ptr [r13+18h] ; sprite size
				; if x + width >= max_x
				cmp eax, dWinX
				jl block6
					mov eax, r15d ; x pos
					; if x >= max_x :: sprite is not visible
					cmp eax, dWinX
					jge skip_draw
					; store size - overlap
					mov edx, dWinX
					sub edx, eax
					mov r9d, edx ; move available space into r9d
				block6:
			; vaidate left side
				mov eax, r15d ; x pos
				; if x < 0
				cmp eax, 0
				jge block5
					add eax, dword ptr [r13+18h] ; sprite size
					; if x + width < 0 :: sprite is not visible
					cmp eax, 0
					jl skip_draw
					; store overlap
					mov edx, dword ptr [r13+18h]
					sub edx, eax
					mov r8d, edx
					sub r9d, edx
				block5:
		; vertical
			xor r10d, r10d ; top overlap
			mov r11d, dword ptr [r13+18h] ; bottom overlap = sprite size
			; validate bottom side
				mov eax, r14d ; y pos
				add eax, dword ptr [r13+18h] ; sprite size
				; if y + width >= max_y
				cmp eax, dWinY
				jl block8
					mov eax, r14d ; y pos
					; if y >= max_x :: sprite is not visible
					cmp eax, dWinY
					jge skip_draw
					; store size - overlap
					mov edx, dWinY
					sub edx, eax
					mov r11d, edx ; move available space into r11d
				block8:
			; vaidate top side
				mov eax, r14d ; y pos
				; if y < 0
				cmp eax, 0
				jge block7
					add eax, dword ptr [r13+18h] ; sprite size
					; if y + width < 0 :: sprite is not visible
					cmp eax, 0
					jl skip_draw
					; store overlap
					mov edx, dword ptr [r13+18h]
					sub edx, eax
					mov r10d, edx
					sub r11d, edx
				block7:
	; update position values to use overlap values
		add r15d, r8d ; x
		add r14d, r10d ; y
	; get actors current sprite frame
		xor rax, rax
		mov al, byte ptr [r12+5]
		push rcx ; reserve extra temp register
		mov cl, al
		shr al, 3
		and al, 7 ; al: state index
		shr cl, 6 ; cl: state
	; write final sprite_x (->rdi)
		xor edx, edx
		mov esi, dword ptr [r13+18h]
		mul esi
		add eax, r8d
		mov edi, eax
	; write final sprite_x (->rax)
		xor edx, edx
		xor eax, eax
		mov al, cl
		pop rcx
		mov esi, dword ptr [r13+18h]
		mul esi
		add eax, r10d
	; draw
		push 0AACC0020h ; copy src foreground, maintain dst background ; copy op (00CC0020h)
		
		push rax ; mask y
		push rdi ; mask x
		push qword ptr [r13+8] ; mask hdc src

		push rax ; src y
		push rdi ; src x
		push qword ptr [r13+10h] ; hdc src

		push r11 ; height
		;mov r9, r9 ; width (redundant mov)
		mov r8d, r14d ; y
		mov edx, r15d ; x
		;mov rcx, rcx ; hdc (redundant mov)
		mov r14, rcx ; preserve rcx
		sub rsp, 20h
		call MaskBlt
		add rsp, 60h
		mov rcx, r14
	skip_draw:
		pop r15
		pop r14
		pop r13
		ret
DrawActorSprite ENDP

END