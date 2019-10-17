%include	'functions.asm'
%include 	'memoryFunc.asm'
%include 	'functions1.asm'

SECTION .data
msg1	db	'Please input x and y: ', 0h
msg2	db	0h, 1, 0h, 0h, 80, 0h
string1 db  '-1102875642', 0h
rightS 	db	'I am OK', 0h
sym 	db  '-', 0h
num1 	db	7, 7, 1, 80, 0h
num2 	db 	7, 7, 1, 80, 0h

SECTION .bss
sym1 	RESB 	2
Cal1	RESB 	255
Cal2 	RESB	255

SECTION .text
global	_start

_start:

	mov 	byte[Cal1], 2
	mov 	byte[Cal1+1], 0
	mov 	byte[Cal1+2], 1
	mov 	byte[Cal1+3], 80
	mov 	byte[Cal2], 0
	mov 	byte[Cal2+1], 80 

	mov 	eax, Cal1
	call 	printNLF

	mov 	eax, Cal2
	call 	printNLF


	call 	isZero
	call 	printSinN

	mov 	eax, Cal1
	mov 	ebx, Cal2
	call 	minus

	call 	printNLF

	call	quit



