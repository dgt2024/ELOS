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
%include "driver/syscall.asm"
%include "device/device.asm"
times 512 * 5 - ($ - $$) db 0
section .program vstart=0x40001000
%include "device/proc.asm"
times 512 - ($ - $$) db 0
section .driver.uart vstart=0x80000000
%include "driver/common/uart.asm"
times 512 - ($ - $$) db 0
section .driver.out vstart=0x80000000
%include "driver/common/out.asm"
times 512 - ($ - $$) db 0
section .driver.pic vstart=0x80000000
%include "driver/common/pic.asm"
times 512 - ($ - $$) db 0
section .driver.ldfs vstart=0x80000000
%include "driver/common/ldfs.asm"
times 512 - ($ - $$) db 0
section .driver.pci vstart=0x80000000
%include "driver/common/pci.asm"
times 512 - ($ - $$) db 0
section .driver.ata vstart=0x80000000
%include "driver/pci/ata.asm"
times 1024 - ($ - $$) db 0