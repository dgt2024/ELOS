This is the ELOS7 Source Code
Memory Map
QWORD	0x600 TSC start
DWORD	0x608 LFB ptr
DWORD[]	0x5000 PD
DWORD[]	0x6000 PT <1MB ident.

TODO:
 - Get drive parameters (currently hardcoded to native primary master ATA)
 - Make Disk driver an LCF module

Global Functions:
kernel/memory.s
 - initializeMemory -> Initializes memory
 - kernelPageAllocate -> Allocates a page of memory EDX=ADDR,AL=STATUS
kernel/container.s
 - registerContainer -> EDI=PTR,AX=FLAGS,BL=TYPE,BH=OWNER -> AL=STATUS,DX=HANDLE
kernel/disk.s
 - readDiskSector -> EDI=BUFF,EAX=SECTOR# -> AL=STATUS