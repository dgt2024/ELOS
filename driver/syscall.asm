kernelABIStart:
	; int 0x30 Return from ISR
	mov dword[0x982], 0xae000008
	mov word[0x980], IRQCall_return
	; int 0x40 Driver ABI
	mov dword[0xa02], 0xae000019
	mov word[0xa00], kernelABIDriver
	; int 0x41 Update Page
	mov dword[0xa0a], 0xae000008
	mov word[0xa08], kernelABIDriverR0
	; int 0x42 Priviledged ABI
	mov dword[0xa12], 0xae000019
	mov word[0xa10], kernelABIPriviledge
	; int 0x43 Priviledged ABI
	mov dword[0xa1a], 0xae000008
	mov word[0xa18], kernelABIPriviledgeR0
	; TSS setup
	mov word[0x504], 0x7800
	mov word[0x508], 0x10
	mov word[0x50c], 0x7400
	mov word[0x510], 0x21
	mov word[0x560], 0x1300
	mov word[0x3ff8], 0x0003
	ret

kernelABIDriver:
	inc dword[0x680]

	cmp byte[esp+3], 0x80
	jae kernelABIDriver_cont

	cmp byte[esp+3], 0x40
	jb kernelABIDriver_cont
	iretd

kernelABIDriver_cont:
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

kernelABIDriverR0:
	inc dword[0x680]

	cmp byte[esp+3], 0x80
	jae kernelABIDriverR0_cont

	cmp byte[esp+3], 0x40
	jb kernelABIDriverR0_cont
	iretd

kernelABIDriverR0_cont:
	movzx edx, dh
	call dword[kernelABIDriverR0_lookup+edx*4]
	iretd

kernelABIDriverR0_lookup:
	dd userUpdatePage
	dd userUpdateIDT
	dd userUpdateCR3

kernelABIPriviledge:
	inc dword[0x680]

	mov byte[0x200032], 0x42 ; last syscall #
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
	dd userCreateSingle
	dd readNotification
	dd userSendNotification
	dd userCreateShare
	dd userRequestShare
	dd userAnswerShare

kernelABIPriviledgeR0:
	inc dword[0x680]

	mov byte[0x200032], 0x43 ; last syscall #
	mov byte[0x200033], dh ; last syscall function
	inc word[0x200036] ; syscall count

	movzx edx, dh
	call dword[kernelABIPriviledgeR0_lookup+edx*4]
	pushfd
	pop dword[esp+8]
	iretd

kernelABIPriviledgeR0_lookup:
	dd userSetStateDown
	dd userCreateProcedure
	dd userYieldScheduler
	dd userEndProcedure
