%include	'functions.asm'
%include 	'memoryFunc.asm'
%include 	'functions1.asm'

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
minusAns:	RESB	255
num1:		RESB	255
num0:		RESB	255
string:		RESB	255
mul1:		RESB	255
mul2:		RESB 	255
transMul: 	RESB	255
sym1:		RESB 	2
sym2: 		RESB	2
plusAnsSym: RESB 	2
mulAnsSym:	RESB	2

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
	mov 	ebx, sym1
	call 	isNeg

	mov 	eax, stringy
	mov 	ebx, sym2
	call 	isNeg

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
	call 	bigNumPlus

	mov 	eax, plusAnsSym
	call 	printSym

	mov 	eax, plusAns
	call 	printNLF

	mov 	eax, numX
	mov		ebx, numY
	call 	bigNumMul

	mov 	eax, mulAnsSym
	call 	printSym

	mov 	eax, mulAns
	call 	printNLF

	call	quit

;--------------------------------------------------
; void bigNumPlus(numX, numY)
; if sym1 == sym2 , plusAns = numX + numY
; 

bigNumPlus:
	push 	ebx
	push 	eax
	
	xor 	eax, eax
	mov 	al, [sym1]
	
	xor 	ebx, ebx
	mov 	bl, [sym2]

	cmp 	eax, ebx
	jnz 	.symNotEqual

.symEqual:
	mov 	byte[plusAnsSym], al
	pop 	eax
	pop 	ebx
	call 	plus
	
	jmp 	.over

.symNotEqual:
	pop 	eax
	pop 	ebx

	push 	eax
	call 	Ncompare
	cmp 	eax, 1
	pop		eax
	jz  	.symIsX
	jg 		.symIsY

.symIsX:
	push 	eax
	xor 	eax, eax
	mov		al, [sym1]
	mov 	byte[plusAnsSym], al
	pop 	eax

	push 	ebx
	mov 	ebx, plusAns
	call 	memoryMove
	pop 	ebx

	mov 	eax, plusAns
	call 	minus

	jmp 	.over

.symIsY:
	push 	ebx
	xor 	ebx, ebx
	mov		bl, [sym2]
	mov 	byte[plusAnsSym], bl
	pop 	ebx

	push 	eax
	push 	ebx
	mov 	eax, ebx
	mov 	ebx, plusAns
	call 	memoryMove
	pop 	ebx
	pop 	eax

	mov 	ebx, eax
	mov 	eax, plusAns
	call 	minus

	jmp 	.over

.over:
	ret

;---------------------------------------------------
; void 	bigNumMul(numX, numY)
; if sym1 == sym2, or if numX==0 or numY==0, mulAnsSym = 0
; else = 1
bigNumMul:
	push 	ebx
	push 	eax


	xor 	eax, eax
	mov 	al, [sym1]

	xor 	ebx, ebx
	mov 	bl, [sym2]

	cmp 	eax, ebx
	jnz 	.symNotEqual
	jmp 	.mul
.symNotEqual:
	mov 	byte[mulAnsSym], 1
	jmp 	.mul


.mul:
	pop 	eax
	pop 	ebx
	call 	multiply

	push 	eax
	mov 	eax, mulAns
	call 	isZero
	cmp 	eax, 1
	pop 	eax
	jnz 	.over

	mov 	byte[mulAnsSym], 0

.over:

	ret
	



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























