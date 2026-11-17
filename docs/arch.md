This is the ELOS7 Source CodeBX
Memory Map
QWORD		0x600		TSC start
DWORD		0x608		LFB ptr					>> BEFORE initializeMemory();
BYTE		0x60C		RAM block count			>> BEFORE initializeMemory();
DWORD		0x608		TID
DWORD[]		0x5000		PD
DWORD[]		0x6000		PT <1MB ident.
STRUCT[]	0x20000		Container array

TODO:
 - Get drive parameters (currently hardcoded to native primary master ATA)
 - Make Disk driver an LCF module

Global Functions: NOTE: Functions with 'S' return status on carry flag
kernel/memory.asm
 - initializeMemory -> NO INPUT->NO OUTPUT
S- kernelPageAllocate -> AL=SIZE->EDX=ADDR
kernel/container.asm
S- registerContainer -> EDI=PTR,AX=FLAGS,BX=HNDL -> DX=HNDL
S- getRawContainer -> AX=HANDLE -> EDX=PTR
kernel/procedure.asm
S- createProcedure -> ESI=NAME,AX=CODE HNDL,BL=FLAGS -> DX=PDHNDL


0     1     2     3     4     5     6     7     8
FLAGS       HNDL        ADDRESS        SZ LINK#

FLAGS
0	1	2	3	4	5	6	7	8
R	W	C	COW	FPE	PDE	SPE	SE
SR	SW	SC	SO	SPR	SPW	SPC	SPO

	0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F  10
00	EDI         ESI         EBP         ESP
01	EBX         EDX         ECX         EAX
02	EIP         EFLAGS      TID         CR3
03	FLAGS S# SF SENT# SYSC# DESC.TID    UPTIME
04	BP0         BP1         BP2         BP3
05	BPF   N# R  ALLOC#		ALLOCADDR	LASTSENT
06 -> Process Name (up to 32 chars)
08 -> Children TID
10 -> Notifications
20 -> Owned Containers Array
40 -> Shared Array
60 -> Priviledged Shared Array
80 -> IOPB (ports 0000-4000)

BF -> DR7, 64B means not present
FL
0		1		2		3		4		5		6		7		8
Prvldge	Status	Role	Fatal	ObjPvge	Crtion	Static	Share
BP0E	BP1E	BP2E	BP3E	I/O block(IOBP) RFU		Present
