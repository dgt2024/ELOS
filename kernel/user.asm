userAllocate: ; BX=flags
	push eax
	mov edi, dword[0x200058]
	movzx eax, al
	and al, 0x0f
	inc al
	shl eax, 12
	add dword[0x200058], eax
	add dword[0x20005c], eax
	pop eax

	push edi
	push ebx
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
	pop edi
	ret

userCreateProcedure:
	mov dx, word[0x612]
	call createProcedure
	ret

userCreateSingle:
	mov bx, 0x0007
	call userAllocate
	ret

userCreateShare:
	mov bx, 0x0187
	call userAllocate
	ret

userRequestShare:
	movzx eax, ax

	cmp word[0x1fff8+eax*8], 0
	je userRequestShare_err

	cmp word[0x1fffa+eax*8], 0
	je userRequestShare_map

	mov cx, ax ; cx = data (in this case, CMHNDL)
	mov ax, word[0x1fffa+eax*8] ; ax = dest (CMHNDL.OWNER)
	push eax
	mov bl, 0x01
	call sendNotification
	pop eax

	mov cx, word[0x612]
	mov bl, 0x01
	call sendNotification
	ret

userRequestShare_map:
	cli
	jmp $

userRequestShare_err:
	stc
	ret

; AX=PDHNDL,BL=TYPE,ECX=DATA 24b

userAnswerShare:
	; AL=0 :D, AL!=0 :(
	; BX=obj (not necessary if AL!=0)
	push eax
	push ebx
	call readNotification
	pop ebx
	pop eax

	cmp al, 0
	jne userAnswerShare_map

	pushad
	movzx eax, bx
	movzx ebx, cx
	call mapContainer
	popad

userAnswerShare_map:
	xchg eax, ecx ; PDHNDL<->status
	mov bl, 0x02
	call sendNotification
	ret

userSendNotification:
	mov bl, 0
	call sendNotification
	ret

userEndProcedure:
	cmp word[0x200038], 0
	je userEndProcedure_notify

	mov ecx, eax
	mov ax, word[0x200038]
	mov bl, 0x03
	call sendNotification

userEndProcedure_notify:
	mov ecx, 0x100
	mov esi, 0x200200
userEndProcedure_erase:
	lodsw

	cmp ax, 0
	je userEndProcedure_skipHNDL

	movzx eax, ax
	mov bx, word[0x200038]
	cmp word[0x1fffa+eax*8], bx
	je userEndProcedure_skipHNDL

	push esi
	push ecx
	call deleteContainer
	pop ecx
	pop esi

userEndProcedure_skipHNDL:
	loop userEndProcedure_erase

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