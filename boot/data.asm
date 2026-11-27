gdtTable:
	dw gdtDescriptorTable_end - gdtDescriptorTable - 1
	dd gdtDescriptorTable
gdtDescriptorTable:
	dq 0
	dq 0x00cf9a000000ffff
	dq 0x00cf92000000ffff
	dq 0x00cfba000000ffff
	dq 0x00cfb2000000ffff
	dq 0x00cffa000000ffff
	dq 0x00cff2000000ffff
	dq 0x3f4089fff5001b00
gdtDescriptorTable_end:
idtTable:
	dw 0x7ff
	dd 0x800
fileDescriptorTable:
	; kernel:
	dw 0x07e0
	db 0x07
	; kernelproc:
	dw 0x0900
	db 0x02
	; common/out:
	dw 0x0a00
	db 0x01
	; common/uart:
	dw 0x0a20
	db 0x01
	; common/pic:
	dw 0x0a40
	db 0x01
	; common/ldfs:
	dw 0x0a60
	db 0x01
	; pci/ata:
	dw 0x0a80
	db 0x01
	; common/pci:
	dw 0x0aa0
	db 0x02
fileDescriptorTable_end: