AStack	SEGMENT	STACK
    db	512	dup(0)
AStack ENDS

DATA SEGMENT
	PARAMETER dw ? 
	dd ? 
	dd ? 
	dd ? 
	ERROR_MEM_7 db 13, 10,'MCB destroyed',13,10,'$'
	ERROR_MEM_8 db 13, 10,'Not enough memory',13,10,'$'
	ERROR_MEM_9 db 13, 10,'Wrong address',13,10,'$'
	ERROR_LOAD_1 db 13, 10,'Number of function is wrong',13,10,'$'
	ERROR_LOAD_2 db 13, 10,'File not found',13,10,'$'
	ERROR_LOAD_5 db 13, 10,'Disk error',13,10,'$'
	ERROR_LOAD_8 db 13, 10,'Insufficient value of memory',13,10,'$'
	ERROR_LOAD_10 db 13, 10,'Incorrect environment string',13,10,'$'
	ERROR_LOAD_11 db 13, 10,'Wrong format',13,10,'$'
	NORMAL db 13, 10,'Normal termination',13,10,'$'
	CTRL db 13, 10,'Ended by Ctrl-Break',13,10,'$'
	DEVICE_ERROR db 13, 10,'Ended with device error',13,10,'$'
	END_31H db 13, 10,'Ended by 31h',13,10,'$'
	PATH db '                                               ',13,10,'$',0
	KEEP_SS dw 0
	KEEP_SP dw 0
	END_CODE db 'End code:   ',13,10,'$'
DATA ENDS
DUM_SEGMENT SEGMENT
DUM_SEGMENT ENDS

CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, ES:NOTHING, SS:AStack

TETR_TO_HEX PROC near
    and AL,0Fh
    cmp AL,09
    jbe NEXT
    add AL,07
    NEXT: add AL,30h
    ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near
    push CX
    mov AH,AL
    call TETR_TO_HEX
    xchg AL,AH
    mov CL,4
    shr AL,CL
    call TETR_TO_HEX
    pop CX
    ret
BYTE_TO_HEX ENDP

WRITE_STRING PROC near
    push AX
    mov AH, 09H
    int 21H
    pop AX
    ret
WRITE_STRING ENDP

FREE PROC 
    mov BX,offset DUM_SEGMENT
    mov AX, ES 
    sub BX, AX
    mov CL, 4H
    shr BX, CL
    mov AH, 4AH 
    int 21H
    jnc GOOD 
    cmp AX, 7 
    mov DX, offset ERROR_MEM_7
    je  HAVE_ERROR
    cmp AX, 8 
    mov DX, offset ERROR_MEM_8
    je HAVE_ERROR
    cmp AX, 9 
    mov DX, offset ERROR_MEM_9
HAVE_ERROR:
    call WRITE_STRING 
    xor AL,AL
    mov AH,4CH
    int 21H
GOOD:
    mov AX, ES
    mov PARAMETER, 0
    mov PARAMETER+2, AX 
    mov PARAMETER+4, 80H 
    mov PARAMETER+6, AX 
    mov PARAMETER+8, 5CH 
    mov PARAMETER+10, AX 
    mov PARAMETER+12, 6CH
    ret
FREE ENDP

RUN_P PROC 	NEAR
    mov ES, ES:[2Ch]
    mov SI, 0
ENV:
    mov DL, ES:[SI]
    cmp DL, 00H    
    je EOL
    inc SI
    jmp ENV
EOL:
    inc SI
    mov DL, ES:[SI]
    cmp DL, 00H    
    jne ENV
    add SI, 03H	
    push DI
    lea DI, PATH
G_PATH:
    mov DL, ES:[SI]
    cmp DL, 00H   
    je EOL_2	
    mov [DI], DL	
    inc DI    	
    inc SI    	
    jmp G_PATH
EOL_2:
    sub DI, 7	
    mov [DI], byte ptr 'L'
    mov [DI+1], byte ptr 'R'	
    mov [DI+2], byte ptr '2'
    mov [DI+3], byte ptr '.'
    mov [DI+4], byte ptr 'C'
    mov [DI+5], byte ptr 'O'
    mov [DI+6], byte ptr 'M'
    mov [DI+7], byte ptr 0H
    pop DI
    mov KEEP_SP, SP
    mov KEEP_SS, SS
    push DS
    pop ES 
    mov BX, offset PARAMETER
    mov DX, offset PATH
    mov	AX, 4B00H
    int 21H
    jnc IS_LOADED 
    push AX
    mov AX, DATA
    mov DS, AX
    pop AX
    mov SS, KEEP_SS
    mov SP, KEEP_SP
    cmp AX, 1 
    mov DX,offset ERROR_LOAD_1
    je END_ERROR
    cmp AX, 2 
    mov DX,offset ERROR_LOAD_2
    je  END_ERROR
    cmp AX, 5 
    mov DX,offset ERROR_LOAD_5
    je END_ERROR
    cmp AX, 8 
    mov DX,offset ERROR_LOAD_8
    je END_ERROR
    cmp AX, 10 
    mov DX,offset ERROR_LOAD_10
    je END_ERROR
    cmp AX, 11 
    mov DX,offset ERROR_LOAD_11
END_ERROR:
    call WRITE_STRING
    xor AL, AL
    mov AH, 4CH
    int 21H
IS_LOADED: 
    mov AX, 4D00H 
    int 21H
    cmp AH, 0 
    mov DX, offset NORMAL
    je END_RUN
    cmp AH, 1 
    mov DX, offset CTRL
    je END_RUN
    cmp AH,2 
    mov DX, offset DEVICE_ERROR
    je END_RUN
    cmp AH, 3 
    mov DX, offset END_31H
END_RUN:
    call WRITE_STRING
    mov DI, offset END_CODE
    call BYTE_TO_HEX
    add DI, 0AH
    mov [DI], AL
    add DI, 1
    xchg AH, AL
    mov [DI], AL
    mov DX, offset END_CODE
    call WRITE_STRING
    ret
RUN_P ENDP

MAIN PROC NEAR
	mov AX, DATA
	mov DS, AX
	call FREE
	call RUN_P
	mov AX, 4C00H
	int 21H
	ret
LAST_BYTE:
MAIN ENDP
CODE ENDS
    END MAIN