pci_fdt:
	dd 0, 0, 0, 0, 0, 0, 0, 0
times 0x20 - ($ - pci_fdt) db 0
	ret