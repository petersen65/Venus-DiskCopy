(**************************************************************************)
(* Programmname    : KEYSPEED.PAS V1.1             	          			  *)
(* Programmautor   : Michael Rippl              	         			     *)
(* Compiler        : Quick Pascal V1.0        	  				              *)
(* Inhalt          : Programm zur Einstellung der Tastaturgeschwindigkeit *)
(* Bemerkung       : -																     *)
(* Letzte énderung : 25-May-1990                          			        *)
(**************************************************************************)

PROGRAM KeySpeed;

USES KeyMouse;													(* Tastatur, Maus Routinen	*)

VAR DelayRate,
	 TypematicRate : BYTE;
	 CodePos   		: INTEGER;                       (* Fehler bei Zahlenstring *)
	 Number        : STRING[5];							(* Nimmt Zahlenstrings auf	*)

BEGIN
	WriteLn('KeySpeed  Version 1.01  Copyright (c) 1990 by Michael Rippl');

	IF ParamCount <> 2 THEN									(* UngÅltige Parameter		*)
	BEGIN
		WriteLn;
		WriteLn('Usage : KeySpeed <delay rate> <typematic rate>');
		Halt;
	END;

	Val(ParamStr(1), DelayRate, CodePos);

	IF CodePos <> 0 THEN             					(* Fehler im Zahlenstring  *)
	BEGIN
		WriteLn;
		WriteLn('Illegal delay rate');
		Halt;
	END;

	Val(ParamStr(2), TypematicRate, CodePos);

	IF CodePos <> 0 THEN             					(* Fehler im Zahlenstring  *)
	BEGIN
		WriteLn;
		WriteLn('Illegal typematic rate');
		Halt;
	END;

	SetKeySpeed(DelayRate, TypematicRate);				(* Geschwindigkeit setzen	*)
END.
