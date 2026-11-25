ps2_fdt:
	dd 0, 0, 0, ps2_miscFunc, 0, 0, 0, 0
times 0x20 - ($ - ps2_fdt) db 0
	mov al, 0xad ; reset controller 1
	out 0x64, al

	mov al, 0xa7 ; same for ctrl 2
	out 0x64, al

	in al, 0x60 ; discard input

	mov al, 0x20 ; read config cmd
	out 0x64, al

	and al, 0xae ; clear 0, 4, 6
	mov ah, al

	mov al, 0x60 ; write config cmd
	out 0x64, al

	mov al, ah
	out 0x64, al ; write it

	mov al, 0xaa
	out 0x64, al ; self-test
	in al, 0x60

	cmp al, 0x55
	jne ps2_error

	mov al, 0xa8 ; enable 2nd ctrl
	out 0x64, al

	mov al, 0x20 ; ctrl byte
	out 0x64, al
	in al, 0x60

	test al, 0x20 ; is 2nd ctrl on?
	jz ps2_secondCtrl

	and al, 0xdd
	mov ah, al

	mov al, 0xa7 ; disable it
	out 0x64, al

	mov al, 0x60
	out 0x64, al

	mov al, ah
	out 0x60, al

	mov al, 0xa9
	out 0x64, al
	in al, 0x60

	cmp al, 0x00
	jne ps2_error

	mov al, 0xa8
	out 0x64, al
	in al, 0x60

	mov al, 0x20
	out 0x64, al
	in al, 0x60

	or al, 0x02
	mov ah, al

	mov al, 0x60
	out 0x64, al

	mov al, ah
	out 0x60, al

ps2_secondCtrl:

	mov al, 0xab
	out 0x64, al
	in al, 0x60

	cmp al, 0x00
	jne ps2_error

	mov al, 0xae
	out 0x64, al

	mov al, 0x20
	out 0x64, al
	in al, 0x60

	or al, 0x01
	mov ah, al

	mov al, 0x60
	out 0x64, al

	mov al, ah
	out 0x60, al

	mov edi, ps2_initStr
	mov ecx, ps2_initStr_end - ps2_initStr
	mov ax, 0 ; log
	mov dh, 13
	mov bl, 6
	int 0x34

	mov al, 0x00
	mov ebx, "PS2 "
	mov dh, 15
	int 0x34

	mov bx, dx

	mov al, 0x21
	push ebx

	mov dh, 19
	int 0x34

	pop ebx

	mov al, 0x2c
	mov dh, 19
	int 0x34
	ret

ps2_error:
	mov dh, 11
	int 0x34

	stc
	ret

ps2_miscFunc:
	cli
	jmp $

ps2_initStr:
	db "Initializing PS2...", 10
ps2_initStr_end: