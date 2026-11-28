createProcedure:
	push ax
	push ecx ; Save title size
	push esi ; Save title addr
	push dx ; Save Parent TID
	push bx ; Save flags
	push ax ; Save code container HNDL

	mov al, 1
	call pageAllocate
	mov edi, edx
	or di, 0x100
	mov ax, 0x0030
	mov bx, 0x0000
	call registerContainer

	movzx edx, dx
	mov word[edx*8+0x1fffa], dx ; Change PDHNDL owner to itself

	mov cx, dx ; Store HNDL in cx
	mov ax, dx
	call getRawContainer
	and dx, 0xf000 ; Remove SZ and LINK#
	or dx, 0x0007

	; Create temporal virtual address
	mov dword[0x4020], edx

	push edx
	add edx, 0x1000
	mov dword[0x4028], edx
	pop edx

	invlpg[0x204000]
	invlpg[0x205000]

	; Clear CR3 (page directory)
	push ecx
	mov edi, 0x204000
	mov ecx, 0x2000
	xor eax, eax
	rep stosb
	pop ecx

	mov edi, 0x204000
	; edi=virtual page data,edx=physical page data,cx=PDHNDL

	pop ax ; code container HNDL
	call getRawContainer

	mov dword[edi+0xc], 0x40001ffc ; PDHNDL->ESP
	mov dword[edi+0x20], 0x40002000 ; PDHNDL->EIP
	mov dword[edi+0x24], 0x1202 ; PDHNDL->EFLAGS

	inc dword[0x608]
	mov eax, dword[0x608]
	mov dword[edi+0x28], eax ; PDHNDL->TID

	mov dword[edi+0x2c], 0 ; PDHNDL->CR3

	pop bx ; Load flags
	mov byte[edi+0x30], bl ; PDHNDL->FLAGS (low byte)
	mov byte[edi+0x31], 0

	xor eax, eax
	mov dword[edi+0x34], eax ; PDHNDL->SENT#|SYSC#

	pop dx
	mov word[edi+0x38], dx ; PDHNDL->DESC
	mov dword[edi+0x3c], eax ; PDHNDL->UPTIME
	mov byte[edi+0x52], al ; PDHNDL->N#
	mov dword[edi+0x54], eax ; PDHNDL->ALLOC#
	mov dword[edi+0x58], 0x40003000 ; PDHNDL->ALLOCADDR
	mov dword[edi+0x60], 0x5001 ; Kernel

	; Set up PDPT
	movzx ecx, cx
	mov edx, dword[ecx*8+0x1fffc]
	and dx, 0xf000
	or dx, 0x0001
	add dx, 0x1000
	mov dword[edi+0x68], edx
	mov dword[edi+0x78], 0x6001

	mov dx, cx ; Save PDHNDL to dx

	push edi ; Save raw PDHNDL

	; Set all IOPB bits
	add edi, 0x800
	mov ecx, 0x800
	mov al, 0xff
	rep stosb

	pop edi

	pop esi
	pop ecx
	add edi, 0x80 ; process name

	cmp ecx, 0x80
	jbe createProcedure_noClamp

	mov ecx, 0x80

createProcedure_noClamp:
	rep movsb

	mov ax, dx
	call registerProcedure

	mov ax, dx
	mov bx, dx

	push dx
	push ax
	call giveContainer
	pop ax
	call mapContainer
	pop dx

	pop ax ; Link HNDL code to PDHNDL
	movzx eax, ax

	; Change owner of HNDL to PDHNDL
	mov word[eax*8+0x1fffa], dx

	push edx ; PDHNDL
	push eax

	mov al, 0 ; stack size in pages
	call pageAllocate
	mov edi, edx
	mov ax, 0x0003
	mov ebx, dword[esp+4] ; RDHNDL
	call registerContainer
	mov ax, dx
	mov ebx, dword[esp+4]
	push ax
	call giveContainer
	pop ax
	call mapContainer

	pop eax
	mov edx, dword[esp]

	mov bx, dx
	push ax ; HNDL
	call giveContainer
	pop ax
	call mapContainer
	pop edx

	ret

registerProcedure:
	mov esi, 0x10000
	mov bx, ax
registerProcedure_loop:
	lodsw

	cmp esi, 0x20000
	jae registerProcedure_error

	test ax, ax
	jnz registerProcedure_loop

	mov word[esi-2], bx

	clc
	ret

registerProcedure_error:
	stc
	ret
