startScheduler:
	mov ecx, 0x8000
	mov edi, 0x10000
startScheduler_loop:
	xor eax, eax

	repe scasw

	je startScheduler

	mov ax, word[edi-2] ; get procedure PDHNDL
	call getRawContainer

	and dx, 0xf000
	push edx
	or dx, 0x0003
	mov dword[0x4000], edx
	pop edx

	invlpg[0x200000]

	test byte[0x200030], 0x02
	jz startScheduler_afterYield

	cli
	mov ax, word[edi-2]
	mov word[0x612], ax
	mov word[0x610], cx

	add dx, 0x60
	mov cr3, edx ; Set CR3

	; Set up stack call (iretd at 0x580)
	mov eax, dword[0x20000c]
	mov dword[0x57c], eax ; ESP
	mov eax, dword[0x200020]
	mov dword[0x570], eax ; EIP
	mov eax, dword[0x200024]
	mov dword[0x578], eax ; EFLAGS

	mov ax, 0x33
	mov word[0x580], 0x33
	mov word[0x574], 0x2b

	test byte[0x200030], 0x80
	jz startScheduler_ring1

	mov ax, 0x21
	mov word[0x580], 0x21
	mov word[0x574], 0x19

startScheduler_ring1:
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax

	mov esp, 0x200000
	popad

	mov esp, 0x570
	iretd

startScheduler_afterYield:
	dec ecx
	test ecx, ecx
	jz startScheduler
	jmp startScheduler_loop

yieldScheduler:
	cli
	push eax
	mov al, 0x20
	out 0x20, al
	mov ax, 0x10
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	pop eax

	cmp word[0x610], 0
	je yieldScheduler_skip

	push eax
	mov eax, dword[esp+4]
	mov dword[0x200020], eax ; EIP

	mov eax, dword[esp+12]
	mov dword[0x200024], eax ; EFLAGS

	mov eax, dword[esp+16]
	mov dword[0x20000c], eax ; ESP
	pop eax

	mov esp, 0x200020
	pushad

	inc dword[0x20003c]

	movzx ecx, word[0x610]
	mov word[0x610], 0
	sti

	lea edi, [ecx-0x7fff]
	dec ecx
	neg edi
	lea edi, [0x10002+edi*2]
	jmp startScheduler_afterYield

yieldScheduler_skip:
	iretd