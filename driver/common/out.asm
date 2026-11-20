; Driver for terminal output
out_fdt:
	db "Terminal"
times 0x20 - ($ - $$) db 0
	xor eax, eax
	mov dword[out_fdt], eax
	mov dword[out_fdt+0x4], eax
	mov dword[out_fdt+0x8], eax
	mov dword[out_fdt+0xc], eax
	mov dword[out_fdt+0x10], eax
	mov dword[out_fdt+0x14], eax
	mov dword[out_fdt+0x18], out_sendFunc
	mov dword[out_fdt+0x1c], out_ctrlFunc

	mov al, 0x00
	mov ebx, "OUT "
	mov dh, 12
	int 0x30
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
	stosb

	mov al, byte[out_byteConfig]
	stosb
	loop out_sendFunc_loop

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