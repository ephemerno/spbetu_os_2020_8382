LR2 SEGMENT
ASSUME CS:LR2, DS:LR2, ES:NOTHING, SS:NOTHING
ORG 100H
START: JMP BEGIN
ENTER db 13, 10, '$'
LOCKMEMORY db 'Locked memory addres: $'
ENVIROMENT db 'Enviroment addres: $'
TAIL db 'Command line tail: $'
NO_TAIL db 'is not command line tail $'
ENVIROMENT_CONTENT db 'Enviroment content: $'
PATH db 'Path: $'
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

WRITE_SYMBOL PROC near
    push AX
    mov AH, 02H
    int 21H
    pop AX
    ret
WRITE_SYMBOL ENDP

WRITE_STRING PROC near
    push AX
    mov AH, 09H
    int 21H
    pop AX
    ret
WRITE_STRING ENDP

WRITE_HEX PROC near
    push AX
    mov AL, AH
    call BYTE_TO_HEX
    mov DL, AH
    call WRITE_SYMBOL
    mov DL, AL
    call WRITE_SYMBOL
    pop AX
    call BYTE_TO_HEX
    mov DL, AH
    call WRITE_SYMBOL
    mov DL, AL
    call WRITE_SYMBOL
    ret
WRITE_HEX ENDP

WRITE_LOCKMEMORY PROC near
    push AX
    push DX
    mov DX, offset LOCKMEMORY
    call WRITE_STRING
    mov AX, DS:[02H]
    call WRITE_HEX
    mov DX, offset ENTER
    call WRITE_STRING
    pop DX
    pop AX
    ret
WRITE_LOCKMEMORY ENDP

WRITE_ENVIROMENT PROC near 
    push AX
    push DX
    mov DX, offset ENVIROMENT
    call WRITE_STRING
    mov AX, DS:[2CH]
    call WRITE_HEX
    mov DX, offset ENTER
    call WRITE_STRING
    pop DX
    pop AX
    ret
WRITE_ENVIROMENT ENDP

WRITE_TAIL PROC near 
    push AX
    push SI
    push CX
    push DX
    mov DX, offset TAIL
    call WRITE_STRING
    xor CX, CX
    mov CL, DS:[80H]
    cmp CL, 0
    jne RETAIL
    mov DX, offset NO_TAIL
    call WRITE_STRING
    jmp POPING_TAIL
RETAIL:
    xor SI, SI
    xor AX, AX
WRITING_TAIL:
    mov AL, DS:[81H + SI]
	call WRITE_SYMBOL
	inc SI
	loop WRITING_TAIL
POPING_TAIL:
    mov DX, offset ENTER
    call WRITE_STRING
    pop DX
    pop CX
    pop SI
    pop AX
    ret
WRITE_TAIL ENDP

WRITE_ENVIROMENT_CONTENT_AND_PATH PROC near 
    push AX
    push SI
    push DX
    push BX
    push ES
    mov DX, offset ENVIROMENT_CONTENT
    call WRITE_STRING
    xor SI, SI
	mov BX, 2CH
	mov ES, [BX]
WRITING_CONTENT:
	cmp BYTE PTR ES:[SI], 0H
	je NEXT_CONTENT
	mov AL, ES:[SI]
    mov DL, AL
	call WRITE_SYMBOL
	jmp CHECKING
NEXT_CONTENT:
	mov DX, offset ENTER
	call WRITE_STRING
CHECKING:
	inc SI
	cmp WORD PTR ES:[SI], 0001H
    je WRITE_PATH
	jmp WRITING_CONTENT
WRITE_PATH:
	mov DX, offset PATH
	call WRITE_STRING
	add SI, 2
WRITING_PATH:
	cmp BYTE PTR ES:[SI], 00H
	je POPING_CONTENT
	mov AL, ES:[SI]
    mov DL, AL
	call WRITE_SYMBOL
	inc SI
	jmp WRITING_PATH
POPING_CONTENT:
    pop ES
    pop BX
    pop DX
    pop SI
    pop AX
    ret
WRITE_ENVIROMENT_CONTENT_AND_PATH ENDP

BEGIN:
    call WRITE_LOCKMEMORY
    call WRITE_ENVIROMENT
    call WRITE_TAIL
    call WRITE_ENVIROMENT_CONTENT_AND_PATH
    mov DX, offset ENTER
    call WRITE_STRING
    xor AL,AL
    mov AH, 01H
    int 21H
    mov AH,4CH
    int 21H
LR2 ENDS
END START 