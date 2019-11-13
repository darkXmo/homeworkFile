extern out

global prints  
global printred

section .data:
      
color_red:       db      1Bh, '[33;31m', 0
.len    equ     $ - color_red
color_black:       db      1Bh, '[30;0m', 0
.len    equ     $ - color_black

section .text
 

  
slen: ;must be stored in the way of ascii ,eax save the address of the string to be caculated                   
    push    ebx            
    mov     ebx, eax        
 
nextchar:                   
    cmp     byte [eax], 0
    jz      finished
    inc     eax
    jmp     nextchar
 
finished:
    sub     eax, ebx
    pop     ebx             ; pop the value on the stack back into EBX
    ret     ;eax save the length of the string
;end of strlen

printred:

    push    edx
    push    ecx
    push    ebx
    push    eax

    mov     eax, 4                 ; 系统调用号为4
    mov     ebx, 1                  
    mov     ecx, color_red
    mov     edx, color_red.len
    int     80h

    call printsred
    
    pop     eax
    pop     ebx
    pop     ecx
    pop     edx
    ret   
   
prints:; print the string(ite address save in the eax)
    push    edx
    push    ecx
    push    ebx
    push    eax

    mov     eax, 4                 ; 系统调用号为4
    mov     ebx, 1                  
    mov     ecx, color_black
    mov     edx, color_black.len
    int     80h
            
    call printsred
    pop     eax
    pop     ebx
    pop     ecx
    pop     edx
    ret   
;end of spring

printsred:; print the string(ite address save in the eax)
    mov     eax,[out]
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
;end of spring
