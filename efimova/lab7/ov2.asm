CODE SEGMENT

	ASSUME  CS:CODE, DS:NOTHING, ES:NOTHING, SS:NOTHING

	MAIN PROC FAR
		jmp MAIN_START
		HELLO_FROM_OVERLAY db "Hello from Overlay2 !",0dh,0ah,'$'
		OVERLAY_ADDRESS db "Segment address: $"
		NEW_LINE        db 10,13,'$'
		MAIN_START:
		push AX
		push DX
		push DS
		
		mov AX, CS
		mov DS, AX

		lea DX, HELLO_FROM_OVERLAY 
		mov AH, 9h
		int 21h

		lea DX, OVERLAY_ADDRESS
		mov AH, 9h
		int 21h

		mov AX, CS
		call PRINT_WORD

		lea DX, NEW_LINE
		mov AH, 9h
		int 21h
		
		pop DS
		pop DX
		pop AX
		retf
	MAIN ENDP

	PRINT_WORD PROC
		xchg AH, AL
		call PRINT_BYTE
		xchg AH, AL
		call PRINT_BYTE
		ret
	PRINT_WORD ENDP

	PRINT_BYTE PROC
	; prints AL as two hex digits
		push AX
		push BX
		push DX

		call BYTE_TO_HEX
		mov BH, AH

		mov DL, AL
		mov AH, 02h
		int 21h

		mov DL, BH
		mov AH, 02h
		int 21h

		pop DX
		pop BX
		pop AX
		ret
	PRINT_BYTE    ENDP

	TETR_TO_HEX 	PROC 
		and      AL,0Fh 
		cmp      AL,09 
		jbe      NEXT 
		add      AL,07 
	NEXT:
		add      AL,30h 
		ret 
	TETR_TO_HEX   ENDP 

	BYTE_TO_HEX   PROC
	; AL --> two hex symbols in AX 
		push     CX 
		mov      AH,AL 
		call     TETR_TO_HEX 
		xchg     AL,AH 
		mov      CL,4 
		shr      AL,CL 
		call     TETR_TO_HEX ; AL - high digit
		pop      CX          ; AH - low digit
		ret 
	BYTE_TO_HEX  ENDP 

CODE ENDS

END MAIN