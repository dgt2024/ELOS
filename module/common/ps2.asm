ps2_fdt:
	dd 0, 0, 0, 0, 0, 0, 0, 0
times 0x20 - ($ - ps2_fdt) db 0
	mov edi, ps2_initStr
	mov ecx, ps2_initStr_end - ps2_initStr
	mov ax, 0 ; log
	mov dh, 13
	mov bl, 6
	int 0x34
	
	cli
	jmp $

ps2_initStr:
	db "Initializing PS2...", 10
ps2_initStr_end: