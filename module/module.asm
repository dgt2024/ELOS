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
	db "list.csv"
times 8 - ($ - __list_name) db 0

	dw __pit_end - __pit
	db 01010011b
	db 8
	dd _LSECTOR+3
__pit_name:
	db "pit.sys"
times 8 - ($ - __pit_name) db 0

__mod_end:
times 512*2 - ($ - $$) db 0

__list:
incbin "module/list.csv"
__list_end:

times 512*3 - ($ - $$) db 0

__pit:
%include "module/common/pit.asm"
__pit_end:

times 512*4 - ($ - $$) db 0