kernelPageAllocate:
	; bit
	; EDX=bitask
	xor edx, edx
	and al, 0x0f
	movzx ecx, al
	inc ecx
	
kernelPageAllocate_search:
	push edx
	push ecx
	
	; Test for SIZE+1 pages
kernelPageAllocate_bitloop:
	bt dword[0x10000], edx
	jc kernelPageAllocate_skip
	loop kernelPageAllocate_bitloop

	pop ecx
	pop edx
	jmp kernelPageAllocate_succeed
	
kernelPageAllocate_skip:
	pop ecx
	pop edx
	
	inc edx
	cmp edx, 0x100000
	jae kernelPageAllocate_error
	jmp kernelPageAllocate_search
	
kernelPageAllocate_succeed:
	; Calculate physical address of page
	shl edx, 12
	add edx, 0x100000
	mov al, 0 ; Success
	ret
	
kernelPageAllocate_error:
	mov al, 1 ; Error
	ret

initializeMemory:
	mov ecx, 0x10000
	mov edi, 0x10000
	mov al, 0xff
	rep stosb
	
	movzx ecx, byte[0x60c]
	mov edi, 0x60000
	
initializeMemory_loop:
	push ecx
	
	mov eax, dword[edi] ; offset ram_block.start
	shr eax, 12
	sub eax, 0x200
	
	mov ecx, dword[edi+8] ; offset ram_block.size
	dec ecx
	shr ecx, 12
	inc ecx
	
	; Check start+size < 0x80000000
	lea ebx, [eax+ecx]
	cmp ebx, 0x80000000
	jbe initializeMemory_under2g
	mov ecx, eax
	neg ecx
	add ecx, 0x80000000
initializeMemory_under2g:
	
initializeMemory_bitloop:
	btr dword[0x10000], eax
	inc eax
	loop initializeMemory_bitloop
	
	pop ecx
	loop initializeMemory_loop
	
	mov ecx, 0x80000
	mov edi, 0x20000
	mov al, 0
	rep stosb
	ret
