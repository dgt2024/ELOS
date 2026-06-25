n	0x500			(struct idt[])	IDT Entries						KERNEL
	0x1500			END
n	0x1500			(byte)			Error Counter					MASTER
n	0x1501			(dword[])		Errors							MASTER
	0x1901			END
n	0x1a00			(struct sys)	System Data						KERNEL
	0x1a6d			END
	0x1c00			(dword[])		Stack Array						KERNEL
	0x2000			END
	0x10000			(struct mem[])	Dynamic Memory Indexes			KERNEL
	0x50000			END
n	0x50000			(struct pcb[])	Process List					KERNEL
	0x54000			END
n	0x54000			(struct msg[])	Message Queue					KERNEL
	0x54800			END
n	0x54800			(word)			PCI Device Count				SYSINIT/PCI
n	0x54802			(struct pci[])	PCI Devices						SYSINIT/PCI
	0x5c802			END
n	0x5c900			(byte)			Storage Device Count			SYSINIT/PCI/STORAGE
n	0x5c901			(struct sds[])	Storage Devices					SYSINIT/PCI/STORAGE
	0x5cb01			END
n	0x5cc00			(byte)			IDE HDD Count					SYSINIT/PCI/STORAGE
n	0x5cc01			(struct ide[])	IDE HDDs						SYSINIT/PCI/STORAGE
	0x5e001			END

struct mem {
	(byte)	Owner PID
	(dword)	Start
	(word)	Size (in 8B chunks)
	(byte)	Flags { bit 7 = Stack/Memory, bit 6-0 = Index }
}
struct sys {
	0x00 (dword) 	Current Process
	0x04 (dword)	Interrupt Stack TSS
	0x08 (word)		Stack Segment
	0x0a (byte)		Process Count
	0x0b (byte)		PADDING
	0x0c (dword)	Scheduler ESI Swap
	0x10 (dword)	Scheduler ESP Swap
	0x14 (dword) 	ms Counter
	0x18 (dword)	RAM count
	0x1c (dword)	TID Counter
	0x20 (6b)		IDT Descriptor Table
	0x26 (64b)		Interrupt Stack
	0x66 (word)		I/O TSS
	0x68 (word)		Dynamic Memory Page Count
	0x6a (dword)	Programs Ran
	0x6e (word)		Stack Size
	0x70 (dword)	Context Changes
}
struct ide {
	(byte)	Flags 1 = progIF | (LBA << 3)
	(word)	Data Port Ch 1
	(word)	Ctrl Port Ch 1
	(word)	Data Port Ch 2
	(word)	Ctrl Port Ch 2
	(word)	DMA Port (if NULL, DMA disabled)
	(dword)	PCI Device Pointer
	(dword) Size
	(byte)	Flags 2
} size=20
struct sds {
	(byte)	Disk Type { IDE = 0x01 }
	(byte)	Index
}
struct pci {
	(word)	Device ID
	(word)	Vendor ID
	(dword)	Device Pointer
} size=8
struct pcb {
	(dword)	EDI
	(dword)	ESI
	(dword)	EBP
	(dword)	ESP
	(dword)	EBX
	(dword)	EDX
	(dword)	ECX
	(dword)	EAX
	(dword)	EIP
	(dword)	CS
	(dword)	EFLAGS
	(dword)	ESP
	(dword)	SS
	(dword) DS/ES
	(dword) TID
	(byte)	Flags
	(byte)	Present
	(word)	RFU	
} size=64
struct msg {
	(byte) 	State { unread = 0x80, read = 0x00 }
	(void*)	Data
	(word)	Messenger PID
	(byte) nothing
} size=8