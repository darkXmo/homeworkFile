;----------------------------------------------
; void memoryMove(memory a, memory b)
; eax store the data need to pushed
; ebx store the memory that need be pushed in
; it is same to 'push A to B'
memoryMove:

	push 	ecx
	push 	ebx
	push 	edx

	push 	eax			;clear memoryB at first
	mov 	eax, ebx
	call 	memoryClear
	pop 	eax

	mov 	edx, ebx	;move the address in ebx to edx
	mov 	ecx, 0


.moveLoop:
	xor 	ebx, ebx
	mov 	bl, [eax+ecx]
	mov 	byte[edx+ecx], bl
	cmp 	ecx, 254
	jz 		.moveOver

	inc 	ecx
	jmp 	.moveLoop

.moveOver:
	pop 	edx
	pop 	ebx
	pop 	ecx

	ret

;--------------------------------------------------
; void memoryClear(memory a)
; clear the memory(make it all '0')

memoryClear:
	push 	ecx
	push 	ebx

	mov 	ecx, 0

.clearLoop:

	cmp 	ecx, 255
	jz 		.clearOver

	mov 	byte[eax+ecx], 0
	inc 	ecx
	jmp		.clearLoop

.clearOver:
	pop 	ebx
	pop 	ecx

	ret

