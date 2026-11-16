kernelPageAllocate:
	; Find unused memory
	xor edx, edx
kernelPageAllocate_find:
	bts dword[0x20000], edx ; Used?
	jnc kernelPageAllocate_succeed
	
	; Next page
	add edx, 2
	cmp edx, 0x200000 ; Overflow?
	jae kernelPageAllocate_error
	jmp kernelPageAllocate_find
	
	; On success
kernelPageAllocate_succeed:
	; Calculate physical pointer
	shl edx, 11
	add edx, 0x100000
	mov al, 0 ; Success
	ret
	
	; On error
kernelPageAllocate_error:
	mov al, 1 ; Error
	ret

initializeMemory:
	; Clear KABM
	mov ecx, 0x40000
	mov edi, 0x20000
	mov al, 0xff
	rep stosb
	
	; Initialize KABM
	movzx ecx, byte[0x60c] ; RAM block count
	mov edi, 0x60000 ; Block count start
	
	; Iterate
initializeMemory_loop:
	push ecx
	
	; Get start pointer page #
	mov eax, dword[edi]
	shr eax, 11
	sub eax, 0x200
	
	; Get size in pages
	mov ecx, dword[edi+8]
	shr ecx, 11
	inc ecx
	
	; Set bits as unused
initializeMemory_bitloop:
	btr dword[0x20000], eax
	inc eax
	loop initializeMemory_bitloop
	
	; Next RAM block
	pop ecx
	loop initializeMemory_loop
	
	; Reset Object array
	mov ecx, 0x40000
	mov edi, 0x60000
	mov al, 0
	rep stosb
	ret
