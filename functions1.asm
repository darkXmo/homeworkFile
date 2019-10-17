; tips: use this function, you need to import function.asm 

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

;--------------------------------------------
; void ifNeg(string A, Neg bool)
; if the string is started with "-", the Neg will be set to 1
; and the string will be shifted left
; else nothing will happen

isNeg:
	push 	eax
	push 	ebx

	xor 	ebx, ebx
	mov 	bl, [eax]
	cmp		bl, '-'
	jz	 	.yes

	jmp 	.over

.yes:
	pop 	ebx
	mov 	byte[ebx], 1
	push 	ebx

	call 	shiftLeft

.over:
	pop 	ebx
	pop 	eax
	ret

;----------------------------------------------
; void shiftLeft(string A)
; shift the string to left by one byte

shiftLeft:
	push 	eax
	push 	ebx
	push 	ecx
	
	mov 	ecx, 1
.loop:
	xor 	ebx, ebx
	mov 	bl, [eax+ecx]

	cmp 	bl, 0
	jz 		.over

	dec 	ecx
	mov 	byte[eax+ecx], bl
	inc 	ecx

	inc 	ecx
	jmp		.loop

.over:
	dec 	ecx
	mov 	byte[eax+ecx], 0

	pop 	ecx

	pop 	ebx
	pop 	eax
	ret

;----------------------------------------------
; void printSin(byte a)
; print a singlt byte(number)

printSin:
	push 	eax
	push 	ebx

	xor 	ebx, ebx
	mov 	bl, [eax]
	add 	bl, 48
	push 	ebx
	mov 	eax, esp
	call 	sprint
	pop 	ebx

	pop 	ebx
	pop 	eax
	ret

;----------------------------------------------
; void printSinC(byte a)
; print a singlt byte(char)

printSinC:
	push 	eax
	mov 	eax, esp
	call 	sprint


	pop 	eax
	ret
;-----------------------------------------------
; void printSinN(byte a)
; print a single byte(number, not in memory)

printSinN:
	push 	eax

	call 	iprint

	pop 	eax
	ret

;------------------------------------------------
; void printSym(Symbol)
; if 1, print -, else do nothing

printSym:
	push 	ebx

	xor 	ebx, ebx

	mov 	bl, [eax]
	cmp 	bl, 1
	jz 		.print

	jmp 	.over

.print:

	push 	eax
	xor 	eax, eax
	add 	eax, 45
	call 	printSinC
	pop 	eax

.over:
	pop 	ebx

	ret

;-------------------------------------------------
; void printN(Number n)
; print a number, end with 80

printN:
	push 	ebx
	push 	ecx

	push 	eax
	call 	nlen
	mov 	ecx, eax	;ecx store the len of number
	pop		eax

.loop:
	cmp 	ecx, 0
	jz 		.over

	dec 	ecx
	xor 	ebx, ebx
	mov 	bl, [eax+ecx]


	push 	eax
	mov 	eax, ebx
	call 	printSinN
	pop 	eax

	jmp 	.loop

.over:
	pop 	ecx
	pop 	ebx

	ret
;-------------------------------------------------
;	void printNLF(Number n)
;	print a number, end with 0Ah

printNLF:

	push 	eax
	call 	printN
	mov 	eax, 0Ah
	call 	printSinC
	pop 	eax
	ret

;-------------------------------------------------
; bool Ncompare(numX, numY)
; if numX > numY, return 1
; else if num < numY 
; else return 0 
; ans stored in eax

Ncompare:
	push 	ebx
	push 	ecx
	push 	edx

	push 	eax
	call 	nlen
	xor		ecx, ecx
	add 	ecx, eax  	; ecx store the len of numX
	pop 	eax


	push 	eax
	mov 	eax, ebx
	call 	nlen
	xor 	edx, edx
	add 	edx, eax 	; edx store the len of numY
	pop 	eax


	cmp		ecx, edx
	jl 		.return2
	jg 		.return1

.loop:
	cmp		ecx, 0
	jz 		.return0

	dec 	ecx

	xor 	edx, edx
	push 	ebx
	push 	eax


	mov 	dl, [ebx+ecx]
	xor 	ebx, ebx
	add 	ebx, edx 	; ebx store the No.[ebx] number of numY

	xor 	edx, edx
	mov 	dl, [eax+ecx]
	xor 	eax, eax
	add 	eax, edx	; eax store the No.[eax] number of numX

	cmp 	eax, ebx
	pop 	eax
	pop 	ebx
	jl 		.return2
	jg		.return1
	jmp		.loop


.return2:
	xor 	eax, eax
	mov 	eax, 2
	jmp 	.over

.return1:
	xor 	eax, eax
	mov 	eax, 1
	jmp 	.over

.return0:
	xor 	eax, eax
	mov 	eax, 0

.over:
	pop 	edx
	pop 	ecx
	pop 	ebx

	ret

;-----------------------------------------------------------------
; number minus(numX, numY)
; ans = numX - numY,
; numX should be greater than or equal to numY, else return 777 (7, 7, 7, 80, 12)
; the ans will be stored in memory numX

minus:
	push 	ebx
	push 	ecx
	push 	edx


	push 	eax
	call 	Ncompare
	cmp 	eax, 2
	jz		.return777
	cmp 	eax, 0
	jz 		.return0
	pop 	eax


	push 	eax
	mov 	eax, ebx
	call 	nlen
	mov 	ecx, eax 	;ecx store the len of ebx
	pop 	eax
	
	mov 	edx, 0
.loop:

	cmp 	ecx, 0
	jz 		.over
	dec 	ecx
	
	push 	ebx
	push 	eax

	xor 	edx, edx
	mov 	dl, [eax+ecx]
	mov 	eax, edx

	xor 	edx, edx
	mov 	dl, [ebx+ecx]
	mov 	ebx, edx

	cmp 	eax, ebx	;if the number less than ebx, it need lend ten from high level
	jl		.lendTen

.cal:

	sub 	eax, ebx
	mov 	edx, eax

	pop 	eax
	pop 	ebx

	mov 	byte[eax+ecx], dl

	jmp 	.loop
.lendTen:
	mov 	esi, ecx	;esi store ecx

	mov 	edx, eax 	;edx store eax
	pop 	eax			;get address beck to eax

	push 	ebx
.lendloop:
	inc 	ecx
	xor 	ebx, ebx
	mov 	bl, [eax+ecx]

	cmp 	bl, 0
	jnz 	.lendover
	mov 	byte[eax+ecx], 9
	jmp 	.lendloop


.lendover:
	dec 	bl
	mov 	byte[eax+ecx], bl
	
	pop 	ebx
	mov 	ecx, esi

	push 	eax

	add 	edx, 10
	mov 	eax, edx


	jmp 	.cal

.return777:
	pop 	eax
	call 	pushSeven
	jmp 	.over


.return0:
	pop 	eax
	call 	pushZero
	jmp 	.over

.over:
	pop 	edx
	pop 	ecx
	pop 	ebx

	call 	dez	

	ret

;-----------------------------------------------------------------
; number pushSeven(numX)
; push777 into a number Address, 777 means something goes wrong
; (7, 7, 7, 80, 10)

pushSeven:
	call 	memoryClear
	mov 	byte[eax], 7
	mov 	byte[eax+1], 7
	mov 	byte[eax+2], 7
	mov 	byte[eax+3], 80
	mov 	byte[eax+4], 10

	ret

;----------------------------------------------------------------
pushZero:
	call 	memoryClear
	mov 	byte[eax], 0
	mov 	byte[eax+1], 80

	ret




;--------------------------------------------
; void normalizeNum(Number num)
; normalize number

normalizeNum:
	push 	eax
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
	pop 	eax

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


