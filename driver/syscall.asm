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
	; INT 0x34 Set state down
	mov dword[0x9a2], 0xae000008
	mov word[0x9a0], kernelABIDown
	; INT 0x35 Return from ISR
	mov dword[0x9aa], 0xae000008
	mov word[0x9a8], IRQCall_return
	; INT 0x36 Driver ABI
	mov dword[0x9b2], 0xae000008
	mov word[0x9b0], kernelABIDriver
	; INT 0x37 Priviledged ABI
	mov dword[0x9ba], 0xae000008
	mov word[0x9b8], kernelABIPriviledge
	; TSS setup
	mov word[0x504], 0x7800
	mov word[0x508], 0x10
	mov word[0x50c], 0x7400
	mov word[0x510], 0x21
	mov word[0x560], 0x1300
	mov word[0x3ff8], 0x0003
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

kernelABIDown:
	cmp byte[esp+3], 0x80
	jae kernelABIDown_skip

	mov byte[0x200032], 0x34 ; last syscall #
	mov byte[0x200033], dh ; last syscall function
	inc word[0x200036] ; syscall count

	and byte[0x200030], 0xfd ; set down
	jmp yieldScheduler

kernelABIDown_skip:
	iretd

kernelABIDriver:
	cmp byte[esp+3], 0x80
	jae kernelABIDriver_cont

	cmp byte[esp+3], 0x40
	jb kernelABIDriver_cont
	iretd

kernelABIDriver_cont:
	mov byte[0x200032], 0x36 ; last syscall #
	mov byte[0x200033], dh ; last syscall function
	inc word[0x200036] ; syscall count

	movzx edx, dh
	call dword[kernelABIDriver_lookup+edx*4]
	pushfd
	pop dword[esp+8]
	iretd

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
	dd readNotification

kernelABIPriviledge:
	mov byte[0x200032], 0x37 ; last syscall #
	mov byte[0x200033], dh ; last syscall function
	inc word[0x200036] ; syscall count

	movzx edx, dh
	call dword[kernelABIPriviledge_lookup+edx*4]
	pushfd
	pop dword[esp+8]
	iretd

kernelABIPriviledge_lookup:
	dd loadDriver
	dd runDevice
	dd searchDevice
	dd getRawAddress
	dd userAllocate
	dd readNotification

userAllocate:
	call pageAllocate

	mov edi, edx
	mov ax, 0x0007
	mov bx, word[0x612]
	call registerContainer

	mov ax, dx
	push eax
	mov bx, word[0x612]
	call giveContainer
	pop eax

	mov bx, word[0x612]
	call mapContainer
	ret