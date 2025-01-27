

; input externs
	extern dKeyMap : byte
	extern dHeldKeyMap : byte
	extern dMouseX : dword
	extern dMouseY : dword
; scene externs
	extern dCameraX : dword
	extern dCameraY : dword
; selected actors externs
	extern dSelectedActorsList : qword 
	extern dSelectedActorsCount : dword
; custom funcs externs
	ActorPtrFromHandle PROTO

.code

; give selected actors the move instruction
; iterate selected units
; calculate our positions (just generate a square around the location of the point)


; give selected actors the attack instruction
; acccess hovered unit

ActorInstructionsTick PROC	
	; if no selected units then return
		cmp dSelectedActorsCount, 0
		je return
	; check left mouse down
		lea rcx, dKeyMap
		mov al, byte ptr [rcx+1]
		test al, al
		jz return
	; check ctrl key down
		lea rcx, dHeldKeyMap
		mov al, byte ptr [rcx+11h]
		test al, al
		jz return
	; config locals
		push r13 ; item index
		xor r13, r13 
	; render borders around all selected actors
		lloop:
			; break if at the end of the array
				cmp r13d, dSelectedActorsCount
				je loop_end
			; fetch current actor ptr
				lea rcx, dSelectedActorsList
				mov ecx, dword ptr [rcx+r13*4]
				call ActorPtrFromHandle
			; if returned ptr is null, goto next iteration
				test rax, rax
				jz loop_next
			; set actor to moveto objective mode
				and byte ptr [rax+4], 249 ; clear objective bits
				or byte ptr [rax+4], 2 ; write move to objective
				and word ptr [rax+12], 1023 ; clear path direction bits
			; finally, assign the new destination
				mov edx, dMouseX
				add edx, dCameraX
				mov ecx, dMouseY
				add ecx, dCameraY
				shr ecx, 5
				shr edx, 5
				mov word ptr [rax+16], dx ; target x
				mov word ptr [rax+18], cx ; target y
			loop_next:
				inc r13d
				jmp lloop
		loop_end:
		pop r13

		
	; if mouse down is over a unit, then target that unit

	; else move to this position

	
	return:
		ret
ActorInstructionsTick ENDP

END