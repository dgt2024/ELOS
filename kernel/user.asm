userAllocate: ; AX=flags
	push eax
	call pageAllocate

	mov edi, edx
	pop eax
	mov bx, word[0x612]
	call registerContainer

	mov ax, dx
	push eax
	mov bx, word[0x612]
	call giveContainer
	
	mov eax, dword[esp]

	mov bx, word[0x612]
	call mapContainer
	pop edx
	ret

userCreateSingle:
	mov ax, 0x0007
	call userAllocate
	ret

userCreateShare:
	mov ax, 0x0187
	call userAllocate
	ret

userSendNotification:
	mov bl, 0
	call sendNotification
	ret

userEndProcedure:
	movzx ecx, word[0x610]
	mov word[0x610], 0
	sti

	lea edi, [ecx-0x8000]
	not edi
	lea edi, [0x10000+edi*2]
	mov word[edi-4], 0
	jmp startScheduler_afterYield

userSetStateDown:
	add esp, 4
	and byte[0x200030], 0xfd ; set down
	jmp yieldScheduler

userYieldScheduler:
	add esp, 4
	jmp yieldScheduler

userUpdatePage:
	invlpg [eax]
	ret

userUpdateIDT:
	lidt [idtTable]
	ret

userUpdateCR3:
	push eax
	mov eax, cr3
	mov cr3, eax
	pop eax
	ret