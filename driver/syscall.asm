kernelABIStart:
	; INT 0x30 Update Page 0x30
	mov dword[0x982], 0xae000008
	mov word[0x980], kernelABIUpdate
	; INT 0x31 Driver Functions
	mov dword[0x98a], 0xae000019
	mov word[0x988], kernelABIDriver
	ret

kernelABIUpdate:
	invlpg [edx]
	iretd

kernelABIDriver:
	mov byte[0x200032], 0x30 ; last syscall #
	mov byte[0x200033], dh ; last syscall function

	movzx edx, dh
	call dword[kernelABIDriver_lookup+edx*4]
	iretd

kernelABIDriver_lookup:
	dd pageAllocate
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