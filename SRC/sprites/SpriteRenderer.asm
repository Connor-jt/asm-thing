
LoadImageW PROTO
CreateCompatibleDC PROTO
SelectObject PROTO
MaskBlt PROTO 
BitBlt PROTO 

extern dWinX : dword
extern dWinY : dword

extern dCameraX : dword
extern dCameraY : dword


.code 



; r9: bitmap object ptr
; r8d: bitmap size (x & y will be the same)
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
		mov dword ptr[r9+18h], r8d
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
	; load maskmap (if we declared one)
		cmp r13, 0
		je c05
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
		c05:
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



; r9d: Y
; r8d: X
; rdx: sprite ptr
; rcx: hdc
DrawSpriteOpaque PROC
	; config local variables
		push r12 ; hdc
		push r13 ; sprite ptr
		push r14 ; X
		push r15 ; Y
		sub rsp, 8
		mov r12, rcx
		mov r13,  rdx
		mov r14d, r8d
		mov r15d, r9d
	; load sprite HDC 
		call SetSpriteDevice
	; translate pos to local screen pos
		sub r14d, dCameraX
		sub r15d, dCameraY
	; config bitblt params
		sub rsp, 8
		push 00CC0020h ; raster code (copy src to dst)
		push 0 ; src y
		push 0 ; src x
		push qword ptr [r13+10h] ; hdc src
		mov r9d, dword ptr [r13+18h] ; width
		push r9 ; height
		mov r8d, r15d ; y
		mov edx, r14d ; x
		mov rcx, r12 ; hdc
		sub rsp, 20h
		call BitBlt
		add rsp, 58h ; including the sub rsp 8 at the top
	; return
		pop r15 
		pop r14 
		pop r13 
		pop r12 
		ret
DrawSpriteOpaque ENDP

; r11d: src_offs_y
; r10d: src_offs_x
; r9d: Y
; r8d: X
; rdx: sprite ptr
; rcx: hdc
DrawSpriteMasked PROC
	; config local variables
		push r12 ; hdc
		push r13 ; sprite ptr
		push r14 ; X
		push r15 ; Y
		sub rsp, 8
		mov r12, rcx
		mov r13,  rdx
		mov r14d, r8d
		mov r15d, r9d
	; preconfig maskblt params
		push 0AACC0020h ; copy src foreground, maintain dst background ; copy op (00CC0020h)
		push r11 ; mask y
		push r10 ; mask x
		push qword ptr [r13+8] ; mask hdc src
		push r11 ; src y
		push r10 ; src x
		push qword ptr [r13+10h] ; hdc src
	; load sprite HDC 
		call SetSpriteDevice
	; translate pos to local screen pos
		sub r14d, dCameraX
		sub r15d, dCameraY
	; draw
		mov r9d, dword ptr [r13+18h] ; width
		push r9 ; height
		mov r8d, r15d ; y
		mov edx, r14d ; x
		mov rcx, r12 ; hdc
		sub rsp, 20h
		call MaskBlt
		add rsp, 68h ; including the sub rsp 8 at the top
	; return
		pop r15 
		pop r14 
		pop r13 
		pop r12 
		ret
DrawSpriteMasked ENDP




END