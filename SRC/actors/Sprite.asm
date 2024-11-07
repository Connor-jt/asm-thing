
LoadImageW PROTO
CreateCompatibleDC PROTO
SelectObject PROTO
MaskBlt PROTO 
DeleteDC PROTO


.data?
dSoldierSprite db 28 dup(?) ; 0x0 bitmap ptr
							; 0x8 mask bitmap ptr
							; 0x10 bitmap hdc
							; 0x18 bitmap dimensions (1x4byte)
;

.code


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

