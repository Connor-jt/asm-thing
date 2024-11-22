
extern LoadSprite : proc ; sprite entry

extern dWinX : dd
extern dWinY : dd

.data
cSoldierSprite dw 's','d','.','b','m','p', 0
cSoldierSpriteMask dw 's','d','m','.','b','m','p', 0

.data?
dSoldierSprite db 28 dup(?)	; 0x0 bitmap ptr
							; 0x8 mask bitmap ptr
							; 0x10 bitmap hdc
							; 0x18 bitmap dimensions (1x4byte)
public dSoldierSprite
.code


LoadSpriteLibrary PROC
	; config locals
		push r12 ; just to align stack
	; load soldier
		mov rcx, OFFSET cSoldierSprite
		mov rdx, OFFSET cSoldierSpriteMask
		mov r8, 32
		mov r9, OFFSET dSoldierSprite
		call LoadSprite
	; return
		pop r12
		ret
LoadSpriteLibrary ENDP

; rcx: actor ptr
DrawActorSprite PROC
	push r13
	push r14
	push r15

	; rax : temp
	; rdx : temp
	; rsi : 

	; rcx : actor ptr
	; rdi : sprite ptr
	; r8 : left overlap
	; r9 : right overlap
	; r10 : top overlap
	; r11 : bot overlap

	; r12 :
	; r13 : pos X (adjusted)
	; r14 : pox Y (adjusted)
	; r15 : 

	; get actor type sprite address
		mov rax, dword ptr [rcx] 
		shr rax, 21 ; rshift the unit type
		xor rdx, rdx
		mov rdi, 28
		mul rdi
		lea rdi, dSoldierSprite
		add rdi, rax

	; calc actor width
		mov rax, dword ptr [rdi+18h]
		shr rax, 1
	; calc actor screen position
		mov r13, dword ptr [rcx+8] 
		mov r14, dword ptr [rcx+12]
		sub r13, rax ; x 
		sub r14, rax ; y
		; add in screen position !!!

	; validate whether sprite is on screen
		; horizontal
			xor r8, r8 ; left overlap
			xor r9, r9 ; right overlap
			; vaidate left side
				mov rax, r13 ; x pos
				; if x < 0
				cmp rax, 0
				jge block5
					add rax, dword ptr [rdi+18h] ; sprite size
					; if x + width < 0 :: sprite is not visible
					cmp rax, 0
					jl skip_draw
					; store overlap
					mov r8, rax
				block5:
			; validate right side
				mov rax, r13 ; x pos
				add rax, dword ptr [rdi+18h] ; sprite size
				; if x + width >= max_x
				cmp rax, dWinX
				jl block6
					mov rax, r13 ; x pos
					; if x >= max_x :: sprite is not visible
					cmp rax, dWinX
					jge skip_draw
					; store overlap
					mov r9, dWinX
					sub r9, rax
				block6:
		; vertical
			xor r10, r10 ; top overlap
			xor r11, r11 ; bottom overlap
			; vaidate left side
				mov rax, r14 ; y pos
				; if y < 0
				cmp rax, 0
				jge block7
					add rax, dword ptr [rdi+18h] ; sprite size
					; if y + width < 0 :: sprite is not visible
					cmp rax, 0
					jl skip_draw
					; store overlap
					mov r10, rax
				block7:
			; validate right side
				mov rax, r14 ; x pos
				add rax, dword ptr [rdi+18h] ; sprite size
				; if y + width >= max_y
				cmp rax, dWinX
				jl block8
					mov rax, r14 ; y pos
					; if y >= max_x :: sprite is not visible
					cmp rax, dWinY
					jge skip_draw
					; store overlap
					mov r11, dWinY
					sub r11, rax
				block8:


	; get actors current sprite frame
		mov al, byte ptr [rcx+5]
		mov cl, al
		and al, 7 ; al: state index
		shr cl, 6 ; cl: state


	
		
	; call draw
		
	skip_draw:
	; return
		pop r15
		pop r14
		pop r13
		ret
DrawActorSprite ENDP
END