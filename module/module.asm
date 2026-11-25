section .filesystem
__root:

	dw __mod_end - __mod
	db 01010000b
	db 0
	dd _LSECTOR+1
__mod_name:
	db "mod"
times 8 - ($ - __mod_name) db 0

__root_end:
times 512 - ($ - $$) db 0
__mod:

	dw __list_end - __list
	db 01010011b
	db 8
	dd _LSECTOR+2
__list_name:
	db "list.ll"
times 8 - ($ - __list_name) db 0

	dw __pit_end - __pit
	db 01010011b
	db 8
	dd _LSECTOR+3
__pit_name:
	db "pit.sys"
times 8 - ($ - __pit_name) db 0

	dw __ps2_end - __ps2
	db 01010011b
	db 8
	dd _LSECTOR+4
__ps2_name:
	db "ps2.sys"
times 8 - ($ - __ps2_name) db 0

__mod_end:
times 512*2 - ($ - $$) db 0

__list:
incbin "module/list.csv"
__list_end:

times 512*3 - ($ - $$) db 0

section .driver.pit vstart=0x80000000
__pit:
%include "module/common/pit.asm"
__pit_end:

times 512 - ($ - $$) db 0

section .driver.ps2 vstart=0x80000000
__ps2:
%include "module/common/ps2.asm"
__ps2_end:

times 512 - ($ - $$) db 0