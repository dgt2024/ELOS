startScheduler:
	mov ecx, 0x4000
	mov edi, 0x10000

startScheduler_loop:
	xor eax, eax

	repe scasw

	mov ax, word[edi-2] ; get procedure PDHNDL
	call getRawContainer

	and dx, 0xf000
	push edx
	or dx, 0x0003
	mov dword[0x4000], edx
	pop edx

	invlpg[0x200000]

	add dx, 0x60
	mov cr3, edx ; Set CR3

	mov esp, dword[0x200020]
	popad

	mov esp, dword[0x20000c]

	jmp dword[0x200020]
	loop startScheduler_loop
	jmp startScheduler