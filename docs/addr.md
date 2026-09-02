# Physical -> Virtual memory
0x1000 Variables
0x7000 (boot)	-> 0x7000
0x8000-0x9000 (kernel) -> 0xc0000000
VRAM			-> 0xf000000-0xf0600000
0x10000-0x90000 -> 0x10000-0x90000
0x90000-0xa0000 (custom) -> 0xe0000000 (at 0x90000)
Userland -> 0x10000000

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
0x7327 -> Flags (0:FPU)
0x7380 -> NET v:d
0x7384 -> NET MMIO
0x7388 -> NET send ; EDI/ECX
0x738c -> NET recv ; ESI/ECX
0x7400 -> Mouse X (in pixels)
0x7402 -> Mouse Y (in pixels)
0x7404 -> Button Flag
0x7405 -> Current Flagged Program
0x7406 -> mouse coords
0x7408 -> Keyboard
0x7428 -> Mouse last btn
0x7429 -> Mouse last process
0x742a -> mouse coords before click
0x742c -> keyboard last clicked
0x7500 -> kernel IPC
0x7900 -> ldtsc
0x7b00 -> Interrupt Stack
0x7c00 -> Kernel Stack
0x7228 -> Address of VESA LFB
0x10000-0x20000 -> Memory array
0x20000-0x24000 -> PCB array
0x24000-0x24400 -> Window Array
0x24400-0x24800 -> Textures
0x24800-0x25000 -> IPC
0x25000-0x25200+ -> NET init
0x25200-0x26000 -> NET scrap memory
0x26000-0x27000 -> Disk Scrap memory
0x9a000-0x9f000 -> Wallpaper

# ABI
AH=0x00 CreateText		DX=POS, ESI=STR, ECX=LEN
AH=0x01 CreateButton	DX=POS, BX=SIZE
AH=0x02 CreateSquare	DX=POS, BX=SIZE
AH=0x03 CreateSymbol	DX=POS, BL=CHAR
AH=0x04 Clear			BL=CHAR
AH=0x05 ClearPctg		ECX=AMOUNT BL=CHAR
AH=0x06 CustomSquare	DX=POS, BX=SIZE, ECX=SYM1, EDI=SYM2

AH=0x40 MemoryAlloc		ECX=AMOUNT > EDI=PTR
AH=0x41 ReadFile		ESI=STR, EDX=PTR > ECX=SIZE, EDI=END
AH=0x42 ReadSector		EDX=SECTOR, ECX=COUNT, EDI=PTR
AH=0x43 StartProcess	EDX=PTR(ELOS6 EXECUTABLE)
AH=0x44 FindFile		EBX=SECTOR ECX=SECTOR EDX=PTR(0=NW)
						ESI=FILENAME > EAX=SECTOR ECX=SIZE

AH=0x80 ConvertHex		EDI=STR, EBX=VALUE, ECX=SIZE (NIBBLE#)

AH=0xF9 GetFocusQueue	BL=INDEX_BW > AL=PID
AH=0xFA GetPCBRegister	BL=PID, EDX=OFFSET > EAX=VALUE
AH=0xFB GetKeyboard		BL=KEY > BH=ASCII, BL=SCANCODE, AL=KEY_STAT
AH=0xFC Yield
AH=0xFD Exit
AH=0xFE	GetWindow		> AL=BUTTONS, DX=PTR(INLINE), EDI=W_PTR
AH=0xFF RegisterCall	SI=OFFSET

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
Bootloader Start -> Hello, World!			9.780978 ms
Bootloader Start -> Calculator GUI Drawn	49.946368 ms
