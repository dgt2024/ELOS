This is the ELOS7 Source Code
Memory Map
QWORD	0x600		TSC start
DWORD	0x608		LFB ptr
BYTE	0x60C		RAM block count 
DWORD[]	0x5000		PD
DWORD[]	0x6000		PT <1MB ident.


TODO:
 - Get drive parameters (currently hardcoded to native primary master ATA)
 - Make Disk driver an LCF module

Global Functions:
kernel/memory.asm
 - initializeMemory -> NO INPUT->NO OUTPUT
 - kernelPageAllocate -> NO INPUT->AL=STATUS,EDX=ADDR
kernel/container.asm
 - registerContainer -> EDI=PTR,AX=FLAGS,BX=HNDL -> AL=STATUS,DX=HANDLE
 - getRawContainer -> AX=HANDLE -> AL=STATUS,EDX=PTR