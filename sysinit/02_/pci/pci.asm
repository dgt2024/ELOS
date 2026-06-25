; 0x54800 # PCI connections
; 0x54802-0x29002 PCI connections
sysinit_pci.main:
	mov edi, 0x54802
	mov esi, 0x54800
	mov eax, 0x80000000
	mov ecx, 0x1000
sysinit_pci.pciloop:
	push eax
	call sysinit_pci.pciport
	cmp ax, 0xffff
	je sysinit_pci.pciskip
	inc word[esi]
	stosd
	mov eax, dword[esp]
	stosd
	push ecx
	call sysinit_pci.pcicheck
	pop ecx
sysinit_pci.pciskip:
	pop eax
	add eax, 0x800
	loop sysinit_pci.pciloop
	lodsw
	movzx ecx, ax
sysinit_pci.pciloop2:
	add esi, 4
	lodsd
	mov ebx, eax
	add eax, 0x08
	call sysinit_pci.pciport
	rol eax, 16
	pushad
	call sysinit_pci.pcidriver
	popad
	loop sysinit_pci.pciloop2
	mov edi, 1
	mov bx, 1
	mov ah, 0x00
	int 0x30
	mov ah, 0x06
	int 0x30
sysinit_pci.pcicheck:
	push eax
	add eax, 0x0c
	call sysinit_pci.pciport
	shr eax, 16
	test al, 0x80
	jnz sysinit_pci.pcifunc
	pop eax
	ret
sysinit_pci.pcifunc:
	pop eax
	mov ecx, 4
	sub edi, 8
sysinit_pci.pcicheckloop:
	push eax
	call sysinit_pci.pciport
	cmp ax, 0xffff
	je sysinit_pci.pcicheckskip
	inc word[esi]
	stosd
	mov eax, dword[esp]
	stosd
sysinit_pci.pcicheckskip:
	pop eax
	add eax, 0x100
	loop sysinit_pci.pcicheckloop
	dec word[esi]
	ret
sysinit_pci.pciport:
	mov dx, 0xcf8
	out dx, eax
	mov dx, 0xcfc
	in eax, dx
	ret
sysinit_pci.pciwrite:
	mov dx, 0xcf8
	out dx, eax
	mov dx, 0xcfc
	mov eax, edi
	out dx, eax
	ret
sysinit_pci.pcidriver:
	cmp ah, 0x01
	je pci_storage.main
	mov edi, 0x00000001
	call master.error
	ret