; This is the source code for ELOS6
; Thank you for checking my code ;D
; TODO: add bugs to fix later
section .boot vstart=0x7c00
use16
boot.main:
	cli
	xor ax, ax
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov ss, ax
	mov sp, 0x7c00
	int 0x10
	mov ax, 0x020b
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
	mov cx, 0x20
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
times 506 - ($ - $$) db 0
dd 0
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
	dw boot.gdtend - boot.gdtdesc
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
	mov edx, kernel.test
	call scheduler.create
kernel.run:
	call scheduler.run
	jmp kernel.run
kernel.init:
	; video init
	mov edi, 0xf0000000
	mov ecx, 1280*1024
	mov eax, 0xffff
	rep stosd
	; memory init
	movzx cx, word[0x7308]
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
	; Set Up mouse
	mov word[0x7400], 640
	mov word[0x7402], 512
	; Interrupt create
	mov dword[0x1104], 0xc0008e00
	mov word[0x1102], 0x0008
	mov word[0x1100], scheduler.timer
	mov dword[0x1184], 0xc000ee00
	mov word[0x1182], 0x0008
	mov word[0x1180], window.service
	mov dword[0x110c], 0xc0008e00
	mov word[0x110a], 0x0008
	mov word[0x1108], ps2.keyboard
	mov dword[0x1164], 0xc0008e00
	mov word[0x1162], 0x0008
	mov word[0x1160], ps2.mouse
	lidt [0x7300]
	sti
	; Setup TSS
	mov dword[0x504], 0x7b00
	mov word[0x508], 0x10
	mov word[0x560], 0xffff
	mov ax, 0x28
	ltr ax
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
kernel.test:
	incbin "Build/program"
scheduler.run:
	mov esi, 0x2002c
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
	or eax, 0x1f
	mov dword[0x2100], eax
	mov dword[0x7320], esi
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
	sub dword[edi+0x24], 4
	mov eax, dword[edi+0x24]
	mov ebx, dword[edi+0x20]
	mov dword[eax], ebx
	movzx eax, word[edi+0x2e]
	add eax, 0x10002000
	mov dword[edi+0x20], eax
	mov word[edi+0x2e], 0
scheduler.no_button_prog:
	popad
	mov esi, dword[0x7320]
	mov al, byte[0x730a]
	cmp byte[0x7324], al
	mov al, 0x20
	out 0x20, al
	jae scheduler.run_end
	jmp scheduler.find_prog
scheduler.yield_return:
	push eax
	mov al, 0x20
	out 0x20, al
	pop eax
	iretd
scheduler.create:
	inc byte[0x730a]
	mov esi, 0x2001f
scheduler.find_space:
	lodsb
	add esi, 0x3f
	test al, 0x80
	jnz scheduler.find_space
	sub esi, 0x5f
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
	call memory.kmalloc ; Stack
	or di, 0x1f
	mov dword[0xe0000000], edi
	invlpg [0xe0000000]
	mov dword[0x90008], edi
	movzx ecx, word[edx+10]
	test ecx, ecx
	jz scheduler.end
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
	sub esi, 0xe0000000
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
	sub esi, 0xe0000000
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
	mov dword[esi+0x3c], ebp
	test byte[edx+1], 0x80
	jnz scheduler.window
	mov dword[esi+0x30], 0
scheduler.end:
	ret
scheduler.window:
	mov al, byte[edx+4]
	sub al, byte[edx+2]
	jc scheduler.end
	mov cl, byte[edx+5]
	sub cl, byte[edx+3]
	jc scheduler.end
	mul cl
	add cx, word[edx+8]
	add cx, 4
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
	invlpg [0xe0000000]
	mov edi, 0xe0000000
	push esi
	lea esi, [edx+2]
	movsd
	movzx ecx, word[edx+8]
	lea esi, [edx+ecx]
	movzx ecx, word[edx+6]
	rep movsb
	mov byte[edi], 0
	mov edi, 0x23ffc
	xor eax, eax
	mov ecx, 0xffffffff
	repne scasd
	pop esi
	mov dword[edi], esi
	mov esi, ebp
	call window.updatepointer
	ret
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
ps2.wait_for_input:
	in al, 0x64
	test al, 1
	jz ps2.wait_for_input
	ret
ps2.mouse:
	cli
	pushad
	push es
	push ds
	mov ax, 0x10
	mov es, ax
	mov ds, ax
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
	jo ps2.x_underflow
	cmp word[0x7400], 1280
	ja ps2.x_overflow
ps2.after_xflow:
	call ps2.wait_for_input
	in al, 0x60
	movsx ax, al
	sub word[0x7402], ax
	cmp word[0x7402], 16
	jb ps2.y_underflow
	cmp word[0x7402], 1024
	ja ps2.y_overflow
ps2.after_yflow:
	call window.mouse_update
ps2.skip:
	in al, 0x60
	in al, 0x64
	test al, 1
	jnz ps2.skip
	pop ds
	pop es
	mov al, 0x20
	out 0xa0, al
	out 0x20, al
	popad
	iretd
ps2.y_overflow:
	mov word[0x7402], 1024
	jmp ps2.after_yflow
ps2.y_underflow:
	mov word[0x7402], 16
	jmp ps2.after_yflow
ps2.x_overflow:
	mov word[0x7400], 0
	jmp ps2.after_xflow
ps2.x_underflow:
	mov word[0x7400], 1279
	jmp ps2.after_xflow
ps2.keyboard:
	pushad
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
	bts [0x7408], eax
	jmp ps2.after_walkrel
ps2.write_alkey_rel:
	btc [0x7408], eax
ps2.after_walkrel:
	mov al, 0x20
	out 0x20, al
	popad
	iretd
ps2.anormal_key:
	mov bl, 0x80
	in al, 0x60
	jmp ps2.after_ak
ps2.release_key:
	mov bh, 0x80
	in al, 0x60
	jmp ps2.after_rk
memory.kmalloc:
	mov edi, 0x10000
	mov ecx, 0x10000
	mov al, 0
	repne scasb
	mov byte[edi-1], bl
	sub edi, 0x10000
	shl edi, 12
	add edi, 0xff000
	ret
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
 	push eax
	call memory.kmalloc
	pop eax
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
window.window_moves:
	test byte[0x7404], 0x01
	jz window.after_wm
	pushad
	movzx edx, word[0x7400]
	shr edx, 3
	mov bh, dl
	movzx edx, word[0x7402]
	shr edx, 3
	mov bl, dl
	sub bx, word[0x7406]
	je window.after_wmpa
	xchg bh, bl
	mov ax, word[ecx]
	sub ah, 2
	mov word[0x7500], ax
	mov ax, word[ecx+2]
	mov word[0x7502], ax
	add byte[ecx], bl
	add byte[ecx+1], bh
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
	popad
	jmp window.after_wm
window.mouse_update:
	mov dx, word[0x7406]
	pushad
	call window.get_pid_by_coord
	test ebp, ebp
	jz window.set_pid_null
	cmp byte[ecx], dl
	jae window.window_moves
window.after_wm:
	mov eax, ebp
	sub eax, 0x1ffc0
	shr eax, 6
	mov byte[0x7405], al
window.after_null:
	popad
	sub dl, 2
	push dword[0x2100]
	pushad
	call window.updatetile
	popad
	inc dh
	pushad
	call window.updatetile
	popad
	dec dh
	inc dl
	pushad
	call window.updatetile
	popad
	inc dh
	pushad
	call window.updatetile
	popad
	pop dword[0x2100]
	movzx eax, word[0x7402]
	mul eax, 1280*4
	movzx ebx, word[0x7400]
	shl ebx, 2
	add eax, ebx
	add eax, 0xf0000000
	mov edi, eax
	mov ecx, 8
	mov eax, 0xff00ff
window.mouse_loop:
	mov edx, ecx
	mov ecx, 8
	push edi
	push eax
window.mouse_subloop:
	sub eax, 0x200020
	jc window.mouse_slend
	stosd
	loop window.mouse_subloop
window.mouse_slend:
	pop eax
	pop edi
	add edi, (1280)*4
	sub eax, 0x200020
	mov ecx, edx
	loop window.mouse_loop
	ret
window.set_pid_null:
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
window.service:
	; AH=0 PTREDIT
	; BH=NEW_X
	; BL=NEW_Y
	; AH=1 PRINT
	; ESI=STRING
	; ECX=STRLEN
	; AH=2 CreateButton
	; BH=SIZE_X(both inline)
	; BL=SIZE_Y
	cli
	cmp ah, 0
	je window.user_print
	cmp ah, 1
	je window.user_button
	cmp ah, 2
	je window.user_simple
	cmp ah, 0xfe
	je window.user_get_data
	cmp ah, 0xff
	je window.user_register
	iretd
window.user_get_data:
	mov al, byte[0x730b]
	cmp byte[0x7405], al
	je window.user_cgt
	mov al, byte[0x7404]
	mov dx, word[0x7406]
	mov edi, dword[0x7320]
	mov edi, dword[edi+0x30]
	sub dx, word[edi]
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
window.user_register:
	; at ESI is offset from starting addr
	mov edi, dword[0x7320]
	mov word[edi+0x2e], si
	iretd
window.user_wow:
	add esp, 4
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
	pop edi
	pop ecx
	pop edx
	push edx
	push ecx
	push edi
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
	ret
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
	push ecx
	mov ecx, 0xffffffff
	mov al, 0
	repne scasb
	pop ecx
	pop eax
	add edi, eax
	mov edx, ebp
	pop eax
	movzx ebx, bh
window.uprint_loop:
	push eax
	lodsb
	mov byte[edi], al
	or al, 0x80
	mov byte[edi+ebx], al
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
	mov ax, 0x23
	mov es, ax
	mov ds, ax
	popad
	inc dh
	loop window.uprint_loop
	iretd
window.get_pid_by_coord:
	mov bl, 0
	mov esi, 0x24000
	xor ebp, ebp
window.get_pid_loop:
	lodsd
	mov ecx, dword[eax+0x30]
	mov edi, dword[eax+0x34]
	mov dword[0x2100], edi
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
	cmp bl, byte[0x730a]
	jb window.get_pid_loop
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
	mul edi, 1280*8*4
	movzx edx, dh
	shl edx, 5
	add edi, edx
	add edi, 0xf0014000
	cmp al, ' '
	jb window.blank
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
	add esi, window.font
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
	pop edi
	movzx ecx, dh
	movzx edi, byte[edi+1]
	mul edi, 1280*8*4
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
	add esi, window.font
	pushad
	add edi, 1280*4*2+8
	mov edx, 0xffffff
	call window.nibble
	popad
	pushad
	add esi, 4
	add edi, 1280*4*8+4
	mov edx, 0xffffff
	call window.nibble
	popad
window.notext:
	pop edx
	ret
window.symbol:
	and al, 0x7f
	movzx esi, al
	shl esi, 3
	add esi, window.symbols_font
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
window.no_wnd:
	movzx edi, dl
	mul edi, 1280*8*4
	movzx edx, dh
	shl edx, 5
	add edi, edx
	add edi, 0xf0014000
	mov ecx, 8
	mov eax, 0x00ffff
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
	mov eax, 0xcccccc
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
	mov eax, 0xcccccc
window.ptr_loop:
	push ecx
	mov ecx, edx
	rep stosd
	pop ecx
	add edi, ebp
	loop window.ptr_loop
	pop ecx
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
	mov esi, window.font
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
	add edi, 4
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
	dd 010000010001000010000100001000b
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
	dd 011101000100001011110000100001b
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
	dd 000001111100000000000000000000b ; _
	dd 010000010000010000000000000000b
	dd 000000000000000000000000000000b ; `
	dd 000000000000000011100000101111b
	dd 100010111100000000000000000000b ; a
	dd 000001000010000111101000110001b
	dd 100010111000000000000000000000b ; b
	dd 000000000000000011101000110000b
	dd 100010111000000000000000000000b ; c
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
	dd 000100000100001000011000101110b ; z
	dd 001100100101000110000100001000b
	dd 010010011000000000000000000000b ; {
	dd 001000010000100001000010000100b
	dd 001000010000100000000000000000b ; |
	dd 011001001000010000110001000010b
	dd 100100110000000000000000000000b ; }
	dd 000000000000000010011010110010b
	dd 000000000000000000000000000000b ; ~