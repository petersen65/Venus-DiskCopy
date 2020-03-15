(***************************************************************************)
(* Programmname	 : RESIMAGE.PAS V2.0 											   *)
(* Programmautor	 : Michael Rippl													   *)
(* Compiler 		 : Quick Pascal V1.0 							  			 	   *)
(* Inhalt			 : Kopieren einer Image-Datei von Fesplatte auf Diskette *)
(* Bemerkung		 : Dient als Include-Datei fÅr CopyMenu.Pas 					*)
(* Letzte énderung : 25-Apr-1991 													   *)
(***************************************************************************)

(* Diese Prozedur kopiert eine Image-Datei wieder auf eine Diskette *)
PROCEDURE DoRestoreImage(VAR TargetDrive, SourceHardDisk : CHAR;
								 VAR FromHd : STRING; NrOfErrorTrials : BYTE;
								 HardDiskUsage, VerifyTarget, FormatTarget : BOOLEAN);
CONST CompleteLen = 30;										(* Komplette NamenslÑnge	*)
TYPE CompleteStr = STRING[CompleteLen];		  		(* Typ eines Dateinamens	*)

VAR TempFile  	  : FILE;				  					(* TemporÑre Datei 			*)
	 DiskTypA,                  							(* Typ des Zielaufwerks		*)
	 DiskTypHD    : DiskType;			  					(* Typ des Quellaufwerks	*)
	 Dummy,   													(* Dient als Platzhalter	*)
	 Status,														(* Kopierstatus Ok			*)
	 DoCopy 	     : BOOLEAN;   	  	  					(* Kopieren abbrechen		*)
	 TempFileSize : LONGINT;								(* Grî·e temporÑre Datei	*)

(* Diese Prozedur wird vor dem Kopieren mit zwei Laufwerken aufgerufen *)
PROCEDURE AskRestoreImage(VAR DoCopy : BOOLEAN; VAR DriveA, Partition : CHAR;
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

	InitIntuiText(TxtHdText, 15, 2, cBlack, cMagenta,
					  'Source Partition Is ', NIL);     (* Eingabe der Partition	*)

	InitIntuiText(TxtAText, 15, 3, cBlack, cMagenta,
					  'Target Disk Drive Is', NIL);     (* Eingabe des Laufwerks	*)

	InitIntuiText(TxtTemp, 3, 5, cBlack, cMagenta,	(* Eingabe Dateiname 		*)
					  'Source Filename', NIL);


	InitGadget(GadAText, 15, 3, 20, 1, TxtAText, cWhite, cMagenta, NIL,
				  TextGadget);

	InitGadget(GadHdText, 15, 2, 19, 1, TxtHdText, cWhite, cMagenta, GadAText,
				  TextGadget);

	InitGadget(GadOk, 43, 7, 8, 3, TxtOk, cWhite, cMagenta, GadHdText, OkGadget);

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
					  ' Restore Image To Disk ',
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
		DoMessage(' Error - Missing Source Filename', FALSE, DoCopy);
		DoCopy := FALSE;										(* Kopieren abgebrochen		*)
	END;

	DelKeyStatus(CapsLockKey);								(* CapsLock ausschalten		*)
END; (* AskRestoreImage *)

(* Diese Prozedur kopiert eine Image-Datei wieder auf eine Diskette *)
PROCEDURE RestoreImage(TargetDrive, SourceHardDisk : CHAR; DiskTypA : DiskType);
VAR Cylinder,													(* Cylinder einer Diskette *)
	 CylinderMax : BYTE; 									(* Grî·te Anzahl Cylinder	*)
	 CopyBuffer0,												(* Puffer fÅr Seite 0		*)
	 CopyBuffer1 : POINTER; 								(* Puffer fÅr Seite 1		*)
	 BufferSize  : WORD; 									(* Grî·e des Puffers 		*)
	 DoCopy, 													(* Kopieren fortsetzen		*)
	 DoubleSide  : BOOLEAN; 								(* Einseitg und Zweiseitig *)

(* Diese Prozedur liest eine Spur in einen Puffer *)
PROCEDURE ReadTrack(Side : BYTE; CopyBuffer : POINTER);
VAR Dummy : WORD;												(* Dient als Platzhalter	*)
BEGIN
	WriteToGate('R', Cylinder, Side, cYellow, cRed);
	BlockRead(TempFile, CopyBuffer^, BufferSize, Dummy);
END; (* ReadTrack *)

(* Diese Funktion schreibt eine Spur aus einem Puffer *)
FUNCTION WriteTrack(Side : BYTE; CopyBuffer : POINTER) : BOOLEAN;
BEGIN
	IF FormatTarget THEN 									(* Diskette formatieren 	*)
	BEGIN
		WriteToGate('F', Cylinder, Side, cYellow, cRed);
		FormatStandard(TargetDrive, Side, Cylinder, DiskTypA);

		IF DiskStatus = WriteProtectOn THEN				(* Schreibschutz an			*)
		BEGIN
			RemoveClock;									  	(* Uhr anhalten				*)
			DoMessage('   Error - Remove Write Protect', TRUE, DoCopy);
			InstallClock;										(* Uhr wieder anschalten	*)

			IF DoCopy THEN 									(* Weiterkopieren				*)
				FormatStandard(TargetDrive, Side, Cylinder, DiskTypA)
			ELSE	  												(* Kopieren abgebrochen 	*)
			BEGIN
				WriteTrack := FALSE;
				Exit; 											(* Aktuelle Prozedur Ende	*)
			END;
		END;
	END;

	WriteToGate('W', Cylinder, Side, cYellow, cRed);
	WriteStandard(TargetDrive, Side, Cylinder, DiskTypA, CopyBuffer);

	IF DiskStatus = DiskStatusOk THEN					(* Alles in Ordnung			*)
		WriteToGate(Chr(7), Cylinder, Side, cYellow, cRed)
	ELSE IF DiskStatus = WriteProtectOn THEN
	BEGIN
		RemoveClock;										  	(* Uhr anhalten				*)
		DoMessage('   Error - Remove Write Protect', TRUE, DoCopy);
		InstallClock;	 		  								(* Uhr wieder anschalten	*)

		IF DoCopy THEN 										(* Weiterkopieren 			*)
		BEGIN
			WriteStandard(TargetDrive, Side, Cylinder, DiskTypA, CopyBuffer);

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
				FormatStandard(TargetDrive, Side, Cylinder, DiskTypA);

				WriteToGate('W', Cylinder, Side, cYellow, cRed);
				WriteStandard(TargetDrive, Side, Cylinder, DiskTypA, CopyBuffer);

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
		VerifyStandard(TargetDrive, Side, Cylinder, DiskTypA, CopyBuffer);

		IF DiskStatus = DiskStatusOk THEN
			WriteToGate(Chr(7), Cylinder, Side, cYellow, cRed)
		ELSE WriteToGate('E', Cylinder, Side, cYellow, cRed);
	END;

	WriteTrack := TRUE;										(* Alles in Ordnung			*)
END; (* WriteTrack *)

BEGIN (* RestoreImage *)
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

	GetMem(CopyBuffer0, BufferSize);						(* Speicher Seite 0			*)
	GetMem(CopyBuffer1, BufferSize);						(* Speicher Seite 1			*)
	PutString(19, 4, 'HARD DISK', cLightGreen, cBlue);
	FillDriveInfo(TargetDrive);							(* DriveInfoBlock fÅllen 	*)

	FOR Cylinder := 0 TO CylinderMax DO   				(* Ganze Diskette kopieren *)
	BEGIN
		IF CheckBreak THEN									(* Kopiervorgang abbrechen *)
		BEGIN
			FreeMem(CopyBuffer0, BufferSize);			(* Speicher freigeben		*)
			FreeMem(CopyBuffer1, BufferSize);			(* Speicher freigeben		*)
			Exit; 												(* Aktuelle Prozedur Ende	*)
		END;

		WriteCylinder(Cylinder, DoubleSide);  			(* Cylinder auf Bildschirm *)
		ReadTrack(0, CopyBuffer0);   						(* Spur auf Seite 0 lesen	*)

		IF DoubleSide THEN				  					(* Diskette ist zweiseitig *)
			ReadTrack(1, CopyBuffer1);   					(* Spur auf Seite 1 lesen	*)

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

	FreeMem(CopyBuffer0, BufferSize);  					(* Speicher freigeben		*)
	FreeMem(CopyBuffer1, BufferSize);  					(* Speicher freigeben		*)
	RemoveClock;												(* Die Uhr wird entfernt	*)
	Write(Chr(7)); 											(* Piepston klingen lassen *)
	DoMessage('  ØØ Venus DiskCopy Completed ÆÆ', FALSE, DoCopy);
END; (* RestoreImage *)

BEGIN (* DoRestoreImage *)
	IF NOT (HardDiskAvail AND HardDiskUsage) THEN 	(* Keine Festplatte da 		*)
		DoMessage('  Error - No Harddisks Available', FALSE, Dummy)
	ELSE      													(* Festplatte vorhanden		*)
	BEGIN
		AskRestoreImage(DoCopy, TargetDrive, SourceHardDisk, FromHd);

		IF DoCopy THEN											(* Kopieren fortsetzen		*)
		BEGIN
			Assign(TempFile, SourceHardDisk + ':\' + FromHd);
			Reset(TempFile, 1);		  						(* TemporÑre Datei îffnen	*)

			IF IOResult <> 0 THEN							(* Fehler ist aufgetreten	*)
				DoMessage(' Error - Cannot Open Source File', FALSE, Dummy)
			ELSE													(* TemporÑre Datei ist Ok	*)
			BEGIN
				DoMessage('  Insert Target Disk In Drive ' + TargetDrive + ':',
							 TRUE, DoCopy);

				IF DoCopy THEN			 						(* Kopieren fortsetzen		*)
				BEGIN
					PutString(0, 0, ' RESTORE IMAGE ', cYellow, cRed);

					DiskTypA := GetDiskType(TargetDrive);
					DiskTypHd := GetDiskType(SourceHardDisk);

					IF DiskTypHd <> HardDisk THEN			(* Nur Festplatte erlaubt	*)
					BEGIN
						DoMessage('Error - Drive ' + SourceHardDisk +
									 ': Harddisk Expected', FALSE, Dummy);

						Close(TempFile);						(* Quelldatei schlie·en		*)
					END
					ELSE
					BEGIN
						CASE DiskTypA OF	  					(* Disktyp unterscheiden	*)
							DriveNotReady :
							BEGIN
								DoMessage('  Error - Drive ' + TargetDrive +
											 ': Is Not Ready', FALSE, Dummy);

								Close(TempFile);				(* Quelldatei schlie·en		*)
							END;

							UnknownDrive  :
							BEGIN
								DoMessage('Error - Drive ' + TargetDrive +
											 ': Is Not Installed', FALSE, Dummy);

								Close(TempFile);				(* Quelldatei schlie·en		*)
							END;

							HardDisk, RamDisk :
							BEGIN
								DoMessage('Error - DriveType Of ' + TargetDrive +
											 ': Is Illegal', FALSE, Dummy);

								Close(TempFile);				(* Quelldatei schlie·en		*)
							END;
						ELSE
							TempFileSize := FileSize(TempFile);

																	(* Kein LongInt-Case wegen	*)
																	(* Turbo Pascal V5.5			*)

							IF TempFileSize = 163840 THEN	(* Dateigrî·e fÅr Disktyp	*)
								DiskTypA := Disk160
							ELSE IF TempFileSize = 327680 THEN
								DiskTypA := Disk320
							ELSE IF TempFileSize = 184320 THEN
								DiskTypA := Disk180
							ELSE IF TempFileSize = 368640 THEN
								DiskTypA := Disk360
							ELSE IF TempFileSize = 737280 THEN
								DiskTypA := Disk720
							ELSE IF TempFileSize = 1228800 THEN
								DiskTypA := Disk1200
							ELSE IF TempFileSize = 1474560 THEN
								DiskTypA := Disk1440
							ELSE 									(* Datei ist kein Image		*)
							BEGIN
								DoMessage(' Error - Source File Is No Image',
											 FALSE, Dummy);

								Close(TempFile);				(* Quelldatei schlie·en		*)
								Exit; 							(* Prozedur vorzeitig Ende	*)
							END;

							ReleaseCodeOff;					(* Keine Release Codes		*)
							WriteUnusedGate(DiskTypA);
							WriteDiskType(DiskTypA);
							SaveDriveInfo;
							SetTrials(NrOfErrorTrials);
							InitClock;			  				(* Uhr initialisieren		*)
							InstallClock;		  				(* Ab jetzt lÑuft die Uhr	*)

							RestoreImage(TargetDrive, SourceHardDisk, DiskTypA);

							RemoveClock;						(* Die Uhr wird entfernt	*)
							Close(TempFile);					(* Quelldatei schlie·en		*)
							LoadDriveInfo;
							ResetDiskDrives;
							ReleaseCodeOn;   					(* Tasten Release Codes 	*)
							ClearGate;							(* Alle Ausgaben lîschen	*)
						END;
					END;
				END;
			END;
		END;
	END;
END; (* DoRestoreImage *)
