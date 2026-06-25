master.wait:
	mov ebp, dword[0x1a14]
	add ebp, ecx
master.wait_loop:
	cmp dword[0x1a14], ebp
	jae master.wait_end
	mov ah, 0x04
	int 0x30
	jmp master.wait_loop
master.wait_end:
	ret
master.poll:
	mov ah, 0x03
	int 0x30
	cmp ah, 0x00
	je master.pollskip
	mov ah, 0x04
	int 0x30
	jmp master.poll
master.pollskip:
	ret
master.recv:
	mov ah, 0x01
	int 0x30
	cmp ah, 0x00
	je master.recvskip
	mov ah, 0x04
	int 0x30
	jmp master.recv
master.recvskip:
	ret
master.error:
	mov eax, edi
	mov edi, 0x1501
	push eax
	mov al, byte[0x1500]
	movzx ebx, al
	inc al
	mov byte[0x1500], al
	pop eax
	shl ebx, 2
	add edi, ebx
	stosd
	ret
%include 'sysinit/sysinit.asm'
%include 'sysinit/01_/memory.asm'
%include 'sysinit/02_/pci/pci.asm'
%include 'sysinit/02_/pci/storage.asm'