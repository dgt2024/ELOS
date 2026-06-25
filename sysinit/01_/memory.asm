sysinit_memory.main:
	; EDI=(0x80 FREE 0x00 MALLOC)|(0x80 STACK 0x00 MEM)|MEM(amount)|STACK(bl)
	mov word[0x1a68], 1
	mov byte[0x10000], 0
	mov dword[0x10001], 0x100000
	mov eax, dword[0x1a18]
	sub eax, 0x100000
	shr eax, 3
	cmp eax, 0
	mov word[0x10005], ax
	shr eax, 16
	mov byte[0x10007], al
	mov ah, 0x00
	mov bx, 1
	int 0x30
sysinit_memory.poll:
	call master.poll
	push ebx
	mov edx, edi
	shr edx, 24
	cmp edx, 0x80
	je sysinit_memory.free
	jmp sysinit_memory.malloc_ex
sysinit_memory.send:
	pop ebx
	call master.recv
	int 0x30
	jmp sysinit_memory.poll
sysinit_memory.free:
	movzx ecx, word[0x1a68]
	inc ecx
sysinit_memory.free_poll:
	lodsb
	dec ecx
	jecxz sysinit_memory.end
	add esi, 7
	cmp al, bl
	jne sysinit_memory.free_poll
	mov byte[esi], 0
	mov byte[esi+7], 0
	jmp sysinit_memory.free_poll
sysinit_memory.end:
	xor edi, edi
	jmp sysinit_memory.send
sysinit_memory.malloc_ex:
	mov ecx, edi
	shr ecx, 16
	cmp cl, 0x80
	jne sysinit_memory.malloc
	mov ecx, edi
	mov di, word[0x1a6e]
	mov bl, cl
sysinit_memory.malloc:
	; EDI=Count
	; BL=Owner
	movzx ecx, word[0x1a68]
	shr edi, 3
	mov esi, 0x10000
	inc ecx
sysinit_memory.find_clear:
	lodsb
	add esi, 7
	dec ecx
	jecxz sysinit_memory.none
	cmp al, 0
	jne sysinit_memory.find_clear
	sub esi, 3
	lodsd
	and eax, 0xffffff
	sub esi, 9
	push edi
	and edi, 0xffff
	cmp eax, edi
	pop edi
	jb sysinit_memory.not_enough
	je sysinit_memory.just_enough
	ja sysinit_memory.create
sysinit_memory.none:
	mov edi, 0x00000200
	call master.error
	mov edi, 0
	jmp sysinit_memory.send
sysinit_memory.not_enough:
	mov eax, edi
	shr eax, 16
	cmp al, 0x80
	je sysinit_memory.find_clear
	and edi, 0xffff
	mov byte[esi], bl
	push ebx
	mov ebx, edi
	shr ebx, 16
	mov byte[esi+7], bl
	pop ebx
	movzx eax, word[esi+5]
	sub edi, eax
	jmp sysinit_memory.find_clear
sysinit_memory.just_enough:
	and edi, 0xffff
	mov byte[esi], bl
	push ebx
	mov ebx, edi
	shr ebx, 16
	mov byte[esi+7], bl
	pop ebx
	mov edi, dword[esi+1]
	mov edi, dword[esi+1]
	jmp sysinit_memory.send
sysinit_memory.create:
	push eax
	sub eax, edi
	mov byte[esi], bl
	mov word[esi+5], di
	push ebx
	mov ebx, edi
	shr ebx, 16
	mov byte[esi+7], bl
	pop ebx
	dec ecx
	inc word[0x1a68]
	and edi, 0xffff
	push edi
	push esi
	std
	shl ecx, 3
	add esi, ecx
	mov edi, esi
	add edi, 8
	rep movsb
	cld
	pop esi
	pop edi
	pop eax
	mov edx, dword[esi+1]
	shl edi, 3
	add edx, edi
	sub eax, edi
	mov byte[esi+8], 0
	mov dword[esi+9], edx
	and eax, 0xffffff
	mov word[esi+13], ax
	shr eax, 16
	mov byte[esi+15], al
	mov edi, dword[esi+1]
	jmp sysinit_memory.send