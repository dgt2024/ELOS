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
fileDescriptorTable:
	; kernel:
	dw 0x07e0
	db 0x03
	; kernelproc:
	dw 0x0900
	db 0x01
fileDescriptorTable_driver:
	; ata:
	dw 0x0a00
	db 0x01
fileDescriptorTable_end: