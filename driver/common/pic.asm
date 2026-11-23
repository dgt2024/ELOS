; Driver for terminal output
pic_fdt:
	dd 0, 0, 0, 0, 0, 0, 0, 0
times 0x20 - ($ - pic_fdt) db 0
	mov al, 0x11
	out 0x20, al
	out 0xa0, al
	mov al, 0x20
	out 0x21, al
	mov al, 0x28
	out 0xa1, al
	mov al, 0x04
	out 0x21, al
	mov al, 0x02
	out 0xa1, al
	mov al, 0x01
	out 0x21, al
	out 0xa1, al
	mov al, 0x00
	out 0x21, al
	out 0xa1, al

	; print string2 on COM1
	mov edi, pic_initStr
	mov ecx, pic_initStr_end - pic_initStr
	mov ax, 1 ; linux' /dev/ttyS0
	mov dh, 12
	mov bl, 6
	int 0x33
	
	mov dh, 16
	int 0x33
	ret

pic_initStr:
	db "Initializing PIC...", 10
pic_initStr_end: