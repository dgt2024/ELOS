kernelABIStart:
	; INT 0x30 Update Page
	mov dword[0x982], 0xae000008
	mov word[0x980], kernelABIUpdatePage
	; INT 0x31 Update IDT
	mov dword[0x98a], 0xae000008
	mov word[0x988], kernelABIUpdateIDT
	; INT 0x32 Update CR3
	mov dword[0x992], 0xae000008
	mov word[0x990], kernelABIUpdateCR3
	; INT 0x33 Yield
	mov dword[0x99a], 0xae000008
	mov word[0x998], yieldScheduler
	; INT 0x34 Driver ABI
	mov dword[0x9a2], 0xae000019
	mov word[0x9a0], kernelABIDriver
	; INT 0x35 Ring 1 ABI

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
	dd endDriver
	dd runDevice
	dd searchDevice
	dd createDevice
	dd endDevice
	dd loadDriver
	dd getRawAddress
	dd registerInterrupt
	dd sendNotification
