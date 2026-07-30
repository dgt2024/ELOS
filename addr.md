# Physical -> Virtual memory
0x1000 Variables
0x7000 (boot)	-> 0x7000
0x8000-0x9000 (kernel) -> 0xc0000000
VRAM			-> 0xf000000-0xf0600000
0x10000-0x90000 -> 0x10000-0x90000
0x90000-0xa0000 (custom) -> 0xe0000000 (at 0x90000)
User content -> 0xb0000

# Variables
0x500 -> TSS
0x1000 -> IDT
0x2000 -> Page Directories
0x3000 -> Bootloader Page
0x4000 -> Kernel Page
0x7000 -> VESA config
0x7200 -> VESA mode config
0x7300 -> IDT descriptor
0x7306 -> Memory (dword)
0x730a -> Process Count
0x730b -> Current Process
0x730c -> Interrupt Call Switch
0x7320 -> DWORD PCB*
0x7324 -> Current Thread
0x7325 -> Timer
0x7400 -> Mouse X (in pixels)
0x7402 -> Mouse Y (in pixels)
0x7404 -> Button Flag
0x7405 -> Current Flagged Program
0x7406 -> mouse coords
0x7408 -> Keyboard
0x7500 -> kernel IPC
0x7900 -> ldtsc
0x7b00 -> Interrupt Stack
0x7c00 -> Kernel Stack
0x7228 -> Address of VESA LFB
0x10000-0x20000 -> Memory array
0x20000-0x24000 -> PCB array
0x24000-0x24400 -> Window Array

# Structs
struct pcb {
	0 dword edi
	4 dword esi
	8 dword ebp
	c dword esp
	10 dword ebx
	14 dword edx
	18 dword ecx
	1c dword eax
	20 dword EIP
	24 dword ESP
	28 dword EFLAGS
	2c byte flags:
		(1) occupid
	2d byte RFU
	2e word btnInterrupt
	30 dword window
	34 dword pageDirectory
	38 dword mallocRestant
	3c dword mallocPtr
};
struct window {
	00 byte X1
	01 byte Y1
	02 byte X2
	03 byte Y2
	04 byte bytecode array
	size : (X2-X1) * (Y2-Y1)
}

# Statistics
Bootloader Start -> Hello, World! 9.780978 ms