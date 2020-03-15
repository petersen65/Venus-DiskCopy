;=========================================================================;
;= Programmname    : HIMEM.ASM V1.1  	          	                      =;
;= Programmautor   : Michael Rippl              	                      =;
;= Assembler       : MASM V5.0                	                         =;
;= Inhalt          : Routine zum Aufruf der XMS Basisfunktion aus Pascal =;
;= Bemerkung       : Darf nicht direkt von Pascal aus aufgerufen werden	 =;
;= Letzte énderung : 27-Aug-1990               								    =;
;=========================================================================;

DATA              SEGMENT WORD PUBLIC
		EXTRN       XmsControl:DWORD 						; Adresse der XMS Funktion
		EXTRN			XmsRegs:WORD							; Regs-Struktur von Pascal
DATA              ENDS


CODE    				SEGMENT BYTE PUBLIC
		ASSUME		CS:CODE, DS:DATA

;===============================================================;
		PUBLIC		CallXMS
;---------------------------------------------------------------;
;---------------------------------------------------------------;
CallXMS			  	PROC FAR
		push			ds											; Datensegment von Pascal
		mov			ax,ds										; Inhalt von DS nach ES
		mov			es,ax
		mov			ax,[XmsRegs]							; Inhalt von 'Regs.AX'
		mov			bx,[XmsRegs + 2]						; Inhalt von 'Regs.BX'
		mov			cx,[XmsRegs + 4] 						; Inhalt von 'Regs.CX'
		mov			dx,[XmsRegs + 6] 						; Inhalt von 'Regs.DX'
		mov			si,[XmsRegs + 10]   					; Inhalt von 'Regs.SI'
		mov			ds,[XmsRegs + 14]   					; Inhalt von 'Regs.DS'
		call			dword ptr es:[XmsControl]			; XMS Kontrollfunktion
		pop			ds  										; Datensegment von Pascal
		mov 			word ptr [XmsRegs],ax				; Inhalt in 'Regs.AX'
		mov 			word ptr [XmsRegs + 2],bx	  		; Inhalt in 'Regs.BX'
		mov 			word ptr [XmsRegs + 6],dx	  		; Inhalt in 'Regs.DX'
		retf 														; ZurÅck zu Pascal
CallXMS			  	ENDP
;===============================================================;

CODE    				ENDS
		END
