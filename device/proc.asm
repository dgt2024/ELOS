kernelProcMain:
	; note drivers were loaded from file descriptor table
	cli
	mov esi, fileDescriptorTable+6 ; 3rd index on
kernelProcMain_initLoop:
	movzx eax, word[esi]
	shl eax, 4
	mov bl, byte[esi+2]

	push esi
	mov dh, 0
	int 0x42
	pop esi

	add esi, 3
	cmp esi, fileDescriptorTable_end
	jb kernelProcMain_initLoop

	mov ax, word[0x10000]
	mov word[0x704], ax

	; print string2 on COM1
	mov edi, str
	mov ecx, str_end-str
	mov ax, 0 ; linux' /dev/ttyS0
	mov dh, 1
	mov bl, 6
	int 0x42

	mov eax, "OUT "
	mov dh, 2
	int 0x42

	mov ax, dx ; destination: PCI

	; print string2 on OUT
	mov edi, bootStr
	mov ecx, bootStr_end - bootStr
	mov dh, 1
	mov bl, 6
	int 0x42

	; read mod/ldfs
	mov eax, "LDFS"
	mov dh, 2
	int 0x42

	mov ax, dx

	push eax
	mov edi, listCSVFilename
	mov ecx, listCSVFilename_end - listCSVFilename
	mov dh, 1
	mov bl, 2
	int 0x42
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

	mov dh, 3
	int 0x42

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

	mov dh, 1
	mov bl, 2
	int 0x42

	pop ebp

	pop edi
	pop eax

	mov eax, ebp
	mov bl, 1

	push eax
	push edi
	mov dh, 0
	int 0x42
	pop edi
	pop eax

	mov ecx, 0xffffffff
	mov al, ';'
	repne scasb ; find next disk address

	pop eax

	cmp byte[edi], 0
	jne listCSVLoop
	sti

	mov al, 0
	mov dh, 4
	int 0x42

	mov word[shellShare], dx

	mov eax, "OUT "
	mov dh, 2
	int 0x42

	mov word[shellDevice], dx ; destination: OUT

shellLoop_main:
	mov edi, shell
	mov ecx, shell_end - shell
	mov ax, word[shellDevice]
	mov dh, 1
	mov bl, 6
	int 0x42

	mov edi, 0x40002000

shellLoop:
	sti
	mov dh, 0
	int 0x43

	push edi
	mov dh, 5
	int 0x42
	pop edi

	cmp bl, 0x10
	je shellLoop_keyDown
	jmp shellLoop

shellLoop_keyDown:
	cmp ch, 0x0a
	je shellLoop_run

	cmp ch, 0
	je shellLoop_noWrite

	cmp ch, 0x08
	jne shellLoop_noBackspace

	cmp edi, 0x40002000
	jbe shellLoop

	dec edi
	mov byte[edi], 0

	jmp shellLoop_noWrite

shellLoop_noBackspace:

	mov byte[edi], ch
	inc edi

shellLoop_noWrite:

	mov byte[shellStr], ch

	push edi
	mov edi, shellStr
	mov ecx, 1
	mov ax, word[shellDevice]
	mov dh, 1
	mov bl, 6
	int 0x42
	pop edi
	jmp shellLoop

shellLoop_run:
	inc edi
	mov byte[edi-1], 0
	lea ecx, [edi-0x40002000]

	push edi
	push ecx

	mov eax, "LDFS"
	mov dh, 2
	int 0x42

	mov ax, dx

	mov ecx, dword[esp]

	mov edi, 0x40002000
	mov dh, 1
	mov bl, 2
	int 0x42
	jc shellLoop_runError

	mov al, 0
	mov dh, 4
	int 0x42

	pop ecx
	pop edi ; pointer to code

	push ecx
	push edx

	mov ecx, 0x200
	mov esi, edi
	mov edi, 0x40003000
	rep movsb

	pop eax
	pop ecx

	mov esi, 0x40002000
	mov bl, 0xdf

	mov dh, 1
	int 0x43

	mov ax, dx
	mov dh, 6
	mov ecx, "hey"
	int 0x42

	mov dh, 2
	int 0x43
	jmp shellLoop_main

shellLoop_runError:
	mov edi, shellError
	mov ecx, shellError_end - shellError
	mov ax, word[shellDevice]
	mov dh, 1
	mov bl, 6
	int 0x42
	jmp shellLoop_main

shellDevice:
	dw 0

shellShare:
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
	db 10, "$> "
shell_end:

shellError:
	db 10, "Error: file not found", 10, 0
shellError_end:

shellStr:
	db 0

str:
	db "FDT Initialized", 10
str_end:

bootStr:
	db "Booting up ELOS7...", 10
bootStr_end:

listCSVFilename:
	db "config/mod.cfg", 0
listCSVFilename_end: