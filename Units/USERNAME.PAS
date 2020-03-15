(***********************************************************)
(* Programmname	 : USERNAME.PAS V1.1	  						  *)
(* Programmautor	 : Michael Rippl		  						  *)
(* Compiler 		 : Quick Pascal V1.0   						  *)
(* Inhalt			 : Konfigurationsprogramm fÅr Venus V2.1 *)
(* Bemerkung		 : -						  						  *)
(* Letzte énderung : 22-Jul-1991 		  						  *)
(***********************************************************)

PROGRAM UserName;  											(*$M 8192, 4096, 655360		*)
																	(*$I- Kein I/O Checking		*)

USES Crt, VenColor, KeyMouse, Primitiv, Intuitiv; 	(* Units einbinden			*)

CONST MinMemory = 200000;									(* Config Mindestspeicher	*)
		MemBlock	 = 65520;									(* Grî·e Speicherblock		*)

(* Diese Prozedur gibt eine Nachricht auf dem Bildschirm aus *)
PROCEDURE DoMessage(Message : TextStr);
VAR TxtOk,                                         (* Text von Ok-Gadget		*)
	 TxtMsg : pIntuiText;									(* Text der Nachricht		*)
	 GadOk  : pGadget;										(* Zeiger auf Ok-Gadget		*)
	 MsgReq : pRequester;									(* Zeiger auf Requester		*)
	 Status : BOOLEAN;										(* Status des Requesters	*)
BEGIN
	InitIntuiText(TxtMsg, 2, 2, cBlack, cCyan, Message, NIL);
	InitIntuiText(TxtOk, 27, 4, cBlack, cCyan, '', NIL);

	InitGadget(GadOk, 27, 4, 8, 3, TxtOk, cWhite, cCyan, NIL, OkGadget);

	InitRequester(MsgReq, 21, 7, 38, 8, cBlack, cCyan, ' Message ',
					  [rClose, rShadow, rMove, rTitle, rDouble], GadOk, TxtMsg);

	Status := OpenRequester(MsgReq);						(* Requester îffnen			*)

	IF Status THEN
		Status := CloseRequester(MsgReq);				(* Requester schlie·en		*)
END; (* DoMessage *)

(* Diese Prozedur konfiguriert das Kopierprogramm Venus.Exe *)
PROCEDURE Configuration;
TYPE VenArray = ARRAY [1..MemBlock] OF BYTE;			(* Typ fÅr Speicherblîcke	*)
VAR VenusFile : FILE;										(* Dateivariable fÅr Venus	*)
	 VenPart1,													(* 65520 Bytes von Venus	*)
	 VenPart2,													(* 131040 Bytes von Venus	*)
	 VenPart3  : ^VenArray;				  				  	(* Rest Bytes von Venus		*)
	 i,															(* Dient nur als ZÑhler		*)
	 Dummy,													  	(* Dient als Platzhalter	*)
	 Result    : WORD;										(* Bytes Resultat Lesen		*)
	 UsrName	  : TextStr;									(* Name des Benutzers		*)
	 UsrOk	  : BOOLEAN;									(* Eingabe wird Åbernommen	*)

(* Diese Prozedur lîscht den untersten Bildschirmstreifen fÅr Meldungen *)
PROCEDURE Clear;
BEGIN
	VideoFill(0, 24, 80, 1, ' ', cBlack, cLightGrey);
END; (* Clear *)

(* Diese Prozedur liest den Namen eines Benutzers ein *)
PROCEDURE GetUserName(VAR UsrName : TextStr; VAR UserOk : BOOLEAN);
VAR TxtOk,                                         (* Text von Ok-Gadget		*)
	 TxtExit,  													(* Text von Exit-Gadget		*)
	 TxtUsr  : pIntuiText;									(* Text fÅr Benutzer			*)
	 GadOk,														(* Zeiger auf Ok-Gadget		*)
	 GadExit,													(* Zeiger auf Exit-Gadget	*)
	 GadUsr  : pGadget;										(* Zeiger auf User-Gadget	*)
	 UsrReq  : pRequester;									(* Zeiger auf Requester		*)
	 Status  : BOOLEAN;										(* Status des Requesters	*)
BEGIN
	InitIntuiText(TxtUsr, 4, 2, cBlack, cCyan, 'Your Name', NIL);
	InitIntuiText(TxtOk, 29, 4, cBlack, cCyan, '', NIL);
	InitIntuiText(TxtExit, 3, 4, cBlack, cCyan, '', NIL);

	InitGadget(GadOk, 29, 4, 8, 3, TxtOk, cWhite, cCyan, NIL, OkGadget);
	InitGadget(GadExit, 3, 4, 8, 3, TxtExit, cWhite, cCyan, GadOk, ExitGadget);
	InitGadget(GadUsr, 4, 2, 9, 1, TxtUsr, cWhite, cCyan, GadExit, TextGadget);

	WITH GadUsr^ DO											(* Textpufferdaten 			*)
	BEGIN
		Buffer := '';
		Size := 20;
		Mask := ['A'..'Z', 'a'..'z', '_'];
	END;

	InitRequester(UsrReq, 19, 7, 40, 8, cBlack, cCyan,
					  ' Message ',
					  [rClose, rMove, rShadow, rTitle, rDouble], GadUsr, NIL);

	Clear;  	 						  							(* Meldungsbereich lîschen	*)
	PutString(2, 24, 'Please Enter Your Name, It Must', cBlack, cLightGrey);
	PutString(34, 24, 'Contain At Least 6 Characters', cBlack, cLightGrey);

	Status := OpenRequester(UsrReq); 					(* Requester îffnen			*)

	IF GetEndGadget(GadOk) = GadOk THEN	  		 		(* Benutzername zuweisen	*)
	BEGIN
		UserOk := TRUE;	  									(* Eingabe Åbernehmen		*)
		UsrName := GadUsr^.Buffer;
	END
	ELSE UserOk := FALSE;      		  					(* Eingabe ignorieren		*)

	IF Status THEN
		Status := CloseRequester(UsrReq);				(* Requester schlie·en		*)
END; (* GetUserName *)

(* Diese Prozedur ÅberprÅft, ob Venus V2.1 schon einmal konfiguriert wurde *)
PROCEDURE CheckConfig;
BEGIN
	IF (VenPart1^[1] <> $4A) OR (VenPart1^[2] <> $57) THEN
	BEGIN
		FreeMem(VenPart1, MemBlock); 						(* Speicher 1 freigeben		*)
		FreeMem(VenPart2, MemBlock); 						(* Speicher 2 freigeben		*)
		FreeMem(VenPart3, MemBlock); 						(* Speicher 3 freigeben		*)

		Clear;  													(* Meldungsbereich lîschen	*)
		PutString(2, 24, 'The Configuration Of Your Program', cBlack, cLightGrey);
		PutString(36, 24, 'Venus.Exe Was Already Done', cBlack, cLightGrey);

		DoMessage(' Error - File Already Configured');

		IF MouseAvail THEN MouseOff;	  					(* Maus ausschalten			*)
		ClrScr;		  											(* Bildschirm lîschen		*)
		Halt;														(* Programm beenden			*)
	END;
END; (* CheckConfig *)

(* Diese Prozedur trÑgt einen Benutzernamen in Venus V2.1 ein *)
PROCEDURE EnterUserName(UsrName : TextStr);
VAR i 		  : BYTE;										(* Dient als ZÑhler			*)
	 NameIndex : WORD;   									(* Index fÅr Benutzername	*)
BEGIN
	FOR i := 1 TO Length(UsrName) DO						(* Benutzername kodieren	*)
		Dec(UsrName[i], 4);

	NameIndex := Result - 3;								(* Viermal Wert 28 suchen	*)

	WHILE (VenPart3^[NameIndex] <> 28) OR 				(* Datei wird durchsucht	*)
		(VenPart3^[NameIndex + 1] <> 28) OR
		(VenPart3^[NameIndex + 2] <> 28) OR
		(VenPart3^[NameIndex + 3] <> 28) DO
			Dec(NameIndex);

	Dec(NameIndex, 16);										(* Zeigt auf Namensanfang	*)

	FOR i := 1 TO Length(UsrName) DO  					(* Name in Datei schreiben	*)
		VenPart3^[NameIndex + i - 1] := Ord(UsrName[i]);
END; (* EnterUserName *)

BEGIN (* Configuration *)
	IF ColorGraphic THEN										(* Farbgrafik vorhanden		*)
		SetColorGraphics										(* Farbpalette setzen		*)
	ELSE SetMonochromGraphics;								(* Monochrompalette setzen	*)

	CheckBreak := FALSE;										(* Kein Strg-Untbr Ende		*)
	CursorLine;
	CursorOff;													(* Kein Cursor sichtbar 	*)
	ReleaseCodeOn; 											(* Release Codes zulassen	*)
	MakeCodeOff;												(* Keine unbekannten Codes *)
	VideoFill(0, 2, 80, 22, Chr(177), cBlack, cLightGrey);
	VideoFill(0, 0, 80, 2, ' ', cYellow, cRed);
	Clear;														(* Meldungsbereich lîschen	*)

	PutString(19, 0, 'VENUS DISKCOPY V2.1 CONFIGURATION PROGRAM', cYellow, cRed);
	PutString(22, 1, '(C) COPYRIGHT 1991 BY DIGITAL IMAGE', cYellow, cRed);

	IF MouseAvail THEN								  		(* Eine Maus ist vorhanden *)
	BEGIN
		IF ColorGraphic THEN 						  		(* Farbe 						*)
		BEGIN
			DefineMouseCursor($00FF, WORD((Ord(cRed) SHL 4) OR
									(Ord(cYellow))) SHL 8);
		END
		ELSE DefineMouseCursor($F0FF, $7F00);	  		(* Monochrom					*)

		SetMouseSpeed(4, 8); 						  		(* Mausgeschwindigkeit		*)
	END;

	IF MouseAvail THEN MouseOn;							(* Maus anschalten			*)

	IF MaxAvail < MinMemory THEN							(* Zu wenig Speicher			*)
	BEGIN
		Clear;  													(* Meldungsbereich lîschen	*)
		PutString(2, 24, 'Configuration Needs At Least', cBlack, cLightGrey);
		PutString(31, 24, '180.000 Bytes Of Memory', cBlack, cLightGrey);

		DoMessage('  Error - Need Additional Memory');
	END
	ELSE															(* Genug Speicher da			*)
	BEGIN
		Assign(VenusFile, 'VENUS.EXE');		  			(* Dateiname zuweisen		*)
		Reset(VenusFile, 1);						  			(* Datei zum Lesen îffnen	*)

		IF IOResult <> 0 THEN					  			(* Fehler beim ôffnen  		*)
		BEGIN
			Clear;  												(* Meldungsbereich lîschen	*)
			PutString(2, 24, 'File Venus.Exe Must Be Placed', cBlack, cLightGrey);
			PutString(32, 24, 'In Your Actual Directory', cBlack, cLightGrey);

			DoMessage(' Error - File Venus.Exe Not Found');
		END
		ELSE   										  			(* Datei ist geîffnet		*)
		BEGIN
			GetMem(VenPart1, MemBlock);					(* Erster Teil von Venus	*)
			GetMem(VenPart2, MemBlock);					(* Zweiter Teil von Venus	*)
			GetMem(VenPart3, MemBlock);					(* Dritter Teil von Venus	*)

			Clear;  											(* Meldungsbereich lîschen	*)
			PutString(2, 24, 'Please Wait, Reading File', cBlack, cLightGrey);
			PutString(28, 24, 'Venus.Exe ...', cBlack, cLightGrey);

			BlockRead(VenusFile, VenPart1^, MemBlock, Result);
			BlockRead(VenusFile, VenPart2^, MemBlock, Result);
			BlockRead(VenusFile, VenPart3^, MemBlock, Result);

			IF IOResult <> 0 THEN					  		(* Fehler beim Einlesen		*)
			BEGIN
				Close(VenusFile);								(* Datei wieder schlie·en	*)
				FreeMem(VenPart1, MemBlock);				(* Speicher 1 freigeben		*)
				FreeMem(VenPart2, MemBlock);				(* Speicher 2 freigeben		*)
				FreeMem(VenPart3, MemBlock);				(* Speicher 3 freigeben		*)

				Clear;  											(* Meldungsbereich lîschen	*)
				PutString(2, 24, 'Your Disk Has A Read', cBlack, cLightGrey);
				PutString(23, 24, 'Error, Please Call Your', cBlack, cLightGrey);
				PutString(47, 24, 'Distributor', cBlack, cLightGrey);

				DoMessage('   Error - Venus.Exe Read Error');
			END
			ELSE 													(* Datei korrekt gelesen	*)
			BEGIN
				Close(VenusFile);								(* Datei wieder schlie·en	*)
				CheckConfig;									(* Konfiguration prÅfen		*)
				GetUserName(UsrName, UsrOk); 				(* Benutzername einlesen	*)

				IF NOT UsrOk THEN								(* Programm abbrechen		*)
				BEGIN
					FreeMem(VenPart1, MemBlock); 			(* Speicher 1 freigeben		*)
					FreeMem(VenPart2, MemBlock); 			(* Speicher 2 freigeben		*)
					FreeMem(VenPart3, MemBlock);			(* Speicher 3 freigeben		*)

					Clear;  										(* Meldungsbereich lîschen	*)
					PutString(2, 24, 'Configuration Is Not', cBlack, cLightGrey);
					PutString(23, 24, 'Complete, Therefore', cBlack, cLightGrey);
					PutString(43, 24, 'Venus V2.1 Is Not', cBlack, cLightGrey);
					PutString(61, 24, 'Executable', cBlack, cLightGrey);

					DoMessage('   Configuration Is Interrupted');

					IF MouseAvail THEN MouseOff;	  		(* Maus ausschalten			*)
					ClrScr;		  								(* Bildschirm lîschen		*)
					Exit;											(* Programm vorzeitig Ende	*)
				END
				ELSE IF Length(UsrName) < 6 THEN			(* Benutzername unzulÑssig	*)
				BEGIN
					FreeMem(VenPart1, MemBlock); 			(* Speicher 1 freigeben		*)
					FreeMem(VenPart2, MemBlock); 			(* Speicher 2 freigeben		*)
					FreeMem(VenPart3, MemBlock);			(* Speicher 3 freigeben		*)

					Clear;  										(* Meldungsbereich lîschen	*)
					PutString(2, 24, 'Your Name Must Contain', cBlack, cLightGrey);
					PutString(25, 24, 'At Least 6 Characters', cBlack, cLightGrey);

					DoMessage('  The User Name Was Not Accepted');

					IF MouseAvail THEN MouseOff;	  		(* Maus ausschalten			*)
					ClrScr;		  								(* Bildschirm lîschen		*)
					Exit;											(* Programm vorzeitig Ende	*)
				END;

				FOR i := 1 TO MemBlock DO					(* Venus dekodieren			*)
				BEGIN
					Inc(VenPart1^[i], 3);
					Inc(VenPart2^[i], 3);
					Inc(VenPart3^[i], 3);
				END;

				EnterUserName(UsrName);						(* Name in Venus eintragen	*)

				ReWrite(VenusFile, 1);  					(* FÅr Schreiben îffnen 	*)

				IF IOResult <> 0 THEN 						(* Fehler beim ôffnen		*)
				BEGIN
					FreeMem(VenPart1, MemBlock);			(* Speicher 1 freigeben		*)
					FreeMem(VenPart2, MemBlock);			(* Speicher 2 freigeben		*)
					FreeMem(VenPart3, MemBlock);			(* Speicher 3 freigeben		*)

					Clear;  										(* Meldungsbereich lîschen	*)
					PutString(2, 24, 'You Must Remove The', cBlack, cLightGrey);
					PutString(22, 24, 'Write Protect Switch', cBlack, cLightGrey);
					PutString(43, 24, 'From Your Disk', cBlack, cLightGrey);

					DoMessage('   Error - Remove Write Protect');
				END
				ELSE        									(* Datei wird geschrieben	*)
				BEGIN
					Clear;  										(* Meldungsbereich lîschen	*)
					PutString(2, 24, 'Please Wait, Writing', cBlack, cLightGrey);
					PutString(23, 24, 'File Venus.Exe ...', cBlack, cLightGrey);

					BlockWrite(VenusFile, VenPart1^, MemBlock, Dummy);
					BlockWrite(VenusFile, VenPart2^, MemBlock, Dummy);
					BlockWrite(VenusFile, VenPart3^, Result, Dummy);

					FreeMem(VenPart1, MemBlock);			(* Speicher 1 freigeben		*)
					FreeMem(VenPart2, MemBlock);			(* Speicher 2 freigeben		*)
					FreeMem(VenPart3, MemBlock);			(* Speicher 3 freigeben		*)

					IF IOResult <> 0 THEN					(* Fehler beim Schreiben	*)
					BEGIN
						Close(VenusFile);	  					(* Datei wieder schlie·en	*)

						Clear;  									(* Meldungsbereich lîschen	*)
						PutString(2, 24, 'Your Disk Has A Write', cBlack, cLightGrey);
						PutString(24, 24, 'Error, Please Call', cBlack, cLightGrey);
						PutString(43, 24, 'Your Distributor', cBlack, cLightGrey);

						DoMessage('  Error - Venus.Exe Write Error');
					END
					ELSE											(* Datei geschrieben Ok		*)
					BEGIN
						Close(VenusFile);	  					(* Datei wieder schlie·en	*)

						Clear;  									(* Meldungsbereich lîschen	*)
						PutString(2, 24, 'Now, Your Program Is', cBlack, cLightGrey);
						PutString(23, 24, 'Encoded And', cBlack, cLightGrey);
						PutString(35, 24, 'Executable', cBlack, cLightGrey);

						DoMessage('Ø Venus V2.1  Configuration Done Æ');
					END;
				END;
			END
		END;
	END;

	IF MouseAvail THEN MouseOff;							(* Maus ausschalten			*)
	ClrScr;														(* Bildschirm lîschen		*)
END; (* Configuration *)

BEGIN 															(* Hauptprogramm 				*)
	Configuration;												(* Konfiguration von Venus	*)
END. (* UserName *)
