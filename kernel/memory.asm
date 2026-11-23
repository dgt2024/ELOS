pageAllocate:
	; bit
	; EDX=bitask
	; clear page directory
	xor edx, edx
	and al, 0x0f
	movzx ecx, al
	inc ecx

	push ecx ; save allocated mem
	shl ecx, 12
	add dword[0x60c], ecx
	pop ecx
	
pageAllocate_search:
	push edx
	push ecx
	
pageAllocate_bitloop:
	bt dword[0x1c0000], edx
	inc edx
	jc pageAllocate_skip
	loop pageAllocate_bitloop

	pop ecx
	mov edx, dword[esp]
	
pageAllocate_setloop:
	bts dword[0x1c0000], edx
	inc edx
	loop pageAllocate_setloop
	
	pop edx
	jmp pageAllocate_succeed
	
pageAllocate_skip:
	pop ecx
	pop edx
	
	inc edx
	cmp edx, 0x4000
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

pageFree:
	and al, 0x0f
	movzx ecx, al
	inc ecx

	push ecx ; save allocated mem
	shl ecx, 12
	sub dword[0x60c], ecx
	pop ecx

	sub ebx, 0x200000
	shr ebx, 12 ; calculate bit

pageFree_clrloop:
	bts dword[0x1c0000], ebx
	inc ebx
	loop pageFree_clrloop
	ret
		
initializeMemory:
	mov edi, 0x1c0000
	mov ecx, 0x20000
	mov al, 0xff
	rep stosb

	movzx ecx, byte[0x60c]
	mov edi, 0x60000
	
initializeMemory_loop:
	push ecx
	
	mov eax, dword[edi] ; offset ram_block.start
	shr eax, 12
	sub eax, 0x100
	
	mov ecx, dword[edi+8] ; offset ram_block.size
	dec ecx
	shr ecx, 12
	inc ecx

	; Check start+size < 0x100000000
	lea ebx, [eax+ecx]
	cmp ebx, 0x100000
	jbe initializeMemory_under32g

	; ecx = 0x10000000-eax
	mov ecx, eax
	neg ecx
	add ecx, 0x100000

initializeMemory_under32g:
	
initializeMemory_bitloop:
	btr dword[0x1c0000], eax
	inc eax
	loop initializeMemory_bitloop
	
	pop ecx
	loop initializeMemory_loop

	mov ecx, 0x80000
	mov edi, 0x20000
	mov al, 0
	rep stosb
	ret
