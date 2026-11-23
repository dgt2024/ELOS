; Driver for terminal output
out_fdt:
	dd 0, 0, 0, out_ctrlFunc, 0, 0
	dd out_sendFunc, 0
times 0x20 - ($ - out_fdt) db 0
	mov al, 0x00
	mov ebx, "OUT "
	mov dh, 13
	int 0x33
	ret

out_sendFunc:
	test edi, edi
	jz out_sendFunc_err

	test ecx, ecx
	jz out_sendFunc_err

	mov esi, edi
	mov edi, 0xb8000

	cld
out_sendFunc_loop:
	lodsb

	cmp al, 0x0a
	je out_sendFunc_newline

	stosb

	mov al, byte[out_byteConfig]
	stosb
	loop out_sendFunc_loop

	clc
	ret

out_sendFunc_newline:
	sub edi, 0xb8000

	xor edx, edx
	mov eax, edi
	mov ebx, 40

	div ebx

	sub edi, edx
	
	clc
	ret

out_sendFunc_err:
	stc
	ret

out_ctrlFunc:
	mov byte[out_byteConfig], cl
	ret

out_byteConfig:
	db 0x0f