section .filesystem						; _LSECTOR+0 /
__root:

	dw __config_end - __config
	db 01010000b
	db 0
	dd _LSECTOR+1
__config_name:
	db "config"
times 16 - ($ - __config_name) db 0

	dw __bin_end - __bin
	db 01010000b
	db 0
	dd _LSECTOR+2
__bin_name:
	db "bin"
times 16 - ($ - __bin_name) db 0

	dw __mod_end - __mod
	db 01010000b
	db 0
	dd _LSECTOR+3
__mod_name:
	db "mod"
times 16 - ($ - __mod_name) db 0

__root_end:
times 512 - ($ - $$) db 0				; _LSECTOR+1 /config/
__config:

	dw __modcfg_end - __modcfg
	db 01010011b
	db 8
	dd _LSECTOR+4
__modcfg_name:
	db "mod.cfg"
times 16 - ($ - __modcfg_name) db 0

	dw __dircfg_end - __dircfg
	db 01010011b
	db 8
	dd _LSECTOR+5
__dircfg_name:
	db "path.cfg"
times 16 - ($ - __dircfg_name) db 0

__config_end:
times 512*2 - ($ - $$) db 0				; _LSECTOR+2 /bin/
__bin:

	dw __hwrld_end - __hwrld
	db 01010011b
	db 8
	dd _LSECTOR+6
__hwrld_name:
	db "hwrld"
times 16 - ($ - __hwrld_name) db 0

	dw __echo_end - __echo
	db 01010011b
	db 8
	dd _LSECTOR+7
__echo_name:
	db "echo"
times 16 - ($ - __echo_name) db 0

__bin_end:
times 512*3 - ($ - $$) db 0				; _LSECTOR+3 /mod/
__mod:

	dw __pit_end - __pit
	db 01010011b
	db 8
	dd _LSECTOR+8
__pit_name:
	db "pit.sys"
times 16 - ($ - __pit_name) db 0

	dw __ps2_end - __ps2
	db 01010011b
	db 8
	dd _LSECTOR+9
__ps2_name:
	db "ps2.sys"
times 16 - ($ - __ps2_name) db 0

__mod_end:
times 512*4 - ($ - $$) db 0				; _LSECTOR+4 /config/mod.cfg

__modcfg:
incbin "config/mod.cfg"
__modcfg_end:

times 512*5 - ($ - $$) db 0				; _LSECTOR+5 /config/dir.cfg

__dircfg:
incbin "config/dir.cfg"
__dircfg_end:

times 512*6 - ($ - $$) db 0				; _LSECTOR+6 /bin/hwrld

section .binary.hwrld vstart=0x40001000
__hwrld:
%include "bin/hwrld.asm"
__hwrld_end:

times 512 - ($ - $$) db 0				; _LSECTOR+7 /bin/echo

section .binary.echo vstart=0x40001000
__echo:
%include "bin/echo.asm"
__echo_end:

times 512 - ($ - $$) db 0				; _LSECTOR+8 /mod/pit.sys

section .driver.pit vstart=0x80000000
__pit:
%include "module/common/pit.asm"
__pit_end:

times 512 - ($ - $$) db 0				; _LSECTOR+9 /mod/ps2.sys

section .driver.ps2 vstart=0x80000000
__ps2:
%include "module/common/ps2.asm"
__ps2_end:

times 512 - ($ - $$) db 0