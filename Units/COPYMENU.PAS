(*************************************************************************)
(* Programmname	 : COPYMENU.PAS V2.1 											 *)
(* Programmautor	 : Michael Rippl													 *)
(* Compiler 		 : Quick Pascal V1.0 							  			 	 *)
(* Inhalt			 : MenÅ DiskCopy des Kopierprogramms Venus V2.1 		 *)
(* Bemerkung		 : Verwendet periodischen Interrupt $1C fÅr Kopierzeit *)
(* Letzte énderung : 08-Aug-1991 													 *)
(*************************************************************************)

UNIT CopyMenu;													(*$I- Kein I/O Checking		*)
																	(*$V- Kein String-Check		*)

INTERFACE

USES Dos, KeyMouse, Primitiv, Intuitiv, Windows, VenColor,
	  Disk, Memory;									 		(* Units einbinden			*)

(* Diese Prozedur kopiert eine Diskette mit einem Laufwerk *)
PROCEDURE DoSingleDrive(VAR Drive : CHAR; EmsUsage, XmsUsage, ExtUsage,
								RamDiskUsage, HardDiskUsage : BOOLEAN;
								NrOfErrorTrials : BYTE; VerifyTarget, FormatTarget,
								Multiple, Cylinder : BOOLEAN);

(* Diese Prozedur kopiert eine Diskette mit zwei Laufwerken *)
PROCEDURE DoDualDrive(VAR DriveA, DriveB : CHAR; NrOfErrorTrials : BYTE;
							 VerifyTarget, FormatTarget : BOOLEAN);

(* Diese Prozedur legt eine Gesamtkopie einer Diskette auf Festplatte ab *)
PROCEDURE DoImageToHd(VAR SourceDrive, TargetHardDisk : CHAR; VAR ToHd : STRING;
							 NrOfErrorTrials : BYTE; HardDiskUsage : BOOLEAN);

(* Diese Prozedur kopiert eine Image-Datei wieder auf eine Diskette *)
PROCEDURE DoRestoreImage(VAR TargetDrive, SourceHardDisk : CHAR;
								 VAR FromHd : STRING; NrOfErrorTrials : BYTE;
								 HardDiskUsage, VerifyTarget, FormatTarget : BOOLEAN);

(* Diese Prozedur gibt eine Nachricht auf dem Bildschirm aus *)
PROCEDURE DoMessage(Message : TextStr; WithExit : BOOLEAN; VAR GetOk : BOOLEAN);

IMPLEMENTATION

CONST Ticks19 = 1.043956;									(* 19 Ticks in Sekunden		*)

VAR Interrupt1C  : POINTER;								(* Periodischer Interrupt	*)
	 CopyTime	  : REAL; 		  							(* Benîtigte Zeit in Sek	*)
	 ClockCounter : BYTE;									(* ZÑhler fÅr die Uhr		*)
	 MinuteLow, 												(* Zeiger auf 1er Minute	*)
	 MinuteHigh,												(* Zeiger auf 10er Minute	*)
	 SecondLow, 												(* Zeiger auf 1er Sekunde	*)
	 SecondHigh   : ^CHAR;									(* Zeiger auf 10er Sekunde *)

(* Diese Interruptroutine wird beim Kopieren 18.2 mal pro Sekunde aufgerufen *)
PROCEDURE Clock; INTERRUPT;
VAR Time,														(* Zeit in Sekunden			*)
	 ValueOut	: WORD;										(* Wert wird ausgegeben 	*)
	 TextString : STRING [2];								(* Zeitangabe als Text		*)
BEGIN
	Inc(ClockCounter);

	IF ClockCounter = 19 THEN								(* Eine Sekunde vergangen	*)
	BEGIN
		ClockCounter := 0;									(* ZÑhler fÅr Uhr auf 0 	*)
		CopyTime := CopyTime + Ticks19;					(* Zeit der 19 Ticks dazu	*)
		Time := Round(CopyTime);							(* Zeit in Wortformat 		*)

		ValueOut := Time DIV 60;							(* Anzahl der Minuten		*)
		Str(ValueOut : 2, TextString);

		IF MouseAvail THEN MouseOff;						(* Maus ausschalten			*)

		IF ValueOut < 10 THEN TextString[1] := '0';	(* FÅhrende Null				*)
		MinuteHigh^ := TextString[1]; 					(* In Bildschirmspeicher	*)
		MinuteLow^ := TextString[2];

		ValueOut := Time MOD 60;							(* Restliche Sekunden		*)
		Str(ValueOut : 2, TextString);

		IF ValueOut < 10 THEN TextString[1] := '0';	(* FÅhrende Null				*)
		SecondHigh^ := TextString[1]; 					(* In Bildschirmspeicher	*)
		SecondLow^ := TextString[2];

		IF MouseAvail THEN MouseOn;						(* Maus anschalten			*)
	END;
END; (* Clock *)

(* Diese Prozedur initialisiert die Parameter der Clock *)
PROCEDURE InitClock;
BEGIN
	GetIntVec($1C, Interrupt1C);							(* Alten Interrupt merken	*)
	CopyTime := 0.0;											(* Benîtigte Kopierzeit 0	*)
	ClockCounter := 0;										(* ZÑhler fÅr Uhr auf 0 	*)

	MinuteHigh := Ptr(VideoSegment, (NrOfColumns * 4 + 71) SHL 1);
	MinuteLow := Ptr(VideoSegment, (NrOfColumns * 4 + 72) SHL 1);
	SecondHigh := Ptr(VideoSegment, (NrOfColumns * 4 + 74) SHL 1);
	SecondLow := Ptr(VideoSegment, (NrOfColumns * 4 + 75) SHL 1);
END; (* InitClock *)

(* Diese Prozedur installiert die Prozedur Clock als Interruptroutine *)
PROCEDURE InstallClock;
BEGIN
	SetIntVec($1C, Addr(Clock));							(* Uhrzeit anzeigen			*)
END; (* InstallClock *)

(* Diese Prozedur entfernt die Prozedur Clock als Interruptroutine *)
PROCEDURE RemoveClock;
BEGIN
	SetIntVec($1C, Interrupt1C);							(* Alten Interrupt setzen	*)
END; (* RemoveClock *)

(* Diese Prozedur schreibt ein Zeichen auf eine Spurposition im Spurgatter *)
PROCEDURE WriteToGate(Character : CHAR; Track, Side : BYTE;
							 DetailPen, BlockPen : Colors);
CONST TracksPerLine = 30;									(* Spuren pro Zeile			*)
VAR PosX,
	 PosY : BYTE;
BEGIN
	PosX := 18 + (Track MOD TracksPerLine) SHL 1;	(* Zeichenposition (X,Y)	*)
	PosY := Side * 9 + 9 + ((Track DIV TracksPerLine) SHL 1);

	IF MouseAvail THEN MouseOff;							(* Maus ausschalten			*)

	IF Character = 'E' THEN
		PutChar(PosX, PosY, Character, cBlack, cCyan)
	ELSE
		PutChar(PosX, PosY, Character, DetailPen, BlockPen);

	IF MouseAvail THEN MouseOn;							(* Maus anschalten			*)
END; (* WriteToGate *)

(* Diese Prozedur markiert ungenutzte Spuren im Spurgatter *)
PROCEDURE WriteUnusedGate(Typ : DiskType);
CONST TrackMax = 89; 										(* Grî·te Spur im Gatter	*)
VAR i : BYTE;
BEGIN
	CASE Typ OF 												(* Disktypen unterscheiden *)
		Disk160, Disk180 :									(* 40 Spuren, einseitig 	*)
		BEGIN
			FOR i := 40 TO TrackMax DO
				WriteToGate('˛', i, 0, cLightMagenta, cBlue);

			FOR i := 0 TO TrackMax DO
				WriteToGate('˛', i, 1, cLightMagenta, cBlue);
		END;

		Disk320, Disk360 :									(* 40 Spuren, doppelseitig *)
		BEGIN
			FOR i := 40 TO TrackMax DO
			BEGIN
				WriteToGate('˛', i, 0, cLightMagenta, cBlue);
				WriteToGate('˛', i, 1, cLightMagenta, cBlue);
			END;
		END;

		Disk720, Disk1440, Disk1200 : 					(* 80 Spuren, doppelseitig *)
		BEGIN
			FOR i := 80 TO TrackMax DO
			BEGIN
				WriteToGate('˛', i, 0, cLightMagenta, cBlue);
				WriteToGate('˛', i, 1, cLightMagenta, cBlue);
			END;
		END;
	END;
END; (* WriteUnusedGate *)

(* Diese Prozedur lîscht das komplette Spurgatter *)
PROCEDURE ClearGate;
CONST TrackMax = 89; 										(* Grî·te Spur im Gatter	*)
VAR i : BYTE;
BEGIN
	FOR i := 0 TO TrackMax DO								(* Beide Gatter lîschen 	*)
	BEGIN
		WriteToGate(' ', i, 0, cLightMagenta, cBlue);
		WriteToGate(' ', i, 1, cLightMagenta, cBlue);
	END;

	IF MouseAvail THEN MouseOff;							(* Maus ausschalten			*)

	PutString(7, 12, '00', cLightGreen, cBlue);
	PutString(7, 21, '00', cLightGreen, cBlue);
	PutString(19, 4, 'MAIN MEM ', cLightGreen, cBlue);
	PutString(41, 4, '1.2 MB 5¨" 2S HD ', cLightGreen, cBlue);
	PutString(71, 4, '00:00', cLightGreen, cBlue);

	IF MouseAvail THEN MouseOn;							(* Maus anschalten			*)
END; (* ClearGate *)

(* Diese Prozedur schreibt den Diskettentyp auf den Bildschirm *)
PROCEDURE WriteDiskType(DiskTyp : DiskType);
BEGIN
	IF MouseAvail THEN MouseOff;							(* Maus ausschalten			*)

	CASE DiskTyp OF											(* Disktyp unterscheiden	*)
		Disk160	: PutString(41, 4, '160 KB 5¨" 1S 2D ', cLightGreen, cBlue);
		Disk320	: PutString(41, 4, '320 KB 5¨" 2S 2D ', cLightGreen, cBlue);
		Disk180	: PutString(41, 4, '180 KB 5¨" 1S 2D ', cLightGreen, cBlue);
		Disk360	: PutString(41, 4, '360 KB 5¨" 2S 2D ', cLightGreen, cBlue);
		Disk720	: PutString(41, 4, '720 KB 3´" 2S 2D ', cLightGreen, cBlue);
		Disk1200 : PutString(41, 4, '1.2 MB 5¨" 2S HD ', cLightGreen, cBlue);
		Disk1440 : PutString(41, 4, '1.44 MB 3´" 2S HD', cLightGreen, cBlue);
	END;                            

	IF MouseAvail THEN MouseOn;							(* Maus anschalten			*)
END; (* WriteDiskType *)

(* Diese Prozedur schreibt den verwendeten Speicher auf den Bildschirm *)
PROCEDURE WriteUsedMemory;
BEGIN
	IF MouseAvail THEN MouseOff;							(* Maus ausschalten			*)

	CASE UsingMemory OF										(* Verwendeter Speicher 	*)
		UsingMainMem	  : PutString(19, 4, 'MAIN MEM ', cLightGreen, cBlue);
		UsingExtMem 	  : PutString(19, 4, 'EXTENDED ', cLightGreen, cBlue);
		UsingEmsMem 	  : PutString(19, 4, 'EXPANDED ', cLightGreen, cBlue);
		UsingXmsMem 	  : PutString(19, 4, 'XMS MEM  ', cLightGreen, cBlue);
		UsingRamDiskMem  : PutString(19, 4, 'RAM DISK ', cLightGreen, cBlue);
		UsingHardDiskMem : PutString(19, 4, 'HARD DISK', cLightGreen, cBlue);
	END;

	IF MouseAvail THEN MouseOn;							(* Maus anschalten			*)
END; (* WriteUsedMemory *)

(* Diese Prozedur schreibt die verwendete Cylindernummer auf den Bildschirm *)
PROCEDURE WriteCylinder(Cylinder : BYTE; DoubleSide : BOOLEAN);
VAR TextString : STRING [2];
	 Column		: BYTE;
BEGIN
	IF MouseAvail THEN MouseOff;							(* Maus ausschalten			*)
	Str(Cylinder, TextString);

	IF Cylinder < 10 THEN									(* Einstellige Zahl			*)
	BEGIN
		PutChar(7, 12, '0', cLightGreen, cBlue);
		PutChar(8, 12, TextString[1], cLightGreen, cBlue);

		IF DoubleSide THEN									(* Zweiseitige Diskette 	*)
		BEGIN
			PutChar(7, 21, '0', cLightGreen, cBlue);
			PutChar(8, 21, TextString[1], cLightGreen, cBlue);
		END;
	END
	ELSE															(* Zweistellige Zahl 		*)
	BEGIN
		PutString(7, 12, TextString, cLightGreen, cBlue);

		IF DoubleSide THEN									(* Zweiseitige Diskette 	*)
			PutString(7, 21, TextString, cLightGreen, cBlue);
	END;

	IF MouseAvail THEN MouseOn;							(* Maus anschalten			*)
END; (* WriteCylinder *)

(* Diese Prozedur ÅberprÅft, ob der Kopiervorgang unterbrochen werden soll *)
FUNCTION CheckBreak : BOOLEAN;
VAR NewEvent : Event;
	 DoBreak  : BOOLEAN;
BEGIN
	CheckBreak := FALSE; 									(* Kopieren fortsetzen		*)

	WHILE IsKeyEvent DO										(* Tastatur Ereignisse		*)
	BEGIN
		GetEvent(NewEvent);									(* Ereignis holen 			*)

		IF NOT NewEvent.Mouse THEN 						(* Tastatur Ereignis 		*)
		BEGIN
			IF NewEvent.ScanCode = 1 THEN 				(* ScanCode der Taste ESC	*)
			BEGIN
				RemoveClock;									(* Uhr anhalten				*)
				DoMessage(' Do You Want To Cancel DiskCopy ?', TRUE, DoBreak);
				CheckBreak := DoBreak;						(* Ergebnis zurÅckgeben 	*)

				WHILE IsEvent DO GetEvent(NewEvent);	(* Alle Ereignisse lîschen *)
				InstallClock;									(* Uhr wieder anschalten	*)
			END;
		END;
	END;
END; (* CheckBreak *)

(* Diese Prozedur gibt eine Nachricht auf dem Bildschirm aus *)
PROCEDURE DoMessage(Message : TextStr; WithExit : BOOLEAN; VAR GetOk : BOOLEAN);
VAR Txt1,
	 Txt2,
	 Txt3   : pIntuiText;
	 Gad1,
	 Gad2   : pGadget;
	 MsgReq : pRequester;
	 Status : BOOLEAN;										(* Status des Requesters	*)
BEGIN
	InitIntuiText(Txt1, 2, 2, cBlack, cMagenta, Message, NIL);
	InitIntuiText(Txt2, 27, 4, cBlack, cMagenta, '', NIL);

	IF WithExit THEN											(* Exit/No Gadgets			*)
	BEGIN
		InitIntuiText(Txt3, 3, 4, cBlack, cMagenta, '', NIL);
		InitGadget(Gad2, 3, 4, 8, 3, Txt3, cWhite, cMagenta, NIL, ExitGadget);
	END
	ELSE Gad2 := NIL;											(* Nur Yes/Ok Gadgets		*)

	InitGadget(Gad1, 27, 4, 8, 3, Txt2, cWhite, cMagenta, Gad2, OkGadget);

	InitRequester(MsgReq, 19, 6, 38, 8, cYellow, cMagenta, ' Message ',
					  [rClose, rMove, rShadow, rTitle, rDouble], Gad1, Txt1);

	Status := OpenRequester(MsgReq);						(* Requester îffnen			*)
	GetOk := GetEndGadget(Gad1) = Gad1;					(* Ok Gadget gedrÅckt		*)

	IF Status THEN Status := CloseRequester(MsgReq);(* Requester schlie·en		*)
END; (* DoMessage *)

(*$F+ Diese Prozedur ist eine Gadgetaktion und schreibt Laufwerkszeichen gro·	*)
PROCEDURE UpCaseDrive(GadgetPtr : pGadget);
BEGIN
	WITH GadgetPtr^ DO
	BEGIN
		Buffer[1] := UpCase(Buffer[1]);					(* Nur Gro·buchstaben		*)

		SetVirtualXY(OneText^.LeftEdge + Length(OneText^.Buffer) + 2,
						 OneText^.TopEdge);

		WriteString(Buffer[1], OneText^.DetailPen, OneText^.BlockPen);
	END;
END; (*$F- UpCaseDrive *)

(* Diese Prozedur kopiert eine Diskette mit einem Laufwerk *)
PROCEDURE DoSingleDrive(VAR Drive : CHAR; EmsUsage, XmsUsage, ExtUsage,
								RamDiskUsage, HardDiskUsage : BOOLEAN;
								NrOfErrorTrials : BYTE;	VerifyTarget, FormatTarget,
								Multiple, Cylinder : BOOLEAN);
VAR DiskTyp  : DiskType;									(* Typ einer Diskette		*)
	 EndCyl,                                    		(* Letzte Spur zu kopieren	*)
	 StartCyl : BYTE;											(* Erste Spur zu kopieren	*)
	 Dummy,														(* Dient als Platzhalter	*)
	 DoCopy	 : BOOLEAN;										(* Kopieren fortsetzen		*)

(* Diese Prozedur wird vor dem Kopieren mit einem Laufwerk aufgerufen *)
PROCEDURE AskSingleDrive(Multiple, Cylinder : BOOLEAN; VAR DoCopy : BOOLEAN;
								 VAR Drive : CHAR);
VAR TxtOk,                   								(* Text des Ok-Gadgets		*)
	 TxtExit,					                        (* Text des Exit-Gadgets	*)
	 TxtText    : pIntuiText;							  	(* Text fÅr Laufwerk    	*)
	 GadOk,             									 	(* Ok-Gadget					*)
	 GadExit,                                       (* Exit-Gadget					*)
	 GadText    : pGadget;                          (* Gadget fÅr Laufwerk		*)
	 ReqTitle   : TextStr;								  	(* Titeltext vom Requester	*)
	 DriveOk,													(* Laufwerksname ist Ok		*)
	 Status 	   : BOOLEAN;								  	(* Status des Requesters	*)
	 DriveReq   : pRequester;							  	(* Requester fÅr Laufwerk	*)
BEGIN
	InitIntuiText(TxtExit, 3, 4, cBlack, cMagenta, '', NIL);
	InitIntuiText(TxtOk, 27, 4, cBlack, cMagenta, '', NIL);

	InitIntuiText(TxtText, 4, 2, cBlack, cMagenta,	(* Eingabe des Laufwerks	*)
					  'Source And Target Drive Is', NIL);

	InitGadget(GadExit, 3, 4, 8, 3, TxtExit, cWhite, cMagenta, NIL, ExitGadget);

	InitGadget(GadText, 4, 2, 26, 1, TxtText, cWhite, cMagenta, GadExit,
				  TextGadget);

	WITH GadText^ DO											(* Textpufferdaten 			*)
	BEGIN
		Buffer := Drive;
		Size := 1;
		Mask := ['A'..'Z', 'a'..'z'];
		DoAction := TRUE;										(* Aktion Gro·buchstaben	*)
		Action := UpCaseDrive;
	END;

	InitGadget(GadOk, 27, 4, 8, 3, TxtOk, cWhite, cMagenta, GadText, OkGadget);

	IF Multiple THEN ReqTitle := ' Multiple Copy '	(* Requestertitel wÑhlen	*)
	ELSE IF Cylinder THEN ReqTitle := ' Cylinder Copy '
	ELSE ReqTitle := ' Single Drive Copy ';

	InitRequester(DriveReq, 20, 7, 38, 8, cYellow, cMagenta, ReqTitle,
					  [rClose, rMove, rShadow, rTitle, rDouble], GadOk, NIL);

	SetKeyStatus(CapsLockKey);								(* CapsLock anschalten		*)
	Status := OpenRequester(DriveReq); 					(* Requester îffnen			*)
	DriveOk := Length(GadText^.Buffer) = 1;	  		(* LÑnge vom Laufwerktext	*)

	IF GetEndGadget(GadOk) = GadOk THEN	   	 		(* Laufwerksname zuweisen	*)
	BEGIN
		IF DriveOk THEN Drive := GadText^.Buffer[1];
		DoCopy := TRUE;	 		  							(* Diskette kopieren			*)
	END
	ELSE DoCopy := FALSE;									(* Kopieren abgebrochen		*)

	IF Status THEN
		Status := CloseRequester(DriveReq);				(* Requester schlie·en		*)

	IF DoCopy AND NOT DriveOk THEN						(* Laufwerkbuchstabe fehlt	*)
	BEGIN
		DoMessage(' Error - Missing Drive Character', FALSE, DoCopy);
		DoCopy := FALSE;										(* Kopieren abgebrochen		*)
	END;

	DelKeyStatus(CapsLockKey);								(* CapsLock ausschalten		*)
END; (* AskSingleDrive *)

(* Diese Prozedur erfragt den Start- und Endcylinder fÅr eine Kopie *)
PROCEDURE AskCylinder(VAR StartCyl, EndCyl : BYTE; VAR DoCopy : BOOLEAN);
VAR TxtOk,                   								(* Text des Ok-Gadgets		*)
	 TxtExit,					                        (* Text des Exit-Gadgets	*)
	 TxtStart,             									(* Text fÅr Startcylinder	*)
	 TxtEnd   : pIntuiText;									(* Text fÅr Endcylinder		*)
	 GadOk,             									 	(* Ok-Gadget					*)
	 GadExit,                                       (* Exit-Gadget					*)
	 GadStart,                                      (* Gadget Endcylinder		*)
	 GadEnd   : pGadget;										(* Gadget Endcylinder		*)
	 CylReq   : pRequester;									(* Requester fÅr Cylinder	*)
	 Dummy,														(* Dient als Platzhalter	*)
	 BufferOk,													(* Inhalte der Puffer Ok	*)
	 Status   : BOOLEAN;										(* Status des Requesters	*)
	 Code     : INTEGER;										(* Umwandlung Text -> Zahl	*)
BEGIN
	InitIntuiText(TxtExit, 3, 5, cBlack, cMagenta, '', NIL);
	InitIntuiText(TxtOk, 21, 5, cBlack, cMagenta, '', NIL);
	InitIntuiText(TxtStart, 5, 2, cBlack, cMagenta, 'Start At Cylinder', NIL);
	InitIntuiText(TxtEnd, 5, 3, cBlack, cMagenta, 'End At Cylinder  ', NIL);

	InitGadget(GadExit, 3, 5, 8, 3, TxtExit, cWhite, cMagenta, NIL, ExitGadget);

	InitGadget(GadEnd, 5, 3, 15, 1, TxtEnd, cWhite, cMagenta, GadExit,
				  TextGadget);

	InitGadget(GadStart, 5, 2, 17, 1, TxtStart, cWhite, cMagenta, GadEnd,
				  TextGadget);

	InitGadget(GadOk, 21, 5, 8, 3, TxtOk, cWhite, cMagenta, GadStart, OkGadget);

	WITH GadStart^ DO											(* Daten fÅr Textgadget		*)
	BEGIN
		Buffer := '00';
		Size := 2;
		Mask := ['0'..'9'];
	END;

	WITH GadEnd^ DO											(* Daten fÅr Textgadget		*)
	BEGIN
		Buffer := '79';
		Size := 2;
		Mask := ['0'..'9'];
	END;

	InitRequester(CylReq, 22, 6, 32, 9, cYellow, cMagenta, ' Set New Cylinder ',
					  [rClose, rMove, rShadow, rTitle, rDouble], GadOk, NIL);

	Status := OpenRequester(CylReq); 					(* Requester îffnen			*)

	BufferOk := NOT ((Length(GadStart^.Buffer) = 0) OR
		(Length(GadEnd^.Buffer) = 0));					(* Cylindernummer fehlt		*)

	IF GetEndGadget(GadOk) = GadOk THEN	   	 		(* Laufwerksname zuweisen	*)
	BEGIN
		Val(GadStart^.Buffer, StartCyl, Code);			(* Text -> Startcylinder	*)
		Val(GadEnd^.Buffer, EndCyl, Code);				(* Text -> Endcylinder		*)
		DoCopy := TRUE;
	END
	ELSE DoCopy := FALSE;									(* Kopieren abgebrochen		*)

	IF Status THEN
		Status := CloseRequester(CylReq);				(* Requester schlie·en		*)

	IF DoCopy THEN												(* Es soll kopiert werden	*)
	BEGIN
		IF StartCyl > EndCyl THEN							(* Start hinter Ende			*)
		BEGIN
			DoCopy := FALSE;
			DoMessage(' Error - StartCyl Greater EndCyl', FALSE, Dummy);
		END
		ELSE IF NOT BufferOk THEN	 						(* Cylindernummer fehlt		*)
		BEGIN
			DoCopy := FALSE;
			DoMessage(' Error - Missing Cylinder Number', FALSE, Dummy);
		END;
	END;
END; (* AskCylinder *)

(* Diese Prozedur kopiert eine Diskette mit einem Laufwerk *)
PROCEDURE SingleCopy(VerifyTarget, FormatTarget : BOOLEAN; Drive : CHAR;
							DiskTyp : DiskType; Multiple, DoCylinder : BOOLEAN;
							StartCyl, EndCyl : BYTE);
Label Demo;														(* Nur fÅr Demo-Version		*)
VAR i,															(* ZÑhler						*)
	 ReadTrack, 												(* Aktuelle Spur Lesen		*)
	 WriteTrack,												(* Aktuelle Spur Schreiben *)
	 RemTrack,													(* Aktuelle Spur merken 	*)
	 Side,														(* Seite einer Diskette 	*)
	 Cylinder,													(* Cylinder einer Diskette *)
	 TrackMax	: BYTE;										(* Maximale Anzahl Spuren	*)
	 CopyBuffer : POINTER;									(* Puffer fÅr Spurdaten 	*)
	 BufferSize : WORD;										(* Grî·e des Puffers 		*)
	 DoCopy, 													(* Kopieren oder nicht		*)
	 DoMultiple,												(* Mehrfachkopien 			*)
	 DoubleSide : BOOLEAN;									(* Einseitg und Zweiseitig *)
BEGIN
	CASE DiskTyp OF											(* Disktyp unterscheiden	*)
		Disk160 :
		BEGIN
			BufferSize := 8 * 512;							(* Speicher fÅr eine Spur	*)
			TrackMax := 40;									(* 40 Spuren insgesamt		*)
			DoubleSide := FALSE; 							(* Einseitige Disketten 	*)
		END;

		Disk320 :
		BEGIN
			BufferSize := 8 * 512;							(* Speicher fÅr eine Spur	*)
			TrackMax := 80;									(* 80 Spuren insgesamt		*)
			DoubleSide := TRUE;								(* Zweiseitige Disketten	*)
		END;

		Disk180 :
		BEGIN
			BufferSize := 9 * 512;							(* Speicher fÅr eine Spur	*)
			TrackMax := 40;									(* 40 Spuren insgesamt		*)
			DoubleSide := FALSE; 							(* Einseitige Disketten 	*)
		END;

		Disk360 :
		BEGIN
			BufferSize := 9 * 512;							(* Speicher fÅr eine Spur	*)
			TrackMax := 80;									(* 80 Spuren insgesamt		*)
			DoubleSide := TRUE;								(* Zweiseitige Disketten	*)
		END;

		Disk720 :
		BEGIN
			BufferSize := 9 * 512;							(* Speicher fÅr eine Spur	*)
			TrackMax := 160;									(* 160 Spuren insgesamt 	*)
			DoubleSide := TRUE;								(* Zweiseitige Disketten	*)
		END;

		Disk1200 :
		BEGIN
			BufferSize := 15 * 512; 						(* Speicher fÅr eine Spur	*)
			TrackMax := 160;									(* 160 Spuren insgesamt 	*)
			DoubleSide := TRUE;								(* Zweiseitige Disketten	*)
		END;

		Disk1440 :
		BEGIN
			BufferSize := 18 * 512; 						(* Speicher fÅr eine Spur	*)
			TrackMax := 160;									(* 160 Spuren insgesamt 	*)
			DoubleSide := TRUE;								(* Zweiseitige Disketten	*)
		END;
	END;

	IF DoCylinder THEN  										(* Cylinder kopieren			*)
	BEGIN
		IF (StartCyl >= (TrackMax DIV (Ord(DoubleSide) + 1))) OR
			(EndCyl >= (TrackMax DIV (Ord(DoubleSide) + 1))) THEN
		BEGIN
			RemoveClock;
			DoMessage(' Error - Illegal Cylinder Number', FALSE, DoCopy);
			Exit;													(* Prozedur vorzeitig Ende	*)
		END
		ELSE														(* Cylinderwerte sind Ok	*)
		BEGIN
			ReadTrack := StartCyl * (Ord(DoubleSide) + 1);
			WriteTrack := ReadTrack;
			TrackMax := (EndCyl + 1) * (Ord(DoubleSide) + 1);
		END;
	END
	ELSE
	BEGIN
		ReadTrack := 0;										(* Startwerte					*)
		WriteTrack := 0;
	END;

	GetMem(CopyBuffer, BufferSize);						(* Speicher belegen			*)

	REPEAT														(* Gesamte Disk kopieren	*)
		FreeMemory; 											(* Alle Speicherblîcke weg *)
		FillDriveInfo(Drive);								(* DriveInfoBlock fÅllen	*)

		REPEAT													(* Diskette lesen 			*)
			IF CheckBreak THEN								(* Kopiervorgang abbrechen *)
			BEGIN
				FreeMem(CopyBuffer, BufferSize); 		(* Speicher freigeben		*)
				Exit; 											(* Aktuelle Prozedur Ende	*)
			END;

			Side := Ord(Odd(ReadTrack) AND DoubleSide);

			IF DoubleSide THEN								(* Diskette ist zweiseitig *)
				Cylinder := ReadTrack SHR 1				(* Aktueller Cylinder		*)
			ELSE Cylinder := ReadTrack;

			WriteCylinder(Cylinder, DoubleSide);		(* Cylinder auf Bildschirm *)
			WriteToGate('R', Cylinder, Side, cYellow, cRed);
			ReadStandard(Drive, Side, Cylinder, DiskTyp, CopyBuffer);

			IF DiskStatus <> DiskStatusOk THEN			(* Disketten Lesefehler 	*)
			BEGIN
				WriteToGate('E', Cylinder, Side, cYellow, cRed);
				FillChar(CopyBuffer^, BufferSize, 0);	(* Mit Nullen auffÅllen 	*)
			END;

			WriteToMemory(CopyBuffer, BufferSize); 	(* Puffer in Speicher		*)
			WriteUsedMemory;									(* Verwendeter Speicher 	*)
			Inc(ReadTrack);									(* NÑchste Spur				*)
		UNTIL (ReadTrack = TrackMax) OR (MemoryStatus <> MemoryStatusOk);

		IF MemoryStatus = NotEnoughMemory THEN 		(* Speicher ist voll 		*)
		BEGIN
			WriteToGate(' ', Cylinder, Side, cLightMagenta, cBlue);
			Dec(ReadTrack);									(* Spur nicht im Speicher	*)
			RemoveClock;										(* Uhr anhalten				*)
			Write(Chr(7)); 									(* Piepston klingen lassen *)

			DoMessage('  Insert Target Disk In Drive ' + Drive + ':', TRUE,
						 DoCopy);

			InstallClock;										(* Uhr wieder anschalten	*)

			IF NOT DoCopy THEN								(* Kopieren abgebrochen 	*)
			BEGIN
				FreeMem(CopyBuffer, BufferSize); 		(* Speicher freigeben		*)
				Exit; 											(* Aktuelle Prozedur Ende	*)
			END;
		END
		ELSE IF MemoryStatus = MemoryStatusOk THEN	(* Komplette Disk gelesen	*)
		BEGIN
			RemoveClock;										(* Uhr anhalten				*)
			Write(Chr(7)); 									(* Piepston klingen lassen *)

			DoMessage('  Insert Target Disk In Drive ' + Drive + ':', TRUE,
						 DoCopy);

			InstallClock;										(* Uhr wieder anschalten	*)

			IF NOT DoCopy THEN								(* Kopieren abgebrochen 	*)
			BEGIN
				FreeMem(CopyBuffer, BufferSize); 		(* Speicher freigeben		*)
				Exit; 											(* Aktuelle Prozedur Ende	*)
			END;
		END
		ELSE														(* Schwerer Speicherfehler *)
		BEGIN
			RemoveClock;										(* Uhr anhalten				*)
			DoMessage(' Error - Failure In Memory System', FALSE, DoCopy);
			FreeMem(CopyBuffer, BufferSize); 			(* Speicher freigeben		*)
			Exit; 												(* Aktuelle Prozedur Ende	*)
		END;

		DoMultiple := TRUE;									(* Standardwert				*)
		RemTrack := WriteTrack; 							(* Aktuelle Spur merken 	*)

		GOTO Demo;												(* Abbruch Demo-Version		*)

		REPEAT													(* Disk mehrfach schreiben *)
			FillDriveInfo(Drive);							(* DriveInfoBlock fÅllen	*)

			REPEAT												(* Diskette schreiben		*)
				IF CheckBreak THEN							(* Kopiervorgang abbrechen *)
				BEGIN
					FreeMem(CopyBuffer, BufferSize); 	(* Speicher freigeben		*)
					Exit; 										(* Aktuelle Prozedur Ende	*)
				END;

				Side := Ord(Odd(WriteTrack) AND DoubleSide);

				IF DoubleSide THEN							(* Diskette ist zweiseitig *)
					Cylinder := WriteTrack SHR 1			(* Aktueller Cylinder		*)
				ELSE Cylinder := WriteTrack;

				WriteCylinder(Cylinder, DoubleSide);	(* Cylinder auf Bildschirm *)

				IF FormatTarget THEN 						(* Diskette formatieren 	*)
				BEGIN
					WriteToGate('F', Cylinder, Side, cYellow, cRed);
					FormatStandard(Drive, Side, Cylinder, DiskTyp);

					IF DiskStatus = WriteProtectOn THEN
					BEGIN
						RemoveClock; 							(* Uhr anhalten				*)
						DoMessage('   Error - Remove Write Protect', TRUE, DoCopy);
						InstallClock; 							(* Uhr wieder anschalten	*)

						IF DoCopy THEN 						(* Weiterkopieren 			*)
						BEGIN
							FormatStandard(Drive, Side, Cylinder, DiskTyp);

							IF DiskStatus <> DiskStatusOk THEN
								WriteToGate('E', Cylinder, Side, cYellow, cRed);
						END
						ELSE	  									(* Kopieren abgebrochen 	*)
						BEGIN
							FreeMem(CopyBuffer, BufferSize);
							Exit; 							   (* Aktuelle Prozedur Ende	*)
						END;
					END
					ELSE IF DiskStatus <> DiskStatusOk THEN
						WriteToGate('E', Cylinder, Side, cYellow, cRed);
				END;

				ReadFromMemory(CopyBuffer);				(* Speicher in Puffer		*)
				WriteUsedMemory;								(* Verwendeter Speicher 	*)

				IF MemoryStatus <> MemoryStatusOk THEN (* Schwerer Speicherfehler *)
				BEGIN
					RemoveClock;	 							(* Uhr anhalten				*)
					DoMessage(' Error - Failure In Memory System', FALSE, DoCopy);
					FreeMem(CopyBuffer, BufferSize); 	(* Speicher freigeben		*)
					Exit; 										(* Aktuelle Prozedur Ende	*)
				END;

				WriteToGate('W', Cylinder, Side, cYellow, cRed);
				WriteStandard(Drive, Side, Cylinder, DiskTyp, CopyBuffer);

				IF DiskStatus = DiskStatusOk THEN		(* Alles in Ordnung			*)
					WriteToGate(Chr(7), Cylinder, Side, cYellow, cRed)
				ELSE IF DiskStatus = WriteProtectOn THEN
				BEGIN
					RemoveClock; 								(* Uhr anhalten				*)
					DoMessage('   Error - Remove Write Protect', TRUE, DoCopy);
					InstallClock; 								(* Uhr wieder anschalten	*)

					IF DoCopy THEN 							(* Weiterkopieren 			*)
					BEGIN
						WriteStandard(Drive, Side, Cylinder, DiskTyp, CopyBuffer);

						IF DiskStatus = DiskStatusOk THEN
							WriteToGate(Chr(7), Cylinder, Side, cYellow, cRed)
						ELSE WriteToGate('E', Cylinder, Side, cYellow, cRed);
					END
					ELSE											(* Kopieren abgebrochen 	*)
					BEGIN
						FreeMem(CopyBuffer, BufferSize); (* Speicher freigeben		*)
						Exit; 									(* Aktuelle Prozedur Ende	*)
					END;
				END
				ELSE												(* Diskette Schreibfehler	*)
				BEGIN
					IF FormatTarget THEN
						WriteToGate('E', Cylinder, Side, cYellow, cRed)
					ELSE
					BEGIN      
						RemoveClock; 	 						(* Uhr anhalten				*)
						DoMessage('Error - Try To Format Target Disk', TRUE, DoCopy);
						InstallClock; 							(* Uhr wieder anschalten	*)

						IF DoCopy THEN							(* Target Disk formatieren	*)
						BEGIN
							FormatTarget := TRUE;

							WriteToGate('F', Cylinder, Side, cYellow, cRed);
							FormatStandard(Drive, Side, Cylinder, DiskTyp);

							WriteToGate('W', Cylinder, Side, cYellow, cRed);
							WriteStandard(Drive, Side, Cylinder, DiskTyp, CopyBuffer);

							IF DiskStatus = DiskStatusOk THEN
								WriteToGate(Chr(7), Cylinder, Side, cYellow, cRed)
							ELSE WriteToGate('E', Cylinder, Side, cYellow, cRed);
						END
						ELSE WriteToGate('E', Cylinder, Side, cYellow, cRed);
					END;
				END;

				IF VerifyTarget AND (DiskStatus = DiskStatusOk) THEN
				BEGIN												(* Diskette ÅberprÅfen		*)
					WriteToGate('V', Cylinder, Side, cYellow, cRed);
					VerifyStandard(Drive, Side, Cylinder, DiskTyp, CopyBuffer);

					IF DiskStatus = DiskStatusOk THEN
						WriteToGate(Chr(7), Cylinder, Side, cYellow, cRed)
					ELSE WriteToGate('E', Cylinder, Side, cYellow, cRed);
				END;

				Inc(WriteTrack);								(* NÑchste Spur				*)
			UNTIL WriteTrack = ReadTrack;

			IF Multiple THEN									(* Disk mehrfach kopieren	*)
			BEGIN
				RemoveClock;  			 						(* Uhr anhalten				*)
				Write(Chr(7)); 								(* Piepston klingen lassen *)

				DoMessage('  Insert Target Disk In Drive ' + Drive + ':', TRUE,
							 DoCopy);

				InstallClock; 									(* Uhr wieder anschalten	*)

				IF DoCopy THEN 								(* Disk mehrfach kopieren	*)
				BEGIN
					FOR i := RemTrack TO WriteTrack - 1 DO
						WriteToGate('R', i SHR 1, Ord(Odd(i) AND DoubleSide),
										cYellow, cRed);		(* Bereich wurde gelesen	*)

					WriteTrack := RemTrack; 				(* Ab dieser Spur kopieren *)
				END
				ELSE DoMultiple := FALSE;					(* Mehrfachkopie abbrechen *)
			END
			ELSE DoMultiple := FALSE;						(* Disk einfach kopieren	*)

			IF (NOT DoMultiple) AND							(* Keine Mehrfachkopie		*)
				(WriteTrack < TrackMax) THEN		 		(* Noch nicht fertig 		*)
			BEGIN
				RemoveClock; 	 								(* Uhr anhalten				*)
				Write(Chr(7)); 								(* Piepston klingen lassen *)

				DoMessage('  Insert Source Disk In Drive ' + Drive + ':',
							 TRUE, DoCopy);

				InstallClock; 									(* Uhr wieder anschalten	*)

				IF NOT DoCopy THEN							(* Kopiervorgang abbrechen *)
				BEGIN
					FreeMem(CopyBuffer, BufferSize);
					Exit; 										(* Aktuelle Prozedur Ende	*)
				END;
			END;
		UNTIL NOT DoMultiple;
	UNTIL WriteTrack = TrackMax;							(* Bis alles geschrieben	*)

Demo:

	FreeMem(CopyBuffer, BufferSize); 					(* Speicher freigeben		*)
	RemoveClock;												(* Die Uhr wird entfernt	*)
	Write(Chr(7)); 											(* Piepston klingen lassen *)
	DoMessage('S O R R Y, D E M O V E R S I O N !', FALSE, DoCopy);
	DoMessage('  ØØ Venus DiskCopy Completed ÆÆ', FALSE, DoCopy);
END; (* SingleCopy *)

BEGIN (* DoSingleDrive *)
	AskSingleDrive(Multiple, Cylinder, DoCopy, Drive);

	IF DoCopy THEN 											(* Eine Diskette kopieren	*)
	BEGIN
		IF Cylinder THEN										(* Erste und letzte Spur	*)
			AskCylinder(StartCyl, EndCyl, DoCopy);

		IF DoCopy THEN											(* Kopieren fortsetzen		*)
		BEGIN
			DoMessage('  Insert Source Disk In Drive ' + Drive + ':', TRUE,
						 DoCopy);

			IF DoCopy THEN   									(* Eine Diskette kopieren	*)
			BEGIN
				IF Multiple THEN						  		(* Disk mehrfach kopieren	*)
					PutString(0, 0, ' MULTIPLE COPY ', cYellow, cRed)
				ELSE IF Cylinder THEN				  		(* Cylinder kopieren			*)
					PutString(0, 0, ' CYLINDER COPY ', cYellow, cRed)
				ELSE     								  		(* Normale Einzelkopie		*)
				BEGIN
					PutString(0, 0, ' SINGLE DRIVE ', cYellow, cRed);
					PutChar(14, 0, ' ', cBlack, cCyan);
				END;

				DiskTyp := GetDiskType(Drive);	  		(* Typ der Diskette			*)

				CASE DiskTyp OF						  		(* Disktyp unterscheiden	*)
					UnknownDisk   :
						DoMessage(' Error - Type Of Disk Is Illegal', FALSE, Dummy);

					DiskFailure   :
						DoMessage('   Error - Disk Has Read Errors', FALSE, Dummy);

					DriveNotReady :
						DoMessage(' Error - Disk Drive Is Not Ready', FALSE, Dummy);

					UnknownDrive  :
						DoMessage('  Error - Drive Is Not Installed', FALSE, Dummy);

					HardDisk, RamDisk :
						DoMessage(' Error - Type Of Drive Is Illegal', FALSE, Dummy);

					ELSE					  						(* Alles in Ordnung			*)
						ReleaseCodeOff;  						(* Keine Release Codes		*)
						WriteUnusedGate(DiskTyp);
						WriteDiskType(DiskTyp);
						SaveDriveInfo;
						SetTrials(NrOfErrorTrials);

						InitMemory(TRUE, XmsUsage, ExtUsage, EmsUsage, RamDiskUsage,
									  HardDiskUsage, TRUE, ' ');

						InitClock;								(* Uhr initialisieren		*)
						InstallClock;							(* Ab jetzt lÑuft die Uhr	*)

						SingleCopy(VerifyTarget, FormatTarget, Drive, DiskTyp,
									  Multiple, Cylinder, StartCyl, EndCyl);

						RemoveClock;							(* Die Uhr wird entfernt	*)
						DelMemory;
						LoadDriveInfo;
						ResetDiskDrives;
						ClearGate;
						ReleaseCodeOn; 						(* Tasten Release Codes 	*)
				END;
			END;
		END;
	END;
END; (* DoSingleDrive *)

(* Diese Prozedur kopiert eine Diskette mit zwei Laufwerken *)
PROCEDURE DoDualDrive(VAR DriveA, DriveB : CHAR; NrOfErrorTrials : BYTE;
							 VerifyTarget, FormatTarget : BOOLEAN);
VAR DiskTypA,
	 DiskTypB : DiskType;
	 Dummy,
	 DoCopy	 : BOOLEAN;

(* Diese Prozedur wird vor dem Kopieren mit zwei Laufwerken aufgerufen *)
PROCEDURE AskDualDrive(VAR DoCopy : BOOLEAN; VAR DriveA, DriveB : CHAR);
VAR TxtOk,                   								(* Text des Ok-Gadgets		*)
	 TxtExit,					                        (* Text des Exit-Gadgets	*)
	 TxtAText,                                      (* Text von Laufwerk A:		*)
	 TxtBText  : pIntuiText;  								(* Text von Laufwerk B: 	*)
	 GadOk,             									 	(* Ok-Gadget					*)
	 GadExit,                                       (* Exit-Gadget					*)
	 GadAText, 													(* Gadget fÅr Laufwerk A:	*)
	 GadBText : pGadget;                            (* Gadget fÅr Laufwerk B: 	*)
	 DrivesOk, 													(* Laufwerksnamen sind Ok	*)
	 Status 	 : BOOLEAN;										(* Status des Requesters	*)
	 DriveReq : pRequester;									(* Requester fÅr Laufwerk	*)
BEGIN
	InitIntuiText(TxtExit, 3, 5, cBlack, cMagenta, '', NIL);
	InitIntuiText(TxtOk, 23, 5, cBlack, cMagenta, '', NIL);

	InitIntuiText(TxtAText, 5, 2, cBlack, cMagenta,	(* Eingabe des Laufwerks	*)
					  'Source Disk Drive Is', NIL);

	InitIntuiText(TxtBText, 5, 3, cBlack, cMagenta,	(* Eingabe des Laufwerks	*)
					  'Target Disk Drive Is', NIL);

	InitGadget(GadExit, 3, 5, 8, 3, TxtExit, cWhite, cMagenta, NIL, ExitGadget);

	InitGadget(GadBText, 5, 3, 20, 1, TxtBText, cWhite, cMagenta, GadExit,
				  TextGadget);

	InitGadget(GadAText, 5, 2, 20, 1, TxtAText, cWhite, cMagenta, GadBText,
				  TextGadget);

	WITH GadAText^ DO											(* Textpufferdaten fÅr A:	*)
	BEGIN
		Buffer := DriveA;
		Size := 1;
		Mask := ['A'..'Z', 'a'..'z'];
		DoAction := TRUE;										(* Aktion Gro·buchstaben	*)
		Action := UpCaseDrive;
	END;

	WITH GadBText^ DO											(* Textpufferdaten fÅr B:	*)
	BEGIN
		Buffer := DriveB;
		Size := 1;
		Mask := ['A'..'Z', 'a'..'z'];
		DoAction := TRUE;										(* Aktion Gro·buchstaben	*)
		Action := UpCaseDrive;
	END;

	InitGadget(GadOk, 23, 5, 8, 3, TxtOk, cWhite, cMagenta, GadAText, OkGadget);

	InitRequester(DriveReq, 21, 7, 34, 9, cYellow, cMagenta, ' Dual Drive Copy ',
					  [rClose, rMove, rShadow, rTitle, rDouble], GadOk, NIL);

	SetKeyStatus(CapsLockKey);								(* CapsLock anschalten		*)
	Status := OpenRequester(DriveReq); 					(* Requester îffnen			*)

	DrivesOk := (Length(GadAText^.Buffer) = 1) AND
		(Length(GadBText^.Buffer) = 1);					(* Laufwerksnamen sind Ok	*)

	IF GetEndGadget(GadOk) = GadOk THEN	  		 		(* Laufwerksname zuweisen	*)
	BEGIN
		IF DrivesOk THEN 	  									(* Laufwerksnamen sind Ok	*)
		BEGIN
			DriveA := GadAText^.Buffer[1];
			DriveB := GadBText^.Buffer[1];
		END;

		DoCopy := TRUE;										(* Diskette kopieren			*)
	END
	ELSE DoCopy := FALSE;									(* Kopieren abgebrochen		*)

	IF Status THEN
		Status := CloseRequester(DriveReq);				(* Requester schlie·en		*)

	IF DoCopy AND NOT DrivesOk THEN						(* Laufwerknamen falsch		*)
	BEGIN
		DoMessage(' Error - Missing Drive Character ', FALSE, DoCopy);
		DoCopy := FALSE;										(* Kopieren abgebrochen		*)
	END;

	DelKeyStatus(CapsLockKey);								(* CapsLock ausschalten		*)
END; (* AskDualDrive *)

(* Diese Prozedur kopiert eine Diskette mit zwei Laufwerken *)
PROCEDURE DualCopy(VerifyTarget, FormatTarget : BOOLEAN; DriveA, DriveB : CHAR;
						 DiskTyp : DiskType);
VAR Cylinder,													(* Cylinder einer Diskette *)
	 CylinderMax : BYTE; 									(* Grî·te Anzahl Cylinder	*)
	 CopyBuffer0,												(* Puffer fÅr Seite 0		*)
	 CopyBuffer1 : POINTER; 								(* Puffer fÅr Seite 1		*)
	 BufferSize  : WORD; 									(* Grî·e des Puffers 		*)
	 DoCopy, 													(* Kopieren oder nicht		*)
	 DoubleSide  : BOOLEAN; 								(* Einseitg und Zweiseitig *)

(* Diese Prozedur liest eine Spur in einen Puffer *)
PROCEDURE ReadTrack(Side : BYTE; CopyBuffer : POINTER);
BEGIN
	WriteToGate('R', Cylinder, Side, cYellow, cRed);
	ReadStandard(DriveA, Side, Cylinder, DiskTyp, CopyBuffer);

	IF DiskStatus <> DiskStatusOk THEN					(* Disketten Lesefehler 	*)
	BEGIN
		WriteToGate('E', Cylinder, Side, cYellow, cRed);
		FillChar(CopyBuffer^, BufferSize, 0);			(* Mit Nullen auffÅllen 	*)
	END;
END; (* ReadTrack *)

(* Diese Funktion schreibt eine Spur aus einem Puffer *)
FUNCTION WriteTrack(Side : BYTE; CopyBuffer : POINTER) : BOOLEAN;
BEGIN
	IF FormatTarget THEN 									(* Diskette formatieren 	*)
	BEGIN
		WriteToGate('F', Cylinder, Side, cYellow, cRed);
		FormatStandard(DriveB, Side, Cylinder, DiskTyp);

		IF DiskStatus = WriteProtectOn THEN				(* Schreibschutz an			*)
		BEGIN
			RemoveClock;									  	(* Uhr anhalten				*)
			DoMessage('   Error - Remove Write Protect', TRUE, DoCopy);
			InstallClock;										(* Uhr wieder anschalten	*)

			IF DoCopy THEN 									(* Weiterkopieren				*)
				FormatStandard(DriveB, Side, Cylinder, DiskTyp)
			ELSE	  												(* Kopieren abgebrochen 	*)
			BEGIN
				WriteTrack := FALSE;
				Exit; 											(* Aktuelle Prozedur Ende	*)
			END;
		END;
	END;

	WriteToGate('W', Cylinder, Side, cYellow, cRed);
	WriteStandard(DriveB, Side, Cylinder, DiskTyp, CopyBuffer);

	IF DiskStatus = DiskStatusOk THEN					(* Alles in Ordnung			*)
		WriteToGate(Chr(7), Cylinder, Side, cYellow, cRed)
	ELSE IF DiskStatus = WriteProtectOn THEN
	BEGIN
		RemoveClock;										  	(* Uhr anhalten				*)
		DoMessage('   Error - Remove Write Protect', TRUE, DoCopy);
		InstallClock;	 		  								(* Uhr wieder anschalten	*)

		IF DoCopy THEN 										(* Weiterkopieren 			*)
		BEGIN
			WriteStandard(DriveB, Side, Cylinder, DiskTyp, CopyBuffer);

			IF DiskStatus = DiskStatusOk THEN
				WriteToGate(Chr(7), Cylinder, Side, cYellow, cRed)
			ELSE WriteToGate('E', Cylinder,	Side, cYellow, cRed);
		END
		ELSE														(* Kopieren abgebrochen 	*)
		BEGIN
			WriteTrack := FALSE;
			Exit; 												(* Aktuelle Prozedur Ende	*)
		END;
	END
	ELSE															(* Diskette Schreibfehler	*)
	BEGIN
		IF FormatTarget THEN
			WriteToGate('E', Cylinder, Side, cYellow, cRed)
		ELSE
		BEGIN
			RemoveClock;									  	(* Uhr anhalten				*)
			DoMessage('Error - Try To Format Target Disk', TRUE, DoCopy);
			InstallClock;										(* Uhr wieder anschalten	*)

			IF DoCopy THEN										(* Target Disk formatieren	*)
			BEGIN
				FormatTarget := TRUE;

				WriteToGate('F', Cylinder, Side, cYellow, cRed);
				FormatStandard(DriveB, Side, Cylinder, DiskTyp);

				WriteToGate('W', Cylinder, Side, cYellow, cRed);
				WriteStandard(DriveB, Side, Cylinder, DiskTyp, CopyBuffer);

				IF DiskStatus = DiskStatusOk THEN
					WriteToGate(Chr(7), Cylinder, Side, cYellow, cRed)
				ELSE WriteToGate('E', Cylinder, Side, cYellow, cRed);
			END
			ELSE WriteToGate('E', Cylinder, Side, cYellow, cRed);
		END;
	END;

	IF VerifyTarget AND (DiskStatus = DiskStatusOk) THEN
	BEGIN															(* Diskette ÅberprÅfen		*)
		WriteToGate('V', Cylinder, Side, cYellow, cRed);
		VerifyStandard(DriveB, Side, Cylinder, DiskTyp, CopyBuffer);

		IF DiskStatus = DiskStatusOk THEN
			WriteToGate(Chr(7), Cylinder, Side, cYellow, cRed)
		ELSE WriteToGate('E', Cylinder, Side, cYellow, cRed);
	END;

	WriteTrack := TRUE;										(* Alles in Ordnung			*)
END; (* WriteTrack *)

BEGIN (* DualCopy *)
	CASE DiskTyp OF											(* Disktyp unterscheiden	*)
		Disk160 :
		BEGIN
			BufferSize := 8 * 512;							(* Speicher fÅr eine Spur	*)
			CylinderMax := 39;								(* 40 Cylinder insgesamt	*)
			DoubleSide := FALSE; 							(* Einseitige Disketten 	*)
		END;

		Disk320 :
		BEGIN
			BufferSize := 8 * 512;							(* Speicher fÅr eine Spur	*)
			CylinderMax := 39;								(* 40 Cylinder insgesamt	*)
			DoubleSide := TRUE;								(* Zweiseitige Disketten	*)
		END;

		Disk180 :
		BEGIN
			BufferSize := 9 * 512;							(* Speicher fÅr eine Spur	*)
			CylinderMax := 39;								(* 40 Cylinder insgesamt	*)
			DoubleSide := FALSE; 							(* Einseitige Disketten 	*)
		END;

		Disk360 :
		BEGIN
			BufferSize := 9 * 512;							(* Speicher fÅr eine Spur	*)
			CylinderMax := 39;								(* 40 Cylinder insgesamt	*)
			DoubleSide := TRUE;								(* Zweiseitige Disketten	*)
		END;

		Disk720 :
		BEGIN
			BufferSize := 9 * 512;							(* Speicher fÅr eine Spur	*)
			CylinderMax := 79;								(* 80 Cylinder insgesamt	*)
			DoubleSide := TRUE;								(* Zweiseitige Disketten	*)
		END;

		Disk1200 :
		BEGIN
			BufferSize := 15 * 512; 						(* Speicher fÅr eine Spur	*)
			CylinderMax := 79;								(* 80 Cylinder insgesamt	*)
			DoubleSide := TRUE;								(* Zweiseitige Disketten	*)
		END;

		Disk1440 :
		BEGIN
			BufferSize := 18 * 512; 						(* Speicher fÅr eine Spur	*)
			CylinderMax := 79;								(* 80 Cylinder insgesamt	*)
			DoubleSide := TRUE;								(* Zweiseitige Disketten	*)
		END;
	END;

	GetMem(CopyBuffer0, BufferSize); 					(* Speicher belegen			*)
	GetMem(CopyBuffer1, BufferSize); 					(* Speicher belegen			*)

	FillDriveInfo(DriveA);									(* DriveInfoBlock fÅllen A	*)
	FillDriveInfo(DriveB);									(* DriveInfoBlock fÅllen B	*)

	FOR Cylinder := 0 TO CylinderMax DO 				(* Ganze Diskette kopieren *)
	BEGIN
		IF CheckBreak THEN									(* Kopiervorgang abbrechen *)
		BEGIN
			FreeMem(CopyBuffer0, BufferSize);			(* Speicher freigeben		*)
			FreeMem(CopyBuffer1, BufferSize);			(* Speicher freigeben		*)
			Exit; 												(* Aktuelle Prozedur Ende	*)
		END;

		WriteCylinder(Cylinder, DoubleSide);			(* Cylinder auf Bildschirm *)
		ReadTrack(0, CopyBuffer0); 						(* Spur auf Seite 0 lesen	*)

		IF DoubleSide THEN									(* Diskette ist zweiseitig *)
			ReadTrack(1, CopyBuffer1); 					(* Spur auf Seite 1 lesen	*)

		IF NOT WriteTrack(0, CopyBuffer0) THEN 		(* Spur Seite 0 schreiben	*)
		BEGIN
			FreeMem(CopyBuffer0, BufferSize);			(* Speicher freigeben		*)
			FreeMem(CopyBuffer1, BufferSize);			(* Speicher freigeben		*)
			Exit; 												(* Aktuelle Prozedur Ende	*)
		END;

		IF DoubleSide THEN									(* Diskette ist zweiseitig *)
		BEGIN
			IF NOT WriteTrack(1, CopyBuffer1) THEN 	(* Spur Seite 1 schreiben	*)
			BEGIN
				FreeMem(CopyBuffer0, BufferSize);		(* Speicher freigeben		*)
				FreeMem(CopyBuffer1, BufferSize);		(* Speicher freigeben		*)
				Exit; 											(* Aktuelle Prozedur Ende	*)
			END;
		END;
	END;

	FreeMem(CopyBuffer0, BufferSize);					(* Speicher freigeben		*)
	FreeMem(CopyBuffer1, BufferSize);					(* Speicher freigeben		*)
	RemoveClock;												(* Die Uhr wird entfernt	*)
	Write(Chr(7)); 											(* Piepston klingen lassen *)
	DoMessage('  ØØ Venus DiskCopy Completed ÆÆ', FALSE, DoCopy);
END; (* DualCopy *)

BEGIN (* DoDualDrive *)
	AskDualDrive(DoCopy, DriveA, DriveB);				(* Laufwerke erfragen		*)

	IF DoCopy THEN 											(* Eine Diskette kopieren	*)
	BEGIN
		IF DriveA = DriveB THEN 							(* Verschiedene Laufwerke	*)
			DoMessage(' Error - Drives Must Be Different', FALSE, DoCopy)
		ELSE IF NrOfDiskDrives = 1 THEN					(* Nur ein Laufwerk da		*)
			DoMessage(' Error - Only One Drive Installed', FALSE, DoCopy)
		ELSE
		BEGIN
			DoMessage('Insert Source Disk And Target Disk', TRUE, DoCopy);

			IF DoCopy THEN 									(* Eine Diskette kopieren	*)
			BEGIN
				PutString(0, 0, ' DUAL DRIVE ', cYellow, cRed);
				PutString(12, 0, '   ', cBlack, cCyan);

				DiskTypA := GetDiskType(DriveA); 		(* Typ der Quelldiskette	*)
				DiskTypB := GetDiskType(DriveB); 		(* Typ der Zieldiskette 	*)

				CASE DiskTypA OF								(* Disktyp unterscheiden	*)
					UnknownDisk   :
						DoMessage(' Error - Unknown Disk In Drive ' + DriveA + ':',
									 FALSE, Dummy);

					DiskFailure   :
						DoMessage('  Error - Disk Read Error In ' + DriveA + ':',
									 FALSE, Dummy);

					DriveNotReady :
						DoMessage('  Error - Drive ' + DriveA + ': Is Not Ready',
									 FALSE, Dummy);

					UnknownDrive  :
						DoMessage('Error - Drive ' + DriveA + ': Is Not Installed',
									 FALSE, Dummy);

					HardDisk, RamDisk :
						DoMessage('Error - DriveType Of ' + DriveA + ': Is Illegal',
									 FALSE, Dummy);

				ELSE												(* Alles in Ordnung			*)
					CASE DiskTypB OF							(* Disktyp unterscheiden	*)
						DriveNotReady :
							DoMessage('Error - Drive ' + DriveB + ': Is Not Ready',
										 FALSE, Dummy);

						UnknownDrive  :
							DoMessage('Error - Drive ' + DriveB + ': Is Not Installed',
										 FALSE, Dummy);

						HardDisk, RamDisk :
							DoMessage('Error - DriveType Of ' + DriveB +
										 ': Is Illegal', FALSE, Dummy);

					ELSE											(* Alles in Ordnung			*)
						ReleaseCodeOff;						(* Keine Release Codes		*)
						WriteUnusedGate(DiskTypA);
						WriteDiskType(DiskTypA);
						SaveDriveInfo;
						SetTrials(NrOfErrorTrials);
						InitClock;								(* Uhr initialisieren		*)
						InstallClock;							(* Ab jetzt lÑuft die Uhr	*)

						DualCopy(VerifyTarget, FormatTarget, DriveA, DriveB,
									DiskTypA);

						RemoveClock;							(* Die Uhr wird entfernt	*)
						LoadDriveInfo;
						ResetDiskDrives;
						ClearGate;
						ReleaseCodeOn; 						(* Tasten Release Codes 	*)
					END;
				END;
			END;
		END;
	END;
END; (* DoDualDrive *)

(* Diese Prozedur legt eine Gesamtkopie einer Diskette auf Festplatte ab *)
PROCEDURE DoImageToHd(VAR SourceDrive, TargetHardDisk : CHAR; VAR ToHd : STRING;
							 NrOfErrorTrials : BYTE; HardDiskUsage : BOOLEAN);
CONST CompleteLen = 30;										(* Komplette NamenslÑnge	*)
TYPE CompleteStr = STRING[CompleteLen];		  		(* Typ eines Dateinamens	*)

VAR TempFile  : FILE;										(* TemporÑre Datei 			*)
	 DiskTypA,                  							(* Typ des Quelllaufwerks	*)
	 DiskTypHD : DiskType;									(* Typ des Ziellaufwerks	*)
	 Dummy,   													(* Dient als Platzhalter	*)
	 Status,														(* Kopierstatus Ok			*)
	 DoCopy 	  : BOOLEAN;   	  							(* Kopieren abbrechen		*)

(* Diese Prozedur wird vor dem Kopieren mit zwei Laufwerken aufgerufen *)
PROCEDURE AskImageToHd(VAR DoCopy : BOOLEAN; VAR DriveA, Partition : CHAR;
							  VAR FileName : CompleteStr);
VAR TxtOk,                   								(* Text des Ok-Gadgets		*)
	 TxtExit,					                        (* Text des Exit-Gadgets	*)
	 TxtTemp,  													(* Text temporÑre Datei		*)
	 TxtAText,                                      (* Text von Laufwerk A:		*)
	 TxtHdText : pIntuiText;  								(* Text von Harddisk		 	*)
	 GadOk,             									 	(* Ok-Gadget					*)
	 GadExit,                                       (* Exit-Gadget					*)
	 GadTemp,  													(* Gadget temporÑre Datei	*)
	 GadAText, 													(* Gadget fÅr Laufwerk A:	*)
	 GadHdText : pGadget;                           (* Gadget fÅr Harddisk		*)
	 DrivesOk, 													(* Laufwerksnamen sind Ok	*)
	 Status 	  : BOOLEAN;									(* Status des Requesters	*)
	 DriveReq  : pRequester;								(* Requester fÅr Laufwerk	*)
BEGIN
	InitIntuiText(TxtExit, 3, 7, cBlack, cMagenta, '', NIL);
	InitIntuiText(TxtOk, 43, 7, cBlack, cMagenta, '', NIL);

	InitIntuiText(TxtAText, 15, 2, cBlack, cMagenta,
					  'Source Disk Drive Is', NIL);     (* Eingabe des Laufwerks	*)

	InitIntuiText(TxtHdText, 15, 3, cBlack, cMagenta,
					  'Target Partition Is ', NIL);     (* Eingabe der Partition	*)

	InitIntuiText(TxtTemp, 3, 5, cBlack, cMagenta,	(* Eingabe Dateiname 		*)
					  'Target Filename', NIL);

	InitGadget(GadHdText, 15, 3, 19, 1, TxtHdText, cWhite, cMagenta, NIL,
				  TextGadget);

	InitGadget(GadAText, 15, 2, 20, 1, TxtAText, cWhite, cMagenta, GadHdText,
				  TextGadget);

	InitGadget(GadOk, 43, 7, 8, 3, TxtOk, cWhite, cMagenta, GadAText, OkGadget);

	InitGadget(GadExit, 3, 7, 8, 3, TxtExit, cWhite, cMagenta, GadOk,
				  ExitGadget);

	InitGadget(GadTemp, 3, 5, 15, 1, TxtTemp, cWhite, cMagenta, GadExit,
				  TextGadget);

	WITH GadAText^ DO											(* Textpufferdaten fÅr A:	*)
	BEGIN
		Buffer := DriveA;
		Size := 1;
		Mask := ['A'..'Z', 'a'..'z'];
		DoAction := TRUE;										(* Aktion Gro·buchstaben	*)
		Action := UpCaseDrive;
	END;

	WITH GadHdText^ DO	  									(* Textpufferdaten fÅr Hd	*)
	BEGIN
		Buffer := Partition;
		Size := 1;
		Mask := ['C'..'Z', 'c'..'z'];
		DoAction := TRUE;										(* Aktion Gro·buchstaben	*)
		Action := UpCaseDrive;
	END;

	WITH GadTemp^ DO	 	 									(* Name temporÑre Datei		*)
	BEGIN
		Buffer := FileName;
		Size := 30;

		Mask := ['A'..'Z', 'a'..'z', '0'..'9', '$', '&', '#', '%', '`', '(',
					')', '_', '@', '''', '^', '{', '}', '-', '!', '.', '\'];
	END;

	InitRequester(DriveReq, 12, 5, 54, 11, cYellow, cMagenta,
					  ' Image To Harddisk ',
					  [rClose, rMove, rShadow, rTitle, rDouble], GadTemp, NIL);

	SetKeyStatus(CapsLockKey);								(* CapsLock anschalten		*)
	Status := OpenRequester(DriveReq); 					(* Requester îffnen			*)

	DrivesOk := (Length(GadAText^.Buffer) = 1) AND
		(Length(GadHdText^.Buffer) = 1);					(* Laufwerksnamen sind Ok	*)

	IF GetEndGadget(GadOk) = GadOk THEN	  		 		(* Laufwerksname zuweisen	*)
	BEGIN
		IF DrivesOk THEN 	  									(* Laufwerksnamen sind Ok	*)
		BEGIN
			DriveA := GadAText^.Buffer[1];
			Partition := GadHdText^.Buffer[1];
			FileName := GadTemp^.Buffer;
		END;

		DoCopy := TRUE;										(* Diskette kopieren			*)
	END
	ELSE DoCopy := FALSE;									(* Kopieren abgebrochen		*)

	IF Status THEN
		Status := CloseRequester(DriveReq);				(* Requester schlie·en		*)

	IF DoCopy AND NOT DrivesOk THEN						(* Laufwerknamen falsch		*)
	BEGIN
		DoMessage(' Error - Missing Drive Character', FALSE, DoCopy);
		DoCopy := FALSE;										(* Kopieren abgebrochen		*)
	END
	ELSE IF DoCopy AND (Length(FileName) = 0) THEN	(* Dateiname unzulÑssig		*)
	BEGIN
		DoMessage(' Error - Missing Target Filename', FALSE, DoCopy);
		DoCopy := FALSE;										(* Kopieren abgebrochen		*)
	END;

	DelKeyStatus(CapsLockKey);								(* CapsLock ausschalten		*)
END; (* AskImageToHd *)

(* Diese Funktion kopiert eine Diskette als Datei auf die Festplatte *)
FUNCTION ImageToHd(SourceDrive, TargetHardDisk : CHAR;
						 DiskTypA : DiskType) : BOOLEAN;
VAR Cylinder,													(* Cylinder einer Diskette *)
	 CylinderMax : BYTE; 									(* Grî·te Anzahl Cylinder	*)
	 CopyBuffer0,												(* Puffer fÅr Seite 0		*)
	 CopyBuffer1 : POINTER; 								(* Puffer fÅr Seite 1		*)
	 BufferSize  : WORD; 									(* Grî·e des Puffers 		*)
	 CompleteMem : LONGINT;									(* Speicher frei HardDisk 	*)
	 DoCopy, 													(* Kopieren fortsetzen		*)
	 DoubleSide  : BOOLEAN; 								(* Einseitg und Zweiseitig *)

(* Diese Prozedur liest eine Spur in einen Puffer *)
PROCEDURE ReadTrack(Side : BYTE; CopyBuffer : POINTER);
BEGIN
	WriteToGate('R', Cylinder, Side, cYellow, cRed);
	ReadStandard(SourceDrive, Side, Cylinder, DiskTypA, CopyBuffer);

	IF DiskStatus <> DiskStatusOk THEN					(* Disketten Lesefehler 	*)
	BEGIN
		WriteToGate('E', Cylinder, Side, cYellow, cRed);
		FillChar(CopyBuffer^, BufferSize, 0);			(* Mit Nullen auffÅllen 	*)
	END;
END; (* ReadTrack *)

(* Diese Prozedur schreibt eine Spur aus einem Puffer *)
PROCEDURE WriteTrack(Side : BYTE; CopyBuffer : POINTER);
BEGIN
	WriteToGate('W', Cylinder, Side, cYellow, cRed);
	WriteToMemory(CopyBuffer, BufferSize); 			(* Puffer in Speicher		*)
	WriteUsedMemory;											(* Verwendeter Speicher 	*)
	WriteToGate(Chr(7), Cylinder, Side, cYellow, cRed);
END; (* WriteTrack *)

BEGIN (* ImageToHd *)
	CASE DiskTypA OF											(* Disktyp unterscheiden	*)
		Disk160 :
		BEGIN
			BufferSize := 8 * 512;							(* Speicher fÅr eine Spur	*)
			CylinderMax := 39;								(* 40 Cylinder insgesamt	*)
			DoubleSide := FALSE; 							(* Einseitige Disketten 	*)
		END;

		Disk320 :
		BEGIN
			BufferSize := 8 * 512;							(* Speicher fÅr eine Spur	*)
			CylinderMax := 39;								(* 40 Cylinder insgesamt	*)
			DoubleSide := TRUE;								(* Zweiseitige Disketten	*)
		END;

		Disk180 :
		BEGIN
			BufferSize := 9 * 512;							(* Speicher fÅr eine Spur	*)
			CylinderMax := 39;								(* 40 Cylinder insgesamt	*)
			DoubleSide := FALSE; 							(* Einseitige Disketten 	*)
		END;

		Disk360 :
		BEGIN
			BufferSize := 9 * 512;							(* Speicher fÅr eine Spur	*)
			CylinderMax := 39;								(* 40 Cylinder insgesamt	*)
			DoubleSide := TRUE;								(* Zweiseitige Disketten	*)
		END;

		Disk720 :
		BEGIN
			BufferSize := 9 * 512;							(* Speicher fÅr eine Spur	*)
			CylinderMax := 79;								(* 80 Cylinder insgesamt	*)
			DoubleSide := TRUE;								(* Zweiseitige Disketten	*)
		END;

		Disk1200 :
		BEGIN
			BufferSize := 15 * 512; 						(* Speicher fÅr eine Spur	*)
			CylinderMax := 79;								(* 80 Cylinder insgesamt	*)
			DoubleSide := TRUE;								(* Zweiseitige Disketten	*)
		END;

		Disk1440 :
		BEGIN
			BufferSize := 18 * 512; 						(* Speicher fÅr eine Spur	*)
			CylinderMax := 79;								(* 80 Cylinder insgesamt	*)
			DoubleSide := TRUE;								(* Zweiseitige Disketten	*)
		END;
	END;

	CompleteMem := LONGINT(BufferSize) * (CylinderMax + 1);
	IF DoubleSide THEN Inc(CompleteMem, CompleteMem);

	IF CompleteMem > DiskFree(Ord(TargetHardDisk) - Ord('A') + 1) + 8192 THEN
	BEGIN
		RemoveClock;	  						 				(* Die Uhr wird entfernt	*)
		ClearGate;
		ImageToHd := FALSE;	  		 						(* Fehler beim Kopieren		*)

		DoMessage('Error - No Free Memory On Drive ' + TargetHardDisk + ':',
					 FALSE, DoCopy);
	END
	ELSE
	BEGIN
		GetMem(CopyBuffer0, BufferSize);					(* Speicher Seite 0			*)
		GetMem(CopyBuffer1, BufferSize);					(* Speicher Seite 1			*)
		FillDriveInfo(SourceDrive);						(* DriveInfoBlock fÅllen 	*)

		FOR Cylinder := 0 TO CylinderMax DO   			(* Ganze Diskette kopieren *)
		BEGIN
			IF CheckBreak THEN								(* Kopiervorgang abbrechen *)
			BEGIN
				FreeMem(CopyBuffer0, BufferSize);		(* Speicher freigeben		*)
				FreeMem(CopyBuffer1, BufferSize);		(* Speicher freigeben		*)
				ImageToHd := FALSE;	 	 		  			(* Fehler beim Kopieren		*)
				Exit; 											(* Aktuelle Prozedur Ende	*)
			END;

			WriteCylinder(Cylinder, DoubleSide);  		(* Cylinder auf Bildschirm *)
			ReadTrack(0, CopyBuffer0);   					(* Spur auf Seite 0 lesen	*)

			IF DoubleSide THEN				  				(* Diskette ist zweiseitig *)
				ReadTrack(1, CopyBuffer1);   				(* Spur auf Seite 1 lesen	*)

			WriteTrack(0, CopyBuffer0);   				(* Spur Seite 0 schreiben	*)

			IF DoubleSide THEN				  				(* Diskette ist zweiseitig *)
				WriteTrack(1, CopyBuffer1);  				(* Spur Seite 1 schreiben	*)

			IF MemoryStatus <> MemoryStatusOk THEN		(* Schwerer Speicherfehler	*)
			BEGIN
				RemoveClock;  									(* Uhr anhalten				*)
				DoMessage(' Error - Failure In Memory System', FALSE, DoCopy);

				FreeMem(CopyBuffer0, BufferSize);		(* Speicher freigeben		*)
				FreeMem(CopyBuffer1, BufferSize);		(* Speicher freigeben		*)
				ImageToHd := FALSE;	 	 		  			(* Fehler beim Kopieren		*)
				Exit; 											(* Aktuelle Prozedur Ende	*)
			END;
		END;

		FreeMem(CopyBuffer0, BufferSize);  				(* Speicher freigeben		*)
		FreeMem(CopyBuffer1, BufferSize);  				(* Speicher freigeben		*)
		ImageToHd := TRUE;									(* Alles in Ordnung			*)
	END;
END; (* ImageToHd *)

BEGIN (* DoImageToHd *)
	IF NOT (HardDiskAvail AND HardDiskUsage) THEN 	(* Keine Festplatte da 		*)
		DoMessage('  Error - No Harddisks Available', FALSE, Dummy)
	ELSE      													(* Festplatte vorhanden		*)
	BEGIN
		AskImageToHd(DoCopy, SourceDrive, TargetHardDisk, ToHd);

		IF DoCopy THEN											(* Kopieren fortsetzen		*)
		BEGIN
			Assign(TempFile, TargetHardDisk + ':\' + ToHd);
			ReWrite(TempFile);								(* TemporÑre Datei îffnen	*)

			IF IOResult <> 0 THEN							(* Fehler ist aufgetreten	*)
				DoMessage('Error - Cannot Create Target File', FALSE, Dummy)
			ELSE													(* TemporÑre Datei ist Ok	*)
			BEGIN
				Close(TempFile);								(* Nur zum Test geîffnet	*)
				Erase(TempFile);								(* Datei wieder lîschen		*)

				DoMessage('  Insert Source Disk In Drive ' + SourceDrive + ':',
							 TRUE, DoCopy);

				IF DoCopy THEN									(* Kopieren fortsetzen		*)
				BEGIN
					PutString(0, 0, ' IMAGE TO HD ', cYellow, cRed);
					PutString(13, 0, '  ', cBlack, cCyan);

					DiskTypA := GetDiskType(SourceDrive);
					DiskTypHd := GetDiskType(TargetHardDisk);

					CASE DiskTypA OF	  						(* Disktyp unterscheiden	*)
						UnknownDisk   :
							DoMessage(' Error - Unknown Disk In Drive ' +
										 SourceDrive + ':', FALSE, Dummy);

						DiskFailure   :
							DoMessage('  Error - Disk Read Error In ' + SourceDrive +
										 ':', FALSE, Dummy);

						DriveNotReady :
							DoMessage('  Error - Drive ' + SourceDrive +
										 ': Is Not Ready', FALSE, Dummy);

						UnknownDrive  :
							DoMessage('Error - Drive ' + SourceDrive +
										 ': Is Not Installed', FALSE, Dummy);

						HardDisk, RamDisk :
							DoMessage('Error - DriveType Of ' + SourceDrive +
										 ': Is Illegal', FALSE, Dummy);

					ELSE 			 						  		(* Alles in Ordnung			*)
						IF DiskTypHd <> HardDisk THEN		(* Nur Festplatte erlaubt	*)
						BEGIN
							DoMessage('Error - Drive ' + TargetHardDisk +
										 ': Harddisk Expected', FALSE, Dummy);
						END
						ELSE	  									(* Alles in Ordnung			*)
						BEGIN
							ReleaseCodeOff;					(* Keine Release Codes		*)
							WriteUnusedGate(DiskTypA);
							WriteDiskType(DiskTypA);
							SaveDriveInfo;
							SetTrials(NrOfErrorTrials);

							InitMemory(FALSE, FALSE, FALSE, FALSE, FALSE, TRUE, FALSE,
										  TargetHardDisk); 	(* Speicher nur auf Platte	*)

							InitClock;			  				(* Uhr initialisieren		*)
							InstallClock;		  				(* Ab jetzt lÑuft die Uhr	*)

							Status := ImageToHd(SourceDrive, TargetHardDisk, DiskTypA);

							RemoveClock;						(* Die Uhr wird entfernt	*)
							DelMemory;
							LoadDriveInfo;
							ResetDiskDrives;
							ReleaseCodeOn;   					(* Tasten Release Codes 	*)
							Assign(TempFile, TargetHardDisk + ':\' + TempFilename);

							IF NOT Status THEN				(* Fehler beim Kopieren		*)
								Erase(TempFile)				(* Datei wieder lîschen		*)
							ELSE									(* Kopiervorgang war Ok		*)
							BEGIN
								Rename(TempFile, TargetHardDisk + ':\' + ToHd);

								IF IOResult <> 0 THEN		(* Fehler beim Umbenennen	*)
								BEGIN
									DoMessage('Error - Cannot Rename Target File',
												 FALSE, Dummy);
								END
								ELSE								(* Neue Datei ist Ok			*)
								BEGIN
									Write(Chr(7));  			(* Piepston klingen lassen *)

									DoMessage('  ØØ Venus DiskCopy Completed ÆÆ',
												 FALSE, Dummy);
								END;
							END;

							ClearGate;							(* Alle Ausgaben lîschen	*)
						END;
					END;
				END;
			END;
		END;
	END;
END; (* DoImageToHd *)

(*$I ResImage.Pas  Die Prozedur RestoreImage ist als Include-Datei vorhanden *)

END. (* CopyMenu *)
