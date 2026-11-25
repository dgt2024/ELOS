kernelProcMain:
	; note drivers were loaded from file descriptor table
	; Setup terminal output
	mov esi, fileDescriptorTable+6 ; 3rd index on

kernelProcMain_initLoop:
	push esi ; Save FDT entry

	mov al, 2 ; allocates DDHNDL + PD + PT
	mov dh, 0
	int 0x33

	push edx ; Save DDHNDL for later

	mov eax, edx
	mov dh, 9
	int 0x33

	mov ebp, edx

	mov eax, dword[esp]

	mov dh, 18
	int 0x33

	movzx esi, dword[esp+4]
	movzx eax, word[esi]
	shl eax, 4

	mov dh, 17
	int 0x33

	movzx eax, word[esi]
	shl eax, 4

	and ax, 0x0fff

	movzx ecx, byte[esi+2]
	shl ecx, 9

	mov esi, 0x3ff000
	add esi, eax

	mov edi, 0x3fe000
	rep movsb

	mov eax, dword[esp]
	add eax, 0x1000 ; page directory

	mov dh, 17
	int 0x33

	mov eax, dword[esp]
	add eax, 0x2000 ; page table
	or ax, 0x0001
	mov dword[0x3ff000], eax

	mov dh, 17
	int 0x33

	mov eax, dword[esp]
	or ax, 0x0003 ; code (R/W)
	mov dword[0x3ff000], eax

	mov ax, bp
	mov dh, 10
	int 0x33

	mov word[0x80000ffc], bp
	call 0x80000020

	pop edx
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

	; print string2 on COM1
	mov edi, str
	mov ecx, str_end-str
	mov ax, 0 ; linux' /dev/ttyS0
	mov dh, 13
	mov bl, 6
	int 0x33

	mov eax, "OUT "
	mov dh, 14
	int 0x33

	mov ax, dx ; destination: PCI

	; print string2 on OUT
	mov edi, bootStr
	mov ecx, bootStr_end - bootStr
	mov dh, 13
	mov bl, 6
	int 0x33

	; read mod/ldfs
	mov eax, "LDFS"
	mov dh, 14
	int 0x33

	mov ax, dx

	mov edi, listCSVFilename
	mov ecx, listCSVFilename_end - listCSVFilename
	mov dh, 13
	mov bl, 2
	int 0x33

	mov edi, listCSVFilename_end
	mov ecx, 512
	mov ax, 0
	mov dh, 13
	mov bl, 6
	int 0x33

	mov edi, listCSVFilename_end
	cli
	jmp $

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

str:
	db "File Table Initialized in 0x"
str_num:
	db "XXXXXXXXXXXXXXXX TSC ticks from boot", 10
str_end:

bootStr:
	db "Booting up ELOS7...", 10
bootStr_end:

listCSVFilename:
	db "mod/list.csv", 0
listCSVFilename_end: