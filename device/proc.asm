kernelProcMain:
	; note drivers were loaded from file descriptor table
	cli
	mov esi, fileDescriptorTable+6 ; 3rd index on
kernelProcMain_initLoop:
	movzx eax, word[esi]
	shl eax, 4
	mov bl, byte[esi+2]

	push esi
	mov dh, 17
	int 0x36
	pop esi

	add esi, 3
	cmp esi, fileDescriptorTable_end
	jb kernelProcMain_initLoop

	rdtsc
	sub eax, dword[0x600]
	sub edx, dword[0x604]

	push eax

	mov eax, edx
	mov edi, str_num
	mov ecx, 8
	call intToStr

	pop eax
	mov ecx, 8
	call intToStr

	mov ax, word[0x10000]
	mov word[0x704], ax

	; print string2 on COM1
	mov edi, str
	mov ecx, str_end-str
	mov ax, 0 ; linux' /dev/ttyS0
	mov dh, 13
	mov bl, 6
	int 0x36

	mov eax, "OUT "
	mov dh, 14
	int 0x36

	mov ax, dx ; destination: PCI

	; print string2 on OUT
	mov edi, bootStr
	mov ecx, bootStr_end - bootStr
	mov dh, 13
	mov bl, 6
	int 0x36

	; read mod/ldfs
	mov eax, "LDFS"
	mov dh, 14
	int 0x36

	mov ax, dx

	push eax
	mov edi, listCSVFilename
	mov ecx, listCSVFilename_end - listCSVFilename
	mov dh, 13
	mov bl, 2
	int 0x36
	pop eax

	mov edi, listCSVFilename_end
listCSVLoop:
	push eax
	push edi

	mov ecx, 0xffffffff
	mov al, 0
	repne scasb ; find last reg

	dec edi
	mov eax, edi ; here should be the address of the driver

	mov dh, 18
	int 0x36

	mov ebp, edx

	pop edi
	pop eax

	push eax
	push eax
	push edi

	mov ecx, 0xffffffff
	mov al, ';'
	repne scasb ; find next disk address

	mov edi, dword[esp]
	mov eax, dword[esp+4]

	push ebp ; save address

	not ecx ; get size of filename

	mov dh, 13
	mov bl, 2
	int 0x36

	pop ebp

	pop edi
	pop eax

	mov eax, ebp
	mov bl, 1

	push eax
	push edi
	mov dh, 17
	int 0x36
	pop edi
	pop eax

	mov ecx, 0xffffffff
	mov al, ';'
	repne scasb ; find next disk address

	pop eax

	cmp byte[edi], 0
	jne listCSVLoop
	sti

	mov eax, "OUT "
	mov dh, 14
	int 0x36

	mov word[shellDevice], dx ; destination: OUT

shellLoop_main:
	mov edi, shell
	mov ecx, shell_end - shell
	mov ax, word[shellDevice]
	mov dh, 13
	mov bl, 6
	int 0x36

shellLoop:
	sti
	int 0x34

	mov dh, 21
	int 0x36

	cmp bl, 0x10
	je shellLoop_keyDown
	jmp shellLoop

shellLoop_keyDown:
	cmp ch, 0x0a
	je shellLoop_main

	mov byte[shellStr], ch

	mov edi, shellStr
	mov ecx, 1
	mov ax, word[shellDevice]
	mov dh, 13
	mov bl, 6
	int 0x36
	jmp shellLoop

shellDevice:
	dw 0

intToStr:
	rol eax, 4

	push eax
	and al, 0x0f

	cmp al, 0x0a
	jae intToStr_letter

	add al, '0'
	
	stosb
	pop eax
	loop intToStr
	ret

intToStr_letter:
	add al, 'A'-0x0a

	stosb
	pop eax
	loop intToStr
	ret

shell:
	db 10, "ELOS7> "
shell_end:

shellStr:
	db 0

str:
	db "File Table Initialized in 0x"
str_num:
	db "XXXXXXXXXXXXXXXX TSC ticks from boot", 10
str_end:

bootStr:
	db "Booting up ELOS7...", 10
bootStr_end:

listCSVFilename:
	db "mod/list.ll", 0
listCSVFilename_end: