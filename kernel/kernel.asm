main:
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

	mov dword[0x608], 0 ; TID

	; Initialize kernel data pages
	mov dword[0x5e0], 0x5001
	mov dword[0x5f8], 0x6001
	mov dword[0x5000], 0x83
	mov dword[0x5008], 0x4003
	mov dword[0x5ff8], 0x3003
	; TSS setup
	mov dword[0x504], 0x7b00
	mov word[0x508], 0x10
	mov word[0x560], 0x1300
	mov dword[0x3ff8], 0x0003

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

	mov ecx, 0x80000
	mov edi, 0x20000
	mov al, 0
	rep stosb

	; Start PID=0
	mov edi, 0x9000
	mov ax, 0x0014
	mov bx, 0x0000
	call registerContainer ; CODE DATA
	mov ax, dx
	mov bl, 0xdf
	mov ecx, kprocName_end-kprocName
	mov esi, kprocName
	call createProcedure

	mov ax, 0x38
	ltr ax

	mov ecx, 0xc0000080 ; IA32_EFER
	rdmsr
	or ax, 0x800
	wrmsr
	
	; Run procedures
	jmp startScheduler
kprocName:
	db "kernelproc"
kprocName_end: