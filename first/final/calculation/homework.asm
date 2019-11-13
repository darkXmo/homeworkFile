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


;------------------------------------------
; int slen(String message)
; String length calculation function
slen:
    push    ebx
    mov     ebx, eax
 
nextchar:
    cmp     byte [eax], 0
    jz      finished
    inc     eax
    jmp     nextchar
 
finished:
    sub     eax, ebx
    pop     ebx
    ret

;------------------------------------------
; int nlen(number n)
; number length calculation function
nlen:
	push 	ebx
	mov 	ebx, eax

.nextchar:
	cmp 	byte [eax], 80
	jz		finished
	inc 	eax
	jmp 	.nextchar

;------------------------------------------
; void sprint(String message)
; String printing function
sprint:
    push    edx
    push    ecx
    push    ebx
    push    eax
    call    slen
 
    mov     edx, eax
    pop     eax
 
    mov     ecx, eax
    mov     ebx, 1
    mov     eax, 4
    int     80h
 
    pop     ebx
    pop     ecx
    pop     edx
    ret

sprintLF:
    call    sprint

    push    eax
    mov     eax, 0Ah
    push    eax
    mov     eax, esp
    call    sprint
    pop     eax
    pop     eax
    ret


;------------------------------------------
; void iprint(Integer number)
; Integer printing function (itoa)
iprint:
    push    eax
    push    ecx
    push    edx
    push    esi
    mov     ecx, 0

divideLoop:
    inc     ecx
	mov		edx, 0
	mov		esi, 10
	idiv 	esi
	add		edx, 48
	push 	edx
	cmp		eax, 0
	jnz		divideLoop

printLoop:
	dec		ecx
	mov		eax, esp
	call  	sprint
	pop 	eax
	cmp 	ecx, 0
	jnz 	printLoop

	pop 	esi
	pop 	edx
	pop 	ecx
	pop 	eax
	ret

;------------------------------------------
; void iprintLF(Integer number)
; Integer printing function with linefeed (itoa)
iprintLF:
	call 	iprint

	push	eax
	mov		eax, 0Ah
	push 	eax
	mov		eax, esp
	call	sprint
	pop  	eax
	pop 	eax
	ret

;------------------------------------------
; int atoi(Integer number)
; Ascii to integer function (atoi)
atoi:
	push 	ebx
	push 	ecx
	push 	edx
	push 	esi
	mov 	esi, eax
	mov 	eax, 0
	mov 	ecx, 0


.multiplyLoop:
	xor		ebx, ebx
	mov 	bl, [esi+ecx]
	cmp		bl, 48
	jl		.finished
	cmp		bl, 57
	jg 		.finished

	sub 	bl, 48
	add		eax, ebx
	mov 	ebx, 10
	mul 	ebx
	inc 	ecx
	jmp 	.multiplyLoop

.finished:
	mov 	ebx, 10
	div 	ebx
	pop 	esi 
	pop 	edx
	pop 	ecx
	pop 	ebx
	ret


;------------------------------------------
; void exit()
; Exit program and restore resources
quit:
    mov     ebx, 0
    mov     eax, 1
    int     80h
    ret


;------------------------------------------
; void printw()
; Print a single word
wprint:
	push	eax
	mov 	eax, esp
	call 	sprint
	pop 	eax

	ret


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


