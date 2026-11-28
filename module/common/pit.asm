pit_fdt:
	dd 0, 0, 0, 0, 0, 0, 0, 0
times 0x20 - ($ - pit_fdt) db 0
	; set up channel 0 to yield
	mov word[0x906], 0x8000
	mov dword[0x902], 0xae000019
	mov word[0x900], pit_stuff
	mov dh, 1
	int 0x41

	mov al, 0x34
	out 0x43, al
	mov al, 0xa9
	out 0x40, al
	mov al, 0x04
	out 0x40, al

	mov edi, pit_initStr
	mov ecx, pit_initStr_end - pit_initStr
	mov ax, 0 ; log
	mov dh, 13
	mov bl, 6
	int 0x40

	mov dh, 11
	int 0x40
	sti
	jmp $

pit_stuff:
	sti
	mov dword[0x902], 0xae000019
	mov word[0x900], pit_stuff2
	mov dh, 1
	int 0x41
	rdtsc
	mov dword[0x684], eax

	mov al, 0x20
	out 0x20, al
	jmp $

pit_stuff2:
	sti
	rdtsc
	cli
	sub eax, dword[0x684]
	mov dword[0x684], eax

	mov word[0x906], 0
	mov dword[0x902], 0xae000008
	mov word[0x900], yieldScheduler

	mov dh, 1
	int 0x41
	add esp, 24
	ret

pit_time:
	dq 0

pit_initStr:
	db "Initializing PIT...", 10
pit_initStr_end: