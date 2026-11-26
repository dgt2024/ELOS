; Driver for terminal uartput
uart_fdt:
	dd 0, 0, 0, 0
	dd 0, 0, uart_sendFunc, 0
times 0x20 - ($ - uart_fdt) db 0
uart_main:
	mov edi, uart_devtable
	mov ebx, "COM1"
uart_findCOMPorts:
	mov dx, word[edi]

	; x86 assembly version of
	; https://wiki.osdev.org/Serial_Ports#Initialization
	mov al, 0x00
	inc dx
	out dx, al ; outb(PORT + 1, 0x00);

	mov al, 0x80
	add dx, 2
	out dx, al ; outb(PORT + 3, 0x80);

	mov al, 0x03
	sub dx, 3
	out dx, al ; outb(PORT + 0, 0x03);

	mov al, 0x00
	inc dx
	out dx, al ; outb(PORT + 1, 0x00);

	mov al, 0x03
	add dx, 2
	out dx, al ; outb(PORT + 3, 0x03);

	mov al, 0x0b
	inc dx
	out dx, al ; outb(PORT + 4, 0x0B);

	mov al, 0x1e
	out dx, al ; outb(PORT + 4, 0x1E);

	; test serial chip

	mov al, 0xae
	sub dx, 4
	out dx, al ; outb(PORT + 0, 0xAE);

	in al, dx
	cmp al, 0xae
	jne uart_skip

	mov al, 0x03
	add dx, 4
	out dx, al

	mov al, 0x00
	mov dh, 15
	push edi
	int 0x36
	pop edi

uart_skip:
	inc bl ; next COM port

	add edi, 2
	cmp edi, uart_devtableEnd
	jb uart_findCOMPorts
	ret

uart_sendFunc:
	mov ebp, ecx
	inc ebp
	; ebp=preamble end (ECX=EBP, preamble end)

	add ecx, uart_preambleEnd - uart_preamble
	; add preamble

	mov esi, edi
	shr edx, 24
	sub dl, '1' ; COM<n> -> n - 1
	
	mov dx, word[uart_devtable+edx*2]
	add dx, 5 ; port+5

	push esi ; save str after preamble
	mov esi, uart_preamble ; set preamble first

uart_sendFunc_isEmpty:
	in al, dx

	test al, 0x20
	jz uart_sendFunc_isEmpty

	sub dx, 5 ; port+0

	lodsb

	cmp al, 0
	je uart_sendFunc_end

	out dx, al

	add dx, 5 ; port+5

	cmp ecx, ebp
	je uart_endPreamble

	loop uart_sendFunc_isEmpty
uart_sendFunc_end:

	clc
	ret

uart_endPreamble:
	pop esi
	loop uart_sendFunc_isEmpty

	stc
	ret

uart_devtable:
	dw 0x3f8
	dw 0x2f8
	dw 0x3e8
	dw 0x2e8
	dw 0x5f8
	dw 0x4f8
	dw 0x5e8
	dw 0x4e8 
uart_devtableEnd:

uart_preamble:
	db "[SERIAL] "
uart_preambleEnd: