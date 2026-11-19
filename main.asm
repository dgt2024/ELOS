section .boot vstart=0x7c00
use16
%include "boot/boot.asm"
%include "boot/data.asm"
use32
%include "kernel/kernel.asm"
times 510 - ($ - $$) db 0
	dw 0xaa55
%include "kernel/memory.asm"
%include "kernel/container.asm"
%include "kernel/procedure.asm"
%include "kernel/link.asm"
%include "kernel/scheduler.asm"
%include "driver/driver.asm"
times 512 * 4 - ($ - $$) db 0
section .kernelproc vstart=0x9000
	cli
	jmp $
times 512 - ($ - $$) db 0
section .driver_ata vstart=0xa000
%include "driver/ata.asm"
times 512 - ($ - $$) db 0