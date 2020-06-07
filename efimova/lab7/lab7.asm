DATA SEGMENT

	OVERLAY1 db "OV1.OVL",0
	OVERLAY2 db "OV2.OVL",0


	KEEP_PSP dw 0

	MEM_ERROR_7 db "The control block destroyed",0dh,0ah,'$'
	MEM_ERROR_8 db "Not enough memory to perform the function",0dh,0ah,'$'
	MEM_ERROR_9 db "Invalid address of the memory block",0dh,0ah,'$'
	MEM_SUCCESS db "Successful free",0dh,0ah,'$'


	
	SIZE_ERROR2 db "File not found",0dh,0ah,'$'
	SIZE_ERROR3 db "Route not found",0dh,0ah,'$'
	SIZE_SUCCESS db "Successful allocation",0dh,0ah,'$'

	LOAD_SUCCESS db "Successful load",0dh,0ah,'$'
	LOAD_ERROR1  db "Non-existent function function number",0dh,0ah,'$'
	LOAD_ERROR2  db "File not found",0dh,0ah,'$'
	LOAD_ERROR3  db "Foute not found",0dh,0ah,'$'
	LOAD_ERROR4  db "Too many open files",0dh,0ah,'$'
	LOAD_ERROR5  db "No access",0dh,0ah,'$'
	LOAD_ERROR8  db "Not enough memory",0dh,0ah,'$'
	LOAD_ERROR10 db "Wrong environment",0dh,0ah,'$'



	FULL_PATH db 128 dup(0)

	MEMORY_FOR_DTA db 43 dup(?)

	OVERLAY_SEG_ADDRESS dd 0

	
	
	DATA_END db 0

DATA ENDS

AStack SEGMENT STACK
	DW 200 DUP(?)
AStack ENDS

CODE SEGMENT

	ASSUME  CS:CODE, DS:DATA, ES:NOTHING, SS:AStack

Write_message	PROC
		push AX
		mov AH, 09h
		int 21h
		pop AX
		ret
Write_message	ENDP


FREE_EXTRA_MEMORY PROC NEAR
		push BX
		push DX
		push CX

		mov BX, offset PROGRAM_END
		mov AX, offset DATA_END
		add BX, AX

		mov CL, 4
		shr BX, CL
		add BX, 100h

		mov AH, 4Ah
		int 21h

		jnc FREE_MEMORY_SUCCESS

		cmp AX, 7
		je MEMORY_ERROR7
		cmp AX, 8
		je MEMORY_ERROR8
		cmp AX, 9
		je MEMORY_ERROR9

		MEMORY_ERROR7:
			lea DX, MEM_ERROR_7 
			call Write_message
			mov AX,0
			jmp FREE_MEMORY_END
		MEMORY_ERROR8:
			lea DX, MEM_ERROR_8
			call Write_message
			mov AX,0
			jmp FREE_MEMORY_END
		MEMORY_ERROR9:
			lea DX, MEM_ERROR_9 
			call Write_message
			mov AX,0
			jmp FREE_MEMORY_END

		FREE_MEMORY_SUCCESS:
			lea DX, MEM_SUCCESS
			call Write_message
			mov AX,1		

		FREE_MEMORY_END:
		pop CX
		pop DX
		pop BX

		ret
	FREE_EXTRA_MEMORY ENDP

	CREATE_PATH PROC NEAR
		push AX
		push CX
		push BX
		push DI
		push SI
		push ES

		mov SI, DX

		mov AX, KEEP_PSP
		mov ES, AX
		mov ES, ES:[2Ch]

		mov BX, 0
		print_env_variable:
			cmp BYTE PTR ES:[BX], 0
			je variable_end
			inc BX
			jmp print_env_variable
		variable_end:
			inc BX
			cmp BYTE PTR ES:[BX+1], 0
			jne print_env_variable

		add BX, 2

		mov DI, 0
		path_loop:
			mov DL, ES:[BX]
			mov BYTE PTR [FULL_PATH+DI], DL
			inc BX
			inc DI
			cmp DL, 0
			je path_loop_end
			cmp DL, '\'
			jne path_loop 
			mov CX, DI
			jmp path_loop
		path_loop_end:
		mov DI, CX

		filename_loop:
			mov DL, BYTE PTR [SI]
			mov BYTE PTR [FULL_PATH+DI], DL
			inc DI
			inc SI
			cmp DL, 0
			jne filename_loop

		pop ES
		pop SI
		pop DI
		pop BX
		pop CX
		pop AX

		ret
	CREATE_PATH ENDP

	ALLOCATE_MEM_FOR_OVERLAY PROC
		push BX
		push CX
		push DX

		push DX 		

		mov DX, offset MEMORY_FOR_DTA
		mov AH, 1Ah
		int 21h

		
		pop DX 			
		mov CX, 0
		mov AH, 4Eh
		int 21h

		jnc SIZE_SUCCESS_POINT

		cmp AX, 2
		jmp SIZE_ERROR2_POINT
		cmp AX, 3
		jmp SIZE_ERROR3_POINT

		SIZE_ERROR2_POINT:
			lea DX, SIZE_ERROR2
			jmp SIZE_FAIL
		SIZE_ERROR3_POINT:
			lea DX, SIZE_ERROR3
			jmp SIZE_FAIL

		SIZE_SUCCESS_POINT:
			push DI
			mov DI, offset MEMORY_FOR_DTA
			mov BX, [DI+1Ah] 		
			mov AX, [DI+1Ch] 		
			pop DI

			push CX
			mov CL, 4
			shr BX, Cl
			mov CL, 12
			shl AX, CL
			pop CX
			add BX, AX
			add BX, 1

			mov AH, 48h
			int 21h

			mov WORD PTR OVERLAY_SEG_ADDRESS, AX

			mov DX, offset SIZE_SUCCESS
			call Write_message

			mov AX, 1
			jmp SIZE_END

		SIZE_FAIL:
			mov AX, 0
			call Write_message

		SIZE_END:
		
		pop DX
		pop CX
		pop BX
		
		ret
	ALLOCATE_MEM_FOR_OVERLAY ENDP

	LOAD_OVERLAY PROC
		push AX
		push BX
		push CX
		push DX
		push DS
		push ES

		mov AX, DATA
		mov ES, AX
		mov DX, offset FULL_PATH
		mov BX, offset OVERLAY_SEG_ADDRESS
		mov AX, 4B03h
		int 21h

		jnc LOAD_SUCCESS_POINT

		cmp AX, 1
		jmp LOAD_ERROR1_POINT
		cmp AX, 2
		jmp LOAD_ERROR2_POINT
		cmp AX, 3
		jmp LOAD_ERROR3_POINT
		cmp AX, 4
		jmp LOAD_ERROR4_POINT
		cmp AX, 5
		jmp LOAD_ERROR5_POINT
		cmp AX, 8
		jmp LOAD_ERROR8_POINT
		cmp AX, 10
		jmp LOAD_ERROR10_POINT

		LOAD_ERROR1_POINT:
			lea DX, LOAD_ERROR1
			call Write_message
			jmp LOAD_END
		LOAD_ERROR2_POINT:
			lea DX, LOAD_ERROR2
			call Write_message
			jmp LOAD_END
		LOAD_ERROR3_POINT:
			lea DX, LOAD_ERROR3
			call Write_message
			jmp LOAD_END
		LOAD_ERROR4_POINT:
			lea DX, LOAD_ERROR4
			call Write_message
			jmp LOAD_END
		LOAD_ERROR5_POINT:
			lea DX, LOAD_ERROR5
			call Write_message
			jmp LOAD_END
		LOAD_ERROR8_POINT:
			lea DX, LOAD_ERROR8
			call Write_message
			jmp LOAD_END
		LOAD_ERROR10_POINT:
			lea DX, LOAD_ERROR10
			call Write_message
			jmp LOAD_END

		LOAD_SUCCESS_POINT:
			lea DX, LOAD_SUCCESS
			call Write_message

			mov AX, WORD PTR OVERLAY_SEG_ADDRESS
			mov ES, AX
			mov WORD PTR OVERLAY_SEG_ADDRESS, 0
			mov WORD PTR OVERLAY_SEG_ADDRESS+2, AX

			call OVERLAY_SEG_ADDRESS

			mov ES, AX
			mov AH, 49h
			int 21h

			jmp LOAD_END

		LOAD_END:

		pop ES
		pop DS
		pop DX
		pop CX
		pop BX
		pop AX

		ret
	LOAD_OVERLAY ENDP




	START_OVERLAY PROC
		push DX

		call CREATE_PATH

		lea DX, FULL_PATH
		call ALLOCATE_MEM_FOR_OVERLAY
		cmp AX, 1
		jne OVERLAY_END
		
		call LOAD_OVERLAY
		
	OVERLAY_END:
		pop DX
		ret
	START_OVERLAY ENDP

	
	MAIN PROC
		PUSH DS
		SUB AX, AX
		PUSH AX
		MOV AX, DATA
		MOV DS, AX
		mov KEEP_PSP, ES

		call FREE_EXTRA_MEMORY
		cmp AX,0
		je MAIN_END
		
		lea DX, OVERLAY1
		call START_OVERLAY 

		lea DX, OVERLAY2
		call START_OVERLAY 
		
		MAIN_END:
		xor AL, AL
		mov AH, 4Ch
		int 21h
	MAIN ENDP
	PROGRAM_END:

CODE ENDS

END MAIN 