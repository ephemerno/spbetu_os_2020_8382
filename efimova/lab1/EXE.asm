AStack    SEGMENT  STACK
          DW 128 DUP(?)   
AStack    ENDS

DATA  SEGMENT
   TYPE_PC db  'PC',0DH,0AH,'$'
   TYPE_PC_XT db 'PC/XT',0DH,0AH,'$'
   TYPE_AT db  'AT',0DH,0AH,'$'
   TYPE_PS2_M30 db 'PS2 модель 30',0DH,0AH,'$'
   TYPE_PS2_M50_60 db 'PS2 модель 50 или 60',0DH,0AH,'$'
   TYPE_PS2_M80 db 'PS2 модель 80',0DH,0AH,'$'
   TYPE_PС_JR db 'PСjr',0DH,0AH,'$'
   TYPE_PC_CONV db 'PC Convertible',0DH,0AH,'$'

   VERSIONS db 'Version MS-DOS:  .  ',0DH,0AH,'$'
   SERIAL_NUMBER db  'OEM number :  ',0DH,0AH,'$'
   USER_NUMBER db  'User serial number:       H $'
DATA ENDS

CODE SEGMENT
   ASSUME CS:CODE,DS:DATA,SS:AStack
   ; Процедуры
;-----------------------------------------------------
TETR_TO_HEX PROC near
   and AL,0Fh
   cmp AL,09
   jbe next
   add AL,07
next:
   add AL,30h
   ret
TETR_TO_HEX ENDP
;-------------------------------
BYTE_TO_HEX PROC near
;байт в AL переводится в два символа шест. числа в AX
   push CX
   mov AH,AL
   call TETR_TO_HEX
   xchg AL,AH
   mov CL,4
   shr AL,CL
   call TETR_TO_HEX ;в AL старшая цифра
   pop CX ;в AH младшая
   ret
BYTE_TO_HEX ENDP
;-------------------------------
WRD_TO_HEX PROC near
;перевод в 16 с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
   push BX
   mov BH,AH
   call BYTE_TO_HEX
   mov [DI],AH
   dec DI
   mov [DI],AL
   dec DI
   mov AL,BH
   call BYTE_TO_HEX
   mov [DI],AH
   dec DI
   mov [DI],AL
   pop BX
   ret
WRD_TO_HEX ENDP
;--------------------------------------------------
BYTE_TO_DEC PROC near
; перевод в 10с/с, SI - адрес поля младшей цифры
   push CX
   push DX
   xor AH,AH
   xor DX,DX
   mov CX,10
loop_bd:
   div CX
   or DL,30h
   mov [SI],DL
   dec SI
   xor DX,DX
   cmp AX,10
   jae loop_bd
   cmp AL,00h
   je end_l
   or AL,30h
   mov [SI],AL
end_l:
   pop DX
   pop CX
   ret
BYTE_TO_DEC ENDP
;-------------------------------
WRITESTRING PROC near
   mov AH,09h
   int 21h
   ret
WRITESTRING ENDP

PC_TYPE PROC near
   mov ax, 0F000H ; получаем номер модели 
	mov es, ax
	mov al, es:[0FFFEH]

	cmp al, 0FFH ; начинаем стравнивать
	je isPc
	cmp al, 0FEH
	je isPc_xt
	cmp al, 0FBH
	je isPc_xt
	cmp al, 0FCH
	je isPc_at
	cmp al, 0FAH
	je isPs2_m30
	cmp al, 0F8H
	je isPs2_m80
	cmp al, 0FDH
	je isPc_jr
	cmp al, 0F9H
	je isPc_cv
isPc:
	mov dx, offset TYPE_PC
	jmp writetype
isPc_xt:
	mov dx, offset TYPE_PC_XT
	jmp writetype
isPc_at:
	mov dx, offset TYPE_AT
	jmp writetype
isPs2_m30:
	mov dx, offset TYPE_PS2_M30
	jmp writetype
isPs2_m50_60:
	mov dx, offset TYPE_PS2_M50_60
	jmp writetype
isPs2_m80:
	mov dx, offset TYPE_PS2_M80
	jmp writetype
isPc_jr:
	mov dx, offset TYPE_PС_JR
	jmp writetype
isPc_cv:
	mov dx, offset TYPE_PC_CONV
	jmp writetype
writetype:
	call WRITESTRING
	ret
PC_TYPE ENDP

OS_VER PROC near
	mov ah, 30h
	int 21h
	push ax
	
	mov si, offset VERSIONS
	add si, 16 ;шаг для ''
	call BYTE_TO_DEC
   pop ax
   mov al, ah
   add si, 3
	call BYTE_TO_DEC
	mov dx, offset VERSIONS
	call WRITESTRING
   
	
	mov si, offset SERIAL_NUMBER
	add si, 13
	mov al, bh
	call BYTE_TO_DEC
	mov dx, offset SERIAL_NUMBER
	call WRITESTRING
	
	mov di, offset USER_NUMBER
	add di, 25
	mov ax, cx
	call WRD_TO_HEX
	mov al, bl
	call BYTE_TO_HEX
	sub di, 2
	mov [di], ax
	mov dx, offset USER_NUMBER
	call WRITESTRING
	ret
OS_VER ENDP

Main PROC FAR
   sub   AX,AX
   push  AX
   mov   AX,DATA
   mov   DS,AX
   call PC_TYPE
   call OS_VER
   xor AL,AL
   mov AH,4Ch
   int 21H
   ;ret
Main ENDP
CODE ENDS
      END Main