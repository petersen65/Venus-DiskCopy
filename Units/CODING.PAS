(*********************************************************************)
(* Programmname	 : CODING.PAS V1.0 											*)
(* Programmautor	 : Michael Rippl												*)
(* Compiler 		 : Quick Pascal V1.0 										*)
(* Inhalt			 : Kodierungsprogramm fÅr Venus V2.1 					*)
(* Bemerkung		 : Dieses Programm trÑgt auch die Seriennummer ein	*)
(* Letzte énderung : 22-JUL-1991 												*)
(*********************************************************************)

PROGRAM Coding;												(*$I- Kein I/O Checking		*)

CONST MemBlock  = 65520;									(* Grî·e Speicherblock		*)
		MinMemory = 200000;	  								(* Coding Mindestspeicher	*)

TYPE VenArray = ARRAY [1..MemBlock] OF BYTE;			(* Typ fÅr Speicherblîcke	*)

VAR Source,               									(* Quelldatei					*)
	 Target 		  : FILE;			  						(* Zieldatei					*)
	 SerialNumber : LONGINT;        						(* Seriennummer von Venus	*)
	 VenPart1,													(* 65520 Bytes von Venus	*)
	 VenPart2,													(* 131040 Bytes von Venus	*)
	 VenPart3  	  : ^VenArray;			  				  	(* Rest Bytes von Venus		*)
	 Result    	  : WORD;	  								(* Bytes Resultat Lesen		*)

(* Diese Funktion nimmt alle Initialisierungen vor *)
FUNCTION Initialize : BOOLEAN;
VAR Code : INTEGER;											(* Code Zahlenumwandlung	*)
BEGIN
	Initialize := TRUE;										(* Dient als Vorgabewert	*)

	IF MaxAvail < MinMemory THEN							(* Zu wenig Speicher			*)
	BEGIN
		WriteLn('Error - Not Enough Memory');
		Initialize := FALSE;
	END
	ELSE IF ParamCount <> 3 THEN							(* Parameterfehler			*)
	BEGIN
		WriteLn('Error - Illegal Number Of Parameters');
		Initialize := FALSE;
	END
	ELSE IF ParamStr(2) = ParamStr(3) THEN				(* Dateinamen sind gleich	*)
	BEGIN
		WriteLn('Error - Source And Target Must Be Different');
		Initialize := FALSE;
	END
	ELSE															(* Anzahl Parameter Ok		*)
	BEGIN
		Val(ParamStr(1), SerialNumber, Code);			(* Seriennummer als Zahl	*)
		Assign(Source, ParamStr(2));						(* Name der Quelldatei		*)
		Assign(Target, ParamStr(3));						(* Name der Zieldatei		*)

		IF Code <> 0 THEN										(* Fehler Seriennummer		*)
		BEGIN
			WriteLn('Error - Illegal Serial Number');
			Initialize := FALSE;
		END
		ELSE														(* Seriennummer ist Ok		*)
		BEGIN
			Reset(Source, 1);									(* Quelldatei îffnen			*)

			IF IOResult <> 0 THEN							(* Fehler beim Dateiîffnen	*)
			BEGIN
				WriteLn('Error - Cannot Open Source File');
				Initialize := FALSE;
			END
			ELSE													(* Quelldatei îffnen Ok		*)
			BEGIN
				ReWrite(Target, 1); 							(* Zieldatei îffnen			*)

				IF IOResult <> 0 THEN						(* Fehler beim Dateiîffnen	*)
				BEGIN
					WriteLn('Error - Cannot Open Target File');
					Close(Source);
					Initialize := FALSE;
				END;
			END;
		END;
	END;
END; (* Initialize *)

(* Diese Prozedur liest die Quelldatei Venus.Exe in den Speicher *)
PROCEDURE ReadFile;
BEGIN
	WriteLn('Reading File ...');

	BlockRead(Source, VenPart1^, MemBlock, Result);
	BlockRead(Source, VenPart2^, MemBlock, Result);
	BlockRead(Source, VenPart3^, MemBlock, Result);
END; (* ReadFile *)

(* Diese Prozedur kodiert die Quelldatei Venus.Exe *)
PROCEDURE CodeFile;
VAR i : WORD;													(* Dient als ZÑhler 			*)
BEGIN
	WriteLn('Coding File ...');

	FOR i := 1 TO MemBlock DO								(* Datei durchgehen			*)
	BEGIN
		Dec(VenPart1^[i], 3);
		Dec(VenPart2^[i], 3);
		Dec(VenPart3^[i], 3);
	END;
END; (* CodeFile *)

(* Diese Prozedur trÑgt die Seriennummer in die Datei ein *)
PROCEDURE EnterSerialNumber;
VAR pNumber   	 : ^LONGINT;	  							(* Zeiger auf Seriennummer	*)
	 SerialIndex : WORD;   									(* Index fÅr Seriennummer	*)
BEGIN
	SerialIndex := Result - 3;								(* Viermal Wert 28 suchen	*)

	WHILE (VenPart3^[SerialIndex] <> 28) OR 			(* Datei wird durchsucht	*)
		(VenPart3^[SerialIndex + 1] <> 28) OR
		(VenPart3^[SerialIndex + 2] <> 28) OR
		(VenPart3^[SerialIndex + 3] <> 28) DO
			Dec(SerialIndex);

	Inc(SerialIndex, 7);										(* Zeigt auf Seriennummer	*)

	pNumber := Addr(VenPart3^[SerialIndex]);
	pNumber^ := SerialNumber - 2;
END; (* EnterSerialNumber *)

(* Diese Prozedur schreibt die Quelldatei Venus.Exe *)
PROCEDURE WriteFile;
VAR Dummy : WORD;												(* Dient als Platzhalter	*)
BEGIN
	WriteLn('Writing File ...');

	BlockWrite(Target, VenPart1^, MemBlock, Dummy);
	BlockWrite(Target, VenPart2^, MemBlock, Dummy);
	BlockWrite(Target, VenPart3^, Result, Dummy);
END; (* WriteFile *)

BEGIN            												(* Hauptprogramm				*)
	IF Initialize THEN										(* Initialisierung ist Ok	*)
	BEGIN
		GetMem(VenPart1, MemBlock);						(* Speicher Venus Teil 1	*)
		GetMem(VenPart2, MemBlock);						(* Speicher Venus Teil 2	*)
		GetMem(VenPart3, MemBlock);						(* Speicher Venus Teil 3	*)

		ReadFile;												(* Venus-Datei einlesen		*)
		EnterSerialNumber;									(* Seriennummer eintragen	*)
		CodeFile;												(* Datei wird kodiert		*)
		WriteFile;												(* Venus-Datei schreiben	*)

		Close(Source);											(* Quelldatei schlie·en		*)
		Close(Target);											(* Zieldatei schlie·en		*)

		FreeMem(VenPart1, MemBlock);						(* Speicher freigeben		*)
		FreeMem(VenPart2, MemBlock);
		FreeMem(VenPart3, MemBlock);

		WriteLn('Working Done !');
	END;
END. (* Coding *)
