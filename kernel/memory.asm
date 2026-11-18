pageAllocate:
	; bit
	; EDX=bitask
	; clear page directory
	xor edx, edx
	and al, 0x0f
	movzx ecx, al
	inc ecx
	
pageAllocate_search:
	push edx
	push ecx
	
pageAllocate_bitloop:
	bt dword[0x100000], edx
	inc edx
	jc pageAllocate_skip
	loop pageAllocate_bitloop

	pop ecx
	mov edx, dword[esp]
	
pageAllocate_setloop:
	bts dword[0x100000], edx
	inc edx
	loop pageAllocate_setloop
	
	pop edx
	jmp pageAllocate_succeed
	
pageAllocate_skip:
	pop ecx
	pop edx
	
	inc edx
	cmp edx, 0x800000
	jae pageAllocate_error
	jmp pageAllocate_search
	
pageAllocate_succeed:
	; Calculate physical address of page
	shl edx, 12
	add edx, 0x200000
	clc ; Success
	ret
	
pageAllocate_error:
	stc ; Error
	ret

initializeMemory:
	mov ecx, 0x100000
	mov edi, 0x100000
	mov al, 0xff
	rep stosb

	movzx ecx, byte[0x60c]
	mov edi, 0x60000
	
initializeMemory_loop:
	push ecx
	
	mov eax, dword[edi] ; offset ram_block.start
	shr eax, 12
	sub eax, 0x100
	mov ebx, dword[edi+4]
	shl ebx, 20
	or eax, ebx
	
	mov ecx, dword[edi+8] ; offset ram_block.size
	dec ecx
	shr ecx, 12
	inc ecx
	mov ebx, dword[edi+12]
	shl ebx, 20
	or ecx, ebx

	; Check start+size < 0x800000000
	lea ebx, [eax+ecx]
	cmp ebx, 0x800000
	jbe initializeMemory_under32g

	; ecx = 0x80000000-eax
	mov ecx, eax
	neg ecx
	add ecx, 0x800000

initializeMemory_under32g:
	
initializeMemory_bitloop:
	btr dword[0x100000], eax
	inc eax
	loop initializeMemory_bitloop
	
	pop ecx
	loop initializeMemory_loop
	
	mov ecx, 0x80000
	mov edi, 0x20000
	mov al, 0
	rep stosb
	
	mov dword[0x608], 0 ; TID
	ret
