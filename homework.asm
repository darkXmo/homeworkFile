%include	'functions.asm'

SECTION .data
msg1	db	'Please input x and y: ', 0h
msg2	db	0h, 1, 0h, 0h, 80, 0h
rightS 	db	'I am OK', 0h

SECTION .bss
sinput: 	RESB 	255
stringx:	RESB 	255
stringy:	RESB	255
numX: 		RESB	255
numY:		RESB	255
plusAns:	RESB	255
mulAns:		RESB	255
num1:		RESB	255
num0:		RESB	255
string:		RESB	255
output:		RESB	255
mul1:		RESB	255
mul2:		RESB 	255
transMul: 	RESB	255

SECTION .text
global	_start

_start:

	mov		eax, msg1
	call	sprint

    mov     edx, 255        ; read the x and y string
	mov     ecx, sinput     ;
	mov     ebx, 0          ;
	mov     eax, 3          ;
	int     80h

	mov		esi, sinput
	mov		eax, 0
	mov 	ecx, 0
	
storeXstring:
	xor		ebx, ebx
	mov		bl, [esi+ecx]
	cmp 	bl, 32
	jz	 	nextString
	
	mov 	byte[stringx+ecx], bl
	inc 	ecx

	jmp 	storeXstring

nextString:
	inc 	ecx

storeYstring:
	xor		ebx, ebx
	mov		bl, [esi+ecx]
	cmp 	bl, 0Ah
	jz	 	.storeFinished
	
	mov 	byte[stringy+eax], bl
	inc 	ecx
	inc 	eax

	jmp 	storeYstring


.storeFinished:
	mov 	eax, stringx
	call 	reverse

	mov 	eax, stringy
	call 	reverse

	mov		eax, stringx
	mov 	ebx, numX
	call 	ston


	mov 	eax, stringy
	mov 	ebx, numY
	call 	ston

.finished:
	
	mov 	eax, numX
	mov 	ebx, numY
	call 	plus

	mov 	eax, plusAns
	call 	printN

	mov 	eax, numX
	mov		ebx, numY
	call 	multiply

	mov 	eax, mulAns
	call 	printN

	call	quit


;--------------------------------------------------
;void reverse(string x)
;the string is stored in eax
;reverse the string
;this function will change the string{warning!}

reverse:
	push 	ecx
	push 	esi
	push 	ebx

	push 	eax
	call 	slen
	mov 	esi, eax 	;esi store the length of string
	pop		eax

	cmp		esi, 1
	jz 		.revOver

	mov 	ecx, 0
	dec 	esi


.revLoop:
	xor 	ebx, ebx
	mov 	bl, [eax+esi]
	mov		byte[string+ecx], bl
	inc 	ecx
	dec 	esi

	cmp 	esi, 0
	jz 		.putBack

	jmp 	.revLoop

.putBack:
	xor 	ebx, ebx
	mov 	bl, [eax+esi]
	mov 	byte[string+ecx], bl

	push 	eax
	mov 	eax, string
	pop 	ebx
	call 	memoryMove

	mov 	eax, string
	call 	memoryClear

.revOver:


	pop 	ebx
	pop		esi
	pop		ecx

	ret


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
	xor		ebx, ebx
	mov 	bl, [eax+ecx]
	cmp 	bl, 0
	jz 		.clearOver

	mov 	byte[eax+ecx], 0
	inc 	ecx
	jmp		.clearLoop

.clearOver:
	pop 	ebx
	pop 	ecx

	ret

;---------------------------------------------------
; void printN(memory a)
; reverse and print
; the string will be stored in string(indeed be deleted after print)

printN:
	push 	ecx
	push 	ebx

	mov 	ecx, 0

.printNLoop:
	xor 	ebx, ebx
	mov 	bl, [eax+ecx]
	cmp		bl, 80		;set 80 that is 'P' as the end
	jz 		.printNOver

	add 	bl, 48
	mov 	byte[output+ecx], bl
	inc 	ecx
	jmp 	.printNLoop


.printNOver:

	mov 	eax, output
	call 	reverse

	mov 	eax, output
	call 	sprintLF
	
	mov 	eax, output
	call 	memoryClear

	pop 	ebx
	pop		ecx

	ret

;-------------------------------------------------
; void ston(string a, memory b)
; make the number-string to number in memory b, end with 80
; 
ston:
	push 	ecx
	push 	ebx

	mov 	ecx, 0
	mov 	edx, ebx 		;move the address to edx

	push 	eax
	mov 	eax, edx
	call 	memoryClear
	pop		eax

.stonLoop:
	xor 	ebx, ebx
	mov 	bl, [eax+ecx]
	cmp		bl, 0
	jz 		.stonOver

	sub 	bl, 48
	mov 	byte[edx+ecx], bl
	inc 	ecx
	jmp 	.stonLoop

.stonOver:
	mov 	byte[edx+ecx], 80

	push 	eax
	mov 	eax, edx
	call 	normalizeNum
	pop 	eax

	pop 	ebx
	pop 	ecx

	ret


;------------------------------------------------
; void Plus(memory A, memory B)
; add A and B, the ans will be stored in plusAns, and the address will be stored in eax

plus:
	push	ecx
	push 	ebx
	push 	edx
	push 	esi

	mov		ecx, 0
	mov 	esi, 0

	push 	eax				;clear plusAns
	mov 	eax, plusAns
	call 	memoryClear
	pop		eax

	push 	eax				;clear num0
	mov		eax, num0
	call 	memoryClear
	pop 	eax
;----------------------------------------------------------------
	push 	eax

	call 	nlen
	mov 	ecx, eax		;ecx store the length of A

	mov 	eax, ebx
	call 	nlen
	mov 	edx, eax		;edx store the length of B

	pop 	eax
;---------------------------------------------------------------
	cmp 	ecx, edx		;if lenA is greater than lenB
	jg		.AtoplusAns		;move eax to plusAns

	jmp		.BtoplusAns		;else move ebx to plusAns

.AtoplusAns:
	push 	eax				;move eax to plusAns
	push 	ebx
	mov		ebx, plusAns
	call 	memoryMove
	pop 	ebx
	pop 	eax
	
	push 	eax				;move ebx to num0
	push 	ebx			
	mov 	eax, ebx
	mov 	ebx, num0
	call 	memoryMove
	pop 	ebx
	pop 	eax

	jmp		.beforeLoop


.BtoplusAns:
	push 	eax				;move ebx to plusAns
	push 	ebx
	mov 	eax, ebx
	mov 	ebx, plusAns
	call 	memoryMove
	pop 	ebx
	pop 	eax

	push 	eax				;move eax to num0
	push 	ebx
	mov		ebx, num0	
	call 	memoryMove
	pop 	ebx
	pop 	eax

	jmp		.beforeLoop

.beforeLoop:
	mov 	ecx, 0

.plusLoop:
	xor		ebx, ebx
	mov 	bl, [num0+ecx]

	cmp 	bl, 80
	jz		.plusFinished

	xor 	eax, eax
	mov 	al, [plusAns+ecx]
	add 	eax, ebx
	mov 	byte[plusAns+ecx], al
	inc 	ecx
	jmp 	.plusLoop

.plusFinished:
	mov 	eax, plusAns
	call 	normalizeNum

	mov 	eax, num0
	call 	memoryClear

	pop 	esi
	pop 	edx
	pop 	ebx
	pop 	ecx

	ret

;--------------------------------------------
; void normalizeNum(Number num)
; normalize number

normalizeNum:
	push 	ebx
	push 	ecx
	push 	edx

	mov		ecx, 0

.normalLoop:

	xor 	ebx, ebx
	mov		bl, [eax+ecx]
	cmp 	bl, 80
	jz 		.normalOver

	cmp 	bl, 10
	jl		.noChange

	xor 	edx, edx
	inc 	ecx
	mov 	dl, [eax+ecx]		;dl stored the next number

	cmp 	dl, 80
	jnz		.noLonger

	mov 	byte[eax+ecx], 0	;if next number is 80, change it to 0
	mov 	edx, 0
	inc 	ecx
	mov 	byte[eax+ecx], 80	;then change next next number to 80
	dec		ecx

.noLonger:
	inc		dl					;next number ++
	mov 	byte[eax+ecx], dl	;put it back

	dec		ecx
	sub		bl, 10

	mov		byte[eax+ecx], bl

.noChange:
	inc 	ecx
	jmp		.normalLoop

.normalOver:
	push 	eax
	call 	dez
	pop 	eax

	pop 	edx
	pop		ecx
	pop 	ebx

	ret

;--------------------------------------------------------
;	number Dez(memory A)
;	Delete end zero

dez:
	push 	ebx
	push 	ecx
	
	push 	eax
	call 	nlen
	mov 	ecx, eax
	dec 	ecx
	pop 	eax

.dezLoop:
	cmp		ecx, 0
	jz	 	.dezOver


	xor 	ebx, ebx
	mov 	bl, [eax+ecx]
	cmp 	bl, 0
	jnz 	.dezOver

	mov 	byte[eax+ecx], 80
	inc 	ecx
	mov 	byte[eax+ecx], 0
	sub		ecx, 2

	jmp 	.dezLoop

.dezOver:
	pop 	ecx
	pop 	ebx

	ret

;--------------------------------------------------------
;	number multplyBy10(memory A)
;	multply itself By10 
;	use num0 as transition


multiplyBy10:
	push 	ebx
	push 	ecx

	mov 	ecx, 0


.mult10Loop:
	xor 	ebx, ebx
	mov 	bl, [eax+ecx]		; bl store eax byte
	inc 	ecx
	mov 	byte[num0+ecx], bl	;num
	
	cmp		bl, 80
	jz 		.mult10Back

	jmp 	.mult10Loop

.mult10Back:
	push 	eax					;push num0 to eax
	push 	ebx
	mov 	ebx, eax
	mov 	eax, num0
	call 	memoryMove
	pop 	ebx
	pop 	eax

	push 	eax
	mov 	eax, num0
	call 	memoryClear
	pop		eax

.mult10Over:
	push 	eax
	call 	dez
	pop 	eax

	pop 	ecx
	pop 	ebx

	ret


;-------------------------------------------------------------
; number auto(memory A, int B)
; auto myself by B times
; the number should be less than 10
; the number shoule be greayer than 0 (B will be 1 if it's not)

auto:

	push 	esi

	mov 	esi, ebx
	dec 	esi

	push 	eax
	push 	ebx
	mov 	ebx, num1
	call 	memoryMove
	pop 	ebx
	pop 	eax

.autoLoop:
	cmp 	esi, 0
	jz 		.autoOver

	push	eax
	push 	ebx
	mov		ebx, num1
	call 	plus
	pop 	ebx
	pop 	eax

	push 	eax
	push 	ebx
	mov 	ebx, eax
	mov 	eax, plusAns
	call 	memoryMove
	pop 	ebx
	pop 	eax

	dec 	esi
	jmp 	.autoLoop


.autoOver:
	pop 	esi

	ret

;--------------------------------------------------
; void multiply(number A, number B)
; multiply A and B
; the ans will be stored in mulAns 

multiply:

	push 	ecx

	mov 	ecx, 0

	push 	eax					;clear mulAns
	mov 	eax, mulAns
	call 	memoryClear
	pop 	eax

	mov 	byte[mulAns], 0		;mulAns = 0
	mov 	byte[mulAns+1], 80


	push 	eax					;if number A == 0, over
	call 	isZero
	cmp 	eax, 1
	jz		.over0
	pop 	eax

	push 	eax					;if number B == 0, over
	mov 	eax, ebx
	call 	isZero
	cmp		eax, 1
	jz		.over0
	pop 	eax

	push 	eax					;move number A to mul1
	push 	ebx
	mov 	ebx, mul1
	call 	memoryMove
	pop 	ebx
	pop 	eax

	push 	eax					;move number B to mul2
	push 	ebx
	mov 	eax, ebx
	mov 	ebx, mul2
	call 	memoryMove
	pop 	ebx
	pop 	eax

.Loop:


	xor 	ebx, ebx			;if number == 0, no plus, pass
	mov 	bl, [mul2+ecx]		;bl store a number
	cmp		bl, 80				;if number == 80, over
	jz 		.over
	cmp 	bl, 0
	jz 		.pass




	push 	eax					;copy mul1 to transMul
	push 	ebx
	mov 	eax, mul1
	mov 	ebx, transMul
	call 	memoryMove
	pop 	ebx
	pop 	eax


	push 	eax					;auto transMul by bl
	push 	ebx
	mov 	eax, transMul
	call 	auto
	pop 	ebx
	pop 	eax

	push 	eax					;transMul plus mulAns
	push 	ebx	
	mov 	eax, transMul
	mov 	ebx, mulAns
	call 	plus
	mov 	eax, plusAns		;move plusAns to mulAns
	mov		ebx, mulAns
	call 	memoryMove
	pop 	ebx
	pop 	eax

.pass:
	inc		ecx					;ecx ++
	
	push 	eax					;mul1 *= 10
	mov 	eax, mul1
	call 	multiplyBy10
	pop 	eax


	jmp 	.Loop

.over0:
	pop 	eax

.over:
	
	pop 	ecx

	ret




;--------------------------------------------------
; bool isZero(number A)
; if A is equal to zero, return 1, else return 0

isZero:

	push	ebx

	xor 	ebx, ebx
	mov 	bl, [eax+1]
	cmp 	bl, 80
	jnz 	.return0

	xor 	ebx, ebx
	mov		bl, [eax]
	cmp		bl, 0
	jnz 	.return0

.return1:
	mov 	eax, 1
	jmp 	.over

.return0:
	mov 	eax, 0

.over:
	pop 	ebx

	ret
























