(*********************************************************************)
(* Programmname	 : INFOMENU.PAS V2.0 										*)
(* Programmautor	 : Michael Rippl												*)
(* Compiler 		 : Quick Pascal V1.0 										*)
(* Inhalt			 : Men Information des Kopierprogramms Venus V2.1 *)
(* Bemerkung		 : -																*)
(* Letzte Žnderung : 05-Aug-1991 												*)
(*********************************************************************)

UNIT InfoMenu;

INTERFACE

(* Diese Prozedur gibt Copyright-Informationen und eine Seriennummer aus *)
PROCEDURE DoVenusInfo(SerialNumber : LONGINT; UserName : STRING);

(* Diese Prozedur gibt Informationen ber das Computersystem aus *)
PROCEDURE DoSystemInfo;

(* Diese Prozedur gibt Informationen ber den Speicher des Computers aus *)
PROCEDURE DoMemorySizes(XmsUsage : BOOLEAN);

(* Diese Prozedur gibt Informationen ber eine Diskette oder Festplatte aus *)
PROCEDURE DoDiskInfo;

IMPLEMENTATION

USES Dos, SysInfo, Memory, KeyMouse, Primitiv,
	  Windows, Intuitiv, VenColor, FileInfo,
	  Disk, Extended, Expanded, HiMem, CopyMenu;		(* Units einbinden			*)

VAR BiosDate : ARRAY [1..8] OF CHAR ABSOLUTE $F000:$FFF5;

(* Diese Prozedur gibt Copyright-Informationen und eine Seriennummer aus *)
PROCEDURE DoVenusInfo(SerialNumber : LONGINT; UserName : STRING);
VAR i 		  	: BYTE;	  									(* Dient nur als Z„hler		*)
	 TextString	: STRING [8];								(* Text der Seriennummer	*)
	 TxtSerial,													(* Seriennummer				*)
	 TxtTit1,													(* Texte auf dem Requester	*)
	 TxtTit2,
	 TxtTit3,
	 TxtTit4,
	 TxtTit5,
	 TxtTit6,
	 TxtTit7,
	 TxtTit8,
	 TxtTit9,
	 TxtOk		: pIntuiText;								(* Text fr Ok-Gadget		*)
	 GadOk		: pGadget;									(* Ok-Gadget					*)
	 InfoReq		: pRequester;								(* Requester Information	*)
	 Status		: BOOLEAN;									(* Status des Requesters	*)
BEGIN
	Str(SerialNumber + 2 : 8, TextString);
	InitIntuiText(TxtSerial, 21, 8, cBlack, cCyan, TextString, NIL);

	FOR i := 1 TO Length(UserName) DO					(* Buchstaben dekodieren	*)
		Inc(UserName[i], 4);

	InitIntuiText(TxtTit1, 7, 1, cYellow, cRed,
					  '       VENUS DISKCOPY V2.1       ', TxtSerial);

	InitIntuiText(TxtTit2, 7, 2, cYellow, cRed,
					  ' (C) 1990, 1991 BY DIGITAL IMAGE ', TxtTit1);

	InitIntuiText(TxtTit3, 13, 4, cBlack, cCyan, 'REVISION  05-AUG-1991',
					  TxtTit2);

	InitIntuiText(TxtTit4, 1, 5, cBlack, cCyan,
					  'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ', TxtTit3);

	InitIntuiText(TxtTit5, 21, 7, cBlack, cCyan, UserName, TxtTit4);

	InitIntuiText(TxtTit6, 5, 7, cBlack, cCyan,
					  'USER NAME      [                    ]', TxtTit5);

	InitIntuiText(TxtTit7, 5, 8, cBlack, cCyan,
					  'SERIAL NUMBER  [        ]', TxtTit6);

	InitIntuiText(TxtTit8, 7, 10, cBlack, cCyan,
					  'PROGRAM WRITTEN BY', TxtTit7);

	InitIntuiText(TxtTit9, 3, 11, cBlack, cCyan,
					  'EDV SERVICE  MICHAEL RIPPL', TxtTit8);

	InitIntuiText(TxtOk, 36, 10, cBlack, cCyan, '', NIL);
	InitGadget(GadOk, 36, 10, 8, 3, TxtOk, cWhite, cCyan, NIL, OkGadget);

	InitRequester(InfoReq, 15, 5, 47, 14, cBlack, cCyan, '',
					  [rMove, rShadow, rDouble], GadOk, TxtTit9);

	Status := OpenRequester(InfoReq);   				(* Requester ”ffnen			*)

	IF Status THEN
		Status := CloseRequester(InfoReq);				(* Requester schlieáen		*)
END; (* DoVenusInfo *)

(* Diese Prozedur gibt Informationen ber das Computersystem aus *)
PROCEDURE DoSystemInfo;
VAR IsColor		  : BOOLEAN;								(* Farbe oder Monochrom 	*)
	 VideoAdapter : VideoModes;							(* Typ der Grafikkarte		*)
	 Lines,														(* Anzahl der Zeilen 		*)
	 Columns 	  : BYTE;									(* Anzahl der Spalten		*)
	 VideoAddress : WORD;									(* Segment des Videorams	*)
	 VerLowStr, 												(* Dos Text nach Punkt		*)
	 VerHighStr   : STRING[2];								(* Dos Text vor Punkt		*)
	 TextString   : STRING[20]; 	 						(* Allgemeiner Textstring	*)
	 VerLow, 													(* Dos Version vor Punkt	*)
	 VerHigh 	  : BYTE;									(* Dos Version nach Punkt	*)
	 TxtTit1, 													(* Texte auf dem Requester	*)
	 TxtTit2,
	 TxtTit3,
	 TxtTit4,
	 TxtTit5,
	 TxtTit6,
	 TxtTit7,
	 TxtTit8,
	 TxtTit9,
	 TxtTit10,
	 TxtTit11,
	 TxtTit12,
	 TxtTit13,
	 TxtTit14,
	 TxtTit15,
	 TxtTit16,
	 TxtTit17,
	 TxtTit18,
	 TxtTit19,
	 TxtTit20,
	 TxtTit21,
	 TxtTit22,
	 TxtTit23,
	 TxtTit24,
	 TxtOk		  : pIntuiText;							(* Text fr Ok-Gadget		*)
	 GadOk		  : pGadget;								(* Ok-Gadget					*)
	 InfoReq		  : pRequester;							(* Requester Information	*)
	 Status		  : BOOLEAN;								(* Status des Requesters	*)
	 LastDrive,        										(* Letztes Laufwerk			*)
	 FirstDrive   : CHAR;  									(* Erstes Laufwerk			*)
BEGIN
	InitIntuiText(TxtTit1, 3, 2, cBlack, cMagenta,
					  'COMPUTER           -', NIL);

	InitIntuiText(TxtTit2, 3, 3, cBlack, cMagenta,
					  'OPERATING SYSTEM   -', TxtTit1);

	InitIntuiText(TxtTit3, 3, 4, cBlack, cMagenta,
					  'CPU TYPE           -', TxtTit2);

	InitIntuiText(TxtTit22, 26, 2, cBlack, cMagenta,
					  'IBM/PC AT', TxtTit3);

	InitIntuiText(TxtTit23, 26, 3, cBlack, cMagenta,
					  'MS DOS V', TxtTit22);

	InitIntuiText(TxtTit24, 26, 4, cBlack, cMagenta,
					  'Intel', TxtTit23);

	InitIntuiText(TxtTit4, 3, 5, cBlack, cMagenta,
					  'DISPLAY ADAPTER    -', TxtTit24);

	InitIntuiText(TxtTit5, 3, 6, cBlack, cMagenta,
					  'MOUSE              -', TxtTit4);

	InitIntuiText(TxtTit6, 3, 7, cBlack, cMagenta,
					  'SERIAL PORTS       -', TxtTit5);

	InitIntuiText(TxtTit7, 3, 8, cBlack, cMagenta,
					  'PARALLEL PORTS     -', TxtTit6);

	InitIntuiText(TxtTit8, 3, 9, cBlack, cMagenta,
					  'DISK DRIVES        -', TxtTit7);

	InitIntuiText(TxtTit9, 3, 10, cBlack, cMagenta,
					  'HARDDISK           -', TxtTit8);

	InitIntuiText(TxtTit10, 3, 11, cBlack, cMagenta,
					  'BIOS DATED AT      -', TxtTit9);

	InitIntuiText(TxtTit20, 3, 12, cBlack, cMagenta,
					  'DRIVES FOUND       -', TxtTit10);

	MsDosVersion(VerHigh, VerLow); 						(* Dos Version ermitteln	*)
	Str(VerHigh, VerHighStr);								(* Ziffer vor dem Punkt		*)
	Str(VerLow, VerLowStr);   								(* Ziffer hinter dem Punkt	*)

	InitIntuiText(TxtTit11, 34, 3, cBlack, cMagenta,
					  VerHighStr + '.' + VerLowStr, TxtTit20);

	IF GetCPUType = Intel80286 THEN  					(* Prozessortyp ermitteln	*)
		TextString := '80286'
	ELSE TextString :=  '80386';

	InitIntuiText(TxtTit12, 32, 4, cBlack, cMagenta, TextString, TxtTit11);

	GetVideoMode(VideoAdapter, IsColor, Lines, Columns, VideoAddress);

	CASE VideoAdapter OF 									(* Grafikkarte zuweisen 	*)
		MDA	: TextString := 'MDA';
		CGA	: TextString := 'CGA';
		EGA	: TextString := 'EGA';
		mEGA	: TextString := 'MONOCHROM EGA';
		VGA	: TextString := 'VGA';
		mVGA	: TextString := 'MONOCHROM VGA';
		MCGA	: TextString := 'MCGA';
		mMCGA : TextString := 'MONOCHROM MCGA';
	END;

	InitIntuiText(TxtTit13, 26, 5, cBlack, cMagenta, TextString, TxtTit12);

	IF MouseAvail THEN TextString := 'PRESENT'		(* Maus angeschlossen		*)
	ELSE TextString := 'NOT PRESENT';

	InitIntuiText(TxtTit14, 26, 6, cBlack, cMagenta, TextString, TxtTit13);

	Str(SerialPorts, TextString); 						(* Anzahl serieller Ports	*)
	InitIntuiText(TxtTit15, 26, 7, cBlack, cMagenta, TextString, TxtTit14);

	Str(ParallelPorts, TextString);						(* Anzahl paralleler Ports *)
	InitIntuiText(TxtTit16, 26, 8, cBlack, cMagenta, TextString, TxtTit15);

	Str(NrOfDiskDrives, TextString); 					(* Anzahl Laufwerke			*)
	InitIntuiText(TxtTit17, 26, 9, cBlack, cMagenta, TextString, TxtTit16);

	IF HardDiskAvail THEN TextString := 'PRESENT'	(* HardDisk angeschlossen 	*)
	ELSE TextString := 'NOT PRESENT';

	InitIntuiText(TxtTit18, 26, 10, cBlack, cMagenta, TextString, TxtTit17);
	InitIntuiText(TxtTit19, 26, 11, cBlack, cMagenta, BiosDate, TxtTit18);

	FirstDrive := 'A';										(* Ab hier wird gesucht		*)

	WHILE NOT DriveExist(FirstDrive) DO					(* Erstes Laufwerk suchen	*)
		Inc(FirstDrive);

	LastDrive := FirstDrive;								(* Ab hier weitersuchen		*)

	WHILE DriveExist(LastDrive) DO Inc(LastDrive);	(* Letztes Laufwerk suchen	*)

	InitIntuiText(TxtTit21, 26, 12, cBlack, cMagenta,
					  FirstDrive + ':\  ' + Chr(26) + '  ' + Pred(LastDrive) +
					  ':\', TxtTit19);

	InitIntuiText(TxtOk, 32, 13, cBlack, cMagenta, '', NIL);
	InitGadget(GadOk, 32, 13, 8, 3, TxtOk, cWhite, cMagenta, NIL, OkGadget);

	InitRequester(InfoReq, 17, 4, 43, 17, cYellow, cMagenta,
					  ' System Information ',
					  [rMove, rShadow, rClose, rTitle, rDouble], GadOk, TxtTit21);

	Status := OpenRequester(InfoReq);   				(* Requester ”ffnen			*)

	IF Status THEN
		Status := CloseRequester(InfoReq);				(* Requester schlieáen		*)
END; (* DoSystemInfo *)

(* Diese Prozedur gibt Informationen ber den Speicher des Computers aus *)
PROCEDURE DoMemorySizes(XmsUsage : BOOLEAN);
VAR TextString	: STRING [10]; 	  		 				(* Textstring einer Zahl	*)
	 VerLowStr, 												(* EMM Text vor Punkt		*)
	 VerHighStr : STRING[2];								(* EMM Text nach Punkt		*)
	 VerLow, 													(* EMM Version nach Punkt	*)
	 VerHigh,   			  									(* EMM Version vor Punkt	*)
	 SizeLow,            									(* Low-Byte von Ext-Size	*)
	 SizeHigh   : BYTE;										(* High-Byte von Ext-Size	*)
	 TotalXms,													(* Gesamter XMS Speicher	*)
	 LargestXms : WORD;										(* Gr”áter XMS Block frei	*)
	 TxtTit1, 													(* Texte auf dem Requester	*)
	 TxtTit2,
	 TxtTit3,
	 TxtTit4,
	 TxtTit5,
	 TxtTit6,
	 TxtTit7,
	 TxtTit8,
	 TxtTit9,
	 TxtTit10,
	 TxtTit11,
	 TxtTit12,
	 TxtTit13,
	 TxtTit14,
	 TxtTit15,
	 TxtTit16,
	 TxtTit17,
	 TxtTit18,
	 TxtTit19,
	 TxtTit20,
	 TxtTit21,
	 TxtTit22,
	 TxtOk	   : pIntuiText;								(* Text fr Ok-Gadget		*)
	 GadOk	   : pGadget;									(* Ok-Gadget					*)
	 InfoReq	   : pRequester;			  	 				(* Requester Information	*)
	 Status	   : BOOLEAN;				  					(* Status des Requesters	*)
BEGIN
	InitIntuiText(TxtTit1, 3, 2, cBlack, cMagenta,
					  'DOS MEMORY      - INSTALLED', NIL);

	InitIntuiText(TxtTit2, 21, 3, cBlack, cMagenta, 'FREE', TxtTit1);

	InitIntuiText(TxtTit3, 3, 5, cBlack, cMagenta,
					  'EXTENDED MEMORY - STARTADDRESS', TxtTit2);

	InitIntuiText(TxtTit15, 21, 6, cBlack, cMagenta, 'INSTALLED', TxtTit3);
	InitIntuiText(TxtTit4, 21, 7, cBlack, cMagenta, 'FREE', TxtTit15);

	InitIntuiText(TxtTit5, 3, 9, cBlack, cMagenta,
					  'EXPANDED MEMORY - VERSION', TxtTit4);

	InitIntuiText(TxtTit6, 21, 10, cBlack, cMagenta, 'INSTALLED', TxtTit5);
	InitIntuiText(TxtTit7, 21, 11, cBlack, cMagenta, 'FREE', TxtTit6);

	InitIntuiText(TxtTit17, 3, 13, cBlack, cMagenta,
					  'XMS MEMORY      - VERSION', TxtTit7);

	InitIntuiText(TxtTit18, 21, 14, cBlack, cMagenta, 'LARGEST', TxtTit17);
	InitIntuiText(TxtTit19, 21, 15, cBlack, cMagenta, 'FREE', TxtTit18);

	Str(MainMemSize, TextString); 						(* Hauptspeichergr”áe		*)
	InitIntuiText(TxtTit8, 34, 2, cBlack, cMagenta, TextString, TxtTit19);

	Str(MemAvail, TextString); 							(* Hauptspeicher noch da	*)
	InitIntuiText(TxtTit9, 34, 3, cBlack, cMagenta, TextString, TxtTit8);

	Str(ExtMemStart, TextString); 						(* Startadresse vom EXT 	*)
	InitIntuiText(TxtTit10, 34, 5, cBlack, cMagenta, TextString, TxtTit9);

	ReadCMos($17, SizeLow);	 			  					(* Daten aus CMOS lesen		*)
	ReadCMos($18, SizeHigh);

	Str((LONGINT(SizeLow) + 256 * LONGINT(SizeHigh)) * 1024, TextString);
	InitIntuiText(TxtTit16, 34, 6, cBlack, cMagenta, TextString, TxtTit10);

	Str(LONGINT(ExtMemSize) * 1024, TextString); 	(* Speichergr”áe vom EXT	*)
	InitIntuiText(TxtTit11, 34, 7, cBlack, cMagenta, TextString, TxtTit16);

	IF EmsMemAvail THEN										(* Expandend Speicher da	*)
	BEGIN
		GetEmsVersion(VerHigh, VerLow);					(* EMS Version ermitteln	*)
		Str(VerHigh, VerHighStr);	  						(* Ziffer vor dem Punkt		*)
		Str(VerLow, VerLowStr);   	  						(* Ziffer hinter dem Punkt	*)

		InitIntuiText(TxtTit12, 34, 9, cBlack, cMagenta,
						  'V' + VerHighStr + '.' + VerLowStr, TxtTit11);

		Str(LONGINT(EmsNrOfPages) * 16384, TextString);
		InitIntuiText(TxtTit13, 34, 10, cBlack, cMagenta, TextString, TxtTit12);

		Str(LONGINT(NrOfAvailablePages) * 16384, TextString);
		InitIntuiText(TxtTit14, 34, 11, cBlack, cMagenta, TextString, TxtTit13);
	END
	ELSE															(* Kein EMS Speicher da 	*)
	BEGIN
		InitIntuiText(TxtTit12, 34, 9, cBlack, cMagenta, 'NOT PRESENT', TxtTit11);
		InitIntuiText(TxtTit13, 34, 10, cBlack, cMagenta, '0', TxtTit12);
		InitIntuiText(TxtTit14, 34, 11, cBlack, cMagenta, '0', TxtTit13);
	END;

	IF XmsUsage THEN											(* XMS Speicher benutzt		*)
	BEGIN
		GetInternRevision(VerHigh, VerLow);	  			(* XMS Version ermitteln	*)

		VerHighStr[1] := Chr((VerHigh AND $0F) + Ord('0'));
		VerHighStr[0] := Chr(1);							(* Version vor dem Punkt	*)

		VerLowStr[1] := Chr(((VerLow AND $F0) SHR 4) + Ord('0'));
		VerLowStr[2] := Chr((VerLow AND $0F) + Ord('0'));
		VerLowStr[0] := Chr(2);								(* Version nach dem Punkt	*)

		InitIntuiText(TxtTit20, 34, 13, cBlack, cMagenta,
						  'V' + VerHighStr + '.' + VerLowStr, TxtTit14);

		QueryFreeXms(LargestXms, TotalXms);				(* Freier XMS Speicher		*)

		Str(LONGINT(LargestXms) * 1024, TextString);
		InitIntuiText(TxtTit21, 34, 14, cBlack, cMagenta, TextString, TxtTit20);

		Str(LONGINT(TotalXms) * 1024, TextString);
		InitIntuiText(TxtTit22, 34, 15, cBlack, cMagenta, TextString, TxtTit21);
	END
	ELSE															(* Kein XMS Speicher da		*)
	BEGIN
		InitIntuiText(TxtTit20, 34, 13, cBlack, cMagenta, 'NOT PRESENT',
						  TxtTit14);

		InitIntuiText(TxtTit21, 34, 14, cBlack, cMagenta, '0', TxtTit20);
		InitIntuiText(TxtTit22, 34, 15, cBlack, cMagenta, '0', TxtTit21);
	END;

	InitIntuiText(TxtOk, 37, 16, cBlack, cMagenta, '', NIL);
	InitGadget(GadOk, 37, 16, 8, 3, TxtOk, cWhite, cMagenta, NIL, OkGadget);

	InitRequester(InfoReq, 14, 3, 48, 20, cYellow, cMagenta,
					  ' Memory Sizes ',
					  [rMove, rShadow, rClose, rTitle, rDouble], GadOk, TxtTit22);

	Status := OpenRequester(InfoReq);   				(* Requester ”ffnen			*)

	IF Status THEN
		Status := CloseRequester(InfoReq);				(* Requester schlieáen		*)
END; (* DoMemorySizes *)

(*$F+ Diese Prozedur ist eine Gadgetaktion und schreibt Laufwerkszeichen groá	*)
PROCEDURE UpCaseDrive(GadgetPtr : pGadget);
BEGIN
	WITH GadgetPtr^ DO
	BEGIN
		Buffer[1] := _UpCase(Buffer[1]);					(* Nur Groábuchstaben		*)

		SetVirtualXY(OneText^.LeftEdge + Length(OneText^.Buffer) + 2,
						 OneText^.TopEdge);

		WriteString(Buffer[1], OneText^.DetailPen, OneText^.BlockPen);
	END;
END; (*$F- UpCaseDrive *)

(* Diese Prozedur gibt Informationen ber eine Diskette oder Festplatte aus *)
PROCEDURE DoDiskInfo;
VAR Dummy,														(* Dient als Platzhalter	*)
	 DoCont   : BOOLEAN;										(* Information fortsetzen	*)
	 DiskTyp  : DiskType; 									(* Typ einer Diskette		*)
	 TextStr  : STRING[15];									(* Allgemeiner Text			*)
	 Regs     : REGISTERS;									(* Register des Prozessors	*)
	 TxtTit1,													(* Informationstexte			*)
	 TxtTit2,
	 TxtTit3,
	 TxtTit4,
	 TxtTit5,
	 TxtTit6,
	 TxtTit7,
	 TxtTit8,
	 TxtTit9,
	 TxtTit10,
	 TxtTit11,
	 TxtTit12,
	 TxtTit13,
	 TxtTit14,
	 TxtTit15,
	 TxtTit16,
	 TxtTit17,
	 TxtTit18,
	 TxtTit19,
	 TxtTit20,
	 TxtTit21,
	 TxtTit22,
	 TxtTit23,
	 TxtTit24,
	 TxtOk	 : pIntuiText;									(* Text fr Ok-Gadget		*)
	 GadOk	 : pGadget;										(* Ok-Gadget					*)
	 InfoReq	 : pRequester;			  	 					(* Requester Information	*)
	 VerLow, 													(* Dos Version vor Punkt	*)
	 VerHigh  : BYTE;											(* Dos Version nach Punkt	*)
	 Drive	 : CHAR;
	 Status	 : BOOLEAN;				  						(* Status des Requesters	*)

TYPE DriveParamBlock = RECORD 					 		(* Laufwerksparameter		*)
								  DriveNumber,					(* Zugeh”riges Laufwerk		*)
								  DeviceDriverNr : BYTE;  	(* Zugeh”riger Treiber		*)
								  BytePerSector  : WORD;  	(* Bytes pro Sektor			*)
								  SecPerClusMin1,				(* Sektoren pro Cluster	-1	*)
								  Interleave	  : BYTE;	(* Cluster - Cluster Shift	*)
								  NrOfBootSecs   : WORD;	(* Anzahl Boot Sektoren		*)
								  NrOfFats 		  : BYTE;	(* Anzahl der FAT's			*)
								  NrOfRootItem,				(* Anzahl Eintr„ge in Root	*)
								  FirstDataSec,				(* Erster Datensektor		*)
								  LastCluster 	  : WORD;	(* Letzter Cluster			*)
								  SectorsPerFat,				(* Sektoren pro FAT			*)
								  RootDirSec3 	  : BYTE;	(* Erster Root Sektor Dos3	*)
								  RootDirSec4	  : WORD;	(* Erster Root Sektor Dos4	*)
							  END;

	  pDriveParBlock  = ^DriveParamBlock;				(* Zeiger auf Parameter		*)

(* Diese Prozedur fragt einen Laufwerksbuchstaben ab *)
PROCEDURE AskDiskDrive(VAR Drive : CHAR; VAR DoCont : BOOLEAN);
VAR TxtOk,                   								(* Text des Ok-Gadgets		*)
	 TxtExit,					                        (* Text des Exit-Gadgets	*)
	 TxtDrive : pIntuiText;							  		(* Text fr Laufwerk    	*)
	 GadOk,             									 	(* Ok-Gadget					*)
	 GadExit,                                       (* Exit-Gadget					*)
	 GadDrive : pGadget;                          	(* Gadget fr Laufwerk		*)
	 DriveOk,													(* Laufwerksbuchstabe Ok	*)
	 Status 	 : BOOLEAN;								  		(* Status des Requesters	*)
	 InfoReq  : pRequester;							  		(* Requester fr DriveInfo *)
BEGIN
	InitIntuiText(TxtExit, 3, 4, cBlack, cMagenta, '', NIL);
	InitIntuiText(TxtOk, 27, 4, cBlack, cMagenta, '', NIL);

	InitIntuiText(TxtDrive, 4, 2, cBlack, cMagenta,	(* Eingabe des Laufwerks	*)
					  'Get Information From Drive', NIL);

	InitGadget(GadExit, 3, 4, 8, 3, TxtExit, cWhite, cMagenta, NIL, ExitGadget);

	InitGadget(GadDrive, 4, 2, 26, 1, TxtDrive, cWhite, cMagenta, GadExit,
				  TextGadget);

	InitGadget(GadOk, 27, 4, 8, 3, TxtOk, cWhite, cMagenta, GadDrive, OkGadget);

	WITH GadDrive^ DO											(* Textpufferdaten 			*)
	BEGIN
		Buffer := Drive;
		Size := 1;
		Mask := ['A'..'Z', 'a'..'z'];
		DoAction := TRUE;										(* Aktion Groábuchstaben	*)
		Action := UpCaseDrive;
	END;

	InitRequester(InfoReq, 20, 7, 38, 8, cYellow, cMagenta,
					  ' Get Disk Information ',
					  [rClose, rMove, rShadow, rTitle, rDouble], GadOk, NIL);

	SetKeyStatus(CapsLockKey);								(* CapsLock anschalten		*)
	Status := OpenRequester(InfoReq); 					(* Requester ”ffnen			*)
	DriveOk := Length(GadDrive^.Buffer) = 1;	  		(* L„nge vom Laufwerktext	*)

	IF GetEndGadget(GadOk) = GadOk THEN	   	 		(* Laufwerksname zuweisen	*)
	BEGIN
		IF DriveOk THEN Drive := GadDrive^.Buffer[1];
		DoCont := TRUE;	 		  							(* Information fortsetzen	*)
	END
	ELSE DoCont := FALSE;									(* Information abgebrochen	*)

	IF Status THEN
		Status := CloseRequester(InfoReq);				(* Requester schlieáen		*)

	IF DoCont AND NOT DriveOk THEN						(* Laufwerkbuchstabe fehlt	*)
	BEGIN
		DoMessage(' Error - Missing Drive Character', FALSE, DoCont);
		DoCont := FALSE;										(* Information abgebrochen	*)
	END;

	DelKeyStatus(CapsLockKey);								(* CapsLock ausschalten		*)
END; (* AskDiskDrive *)

BEGIN (* DoDiskInfo *)
	Drive := 'A';
	AskDiskDrive(Drive, DoCont);							(* Laufwerk erfragen			*)

	IF DoCont THEN												(* Information fortsetzen	*)
	BEGIN
		DiskTyp := GetDiskType(Drive);	  				(* Typ der Diskette			*)

		CASE DiskTyp OF						  				(* Disktyp unterscheiden	*)
			UnknownDisk   :
				DoMessage(' Error - Type Of Disk Is Illegal', FALSE, Dummy);

			DiskFailure   :
				DoMessage('   Error - Disk Has Read Errors', FALSE, Dummy);

			DriveNotReady :
				DoMessage(' Error - Disk Drive Is Not Ready', FALSE, Dummy);

			UnknownDrive  :
				DoMessage('  Error - Drive Is Not Installed', FALSE, Dummy);
		ELSE 		 				  								(* Alles in Ordnung			*)
			Regs.AH := $32;									(* Hole Parameter Block		*)
			Regs.DL := Ord(Drive) - Ord('A') + 1; 		(* Nummer des Laufwerks		*)
			MsDos(Regs);								  		(* Dos Interrupt				*)

			WITH pDriveParBlock(Ptr(Regs.DS, Regs.BX))^ DO
			BEGIN
				InitIntuiText(TxtTit1, 3, 2, cBlack, cMagenta,
								  'DISK SIZE                -', NIL);

				InitIntuiText(TxtTit2, 3, 3, cBlack, cMagenta,
								  'DISK FREE                -', TxtTit1);

				InitIntuiText(TxtTit3, 3, 4, cBlack, cMagenta,
								  'DISK VOLUME ID           -', TxtTit2);

				InitIntuiText(TxtTit4, 3, 5, cBlack, cMagenta,
								  'BYTES PER SECTOR         -', TxtTit3);

				InitIntuiText(TxtTit5, 3, 6, cBlack, cMagenta,
								  'SECTORS PER CLUSTER      -', TxtTit4);

				InitIntuiText(TxtTit6, 3, 7, cBlack, cMagenta,
								  'NUMBER OF BOOT SECTORS   -', TxtTit5);

				InitIntuiText(TxtTit7, 3, 8, cBlack, cMagenta,
								  'NUMBER OF FATS           -', TxtTit6);

				InitIntuiText(TxtTit8, 3, 9, cBlack, cMagenta,
								  'NUMBER OF ROOT ITEMS     -', TxtTit7);

				InitIntuiText(TxtTit9, 3, 10, cBlack, cMagenta,
								  'FIRST DATA SECTOR        -', TxtTit8);

				InitIntuiText(TxtTit10, 3, 11, cBlack, cMagenta,
								  'NUMBER OF CLUSTERS       -', TxtTit9);

				InitIntuiText(TxtTit11, 3, 12, cBlack, cMagenta,
								  'SECTORS PER FAT          -', TxtTit10);

				InitIntuiText(TxtTit12, 3, 13, cBlack, cMagenta,
								  'FIRST ROOT SECTOR        -', TxtTit11);


				Str(DiskSize(Ord(Drive) - Ord('A') + 1), TextStr);
				InitIntuiText(TxtTit13, 32, 2, cBlack, cMagenta, TextStr,
								  TxtTit12);

				Str(DiskFree(Ord(Drive) - Ord('A') + 1), TextStr);
				InitIntuiText(TxtTit14, 32, 3, cBlack, cMagenta, TextStr,
								  TxtTit13);

				TextStr := GetVolume(Drive);
				IF Length(TextStr) = 0 THEN TextStr := 'NO VOLUME ID';

				InitIntuiText(TxtTit15, 32, 4, cBlack, cMagenta, TextStr,
								  TxtTit14);

				Str(BytePerSector, TextStr);
				InitIntuiText(TxtTit16, 32, 5, cBlack, cMagenta, TextStr,
								  TxtTit15);

				Str(SecPerClusMin1 + 1, TextStr);
				InitIntuiText(TxtTit17, 32, 6, cBlack, cMagenta, TextStr,
								  TxtTit16);

				Str(NrOfBootSecs, TextStr);
				InitIntuiText(TxtTit18, 32, 7, cBlack, cMagenta, TextStr,
								  TxtTit17);

				Str(NrOfFats, TextStr);
				InitIntuiText(TxtTit19, 32, 8, cBlack, cMagenta, TextStr,
								  TxtTit18);

				Str(NrOfRootItem, TextStr);
				InitIntuiText(TxtTit20, 32, 9, cBlack, cMagenta, TextStr,
								  TxtTit19);

				Str(FirstDataSec, TextStr);
				InitIntuiText(TxtTit21, 32, 10, cBlack, cMagenta, TextStr,
								  TxtTit20);

				Str(LastCluster - 1, TextStr);
				InitIntuiText(TxtTit22, 32, 11, cBlack, cMagenta, TextStr,
								  TxtTit21);

				Str(SectorsPerFat, TextStr);
				InitIntuiText(TxtTit23, 32, 12, cBlack, cMagenta, TextStr,
								  TxtTit22);

				MsDosVersion(VerHigh, VerLow);  			(* Dos Version ermitteln	*)

				IF VerHigh > 3 THEN							(* Dos Version gr”áer V3	*)
					Str(RootDirSec4, TextStr)
				ELSE Str(RootDirSec3, TextStr);

				InitIntuiText(TxtTit24, 32, 13, cBlack, cMagenta, TextStr,
								  TxtTit23);

				InitIntuiText(TxtOk, 36, 14, cBlack, cMagenta, '', NIL);

				InitGadget(GadOk, 36, 14, 8, 3, TxtOk, cWhite, cMagenta, NIL,
							  OkGadget);

				InitRequester(InfoReq, 15, 3, 47, 18, cYellow, cMagenta,
								  ' Disk Information ', [rMove, rShadow, rClose,
								  rTitle, rDouble], GadOk, TxtTit24);

				Status := OpenRequester(InfoReq);   	(* Requester ”ffnen			*)

				IF Status THEN
					Status := CloseRequester(InfoReq);	(* Requester schlieáen		*)
			END;
		END;
	END;
END; (* DoDiskInfo *)

END. (* InfoMenu *)
