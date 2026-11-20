kernelDriver:
	mov byte[0x200032], 0x30 ; last syscall #
	mov byte[0x200033], dh ; last syscall function

	movzx edx, dh
	call dword[kernelDriver_lookup+edx*4]
kernelDriver_noprvldge:
	iretd

kernelDriver_lookup:
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
	; dh=10
	dd mapPage1
	dd mapPage2