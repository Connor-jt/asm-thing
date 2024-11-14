.data
; see https://learn.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes

dKeyMap db 256 dup(0)

dMouseX dw 0
dMouseY dw 0

public dKeyMap
public dMouseX
public dMouseY

END