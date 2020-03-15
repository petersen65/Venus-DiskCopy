(*********************************************************************)
(* Programmname    : DISK.PAS V1.8   	               	            *)
(* Programmautor   : Michael Rippl               		               *)
(* Compiler        : Quick Pascal V1.0      		                     *)
(* Inhalt          : Routinen fÅr Zugriff auf die Diskettenlaufwerke *)
(* Bemerkung       : Nur fÅr AT Rechner aufwÑrts geeignet      		*)
(* Letzte énderung : 20-Jun-1991                                		*)
(*********************************************************************)

UNIT Disk;

INTERFACE

CONST DiskStatusOk		  = 0;							(* Diskettenstatus Ok		*)
		IllegalFunctionNr   = 1;  							(* UnzulÑssige Funktion		*)
		AddressMarkNotFound = 2;  							(* Keine Adressmarkierung	*)
		WriteProtectOn		  = 3; 						  	(* Disk schreibgeschÅtzt	*)
		SectorNotFound		  = 4;							(* Sektor nicht gefunden	*)
		DMAOverflow			  = 8;							(* DMA öberlauf				*)
		ReadError			  = 16;							(* Lesefehler					*)
		DiskControllerError = 32;							(* Disk-Controller Fehler	*)
		CylinderNotFound 	  = 64;							(* Zylinder nicht gefunden	*)
		TimeOutErrorNoDrive = 128;							(* Laufwerk reagiert nicht	*)
		DiskDriveExpected   = 200;							(* Nur Diskettenlaufwerke	*)
		DriveNotInstalled   = 201;							(* Laufwerk ist unbekannt	*)
		DiskDriveNotReady	  = 202;                   (* Laufwerk nicht bereit	*)

CONST BytesPerSector128	  = 0;							(* 128 Byte pro Sektor		*)
		BytesPerSector256	  = 1;							(* 256 Byte pro Sektor		*)
		BytesPerSector512	  = 2;							(* 512 Byte pro Sektor		*)
		BytesPerSector1024  = 3;							(* 1024 Byte pro Sektor		*)
		StdBytesPerSector   = 512;							(* Standard 512 Bytes/Sekt	*)

CONST AvailableCluster = $0000;							(* Cluster frei, 12 Bit		*)
		ReservedClusLow  = $0FF0;							(* Cluster reserviert Low	*)
		ReservedClusHigh = $0FF6;							(* Cluster reserviert High	*)
		BadCluster		  = $0FF7;							(* Cluster beschÑdigt		*)
		ChainEndClusLow  = $0FF8;							(* Clusterkette Ende Low	*)
		ChainEndClusHigh = $0FFF;							(* Clusterkette Ende High	*)

TYPE DiskType 	= (RamDisk, HardDisk, Disk160, Disk320, Disk180, Disk360,
						Disk720, Disk1440, Disk1200, UnknownDisk, DiskFailure,
						DriveNotReady, UnknownDrive);

	  CylFormat = RECORD										(* Formatelement vom Cyl	*)
						  NrOfCyl,                   		(* Nummer vom Zylinder 		*)
						  NrOfSide,								(* Seite der Diskette		*)
						  NrOfSector	  : BYTE;	  		(* Anzahl der Sektoren		*)
						  BytesPerSector : 0..3;			(* Bestimmt Byteanzahl		*)
					  END;

VAR NrOfDiskDrives,       									(* Anzahl der Laufwerke		*)
	 DiskStatus     : BYTE;									(* Status von Operationen	*)

(* Diese Prozedur sichert den Inhalt des DriveInfo Blocks *)
PROCEDURE SaveDriveInfo;

(* Diese Prozedur lÑdt den Inhalt des DriveInfo Blocks zurÅck *)
PROCEDURE LoadDriveInfo;

(* Diese Prozedur bewirkt, da· der DriveInfoBlock mit Daten belegt wird *)
PROCEDURE FillDriveInfo(Drive : CHAR);

(* Diese Prozedur liefert den Media Descriptor und den Fehlerstatus *)
PROCEDURE GetMediaDescriptor(Drive : CHAR; VAR Descriptor, Status : BYTE);

(* Diese Prozedur ermittelt den Typ einer Diskette *)
FUNCTION GetDiskType(Drive : CHAR) : DiskType;

(* Diese Prozedur fÅhrt einen Reset der Diskettenlaufwerke durch *)
PROCEDURE ResetDiskDrives;

(* Festlegung, wie oft bei Fehlern Operationen wiederholt werden sollen *)
PROCEDURE SetTrials(NrOfTrials : BYTE);

(* Diese Prozedur aktualisiert Werte in der Laufwerksparametertabelle *)
PROCEDURE SetDriveInfo(BytesPerSector, SectorsPerTrack, HeadSleepTime : BYTE);

(* Diese Prozedur formatiert eine komplette Spur einer Diskettenseite *)
PROCEDURE FormatTrack(Drive : CHAR; Side, Cylinder, SectorsPerTrack : BYTE;
							 TrackFormatBuffer : POINTER);

(* Diese Prozedur liest eine bestimmte Anzahl von Sektoren in einen Puffer *)
PROCEDURE ReadSectors(Drive : CHAR; Side, Cylinder, FirstSector,
							 NrOfSectors : BYTE; Buffer : POINTER);

(* Diese Prozedur schreibt eine bestimmte Anzahl von Sektoren auf Diskette *)
PROCEDURE WriteSectors(Drive : CHAR; Side, Cylinder, FirstSector,
							  NrOfSectors : BYTE; Buffer : POINTER);

(* Diese Prozedur verifiziert eine Anzahl von Sektoren auf Diskette *)
PROCEDURE VerifySectors(Drive : CHAR; Side, Cylinder, FirstSector,
								NrOfSectors : BYTE; Buffer : POINTER);

(* Diese Prozedur legt das Diskettenformat der folgenden Formatierung fest *)
PROCEDURE SetDiskFormat(Drive : CHAR; Format : BYTE);

(* Diese Prozedur formatiert eine Dos Standardspur *)
PROCEDURE FormatStandard(Drive : CHAR; Side, Cylinder : BYTE;
								 DskTyp : DiskType);

(* Diese Prozedur liest eine Dos Standardspur in einen Puffer *)
PROCEDURE ReadStandard(Drive : CHAR; Side, Cylinder : BYTE;
							  DskTyp : DiskType; Buffer : POINTER);

(* Diese Prozedur schreibt eine Dos Standardspur auf Diskette *)
PROCEDURE WriteStandard(Drive : CHAR; Side, Cylinder : BYTE;
								DskTyp : DiskType; Buffer : POINTER);

(* Diese Prozedur verifiziert eine Dos Standardspur auf Diskette *)
PROCEDURE VerifyStandard(Drive : CHAR; Side, Cylinder : BYTE;
								 DskTyp : DiskType; Buffer : POINTER);

(* Diese Funktion ermittelt, ob ein bestimmtes Laufwerk vorhanden ist *)
FUNCTION DriveExist(Drive : CHAR) : BOOLEAN;

(* Diese Funktion ermittelt, ob ein Laufwerk eine Festplatte ist oder nicht *)
FUNCTION IsHardDisk(Drive : CHAR) : BOOLEAN;

(* Es wird eine absolute Sektornummer in Seite, Spur, Sektor umgerechnet *)
PROCEDURE GetDiskPosition(DiskTyp : DiskType; AbsSector : WORD;
								  VAR Side, Cylinder, Sector : BYTE);

(* Es wird Seite, Spur, Sektor in eine absolute Sektornummer umgerechnet *)
PROCEDURE GetAbsoluteSector(DiskTyp : DiskType; Side, Cylinder, Sector : BYTE;
									 VAR AbsSector : WORD);

(* Diese Prozedur liest hintereinanderliegende Sektoren in einen Puffer *)
PROCEDURE ReadSingleStandard(Drive : CHAR; DiskTyp : DiskType;
									  AbsSector, NrOfSectors : WORD; Buffer : POINTER);

(* Diese Prozedur schreibt hintereinanderliegende Sektoren aus einen Puffer *)
PROCEDURE WriteSingleStandard(Drive : CHAR; DiskTyp : DiskType;
										AbsSector, NrOfSectors : WORD; Buffer : POINTER);

(* Diese Prozedur liest die FAT einer Diskette ein *)
PROCEDURE GetFAT(Drive : CHAR; VAR Buffer : POINTER;
					  VAR SecPerFat, SecPerCluster : BYTE; VAR FirstData : WORD);

(* Diese Funktion berechnet fÅr einen Cluster seinen logischen Sektor *)
FUNCTION GetLogicalSector(Cluster, FirstDataSec : WORD;
								  SecPerCluster : BYTE) : WORD;

(* Diese Funktion berechnet fÅr einen logischen Sektor seinen Cluster *)
FUNCTION GetCluster(LogicalSector, FirstDataSec : WORD;
						  SecPerCluster : BYTE) : WORD;

(* Diese Prozedur ermittelt den Typ eines Clusters mit Hilfe der FAT, 12 Bit *)
FUNCTION GetClusterType(FatBuffer : POINTER; Cluster : WORD) : WORD;

(* Diese Funktion stellt mit Hilfe der FAT fest, ob ein Track leer ist *)
FUNCTION TrackIsEmpty(FatBuffer : POINTER; DiskTyp : DiskType;
							 FirstDataSec : WORD;
							 SecPerCluster, Side, Cylinder : BYTE) : BOOLEAN;

IMPLEMENTATION

USES Dos;														(* Units einbinden			*)

TYPE DriveParamBlock = RECORD 					 		(* Laufwerksparameter		*)
								  DriveNumber,					(* Zugehîriges Laufwerk		*)
								  DeviceDriverNr : BYTE;  	(* Zugehîriger Treiber		*)
								  BytePerSector  : WORD;  	(* Bytes pro Sektor			*)
								  SecPerClusMin1,				(* Sektoren pro Cluster	-1	*)
								  Interleave	  : BYTE;	(* Cluster - Cluster Shift	*)
								  NrOfBootSecs   : WORD;	(* Anzahl Boot Sektoren		*)
								  NrOfFats 		  : BYTE;	(* Anzahl der FAT's			*)
								  NrOfRootItem,				(* Anzahl EintrÑge in Root	*)
								  FirstDataSec,				(* Erster Datensektor		*)
								  LastCluster 	  : WORD;	(* Letzter Cluster			*)
								  SectorsPerFat,				(* Sektoren pro FAT			*)
								  RootDirSec3 	  : BYTE;	(* Erster Root Sektor Dos3	*)
								  RootDirSec4	  : WORD;	(* Erster Root Sektor Dos4	*)
							  END;

	  DriveInfo  		= RECORD								(* Laufwerksinformation		*)
								  StepTime,						(* Schrittzeit fÅr Motor	*)
								  DMAMode,						(* Mode fÅr DMA Kontroller	*)
								  MotorRunTime,				(* Nachlaufzeit vom Motor	*)
								  BytesPerSector,				(* Bytes pro Sektor			*)
								  SectorsPerTrack,			(* Sektoren pro Spur			*)
								  TimeBetweenSecs,         (* Zeit zwischen Sektoren	*)
								  DataTransferLen, 		 	(* DatentransferlÑnge		*)
								  MagneticalBlank,			(* Magnetische LÅcke			*)
								  FormatCharacter,			(* Format FÅllzeichen		*)
								  HeadSleepTime,				(* Kopf Ruhezeit 				*)
								  MotorStartTime  : BYTE;  (* Startzeit vom Motor		*)
							  END;

	  Address 			= RECORD			 		  			(* Bestandteile von Zeiger	*)
								  Offset,                  (* Offset eines Zeigers		*)
								  Segment : WORD;          (* Segment eines Zeigers	*)
							  END;

	  pDriveParBlock  = ^DriveParamBlock;				(* Zeiger auf Parameter		*)

VAR DiskTrials  : BYTE;										(* Wiederholung bei Fehler	*)
	 pDriveInfo  : ^DriveInfo ABSOLUTE $0000:$0078;	(* Zeiger auf LaufwerkInfo *)
	 DrvInfoCopy : DriveInfo;								(* Kopie von LaufwerkInfo	*)

(* Diese Prozedur sichert den Inhalt des DriveInfo Blocks *)
PROCEDURE SaveDriveInfo;
BEGIN
	DrvInfoCopy := pDriveInfo^;							(* Inhalt des Info Blocks	*)
END; (* SaveDriveInfo *)

(* Diese Prozedur lÑdt den Inhalt des DriveInfo Blocks zurÅck *)
PROCEDURE LoadDriveInfo;
BEGIN
	pDriveInfo^ := DrvInfoCopy;							(* Inhalt des Info Blocks	*)
END; (* LoadDriveInfo *)

(* Diese Prozedur bewirkt, da· der DriveInfoBlock mit Daten belegt wird *)
PROCEDURE FillDriveInfo(Drive : CHAR);
VAR Result : SearchRec;
BEGIN
	FindFirst(Drive + ':\*.*', AnyFile, Result);
	IF IOResult = 0 THEN FindNext(Result);				(* Falls kein Volume-Label	*)
END; (* FillDriveInfo *)

(* Festlegung, wie oft bei Fehlern Operationen wiederholt werden sollen *)
PROCEDURE SetTrials(NrOfTrials : BYTE);
BEGIN
	DiskTrials := NrOfTrials;								(* Wiederholung einstellen	*)
END; (* SetTrials *)

(* Diese Prozedur aktualisiert Werte in der Laufwerksparametertabelle *)
PROCEDURE SetDriveInfo(BytesPerSector, SectorsPerTrack, HeadSleepTime : BYTE);
BEGIN
	pDriveInfo^.SectorsPerTrack := SectorsPerTrack;
	pDriveInfo^.HeadSleepTime := HeadSleepTime;
	pDriveInfo^.BytesPerSector := BytesPerSector;
END; (* SetDriveInfo *)

(* Diese Prozedur liefert den Media Descriptor und den Fehlerstatus *)
PROCEDURE GetMediaDescriptor(Drive : CHAR; VAR Descriptor, Status : BYTE);
VAR Regs : REGISTERS;
BEGIN
	Regs.AH := $1C;											(* Informationen holen		*)
	Regs.DL := Ord(Drive) - Ord('A') + 1;				(* Nummer des Laufwerks		*)
	MsDos(Regs);												(* Dos Interrupt				*)
	Descriptor := Mem[Regs.DS:Regs.BX];	  		 		(* Media Descriptor			*)

	IF Regs.AL = $FF THEN									(* Es liegt ein Fehler vor	*)
	BEGIN
		Regs.AH := $59;										(* Detaillierter Fehler		*)
		Regs.BX := 0;
		MsDos(Regs);		  									(* Dos Interrupt				*)
		Status := Regs.AX;									(* Fehlerbeschreibung		*)
	END
	ELSE Status := 0;											(* Alles in Ordnung			*)
END; (* GetMediaDescriptor *)

(* Diese Funktion ermittelt den Typ einer Diskette *)
FUNCTION GetDiskType(Drive : CHAR) : DiskType;
VAR Regs 			  : REGISTERS;
	 Status,
	 MediaDescriptor : BYTE;
BEGIN
	GetMediaDescriptor(Drive, MediaDescriptor, Status);

	IF Status <> 0 THEN										(* Es liegt ein Fehler vor	*)
	BEGIN
		IF Status = 21 THEN GetDiskType := DriveNotReady
		ELSE IF Status = 15 THEN GetDiskType := UnknownDrive
		ELSE GetDiskType := DiskFailure;
	END
	ELSE															(* Alles in Ordnung			*)
	BEGIN
		Regs.AH := $32;										(* Hole Parameter Block		*)
		Regs.DL := Ord(Drive) - Ord('A') + 1;			(* Nummer des Laufwerks		*)
		MsDos(Regs);											(* Dos Interrupt				*)

		WITH pDriveParBlock(Ptr(Regs.DS, Regs.BX))^ DO
		BEGIN
			IF NrOfFats = 1 THEN
				GetDiskType := RamDisk			  			(* RamDisk hat eine FAT		*)
			ELSE IF MediaDescriptor = $F8 THEN
				GetDiskType := HardDisk						(* Festplatte					*)
			ELSE IF MediaDescriptor = $F0 THEN
				GetDiskType := Disk1440						(* 1.44 MB 3.5" 18 Sektor	*)
			ELSE
			BEGIN
				CASE LastCluster OF
					314  : GetDiskType := Disk160;		(* 160 KB 5.25" 8 Sektor   *)
					316  : GetDiskType := Disk320;      (* 320 KB 5.25" 8 Sektor   *)
					352  : GetDiskType := Disk180;		(* 180 KB 5.25" 9 Sektor   *)
					355  : GetDiskType := Disk360;		(* 360 KB 5.25" 9 Sektor  	*)
					714  : GetDiskType := Disk720;		(* 720 KB 3.5" 9 Sektor  	*)
					2372 : GetDiskType := Disk1200;		(* 1.2 MB 5.25" 15 Sektor  *)

					ELSE GetDiskType := UnknownDisk; 	(* Unbekanntes Format		*)
				END;
			END;
		END;
	END;
END; (* GetDiskType *)

(* Diese Prozedur fÅhrt einen Reset der Diskettenlaufwerke durch *)
PROCEDURE ResetDiskDrives;
VAR Regs : REGISTERS;
BEGIN
	Regs.AH := $00;											(* Reset der Laufwerke		*)
	Regs.DL := $00;
	Intr($13, Regs);											(* Disketten Interrupt		*)
END; (* ResetDiskDrives *)

(* Diese Prozedur formatiert eine komplette Spur einer Diskettenseite *)
PROCEDURE FormatTrack(Drive : CHAR; Side, Cylinder, SectorsPerTrack : BYTE;
							 TrackFormatBuffer : POINTER);
VAR Regs   : REGISTERS;
	 Trials : BYTE;										 	(* Wiederholungen				*)
BEGIN
	Trials := 1;												(* Erster Versuch				*)

	REPEAT
		Regs.AH := $05;										(* Diskette formatieren		*)
		Regs.DL := Ord(Drive) - Ord('A');				(* Nummer des Laufwerks		*)
		Regs.DH := Side;										(* Seite der Diskette		*)
		Regs.CH := Cylinder;								  	(* Nummer des Zylinders		*)
		Regs.AL := SectorsPerTrack;						(* Sektoren pro Spur			*)
		Regs.ES := Address(TrackFormatBuffer).Segment;
		Regs.BX := Address(TrackFormatBuffer).Offset;
		Intr($13, Regs);										(* Disketten Interrupt		*)

		IF Regs.Flags AND FCarry = 0 THEN
			DiskStatus := DiskStatusOk         	  		(* Alles in Ordnung			*)
		ELSE
		BEGIN
			DiskStatus := Regs.AH;  				  	  	(* Fehlerstatus 				*)
			ResetDiskDrives;                         	(* Reset von Laufwerken		*)
		END;

		Inc(Trials);  											(* NÑchster Versuch			*)
	UNTIL (DiskStatus = DiskStatusOk) OR (Trials > DiskTrials);
END; (* FormatTrack *)

(* Diese Prozedur liest eine bestimmte Anzahl von Sektoren in einen Puffer *)
PROCEDURE ReadSectors(Drive : CHAR; Side, Cylinder, FirstSector,
							 NrOfSectors : BYTE; Buffer : POINTER);
VAR Regs   : REGISTERS;
	 Trials : BYTE;										 	(* Wiederholungen				*)
BEGIN
	Trials := 1;												(* Erster Versuch				*)

	REPEAT
		Regs.AH := $02;										(* Diskette lesen      		*)
		Regs.DL := Ord(Drive) - Ord('A');				(* Nummer des Laufwerks		*)
		Regs.DH := Side;										(* Seite der Diskette		*)
		Regs.CH := Cylinder;									(* Nummer des Zylinders		*)
		Regs.CL := FirstSector;								(* Erster Sektor Lesen		*)
		Regs.AL := NrOfSectors;								(* Anzahl der Sektoren		*)
		Regs.ES := Address(Buffer).Segment;
		Regs.BX := Address(Buffer).Offset;
		Intr($13, Regs);										(* Disketten Interrupt		*)

		IF Regs.Flags AND FCarry = 0 THEN
			DiskStatus := DiskStatusOk         	  		(* Alles in Ordnung			*)
		ELSE
		BEGIN
			DiskStatus := Regs.AH;  				  	  	(* Fehlerstatus 				*)
			ResetDiskDrives;                         	(* Reset von Laufwerken		*)
		END;

		Inc(Trials);  											(* NÑchster Versuch			*)
	UNTIL (DiskStatus = DiskStatusOk) OR (Trials > DiskTrials);
END; (* ReadSectors *)

(* Diese Prozedur schreibt eine bestimmte Anzahl von Sektoren auf Diskette *)
PROCEDURE WriteSectors(Drive : CHAR; Side, Cylinder, FirstSector,
							  NrOfSectors : BYTE; Buffer : POINTER);
VAR Regs   : REGISTERS;
	 Trials : BYTE;										 	(* Wiederholungen				*)
BEGIN
	Trials := 1;												(* Erster Versuch				*)

	REPEAT
		Regs.AH := $03;										(* Diskette schreiben  		*)
		Regs.DL := Ord(Drive) - Ord('A');				(* Nummer des Laufwerks		*)
		Regs.DH := Side;										(* Seite der Diskette		*)
		Regs.CH := Cylinder;									(* Nummer des Zylinders		*)
		Regs.CL := FirstSector;								(* Erster Sektor Lesen		*)
		Regs.AL := NrOfSectors;								(* Anzahl der Sektoren		*)
		Regs.ES := Address(Buffer).Segment;
		Regs.BX := Address(Buffer).Offset;
		Intr($13, Regs);										(* Disketten Interrupt		*)

		IF Regs.Flags AND FCarry = 0 THEN
			DiskStatus := DiskStatusOk         	  		(* Alles in Ordnung			*)
		ELSE
		BEGIN
			DiskStatus := Regs.AH;  				  	  	(* Fehlerstatus 				*)
			ResetDiskDrives;                         	(* Reset von Laufwerken		*)
		END;

		Inc(Trials);  											(* NÑchster Versuch			*)
	UNTIL (DiskStatus = DiskStatusOk) OR (Trials > DiskTrials);
END; (* WriteSectors *)

(* Diese Prozedur verifiziert eine Anzahl von Sektoren auf Diskette *)
PROCEDURE VerifySectors(Drive : CHAR; Side, Cylinder, FirstSector,
								NrOfSectors : BYTE; Buffer : POINTER);
VAR Regs   : REGISTERS;
	 Trials : BYTE;										 	(* Wiederholungen				*)
BEGIN
	Trials := 1;												(* Erster Versuch				*)

	REPEAT
		Regs.AH := $04;										(* Diskette verifizieren	*)
		Regs.DL := Ord(Drive) - Ord('A');				(* Nummer des Laufwerks		*)
		Regs.DH := Side;										(* Seite der Diskette		*)
		Regs.CH := Cylinder;							  		(* Nummer des Zylinders		*)
		Regs.CL := FirstSector;								(* Erster Sektor Lesen		*)
		Regs.AL := NrOfSectors;								(* Anzahl der Sektoren		*)
		Regs.ES := Address(Buffer).Segment;
		Regs.BX := Address(Buffer).Offset;
		Intr($13, Regs);										(* Disketten Interrupt		*)

		IF Regs.Flags AND FCarry = 0 THEN
			DiskStatus := DiskStatusOk         	  		(* Alles in Ordnung			*)
		ELSE
		BEGIN
			DiskStatus := Regs.AH;  				  	  	(* Fehlerstatus 				*)
			ResetDiskDrives;                         	(* Reset von Laufwerken		*)
		END;

		Inc(Trials);  											(* NÑchster Versuch			*)
	UNTIL (DiskStatus = DiskStatusOk) OR (Trials > DiskTrials);
END; (* VerifySectors *)

(* Diese Prozedur legt das Diskettenformat der folgenden Formatierung fest *)
PROCEDURE SetDiskFormat(Drive : CHAR; Format : BYTE);
VAR Regs : REGISTERS;
BEGIN
	Regs.AH := $17;											(* Diskformat festlegen		*)
	Regs.AL := Format;										(* Nummer vom Diskformat	*)
	Regs.DL := Ord(Drive) - Ord('A');					(* Nummer des Laufwerks		*)
	Intr($13, Regs);											(* Disketten Interrupt		*)
END; (* SetDiskFormat *)

(* Diese Prozedur formatiert eine Dos Standardspur *)
PROCEDURE FormatStandard(Drive : CHAR; Side, Cylinder : BYTE;
								 DskTyp : DiskType);
CONST SectorMax = 18;										(* Grî·te Anzahl Sektoren	*)

TYPE DriveType = (Drive360, Drive720, Drive1200,	(* Laufwerkstypen				*)
						Drive1440, DriveFixed, DriveUnknown);

VAR FormatBuffer    : ARRAY [1..SectorMax] OF
								 CylFormat;	  					(* Puffer fÅr Spurdaten		*)
	 k,
	 Format,               									(* Nummer vom Diskformat	*)
	 SectorsPerTrack : BYTE;								(* Sektoren pro Spur			*)
	 DrvCnt 			  : BYTE;								(* ZÑhler Anzahl Laufwerke	*)
	 Regs 			  : REGISTERS;
	 BiosIdx	  		  : SHORTINT;							(* Index in Bios-Tabelle	*)

	 BiosDrives : ARRAY [1..4] OF
						  RECORD
							  DriveChar	  : CHAR;			(* Laufwerksbuchstabe		*)
							  Typ			  : DriveType;		(* Typ des Laufwerks			*)
						  END;
BEGIN
	DrvCnt := 0;												(* Keine Laufwerke gezÑhlt	*)
	BiosIdx := -1;												(* Wert dient als Vorgabe	*)

	FOR k := 1 TO 4 DO										(* BIOS Laufwerke lîschen	*)
	BEGIN
		WITH BiosDrives[k] DO
		BEGIN
			DriveChar := 'A';
			Typ := DriveUnknown;
		END;
	END;

	FOR k := 0 TO 127 DO										(* Mîgliche DISK Laufwerke	*)
	BEGIN
		IF DrvCnt <= 4 THEN									(* Weniger als 5 Laufwerke	*)
		BEGIN
			Regs.AH := $08;									(* Hole Info Åber Laufwerk	*)
			Regs.DL := k;										(* Nummer des Laufwerks		*)
			Intr($13, Regs);									(* Disketten Interrupt		*)

			IF (Regs.Flags AND FCarry = 0) AND (Regs.BL > 0) THEN
			BEGIN
				Inc(DrvCnt);									(* Neues Laufwerk gefunden	*)

				WITH BiosDrives[DrvCnt] DO					(* Laufwerksinformationen	*)
				BEGIN
					CASE Regs.BL OF
						1 : Typ := Drive360;
						2 : Typ := Drive1200;
						3 : Typ := Drive720;
						4 : Typ := Drive1440;

						ELSE										(* Information ignorieren	*)
							;
					END;

					DriveChar := Chr(k + Ord('A'));		(* Laufwerksbezeichnung		*)
				END;
			END;
		END;
	END;

	FOR k := 1 TO 4 DO										(* Laufwerk im Bios suchen	*)
	BEGIN
		IF (BiosDrives[k].Typ <> DriveUnknown) AND
			(BiosDrives[k].DriveChar = Drive) THEN
			BiosIdx := k;										(* Tabelleneintrag merken	*)
	END;

	CASE DskTyp OF		  										(* Disktyp unterscheiden	*)
		Disk160, Disk320, Disk180, Disk360 :
		BEGIN
			IF BiosIdx = -1 THEN								
				Format := 2                		      (* 360 KB in 1.2 MB			*)
			ELSE IF BiosDrives[BiosIdx].Typ = Drive360 THEN
				Format := 1										(* 360 KB in 360 KB			*)
			ELSE
				Format := 2;    		                  (* 360 KB in 1.2 MB			*)
		END;

		Disk720 :
		BEGIN
			IF BiosIdx = -1 THEN								
				Format := 5                            (* 720 KB in 1.44 MB			*)
			ELSE IF BiosDrives[BiosIdx].Typ = Drive720 THEN
				Format := 4										(* 720 KB in 720 KB			*)
			ELSE
				Format := 5;                           (* 720 KB in 1.44 MB			*)
		END;

		Disk1200 : Format := 3;								(* 1.2 MB in 1.2 MB			*)
		Disk1440 : Format := 6;								(* 1.44 MB in 1.44 MB		*)
	END;

	SetDiskFormat(Drive, Format);							(* Format festlegen			*)

	CASE DskTyp OF	  		 									(* Disktyp unterscheiden	*)
		Disk160, Disk320 :
			SectorsPerTrack := 8;							(* 8 Sektoren pro Spur		*)

		Disk180, Disk360, Disk720 :
			SectorsPerTrack := 9;							(* 9 Sektoren pro Spur		*)

		Disk1200 : SectorsPerTrack := 15;				(* 15 Sektoren pro Spur		*)
		Disk1440 : SectorsPerTrack := 18;				(* 18 Sektoren pro Spur		*)
	END;

	SetDriveInfo(BytesPerSector512, SectorsPerTrack, 1);

	FOR k := 1 TO SectorsPerTrack DO						(* Formatpuffer ausfÅllen	*)
	BEGIN
		WITH FormatBuffer[k] DO
		BEGIN
			NrOfCyl := Cylinder;								(* Zylinder ist konstant 	*)
			NrOfSide := Side;									(* Seite ist konstant		*)
			NrOfSector := k;									(* Sektoren nummerieren	 	*)
			BytesPerSector := BytesPerSector512;		(* 512 Bytes pro Sektor		*)
		END;
	END;

	FormatTrack(Drive, Side, Cylinder, SectorsPerTrack, Addr(FormatBuffer));
END; (* FormatStandard *)

(* Diese Prozedur liest eine Dos Standardspur in einen Puffer *)
PROCEDURE ReadStandard(Drive : CHAR; Side, Cylinder : BYTE;
							  DskTyp : DiskType; Buffer : POINTER);
VAR SectorsPerTrack : BYTE;								(* Sektoren pro Spur			*)
BEGIN
	CASE DskTyp OF	  		 									(* Disktyp unterscheiden	*)
		Disk160, Disk320 :
			SectorsPerTrack := 8;							(* 8 Sektoren pro Spur		*)

		Disk180, Disk360, Disk720 :
			SectorsPerTrack := 9;							(* 9 Sektoren pro Spur		*)

		Disk1200 : SectorsPerTrack := 15;				(* 15 Sektoren pro Spur		*)
		Disk1440 : SectorsPerTrack := 18;				(* 18 Sektoren pro Spur		*)
	END;

	SetDriveInfo(BytesPerSector512, SectorsPerTrack, 1);
	ReadSectors(Drive, Side, Cylinder, 1, SectorsPerTrack, Buffer);
END; (* ReadStandard *)

(* Diese Prozedur schreibt eine Dos Standardspur auf Diskette *)
PROCEDURE WriteStandard(Drive : CHAR; Side, Cylinder : BYTE;
								DskTyp : DiskType; Buffer : POINTER);
VAR SectorsPerTrack : BYTE;								(* Sektoren pro Spur			*)
BEGIN
	CASE DskTyp OF	  		 									(* Disktyp unterscheiden	*)
		Disk160, Disk320 :
			SectorsPerTrack := 8;							(* 8 Sektoren pro Spur		*)

		Disk180, Disk360, Disk720 :
			SectorsPerTrack := 9;							(* 9 Sektoren pro Spur		*)

		Disk1200 : SectorsPerTrack := 15;				(* 15 Sektoren pro Spur		*)
		Disk1440 : SectorsPerTrack := 18;				(* 18 Sektoren pro Spur		*)
	END;

	SetDriveInfo(BytesPerSector512, SectorsPerTrack, 1);
	WriteSectors(Drive, Side, Cylinder, 1, SectorsPerTrack, Buffer);
END; (* WriteStandard *)

(* Diese Prozedur verifiziert eine Dos Standardspur auf Diskette *)
PROCEDURE VerifyStandard(Drive : CHAR; Side, Cylinder : BYTE;
								 DskTyp : DiskType; Buffer : POINTER);
VAR SectorsPerTrack : BYTE;								(* Sektoren pro Spur			*)
BEGIN
	CASE DskTyp OF	  		 									(* Disktyp unterscheiden	*)
		Disk160, Disk320 :
			SectorsPerTrack := 8;							(* 8 Sektoren pro Spur		*)

		Disk180, Disk360, Disk720 :
			SectorsPerTrack := 9;							(* 9 Sektoren pro Spur		*)

		Disk1200 : SectorsPerTrack := 15;				(* 15 Sektoren pro Spur		*)
		Disk1440 : SectorsPerTrack := 18;				(* 18 Sektoren pro Spur		*)
	END;

	SetDriveInfo(BytesPerSector512, SectorsPerTrack, 1);
	VerifySectors(Drive, Side, Cylinder, 1, SectorsPerTrack, Buffer);
END; (* VerifyStandard *)

(* Diese Funktion ermittelt, ob ein bestimmtes Laufwerk vorhanden ist *)
FUNCTION DriveExist(Drive : CHAR) : BOOLEAN;
CONST FcbSize 		= 37;  									(* Grî·e von FCB				*)
		CompleteLen = 12;  									(* LÑnge kompletter Name	*)
VAR FCB 		 : ARRAY [1..FcbSize] OF BYTE;  			(* File Control Block		*)
	 FileName : ARRAY [1..CompleteLen] OF CHAR; 		(* Kompletter Dateiname		*)
	 Regs     : REGISTERS;									(* FÅr Interrupt-Aufrufe	*)
BEGIN
	FileName := ' :          ';							(* Laufwerksname aufnehmen	*)
	FileName[1] := UpCase(Drive);                   (* Laufwerksbuchstabe		*)

	Regs.AH := $29;											(* Dateiname untersuchen	*)
	Regs.DS := Seg(FileName);
	Regs.SI := Ofs(FileName);
	Regs.ES := Seg(FCB);
	Regs.DI := Ofs(FCB);

	MsDos(Regs);												(* Dos Interrupt				*)
	DriveExist := Regs.AL <> $FF;							(* Laufwerk vorhanden		*)
END; (* DriveExist *)

(* Diese Funktion ermittelt, ob ein Laufwerk eine Festplatte ist oder nicht *)
FUNCTION IsHardDisk(Drive : CHAR) : BOOLEAN;
VAR Regs : Registers;										(* FÅr Interruptaufruf		*)
BEGIN
	Regs.AH := $44;		   								(* IOCTL Device 				*)
	Regs.AL := $08;         								(* Laufwerkstyp ermitteln	*)
	Regs.BL := Ord(UpCase(Drive)) - Ord('A') + 1;	(* Laufwerkszahl berechnen	*)
	MsDos(Regs);												(* Dos Interrupt				*)

	IsHardDisk := Regs.AL = $01; 							(* Nummer fÅr Festplatte	*)
END; (* IsHardDisk *)

(* Es wird eine absolute Sektornummer in Seite, Spur, Sektor umgerechnet *)
PROCEDURE GetDiskPosition(DiskTyp : DiskType; AbsSector : WORD;
								  VAR Side, Cylinder, Sector : BYTE);
VAR SecPerCyl  : BYTE;										(* Sektoren pro Zylinder	*)
	 DoubleSide : BOOLEAN;									(* Doppelseitige Diskette	*)
BEGIN
	CASE DiskTyp OF											(* Disktyp unterschieden	*)
		Disk160  :
		BEGIN
			SecPerCyl := 8;									(* 8 Sektoren / Zylinder	*)
			DoubleSide := FALSE;								(* Einseitige Diskette		*)
		END;

		Disk320  :
		BEGIN
			SecPerCyl := 8 * 2;								(* 16 Sektoren / Zylinder	*)
			DoubleSide := TRUE;								(* Zweiseitige Diskette		*)
		END;

		Disk180  :
		BEGIN
			SecPerCyl := 9;									(* 9 Sektoren / Zylinder	*)
			DoubleSide := FALSE;								(* Einseitige Diskette		*)
		END;

		Disk360, Disk720  :
		BEGIN
			SecPerCyl := 9 * 2;								(* 18 Sektoren / Zylinder	*)
			DoubleSide := TRUE;								(* Zweiseitige Diskette		*)
		END;

		Disk1200 :
		BEGIN
			SecPerCyl := 15 * 2; 							(* 30 Sektoren / Zylinder	*)
			DoubleSide := TRUE;								(* Zweiseitige Diskette		*)
		END;

		Disk1440 :
		BEGIN
			SecPerCyl := 18 * 2;								(* 36 Sektoren / Zylinder	*)
			DoubleSide := TRUE;								(* Zweiseitige Diskette		*)
		END;

	ELSE              										(* Rest wird ignoriert		*)
		Exit;														(* Prozedur vorzeitig Ende	*)
	END;

	Cylinder := AbsSector DIV SecPerCyl; 				(* Zylinder berechnen  		*)
	Sector := AbsSector MOD SecPerCyl; 		 			(* Sektoroffset in Zyl.		*)

	IF DoubleSide THEN										(* Zweiseitige Diskette		*)
	BEGIN
		IF Sector >= SecPerCyl DIV 2 THEN  				(* Sektor auf Seite 1		*)
		BEGIN
			Dec(Sector, SecPerCyl DIV 2);					(* Sektoroffset in Spur		*)
			Side := 1;
		END
		ELSE Side := 0;										(* Sektor auf Seite 0 		*)
	END
	ELSE Side := 0;											(* Nur einseitige Diskette	*)
END; (* GetDiskPosition *)

(* Es wird Seite, Spur, Sektor in eine absolute Sektornummer umgerechnet *)
PROCEDURE GetAbsoluteSector(DiskTyp : DiskType; Side, Cylinder, Sector : BYTE;
									 VAR AbsSector : WORD);
VAR SecPerCyl  : BYTE;										(* Sektoren pro Zylinder	*)
	 DoubleSide : BOOLEAN;									(* Doppelseitige Diskette	*)
BEGIN
	CASE DiskTyp OF											(* Disktyp unterschieden	*)
		Disk160  			: SecPerCyl := 8;				(* 8 Sektoren / Zylinder	*)
		Disk320  			: SecPerCyl := 8 * 2;  		(* 16 Sektoren / Zylinder	*)
		Disk180  			: SecPerCyl := 9;		  		(* 9 Sektoren / Zylinder	*)
		Disk360, Disk720  : SecPerCyl := 9 * 2; 		(* 18 Sektoren / Zylinder	*)
		Disk1200 			: SecPerCyl := 15 * 2; 		(* 30 Sektoren / Zylinder	*)
		Disk1440 			: SecPerCyl := 18 * 2; 		(* 36 Sektoren / Zylinder	*)

	ELSE              										(* Rest wird ignoriert		*)
		Exit;														(* Prozedur vorzeitig Ende	*)
	END;

	AbsSector := Cylinder * SecPerCyl;					(* Anfang des Zylinders		*)

	IF Side = 1 THEN											(* Doppelseitige Diskette	*)
		Inc(AbsSector, SecPerCyl DIV 2);					(* Zweite Diskettenseite	*)

	Inc(AbsSector, Sector);									(* Sektor innerhalb Spur	*)
END; (* GetAbsoluteSector *)

(* Diese Prozedur liest hintereinanderliegende Sektoren in einen Puffer *)
PROCEDURE ReadSingleStandard(Drive : CHAR; DiskTyp : DiskType;
									  AbsSector, NrOfSectors : WORD; Buffer : POINTER);
TYPE Address = RECORD										(* Zeigeradresse zerlegen	*)
						Offset,									(* Offsetanteil 				*)
						Segment : WORD;						(* Segmentanteil				*)
					END;

VAR i	  			 : WORD; 									(* Dient als ZÑhler			*)
	 Side,          											(* Seite einer Diskette		*)
	 Cylinder,	  												(* Zylinder einer Diskette	*)
	 Sector,														(* Sektor einer Diskette	*)
	 SecPerTrack : BYTE; 									(* Sektoren pro Spur			*)
BEGIN
	CASE DiskTyp OF	  		  								(* Disktyp unterscheiden	*)
		Disk160, Disk320 :
			SecPerTrack := 8;  								(* 8 Sektoren pro Spur		*)

		Disk180, Disk360, Disk720 :
			SecPerTrack := 9;									(* 9 Sektoren pro Spur		*)

		Disk1200 : SecPerTrack := 15;	  					(* 15 Sektoren pro Spur		*)
		Disk1440 : SecPerTrack := 18;	  					(* 18 Sektoren pro Spur		*)
	END;

	SetDriveInfo(BytesPerSector512, SecPerTrack, 1);

	FOR i := 0 TO NrOfSectors - 1 DO	  					(* Jeden Sektor einlesen	*)
	BEGIN
		GetDiskPosition(DiskTyp, AbsSector + i, Side, Cylinder, Sector);
		ReadSectors(Drive, Side, Cylinder, Sector + 1, 1, Buffer);
		Inc(Address(Buffer).Offset, StdBytesPerSector);

		IF DiskStatus <> DiskStatusOk THEN				(* Fehler ist aufgetreten	*)
			Exit;													(* Prozedur vorzeitig Ende	*)
	END;
END; (* ReadSingleStandard *)

(* Diese Prozedur schreibt hintereinanderliegende Sektoren aus einen Puffer *)
PROCEDURE WriteSingleStandard(Drive : CHAR; DiskTyp : DiskType;
										AbsSector, NrOfSectors : WORD; Buffer : POINTER);
TYPE Address = RECORD										(* Zeigeradresse zerlegen	*)
						Offset,									(* Offsetanteil 				*)
						Segment : WORD;						(* Segmentanteil				*)
					END;

VAR i	  			 : WORD; 									(* Dient als ZÑhler			*)
	 Side,          											(* Seite einer Diskette		*)
	 Cylinder,													(* Zylinder einer Diskette	*)
	 Sector,														(* Sektor einer Diskette	*)
	 SecPerTrack : BYTE; 									(* Sektoren pro Spur			*)
BEGIN
	CASE DiskTyp OF	  		  								(* Disktyp unterscheiden	*)
		Disk160, Disk320 :
			SecPerTrack := 8;  								(* 8 Sektoren pro Spur		*)

		Disk180, Disk360, Disk720 :
			SecPerTrack := 9;									(* 9 Sektoren pro Spur		*)

		Disk1200 : SecPerTrack := 15;	  					(* 15 Sektoren pro Spur		*)
		Disk1440 : SecPerTrack := 18;	  					(* 18 Sektoren pro Spur		*)
	END;

	SetDriveInfo(BytesPerSector512, SecPerTrack, 1);

	FOR i := 0 TO NrOfSectors - 1 DO	  					(* Jeden Sektor einlesen	*)
	BEGIN
		GetDiskPosition(DiskTyp, AbsSector + i, Side, Cylinder, Sector);
		WriteSectors(Drive, Side, Cylinder, Sector + 1, 1, Buffer);
		Inc(Address(Buffer).Offset, StdBytesPerSector);

		IF DiskStatus <> DiskStatusOk THEN				(* Fehler ist aufgetreten	*)
			Exit;													(* Prozedur vorzeitig Ende	*)
	END;
END; (* WriteSingleStandard *)

(* Diese Prozedur liest die FAT einer Diskette ein *)
PROCEDURE GetFAT(Drive : CHAR; VAR Buffer : POINTER;
					  VAR SecPerFat, SecPerCluster : BYTE; VAR FirstData : WORD);
VAR DiskTyp : DiskType;										(* Typ einer Diskette		*)
	 Regs    : REGISTERS;									(* Register des Prozessors	*)
BEGIN
	DiskTyp := GetDiskType(Drive);						(* Diskettentyp ermitteln	*)

	IF NOT (DiskTyp IN [Disk160, Disk180, Disk320,  (* Fehler, falscher Typ		*)
		Disk360, Disk720, Disk1200, Disk1440]) THEN
	BEGIN
		CASE DiskTyp OF										(* Typ wird unterschieden	*)
			RamDisk, HardDisk 		 : DiskStatus := DiskDriveExpected;
			UnknownDisk, DiskFailure : DiskStatus := ReadError;
			DriveNotReady 				 : DiskStatus := DiskDriveNotReady;
			UnknownDrive  				 : DiskStatus := DriveNotInstalled;
		END;
	END
	ELSE															(* Diskette ist Ok			*)
	BEGIN
		Regs.AH := $32;										(* Hole Parameter Block		*)
		Regs.DL := Ord(Drive) - Ord('A') + 1; 			(* Nummer des Laufwerks		*)
		MsDos(Regs);								  			(* Dos Interrupt				*)

		WITH pDriveParBlock(Ptr(Regs.DS, Regs.BX))^ DO
		BEGIN
			SecPerFat := SectorsPerFat;					(* Grî·e der FAT zurÅck		*)
			SecPerCluster := SecPerClusMin1 + 1;		(* Sektoren pro Cluster		*)
			FirstData := FirstDataSec;						(* Erster Datensektor		*)
			GetMem(Buffer, SectorsPerFat * StdBytesPerSector);
			ReadSingleStandard(Drive, DiskTyp, NrOfBootSecs, SecPerFat, Buffer);
		END;
	END;
END; (* GetFAT *)

(* Diese Funktion berechnet fÅr einen Cluster seinen logischen Sektor *)
FUNCTION GetLogicalSector(Cluster, FirstDataSec : WORD;
								  SecPerCluster : BYTE) : WORD;
BEGIN
	GetLogicalSector := FirstDataSec + ((Cluster - 2) * SecPerCluster);
END; (* GetLogicalSector *)

(* Diese Funktion berechnet fÅr einen logischen Sektor seinen Cluster *)
FUNCTION GetCluster(LogicalSector, FirstDataSec : WORD;
						  SecPerCluster : BYTE) : WORD;
BEGIN
	IF LogicalSector < FirstDataSec THEN				(* Ab hier keine Cluster	*)
		GetCluster := 0
	ELSE															(* Cluster berechnen			*)
		GetCluster := 2 + ((LogicalSector - FirstDataSec) DIV	SecPerCluster);
END; (* GetCluster *)

(* Diese Prozedur ermittelt den Typ eines Clusters mit Hilfe der FAT, 12 Bit *)
FUNCTION GetClusterType(FatBuffer : POINTER; Cluster : WORD) : WORD;
VAR Result 		 : LONGINT;	  								(* Index auf Cluster			*)
	 ClusterType : WORD;										(* Gesuchter Clustertyp		*)
TYPE FatArray = ARRAY [0..65519] OF BYTE;				(* FAT als Datenfeld			*)
BEGIN
	Result := (LONGINT(Cluster) * 3) DIV 2;			(* Index auf Cluster			*)

	ClusterType := WORD(FatArray(FatBuffer^)[Result]) OR
		(WORD(FatArray(FatBuffer^)[Result + 1]) SHL 8);

	IF Odd(Cluster) THEN 	  								(* Clusterindex ungerade	*)
		GetClusterType := ClusterType SHR 4
	ELSE GetClusterType := ClusterType AND $0FFF;	(* Clusterindex gerade		*)
END; (* GetClusterType *)

(* Diese Funktion stellt mit Hilfe der FAT fest, ob ein Track leer ist *)
FUNCTION TrackIsEmpty(FatBuffer : POINTER; DiskTyp : DiskType;
							 FirstDataSec : WORD;
							 SecPerCluster, Side, Cylinder : BYTE) : BOOLEAN;
VAR Cluster,													(* Nummer eines Clusters	*)
	 ClusterType,   											(* Typ eines Clusters		*)
	 AbsSector	 : WORD;	 	 								(* Absolute Sektornummer	*)
	 i,															(* Dient als ZÑhler			*)
	 FreeSectors,  		 	  								(* Anzahl freier Sektoren	*)
	 SecPerTrack : BYTE;	  									(* Sektoren pro Spur			*)
BEGIN
	CASE DiskTyp OF											(* Disktyp unterschieden	*)
		Disk160, Disk320 :									(* 8 Sektoren pro Spur		*)
			SecPerTrack := 8;

		Disk180, Disk360, Disk720 :						(* 9 Sektoren pro Spur		*)
			SecPerTrack := 9;

		Disk1200 :          									(* 15 Sektoren pro Spur		*)
			SecPerTrack := 15;

		Disk1440 :												(* 18 Sektoren pro Spur		*)
			SecPerTrack := 18;
	ELSE              										(* Rest wird ignoriert		*)
		Exit;														(* Prozedur vorzeitig Ende	*)
	END;

	FreeSectors := 0;	 										(* Anzahl freier Sektoren	*)

	FOR i := 0 TO SecPerTrack - 1 DO 					(* Alle Sektoren der Spur	*)
	BEGIN
		GetAbsoluteSector(DiskTyp, Side, Cylinder, i, AbsSector);
		Cluster := GetCluster(AbsSector, FirstDataSec, SecPerCluster);
		ClusterType := GetClusterType(FatBuffer, Cluster);

		IF (ClusterType = AvailableCluster) AND  	(* Cluster ist nicht belegt	*)
			(Cluster >= 2) THEN							(* Clusternummer zulÑssig		*)
			Inc(FreeSectors);								(* Ein unbelegter Sektor mehr *)
	END;

	TrackIsEmpty := FreeSectors = SecPerTrack;	(* Spur ist leer oder nicht	*)
END; (* TrackIsEmpty *)

(* Diese Prozedur initialisiert die Unit Disk *)
PROCEDURE Initialize;
VAR Regs : REGISTERS;
BEGIN
	Intr($11, Regs);											(* Rechner-Konfiguration	*)

	IF Regs.AX AND $0001 = 1 THEN							(* Laufwerke vorhanden		*)
		NrOfDiskDrives := ((Regs.AX AND $00C0) SHR 6) + 1
	ELSE NrOfDiskDrives := 0;								(* Kein Diskettenlaufwerk	*)

	DiskStatus := DiskStatusOk;							(* Alles in Ordnung			*)
	SetTrials(5);   											(* Standard Wiederholung	*)
END; (* Initialize *)

BEGIN																(* Initialisierung			*)
	Initialize;
END. (* Disk *)
