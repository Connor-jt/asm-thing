

CreateSolidBrush PROTO





.data

Color_HealthGreen equ 00FF00h
public Brush_HealthGreen
Brush_HealthGreen dword 0

Color_HealthBackground equ 102010h
public Brush_HealthBackground
Brush_HealthBackground dword 0


Color_ActorHoverGreen equ 18CF00h
public Brush_ActorHoverGreen
Brush_ActorHoverGreen dword 0

Color_ActorHover_Destination equ 03232deh
public Brush_ActorHover_Destination
Brush_ActorHover_Destination dword 0

Color_ActorHover_Step1 equ 0e4e4e4h
public Brush_ActorHover_Step1
Brush_ActorHover_Step1 dword 0

Color_ActorHover_Step2 equ 0b6b6b6h
public Brush_ActorHover_Step2
Brush_ActorHover_Step2 dword 0


Color_ActorSelected equ 00C0C0h
public Brush_ActorSelected
Brush_ActorSelected dword 0


.code 
LoadBrushes PROC
	sub rsp, 28h
	; health green
		mov rcx, Color_HealthGreen
		call CreateSolidBrush
		mov Brush_HealthGreen, eax
	; health background
		mov rcx, Color_HealthBackground
		call CreateSolidBrush
		mov Brush_HealthBackground, eax

	; unit hover green
		mov rcx, Color_ActorHoverGreen
		call CreateSolidBrush
		mov Brush_ActorHoverGreen, eax
	; unit hover destination
		mov rcx, Color_ActorHover_Destination
		call CreateSolidBrush
		mov Brush_ActorHover_Destination, eax
	; unit hover step1
		mov rcx, Color_ActorHover_Step1
		call CreateSolidBrush
		mov Brush_ActorHover_Step1, eax
	; unit hover step2
		mov rcx, Color_ActorHover_Step2
		call CreateSolidBrush
		mov Brush_ActorHover_Step2, eax

	; unit selected green
		mov rcx, Color_ActorSelected
		call CreateSolidBrush
		mov Brush_ActorSelected, eax
	add rsp, 28h
	ret
LoadBrushes ENDP
END