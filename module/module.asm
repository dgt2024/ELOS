section .filesystem
__root:
	dw __mod_end - __mod
	db 01010000b
	db 3
	dd _LSECTOR+1
__root_end:
times 512-4 - ($ - $$) db 0
	dd 0xffffffff

	db "mod"
__mod:
	dw __list_end - __list
	db 01010011b
	db 8
	dd _LSECTOR+2
__mod_end:
times 512*2-4 - ($ - $$) db 0
	dd 0xffffffff
	
	db "list.csv"
__list:
incbin "module/list.csv"
__list_end:
times 512*3 - ($ - $$) db 0