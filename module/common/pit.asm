pit_fdt:
	dd 0, 0, 0, 0, 0, 0, 0, 0
times 0x20 - ($ - pit_fdt) db 0
	cli
	jmp $