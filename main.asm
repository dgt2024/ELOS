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
times 512 * 4 - ($ - $$) db 0
section .kernelproc vstart=0x40001000
%include "driver/driver.asm"
times 512 - ($ - $$) db 0