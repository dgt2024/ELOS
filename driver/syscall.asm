kernelABIStart:
	; INT 0x30 Update Page 0x30
	mov dword[0x982], 0xae000008
	mov word[0x980], kernelABIUpdatePage
	; INT 0x31 Update IDT 0x31
	mov dword[0x98a], 0xae000008
	mov word[0x988], kernelABIUpdateIDT
	; INT 0x32 Update CR3 0x31
	mov dword[0x992], 0xae000008
	mov word[0x990], kernelABIUpdateCR3
	; INT 0x33 Driver Functions
	mov dword[0x99a], 0xae000019
	mov word[0x998], kernelABIDriver
	ret

kernelABIUpdatePage:
	mov byte[0x200032], 0x30 ; last syscall #
	mov byte[0x200033], 0 ; last syscall function
	inc word[0x200036]
	
	invlpg [edx]
	iretd

kernelABIUpdateIDT:
	mov byte[0x200032], 0x31 ; last syscall #
	mov byte[0x200033], 0 ; last syscall function
	inc word[0x200036]
	
	lidt [idtTable]
	iretd

kernelABIUpdateCR3:
	mov byte[0x200032], 0x32 ; last syscall #
	mov byte[0x200033], 0 ; last syscall function
	inc word[0x200036]
	
	push eax
	mov eax, cr3
	mov cr3, eax
	pop eax
	
	iretd

kernelABIDriver:
	mov byte[0x200032], 0x33 ; last syscall #
	mov byte[0x200033], dh ; last syscall function
	inc word[0x200036] ; syscall count

	movzx edx, dh
	call dword[kernelABIDriver_lookup+edx*4]

	iretd

kernelABISkip:
	cli
	jmp $

kernelABIDriver_lookup:
	dd pageAllocate
	dd pageFree
	dd registerContainer
	dd getRawContainer
	dd deleteContainer
	dd createProcedure
	dd registerProcedure
	dd giveContainer
	dd mapContainer
	dd registerDriver
	dd mapDriver
	dd runDriver
	dd runDevice
	dd createDevice
	;
	dd mapPage1
	dd mapPage2
	dd endDriver