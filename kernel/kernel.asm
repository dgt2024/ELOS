main:
	cli
	mov ax, 0x10
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax
	mov esp, 0x7c00

	mov edi, 0x5000
	mov ecx, 0x800
	xor eax, eax
	rep stosd

	lidt [idtTable]

	; driver syscall
	call kernelABIStart

	; Initialize kernel data pages
	mov word[0x5e0], 0x5001
	mov word[0x5f8], 0x6001
	mov word[0x5000], 0x83
	mov word[0x5008], 0x4003
	mov word[0x5ff8], 0x3001

	; Set up page directory
	mov eax, 0x5e0
	mov cr3, eax

	; Set CR4.PSE for larger pages and CR4.PAE
	mov eax, cr4
	or eax, 0x00000030
	mov cr4, eax
	
	; Start paging
	mov eax, cr0
	or eax, 0x80000000
	mov cr0, eax

	call initializeMemory

	; Start PID=0
	mov edi, 0x9000
	mov ax, 0x0004
	call registerContainer
	mov ax, dx
	mov bl, 0xdf
	mov ecx, kprocName_end-kprocName
	mov esi, kprocName
	call createProcedure

	mov ax, 0x38
	ltr ax

	; enable NX bit
	mov ecx, 0xc0000080 ; IA32_EFER
	rdmsr
	or ax, 0x800
	wrmsr
	
	; Run procedures
	jmp startScheduler

kprocName:
	db "kproc"
kprocName_end: