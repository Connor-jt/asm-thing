
DeleteDC PROTO



SIZEOF_Sprite EQU 28
SIZEOF_SpriteBuffer EQU 28 ; SIZEOF_Sprite * 1 sprite

.data
soldier_sprite_path word 'r','e','s','/','a','c','t','o','r','s','/','s','o','l','d','i','e','r','.','b','m','p',0
soldier_mask_path word 'r','e','s','/','a','c','t','o','r','s','/','s','o','l','d','i','e','r','_','m','a','s','k','.','b','m','p',0

; MAX: 256 types!!!!
ActorSpriteBuffer byte SIZEOF_SpriteBuffer dup(0)	
; 0x0 bitmap ptr
; 0x8 mask bitmap ptr
; 0x10 bitmap hdc
; 0x18 bitmap dimensions (1x4byte)



.code


LoadActorSpriteLibrary PROC
	sub rsp, 8
	; load soldier actor
		lea r9, ActorSpriteBuffer
		mov r8, 32
		lea rdx, soldier_mask_path
		lea rcx, soldier_sprite_path
		call LoadSprite
	; return
		add rsp, 8
		ret
LoadActorSpriteLibrary ENDP

; rcx: actor ptr
; [return] rax: sprite ptr
GetActorSprite PROC
	movzx eax, byte ptr [rcx] 
	mov rcx, SIZEOF_Sprite
	mul rcx
	lea rcx, ActorSpriteBuffer
	add rax, rcx
	ret
GetActorSprite ENDP

; r12: actor ptr (paas through)
; rcx: hdc
DrawActorSprite PROC
	; config locals
		push r13
		mov r13, rcx
	; get actor type sprite address
		mov rcx, r12
		call GetActorSprite
		mov rdi, rax
		mov esi, dword ptr [rax+18h]
	; get actors current sprite frame
		movzx eax, byte ptr [r12+4]
		mov ecx, eax
		shr eax, 3
		and eax, 7 ; eax: state index
		shr ecx, 6 ; ecx: state
	; get x offset
		mul esi
		mov r10d, eax
	; get y offset
		mov eax, ecx
		mul esi
		mov r11d, eax
	; get actor position
		mov rcx, r12
		call GetActorWorldPos
		mov r8d, eax ; X
		mov r9d, edx ; Y
	; calc actor half width
		shr esi, 1
		sub r8d, esi
		sub r9d, esi

	; run draw func
		mov rdx, rdi
		mov rcx, r13 ; restore hdc value
		call DrawSpriteMasked
	; return
		pop r13
		ret
DrawActorSprite ENDP

; rcx: sprite_ptr
ReleaseActorSpriteHDCs PROC
	; config locals
		push r12 ; curr offset
		push r13 ; final offset
		sub rsp, 28h
		lea r12, ActorSpriteBuffer 
		mov r13, r12
		add r13, SIZEOF_SpriteBuffer
	lloop:
		; break if we reached the last valid index
			cmp r12, r13
			je return
		; if hdc ptr is not null, release it
			mov rcx, qword ptr [r12+10h]
			cmp rcx, 0
			je b8
				call DeleteDC
				mov qword ptr [r12+10h], 0
			b8:
		; next iteration
			add r12, SIZEOF_Sprite ; inc offset
			jmp lloop
	return:
		add rsp, 28h
		pop r13
		pop r12
		ret
ReleaseActorSpriteHDCs ENDP

END