; Global Functions:
;	initializeMemory -> Initializes memory
;	kernelPageAllocate -> Allocates a page of memory EDX=ADDR,AL=STATUS
kernelPageAllocate:
	xor edx, edx
kernelPageAllocate_find:
	bts dword[0x10000], edx
	jnc kernelPageAllocate_succeed
	add edx, 2
	cmp edx, 10
	jmp kernelPageAllocate_find
kernelPageAllocate_succeed:
	shl edx, 11
	add edx, 0x100000
	mov al, 0
	ret
kernelPageAllocate_error:
	mov al, 1
	ret
initializeMemory:
	; Clear KABM
	mov ecx, 0x40000
	mov edi, 0x20000
	mov al, 0xff
	rep stosb
	; Initialize KABM
	movzx ecx, byte[0x604]
	mov edi, 0x60000
initializeMemory_loop:
	push ecx
	mov eax, dword[edi]
	shr eax, 11
	sub eax, 0x200
	mov ecx, dword[edi+8]
	shr ecx, 11
	inc ecx
initializeMemory_bitloop:
	btr dword[0x20000], eax
	inc eax
	loop initializeMemory_bitloop
	pop ecx
	loop initializeMemory_loop
	; Reset Object/PCB Array
	mov ecx, 0x80000
	mov edi, 0x20000
	mov al, 0
	rep stosb
	ret
