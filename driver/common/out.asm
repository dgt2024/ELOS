; Driver for terminal output
out_fdt:
	dd 0, 0, 0, out_ctrlFunc, 0, 0
	dd out_sendFunc, out_ctrlFunc
times 0x20 - ($ - out_fdt) db 0
	mov al, 0x00
	mov ebx, "OUT "
	mov dh, 15
	int 0x37
	ret

out_sendFunc:
	test edi, edi
	jz out_sendFunc_err

	test ecx, ecx
	jz out_sendFunc_err

	mov esi, edi
	mov edi, dword[out_cursor]

	cld
out_sendFunc_loop:
	lodsb

	cmp al, 0x08
	je out_sendFunc_backspace

	cmp al, 0x09
	je out_sendFunc_tab

	cmp al, 0x0a
	je out_sendFunc_newline

	cmp al, 0
	je out_sendFunc_end

	stosb

	mov al, byte[out_byteConfig]
	stosb
	loop out_sendFunc_loop

	mov dword[out_cursor], edi

	clc
	ret

out_sendFunc_tab:
	; todo: fix this
	add dword[out_cursor], 2
	loop out_sendFunc_loop
	clc
	ret

out_sendFunc_backspace:
	cmp dword[out_cursor], 0xb8f00
	je out_sendFunc_backspaceSkip

	sub dword[out_cursor], 2
	mov edi, dword[out_cursor]
	mov word[edi], 0x0000	

out_sendFunc_backspaceSkip:
	loop out_sendFunc_loop
	clc
	ret

out_sendFunc_newline:
	mov dword[out_cursor], 0xb8f00

	push ecx
	push esi
	mov edi, 0xb8000
	mov esi, 0xb80a0
	mov ecx, 0xfa0
	rep movsb ; move screen up
	pop esi
	pop ecx

	mov edi, 0xb8f00

	loop out_sendFunc_loop
	clc
	ret

out_sendFunc_end:
	clc
	ret

out_sendFunc_err:
	stc
	ret

out_cursor:
	dd 0xb8f00

out_ctrlFunc:
	mov byte[out_byteConfig], cl
	ret

out_byteConfig:
	db 0x0f