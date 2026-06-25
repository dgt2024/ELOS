; byte 0x5c900 Storage Devices
; 0x5c901-0x29301 Storage device array
; word: type | index in table
; byte 0x5cc00 IDE Storage Device Count TYPE=0x01
; 0x5cc01-0x2a801 IDE Storage Devices
; 0x2a900-0x2ab00 IDE identify buffer
; Prog IF bit 4 is LBA support
; Data Channel 1 WORD
; Ctrl Channel 1 WORD
; Data Channel 2 WORD
; Ctrl Channel 2 WORD
; DMA Port (if 0, disabled) WORD
; PCI Device ID
; Size
; flag
pci_storage.main:
	cmp al, 0x01
	je pci_storage.ide
	mov edi, 0x00000002
	call master.error
	ret
pci_storage.ide:
	push eax
	mov al, byte[0x5cc00]
	movzx eax, al
	imul eax, 20
	mov edi, 0x5cc01
	add edi, eax
	pop eax
	rol eax, 8
	stosb
	push edi
	test al, 0x1
	jnz pci_storage.ide_channel1_native
	mov word[edi], 0x1f0
	mov word[edi+2], 0x3f6
	add edi, 4
pci_storage.ide_channel1_return:
	test al, 0x4
	jnz pci_storage.ide_channel2_native
	mov word[edi], 0x170
	mov word[edi+2], 0x376
	add edi, 4
pci_storage.ide_channel2_return:
	test al, 0x80
	jz pci_storage.ide_no_dma
	mov eax, ebx
	add eax, 0x20
	call sysinit_pci.pciport
	and eax, 0xfffc
	stosw
pci_storage.ide_no_dma:
	pop edi
	; Disable Interrupts
	mov dx, word[edi+2]
	mov al, 2
	add dx, 2
	out dx, al
	mov dx, word[edi+6]
	add dx, 2
	out dx, al
	; Detect ATA/PATA devices
	push ebx
	xor bx, bx
pci_storage.ide_detect:
	push ebx
	movzx ebx, bl
	mov dx, word[edi+ebx]
	pop ebx
	add dx, 6
	mov al, 0xa0
	or al, bh
	out dx, al
	mov ecx, 1
	call master.wait
	inc dx
	mov al, 0xec
	out dx, al
	mov ecx, 1
	call master.wait
pci_storage.ide_poll:
	in al, dx
	cmp al, 0
	je pci_storage.no_dev
	in al, dx
	test al, 0x01
	jnz pci_storage.not_ata
	test al, 0x80
	jnz pci_storage.ide_poll
	test al, 0x08
	jz pci_storage.ide_poll
pci_storage.identify_ide:
	sub dx, 7
	mov ecx, 128
	mov dword[esp+0x8], edi
	pushad
	mov edi, 0x00000200
	mov bx, 2
	call master.recv
	int 0x30

	rep insd
	popad
	mov eax, dword[ebp+0xa4]
	test eax, 0x4000000
	jnz pci_storage.ide_lba48
	test eax, 0x200
	jnz pci_storage.ide_lba_enabled
pci_storage.ide_lba_return:
	mov eax, dword[ebp+0x78]
pci_storage.ide_after_size:
	cmp bx, 0
	jne pci_storage.ide_stored
	mov cl, byte[0x5cc00]
	inc byte[0x5cc00]
	xchg dword[esp], ebx
	mov dword[edi+10], ebx
	xchg dword[esp], ebx
	mov dword[edi+14], eax
	mov word[edi+18], 0
pci_storage.ide_stored:
	cmp bl, 0x10
	je pci_storage.ide_channel1
	add bh, 4
	shl bh, 2
	or byte[edi+18], bh
	shr bh, 2
	sub bh, 4
pci_storage.ide_channel_return:
	mov dl, byte[0x5c900]
	inc byte[0x5c900]
	movzx edx, dl
	push edi
	mov edi, 0x5c901
	shl edx, 1
	add edi, edx
	mov byte[edi], 0x01
	mov byte[edi+1], cl
	pop edi
pci_storage.no_dev:
	add bl, 4
	cmp bl, 8
	jne pci_storage.ide_detect
	mov bl, 0
	add bh, 0x10
	cmp bh, 0x20
	jne pci_storage.ide_detect
	pop ebx
	ret
pci_storage.ide_channel1:
	or byte[edi+18], bh
	jmp pci_storage.ide_channel_return
pci_storage.ide_lba48:
	or byte[edi-1], 0x10
	mov eax, dword[ebp+0xc8]
	jmp pci_storage.ide_after_size
pci_storage.ide_lba_enabled:
	or byte[edi-1], 0x10
	jmp pci_storage.ide_lba_return
pci_storage.not_ata:
	sub dx, 3
	in al, dx
	mov ah, al
	inc dx
	in al, dx
	cmp ax, 0xeb14
	je pci_storage.atapi
	cmp ax, 0x6996
	je pci_storage.atapi
	jmp pci_storage.no_dev
pci_storage.atapi:
	add dx, 2
	mov al, 0xa1
	out dx, al
	jmp pci_storage.ide_detect
pci_storage.ide_channel2_native:
	mov eax, ebx
	add eax, 0x18
	call sysinit_pci.pciport
	and eax, 0xfffc
	stosw
	mov eax, ebx
	add eax, 0x1c
	call sysinit_pci.pciport
	and eax, 0xfffc
	add ax, 2
	stosw
	jmp pci_storage.ide_channel2_return
pci_storage.ide_channel1_native:
	mov eax, ebx
	and eax, 0x10
	call sysinit_pci.pciport
	and eax, 0xfffc
	stosw
	mov eax, ebx
	add eax, 0x14
	call sysinit_pci.pciport
	and eax, 0xfffc
	add ax, 2
	stosw
	jmp pci_storage.ide_channel1_return