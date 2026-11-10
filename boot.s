; This is the ELOS7 Source Code
section .boot
global main
use16
main:
	cli
	hlt
section .signature
	dw 0xaa55
