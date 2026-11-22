; Driver for terminal uartput
uart_fdt:
	db "Serial Logger"
times 0x20 - ($ - uart_fdt) db 0
uart_main:
	xor eax, eax
	mov dword[uart_fdt], eax
	mov dword[uart_fdt+0x4], eax
	mov dword[uart_fdt+0x8], eax
	mov dword[uart_fdt+0xc], eax
	mov dword[uart_fdt+0x10], eax
	mov dword[uart_fdt+0x14], eax
	mov dword[uart_fdt+0x18], uart_sendFunc
	mov dword[uart_fdt+0x1c], eax

	mov edi, uart_devtable
	mov ebx, "COM1"

	cld
	cli
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

	mov al, 0x0f
	add dx, 4
	out dx, al

	mov al, 0x01
	mov dh, 12
	push edi
	int 0x31
	pop edi

uart_skip:
	inc bl ; next COM port

	add edi, 2
	cmp edi, uart_devtableEnd
	jb uart_findCOMPorts
	ret

uart_sendFunc:
	mov esi, edi
	shr edx, 24
	sub dl, '1' ; COM<n> -> n - 1
	
	mov dx, word[uart_devtable+edx*2]
	add dx, 5 ; port+5

uart_sendFunc_isEmpty:
	in al, dx

	test al, 0x20
	jz uart_sendFunc_isEmpty

	sub dx, 5 ; port+0

	lodsb
	out dx, al

	add dx, 5 ; port+5
	loop uart_sendFunc_isEmpty

	clc
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