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
	mov byte[0x204100+edx*4], bl
	mov byte[0x204101+edx*4], cl
	shr ecx, 8
	mov word[0x204102+edx*4], cx

	inc byte[0x204052]

	clc
	ret

sendNotification_error:
	stc
	ret