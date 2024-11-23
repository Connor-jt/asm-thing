
LoadImageW PROTO
CreateCompatibleDC PROTO
SelectObject PROTO
MaskBlt PROTO 
DeleteDC PROTO


;

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
; r12: hdc (pass through)
SetSpriteDevice PROC
	sub rsp, 28h
	; if bitmap hdc mem is valid, skip
		cmp qword ptr [r13+10h], 0
		jne return
		; create hdmem
			mov rcx, r12 ; window hdc
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

; r15: x
; r14: y
; r13: sprite_object (pass through)
; r12: hdc (pass through)
;RenderSprite PROC
;	sub rsp, 8
;	; if bitmap invalid, skip
;		cmp qword ptr [r13], 0 ; check bitmap
;		je sprite_draw_end
;		cmp qword ptr [r13+8], 0 ; check maskmap
;		je sprite_draw_end
;		cmp dword ptr [r13+18h], 0 ; check size
;		je sprite_draw_end
;
;		call SetSpriteDevice
;		
;		xor rax, rax ; TOOD: cleanup unnecessary casts
;		mov eax, dword ptr [r13+18h] ; grab the size 
;		mov rcx, qword ptr [r13+10h] ; + bitmap hdmem
;		mov rdx, qword ptr [r13+8] ; + maskmap 
;
;		push 0AACC0020h ; copy src foreground, maintain dst background ; copy op (00CC0020h)
;		
;		push 0 ; mask y
;		push 0 ; mask x
;		push rdx ; mask hdc src
;
;		push 0 ; src y
;		push 0 ; src x
;		push rcx ; hdc src
;
;		push rax ; height
;		mov r9, rax ; width
;		mov r8, 0 ; y
;		mov rdx, 0 ; x
;		mov rcx, r12 ; hdc
;		sub rsp, 20h
;		call MaskBlt
;		add rsp, 60h
;	sprite_draw_end:
;		add rsp, 8
;		ret
;RenderSprite ENDP

; r12: hdc (pass through)
; rcx: actor ptr
DrawActorSprite PROC
	push r13
	push r14
	push r15
	; rax : temp
	; rdx : temp
	; rsi : temp
	; rdi : temp
	; rcx : actor ptr
	; r8 : left overlap
	; r9 : right overlap
	; r10 : top overlap
	; r11 : bot overlap
	; r12 : hdc
	; r13 : sprite ptr
	; r14 : pox Y (adjusted)
	; r15 : pos X (adjusted)
	; get actor type sprite address
		mov rax, dword ptr [rcx] 
		shr rax, 21 ; rshift the unit type
		xor rdx, rdx
		mov r13, 28
		mul r13
		lea r13, dSoldierSprite
		add r13, rax
	; validate sprite
		cmp qword ptr [r13], 0 ; check bitmap
		je skip_draw
		cmp qword ptr [r13+8], 0 ; check maskmap
		je skip_draw
		cmp dword ptr [r13+18h], 0 ; check size
		je skip_draw
	; load sprite HDC 
		mov r14, rcx ; preserve value of rcx
		call SetSpriteDevice
		mov rcx, r14 
	; calc actor half width
		mov rax, dword ptr [r13+18h]
		shr rax, 1
	; calc actor screen position
		mov r15, dword ptr [rcx+8] 
		mov r14, dword ptr [rcx+12]
		sub r15, rax ; x 
		sub r14, rax ; y
		; add in screen position !!!

	; validate whether sprite is on screen
		; horizontal
			xor r8, r8 ; left overlap
			xor r9, r9 ; right overlap
			; vaidate left side
				mov rax, r15 ; x pos
				; if x < 0
				cmp rax, 0
				jge block5
					add rax, dword ptr [r13+18h] ; sprite size
					; if x + width < 0 :: sprite is not visible
					cmp rax, 0
					jl skip_draw
					; store overlap
					mov r8, rax
				block5:
			; validate right side
				mov rax, r15 ; x pos
				add rax, dword ptr [r13+18h] ; sprite size
				; if x + width >= max_x
				cmp rax, dWinX
				jl block6
					mov rax, r15 ; x pos
					; if x >= max_x :: sprite is not visible
					cmp rax, dWinX
					jge skip_draw
					; store size - overlap
					mov rdx, dWinX
					sub rdx, rax
					mov r9, dword ptr [r13+18h] ; sprite size
					sub r9, rdx
				block6:
		; vertical
			xor r10, r10 ; top overlap
			xor r11, r11 ; bottom overlap
			; vaidate left side
				mov rax, r14 ; y pos
				; if y < 0
				cmp rax, 0
				jge block7
					add rax, dword ptr [r13+18h] ; sprite size
					; if y + width < 0 :: sprite is not visible
					cmp rax, 0
					jl skip_draw
					; store overlap
					mov r10, rax
				block7:
			; validate right side
				mov rax, r14 ; y pos
				add rax, dword ptr [r13+18h] ; sprite size
				; if y + width >= max_y
				cmp rax, dWinX
				jl block8
					mov rax, r14 ; y pos
					; if y >= max_x :: sprite is not visible
					cmp rax, dWinY
					jge skip_draw
					; store size - overlap
					mov rdx, dWinY
					sub rdx, rax
					mov r11, dword ptr [r13+18h] ; sprite size
					sub r11, rdx
				block8:
	; update position values to use overlap values
		add r15, r18 ; x
		add r14, r10 ; y
		sub rsp, 16
	; get actors current sprite frame
		xor rax, rax
		mov al, byte ptr [rcx+5]
		mov cl, al
		and al, 7 ; al: state index
		shr cl, 6 ; cl: state
	; write final sprite_x (->rdi)
		xor rdx, rdx
		mov rsi, dword ptr [r13+18h]
		mul rsi
		add rax, r8
		mov rdi, rax
	; write final sprite_x (->rax)
		xor rdx, rdx
		xor rax, rax
		mov al, cl
		mov rsi, dword ptr [r13+18h]
		mul rsi
		add rax, r10
	; draw
		push 0AACC0020h ; copy src foreground, maintain dst background ; copy op (00CC0020h)
		
		push rax ; mask y
		push rdi ; mask x
		;mov rdx, qword ptr [r13+8] ; + maskmap 
		;push rdx ; mask hdc src
		push qword ptr [r13+8] ; mask hdc src

		push rax ; src y
		push rdi ; src x
		;mov rcx, qword ptr [r13+10h] ; + bitmap hdmem
		;push rcx ; hdc src
		push qword ptr [r13+10h] ; hdc src

		push r11 ; height
		;mov r9, r9 ; width (redundant mov)
		mov r8, r14 ; y
		mov rdx, r15 ; x
		mov rcx, r12 ; hdc
		sub rsp, 20h
		call MaskBlt
		add rsp, 60h
	skip_draw:
		pop r15
		pop r14
		pop r13
		ret
DrawActorSprite ENDP

; rcx: sprite_ptr
ReleaseSpriteHDC PROC
	; config locals
		push r12
		sub rsp, 20h
		mov r12, rcx
	; make cleanup call
		mov rcx, qword ptr [r12+10h]
		call DeleteDC
		mov qword ptr [r12+10h], 0
	; return
		add rsp, 20h
		pop r12
		ret
ReleaseSpriteHDC ENDP
END