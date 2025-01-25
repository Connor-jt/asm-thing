
DeleteDC PROTO
LoadSprite PROTO


SIZEOF_Sprite EQU 28
SIZEOF_SpriteBuffer EQU 84 ; SIZEOF_Sprite * 3 sprites

.data
dirt_sprite_path word 'r','e','s','/','t','e','r','r','a','i','n','/','d','i','r','t','.','b','m','p',0
stone_sprite_path word 'r','e','s','/','t','e','r','r','a','i','n','/','s','t','o','n','e','.','b','m','p',0
void_sprite_path word 'r','e','s','/','t','e','r','r','a','i','n','/','v','o','i','d','.','b','m','p',0


; MAX: 256 types!!!!
TerrainSpriteBuffer byte SIZEOF_SpriteBuffer dup(0)	
; 0x0 bitmap ptr
; 0x8 mask bitmap ptr
; 0x10 bitmap hdc
; 0x18 bitmap dimensions (1x4byte)


; terrain types
; 0: void - uninitialized
; 1: solid - generic solid rock
; 2: path - generic walkable path

.code


LoadTerrainSpriteLibrary PROC
	sub rsp, 8
	; load uninitialized void sprite
		lea r9, TerrainSpriteBuffer
		mov r8, 32
		xor rdx, rdx
		lea rcx, void_sprite_path
		call LoadSprite
	; load solid stone sprite
		lea r9, TerrainSpriteBuffer
		add r9, 28
		mov r8, 32
		xor rdx, rdx
		lea rcx, stone_sprite_path
		call LoadSprite
	; load dirt path sprite
		lea r9, TerrainSpriteBuffer
		add r9, 56
		mov r8, 32
		xor rdx, rdx
		lea rcx, dirt_sprite_path
		call LoadSprite
	; return
		add rsp, 8
		ret
LoadTerrainSpriteLibrary ENDP

; rax: terrain type (the highest byte of a terrain info, +7)
; [return] rax: sprite ptr
GetTerrainSprite PROC
	mov rsi, SIZEOF_Sprite
	mul rsi
	lea rsi, TerrainSpriteBuffer
	add rax, rsi
	ret
GetTerrainSprite ENDP

; r9d: Y (passes straight into draw func)
; r8d: X (passes straight into draw func)
; rax: terrain info
; rcx: hdc (passes straight into draw func)
DrawTerrainSprite PROC
	sub rsp, 8
	; get terrain type sprite address
		shr rax, 56
		call GetTerrainSprite
	; run draw func
		mov rdx, rax
		call DrawSpriteOpaque
	; return
		add rsp, 8
		ret
DrawTerrainSprite ENDP

; rcx: sprite_ptr
ReleaseTerrainSpriteHDCs PROC
	; config locals
		push r12 ; curr offset
		push r13 ; final offset
		sub rsp, 28h
		lea r12, TerrainSpriteBuffer 
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
ReleaseTerrainSpriteHDCs ENDP

END