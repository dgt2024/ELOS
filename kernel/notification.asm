sendNotification:
	call getRawContainer
	jc sendNotification_error

	or dx, 0x0003
	mov dword[0x4020], edx

	mov edx, 0x204000 ; map here
	int 0x30

	cmp byte[0x204052], 0x40
	jae sendNotification_error

	movzx edx, byte[0x204052]
	mov dword[0x204100+edx*4], ecx
	mov byte[0x204103+edx*4], bl

	inc byte[0x204052]

	or byte[0x204030], 0x02
	clc
	ret

sendNotification_error:
	stc
	ret

sendNotification_c:
	cli
	jmp $

readNotification:
	cmp byte[0x200052], 0
	je readNotification_none

	mov ecx, dword[0x200100]
	mov bl, byte[0x200103]

	and ecx, 0x00ffffff

	push ecx
	movzx ecx, byte[0x200052]
	mov edi, 0x200100
	mov esi, 0x200104
	rep movsd
	pop ecx

	dec byte[0x200052]
	clc
	ret

readNotification_none:
	stc
	ret
