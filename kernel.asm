org 0x7c00
use16
kernel.boot:
	cli
	xor ax, ax
	mov ds, ax
	mov es, ax
	mov ss, ax
	int 0x10
	inc ah
	mov cx, 0x2607
	int 0x10
	mov ax, 0x0205
	mov bx, 0x7c00
	mov cx, 0x0001
	mov dh, 0
	int 0x13
	lgdt [kernel.gdttable]
	mov eax, cr0
	or eax, 1
	mov cr0, eax
	jmp 0x08:kernel.main
kernel.gdttable:
	dw kernel.gdtend - kernel.gdtdesc
	dd kernel.gdtdesc
kernel.gdtdesc:
	dq 0
	dq 0x00cf9a000000ffff
	dq 0x00cf92000000ffff
	dq 0x00cffe0004b0ffff
	dq 0x00c0f60000000000
	dq 0x00cffe000000ffff
	dq 0x00cff6000000ffff
	dq 0x00cff60004b0ffff
	dq 0x004089001a000068
kernel.gdtend:
use32
kernel.main:
	mov ax, 0x10
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov esp, 0x7c00
	call scheduler.fullsetup
	mov esi, sysinit.main
	mov ecx, 0x7b00
	mov bl, 0xc1
	call scheduler.addq
kernel.loop:
	call scheduler.run
	jmp short kernel.loop
intsr.setup:
	; SETUP PIC and Slave/Master ISR
	mov al, 0x11
	out 0x20, al
	out 0xa0, al
	mov al, 0x20
	out 0x21, al
	mov al, 0x28
	out 0xa1, al
	mov al, 0x04
	out 0x21, al
	mov al, 0x02
	out 0xa1, al
	mov al, 0x01
	out 0x21, al
	out 0xa1, al
	mov al, 0x00
	out 0x21, al
	out 0xa1, al
	mov al, 0xfe
	out 0x21, al
	mov al, 0xff
	out 0xa1, al
	; SETUP PIT timer
	mov al, 0x34
	out 0x43, al
	mov al, 0xa9
	out 0x40, al
	mov al, 0x04
	out 0x40, al
	sti
	ret
intsr.pittimer_irq:
	inc dword[0x1a14]
intsr.pittimer:
	cli
	inc dword[0x1a70]
	cmp dword[0x1a00], 0
	je intsr.skip
	push eax
	mov ax, 0x10
	mov ds, ax
	mov es, ax
	pop eax
	mov esp, dword[0x1a0c]
	add esp, 0x20
	pushad
	mov edi, dword[0x1a0c]
	add edi, 0x20
	mov esi, 0x1a52
	mov ecx, 5
	rep movsd
	mov al, 0x20
	out 0x20, al
intsr.no_save:
	mov esp, dword[0x1a10]
	jmp scheduler.loop
exception.undefined:
	cli
	hlt
scheduler.run:
	movzx ecx, byte[0x1a0a]
	jecxz exception.undefined
	mov esi, 0x50000-0x40
	mov dword[0x1a0c], esi
scheduler.loop:
	cli
	inc dword[0x1a00]
	mov eax, dword[0x1a6a]
	movzx ebx, byte[0x1a0a]
	cmp eax, ebx
	jae scheduler.end
	add dword[0x1a0c], 0x40
	mov eax, dword[0x1a0c]
	cmp byte[eax+0x3d], 0xff
	jne scheduler.loop
	inc dword[0x1a6a]
	mov dword[0x1a10], esp
	mov eax, dword[0x1a00]
	shl eax, 2
	add eax, 0x1c00
	mov eax, dword[eax]
	mov dr2, eax
	movzx ebx, word[0x1a6e]
	sub eax, ebx
	mov dr3, eax
	mov eax, 0xff0000f0
	mov dr7, eax
	mov esp, dword[0x1a0c]
	mov ax, word[esp+0x34]
	mov ds, ax
	mov es, ax
	popad
	sti
	iretd
times 506 - ($ - $$) db 0
dd 0x0000
dw 0xaa55
intsr.skip:
	mov al, 0x20
	out 0x20, al
	sti
	iretd
scheduler.end:
	mov dword[0x1a00], 0
	mov dword[0x1a6a], 0
	ret
scheduler.tasksetup:
	mov dword[0x1a04], 0x1a66
	mov word[0x1a08], 0x10
	mov word[0x1a66], 0xffff
	mov word[0x1a6e], 0x80
	mov ax, 0x40
	ltr ax
	mov eax, cr4
	or eax, 0x4
	mov cr4, eax
	ret
scheduler.fullsetup:
	call intsr.create
	call intsr.setup
	call scheduler.tasksetup
	ret
scheduler.addq: ; BL=Capabilities
	xor eax, eax
	inc byte[0x1a0a]
	mov eax, 0x5003d-0x40
scheduler.find_space:
	add eax, 0x40
	cmp byte[eax], 0
	jne scheduler.find_space
	sub eax, 0x1d
	push eax
	sub eax, 0x50020-0x40
	shr eax, 4
	add eax, 0x1c00
	mov dword[eax], ecx
	pop eax
	sub ecx, 0x4b0
	mov dword[eax], esi
	mov dword[eax+12], ecx
	mov dword[eax+16], 0x3b
	test bl, 0x01
	jnz scheduler.addiopl
	mov dword[eax+8], 0x202
	jmp short scheduler.addqc1
scheduler.addqc1:
	test bl, 0x80
	jnz scheduler.addkern
	mov dword[eax+4], 0x1b
	sub dword[eax], 0x4b0
scheduler.addqc2:
	test bl, 0x40
	jnz scheduler.addram
	mov dword[eax+20], 0x23
scheduler.addqc3:
	xor esi, esi
	mov si, word[0x1a0a]
	shl esi, 3
	add esi, 0x54000
	mov byte[esi], 0x80
	mov ebp, dword[0x1a1c]
	inc dword[0x1a1c]
	mov dword[eax+24], ebp
	mov byte[eax+28], bl
	mov byte[eax+29], 0xff
	ret
scheduler.addiopl:
	mov dword[eax+8], 0x3202
	jmp short scheduler.addqc1
scheduler.addkern:
	mov dword[eax+4], 0x2b
	jmp short scheduler.addqc2
scheduler.addram:
	mov dword[eax+20], 0x33
	jmp short scheduler.addqc3
intsr.create:
	mov dword[0x1a1c], 1
	mov edi, 0x500
	mov ebx, 0x8e000008
	mov eax, exception.undefined
	call intsr.createindex
	mov eax, iproccom.endprocess
	call intsr.createindex
	mov ecx, 0x1e
intsr.createloop1:
	mov eax, exception.undefined
	call intsr.createindex
	loop intsr.createloop1
	mov eax, intsr.pittimer_irq
	call intsr.createindex
	mov cl, 0x0f
intsr.createloop2:
	mov eax, exception.undefined
	call intsr.createindex
	loop intsr.createloop2
	mov ebx, 0xee000008
	mov eax, iproccom.service
	call intsr.createindex
	mov cl, 0x0f
intsr.createloop3:
	mov eax, exception.undefined
	call intsr.createindex
	loop intsr.createloop3
	sub edi, 0x500
	mov ax, di
	mov edi, 0x1a20
	mov dword[edi+2], 0x500
	stosw
	lidt [0x1a20]
	ret
intsr.createindex:
	stosw
	mov dword[edi], ebx
	shr eax, 16
	add edi, 4
	stosw
	ret
iproccom.service:
	; FUNCTION LIST:
	; AH=0x00 Send message through PID - returns error:
	;	0 NOERR 1 MSGUSED
	; BX=PID
	; EDI=Data 
	; AH=0x01 Check message status - returns status:
	; 	0 NOMSG 1 MSGIQ
	; BX=PID
	; AH=0x02 Read OWN status - returns error:
	;	0 NOMSG 1 MSGIQ
	; AH=0x03 Check Message - returns error:
	;	0 MSGOK 1 MSGRD
	; EDI DATA
	; BX OWNER
	; AH=0x04 Yield
	; AH=0x05 Get TIMESTAMP
	; EDX:EAX result
	; AH=0x06 End Process
	; AH=0x07 Spawn Sub-process
	cli
	pushad
	push eax
	mov ax, 0x10
	mov ds, ax
	mov es, ax
	pop eax
	cmp ah, 0x00
	je iproccom.sendmsg
	cmp ah, 0x01
	je iproccom.checkstatus
	cmp ah, 0x02
	je iproccom.readstatus
	cmp ah, 0x03
	je iproccom.readmessage
	cmp ah, 0x04
	je intsr.pittimer
	cmp ah, 0x05
	je iproccom.gettimestamp
	cmp ah, 0x06
	je iproccom.endprocess
	cmp ah, 0x07
	je iproccom.newprocess
	cmp ah, 0xff
	je iproccom.reloadidt
iproccom.end:
	mov byte[esp+29], ah
	popad
	iretd
iproccom.end4byte:
	mov dword[esp], edi
	mov word[esp + 16], bx
	mov byte[esp + 29], ah
	popad
	iretd
iproccom.reloadidt:
	lidt [0x1a20]
	popad
	iretd
iproccom.newprocess:
	mov esi, edi
	mov bl, 0x41
	call scheduler.addq
	popad
	iretd
iproccom.endprocess:
	mov bx, word[0x1a0a]
	dec word[0x1a0a]
	movzx ebx, bx
	shl ebx, 6
	mov edi, 0x5001d
	add edi, ebx
	mov byte[edi], 0
	popad
	jmp intsr.no_save
iproccom.gettimestamp:
	rdtsc
	mov dword[esp + 28], eax
	mov dword[esp + 20], edx
	popad
	iretd
iproccom.readmessage:
	mov esi, dword[0x1a00]
	shl esi, 3
	add esi, 0x54000
	lodsb
	test al, 0x80
	jnz iproccom.err1
	or byte[esi-1], 0x80
	lodsd
	mov edi, eax
	mov ah, 0x00
	mov bx, word[esi]
	jmp iproccom.end4byte
iproccom.readstatus:
	mov ebx, dword[0x1a00]
	jmp short iproccom.checkstatus
iproccom.checkstatus:
	movzx esi, bx
	shl esi, 3
	add esi, 0x54000
	lodsb
	test al, 0x80
	jz iproccom.err1
	mov ah, 0x00
	jmp iproccom.end
iproccom.sendmsg:
	movzx esi, bx
	shl esi, 3
	add esi, 0x54000
	lodsb
	test al, 0x80
	jz iproccom.err1
	mov dword[esi], edi
	mov bx, word[0x1a00]
	mov word[esi+4], bx
	mov byte[esi-1], 0x00
	dec esi
	jmp iproccom.end
iproccom.err1:
	mov ah, 0x01
	jmp iproccom.end
%include 'sysinit/master.asm'