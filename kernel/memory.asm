kernelPageAllocate:
	; Find unused memory
	xor edx, edx
kernelPageAllocate_find:
	bts dword[0x20000], edx
	jnc kernelPageAllocate_succeed
	
	add edx, 2
	cmp edx, 0x200000
	jae kernelPageAllocate_error
	jmp kernelPageAllocate_find
	
kernelPageAllocate_succeed:
	; Calculate physical address of page
	shl edx, 11
	add edx, 0x100000
	mov al, 0 ; Success
	ret
	
kernelPageAllocate_error:
	mov al, 1 ; Error
	ret

initializeMemory:
	mov ecx, 0x40000
	mov edi, 0x20000
	mov al, 0xff
	rep stosb
	
	movzx ecx, byte[0x60c]
	mov edi, 0x60000
	
initializeMemory_loop:
	push ecx
	
	mov eax, dword[edi] ; offset ram_block.start
	shr eax, 11
	sub eax, 0x200
	
	mov ecx, dword[edi+8] ; offset ram_block.size
	shr ecx, 11
	inc ecx
	
initializeMemory_bitloop:
	btr dword[0x20000], eax
	inc eax
	loop initializeMemory_bitloop
	
	pop ecx
	loop initializeMemory_loop
	
	mov ecx, 0x40000
	mov edi, 0x60000
	mov al, 0
	rep stosb
	ret
