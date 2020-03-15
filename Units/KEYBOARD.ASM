;=======================================================================;
;= Programmname    : KEYBOARD.ASM V1.0            	                    =;
;= Programmautor   : Michael Rippl              	                    =;
;= Assembler       : MASM V5.0                	                       =;
;= Inhalt          : Routine als ErgÑnzung zum Tastaturinterrupt $09	  =;
;= Bemerkung       : Darf von keinem Pascal-Programm aufgerufen werden =;
;= Letzte énderung : 21-May-1990               								  =;
;=======================================================================;

DATA              SEGMENT WORD PUBLIC
		EXTRN			Interrupt09:DWORD            		; Alter Interrupt Handler
DATA              ENDS


CODE    				SEGMENT BYTE PUBLIC
		ASSUME		CS:CODE, DS:DATA

;===============================================================;
		PUBLIC		KeyboardHandler
		EXTRN			KeyboardEvent:NEAR
;---------------------------------------------------------------;
; Diese Prozedur dient als ErgÑnzung fÅr den Tastaturinterrupt  ;
; $09. Sie wird beim DrÅcken jeder Taste aufgrufen und startet	 ;
; dann den Tastatur-Handler im BIOS. Die Prozedur liest dann    ;
; den Tastaturdatenport aus und Åbergibt dieses Byte an eine    ;
; Quick Pascal Prozedur mit dem Namen 'KeyboardEvent'. Deshalb  ;
; wird diese Routine in ein Quick Pascal Programm eingebunden.	 ;
;---------------------------------------------------------------;
KeyboardHandler  	PROC FAR
		cli											; Keine Interrupts zulassen
		push        ax                      ; Register sichern
		push        bx
		push        cx
		push        dx
		push        si
		push        di
		push        bp
		push        es
		push        ds
		mov			ax,DATA
		mov			ds,ax							; Datensegment von Quick Pascal
		in				al,60h						; Tastaturdatenport auslesen
		xor			ah,ah
		push			ax								; Parameter fÅr Pascal Prozedur
		pushf
		call			[Interrupt09]				; Interruptaufruf simulieren
      call        KeyboardEvent
		pop         ds                      ; Register setzen
		pop         es
		pop         bp
		pop         di
		pop         si
		pop         dx
		pop         cx
		pop         bx
		pop         ax
		sti											; Interrupts wieder zulassen
		iret
KeyboardHandler  	ENDP
;===============================================================;

CODE    				ENDS
		END
