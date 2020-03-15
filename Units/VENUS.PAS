(******************************************************************)
(* Programmname	 : VENUS.PAS V2.1 										*)
(* Programmautor	 : Michael Rippl											*)
(* Compiler 		 : Quick Pascal V1.0 									*)
(* Inhalt			 : Hauptprogramm des Kopierprogramms Venus V2.1 *)
(* Bemerkung		 : -															*)
(* Letzte nderung : 08-Aug-1991 											*)
(******************************************************************)

PROGRAM Venus; 												(*$M 49152, 130172, 655360	*)
																	(*$V- Kein String-Check		*)

USES Crt, Dos, SysInfo, MainMenu, CopyMenu, ParaMenu, InfoMenu,
	  ToolMenu, VenColor, Extended, Expanded, HiMem, Memory,
	  KeyMouse, Primitiv, Windows;						(* Units einbinden			*)

CONST UserName 	 : STRING[20] = #28#28#28#28#28#28#28#28#28#28#28#28 +
											 #28#28#28#28#28#28#28#28;

		SerialBorder : WORD = $03FE;						(* Abtrennen der S.-Nummer	*)
		SerialNumber : LONGINT = -2; 						(* Seriennummer von Venus	*)

VAR QuitProgram,												(* Venus verlassen			*)
	 DemoVersion,												(* Nur fr Demo-Version		*)
	 DoChangeCols,												(* Farben werden ver„ndert	*)
	 EmsUsage,													(* Verwende EMS Speicher	*)
	 XmsUsage,													(* Verwende XMS Speicher	*)
	 ExtUsage,													(* Verwende EXT Speicher	*)
	 RamDiskUsage, 											(* Verwende Ram Disk 		*)
	 HardDiskUsage,											(* Verwende Hard Disk		*)
	 VerifyTarget, 											(* šberprfe Zieldiskette	*)
	 FormatTarget	  : BOOLEAN;							(* Formatiere Zieldiskette *)
	 NrOfErrorTrials : BYTE;								(* Anzahl Wiederholungen	*)
	 SourceDrive,												(* Laufwerk Quelldiskette	*)
	 TargetDrive,												(* Laufwerk Zieldiskette	*)
	 TargetHardDisk  : CHAR;								(* Ziel tempor„re Datei 	*)
	 FromHdFileName,											(* Disk von Festplatte		*)
	 ToHdFileName	  : STRING[30];						(* Disk auf Festplatte		*)

(* Diese Prozedur gibt alle Resourcen frei *)
PROCEDURE CleanUp;
VAR WindowStatus : BOOLEAN;
BEGIN
	IF MouseAvail THEN MouseOff;							(* Maus ausschalten			*)
	WindowStatus := CloseWindow;							(* Hauptfenster schlieáen	*)
	ClearScreen;												(* Bildschirm l”schen		*)
	PutAttributes(0, 0, 80, 1, Ord(cBlack));			(* Oberste Zeile Attribute *)
	PutAttributes(0, 1, 80, 1, Ord(cBlack));			(* Zweite Zeile Attribute	*)
	SetXY(0, 4);												(* Echten Cursor setzen 	*)
END; (* CleanUp *)

(*$F+ Diese Prozedur wird aufgerufen, falls kein Speicher mehr vorhanden ist *)
FUNCTION NoMemory(Size : WORD) : INTEGER;
BEGIN
	IF Size > 0 THEN
	BEGIN
		CleanUp; 												(* Resourcen freigeben		*)
		ClrScr;
		WriteLn;
		WriteLn('Program Interrupted : Fatal Memory Error');
		Halt;
	END; 															(* Programm abbrechen		*)
END; (*$F- NoMemory *)

(* Diese Prozedur schreibt das Spuren-Gatter auf den Bildschirm *)
PROCEDURE WriteTrackGate;
BEGIN
	WriteString('ÉÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ', cLightMagenta, cBlue);
	WriteLnString('ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»', cLightMagenta, cBlue);

	WriteString(' º  SIDE    º    0 1 2 3 ', cLightMagenta, cBlue);
	WriteString('4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 ', cLightMagenta, cBlue);
	WriteLnString('1 2 3 4 5 6 7 8 9º', cLightMagenta, cBlue);

	WriteString(' ÇÄÄÄÄÄÄÄÄÄÄ¶   ÚÄÂÄÂÄÂÄ', cLightMagenta, cBlue);
	WriteString('ÂÄÂÄÂÄÂÄÂÄÂÄÂÄÂÄÂÄÂÄÂÄÂÄÂÄÂÄÂÄÂÄÂÄÂÄ', cLightMagenta, cBlue);
	WriteLnString('ÂÄÂÄÂÄÂÄÂÄÂÄÂÄÂÄ¶', cLightMagenta, cBlue);

	WriteString(' º          º 0', cLightMagenta, cBlue);
	WriteString(' ³ ³ ³ ³ ³ ³ ³ ³ ³ ³ ³ ³ ³ ', cLightMagenta, cBlue);
	WriteLnString('³ ³ ³ ³ ³ ³ ³ ³ ³ ³ ³ ³ ³ ³ ³ ³ ³ º', cLightMagenta, cBlue);

	WriteString(' º CYLINDER º   ÃÄÅÄÅÄÅÄÅÄÅÄÅÄÅÄ', cLightMagenta, cBlue);
	WriteString('ÅÄÅÄÅÄÅÄÅÄÅÄÅÄÅÄÅÄÅÄÅÄÅÄ', cLightMagenta, cBlue);
	WriteLnString('ÅÄÅÄÅÄÅÄÅÄÅÄÅÄÅÄÅÄÅÄ¶', cLightMagenta, cBlue);

	WriteString(' º          º 3 ³ ³ ³ ³ ³ ³ ³ ', cLightMagenta, cBlue);
	WriteString('³ ³ ³ ³ ³ ³ ³ ³ ³ ³ ³ ³ ³ ³', cLightMagenta, cBlue);
	WriteLnString(' ³ ³ ³ ³ ³ ³ ³ ³ ³ º', cLightMagenta, cBlue);

	WriteString(' º    00    º   ÃÄÅÄÅÄÅÄÅÄÅÄÅÄÅÄ', cLightMagenta, cBlue);
	WriteString('ÅÄÅÄÅÄÅÄÅÄÅÄÅÄÅÄÅÄÅÄÅÄÅÄÅÄ', cLightMagenta, cBlue);
	WriteLnString('ÅÄÅÄÅÄÅÄÅÄÅÄÅÄÅÄÅÄ¶', cLightMagenta, cBlue);

	WriteString(' º          º 6 ³ ³ ³ ³ ³ ³ ³ ³ ', cLightMagenta, cBlue);
	WriteString('³ ³ ³ ³ ³ ³ ³ ³ ³ ³ ³ ³ ³ ', cLightMagenta, cBlue);
	WriteLnString('³ ³ ³ ³ ³ ³ ³ ³ ³ º', cLightMagenta, cBlue);

	WriteString(' ÈÍÍÍÍÍÍÍÍÍÍÊÍÍÍÏÍÏÍÏÍÏÍÏÍÏÍÏÍÏÍÏÍ', cLightMagenta, cBlue);
	WriteString('ÏÍÏÍÏÍÏÍÏÍÏÍÏÍÏÍÏÍÏÍÏÍÏÍ', cLightMagenta, cBlue);
	WriteString('ÏÍÏÍÏÍÏÍÏÍÏÍÏÍÏÍÏÍ¼', cLightMagenta, cBlue);
END; (* WriteTrackGate *)

(* Diese Prozedur schreibt die Informationsleiste auf den Bildschirm *)
PROCEDURE WriteInfo;
BEGIN
	VideoFill(0, 1, 80, 1, ' ', cBlack, cLightGrey);
	PutString(9, 1, 'VENUS DISKCOPY V2.1  (C)', cBlack, cLightGrey);
	PutString(34, 1, 'COPYRIGHT 1990, 1991 BY DIGITAL IMAGE', cBlack, cLightGrey);

	VideoFill(0, 0, 80, 1, ' ', cBlack, cCyan);		(* Eigentlich Mensache 	*)
	PutString(0, 0, ' SINGLE DRIVE ', cYellow, cRed);

	PutString(17, 0, 'DISKCOPY    PARAMETER    INFORMATION    TOOLS',
				 cBlack, cCyan);

	WriteString('ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍ»  ÉÍÍÍÍÍÍÑÍ', cLightMagenta, cBlue);
	WriteLnString('ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»  ÉÍÍÍÍÍÍÑÍÍÍÍÍÍÍ»', cLightMagenta, cBlue);

	WriteString(' º USING MEMORY ³ MAIN MEM  º  ', cLightMagenta, cBlue);
	WriteString('º DISK ³ 1.2 MB 5¬" 2S HD  ', cLightMagenta, cBlue);
	WriteLnString('º  º TIME ³ 00:00 º', cLightMagenta, cBlue);

	WriteString(' ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍ¼  ', cLightMagenta, cBlue);
	WriteString('ÈÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼  ', cLightMagenta, cBlue);
	WriteString('ÈÍÍÍÍÍÍÏÍÍÍÍÍÍÍ¼', cLightMagenta, cBlue);

	PutString(25, 15,' VENUS DISKCOPY DEMOVERSION ', cYellow, cBlue);

	PutAttributes(4, 4, 12, 1, Ord(cBlue) SHL 4 OR Ord(cLightCyan));
	PutAttributes(19, 4, 8, 1, Ord(cBlue) SHL 4 OR Ord(cLightGreen));

	PutAttributes(34, 4, 4, 1, Ord(cBlue) SHL 4 OR Ord(cLightCyan));
	PutAttributes(41, 4, 17, 1, Ord(cBlue) SHL 4 OR Ord(cLightGreen));

	PutAttributes(64, 4, 4, 1, Ord(cBlue) SHL 4 OR Ord(cLightCyan));
	PutAttributes(71, 4, 5, 1, Ord(cBlue) SHL 4 OR Ord(cLightGreen));

	PutAttributes(5, 7, 4, 1, Ord(cBlue) SHL 4 OR Ord(cLightCyan));
	PutChar(10, 7, '0', cLightCyan, cBlue);
	PutAttributes(18, 7, 59, 1, Ord(cBlue) SHL 4 OR Ord(cLightCyan));

	PutAttributes(15, 9, 1, 1, Ord(cBlue) SHL 4 OR Ord(cLightCyan));
	PutAttributes(15, 11, 1, 1, Ord(cBlue) SHL 4 OR Ord(cLightCyan));
	PutAttributes(15, 13, 1, 1, Ord(cBlue) SHL 4 OR Ord(cLightCyan));

	PutAttributes(4, 10, 8, 1, Ord(cBlue) SHL 4 OR Ord(cLightGreen));
	PutAttributes(7, 12, 2, 1, Ord(cBlue) SHL 4 OR Ord(cLightGreen));

	PutAttributes(5, 16, 4, 1, Ord(cBlue) SHL 4 OR Ord(cLightCyan));
	PutChar(10, 16, '1', cLightCyan, cBlue);
	PutAttributes(18, 16, 59, 1, Ord(cBlue) SHL 4 OR Ord(cLightCyan));

	PutAttributes(15, 18, 1, 1, Ord(cBlue) SHL 4 OR Ord(cLightCyan));
	PutAttributes(15, 20, 1, 1, Ord(cBlue) SHL 4 OR Ord(cLightCyan));
	PutAttributes(15, 22, 1, 1, Ord(cBlue) SHL 4 OR Ord(cLightCyan));

	PutAttributes(4, 19, 8, 1, Ord(cBlue) SHL 4 OR Ord(cLightGreen));
	PutAttributes(7, 21, 2, 1, Ord(cBlue) SHL 4 OR Ord(cLightGreen));
END; (* WriteInfo *)

(* Diese Prozedur nimmt alle notwendigen Initialsierungen vor *)
PROCEDURE Initialize;
VAR InfoWindow,												(* Informationsfenster		*)
	 MainWindow : Window;									(* Hauptfenster				*)
	 InfoHandle,
	 MainHandle : pWindow;									(* Handle der Fenster		*)
	 Status		: BOOLEAN;									(* Status eines Fensters	*)
	 ConfigPath : PathStr;     							(* Pfad zur Config-Datei	*)
	 ConfigFile : FILE;										(* Dateivariable Config		*)
	 FileOk		: BOOLEAN;									(* Konfigurationsdatei Ok	*)
	 Result		: WORD;										(* Resultat vom Schreiben	*)
	 Dummy		: ARRAY [1..12] OF BYTE;				(* Feld fr Dummy-Werte		*)
BEGIN
	IF GetCPUType < Intel80286 THEN						(* Mindestens AT ben”tigt	*)
	BEGIN
		WriteLn;
		WriteLn('This Program Requires An Intel 80286 Or Above');
		Halt; 													(* Programmende				*)
	END;

	ConfigPath := FSearch('VENUS.CFG', GetEnv('PATH'));
	FileOk := Length(ConfigPath) > 0;
	HeapError := Addr(NoMemory);							(* Falls Speichermangel 	*)
	CheckBreak := FALSE;										(* Kein Strg-Untbr Ende		*)
	QuitProgram := FALSE;									(* Venus laufen lassen		*)

	IF Colorgraphic THEN
	BEGIN
		SetColorGraphics;

		IF FileOk THEN											(* Config-Datei vorhanden	*)
		BEGIN
			Assign(ConfigFile, ConfigPath);				(* Name fr Dateivariable	*)
			Reset(ConfigFile, 1);							(* Config-Datei ”ffnen		*)

			BlockRead(ConfigFile, cBlack, 1, Result);	(* Farbwerte einlesen		*)
			BlockRead(ConfigFile, cBlue, 1, Result);
			BlockRead(ConfigFile, cCyan, 1, Result);
			BlockRead(ConfigFile, cRed, 1, Result);
			BlockRead(ConfigFile, cMagenta, 1, Result);
			BlockRead(ConfigFile, cLightGrey, 1, Result);
			BlockRead(ConfigFile, cLightGreen, 1, Result);
			BlockRead(ConfigFile, cLightCyan, 1, Result);
			BlockRead(ConfigFile, cLightMagenta, 1, Result);
			BlockRead(ConfigFile, cLightRed, 1, Result);
			BlockRead(ConfigFile, cYellow, 1, Result);
			BlockRead(ConfigFile, cWhite, 1, Result);
		END;
	END
	ELSE
	BEGIN
		SetMonochromGraphics;

		IF FileOk THEN											(* Config-Datei vorhanden	*)
		BEGIN
			Assign(ConfigFile, ConfigPath);				(* Name fr Dateivariable	*)
			Reset(ConfigFile, 1);							(* Config-Datei ”ffnen		*)
			BlockRead(ConfigFile, Dummy, 12, Result);
		END;
	END;

	WITH MainWindow DO										(* Fensterdaten eintragen	*)
	BEGIN
		LeftEdge := 0;
		TopEdge := 2;
		Width := 80;
		Height := 23;
		DetailPen := cWhite;
		BlockPen := cBlue;									(* Fensterhintergrund		*)
		Flags := [Double, Simple];
	END;

	MainHandle := OpenWindow(MainWindow);				(* Hauptfenster ”ffnen		*)

	CursorLine;
	CursorOff;													(* Kein Cursor sichtbar 	*)

	SetVirtualXY(2, 5);										(* Bildschirmgestaltung 	*)
	WriteTrackGate;
	SetVirtualXY(2, 14);
	WriteTrackGate;
	SetVirtualXY(2, 1);
	WriteInfo;

	WITH InfoWindow DO										(* Fensterdaten eintragen	*)
	BEGIN
		LeftEdge := 20;
		TopEdge := 8;
		Width := 38;
		Height := 5;
		DetailPen := cBlack;
		BlockPen := cCyan;
		Flags := [Double, Simple, Shadow];
	END;

	InfoHandle := OpenWindow(InfoWindow);				(* Infofenster ”ffnen		*)

	SetVirtualXY(5, 2);
	WriteString('Please Wait, Checking System', cBlack, cCyan);
	Delay(500); 												(* Warten 0.5 Sekunden		*)

	EmsUsage := EmsMemAvail;								(* EMS Speicher vorhanden	*)
	ExtUsage := ExtMemAvail;								(* EXT Speicher vorhanden	*)

	IF (ParamStr(1) = '/x') OR (ParamStr(1) = '/X') THEN
		XmsUsage := FALSE										(* XMS nur manuell da		*)
	ELSE
	BEGIN
		InitXms;
		XmsUsage := XmsMemAvail;
	END;

	InitMemory(TRUE, FALSE, TRUE, TRUE, TRUE, TRUE, TRUE, ' ');
	RamDiskUsage := RamDiskAvail; 						(* Ram Disk vorhanden		*)
	HardDiskUsage := HardDiskAvail;						(* Hard Disk vorhanden		*)
	DelMemory;													(* Sp„ter initialisieren	*)

	IF MouseAvail THEN										(* Eine Maus ist vorhanden *)
	BEGIN
		IF ColorGraphic THEN 								(* Farbe 						*)
		BEGIN
			DefineMouseCursor($00FF, WORD((Ord(cRed) SHL 4) OR
									(Ord(cYellow))) SHL 8);
		END
		ELSE DefineMouseCursor($F0FF, $7F00);			(* Monochrom					*)

		SetMouseSpeed(4, 8); 								(* Mausgeschwindigkeit		*)
	END;

	NrOfErrorTrials := 5;									(* Anzahl Wiederholungen	*)
	VerifyTarget := FALSE;									(* Keine šberprfung 		*)
	FormatTarget := FALSE;									(* Keine Formatierung		*)
	SourceDrive := 'A';										(* Startwert Laufwerk A 	*)
	TargetDrive := 'B';										(* Startwert Laufwerk B 	*)
	ToHdFileName := '';
	FromHdFileName := '';

	IF HardDiskAvail THEN                     		(* Ziel tempor„re Datei		*)
		TargetHardDisk := UsedPartition
	ELSE TargetHardDisk := ' ';

	Status := CloseWindow;									(* Info-Fenster schlieáen	*)
	ReleaseCodeOn; 											(* Release Codes zulassen	*)
	MakeCodeOff;												(* Keine unbekannten Codes *)

	IF FileOk THEN												(* Config-Datei vorhanden	*)
	BEGIN
		BlockRead(ConfigFile, SourceDrive, 1, Result);
		BlockRead(ConfigFile, TargetDrive, 1, Result);
		BlockRead(ConfigFile, XmsUsage, 1, Result);
		BlockRead(ConfigFile, EmsUsage, 1, Result);
		BlockRead(ConfigFile, ExtUsage, 1, Result);
		BlockRead(ConfigFile, RamDiskUsage, 1, Result);
		BlockRead(ConfigFile, HardDiskUsage, 1, Result);
		BlockRead(ConfigFile, NrOfErrorTrials, 1, Result);
		BlockRead(ConfigFile, VerifyTarget, 1, Result);
		BlockRead(ConfigFile, FormatTarget, 1, Result);
		BlockRead(ConfigFile, ToHdFileName, SizeOf(ToHdFileName), Result);
		BlockRead(ConfigFile, FromHdFileName, SizeOf(FromHdFileName), Result);

		Close(ConfigFile);  			 						(* Config-Datei schlieáen	*)

		IF (ParamStr(1) = '/x') OR (ParamStr(1) = '/X') THEN
			XmsUsage := FALSE;								(* XMS nur manuell da		*)

		IF XmsUsage THEN
			InitXms;
	END;

	IF MouseAvail THEN MouseOn;							(* Maus anschalten			*)
END; (* Initialize *)

BEGIN 															(* Hauptprogramm				*)
	Initialize; 												(* Initialisierung			*)

	REPEAT
		CASE DoMainMenu OF									(* Auswahl unterscheiden	*)
			SingleDrive :
				DoSingleDrive(SourceDrive, EmsUsage, XmsUsage, ExtUsage,
								  RamDiskUsage, HardDiskUsage, NrOfErrorTrials,
								  VerifyTarget, FormatTarget, FALSE, FALSE);

			DualDrive :
				DoMessage('S O R R Y, D E M O V E R S I O N !', FALSE, DemoVersion);

			MultipleCopy :
				DoMessage('S O R R Y, D E M O V E R S I O N !', FALSE, DemoVersion);

			CylinderCopy :
				DoMessage('S O R R Y, D E M O V E R S I O N !', FALSE, DemoVersion);

			ImageToHd :
			BEGIN
				IF (ToHdFileName = '') AND (FromHdFileName <> '') THEN
					ToHdFileName := FromHdFileName;

				DoMessage('S O R R Y, D E M O V E R S I O N !', FALSE, DemoVersion);
			END;

			RestoreImage :
			BEGIN
				IF (FromHdFileName = '') AND (ToHdFileName <> '') THEN
					FromHdFileName := ToHdFileName;

				DoMessage('S O R R Y, D E M O V E R S I O N !', FALSE, DemoVersion);
			END;

			QuitVenus :
				DoMessage('   Do You Want To Leave Venus ?', TRUE, QuitProgram);

			MemoryUsage :
				DoMemoryUsage(EmsUsage, XmsUsage, ExtUsage, RamDiskUsage,
								  HardDiskUsage);

			ErrorTrials :
				DoErrorTrials(NrOfErrorTrials);

			AdjustDisk :
				DoAdjustDisk(VerifyTarget, FormatTarget);

			SystemInfo :
				DoSystemInfo;

			MemorySizes :
				DoMemorySizes(XmsUsage);

			DiskInfo :
				DoDiskInfo;

			VenusInfo :
				DoVenusInfo(SerialNumber, UserName); 	(* Seriennummer				*)

			DosShell :
				DoDosShell(0, 0, 80, 25);

			ChangeColor :
			BEGIN
				DoChangeColors(cBlack, cBlue, cCyan, cRed, cMagenta, cLightGrey,
									cLightGreen, cLightCyan, cYellow, cWhite,
									cLightRed, cLightMagenta, DoChangeCols);

				IF DoChangeCols THEN							(* Farben werden ver„ndert	*)
				BEGIN
					IF MouseAvail THEN MouseOff; 			(* Maus ausschalten			*)

					PutAttributes(0, 1, 80, 24, (Ord(cBlue) SHL 4) OR Ord(cWhite));
					SetVirtualXY(2, 5);						(* Bildschirmgestaltung 	*)
					WriteTrackGate;
					SetVirtualXY(2, 14);
					WriteTrackGate;
					SetVirtualXY(2, 1);
					WriteInfo;

					IF ColorGraphic THEN 					(* Maus in Farbdarstellung *)
					BEGIN
						DefineMouseCursor($00FF, WORD((Ord(cRed) SHL 4) OR
												(Ord(cYellow))) SHL 8);
					END;

					IF MouseAvail THEN MouseOn;			(* Maus anschalten			*)
					PutChar(78, 23, ' ', cWhite, cBlue);(* Wer weiá warum ?!			*)
				END;
			END;

			SaveConfig :
				DoMessage('S O R R Y, D E M O V E R S I O N !', FALSE, DemoVersion);
		END;
	UNTIL QuitProgram;										(* Ende des Programmes		*)

	CleanUp; 													(* Resourcen freigeben		*)
END. (* Venus *)
