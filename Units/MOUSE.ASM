;=======================================================================;
;= Programmname    : MOUSE.ASM V1.0             	                    =;
;= Programmautor   : Michael Rippl              	                    =;
;= Assembler       : MASM V5.0                	                       =;
;= Inhalt          : Routine als Handler fÅr einen Maustreiber 		  =;
;= Bemerkung       : Darf von keinem Pascal-Programm aufgerufen werden =;
;= Letzte énderung : 14-May-1990               								  =;
;=======================================================================;

DATA              SEGMENT WORD PUBLIC
		EXTRN       MouseX:BYTE
		EXTRN       MouseY:BYTE
DATA              ENDS


CODE    				SEGMENT BYTE PUBLIC
		ASSUME		CS:CODE

;===============================================================;
		PUBLIC		MouseHandler
		EXTRN			MouseEvent:NEAR
;---------------------------------------------------------------;
; Diese Prozedur dient als Handler fÅr einen Maustreiber der    ;
; Firma Microsoft. Es sind auch kompatible Maustreiber erlaubt. ;
; Da diese Prozedur in ein Quick Pascal Programm eingebunden	 ;
; wird, ruft sie auch eine Pascal-Prozedur 'MouseEvent' auf.    ;
;---------------------------------------------------------------;
MouseHandler		PROC FAR
		push        ax                      ; Register sichern
		push        bx
		push        cx
		push        dx
		push        si
		push        di
		push        bp
		push        es
		push        ds
		push			dx								; Vertikale Mausposition merken
		mov         si,DATA                 ; Datensegment von Quick Pascal
		mov         ds,si
		mov			dx,cx							; Horizontale Mausposition
		mov			cl,3
	 	shr			dx,cl							; Position fÅr das Textfenster
		mov			MouseX,dl               ; Position fÅr Pascal-Programm
		pop			dx								; Vertikale Mausposition
	 	shr			dx,cl							; Position fÅr das Textfenster
		mov			MouseY,dl               ; Position fÅr Pascal-Programm
		push			ax  							; Parameter MouseEvents
		push			bx                      ; Parameter MouseButtons
		call        MouseEvent					; Prozedur aus der KeyMouse Unit
		pop         ds                      ; Register setzen
		pop         es
		pop         bp
		pop         di
		pop         si
		pop         dx
		pop         cx
		pop         bx
		pop         ax
		ret
MouseHandler		ENDP
;===============================================================;

CODE    				ENDS
		END
