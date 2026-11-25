section .filesystem
__root:
	dw __mod_end - __mod
	db 11010000b
	db 3
	dd _LSECTOR+1
__root_end:
times 512 - ($ - $$) db 0
	db "mod"
__mod:
	dw __list_end - __list
	db 11010011b
	db 3
	dd _LSECTOR+1
__mod_end:
times 512*2 - ($ - $$) db 0
	db "list.csv"
__list:
incbin "module/list.csv"
__list_end:
times 512*3 - ($ - $$) db 0