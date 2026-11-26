pit_fdt:
	dd 0, 0, 0, 0, 0, 0, 0, 0
times 0x20 - ($ - pit_fdt) db 0
	; set up channel 0 to yield
	mov dword[0x902], 0xae000008
	mov word[0x900], yieldScheduler
	int 0x31

	mov al, 0x34
	out 0x43, al
	mov al, 0xa9
	out 0x40, al
	mov al, 0x04
	out 0x40, al

	mov edi, pit_initStr
	mov ecx, pit_initStr_end - pit_initStr
	mov ax, 0 ; log
	mov dh, 13
	mov bl, 6
	int 0x36
	
	mov dh, 11
	int 0x36
	ret

pit_initStr:
	db "Initializing PIT...", 10
pit_initStr_end: