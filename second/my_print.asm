extern ouputString

global sprint
global rsprint

section .data:

rc:     db  1Bh, '[33;31m', 0
.len    equ $ - rc

bc:     db  1Bh, '[30;0m', 0
.len    equ $ - bc

section .text


;------------------------------------------
; void sprint(String message)
; String printing function (Black)
sprint:
    push    edx
    push    ecx
    push    ebx
    push    eax
 
    mov     ebx, 1
    mov     eax, 4
    mov     ecx, bc
    mov     edx, bc.len
    int     80h
 
    call    realPrint

    pop     eax
    pop     ebx
    pop     ecx
    pop     edx
    ret

;------------------------------------------
; void rsprint(String message)
; String printing function (Red)
rsprint:
    push    edx
    push    ecx
    push    ebx
    push    eax

    mov     ebx, 1
    mov     eax, 4
    mov     ecx, rc
    mov     edx, rc.len
    int     80h
 
    call    realPrint

    pop     eax
    pop     ebx
    pop     ecx
    pop     edx

    ret

;---------------------------------------------
; void realPrint(string outputString)
; find the string and print it out;
; color has been set

realPrint:
    push    edx
    push    ecx
    push    ebx
    push    eax

    push    eax
    mov     eax, [ouputString]
    call    slen
    mov     edx, eax        // edx store the len
    pop     eax

    mov     ecx, eax
    mov     ebx, 1
    mov     eax, 4
    int     80h

    pop     eax
    pop     ebx
    pop     ecx
    pop     edx
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