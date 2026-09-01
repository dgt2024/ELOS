; This the ELOS6.1 Source code
; Thank you for checking my code ;D
; TODO: add bugs to fix later
section .boot vstart=0x7c00
use16
boot.main:
	cli
	cld
	xor ax, ax
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov ss, ax
	mov sp, 0x7c00
	int 0x10
	mov ax, 0x0212
	mov bx, 0x7c00
	mov cx, 0x0001
	mov dh, 0
	int 0x13
	mov ax, 0x4f00
	mov di, 0x7000
	mov word[es:di], "BV"
	mov word[es:di+2], "2E"
	push es
	int 0x10
	pop es
	cmp ax, 0x004f
	jne boot.no_vesa
	cmp word[es:di], "VE"
	jne boot.no_vesa
	cmp word[es:di+2], "SA"
	jne boot.no_vesa
	mov si, word[es:di+0x0e]
	mov ax, word[es:di+0x10]
	mov ds, ax
boot.vesa_loop:
	mov cx, word[ds:si]
	add si, 2
	cmp cx, 0xffff
	je boot.no_vesa
	mov ax, 0x4f01
	mov di, 0x7200
	push esi
	push es
	int 0x10
	pop es
	pop esi 
	cmp byte[fs:0x7219], 32
	jne boot.vesa_loop
	cmp word[fs:0x7212], 1280
	jne boot.vesa_loop
	cmp word[fs:0x7214], 1024
	jne boot.vesa_loop
	mov ax, 0x4f02
	mov bx, cx
	or bx, 0x4000
	int 0x10
	mov ax, 0xe801
	int 0x15
	cmp ax, 0x3c00
	jb boot.low_mem
	mov word[0x7308], bx
	lgdt [boot.gdttable]
	mov eax, cr0
	or eax, 1
	mov cr0, eax
	jmp 0x08:boot.after_vesa
use32
boot.low_mem:
	mov si, boot.low_mem_err
	mov cx, boot.low_mem_err_end-boot.low_mem_err
boot.no_vesa:
	mov si, boot.no_vesa_err
	mov cx, boot.no_vesa_err_end-boot.no_vesa_err
boot.print:
	mov ax, 0xb000
	mov es, ax
	mov di, 0x8000
	rep movsb
	jmp $
boot.after_vesa:
	mov ax, 0x10
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov esp, 0x7c00
	rdtsc
	mov dword[0x7900], eax
	mov dword[0x7904], edx
	mov dword[0x2000], 0x0000301b
	mov dword[0x3000], 0x0000001b
	mov dword[0x3004], 0x0000101b
	mov dword[0x3008], 0x0000201b
	mov dword[0x301c], 0x0000701b
	mov dword[0x3240], 0x0009001b
	mov dword[0x2c00], 0x0000401b
	mov dword[0x4000], 0x0000801b
	mov dword[0x4004], 0x0000901b
	mov dword[0x2f00], 0x0000501b
	mov dword[0x2f04], 0x0000601b
	mov dword[0x2e00], 0x0009001b
	mov edi, 0x5000
	mov eax, dword[0x7228]
	or al, 0x1b
	mov ecx, 0x800
	call boot.pagingloop
	mov eax, 0x1001b
	mov di, 0x3040
	mov cx, 0x80
	call boot.pagingloop
	mov eax, 0x2000
	mov cr3, eax
	mov eax, cr0
	or eax, 0x80000001
	mov cr0, eax
	call boot.idt
	jmp 0x08:0xc0000000
boot.pagingloop:
	stosd
	add eax, 0x1000
	loop boot.pagingloop
	ret
boot.idt:
	mov eax, 0x00087e00
	mov ebx, 0x00008e00
	mov ecx, 0x200
	mov edi, 0x1000
boot.idtloop:
	stosd
	xchg eax, ebx
	loop boot.idtloop
	mov word[0x7300], 0x800
	mov dword[0x7302], 0x1000
	lidt [0x7300]
	ret
times 494 - ($ - $$) db 0
dd 0x00000012
dd disk.clean_end-disk.clean
dd 0x00000013
dd disk.boot_end-disk.boot_start
dw 0xaa55
boot.exception:
	rdtsc
	sub edx, dword[0x7904]
	sub eax, dword[0x7900]
	cli
	hlt
boot.no_vesa_err:
	db "E.r.r.o.r.:. .V.E.S.A. .f.a.i.l.e.d."
boot.no_vesa_err_end:
boot.low_mem_err:
	db "E.r.r.o.r.:. .L.o.w. .m.e.m.o.r.y."
boot.low_mem_err_end:
boot.gdttable:
	dw boot.gdtend - boot.gdtdesc - 1
	dd boot.gdtdesc
boot.gdtdesc:
	dq 0
	dq 0x00cf9a000000ffff
	dq 0x00cf92000000ffff
	dq 0x00cffa000000ffff
	dq 0x00cff2000000ffff
	dq 0x0040890005000068
boot.gdtend:
times 1024 - ($ - $$) db 0
section .kernel vstart=0xc0000000
kernel.main:
	call kernel.init
kernel.run:
	call scheduler.run
	jmp kernel.run
kernel.init:
	; memory init
	mov cx, word[0x7308]
	shr cx, 4
	mov edi, 0x1ffff
	mov al, 0xff
	std
	rep stosb
	cld
	; scheduler init
	; SETUP PIC and Slave/Master ISR
	cli
	mov al, 0x11
	out 0x20, al
	out 0xa0, al
	mov al, 0x20
	out 0x21, al
	mov al, 0x28
	out 0xa1, al
	mov al, 0x04
	out 0x21, al
	mov al, 0x02
	out 0xa1, al
	mov al, 0x01
	out 0x21, al
	out 0xa1, al
	mov al, 0x00
	out 0x21, al
	out 0xa1, al
	mov al, 0xf8
	out 0x21, al
	mov al, 0xef
	out 0xa1, al
	; SETUP PIT timer
	mov al, 0x34
	out 0x43, al
	mov al, 0xa9
	out 0x40, al
	mov al, 0x04
	out 0x40, al
	; PS/2 driver
	mov al, 0xad
	out 0x64, al
	mov al, 0xa7
	out 0x64, al
	in al, 0x60
	mov al, 0x20
	out 0x64, al
	in al, 0x60
	and al, 0xae
	push ax
	mov al, 0x60
	out 0x64, al
	pop ax
	out 0x60, al
	mov al, 0xaa
	out 0x64, al
	in al, 0x60
	cmp al, 0x55
	jne kernel.ps2_err
	mov al, 0xa8
	out 0x64, al
	mov al, 0x20
	out 0x64, al
	in al, 0x20
	test al, 0x20
	jnz kernel.ps2_err
	push ax
	mov al, 0xa7
	out 0x64, al
	mov al, 0x60
	out 0x64, al
	pop ax
	and al, 0xdf
	out 0x60, al
	mov al, 0xab
	out 0x64, al
	in al, 0x60
	cmp al, 0
	jne kernel.ps2_err
	mov al, 0xa9
	out 0x64, al
	in al, 0x60
	cmp al, 0
	jne kernel.ps2_err
	mov al, 0xae
	out 0x64, al
	mov al, 0xa8
	out 0x64, al
	mov al, 0x20
	out 0x64, al
	in al, 0x60
	push ax
	mov al, 0x60
	out 0x64, al
	pop ax
	or al, 0x03
	out 0x60, al
	mov al, 0xd4
	out 0x64, al
	mov al, 0xf4
	out 0x60, al
	; load files
	mov esi, kernel.ld_font
	mov edx, 0x24400
	call disk.get_file
	cmp ah, 0x01
	je kernel.init_err
	mov esi, kernel.ld_symbols
	mov edx, 0x24700
	call disk.get_file
	cmp ah, 0x01
	je kernel.init_err
	mov esi, kernel.ld_wallpaper
	mov edx, 0x8a000
	call disk.get_file
	cmp ah, 0x01
	jne kernel.no_def_pp
	cli
	hlt
kernel.no_def_pp:
	; drivers
	;call module.pci_init
	; Set Up mouse
	mov word[0x7400], 640
	mov word[0x7402], 512
	; Interrupt create
	mov word[0x1106], 0xc000
	mov word[0x1102], 0x0008
	mov word[0x1100], scheduler.timer
	mov dword[0x1184], 0xc000ee00
	mov word[0x1180], kernel.service
	mov dword[0x110e], 0xc000
	mov word[0x1108], ps2.keyboard
	mov dword[0x1166], 0xc000
	mov word[0x1160], ps2.mouse
	mov dword[0x1006], 0xc000
	mov word[0x1000], kernel.div_by_0
	mov dword[0x100e], 0xc000
	mov word[0x1008], kernel.debug_exc
	mov dword[0x1036], 0xc000
	mov word[0x1030], kernel.undefined_oc
	mov dword[0x106e], 0xc000
	mov word[0x1068], kernel.general_pf
	mov dword[0x1076], 0xc000
	mov word[0x1070], kernel.page_fault
	lidt [0x7300]
	sti
	; Setup TSS
	mov dword[0x504], 0x7b00
	mov word[0x508], 0x10
	mov word[0x560], 0xffff
	mov ax, 0x28
	ltr ax
	; video init
	xor dx, dx
kernel.vloop:
	push edx
	call window.no_wnd
	pop edx
	inc dh
	cmp dh, 161
	jne kernel.vloop
	mov dh, 0
	inc dl
	cmp dl, 129
	jne kernel.vloop
	; debug tool:
	mov eax, 0x502
	mov dr0, eax
	mov eax, 0x10001
	mov dr7, eax
	ret
kernel.init_err:
	mov edi, 0xf0000000
	mov eax, 0xff0000
	mov ecx, 1280*1024
	rep stosd
	cli
	hlt
kernel.ld_symbols:
	db "symbols.bin", 0
kernel.ld_font:
	db "font.bin", 0
kernel.ld_wallpaper:
	db "wallpaper.spf", 0
kernel.update_whole_page:
	push eax
	mov eax, cr3
	mov cr3, eax
	pop eax
	ret
kernel.ps2_p1clr:
	in al, 0x64
	test al, 0x02
	jnz kernel.ps2_p1clr
	mov al, 0xff
	out 0x60, al
	in al, 0x60
	cmp al, 0xaa
	je kernel.ps2_pass1
	cmp al, 0xfa
	jne kernel.ps2_err
kernel.ps2_pass1:
	in al, 0x60
	cmp al, 0xaa
	je kernel.ps2_pass2
	cmp al, 0xfa
	jne kernel.ps2_err
kernel.ps2_pass2:
	ret
kernel.ps2_err:
	cli
	hlt
kernel.print_escr:
	cli
	cld
	push ecx
	push esi
	push eax
	mov edi, 0xf0000000
	mov ecx, 1280*1024
	mov eax, 0x0000aa
	rep stosd
	mov edx, 0xffffff
	mov esi, kernel.error_scr_msg1
	mov edi, 0xf01e0700
	mov ecx, 0xffffffff
	call window.print
	mov edi, 0xf01e0600 + 0x28000*1
	call window.print
	mov edi, 0xf01e0600 + 0x28000*2
	call window.print
	pop eax
	mov dword[esi], eax
	call window.print
	call window.print
	push edi
	mov edi, esi
	mov eax, dword[esp+16]
	call kernel.convert_hex
	pop edi
	call window.print
	push edi
	mov edi, esi
	push edx
	rdtsc
	sub edx, dword[0x7904]
	mov eax, edx
	pop edx
	call kernel.convert_hex
	pop edi
	call window.print
	push edi
	mov edi, esi
	push edx
	rdtsc
	sub eax, dword[0x7900]
	pop edx
	call kernel.convert_hex
	pop edi
	call window.print
	pop esi
	mov edi, 0xf01e0600 + 0x28000*4
	call window.print
	pop ecx
	push edi
	mov eax, ecx
	mov edi, esi
	call kernel.convert_hex
	pop edi
	call window.print
	ret
kernel.error_scr_msg1:
	db "An error in the kernel has occurred!", 0
	db "Technical Information: ", 0
	db 0, 0, 0, 0, 0, " at 0x", 0, "00000000; 0x", 0
	db "00000000", 0, "00000000 ns after boot", 0
kernel.db0r3:
	mov esi, kernel.db0r3_msg
	mov ecx, kernel.db0r3_msg_end-kernel.db0r3_msg
	jmp kernel.exc_prog
kernel.db0r3_msg:
	db "The program attempted to divide by zero."
kernel.db0r3_msg_end:
kernel.udopcode_r3:
	mov esi, kernel.udopcode_r3_msg
	mov ecx, kernel.udopcode_r3_msg_end-kernel.udopcode_r3_msg
	jmp kernel.exc_prog
kernel.udopcode_r3_msg:
	db "The program attempted to run an undefined opcode."
kernel.udopcode_r3_msg_end:
kernel.general_pf_r3:
	mov esi, kernel.general_pf_r3_msg
	mov ecx, kernel.general_pf_r3_msg_end-kernel.general_pf_r3_msg
	jmp kernel.exc_prog
kernel.general_pf_r3_msg:
	db "The program attempted to make a protected action."
kernel.general_pf_r3_msg_end:
kernel.page_fault_r3:
	mov esi, kernel.page_fault_r3_msg
	mov ecx, kernel.page_fault_r3_msg_end-kernel.page_fault_r3_msg
	jmp kernel.exc_prog
kernel.page_fault_r3_msg:
	db "The program attempted to access protected memory (segfault)."
kernel.page_fault_r3_msg_end:
kernel.div_by_0:
	test dword[esp+4], 0x03
	jnz kernel.db0r3
	mov ecx, eax
	mov eax, "#DE"
	mov esi, kernel.db0msg
	call kernel.print_escr
	cli
	hlt
kernel.db0msg:
	db "Tried to divide 0x", 0, "00000000 between 0", 0
kernel.debug_exc:
	cli
	hlt
kernel.undefined_oc:
	test dword[esp+4], 0x03
	jnz kernel.udopcode_r3
	mov edi, dword[esp]
	mov ecx, dword[edi]
	mov eax, "#UD"
	mov esi, kernel.undef_oc_msg
	call kernel.print_escr
	cli
	hlt
kernel.undef_oc_msg:
	db "Undefined Opcode (0x", 0, "00000000)", 0
kernel.general_pf:
	test dword[esp+8], 0x03
	jnz kernel.general_pf_r3
	pop ecx
	mov eax, "#GP"
	mov esi, kernel.general_pf_msg
	call kernel.print_escr
	cli
	hlt
kernel.general_pf_msg:
	db "Protection Barrier Broken with Segment 0x", 0, "00000000", 0
kernel.page_fault:
	test dword[esp+8], 0x03
	jnz kernel.page_fault_r3
	pop ecx
	mov eax, "#PF"
	mov esi, kernel.page_fault_msg
	call kernel.print_escr
	push edi
	mov eax, cr2
	mov edi, esi
	call kernel.convert_hex
	pop edi
	call window.print
	cli
	hlt
kernel.page_fault_msg:
	db "Accessing Unmapped Memory with Flags 0x", 0, "00000000 at 0x", 0, "00000000", 0
kernel.exc_prog:
	push esi
	push ecx
	pushad
	mov edx, 0x7500
	mov esi, kernel.exc_prog_dir
	call disk.get_file
	mov dword[esp], edi
	mov dword[esp+8], ecx
	popad
	mov ecx, 0xffffffff
	mov esi, dword[0x7320]
	mov esi, dword[esi+0x30]
	add esi, 4
	xor edx, edx
kernel.exc_prog_nloop:
	lodsb
	stosb
	inc edx
	cmp al, 0
	jne kernel.exc_prog_nloop
	mov esi, kernel.exc_progn2
	mov ecx, kernel.exc_progn2_end-kernel.exc_progn2
	dec edi
	lea edx, [edx+ecx-1]
	rep movsb
	mov word[0x7506], dx
	add edx, ebp
	mov word[0x7510], dx
	pop ecx
	pop esi
	mov ax, cx
	add ax, 2
	mov word[0x750e], ax
	rep movsb
	mov edx, 0x7500
	xor ebp, ebp
	call scheduler.create
	mov al, byte[0x730b]
	call scheduler.pkill
	jmp scheduler.yield_directly
kernel.exc_prog_dir:
	db "crash.exe", 0
kernel.exc_progn2:
	db " has stopped working"
kernel.exc_progn2_end:
kernel.user_convert_hex:
	mov eax, ebx
	call kernel.hex_loop
	iretd
kernel.convert_hex:
	mov ecx, 8
kernel.hex_loop:
	rol eax, 4
	push eax
	and al, 0x0f
	cmp al, 10
	jae kernel.hex_letter
	add al, '0'
	stosb
kernel.after_hlcx:
	pop eax
	loop kernel.hex_loop
	ret
kernel.hex_letter:
	add al, 'A' - 10
	stosb
	jmp kernel.after_hlcx
kernel.service:
	cli
	cld
	cmp ah, 0
	je window.user_print
	cmp ah, 1
	je window.user_button
	cmp ah, 2
	je window.user_simple
	cmp ah, 3
	je window.user_symbol
	cmp ah, 4
	je window.user_clear
	cmp ah, 5
	je window.user_fill
	cmp ah, 6
	je window.user_custom_sq
	cmp ah, 0x40
	je memory.user_malloc
	cmp ah, 0x41
	je disk.user_file_get
	cmp ah, 0x42
	je disk.user_sector_get
	cmp ah, 0x43
	je scheduler.user_create
	cmp ah, 0x44
	je disk.user_file_find
	cmp ah, 0x80
	je kernel.user_convert_hex
	cmp ah, 0xf9
	je window.get_focus_queue
	cmp ah, 0xfa
	je scheduler.user_get_register
	cmp ah, 0xfb
	je module.keybd_check
	cmp ah, 0xfc
	je scheduler.yield
	cmp ah, 0xfd
	je window.user_end
	cmp ah, 0xfe
	je window.user_get_data
	cmp ah, 0xff
	je window.user_register
	iretd
scheduler.run:
	sti
	mov esi, 0x2002c
	cmp byte[0x730a], 0
	je scheduler.run
	cli
scheduler.find_prog:
	lodsb
	inc byte[0x730b]
	add esi, 0x3f
	test al, 0x80
	jz scheduler.find_prog
	inc byte[0x7324]
	sub esi, 0x6c
	mov eax, dword[esi+0x20]
	mov dword[0x730c], eax
	mov dword[0x7310], 0x1b
	mov eax, dword[esi+0x28]
	mov dword[0x7314], eax
	mov eax, dword[esi+0x24]
	mov dword[0x7318], eax
	mov dword[0x731c], 0x23
	mov eax, dword[esi+0x34]
	mov dword[0x2100], eax
	mov dword[0x7320], esi
	call kernel.update_whole_page
	mov ax, 0x23
	mov es, ax
	mov ds, ax
	mov esp, esi
	popad
	mov esp, 0x730c
	iretd
scheduler.run_end:
	mov byte[0x730b], 0
	mov byte[0x7324], 0
	ret
scheduler.timer:
	cli
	inc word[0x7325]
	call window.check_time
scheduler.yield:
	cmp byte[0x730b], 0
	je scheduler.yield_return
	push eax
	mov ax, 0x10
	mov es, ax
	mov ds, ax
	pop eax
	mov esp, dword[0x7320]
	add esp, 0x20
	pushad
	mov eax, dword[0x7af8]
	mov dword[esp+0x24], eax
	mov eax, dword[0x7af4]
	mov dword[esp+0x28], eax
	mov eax, dword[0x7aec]
	mov dword[esp+0x20], eax
	mov esp, 0x7bfc
	pushad
	mov al, byte[0x730b]
	cmp byte[0x7405], al
	jne scheduler.no_button_prog
	mov edi, dword[0x7320]
	cmp word[edi+0x2e], 0
	je scheduler.no_button_prog
	test byte[0x7404], 7
	jnz scheduler.button_prog
scheduler.no_button_prog:
	popad
	mov esi, dword[0x7320]
	add esi, 0x6c
	mov al, byte[0x730a]
	cmp byte[0x7324], al
	mov al, 0x20
	out 0x20, al
	jae scheduler.run_end
	jmp scheduler.find_prog
scheduler.yield_directly:
	mov esp, 0x7bfc
	jmp scheduler.run_end
scheduler.yield_return:
	push eax
	mov al, 0x20
	out 0x20, al
	pop eax
	iretd
scheduler.button_prog:
	sub dword[edi+0x24], 4
	mov eax, dword[edi+0x24]
	mov ebx, dword[edi+0x20]
	mov dword[eax], ebx
	movzx eax, word[edi+0x2e]
	add eax, 0x10002000
	mov dword[edi+0x20], eax
	mov word[edi+0x2e], 0
	jmp scheduler.no_button_prog
scheduler.pkill:
	; kills AL
	dec byte[0x730a]
	movzx esi, al
	shl esi, 6
	add esi, 0x1ffc0
	and byte[esi+0x2c], 0x7f
	push dword[0x2100]
	mov ebx, dword[esi+0x34]
	mov dword[0x2100], ebx
	call kernel.update_whole_page
	mov ebx, dword[esi+0x30]
	test ebx, ebx
	jz scheduler.pkill_skip_wnd
	call kernel.update_whole_page
	mov ebx, dword[ebx]
	mov dword[0x7500], ebx
	sub byte[0x7501], 2
	call memory.kfree
	mov eax, esi
	mov edi, 0x23ffc
	mov ecx, 0x100
	repne scasd
	mov esi, edi
	sub edi, 4
scheduler.pkill_move_wnd:
	lodsd
	stosd
	test eax, eax
	jnz scheduler.pkill_move_wnd
	call window.update_whole_ptr
scheduler.pkill_skip_wnd:
	pop dword[0x2100]
	call kernel.update_whole_page
	ret
scheduler.user_create:
	xor ebp, ebp
	call scheduler.create
	iretd
scheduler.create:
	inc byte[0x730a]
	mov esi, 0x2002c
	cld
scheduler.find_space:
	lodsb
	add esi, 0x3f
	test al, 0x80
	jnz scheduler.find_space
	sub esi, 0x6c
	or byte[esi+0x2c], 0x80
	mov dword[esi+0x28], 0x202
	mov dword[esi+0x20], 0x10002000
	movzx eax, word[edx+22]
	add dword[esi+0x20], eax
	mov dword[esi+0x24], 0x10000ff4
	mov dword[esi+0x38], 0
	mov bx, si
	shr bx, 6
	inc bl
	call memory.kmalloc ; Page
	or di, 0x1f
	mov dword[esi+0x34], edi
	or di, 0x1b
	mov dword[0x90000], edi ; 0xa0000
	invlpg [0xe0000000]
	mov edi, 0xe0000000
	mov ecx, 0x400
	xor eax, eax
	rep stosd
	call memory.kmalloc ; Stack
	or di, 0x1f
	mov dword[0xe0000000], edi
	mov dword[0x90008], edi
	invlpg [0xe0002000]
	movzx ecx, word[edx+10]
	test ecx, ecx
	jz scheduler.no_wnd
	dec ecx
	shr ecx, 12
	inc ecx
	push esi
	mov esi, 0xe0000008
	mov ebp, 5
	mov eax, 12
	movzx ecx, word[edx+10]
	call scheduler.add_page
	cmp word[edx+16], 0
	jz scheduler.skip1
	push esi
	shl esi, 10
	add esi, 0x10000000
	mov dword[0xe0002ff8], esi
	pop esi
	mov ebp, 0x1f
	mov eax, 16
	movzx ecx, word[edx+14]
	call scheduler.add_page
scheduler.skip1:
	cmp word[edx+20], 0
	jz scheduler.skip2
	push esi
	shl esi, 10
	add esi, 0x10000000
	mov dword[0xe0002ffc], esi
	pop esi
	mov ebp, 0x1d
	mov eax, 20
	movzx ecx, word[edx+18]
	call scheduler.add_page
scheduler.skip2:
	call memory.kmalloc
	or edi, 0x1f
	mov dword[esi], edi
	lea ebp, [esi+4]
	pop esi
	test byte[edx+1], 0x80
	mov dword[esi+0x3c], ebp
	jnz scheduler.window
	mov dword[esi+0x30], 0
scheduler.no_wnd:
	ret
scheduler.window:
	mov al, byte[edx+4]
	sub al, byte[edx+2]
	jc scheduler.no_wnd
	mov cl, byte[edx+5]
	sub cl, byte[edx+3]
	jc scheduler.no_wnd
	mul cl
	push eax
	add ax, word[edx+8]
	add ax, 4
	push eax
	call memory.malloc
	pop eax
	push edi
	push eax
	mov eax, edi
	mov al, 0x1f
	mov edi, ebp
	mov ch, 0xff
	std
	repne scasd
	cld
	add edi, 4
	sub edi, 0xe0000000
	shl edi, 10
	add edi, 0x10000000
	add edi, dword[esi+0x38]
	pop eax
	movzx eax, ax
	sub edi, eax
	mov dword[esi+0x30], edi
	pop edi
	or edi, 0x1b
	mov dword[0x90000], edi
	invlpg [0xe0000000]
	mov ebp, edi
	mov edi, 0xe0000000
	pop eax
	push edi
	movzx ecx, ax
	mov al, 0
	rep stosb
	pop edi
	push esi
	lea esi, [edx+2]
	movsd
	movzx ecx, word[edx+8]
	lea esi, [edx+ecx]
	movzx ecx, word[edx+6]
	rep movsb
	mov byte[edi], 0
	mov edi, 0x24000
	xor eax, eax
	mov ecx, 0xffffffff
	repne scasd
	pop esi
	mov dword[edi-4], esi
	mov esi, ebp
	call window.updatepointer
	jmp scheduler.no_wnd
scheduler.add_page:
	push eax
	push ecx
	call memory.kmalloc
	pop ecx
	pop eax
	add edi, ebp ; Code (R-O, User)
	mov dword[esi], edi
	add esi, 4
	mov dword[0x90004], edi ; 0xa1000
	invlpg [0xe0001000]
	cmp ecx, 0x1000
	jz scheduler.after_code
	jb scheduler.cut_code
	sub ecx, 0x1000
	push ecx
	mov edi, 0xe0001000
	mov esi, edx
	add si, word[edx+eax]
	rep movsb
	pop ecx
	jmp scheduler.add_page
scheduler.after_code:
	ret
scheduler.cut_code:
	pushad
	mov edi, 0xe0001000
	mov esi, edx
	add si, word[edx+eax]
	rep movsb
	popad
	jmp scheduler.after_code
scheduler.user_get_register:
	mov ax, 0x10
	mov es, ax
	movzx edi, bl
	shl edi, 6
	lea edi, [edi+edx+0x1ffc0]
	mov eax, dword[edi]
	push eax
	mov ax, 0x23
	mov es, ax
	pop eax
	iretd
module.keybd_check:
	movzx eax, bl
	mov bh, 0
	mov bl, byte[0x742c]
	cmp bl, 0x0d
	jb module.keybd_nprint
	cmp bl, 0x66
	ja module.keybd_nprint
	test byte[0x740a], 0x0a
	jnz module.keybd_nprint
	pushad
	mov edi, 0x24000
	xor eax, eax
	mov ecx, 0xffffffff
	repne scasd
	mov esi, dword[0x7320]
	cmp esi, dword[edi-8]
	popad
	jne module.keybd_nprint
	movzx esi, bl
	test byte[0x740a], 0x04
	jnz module.keybd_shift
	test byte[0x7413], 0x02
	jnz module.keybd_shift
	add esi, module.keybd_layout-0x0d
module.after_keybdsh:
	mov bh, byte[esi]
module.keybd_nprint:
	bt [0x7408], eax
	jc module.keybd_y
	mov al, 0x00
	iretd
module.keybd_shift:
	add esi, module.keybd_shift_layout-0x0d
	jmp module.after_keybdsh
module.keybd_y:
	mov al, 0x01
	iretd
module.keybd_layout:
	db 0x09, '`', 0, 0, 0, 0, 0, 0, 'q', '1', 0, 0, 0, 'z'
	db 's', 'a', 'w', '2', 0, 0, 'c', 'x', 'd', 'e', '4', '3'
	db 0, 0, ' ', 'v', 'f', 't', 'r', '5', 0, 0, 'n', 'b', 'h'
	db 'g', 'y', '6', 0, 0, 0, 'm', 'j', 'u', '7', '8', 0, 0
	db ',', 'k', 'i', 'o', '0', '9', 0, 0, '.', '/', 'l', ';'
	db 'p', '-', 0, 0, 0, 0x27, 0, '[', '=', 0, 0, 0, 0, 0xd, ']'
	db 0, '/', 0, 0, 0, 0, 0, 0, 0, 0, 0x7f
module.keybd_shift_layout:
	db 0x09, '~', 0, 0, 0, 0, 0, 0, 'Q', '!', 0, 0, 0, 'Z'
	db 'S', 'A', 'W', '@', 0, 0, 'C', 'X', 'D', 'E', '$', '#'
	db 0, 0, ' ', 'V', 'F', 'T', 'R', '%', 0, 0, 'N', 'B', 'H'
	db 'G', 'Y', '^', 0, 0, 0, 'M', 'J', 'U', '&', '*', 0, 0
	db ',', 'K', 'I', 'O', ')', '(', 0, 0, '>', '?', 'L', ':'
	db 'P', '_', 0, 0, 0, 0x22, 0, '{', '+', 0, 0, 0, 0, 0xd, '}'
	db 0, '?', 0, 0, 0, 0, 0, 0, 0, 0, 0x7f
module.load:
	mov bl, 0xff
	call memory.kmalloc
	or di, 0x1b
	mov dword[0x90000], edi ; 0xa0000
	invlpg [0xe0000000]
	mov edi, 0xe0000000
	mov ecx, 0x400
	xor eax, eax
	rep stosd
	call memory.kmalloc
	ret
module.pci_init:
	mov ebx, 0x7ffffc00
module.pci_poll:
	add ebx, 0x400
	mov eax, ebx
	call module.pci_reg
	mov ecx, eax
	ror ecx, 16
	cmp ax, 0xffff
	je module.pci_poll
	mov eax, ebx
	mov al, 0x08
	call module.pci_reg
	rol eax, 16
	cmp ebx, 0x81000000
	jae module.pci_end
	cmp ah, 0x02
	je module.pci_net
	jmp module.pci_poll
module.pci_end:
	ret
module.pci_net:
	cmp dword[0x7380], 0
	jne module.pci_poll
	push ecx
	mov eax, ecx
	mov ecx, 4
	mov edi, module.pci_devfile
	call kernel.hex_loop
	inc edi
	mov ecx, 4
	call kernel.hex_loop
	push ebx
	mov esi, module.pci_devfile
	mov edx, 0x27000
	call disk.get_file
	pop ebx
	pop ecx
	cmp ah, 0x01
	je module.pci_poll
	pushad
	call 0x27000
	popad
	mov dword[0x7380], ecx
	mov dword[0x7384], ebx
	jmp module.pci_poll
module.pci_devfile:
	db "0000:0000.dev", 0
module.pci_reg:
	mov dx, 0xcf8
	out dx, eax
	mov dx, 0xcfc
	in eax, dx
	ret
disk.user_file_get:
	mov edx, edi
	call disk.get_file
	iretd
disk.user_file_find:
	; ecx=ptr
	; ebx=sector
	; edx=ptr_to_write(NULL=nowrite)
	; esi=filename
	; return:
	; eax=sector
	; ecx=size
	cli
	mov eax, ebx
	mov ebx, esi
	call disk.mfind_file
	iretd
disk.mfind_file:
	; ecx=size
	; eax=sector
	; edx=ptr_to_write(NULL=nowrite)
	; esi=filename
	; return:
	; ebx=sector
	; ecx=size
	mov ebx, esi
	push disk.after_find_file
	push edx
	jmp disk.find_file
disk.after_find_file:
	ret
disk.create_file:
	; esi=directory
	; ebp=filename
	cli
	mov eax, dword[0x7df6]
	mov ecx, dword[0x7dfa]
	mov edx, 0x26000
	pushad
	push ebp
	call disk.mfind_file
	cmp ah, 0x01
	pop ebp
	je disk.no_folder
	push ecx
	lea edi, [0x26000+ecx]
	push edi
	mov edi, ebp
	mov ecx, 0xffffffff
	mov al, 0
	repne scasb
	pop edi
	not ecx
	dec ecx
	add dword[0x26004], ecx
	add dword[0x26004], 14
	mov dword[edi+4], 0
	mov byte[edi+8], 0
	mov word[edi+9], cx
	add word[edi+9], 2
	mov word[edi+11], 0x0101
	mov byte[edi+13], cl
	mov dword[0x7704], ecx
	add edi, 14
	mov esi, ebp
	rep movsb
	pop ecx
	mov eax, ebx
	dec ecx
	shr ecx, 9
	inc ecx
	mov esi, 0x26000
	call disk.fs_write
	popad
	push dword[0x7704]
	push ecx
	push ecx
	push eax
	mov al, 0
	mov edi, esi
	mov ecx, 0xffffffff
	repne scasb
	pop eax
	xchg ecx, dword[esp]
	mov dword[edi-1], "/.."
	push esi
	call disk.mfind_file
	mov eax, ebx
	mov edx, 0x26000
	pop esi
	pop ecx
	not ecx
	dec ecx
	mov byte[esi+ecx], 0
	pop ecx
	pushad
	push eax
	call disk.mfind_file
	pop eax
	cmp eax, dword[0x7df6]
	jne disk.create_noroot
	mov eax, dword[0x7704]
	add dword[0x7dfa], eax
	add dword[0x7dfa], 14
	mov ecx, 1
	mov eax, 0
	mov esi, 0x7c00
	call disk.fs_write
disk.create_noroot:
	mov eax, dword[0x7704]
	add dword[ebp+4], eax
	add dword[ebp+4], 14
	popad
	dec ecx
	shr ecx, 9
	inc ecx
	mov esi, edx
	call disk.fs_write
	ret
disk.no_folder:
	add esp, 36
	ret
disk.get_file:
	; edx=end
	; esi=str
	cli
	cld
	mov eax, dword[0x7df6]
	mov ecx, dword[0x7dfa]
	; eax=pwd
	; ecx=s_size
	mov ebx, esi
	push edx
	cmp byte[esi], 0
	je disk.direct
disk.find_file:
	cmp byte[esi], '/'
	je disk.found_dir
	cmp byte[esi], 0
	je disk.found_file
	inc esi
	jmp disk.find_file
	ret
disk.found_dir:
	mov byte[0x7700], 0x80
	call disk.search_file
	jmp disk.find_file
disk.found_file:
	mov byte[0x7700], 0x00
	call disk.search_file
disk.direct:
	mov edi, dword[esp]
	mov ebx, eax
	test edi, edi
	jz disk.direct_no_write
	push ebx
	push ecx
	dec ecx
	shr ecx, 9
	inc ecx
	call disk.fs_read
	pop ecx
	pop ebx
disk.direct_no_write:
	pop edi
	add edi, ecx
	mov ah, 0x00
	ret
disk.fs_err:
	add esp, 0x14
	mov ah, 0x01
	ret
disk.search_file:
	sub ebx, esi
	neg ebx
	push ebx
	push ecx
	dec ecx
	shr ecx, 9
	inc ecx
	mov edi, 0x28000
	call disk.fs_read
	cmp ah, 0x01
	je disk.fs_err
	mov ebp, 0x28000
	push ebp
disk.check_dir:
	cmp byte[0x7700], 0x00
	je disk.after_cfnd
	test byte[ebp+8], 0x80
	jz disk.next_dir
disk.after_cfnd:
	movzx ecx, byte[ebp+11]
	test ecx, ecx
	jz disk.no_prop ; no properties = failed (there must be name/RFU)
	add ebp, 12
disk.check_prop:
	cmp byte[ebp], 0x01
	jne disk.next_prop
	mov dl, byte[esp+8]
	inc dl
	cmp byte[ebp+1], dl
	jne disk.next_dir
	push esi
	push ebp
	add ebp, 2
	sub esi, dword[esp+16]
	movzx ecx, dl
disk.check_name:
	mov dl, byte[ebp]
	cmp dl, byte[esi]
	jne disk.diff_name
	inc ebp
	inc esi
	loop disk.check_name
	pop ebp
	pop esi
	pop ebp
	pop ecx
	pop ebx
	mov eax, dword[ebp]
	mov ecx, dword[ebp+4]
	inc esi
	mov ebx, esi
	mov ah, 0x00
	ret
disk.diff_name:
	pop ebp
	pop esi
	jmp disk.next_dir
disk.next_prop:
	movzx edx, byte[ebp+1]
	add ebp, edx
	add ebp, 2
	loop disk.check_prop
disk.no_prop:
	add esp, 20
	mov ah, 0x01
	ret
disk.next_dir:
	pop ebp
	movzx edx, word[ebp+9]
	lea ebp, [ebp+edx+12]
	push ebp
	mov edx, dword[esp+4]
	add edx, 0x28000
	cmp ebp, edx
	jb disk.check_dir
	add esp, 20
	mov ah, 0x01
	ret
disk.user_sector_get:
	mov eax, edx
	call disk.fs_read
	iretd
disk.ata_setup:
	xor ebx, ebx
	mov dword[0x7500], eax
	mov dword[0x7503], ebx
	shr eax, 24
	and al, 0x0f
	mov byte[0x7506], al
	call disk.ata_nbsy
	mov dx, 0x1f6
	mov al, 0xe0
	or al, byte[0x7506]
	out dx, al
	mov dx, 0x1f2
	mov al, cl
	out dx, al
	mov dx, 0x1f3
	mov al, byte[0x7500]
	out dx, al
	mov dx, 0x1f4
	mov al, byte[0x7501]
	out dx, al
	mov dx, 0x1f5
	mov al, byte[0x7502]
	out dx, al
	ret
disk.fs_read:
	; eax=sector
	; ecx=sector count
	; edi=dest
	movzx ecx, cl
	call disk.ata_setup
	mov dx, 0x1f7
	mov al, 0x20
	out dx, al
	movzx ecx, cl
	call disk.ata_polling
	in al, dx
	xor al, 0x21
	test al, 0x29
	jz disk.fsr_err
	push ecx
	mov ecx, 256
	mov dx, 0x1f0
	rep insw
	pop ecx
	dec ecx
	test ecx, ecx
	jnz disk.fs_read
	ret
disk.fs_write:
	; eax=sector
	; ecx=sector count
	; esi=ptr
	call disk.ata_setup
	mov dx, 0x1f7
	mov al, 0x30
	out dx, al
	movzx ecx, cl
	call disk.ata_polling
	push ecx
	mov ecx, 256
	mov dx, 0x1f0
	rep outsw
	pop ecx
	sub edi, 4
	mov eax, dword[edi]
	dec ecx
	test ecx, ecx
	jnz disk.fs_write
	mov dx, 0x1f7
	mov al, 0xe7
	out dx, al
	call disk.ata_polling
	ret
disk.ata_polling:
	push ecx
	mov dx, 0x3f6
	mov ecx, 4
disk.fsr_400ns:
	in al, dx
	loop disk.fsr_400ns
	pop ecx
	call disk.ata_nbsy
	ret
disk.ata_nbsy:
	mov dx, 0x1f7
	in al, dx
	test al, 0x80
	jnz disk.ata_nbsy
	ret
disk.fsr_err:
	mov edx, 0xffffff
	mov edi, 0xf0002808
	mov esi, disk.fsr_errmsg
	mov ecx, 0xffffffff
	call window.print
	cli
	hlt
disk.fsr_errmsg:
	db "Error in file system start"
ps2.wait_for_input:
	mov ecx, 0x80
ps2.poll:
	in al, 0x64
	test al, 1
	jnz ps2.poll_end
	loop ps2.poll
	pop eax
	jmp ps2.skip
ps2.poll_end:
	ret
ps2.mouse:
	cli
	cld
	pushad
	push es
	push ds
	mov ax, 0x10
	mov es, ax
	mov ds, ax
	mov al, byte[0x7404]
	mov byte[0x7428], al
	movzx eax, word[0x7400]
	shr eax, 3
	mov byte[0x7407], al
	movzx eax, word[0x7402]
	shr eax, 3
	mov byte[0x7406], al
	call ps2.wait_for_input
	in al, 0x60
	xor al, 0x08
	test al, 0xc8
	jnz ps2.skip
	xor al, 0x08
	mov byte[0x7404], al
	call ps2.wait_for_input
	in al, 0x60
	movsx ax, al
	add word[0x7400], ax
	js ps2.x_underflow
	cmp word[0x7400], 1280
	ja ps2.x_overflow
ps2.after_xflow:
	call ps2.wait_for_input
	in al, 0x60
	movsx ax, al
	neg ax
	add word[0x7402], ax
	js ps2.y_underflow
	cmp word[0x7402], 1024
	ja ps2.y_overflow
ps2.after_yflow:
	call window.mouse_update
ps2.skip:
	pop ds
	pop es
	mov al, 0x20
	out 0xa0, al
	out 0x20, al
	popad
	iretd
ps2.y_overflow:
	mov word[0x7402], 0
	jmp ps2.after_yflow
ps2.y_underflow:
	mov word[0x7402], 1023
	jmp ps2.after_yflow
ps2.x_overflow:
	mov word[0x7400], 0
	jmp ps2.after_xflow
ps2.x_underflow:
	mov word[0x7400], 1279
	jmp ps2.after_xflow
ps2.keybd_wforin:
	mov ecx, 0x80
ps2.keybd_poll:
	in al, 0x64
	test al, 1
	jnz ps2.keybd_poll_end
	loop ps2.keybd_poll
	pop eax
	jmp ps2.no_end_task
ps2.keybd_poll_end:
	ret
ps2.keyboard:
	cli
	cld
	pushad
	call ps2.keybd_wforin
	in al, 0x60
	mov bx, 0
	cmp al, 0xe0
	je ps2.anormal_key
ps2.after_ak:
	cmp al, 0xf0
	je ps2.release_key
ps2.after_rk:
	add al, bl
	movzx eax, al
	cmp bh, 0x80
	je ps2.write_alkey_rel
	mov byte[0x742c], al
	bts [0x7408], eax
	jmp ps2.after_walkrel
ps2.write_alkey_rel:
	cmp byte[0x742c], al
	jne ps2.last_not_reset
	mov byte[0x742c], 0
ps2.last_not_reset:
	btr [0x7408], eax
ps2.after_walkrel:
	xor eax, eax
	mov al, 0x11
	bt [0x7408], eax
	jnc ps2.no_end_task
	mov al, 0x0c
	bt [0x7408], eax
	jnc ps2.shortcut
	cmp byte[0x7405], 0
	je ps2.no_end_task
	mov al, byte[0x7405]
	mov byte[0x7405], 0
	call scheduler.pkill
	mov al, 0x20
	out 0x20, al
	jmp scheduler.yield_directly
ps2.no_end_task:
	mov al, 0x20
	out 0x20, al
	popad
	iretd
ps2.shortcut:
	mov al, 0x2c
	bt [0x7408], eax
	jc ps2.tiny
	mov al, 0x23
	bt [0x7408], eax
	jc ps2.debug
	jmp ps2.no_end_task
ps2.tiny:
	mov esi, ps2.tiny_str
	mov edx, 0x28000
	call disk.get_file
	mov edx, 0x28000
	call scheduler.create
	jmp ps2.no_end_task
ps2.debug:
	mov esi, ps2.debug_str
	mov edx, 0x28000
	call disk.get_file
	mov edx, 0x28000
	call scheduler.create
	jmp ps2.no_end_task
ps2.tiny_str:
	db "tiny.exe", 0
ps2.debug_str:
	db "debug.exe", 0
ps2.anormal_key:
	mov bl, 0x80
	call ps2.keybd_wforin
	in al, 0x60
	jmp ps2.after_ak
ps2.release_key:
	mov bh, 0x80
	call ps2.keybd_wforin
	in al, 0x60
	jmp ps2.after_rk
memory.kfree:
	mov edi, 0x10000
	mov ecx, 0x10000
memory.kfree_loop:
	repne scasb
	mov byte[edi-1], 0
	jecxz memory.kfree_end
	loop memory.kfree_loop
memory.kfree_end:
	ret
memory.kmalloc:
	pushf
	cld
	mov edi, 0x10000
	mov ecx, 0x10000
	mov al, 0
	repne scasb
	mov byte[edi-1], bl
	sub edi, 0x10000
	shl edi, 12
	add edi, 0xff000
	popf
	ret
memory.user_malloc:
	mov esi, dword[0x7320]
	mov bl, byte[0x730b]
	mov eax, ecx
	call memory.malloc
	shl ebp, 10
	add ebp, 0xffff000
	add edi, ebp
	iretd
memory.malloc:
	; esi= PCB* (should be mapped already)
	; eax= Count
	; bl= PID
memory.malloc_loop:
	cmp eax, 0x1000
	push eax
	push memory.malloc_kreturn
	ja memory.kmalloc
	pop ebp
	jb memory.malloc_bit
memory.malloc_kreturn:
 	pop eax
 	sub eax, 0x1000
 	mov ebp, dword[esi+0x3c]
 	add dword[esi+0x3c], 4
	or edi, 0x1f
	mov dword[ebp], edi
	jmp memory.malloc_loop
memory.malloc_bit:
	add dword[esi+0x38], eax
	cmp dword[esi+0x38], 0x1000
	jae memory.malloc_overflow
	mov ebp, dword[esi+0x3c]
	mov edi, dword[ebp-4]
	and di, 0xf000
	add edi, dword[esi+0x38]
	pop eax
	sub edi, eax
	ret
memory.malloc_overflow:
	push eax
	call memory.kmalloc
	pop eax
	sub dword[esi+0x38], 0x1000
	mov eax, dword[esi+0x3c]
	or edi, 0x1f
	mov dword[eax], edi
	add dword[esi+0x3c], 4
	add edi, dword[esi+0x38]
	pop eax
	sub edi, eax
	ret
window.get_focus_queue:
	mov ax, 0x10
	mov es, ax
	mov edi, 0x24000
	xor eax, eax
	mov ecx, 0xffffffff
	repne scasd
	movzx ebx, bl
	lea ebx, [ebx*4+8]
	sub edi, ebx
	mov eax, dword[edi]
	test eax, eax
	jz window.queue_zero
	sub eax, 0x1ffc0
	shr eax, 6
	movzx eax, al
window.queue_zero:
	push eax
	mov ax, 0x23
	mov es, ax
	pop eax
	iretd
window.check_time:
	mov dword[0x7500], esp
	mov esp, 0x7b80
	pushad
	mov ax, word[0x7325]
	test ax, 0xff
	jz window.render_time
	popad
	mov esp, dword[0x7500]
	ret
window.time:
	db " | ", 0, "00000000 | ", 0, "00000000 | ELOS6.1 | Explorer |", 0
window.render_time:
	; edx = RGB Color
	; esi = Char
	; edi = Position
	; ecx = Max Chars
	mov edi, 0xf0000000
	mov ecx, 1280*16
	mov eax, 0x888888
	rep stosd
	mov ecx, 0xffffffff
	mov esi, window.time
	mov edi, 0xf0002808
	mov edx, 0xffffff
	call window.print
	push edi
	xor edx, edx
	mov al, 0x0b
	out 0x70, al
	in al, 0x71
	and al, 0xfb
	mov ah, al
	mov al, 0x0b
	out 0x70, al
	mov al, ah
	out 0x71, al
	mov al, 0x04
	out 0x70, al
	in al, 0x71
	mov dl, al
	shl edx, 12
	mov al, 0x02
	out 0x70, al
	in al, 0x71
	mov dl, al
	shl edx, 12
	mov al, 0x00
	out 0x70, al
	in al, 0x71
	mov dl, al
	mov eax, edx
	mov edi, esi
	call kernel.convert_hex
	pop edi
	mov byte[esi+2], ':'
	mov byte[esi+5], ':'
	mov edx, 0xffffff
	call window.print
	push edi
	mov al, 0x07
	out 0x70, al
	in al, 0x71
	mov dl, al
	shl edx, 12
	mov al, 0x08
	out 0x70, al
	in al, 0x71
	mov dl, al
	shl edx, 12
	mov al, 0x09
	out 0x70, al
	in al, 0x71
	mov dl, al
	mov eax, edx
	mov edi, esi
	call kernel.convert_hex
	pop edi
	mov byte[esi+2], '/'
	mov byte[esi+5], '/'
	mov edx, 0xffffff
	call window.print
	popad
	mov esp, dword[0x7500]
	ret
window.window_moves:
	cmp dl, 0x02
	jae window.after_iwm
	cmp dh, 24
	jb window.after_iwm
	cmp dh, 32
	ja window.after_winver
	pushad
	mov edx, 0x26000
	mov esi, window.winver_dir
	call disk.get_file
	cmp ah, 0x01
	je kernel.init_err
	mov edx, 0x26000
	xor ebp, ebp
	call scheduler.create
	popad
	jmp window.after_iwm
window.after_winver:
	cmp dh, 42
	ja window.after_iwm
	pushad
	mov edx, 0x26000
	mov esi, window.explorer_dir
	call disk.get_file
	cmp ah, 0x01
	je kernel.init_err
	mov edx, 0x26000
	xor ebp, ebp
	call scheduler.create
	popad
window.after_iwm:
	call window.wm_update
	jmp window.after_wm
window.wm_update:
	pushad
	push dword[0x2100]
	cmp byte[0x7429], 0
	je window.after_wmpa
	movzx edi, byte[0x7429]
	shl edi, 6
	add edi, 0x1ffc0
	mov eax, dword[edi+0x34]
	mov dword[0x2100], eax
	call kernel.update_whole_page
	mov ecx, dword[edi+0x30]
	mov bx, word[0x7406]
	sub bx, word[0x742a]
	xchg bh, bl
	mov eax, dword[ecx]
	mov dword[0x7500], eax
	sub byte[0x7501], 2
	add byte[ecx], bl
	js window.wm_x_underflow
window.after_wmxuf:
	add byte[ecx+1], bh
	js window.wm_y_underflow
window.after_wmyuf:
	add byte[ecx+2], bl
	add byte[ecx+3], bh
	push ebx
	call window.update_whole_ptr
	pop ebx
	add byte[0x7500], bl
	add byte[0x7501], bh
	add byte[0x7502], bl
	add byte[0x7503], bh
	call window.update_whole_ptr
window.after_wmpa:
	pop dword[0x2100]
	call kernel.update_whole_page
	popad
	ret
window.wm_x_underflow:
	sub bl, byte[ecx]
	mov byte[ecx], 0
	jmp window.after_wmxuf
window.wm_y_underflow:
	sub bh, byte[ecx+1]
	mov byte[ecx+1], 0
	jmp window.after_wmyuf
window.save_for_wm:
	mov byte[0x7429], al
	mov ax, word[0x7406]
	mov word[0x742a], ax
	jmp window.after_null
window.winver_dir:
	db "winver.exe", 0
window.explorer_dir:
	db "explorer.exe", 0
window.mouse_update:
	mov dx, word[0x7406]
	pushad
	test byte[0x7404], 0x01
	jnz window.after_wm
	test byte[0x7428], 0x01
	jnz window.window_moves
window.after_wm:
	call window.get_pid_by_coord
	test ebp, ebp
	jz window.set_pid_null
	mov eax, ebp
	test byte[0x7404], 0x01
	jnz window.after_cfwnd
	test byte[0x7428], 0x01
	jnz window.check_focused_wnd
window.after_cfwnd:
	sub eax, 0x1ffc0
	shr eax, 6
	mov byte[0x7405], al
	test byte[0x7404], 0x01
	jz window.after_null
	test byte[0x7428], 0x01
	jz window.save_for_wm
window.after_null:
	popad
	sub dl, 2
	push dword[0x2100]
	dec dh
	cmp dl, 0
	jne window.no_dy
	dec dl
window.no_dy:
	mov ecx, 4
window.update_y:
	push ecx
	mov ecx, 3
window.update_x:
	pushad
	call window.updatetile
	popad
	inc dh
	loop window.update_x
	pop ecx
	sub dh, 3
	inc dl
	loop window.update_y
	pop dword[0x2100]
	call kernel.update_whole_page
	movzx eax, word[0x7402]
	imul eax, 1280*4
	movzx ebx, word[0x7400]
	shl ebx, 2
	add eax, ebx
	add eax, 0xf0000000
	mov edi, eax
	mov ecx, 13
	xor ebx, ebx
window.mouse_y:
	push ecx
	mov ecx, 8
window.mouse_x:
	bt [window.mouse_texture], ebx
	jnc window.no_mouse_px
	mov eax, 0xffffff
	mov dword[edi], eax
window.no_mouse_px:
	add edi, 4
	inc ebx
	loop window.mouse_x
	pop ecx
	add edi, (1280-8)*4
	loop window.mouse_y
	ret
window.mouse_texture:
	db 00000001b
	db 00000011b
	db 00000111b
	db 00001111b
	db 00011111b
	db 00111111b
	db 01111111b
	db 11111111b
	db 00111111b
	db 00111011b
	db 01110001b
	db 01110000b
window.check_focused_wnd:
	pushad
	xor eax, eax
	mov edi, 0x24000
	mov ecx, 0xffffffff
	repne scasd
	cmp dword[edi-8], ebp
	je window.check_fwnd_end
	mov edi, 0x24000
	mov eax, ebp
	repne scasd
	mov esi, edi
	sub edi, 4
window.cfwnd_loop:
	lodsd
	stosd
	test eax, eax
	jnz window.cfwnd_loop
	mov dword[edi-4], ebp
	push dword[0x2100]
	mov eax, dword[ebp+0x34]
	mov dword[0x2100], eax
	call kernel.update_whole_page
	mov eax, dword[ebp+0x30]
	mov eax, dword[eax]
	mov dword[0x7500], eax
	sub byte[0x7501], 2
	call window.update_whole_ptr
	pop dword[0x2100]
	call kernel.update_whole_page
window.check_fwnd_end:
	popad
	jmp window.after_cfwnd
window.set_pid_null:
	test byte[0x7404], 0x01
	jz window.after_pid_null
	test byte[0x7428], 0x01
	jnz window.after_pid_null
	mov byte[0x7429], 0
window.after_pid_null:
	mov byte[0x7405], 0
	jmp window.after_null
window.update_whole_ptr:
	mov dx, word[0x7500]
	xchg dh, dl
window.uwptr_loop:
	pushad
	call window.updatetile
	popad
	inc dh
	cmp dh, byte[0x7502]
	jae window.uwptr_down
	jmp window.uwptr_loop
window.uwptr_down:
	mov dh, byte[0x7500]
	inc dl
	cmp dl, byte[0x7503]
	jae window.end_uwptr
	jmp window.uwptr_loop
window.end_uwptr:
	ret
window.user_end:
	mov ax, 0x10
	mov es, ax
	mov ds, ax
	mov al, byte[0x730b]
	call scheduler.pkill
	jmp scheduler.yield_directly
window.user_get_data:
	mov ax, 0x10
	mov es, ax
	mov ds, ax
	mov al, byte[0x730b]
	cmp byte[0x7405], al
	jne window.user_cgt
	mov ah, 0x01
	mov al, byte[0x7404]
	mov dx, word[0x7406]
	mov edi, dword[0x7320]
	mov edi, dword[edi+0x30]
	sub dh, byte[edi]
	sub dl, byte[edi+1]
	push eax
	mov ax, 0x23
	mov es, ax
	mov ds, ax
	pop eax
	iretd
window.user_cgt:
	mov ah, 0
	iretd
window.get_data_prot:
	mov ax, 0x10
	mov es, ax
	mov edi, dword[0x7320]
	mov edi, dword[edi+0x30]
	test edi, edi
	jz window.user_wow
	mov ax, 0x23
	mov es, ax
	ret
window.user_clear:
	xor ecx, ecx
window.user_fill:
	push ebx
	push ecx
	call window.get_data_prot
	mov eax, dword[edi]
	mov dword[0x7500], eax
	mov ax, word[edi+2]
	sub ax, word[edi]
	mul ah
	movzx ebx, ax
	add edi, 4
	mov al, 0
	mov ecx, 0xffffffff
	repne scasb
	pop ecx
	test ecx, ecx
	jnz window.no_setup
	mov ecx, ebx
window.no_setup:
	pop eax
	rep stosb
	call window.update_whole_ptr
	iretd
window.user_register:
	; at ESI is offset from starting addr
	mov edi, dword[0x7320]
	mov word[edi+0x2e], si
	iretd
window.user_wow:
	add esp, 4
	iretd
window.user_custom_sq:
	mov dword[0x7500], ecx
	mov dword[0x7504], edi
	call window.user_square
	iretd
window.user_simple:
	mov dword[0x7500], 0x8b8a8988
	mov dword[0x7504], 0x8d898c8b
	call window.user_square
	iretd
window.user_button:
	mov dword[0x7500], 0x83828180
	mov dword[0x7504], 0x87868584
	call window.user_square
	iretd
window.user_square:
	call window.get_data_prot
	mov cx, bx
	mov ax, word[edi]
	xchg ah, al
	push eax
	push edx
	mov bx, word[edi+2]
	xchg bh, bl
	sub bh, ah
	sub bl, al
	mov al, bh
	mul dl
	movzx dx, dh
	add ax, dx
	movzx eax, ax
	add edi, 4
	push ecx
	push eax
	mov ecx, 0xffffffff
	mov al, 0
	repne scasb
	pop eax
	pop ecx
	add edi, eax
	pop edx
	pop eax
	add dx, ax
	push edx
	push ecx
	push edi
	; Top layer
	mov al, byte[0x7500]
	call window.single
	mov al, byte[0x7501]
	call window.horizontal
window.no_top_layer:
	inc dh
	inc edi
	mov al, byte[0x7502]
	call window.single
	mov edi, dword[esp]
	mov ecx, dword[esp+4]
	mov edx, dword[esp+8]
	push ebx
	inc ch
	movzx ebp, bh
	movzx ebx, ch
	movzx ecx, cl
window.bar_loop:
	inc dl
	mov ax, word[0x7503]
	call window.double
	loop window.bar_loop
	pop ebx
	pop edi
	pop ecx
	pop edx
	mov al, bh
	push ecx
	inc cl
	mul cl
	add dl, cl
	movzx eax, ax
	add edi, eax
	pop ecx
	mov al, byte[0x7505]
	call window.single
	mov al, byte[0x7506]
	call window.horizontal
window.no_bottom_layer:
	inc dh
	inc edi
	mov al, byte[0x7507]
	call window.single
	ret
window.horizontal:
	movzx ecx, ch
	jecxz window.no_horizontal
window.horizontal_loop:
	inc edi
	inc dh
	cmp dh, bl
	je window.horiz_newl
window.after_hnewl:
	call window.single
	loop window.horizontal_loop
window.no_horizontal:
	ret
window.horiz_newl:
	mov dh, 0
	inc dl
	jmp window.after_hnewl
window.single:
	; al = char
	; edi = pos
	mov byte[edi], al
	push dword[0x2100]
	pushad
	call window.updatetile
	popad
	pop dword[0x2100]
	call kernel.update_whole_page
	ret
window.double:
	; edi = pos
	; ebx = space
	; ebp = x size
	; ah | al
	add edi, ebp
	mov byte[edi], al
	mov byte[edi+ebx], ah
	push dword[0x2100]
	pushad
	call window.updatetile
	popad
	pushad
	add dh, bl
	call window.updatetile
	popad
	pop dword[0x2100]
	call kernel.update_whole_page
	ret
window.user_symbol:
	push ebx
	call window.get_data_prot
	mov cx, bx
	mov ax, word[edi]
	xchg ah, al
	push eax
	push edx
	mov bx, word[edi+2]
	xchg bh, bl
	sub bh, ah
	sub bl, al
	mov al, bh
	mul dl
	movzx dx, dh
	add ax, dx
	movzx eax, ax
	add edi, 4
	push ecx
	push eax
	mov ecx, 0xffffffff
	mov al, 0
	repne scasb
	pop eax
	pop ecx
	add edi, eax
	pop edx
	pop eax
	add dx, ax
	pop eax
	call window.single
	iretd
window.user_print:
	call window.get_data_prot
	mov ax, word[edi]
	xchg ah, al
	mov bx, word[edi+2]
	xchg bh, bl
	movzx ebp, dx
	xchg dh, dl
	sub bh, ah
	sub bl, al
	push eax
	mov al, bh
	mul dh
	movzx dx, dl
	add ax, dx
	movzx eax, ax
	add edi, 4
	push eax
	mov ecx, 0xffffffff
	mov al, 0
	repne scasb
	pop eax
	add edi, eax
	mov edx, ebp
	pop eax
	movzx ebx, bh
window.uprint_loop:
	cmp byte[esi], 0x10
	jb window.uprint_end
	push eax
	lodsb
	mov byte[edi], al
	cmp al, ' '
	jb window.no_bottom
	cmp al, '~'
	ja window.no_bottom
	or al, 0x80
	mov byte[edi+ebx], al
window.no_bottom:
	inc edi
	pop eax
	pushad
	add dh, ah
	add dl, al
	mov ax, 0x10
	mov es, ax
	mov ds, ax
	push dword[0x2100]
	push edx
	call window.updatetile
	pop edx
	push edx
	inc dl
	call window.updatetile
	pop edx
	pop dword[0x2100]
	call kernel.update_whole_page
	mov ax, 0x23
	mov es, ax
	mov ds, ax
	popad
	inc dh
	loop window.uprint_loop
window.uprint_end:
	inc esi
	iretd
window.get_pid_by_coord:
	push dword[0x2100]
	mov bl, 0
	mov esi, 0x24000
	xor ebp, ebp
window.get_pid_loop:
	lodsd
	test eax, eax
	jz window.get_pid_none
	mov ecx, dword[eax+0x30]
	mov edi, dword[eax+0x34]
	mov dword[0x2100], edi
	call kernel.update_whole_page
	cmp dh, byte[ecx]
	jb window.nextwindow_nad
	cmp dh, byte[ecx+2]
	jae window.nextwindow_nad
	cmp dl, byte[ecx+3]
	jae window.nextwindow_nad
	add dl, 2
	cmp dl, byte[ecx+1]
	jb window.nextwindow
	mov ebp, eax
window.nextwindow:
	sub dl, 2
window.nextwindow_nad:
	inc bl
	jmp window.get_pid_loop
window.get_pid_none:
	pop dword[0x2100]
	call kernel.update_whole_page
	ret
window.nexttile:
	add esi, 0x40
	jmp window.get_pid_loop
window.updatetile:
	; dh,dl
	call window.get_pid_by_coord
	test ebp, ebp
	jz window.no_wnd
	mov edi, dword[ebp+0x30]
	mov eax, dword[ebp+0x34]
	mov dword[0x2100], eax
	call kernel.update_whole_page
	push edx
	mov al, byte[edi+2]
	sub al, byte[edi]
	sub dl, byte[edi+1]
	jc window.titlebar
	mul dl
	sub dh, byte[edi]
	movzx dx, dh
	add ax, dx
	movzx ebx, ax
	mov al, 0
	mov ecx, 0xffffffff
	add edi, 4
	repne scasb
	mov al, byte[edi+ebx]
	pop edx
	movzx edi, dl
	imul edi, 1280*8*4
	movzx edx, dh
	shl edx, 5
	add edi, edx
	add edi, 0xf0014000
	cmp al, 0x10
	jb window.blank
	cmp al, ' '
	jb window.color
	mov ah, al
	and al, 0x7f
	cmp al, ' '
	jb window.symbol
	pushad
	call window.blank
	popad
window.text:
	sub al, ' '
	movzx esi, al
	shl esi, 3
	add esi, 0x24400
	test ah, 0x80
	jnz window.low_nibble
	add edi, 1280*4*2+8
window.after_lnadd:
	xor edx, edx
	call window.nibble
	ret
window.low_nibble:
	add esi, 4
	add edi, 8
	jmp window.after_lnadd
window.titlebar:
	push edi
	add edi, 4
	mov al, dh
	sub al, byte[edi-4]
	movzx ecx, al
	mov al, 0
	repne scasb
	mov al, byte[edi]
	cmp byte[edi-1], 0
	je window.titlebar_clral
window.after_tbcrlar:
	pop edi
	movzx ecx, dh
	movzx edi, byte[edi+1]
	imul edi, 1280*8*4
	add edi, 0xf0000000
	shl ecx, 5
	add edi, ecx
	mov ah, al
	pushad
	mov ecx, 16
window.titlebar_loop:
	mov edx, ecx
	mov eax, 0x0000ff
	mov ecx, 8
	rep stosd
	add edi, (1280-8)*4
	mov ecx, edx
	loop window.titlebar_loop
	popad
	cmp al, ' '
	jb window.notext
	sub al, ' '
	movzx esi, al
	shl esi, 3
	add esi, 0x24400
	pushad
	add edi, 1280*4*2+8
	mov edx, 0xffffff
	call window.nibble
	popad
	pushad
	add esi, 4
	add edi, 1280*4*8+8
	mov edx, 0xffffff
	call window.nibble
	popad
window.notext:
	pop edx
	ret
window.titlebar_clral:
	mov al, 0
	jmp window.after_tbcrlar
window.color:
	and al, 0x0f
	movzx edx, al
	mov bl, al
	and bl, 0x08
	shl bl, 4
	add bl, 0x7f
	xor edx, edx
	test al, 0x04
	jz window.no_red
	movzx edx, bl
	shl edx, 16
window.no_red:
	test al, 0x02
	jz window.no_green
	mov dh, bl
window.no_green:
	test al, 0x01
	jz window.no_blue
	mov dl, bl
window.no_blue:
	mov eax, edx
	mov ecx, 8
	call window.nownd_loop
	ret
window.symbol:
	and al, 0x7f
	movzx esi, al
	shl esi, 3
	add esi, 0x24700
	pushad
	call window.blank
	popad
	xor edx, edx
	mov ax, 0x10
	mov es, ax
	mov ds, ax
	call window.print_symbol
	mov ax, 0x23
	mov es, ax
	mov ds, ax
	ret
window.taskbar:
	mov eax, 0x888888
	jmp window.after_taskbar
window.no_wnd:
	add dl, 2
	cmp dl, 2
	jb window.taskbar
	push edx
	movzx eax, dl
	imul eax, 160
	movzx edx, dh
	lea eax, [eax+edx+0x8a000]
	mov dl, byte[eax]
	mov al, dl
	shr al, 6
	inc al
	push eax
	push edx
	shr dl, 4
	and dl, 0x03
	mul dl
	shl al, 4
	movzx ebx, al
	shl ebx, 16
	mov edx, dword[esp]
	mov eax, dword[esp+4]
	shr dl, 2
	and dl, 0x03
	mul dl
	shl al, 4
	mov bh, al
	mov edx, dword[esp]
	mov eax, dword[esp+4]
	and dl, 0x03
	mul dl
	shl al, 4
	mov bl, al
	pop edx
	pop eax
	pop edx
	mov eax, ebx
window.after_taskbar:
	movzx edi, dl
	imul edi, 1280*8*4
	movzx edx, dh
	shl edx, 5
	add edi, edx
	add edi, 0xf0000000
	mov ecx, 8
window.nownd_loop:
	mov edx, ecx
	mov ecx, 8
	rep stosd
	add edi, (1280-8)*4
	mov ecx, edx
	loop window.nownd_loop
	ret
window.blank:
	mov ecx, 8
window.blank_loop:
	mov edx, ecx
	mov eax, 0xc0c0c0
	mov ecx, 8
	rep stosd
	add edi, (1280-8)*4
	mov ecx, edx
	loop window.blank_loop
	ret
window.print_symbol:
	xor eax, eax
window.print_symbloop:
	bt [esi], eax
	jnc window.symbp_skip
	mov dword[edi], 0
window.symbp_skip:
	add edi, 4
	inc eax
	test eax, 0x7
	jz window.psymb_down
window.after_psymb_down:
	test eax, 0x3f
	jnz window.print_symbloop
	ret
window.psymb_down:
	add edi, (1280-8)*4
	jmp window.after_psymb_down
window.updatepointer:
	; esi=addr
	mov dword[0x90000], esi
	invlpg [0xe0000000]
	mov esi, 0xe0000000
	movzx edi, byte[esi+1]
	imul edi, 1280*4*8
	movzx eax, byte[esi]
	shl eax, 5
	lea edi, [0xf0000000+eax+edi]
	mov dl, byte[esi+2]
	sub dl, byte[esi]
	movzx edx, dl
	shl edx, 3
	mov cl, byte[esi+3]
	sub cl, byte[esi+1]
	movzx ecx, cl
	shl ecx, 3
	mov ebp, 1280*4
	push edx
	shl edx, 2
	sub ebp, edx
	pop edx
	push edi
	push ecx
	mov ecx, 16
	mov eax, 0x0000ff
window.title_loop:
	push ecx
	mov ecx, edx
	rep stosd
	pop ecx
	add edi, ebp
	loop window.title_loop
	pop ecx
	push ecx
	mov eax, 0xc0c0c0
window.ptr_loop:
	push ecx
	mov ecx, edx
	rep stosd
	pop ecx
	add edi, ebp
	loop window.ptr_loop
	pop ecx
	mov ecx, edx
	shr ecx, 3
	dec ecx
	pop edi
	add edi, 1280*4*2+8
	add esi, 4
	mov edx, 0xffffff
	call window.print
	ret
window.print:
	; edx = RGB Color
	; esi = Char
	; edi = Position
	; ecx = Max Chars
	push ecx
	xor eax, eax
	lodsb
	cmp al, 0
	je window.print_finish
	push esi
	mov esi, 0x24400
	sub ax, 32
	shl eax, 3
	add esi, eax
	mov ecx, 2
window.print_floop:
	push ecx
	call window.nibble
	pop ecx
	loop window.print_floop
	pop esi
	sub edi, 0xefe0
	pop ecx
	loop window.print
	add edi, 0x7800
	mov ecx, 3
window.print_susp:
	mov dword[edi], edx
	add edi, 8
	loop window.print_susp
window.print_end:
	ret
window.nibble:
	lodsd
	mov ecx, 6
	mov ebx, 30
window.print_vloop:
	push ecx
	mov ecx, 5
window.print_hloop:
	dec ebx
	bt eax, ebx
	jnc window.print_skip
	mov dword[edi], edx
window.print_skip:
	add edi, 4
	loop window.print_hloop
	pop ecx
	add edi, 5100
	loop window.print_vloop
	ret
window.print_finish:
	pop ecx
	ret
times 0x10 * 512 - ($ - $$) db 0
disk.clean:
disk.clean_end:
times 0x11 * 512 - ($ - $$) db 0
section .filesystem vstart=0x0
disk.boot_start:
	dd 0x00000013
	dd disk.boot_end-disk.boot_start
	db 0x80
	dw 0x04
	db 0x01, 0x01, 0x02, ".", 0
	dd 0x00000013
	dd disk.boot_end-disk.boot_start
	db 0x80
	dw 0x05
	db 0x01, 0x01, 0x03, "..", 0
	dd 0x00000016
	dd window.font_end-window.font
	db 0x00
	dw 0x0b
	db 0x01, 0x01, 0x09, "font.bin", 0
	dd 0x00000018
	dd window.symbols_font_end-window.symbols_font
	db 0x00
	dw 0x0e
	db 0x01, 0x01, 0x0c, "symbols.bin", 0
	dd 0x00000014
	dd kernel.winver_end-kernel.winver
	db 0x00
	dw 0x0d
	db 0x01, 0x01, 0x0b, "winver.exe", 0
	dd 0x00000015
	dd kernel.exc_progn1_end-kernel.exc_progn1
	db 0x00
	dw 0x0c
	db 0x01, 0x01, 0x0a, "crash.exe", 0
	dd 0x00000019
	dd window.explorer_end-window.explorer
	db 0x00
	dw 0x0f
	db 0x01, 0x01, 0x0d, "explorer.exe", 0
	dd 0x0000001a
	dd module.notepad_end-module.notepad
	db 0x00
	dw 0x0e
	db 0x01, 0x01, 0x0c, "notepad.exe", 0
	dd 0x0000001b
	dd module.tiny_cmd_end-module.tiny_cmd
	db 0x00
	dw 0x0b
	db 0x01, 0x01, 0x09, "tiny.exe", 0
	dd 0x0000001c
	dd module.debug_end-module.debug
	db 0x00
	dw 0x0c
	db 0x01, 0x01, 0x0a, "debug.exe", 0
	dd 0x0000001d
	dd module.mazes_end-module.mazes
	db 0x00
	dw 0x0c
	db 0x01, 0x01, 0x0a, "mazes.exe", 0
	dd 0x0000001e
	dd 0x5000
	db 0x00
	dw 0x10
	db 0x01, 0x01, 0x0e, "wallpaper.spf", 0
disk.boot_end:
times 0x1 * 512 - ($ - $$) db 0
kernel.winver:
	dw 1000000000000000b
	db 10, 10, 55, 35
	dw kernel.winver_data-kernel.winver_title
	dw kernel.winver_title-kernel.winver
	dw kernel.winver_end-kernel.winver_text
	dw kernel.winver_text-kernel.winver
	dw kernel.winver_text-kernel.winver_data
	dw kernel.winver_data-kernel.winver
	dw 0, 0, 0
kernel.winver_title:
	db "About ELOS6.1"
kernel.winver_data:
	db "ELOS6.1", 0
	db "Enhanced Lightweight OS", 0
	db "Version: 6.1", 0
	db "Build: 2026.08.30", 0
	db "Architecture: IA-32", 0
	db "Copyright 2025-2026 @dgt2024", 0
	db "OK", 0
kernel.winver_text:
	pop esi
	pop esi
	mov ah, 0x00
	mov dx, 0x1301
	int 0x30
	mov ah, 0x00
	mov dx, 0x0a03
	int 0x30
	mov ah, 0x00
	mov dx, 0x0106
	int 0x30
	mov ah, 0x00
	mov dx, 0x0108
	int 0x30
	mov ah, 0x00
	mov dx, 0x010a
	int 0x30
	mov ah, 0x00
	mov dx, 0x010e
	int 0x30
	mov ah, 0x00
	mov dx, 0x1512
	int 0x30
	mov ah, 0x01
	mov dx, 0x1311
	mov bx, 0x0402
	int 0x30
	call kernel.winver_reg
	jmp $
kernel.winver_reg:
	push esi
	mov ah, 0xff
	mov si, kernel.winver_btn-kernel.winver_text
	int 0x30
	pop esi
	ret
kernel.winver_btn:
	mov ah, 0xfe
	int 0x30
	test al, 0x01
	jz kernel.winver_nook
	cmp dh, 0x13
	jb kernel.winver_nook
	cmp dl, 0x11
	jb kernel.winver_nook
	cmp dh, 0x19
	ja kernel.winver_nook
	cmp dl, 0x15
	ja kernel.winver_nook
	mov ah, 0xfd
	int 0x30
kernel.winver_nook:
	call kernel.winver_reg
	ret
kernel.winver_end:
times 0x2 * 512 - ($ - $$) db 0
kernel.exc_progn1:
	dw 1000000000000000b
	db 48, 56, 112, 73
	dw 0 ; size of title dependent
	dw kernel.exc_progn1_end-kernel.exc_progn1
	dw kernel.exc_progn1_end-kernel.exc_progn1_cs
	dw kernel.exc_progn1_cs-kernel.exc_progn1
	dw 0 ; size of data dependent
	dw 0 ; data offset dependent
	dw 0, 0, 0
kernel.exc_progn1_cs:
	pop esi
	pop esi
	push esi
	mov dx, 0x0202
	mov ah, 0x00
	int 0x30
	mov bx, 0x0402
	mov dx, 0x1d05
	mov ah, 0x01
	int 0x30
	pop esi
	mov dword[esi], "OK"
	mov dx, 0x1f06
	mov ah, 0x00
	int 0x30
	mov esi, kernel.exc_progn1_btn-kernel.exc_progn1_cs
	mov ah, 0xff
	int 0x30
	jmp $
kernel.exc_progn1_btn:
	mov ah, 0xfe
	int 0x30
	test al, 0x01
	jz kernel.exc_progn1_return
	cmp dh, 0x1d
	jb kernel.exc_progn1_return
	cmp dl, 0x05
	jb kernel.exc_progn1_return
	cmp dh, 0x23
	ja kernel.exc_progn1_return
	cmp dl, 0x09
	ja kernel.exc_progn1_return
	mov ah, 0xfd
	int 0x30
kernel.exc_progn1_return:
	mov esi, kernel.exc_progn1_btn-kernel.exc_progn1_cs
	mov ah, 0xff
	int 0x30
	ret
kernel.exc_progn1_end:
times 0x3 * 512 - ($ - $$) db 0
window.font:
	dd 000000000000000000000000000000b
	dd 000000000000000000000000000000b ; space
	dd 001000010000100001000010000100b
	dd 000000010000000000000000000000b ; ! / 0
	dd 010010100110010000000000000000b
	dd 000000000000000000000000000000b ; "
	dd 010100101011111010100101011111b
	dd 010100101000000000000000000000b ; #
	dd 001000111010100011100010100101b
	dd 011100010000000000000000000000b ; $
	dd 110011101000010001000010001000b
	dd 010111001100000000000000000000b ; %
	dd 011101000110000010001010010101b
	dd 100100110100000000000000000000b ; &
	dd 001000010000000000000000000000b
	dd 000000000000000000000000000000b ; '
	dd 000100010001000010000100001000b
	dd 001000001000000000000000000000b ; (
	dd 010000010000010000100001000010b
	dd 001000100000000000000000000000b ; )
	dd 010100010001010000000000000000b
	dd 000000000000000000000000000000b ; *
	dd 000000000000100001001111100100b
	dd 001000000000000000000000000000b ; +
	dd 000000000000000000000000000000b
	dd 011000110001000000000000000000b ; ,
	dd 000000000000000000000111000000b
	dd 000000000000000000000000000000b ; -
	dd 000000000000000000000000000000b
	dd 000000010000000000000000000000b ; .
	dd 000010001000010001000010001000b
	dd 010001000000000000000000000000b ; /
	dd 011101100110101100111000110001b
	dd 100010111000000000000000000000b ; 0
	dd 001000110010100001000010000100b
	dd 001001111100000000000000000000b ; 1
	dd 011101000100010001000100010000b
	dd 100001111100000000000000000000b ; 2
	dd 011101000100001001100000100001b
	dd 100010111000000000000000000000b ; 3
	dd 001010100110001111110000100001b
	dd 000010000100000000000000000000b ; 4
	dd 111111000010000111100000100001b
	dd 100010111000000000000000000000b ; 5
	dd 011101000110000111101000110001b
	dd 100010111000000000000000000000b ; 6
	dd 111110000100010001000010000100b
	dd 001000010000000000000000000000b ; 7
	dd 011101000110001011101000110001b
	dd 100010111000000000000000000000b ; 8
	dd 011101000110001011110000100001b
	dd 100010111000000000000000000000b ; 9
	dd 000000000000000000000010000000b
	dd 000000010000000000000000000000b ; :
	dd 000000000000000000000010000000b
	dd 000000010000100000000000000000b ; ;
	dd 000000000000000001110100010000b
	dd 010000011100000000000000000000b ; <
	dd 000000000000000000000111000000b
	dd 011100000000000000000000000000b ; =
	dd 000000000000000111000001000001b
	dd 000101110000000000000000000000b ; >
	dd 011101000100001000100010000100b
	dd 000000010000000000000000000000b ; ?
	dd 000000000011110000011110110101b
	dd 111010011000000000000000000000b ; @
	dd 011101000110001111111000110001b
	dd 100011000100000000000000000000b ; A
	dd 111101000110001111101000110001b
	dd 100011111000000000000000000000b ; B
	dd 011101000110000100001000010000b
	dd 100010111000000000000000000000b ; C
	dd 111101000110001100011000110001b
	dd 100011111000000000000000000000b ; D
	dd 111111000010000111101000010000b
	dd 100001111100000000000000000000b ; E
	dd 111111000010000111101000010000b
	dd 100001000000000000000000000000b ; F
	dd 011101000110000101101000110001b
	dd 100101110000000000000000000000b ; G
	dd 100011000110001111111000110001b
	dd 100011000100000000000000000000b ; H
	dd 111110010000100001000010000100b
	dd 001001111100000000000000000000b ; I
	dd 111110001000010000100001000010b
	dd 100100110000000000000000000000b ; J
	dd 100011001010100110001010010010b
	dd 100011000100000000000000000000b ; K
	dd 100001000010000100001000010000b
	dd 100001111100000000000000000000b ; L
	dd 100011101110101100011000110001b
	dd 100011000100000000000000000000b ; M
	dd 100011100110101100111000110001b
	dd 100011000100000000000000000000b ; N
	dd 011101000110001100011000110001b
	dd 100010111000000000000000000000b ; O
	dd 111101000110001111101000010000b
	dd 100001000000000000000000000000b ; P
	dd 011101000110001100011000110001b
	dd 100100110100000000000000000000b ; Q
	dd 111101000110001111101010010010b
	dd 100011000100000000000000000000b ; R
	dd 011101000110000011100000100001b
	dd 100010111000000000000000000000b ; S
	dd 111110010000100001000010000100b
	dd 001000010000000000000000000000b ; T
	dd 100011000110001100011000110001b
	dd 100010111000000000000000000000b ; U
	dd 100011000110001100011000110001b
	dd 010100010000000000000000000000b ; V
	dd 100011000110001100011000110101b
	dd 110111000100000000000000000000b ; W
	dd 100011000110001010100010001010b
	dd 100011000100000000000000000000b ; X
	dd 100011000110001010100010000100b
	dd 001000010000000000000000000000b ; Y
	dd 111110000100010001000100010000b
	dd 100001111100000000000000000000b ; Z
	dd 011100100001000010000100001000b
	dd 010000111000000000000000000000b ; [
	dd 100000100001000001000010000010b
	dd 000100000100000000000000000000b ; \
	
	dd 011100001000010000100001000010b
	dd 000100111000000000000000000000b ; ]
	dd 001000101010001000000000000000b
	dd 000000000000000000000000000000b ; ^
	dd 000000000000000000000000000000b
	;dd 0x00000016
;times 0x4 * 512 - ($ - $$) db 0
	dd 000001111100000000000000000000b ; _
	dd 010000010000010000000000000000b
	dd 000000000000000000000000000000b ; `
	dd 000000000000000011100000101111b
	dd 100010111100000000000000000000b ; a
	dd 000001000010000111101000110001b
	dd 100010111000000000000000000000b ; b
	dd 000000000000000011111000010000b
	dd 100000111100000000000000000000b ; c
	dd 000000000100001011111000110001b
	dd 100010111100000000000000000000b ; d
	dd 000000000000000011101000111110b
	dd 100000111000000000000000000000b ; e
	dd 000000000000000001100100101000b
	dd 010001110001000010000100000000b ; f
	dd 000000000000000011111000110001b
	dd 100010111100001000011000101110b ; g
	dd 000001000010000111101000110001b
	dd 100011000100000000000000000000b ; h
	dd 000000000000100000000010000100b
	dd 001000010000000000000000000000b ; i
	dd 000000000000010000000001000010b
	dd 000100001000010100100110000000b ; j
	dd 000001000010010101001100010100b
	dd 100101000100000000000000000000b ; k
	dd 000000010000100001000010000100b
	dd 001000001000000000000000000000b ; l
	dd 000000000000000110101010110101b
	dd 101011010100000000000000000000b ; m
	dd 000000000000000101101100110001b
	dd 100011000100000000000000000000b ; n
	dd 000000000000000011101000110001b
	dd 100010111000000000000000000000b ; o
	dd 000000000000000111101000110001b
	dd 100011111010000100001000010000b ; p
	dd 000000000000000011111000110001b
	dd 100010111100001001110000100001b ; q
	dd 000000000000000101111100010000b
	dd 100001000000000000000000000000b ; r
	dd 000000000000000011101000001110b
	dd 000010111000000000000000000000b ; s
	dd 000000000000000010001110001000b
	dd 010010011000000000000000000000b ; t
	dd 000000000000000100011000110001b
	dd 100010111100000000000000000000b ; u
	dd 000000000000000100011000110001b
	dd 010100010000000000000000000000b ; v
	dd 000000000000000100011000110001b
	dd 101010101100000000000000000000b ; w
	dd 000000000000000100010101000100b
	dd 010101000100000000000000000000b ; x
	dd 000000000000000100011000101010b
	dd 001000010000100101000100000000b ; y
	dd 000000000000000111110001000100b
	dd 010001111100000000000000000000b ; z
	dd 001100100101000110000100001000b
	dd 010010011000000000000000000000b ; {
	dd 001000010000100001000010000100b
	dd 001000010000100000000000000000b ; |
	dd 011001001000010000110001000010b
	dd 100100110000000000000000000000b ; }
	dd 000000000000000010011010110010b
	dd 000000000000000000000000000000b ; ~
window.font_end:
times 0x5 * 512 - ($ - $$) db 0
window.symbols_font:
	db 00000000b
	db 00000000b
	db 11111100b
	db 00000100b
	db 00001100b
	db 11111100b
	db 00111100b
	db 00111100b

	db 00000000b
	db 00000000b
	db 11111111b
	db 00000000b
	db 00000000b
	db 11111111b
	db 00000000b
	db 00000000b

	db 00000000b
	db 00000000b
	db 00111111b
	db 00100000b
	db 00100000b
	db 00100111b
	db 00100100b
	db 00100100b

	db 00111100b
	db 00111100b
	db 00111100b
	db 00111100b
	db 00111100b
	db 00111100b
	db 00111100b
	db 00111100b

	db 00100100b
	db 00100100b
	db 00100100b
	db 00100100b
	db 00100100b
	db 00100100b
	db 00100100b
	db 00100100b

	db 00111100b
	db 00111100b
	db 11111100b
	db 11111100b
	db 11111100b
	db 11111100b
	db 00000000b
	db 00000000b

	db 00000000b
	db 00000000b
	db 11111111b
	db 11111111b
	db 11111111b
	db 11111111b
	db 00000000b
	db 00000000b

	db 00100100b
	db 00100100b
	db 00100111b
	db 00101111b
	db 00111111b
	db 00111111b
	db 00000000b
	db 00000000b

	db 00000000b
	db 00000000b
	db 00000000b
	db 11111000b
	db 11111000b
	db 00011000b
	db 00011000b
	db 00011000b

	db 00000000b
	db 00000000b
	db 00000000b
	db 11111111b
	db 11111111b
	db 00000000b
	db 00000000b
	db 00000000b

	db 00000000b
	db 00000000b
	db 00000000b
	db 00011111b
	db 00011111b
	db 00011000b
	db 00011000b
	db 00011000b

	db 00011000b
	db 00011000b
	db 00011000b
	db 00011000b
	db 00011000b
	db 00011000b
	db 00011000b
	db 00011000b

	db 00011000b
	db 00011000b
	db 00011000b
	db 11111000b
	db 11111000b
	db 00000000b
	db 00000000b
	db 00000000b

	db 00011000b
	db 00011000b
	db 00011000b
	db 00011111b
	db 00011111b
	db 00000000b
	db 00000000b
	db 00000000b

	db 01111110b
	db 01000010b
	db 01000010b
	db 01000010b
	db 01000010b
	db 01000010b
	db 01000010b
	db 01111110b

	db 01111110b
	db 01000010b
	db 01011010b
	db 01011010b
	db 01011010b
	db 01011010b
	db 01000010b
	db 01111110b

	db 00011000b
	db 00111100b
	db 01111110b
	db 11111111b
	db 00011000b
	db 00011000b
	db 00011000b
	db 00011000b

	db 00001000b
	db 00001100b
	db 00001110b
	db 11111111b
	db 11111111b
	db 00001110b
	db 00001100b
	db 00001000b

	db 00010000b
	db 00110000b
	db 01110000b
	db 11111111b
	db 11111111b
	db 01110000b
	db 00110000b
	db 00010000b

	db 00011000b
	db 00011000b
	db 00011000b
	db 00011000b
	db 11111111b
	db 01111110b
	db 00111100b
	db 00011000b
window.symbols_font_end:
times 0x6 * 512 - ($ - $$) db 0
window.explorer:
	dw 1000000000000000b
	db 10, 10, 50, 50
	dw window.explorer_code-window.explorer_title
	dw window.explorer_title-window.explorer
	dw window.explorer_end-window.explorer_code
	dw window.explorer_code-window.explorer
	dw 0, 0, 0, 0, 0
window.explorer_title:
	db "Explorer"
window.explorer_code:
	mov ecx, 512
	mov ah, 0x40
	int 0x30
	push edi
	mov edx, 0
	mov ecx, 1
	mov ah, 0x42
	int 0x30
	mov edi, dword[esp]
	mov edx, dword[edi+0x1f6]
	mov ecx, dword[edi+0x1fa]
window.explorer_update:
	pushad
	mov ah, 0x04
	mov bl, 1
	int 0x30
	popad
	push ecx
	dec ecx
	shr ecx, 9
	inc ecx
	mov ah, 0x42
	int 0x30
	pop ebp
	mov edi, dword[esp]
	mov edx, 0x0101
	add ebp, edi
	push edi
window.explorer_print:
	push edi
	add edi, 12
	movzx ecx, byte[edi-1]
window.explorer_find_name:
	cmp byte[edi], 1
	jne window.explorer_next_prop
	movzx ecx, byte[edi+1]
	pushad
	add edi, 2
	mov esi, edi
	mov ah, 0x00
	int 0x30
	popad
	add dl, 2
window.explorer_hidden:
	pop edi
	movzx ebx, word[edi+9]
	lea edi, [edi+ebx+12]
	cmp edi, ebp
	jb window.explorer_print
	call window.explorer_unclick
	mov si, window.explorer_button-window.explorer_code
	mov ah, 0xff
	int 0x30
	jmp $
window.explorer_next_prop:
	movzx ebx, byte[edi]
	lea edi, [edx+edi+2]
	jmp window.explorer_find_name
window.explorer_button:
	mov ah, 0xfe
	int 0x30
	test al, 0x01
	jz window.explorer_skipbtn
	cmp dl, 4
	jbe window.explorer_skipbtn
	movzx ecx, dl
	sub ecx, 3
	shr ecx, 1
	jecxz window.explorer_direct
	mov edi, dword[esp+4]
window.explorer_loop:
	movzx edx, word[edi+9]
	lea edi, [edi+edx+12]
	cmp edi, ebp
	ja window.explorer_skipbtn
	loop window.explorer_loop
window.explorer_direct:
	pop eax
	mov edx, dword[edi]
	mov ecx, dword[edi+4]
	test byte[edi+8], 0x80
	mov edi, dword[esp]
	jz window.explorer_prog_start
	jmp window.explorer_update
window.explorer_skipbtn:
	call window.explorer_unclick
	mov si, window.explorer_button-window.explorer_code
	mov ah, 0xff
	int 0x30
	ret
window.explorer_prog_start:
	push edi
	dec ecx
	shr ecx, 9
	inc ecx
	mov ah, 0x42
	int 0x30
	pop edx
	mov ah, 0x43
	int 0x30
	mov ah, 0xfd
	int 0x30
window.explorer_unclick:
	pushad
	mov ah, 0xfc
	int 0x30
	mov ah, 0xfe
	int 0x30
	test al, 0x01
	popad
	jnz window.explorer_unclick
	ret
window.explorer_end:
times 0x7 * 512 - ($ - $$) db 0
module.notepad:
	dw 1000000000000000b
	db 8, 8, 58, 68
	dw module.notepad_code-module.notepad_title
	dw module.notepad_title-module.notepad
	dw module.notepad_end-module.notepad_code
	dw module.notepad_code-module.notepad
	dw 0, 0, 0, 0, 0
module.notepad_title:
	db "Notepad"
module.notepad_code:
	mov ecx, 512
	mov ah, 0x40
	int 0x30
	mov ebp, edi
module.notepad_retry:
	mov ah, 0xfc
	int 0x30
	xor ebx, ebx
	mov ah, 0xfb
	int 0x30
	cmp bh, 0x00
	je module.notepad_retry
	cmp bh, 0x7f
	je module.notepad_erase
	mov byte[edi], bh
	inc edi
module.notepad_aftererase:
	pushad
	mov esi, ebp
	mov dx, 0x0000
	mov ah, 0x00
	int 0x30
	popad
	movzx ecx, bl
module.notepad_wait:
	mov ebx, ecx
	mov ah, 0xfb
	int 0x30
	cmp bl, cl
	je module.notepad_wait
	jmp module.notepad_retry
module.notepad_erase:
	dec edi
	mov byte[edi], 0x20
	jmp module.notepad_aftererase
module.notepad_end:
times 0x8 * 512 - ($ - $$) db 0
module.tiny_cmd:
	dw 1000000000000000b
	db 12, 12, 52, 22
	dw module.tiny_cmd_data-module.tiny_cmd_title
	dw module.tiny_cmd_title-module.tiny_cmd
	dw module.tiny_cmd_end-module.tiny_cmd_code
	dw module.tiny_cmd_code-module.tiny_cmd
	dw module.tiny_cmd_code-module.tiny_cmd_data
	dw module.tiny_cmd_data-module.tiny_cmd
	dw 0, 0, 0
module.tiny_cmd_title:
	db "Tiny"
module.tiny_cmd_data:
	db "OK", 0
module.tiny_cmd_code:
	pop esi
	mov dx, 0x0101
	mov bx, 0x2402
	mov ah, 0x02
	int 0x30
	mov dx, 0x1105
	mov bx, 0x0402
	mov ah, 0x01
	int 0x30
	pop esi
	mov dx, 0x1306
	mov ah, 0x00
	int 0x30
	mov ah, 0x40
	mov ecx, 512
	int 0x30
	push edi
	mov ah, 0x40
	mov ecx, 16
	int 0x30
	mov ebp, edi
module.tiny_cmd_retry:
	mov ah, 0xfc
	int 0x30
	push esi
	mov ah, 0xfb
	int 0x30
	pop esi
	cmp bh, 0x7f
	je module.tiny_cmd_erase
	cmp bh, 0x00
	je module.tiny_cmd_retry
	cmp bh, 0x0d
	je module.tiny_cmd_handle
	mov byte[edi], bh
	inc edi
module.tiny_cmd_load:
	pushad
	mov dx, 0x0202
	mov esi, ebp
	mov ah, 0x00
	int 0x30
	popad
	push ecx
	mov ecx, ebx
module.tiny_cmd_wait:
	push esi
	mov ah, 0xfb
	int 0x30
	pop esi
	cmp bl, cl
	je module.tiny_cmd_wait
	pop ecx
	jmp module.tiny_cmd_retry
module.tiny_cmd_erase:
	dec edi
	mov byte[edi], 0x20
	jmp module.tiny_cmd_load
module.tiny_cmd_handle:
	mov al, byte[ebp]
	cmp al, '/'
	je module.tiny_cmd_root
	cmp al, 'r'
	je module.tiny_cmd_run
module.tiny_cmd_load_wr:
	pushad
	mov edi, ebp
	mov al, 0x20
	mov ecx, 16
	rep stosb
	mov dx, 0x0202
	mov esi, ebp
	mov ah, 0x00
	int 0x30
	popad
	mov edi, ebp
	jmp module.tiny_cmd_retry
module.tiny_cmd_root:
	mov edi, dword[esp]
	pushad
	xor edx, edx
	mov ecx, 1
	mov ah, 0x42
	int 0x30
	mov dword[esp+0x1c], eax
	popad
	cmp ah, 0x01
	je module.tiny_cmd_load_wr
	mov esi, dword[edi+0x1f6]
	mov ecx, dword[edi+0x1fa]
	jmp module.tiny_cmd_load_wr
module.tiny_cmd_run:
	push ecx
	mov edi, ebp
	mov ecx, 0xffffffff
	mov al, 0x20
	repne scasb
	mov byte[edi-1], 0
	pop ecx
	mov edx, dword[esp]
	mov ebx, esi
	mov esi, ebp
	inc esi
	mov ah, 0x44
	int 0x30
	cmp ah, 0x01
	je module.tiny_cmd_load_wr
	pop edx
	mov ah, 0x43
	int 0x30
	mov ah, 0xfd
	int 0x30
module.tiny_cmd_end:
times 0x9 * 512 - ($ - $$) db 0
module.debug:
	dw 1000000000000000b
	db 15, 15, 32, 37
	dw module.debug_data-module.debug_title
	dw module.debug_title-module.debug
	dw module.debug_end-module.debug_code
	dw module.debug_code-module.debug
	dw module.debug_code-module.debug_data
	dw module.debug_data-module.debug
	dw 0, 0, 0
module.debug_title:
	db "Debug Tool"
module.debug_data:
	db "EDI=", 0, "00000000", 0, "ESI=", 0, "00000000", 0, "EBP=", 0, "00000000", 0
	db "ESP=", 0, "00000000", 0, "EBX=", 0, "00000000", 0, "EDX=", 0, "00000000", 0
	db "ECX=", 0, "00000000", 0, "EAX=", 0, "00000000", 0, "EIP=", 0, "00000000", 0
module.debug_code:
	pop esi
	pop ebp
	mov ah, 0xff
	mov si, module.debug_int-module.debug_code
	int 0x30
module.dloop:
	mov ah, 0xfc
	int 0x30
	jmp module.dloop
module.debug_int:
	mov ah, 0xfb
	int 0x30
	cmp bh, 'r'
	jne module.wait_for_key
	mov esi, ebp
	mov ecx, 9
module.debug_loop:
	push ecx
	push edx
	push ebp
	mov dl, byte[esp+8]
	shl dl, 1
	mov dh, 0x01
	mov ah, 0x00
	int 0x30
	pop ebp
	push esi
	mov ecx, 8
	mov edi, esi
	mov edx, dword[esp+4]
	pushad
	push edx
	mov bl, 1
	mov ah, 0xf9
	int 0x30
	pop edx
	mov bl, al
	mov ah, 0xfa
	int 0x30
	mov dword[esp+0x10], eax
	popad
	mov ah, 0x80
	int 0x30
	pop esi
	push ebp
	mov dl, byte[esp+8]
	shl dl, 1
	mov dh, 0x05
	mov ah, 0x00
	int 0x30
	pop ebp
	pop edx
	pop ecx
	add edx, 4
	loop module.debug_loop
module.wait_for_key:
	mov ah, 0xfc
	int 0x30
	mov ah, 0xff
	mov si, module.debug_int-module.debug_code
	int 0x30
	ret
module.debug_end:
times 0xa * 512 - ($ - $$) db 0
module.mazes:
	dw 1000000000000000b
	db 20, 20, 65, 55
	dw module.mazes_data-module.mazes_title
	dw module.mazes_title-module.mazes
	dw module.mazes_end-module.mazes_code
	dw module.mazes_code-module.mazes
	dw module.mazes_code-module.mazes_data
	dw module.mazes_data-module.mazes
	dw 0, 0, 0
module.mazes_title:
	db "Lasers 'n Mazes - Lite Remake"
module.mazes_data:
	db 0x1f, 0x1c, 0x1c, 0x1c, 0x1f, 0x1c, 0x1f, 0x1f, 0x1f, 0x1c, 0x1f, 0x1f, 0x1f, 0x1c, 0x1f, 0x1f, 0x1f, 0x1c, 0x1c, 0x1f, 0x1f, 0
	db 0x1f, 0x1f, 0x1c, 0x1f, 0x1f, 0x1c, 0x1f, 0x1c, 0x1f, 0x1c, 0x1c, 0x1c, 0x1f, 0x1c, 0x1f, 0x1c, 0x1c, 0x1c, 0x1f, 0
	db 0x1f, 0x1c, 0x1f, 0x1c, 0x1f, 0x1c, 0x1f, 0x1f, 0x1f, 0x1c, 0x1c, 0x1f, 0x1c, 0x1c, 0x1f, 0x1f, 0x1f, 0x1c, 0x1c, 0x1f, 0
	db 0x1f, 0x1c, 0x1c, 0x1c, 0x1f, 0x1c, 0x1f, 0x1c, 0x1f, 0x1c, 0x1f, 0x1c, 0x1c, 0x1c, 0x1f, 0x1c, 0x1c, 0x1c, 0x1c, 0x1c, 0x1f, 0
	db 0x1f, 0x1c, 0x1c, 0x1c, 0x1f, 0x1c, 0x1f, 0x1c, 0x1f, 0x1c, 0x1f, 0x1f, 0x1f, 0x1c, 0x1f, 0x1f, 0x1f, 0x1c, 0x1f, 0x1f, 0
	db "Press any key to Start", 0
module.mazes_code:
	pop esi
	mov ah, 0x04
	mov bl, 0x19
	int 0x30
	mov ecx, 45*7
	mov ah, 0x05
	mov bl, 0x1c
	int 0x30
	mov esi, dword[esp]
	mov ecx, 5
	mov dx, 0x0101
module.mazes_start:
	push ecx
	push edx
	mov ah, 0x00
	int 0x30
	pop edx
	pop ecx
	inc dl
	loop module.mazes_start
	mov dx, 0x0208
	mov ah, 0x00
	int 0x30
module.mazes_poll:
	mov ah, 0xfc
	int 0x30
	mov ah, 0xfb
	int 0x30
	cmp bl, 0
	je module.mazes_poll
	call module.mazes_game
	jmp $
module.mazes_game:
	mov ah, 0x04
	mov bl, 0x1b
	int 0x30
	mov dx, 0x0303
module.mazes_fill:
	push edx
	mov bl, 0x10
	mov ah, 0x03
	int 0x30
	pop edx
	add dh, 2
	cmp dh, 21*2
	jb module.mazes_fill
	mov dh, 1
	add dl, 2
	cmp dl, 16*2
	jb module.mazes_fill
	mov ecx, 0x10101010
	mov edi, ecx
	mov dx, 0x0101
	mov bx, 0x291f
	mov ah, 0x06
	int 0x30
	
	ret
module.mazes_end:
times 0xb * 512 - ($ - $$) db 0
	incbin "wallpaper.spf"
times (0xb + 40) * 512 - ($ - $$) db 0
