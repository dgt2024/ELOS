; Driver for terminal output
pic_fdt:
	dd 0, 0, pic_readFunc, 0, 0, pic_writeFunc, 0, 0
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
	mov al, 0x00
	out 0x21, al
	out 0xa1, al

	; print string2 on COM1
	mov edi, pic_initStr
	mov ecx, pic_initStr_end - pic_initStr
	mov ax, 0 ; linux' /dev/ttyS0
	mov dh, 13
	mov bl, 6
	int 0x34

	mov al, 0x00
	mov ebx, "PIC "
	mov dh, 15
	int 0x34

	mov ax, dx
	mov word[0x700], ax
	ret

pic_readFunc:
	cli
	jmp $

pic_writeFunc:
	cli
	jmp $

pic_initStr:
	db "Initializing PIC...", 10
pic_initStr_end: