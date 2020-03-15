(*********************************************************************)
(* Programmname	 : FCP.PAS V1.91 												*)
(* Programmautor	 : Michael Rippl												*)
(* Compiler 		 : Turbo Pascal V5.0 										*)
(* Inhalt			 : Hauptprogramm des Kopierprogramms FCP V1.91		*)
(* Bemerkung		 : Kopiert keine Hidden Dateien und System Dateien	*)
(* Letzte énderung : 22-Jul-1991 												*)
(*********************************************************************)

PROGRAM FCP;		 											(*$I- Kein I/O Checking		*)
																	(*$V- Kein String Checking	*)
																	(*$M 49152, 65536, 655360 	*)

USES Crt, Dos, Fifo, FileInfo;							(* Units einbinden			*)

(* Diese Prozedur kopiert durch Parameter vorgegebene Dateien *)
PROCEDURE DoFileCopy;
CONST BufferSize = 65520;									(* Grî·e des Kopierpuffers	*)

TYPE Status   = (IllegalOpt, TooMuchPars, SubDirOn, EmptyDirOn, InterOn,
					  CopyQuiet, CheckTarget, ArchiveOn);

	  ParamSet = SET OF Status;							(* Statusmenge Parameter	*)

VAR ParamStatus : ParamSet;								(* Status der Parameter		*)
	 CopySource,												(* Quellname einer Datei	*)
	 CopyTarget,												(* Zielname einer Datei		*)
	 SourceName,												(* Name der Quelldatei(en)	*)
	 TargetName  : PathStr;	  								(* Name der Zieldatei		*)
	 i,															(* Dient nur als ZÑhler		*)
	 CopiedFiles, 												(* Anzahl kopierter Files	*)
	 NrOfFiles	 : WORD;		  	   						(* Anzahl aller Dateien		*)
	 FileTable   : pRing;									(* Tabelle aller Dateien	*)
	 ProceedCopy,												(* Kopieren fortsetzen		*)
	 CopyToAFile : BOOLEAN;		  							(* Daten in Datei kopieren	*)
	 TypeOfFile  : FileType;								(* Typ einer Datei			*)
	 Item  		 : pNameRec;  	  							(* Dateieintrag in Tabelle	*)
	 TargetFile  : FILE;			  							(* Typenlose Zieldatei		*)
	 FilesOk		 : BOOLEAN;									(* Zu viele DateieintrÑge	*)

(* Diese Prozedur initialisiert alle Variablen *)
PROCEDURE Initialize;
BEGIN
	SourceName := '';	  		 	     						(* Startwerte eintragen		*)
	TargetName := '';
	ParamStatus := [ ];										(* Parameterstatus leer		*)
	ProceedCopy := FALSE;
	CopyToAFile := FALSE;
	CopiedFiles := 0;	 		  								(* Keine Dateien kopiert	*)
END; (* Initialize *)

(* Diese Prozedur ÅberprÅft die Åbergebenen Parameter *)
PROCEDURE ParamCheck;
VAR i 			: BYTE;	 									(* Dient nur als ZÑhler		*)
	 TextString	: PathStr;									(* Allgemeiner Text			*)

(* Diese Prozedur gibt eine Nachricht aus und beendet dann das Programm *)
PROCEDURE Quit(ErrorCode : BYTE);
BEGIN
	CASE ErrorCode OF											(* Fehler unterscheiden		*)
		1 :
		BEGIN
			Write('Usage : FCP [/i] [/s] [/e] [/q] [/c] [/m] ');
			WriteLn('<source>[[,<source>]...] [<target>]');
		END;

		2 : WriteLn('Illegal Option - ' + TextString);
		3 : WriteLn('Too Much Parameters - ' + TextString);
		4 : WriteLn('Missing Source File');
		5 : WriteLn('Cannot Copy Multiple Hierarchies - ' + SourceName);
	END;

	Halt;															(* Ende des Programms		*)
END; (* Quit *)

BEGIN (* ParamCheck *)
	WriteLn('FCP  Version V1.91  Copyright (c) 1990, 1991 by Michael Rippl');
	WriteLn;

	IF (ParamCount < 1) OR (ParamCount > 8) THEN		(* Parameteranzahl falsch	*)
		Quit(1);   											 	(* Information ausgeben		*)

	i := 1;														(* ZÑhler auf Anfang			*)

	WHILE (i <= ParamCount) AND 							(* Alle Parameter beachten	*)
		([IllegalOpt, TooMuchPars] * ParamStatus = [ ]) DO
	BEGIN
		TextString := ParamStr(i);							(* i-ten Parameter merken	*)

		IF TextString[1] = '/' THEN						(* Option gefunden			*)
		BEGIN
			IF TextString = '/s' THEN 						(* Unterverzeichnisse an	*)
				ParamStatus := ParamStatus + [SubDirOn]
			ELSE IF TextString = '/i' THEN				(* Interaktiv kopieren		*)
				ParamStatus := ParamStatus + [InterOn]
			ELSE IF TextString = '/e' THEN				(* Leere Verzeichnisse an	*)
				ParamStatus := ParamStatus + [EmptyDirOn]
			ELSE IF TextString = '/q' THEN				(* Keine Abfrage zu Beginn	*)
				ParamStatus := ParamStatus + [CopyQuiet]
			ELSE IF TextString = '/c' THEN				(* Zielspeicher prÅfen		*)
				ParamStatus := ParamStatus + [CheckTarget]
			ELSE IF TextString = '/m' THEN				(* Nur Daten mit Archive	*)
				ParamStatus := ParamStatus + [ArchiveOn]
			ELSE													(* Option ist unzulÑssig	*)
				ParamStatus := ParamStatus + [IllegalOpt]
		END
		ELSE IF Length(SourceName) = 0 THEN				(* Quelldateiname gefunden	*)
			SourceName := TextString
		ELSE IF Length(TargetName) = 0 THEN				(* Zieldateiname gefunden	*)
			TargetName := TextString
		ELSE ParamStatus := ParamStatus + [TooMuchPars];

		Inc(i);													(* NÑchsten Parameter		*)
	END;

	FOR i := 1 TO Length(SourceName) DO					(* In Gro·buchstaben			*)
		SourceName[i] := _UpCase(SourceName[i]);

	IF IllegalOpt IN ParamStatus THEN Quit(2)  		(* UnzulÑssige Optionen		*)
	ELSE IF TooMuchPars IN ParamStatus THEN Quit(3)	(* Zu viele Parameter		*)
	ELSE IF Length(SourceName) = 0 THEN	Quit(4) 		(* Quelldatei fehlt			*)
	ELSE IF Length(TargetName) = 0 THEN					(* Zieldatei fehlt			*)
		GetDir(0, TargetName)	  		 					(* Ziel ist aktuelle Dir	*)
	ELSE IF (Pos(',', SourceName) <> 0) AND
		([SubDirOn, EmptyDirOn] * ParamStatus <> [ ]) THEN Quit(5); 
END; (* ParamCheck *)

(* Diese Prozedur holt die durch eine Maske spezifizierten Dateien *)
FUNCTION LookForFiles(FileTable : pRing; VAR NrOfFiles : WORD) : BOOLEAN;
VAR i,						  									(* Dient nur als ZÑhler		*)
	 NrFiles  : WORD;		  									(* Kopie von 'NrOfFiles'	*)
	 NextItem,		 										  	(* Nachfolgender Eintrag	*)
	 Item  	 : pNameRec;   	 							(* Dateieintrag in Tabelle	*)
	 SrcFile  : FILE;
	 Source	 : PathStr;
BEGIN
	IF SubDirOn IN ParamStatus THEN						(* Unterverzeichnisse an	*)
	BEGIN
		LookForFiles := GetFiles(SourceName, FileTable, TRUE, NrOfFiles);

		IF ArchiveOn IN ParamStatus THEN					(* Nur Datei mit Archive	*)
		BEGIN
			NrFiles := NrOfFiles;  							(* Obergrenze nicht Ñndern	*)

			FOR i := 1 TO NrFiles DO 						(* Dateien mit Archive weg	*)
			BEGIN
				Pop(FileTable, POINTER(Item));			(* Dateiname aus Liste		*)

				WITH Item^ DO
				BEGIN
					IF (FileItem.Attr AND (Directory OR Archive)) <> 0 THEN
					BEGIN
						Push(FileTable, Item);

						IF (FileItem.Attr AND Archive) <> 0 THEN
						BEGIN
							IF (Dir[Length(Dir)] <> ':') AND
								(Dir[Length(Dir)] <> '\') THEN
								Source := Dir + '\' + FileItem.Name
							ELSE Source := Dir + FileItem.Name;

							Assign(SrcFile, Source);
							SetFAttr(SrcFile, FileItem.Attr AND NOT Archive);
						END;
					END
					ELSE
					BEGIN
						Dec(NrOfFiles);						(* Ein Eintrag weniger		*)
						Dispose(Item);		  	 				(* Speicher freigeben		*)
					END;
				END;
			END;
		END;

		NrFiles := NrOfFiles;  								(* Obergrenze nicht Ñndern	*)

		FOR i := 1 TO NrFiles DO 							(* '.' und '..' lîschen		*)
		BEGIN
			Pop(FileTable, POINTER(Item));				(* Dateiname aus Liste		*)

			IF (Item^.FileItem.Attr AND (Hidden OR SysFile) = 0) THEN
			BEGIN       										(* Keine Dir, Hidden, Sys	*)
				IF EmptyDirOn IN ParamStatus THEN		(* Leere Verzeichnisse an	*)
				BEGIN
					IF ((i < 3) AND (Item^.FileItem.Name = '..')) OR
						(Item^.FileItem.Name = '.') THEN	(* '.' immer entfernen		*)
					BEGIN
						Dec(NrOfFiles);		  			  	(* Ein Eintrag weniger		*)
						Dispose(Item);			  			  	(* Speicher freigeben		*)
					END
					ELSE IF Item^.FileItem.Name <> '..' THEN
						Push(FileTable, Item) 	  			(* Dateiname in Liste 		*)
					ELSE   							  			(* '..' wurde gefunden		*)
					BEGIN
						IF i = NrFiles THEN		  			(* '..' leeres Verzeichnis	*)
							Push(FileTable, Item)  			(* Dateiname in Liste 		*)
						ELSE							  			(* Nicht letzte Datei		*)
						BEGIN
							NextItem := pNameRec(FileTable^.Next^.Content);

							IF Pos(Item^.Dir, NextItem^.Dir) <> 1 THEN
								Push(FileTable, Item)		(* Verzeichnis ist leer		*)
							ELSE
							BEGIN
								Dec(NrOfFiles);  				(* Ein Eintrag weniger		*)
								Dispose(Item);	  				(* Speicher freigeben		*)
							END;
						END;
					END;
				END
				ELSE												(* Leere Verzeichnisse aus	*)
				BEGIN
					IF (Item^.FileItem.Name <> '.') AND	(* Kein '.' oder '..'		*)
						(Item^.FileItem.Name <> '..') THEN
						Push(FileTable, Item) 				(* Dateiname in Liste 		*)
					ELSE 							  				(* '.' oder '..' gefunden 	*)
					BEGIN
						Dec(NrOfFiles);		  				(* Ein Eintrag weniger		*)
						Dispose(Item);			  				(* Speicher freigeben		*)
					END;
				END;
			END
			ELSE
			BEGIN
				Dec(NrOfFiles);								(* Ein Eintrag weniger		*)
				Dispose(Item);		  			 				(* Speicher freigeben		*)
			END;
		END;
	END
	ELSE															(* Ohne Unterverzeichnisse	*)
	BEGIN
		LookForFiles := GetFiles(SourceName, FileTable, FALSE, NrOfFiles);
		NrFiles := NrOfFiles;  								(* Obergrenze nicht Ñndern	*)

		FOR i := 1 TO NrFiles DO 							(* Verzeichnisse lîschen	*)
		BEGIN
			Pop(FileTable, POINTER(Item));				(* Dateiname aus Liste		*)

			IF ArchiveOn IN ParamStatus THEN				(* Nur Datei mit Archive	*)
			BEGIN
				IF (Item^.FileItem.Attr AND            (* Keine Dir, Hidden, Sys	*)
					(Hidden OR SysFile OR Directory) = 0) AND
					((Item^.FileItem.Attr AND Archive) <> 0) THEN
				BEGIN
					Push(FileTable, Item);

					WITH Item^ DO  							(* Bei Quelle Archive weg	*)
					BEGIN
						IF (Dir[Length(Dir)] <> ':') AND
							(Dir[Length(Dir)] <> '\') THEN
							Source := Dir + '\' + FileItem.Name
						ELSE Source := Dir + FileItem.Name;

						Assign(SrcFile, Source);
						SetFAttr(SrcFile, FileItem.Attr AND NOT Archive);
					END;
				END
				ELSE
				BEGIN
					Dec(NrOfFiles);							(* Ein Eintrag weniger		*)
					Dispose(Item);		  		 				(* Speicher freigeben		*)
				END;
			END
			ELSE													(* Alle Dateien kopieren	*)
			BEGIN
				IF (Item^.FileItem.Attr AND            (* Keine Dir, Hidden, Sys	*)
					(Hidden OR SysFile OR Directory) = 0) THEN
					Push(FileTable, Item) 					
				ELSE
				BEGIN
					Dec(NrOfFiles);							(* Ein Eintrag weniger		*)
					Dispose(Item);		  		 				(* Speicher freigeben		*)
				END;
			END;
		END;
	END;
END; (* LookForFiles *)

(* Diese Prozedur legt eine neue Zieldatei oder ein neues Zielverzeichnis an *)
PROCEDURE MakeNew(VAR ProceedCopy, CopyToAFile : BOOLEAN;
						VAR TargetFile : FILE);
VAR Answer 	  : CHAR;										(* Nimmt Antwort auf			*)
	 Direc     : DirStr;	  									(* EnthÑlt Verzechnistext	*)
	 FileName  : NameStr;									(* EnthÑlt Dateinamen		*)
	 Extension : ExtStr;	  									(* Erweiterung von Namen 	*)
	 Drive     : DriveStr;									(* Text eines Laufwerks		*)
BEGIN
	Write('Does Target Specify A File Or A Directory (F,D,Quit) ? ');
	ReadLn(Answer);											(* Auf Antwort warten		*)

	IF UpCase(Answer) = 'F' THEN	 			  			(* Neue Datei anlegen		*)
	BEGIN
		CopyToAFile := TRUE;
		FSplit(TargetName, Direc, FileName, Extension);
		CutBackslash(Direc);	 			  					(* öberflÅssiges '\' weg	*)

		IF GetFileType(Direc) = NoFile THEN    		(* Verzeichnisse anlegen	*)
		BEGIN
			DriveSplit(Direc, Drive, Direc);

			IF NOT MakeTree(Drive, Direc) THEN
			BEGIN 												(* Fehler beim Anlegen		*)
				WriteLn('Cannot Create Target Directory - ' + Drive + Direc);
				ProceedCopy := FALSE;
			END;
		END;

		IF ProceedCopy THEN	  	 			  	 			(* Keine Fehler vorhanden	*)
		BEGIN
			Assign(TargetFile, TargetName);
			ReWrite(TargetFile, 1);			 			  	(* Zieldatei îffnen			*)

			IF IOResult <> 0 THEN							(* Fehler aufgetreten		*)
			BEGIN
				WriteLn('Cannot Create Target File - ' + TargetName);
				ProceedCopy := FALSE;
			END
			ELSE WriteLn;
		END;
	END
	ELSE IF UpCase(Answer) = 'D' THEN 			  		(* Verzeichnis anlegen	  	*)
	BEGIN
		CopyToAFile := FALSE;
		DriveSplit(TargetName, Drive, Direc);

		IF NOT MakeTree(Drive, Direc) THEN 				(* Fehler beim Anlegen		*)
		BEGIN
			WriteLn('Cannot Create Target Directory - ' + Drive + Direc);
			ProceedCopy := FALSE;
		END
		ELSE WriteLn;
	END
	ELSE       					                      	(* Kopiervorgang abbrechen	*)
	BEGIN
		WriteLn('FCP Aborted, ', CopiedFiles, ' File(s) Copied');
		ProceedCopy := FALSE;
	END;
END; (* MakeNew *)

(* Diese Prozedur prÅft, ob eine existierende Datei Åberschrieben werden soll *)
PROCEDURE FileExists(VAR ProceedCopy, CopyToAFile : BOOLEAN;
							VAR TargetFile : FILE);
VAR Answer : CHAR;  											(* Nimmt Antwort auf			*)
BEGIN
	Write('Do You Want To Overwrite Existing File (Y,N) ? ');
	ReadLn(Answer);											(* Auf Antwort warten		*)

	IF UpCase(Answer) = 'Y' THEN							(* Datei Åberschreiben		*)
	BEGIN
		Assign(TargetFile, TargetName);
		Erase(TargetFile);									(* Zieldatei lîschen			*)

		IF IOResult <> 0 THEN								(* Fehler aufgetreten		*)
		BEGIN
			WriteLn('Cannot Delete Target File - ' + TargetName);
			ProceedCopy := FALSE;
		END
		ELSE MakeNew(ProceedCopy, CopyToAFile, TargetFile);
	END
	ELSE   														(* Kopieren abbrechen		*)
	BEGIN
		WriteLn('FCP Aborted, ', CopiedFiles, ' File(s) Copied');
		ProceedCopy := FALSE;
	END;
END; (* FileExists *)

(* Diese Funktion prÅft, ob genug Speicherplatz auf dem Ziellaufwerk ist *)
FUNCTION EnoughDiskSpace(FileTable : pRing; NrOfFiles : WORD) : BOOLEAN;
VAR Answer 	 	: CHAR;	 									(* Nimmt Antwort auf			*)
	 Direc  	 	: DirStr;	  								(* EnthÑlt Verzechnistext	*)
	 Drive  	 	: DriveStr;	  								(* Text eines Laufwerks		*)
	 FileSize,					  		 						(* Grî·er aller Dateien		*)
	 TargetFree : LONGINT;								  	(* Freier Platz auf Ziel	*)
BEGIN
	EnoughDiskSpace := TRUE;								(* Vorgabewert					*)
	DriveSplit(TargetName, Drive, Direc);				(* Laufwerksname abtrennen	*)
	FileSize := GetFileSize(FileTable, NrOfFiles);	(* Grî·e aller Dateien		*)
	TargetFree := DiskFree(Ord(Drive[1]) - Ord('A') + 1);

	IF NrOfFiles = 1 THEN WriteLn('Copying 1 File Or Directory')
	ELSE WriteLn('Copying ', NrOfFiles, ' Files Or Directories');

	Write('Copying ', FileSize, ' Bytes On Source To ');
	WriteLn(TargetFree, ' Free Bytes On Target');

	IF (TargetFree < FileSize) AND (CheckTarget IN ParamStatus) THEN
	BEGIN                            					(* Kein Speicher auf Ziel	*)
		EnoughDiskSpace := FALSE;
		WriteLn;
		WriteLn('Not Enough Free Memory On Target');
	END
	ELSE IF NOT (CopyQuiet IN ParamStatus) THEN 		(* Genug Zielspeicher da	*)
	BEGIN
		WriteLn;
		Write('Do You Want To Start Copying (Y,N) ? ');
		ReadLn(Answer);  		 								(* Auf Antwort warten		*)

		IF UpCase(Answer) <> 'Y' THEN		  				(* Kopiervorgang abbrechen	*)
		BEGIN
			WriteLn('FCP Aborted, ', CopiedFiles, ' File(s) Copied');
			EnoughDiskSpace := FALSE;
		END
		ELSE WriteLn;
	END
	ELSE WriteLn;
END; (* EnoughDiskSpace  *)

(* Diese Funktion konstruiert den Quell- und den Zielpfad fÅr eine Datei *)
FUNCTION MakePath(FileNr : WORD; Item : pNameRec; FileTable : pRing;
						CopyToAFile : BOOLEAN; VAR CopySource,
						CopyTarget : PathStr) : BOOLEAN;
VAR i	   		: BYTE; 										(* Dient nur als ZÑhler		*)
	 TextString	: PathStr;									(* Allgemeiner Text			*)
BEGIN
	MakePath := TRUE;											(* Vorgabewert					*)

	WITH Item^ DO
	BEGIN
		IF (Dir[Length(Dir)] <> ':') AND	(Dir[Length(Dir)] <> '\') THEN
			CopySource := Dir + '\' + FileItem.Name
		ELSE CopySource := Dir + FileItem.Name;

		IF Pos(',', SourceName) = 0 THEN					(* Keine Liste von Namen	*)
		BEGIN
			i := 0;						  						(* Erster Buchstabe - 1		*)

			REPEAT  												(* Strings vergleichen		*)
				Inc(i);
			UNTIL (Dir[i] <> SourceName[i]) OR (i = Length(SourceName));

			TextString := Dir;		 						(* öberflÅssige Dir weg		*)

			IF i = Length(SourceName) THEN				(* Komplett durchlaufen		*)
				Delete(TextString, 1, i)				  	(* Verzeichnisanfang weg	*)
			ELSE
				Delete(TextString, 1, i - 1);			  	(* Verzeichnisanfang weg	*)

			IF TextString <> '' THEN
			BEGIN
				IF TextString[1] = '\' THEN				(* SourceName hat mehr		*)
					Delete(TextString, 1, 1);				(* Verzeichnisse als Dir	*)
			END;

			IF (TargetName[Length(TargetName)] <> ':') AND
				(TargetName[Length(TargetName)] <> '\') THEN
				CopyTarget := TargetName + '\' + TextString
			ELSE CopyTarget := TargetName + TextString;

			IF Length(TextString) > 0 THEN CopyTarget := CopyTarget + '\';
			CopyTarget := CopyTarget + FileItem.Name;
		END
		ELSE														(* Quelle ist Namensliste	*)
		BEGIN
			IF (TargetName[Length(TargetName)] <> ':') AND
				(TargetName[Length(TargetName)] <> '\') THEN
				CopyTarget := TargetName + '\' + FileItem.Name
			ELSE CopyTarget := TargetName + FileItem.Name;
		END;

		IF CopyToAFile THEN
			CopyTarget := TargetName;						(* Alles in Datei kopieren	*)

		IF CopySource = CopyTarget THEN
		BEGIN		 							  					(* Ziel und Quelle gleich	*)
			IF FileNr > 1 THEN WriteLn;
			WriteLn('File Cannot Be Copied Onto Itself - ', CopySource);
			WriteLn('FCP Aborted, ', CopiedFiles, ' File(s) Copied');
			MakePath := FALSE;
		END;
	END;
END; (* MakePath *)

(* Diese Funktion kopiert eine Datei *)
FUNCTION CopyOneFile(CopyToAFile : BOOLEAN; CopySource, CopyTarget : PathStr)
							: BOOLEAN;
VAR Direc      : DirStr;	  	  							(* EnthÑlt Verzechnistext	*)
	 FileName   : NameStr;									(* EnthÑlt Dateinamen		*)
	 Extension  : ExtStr;	  	  							(* Erweiterung von Namen 	*)
	 Drive      : DriveStr;									(* Text eines Laufwerks		*)
	 MakeTreeOk	: BOOLEAN;								  	(* Verzeichnisbaum ist Ok	*)
BEGIN
	CopyOneFile := TRUE;										(* Vorgabewert					*)

	IF CopyToAFile THEN										(* Alles in Datei kopieren	*)
	BEGIN
		CASE CopyToFile(CopySource, TargetFile, BufferSize) OF
			0 : 													(* Datei wurde kopiert		*)
			BEGIN
				Inc(CopiedFiles);								(* Eine Datei mehr kopiert	*)
				GotoXY(72, WhereY); 							(* Cursor rechter Rand		*)
				WriteLn(' Copied ');
			END;

			8 : 													(* Diskette ist voll			*)
			BEGIN
				WriteLn;	WriteLn;
				WriteLn('Insufficient Disk Space - ', CopySource);
				WriteLn('FCP Aborted, ', CopiedFiles, ' File(s) Copied');
				CopyOneFile := FALSE;
			END;

		ELSE														(* Fehler ist aufgetreten	*)
			WriteLn;	WriteLn;
			WriteLn('Error While Copying - ', CopySource);
			WriteLn('FCP Aborted, ', CopiedFiles, ' File(s) Copied');
			CopyOneFile := FALSE;
		END;
	END
	ELSE   														(* Normaler Kopiervorgang	*)
	BEGIN
		MakeTreeOk := TRUE;									(* Vorgabewert					*)
		FSplit(CopyTarget, Direc, FileName, Extension);
		CutBackslash(Direc);	  					 			(* öberflÅssiges '\' weg	*)

		IF GetFileType(Direc) = NoFile THEN       	(* Verzeichnisse anlegen	*)
		BEGIN
			DriveSplit(Direc, Drive, Direc);

			IF NOT MakeTree(Drive, Direc) THEN			(* Fehler beim Anlegen		*)
			BEGIN
				WriteLn;	WriteLn;
				WriteLn('Cannot Create Target Directory - ' + Drive + Direc);
				WriteLn('FCP Aborted, ', CopiedFiles, ' File(s) Copied');
				CopyOneFile := FALSE;
				MakeTreeOk := FALSE;							(* Verzeichnisbaum Fehler	*)
			END;
		END;

		IF MakeTreeOk THEN									(* Bis jetzt alles Ok		*)
		BEGIN
			CASE CopyFile(CopySource, CopyTarget, BufferSize) OF
				0 : 		  										(* Datei wurde kopiert		*)
				BEGIN
					Inc(CopiedFiles);	  						(* Eine Datei mehr kopiert	*)
					GotoXY(72, WhereY); 	  					(* Cursor rechter Rand		*)
					WriteLn(' Copied ');
				END;

				8 : 												(* Diskette ist voll			*)
				BEGIN
					WriteLn;	WriteLn;
					WriteLn('Insufficient Disk Space - ', CopySource);
					WriteLn('FCP Aborted, ', CopiedFiles, ' File(s) Copied');

					IF GetFileType(CopyTarget) <> NoFile THEN
					BEGIN
						Assign(TargetFile, CopyTarget);
						Erase(TargetFile);
					END;

					CopyOneFile := FALSE;
				END;

				150 :	  								 			(* Schreibschutz ist an		*)
				BEGIN
					WriteLn;	WriteLn;
					WriteLn('Write Protect Error - ', CopySource);
					WriteLn('FCP Aborted, ', CopiedFiles, ' File(s) Copied');

					CopyOneFile := FALSE;
				END;

			ELSE 								   				(* Fehler ist aufgetreten	*)
				WriteLn;	WriteLn;
				WriteLn('Error While Copying - ', CopySource);
				WriteLn('FCP Aborted, ', CopiedFiles, ' File(s) Copied');

				IF GetFileType(CopyTarget) <> NoFile THEN
				BEGIN
					Assign(TargetFile, CopyTarget);
					Erase(TargetFile);
				END;

				CopyOneFile := FALSE;
			END;
		END;
	END;
END; (* CopyOneFile *)

(* Diese Funktion kopiert eine Datei interaktiv *)
FUNCTION InteractiveCopy(Item : pNameRec; CopyToAFile : BOOLEAN; CopySource,
								 CopyTarget : PathStr) : BOOLEAN;
VAR Direc  : DirStr;	  	  									(* EnthÑlt Verzechnistext	*)
	 Drive  : DriveStr;	 		  							(* Text eines Laufwerks		*)
	 Answer : CHAR;	 	 		  							(* Nimmt Antwort auf			*)
BEGIN
	InteractiveCopy := TRUE;								(* Vorgabewert					*)
	DriveSplit(CopyTarget, Drive, Direc);				(* Laufwerk abspalten		*)

	WriteLn;
	Write('Disk Free : ', DiskFree(Ord(Drive[1]) - Ord('A') + 1));
	Write('   File Size : ', Item^.FileItem.Size, '   Copy (Y,N,Quit) ? ');
	ReadLn(Answer);											(* Antwort abwarten			*)
	GotoXY(72, WhereY - 1);									(* Cursor hinter Antwort	*)

	IF UpCase(Answer) = 'Q' THEN							(* Kopieren abbrechen		*)
	BEGIN
		WriteLn;
		WriteLn('FCP Aborted, ', CopiedFiles, ' File(s) Copied');
		InteractiveCopy := FALSE;
	END
	ELSE IF UpCase(Answer) = 'Y' THEN					(* Datei wird kopiert		*)
		InteractiveCopy := CopyOneFile(CopyToAFile, CopySource, CopyTarget)
	ELSE
	BEGIN
		GotoXY(68, WhereY);		  							(* Cursor hinter Antwort	*)
		WriteLn(' Not Copied ');
	END;
END; (* InteractiveCopy *)

(* Diese Funktion legt ein leeres Verzeichnis an *)
FUNCTION MakeEmptyTree(CopyTarget : PathStr) : BOOLEAN;
VAR Direc : DirStr;	  	  									(* EnthÑlt Verzechnistext	*)
	 Drive : DriveStr;	 		  							(* Text eines Laufwerks		*)
BEGIN
	MakeEmptyTree := TRUE;									(* Vorgabewert					*)
	Dec(CopyTarget[0], 3);									(* Entferne Zeichen '\..'	*)

	IF GetFileType(CopyTarget) = NoFile THEN			(* Verzeichnisse anlegen	*)
	BEGIN
		DriveSplit(CopyTarget, Drive, Direc);			(* Laufwerk abtrennen		*)

		IF NOT MakeTree(Drive, Direc) THEN				(* Fehler beim Anlegen		*)
		BEGIN
			WriteLn; WriteLn;
			WriteLn('Cannot Create Target Directory - ' + Drive + Direc);
			WriteLn('FCP Aborted, ', CopiedFiles, ' File(s) Copied');
			MakeEmptyTree := FALSE;
		END
		ELSE
		BEGIN
			GotoXY(71, WhereY);								(* Cursor rechter Rand		*)
			WriteLn(' Created ');  							(* Verzeichnis erzeugt		*)
		END;
	END
	ELSE
	BEGIN                               				(* Ist schon vorhanden		*)
		GotoXY(64, WhereY);									(* Cursor rechter Rand		*)
		WriteLn(' Already Exists ');
	END;
END; (* MakeEmptyTree *)

(* Diese Funktion legt interaktiv ein leeres Verzeichnis an *)
FUNCTION InteractiveEmptyTree(CopyTarget : PathStr) : BOOLEAN;
VAR Direc  : DirStr;	  	  									(* EnthÑlt Verzechnistext	*)
	 Drive  : DriveStr;	 		  							(* Text eines Laufwerks		*)
	 Answer : CHAR;	 	 		  							(* Nimmt Antwort auf			*)
BEGIN
	InteractiveEmptyTree := TRUE;							(* Vorgabewert					*)
	DriveSplit(CopyTarget, Drive, Direc);				(* Laufwerk abspalten		*)

	WriteLn;
	Write('Disk Free : ', DiskFree(Ord(Drive[1]) - Ord('A') + 1));
	Write('   Create (Y,N,Quit) ? ');
	ReadLn(Answer);											(* Antwort abwarten			*)
	GotoXY(68, WhereY - 1);									(* Cursor hinter Antwort	*)

	IF UpCase(Answer) = 'Q' THEN							(* Kopieren abbrechen		*)
	BEGIN
		WriteLn;
		WriteLn('FCP Aborted, ', CopiedFiles, ' File(s) Copied');

		InteractiveEmptyTree := FALSE;
	END
	ELSE IF UpCase(Answer) = 'Y' THEN					(* Verzeichnis angelegen	*)
		InteractiveEmptyTree := MakeEmptyTree(CopyTarget)
	ELSE
	BEGIN
		GotoXY(67, WhereY);	  		 						(* Cursor rechter Rand		*)
		WriteLn(' Not Created ');
	END;
END; (* InteractiveEmptyTree *)

(* Diese Funktion prÅft, ob eine Unterbrechung durch ESC vorgenommen wurde *)
FUNCTION CheckEsc(CopyToAFile : BOOLEAN) : BOOLEAN;
VAR Answer : CHAR;		 									(* Nimmt Antwort auf			*)
BEGIN
	CheckEsc := FALSE;										(* Vorgabewert					*)

	IF KeyPressed THEN  							 			(* Taste wurde gedrÅckt		*)
	BEGIN
		Answer := ReadKey;									(* Tastencode einlesen		*)

		IF Answer = Chr(0) THEN	Answer := ReadKey		(* Taste liefert ScanCode	*)
		ELSE IF Answer = Chr(27) THEN    				(* ESC Taste gedrÅckt		*)
		BEGIN
			WriteLn;
			Write('Do You Want To Abort FCP (Y,N) ? ');
			ReadLn(Answer);									(* Auf Anwort warten			*)

			IF UpCase(Answer) = 'Y' THEN   				(* Kopieren abbrechen		*)
			BEGIN
				WriteLn('FCP Aborted, ', CopiedFiles, ' File(s) Copied');
				CheckEsc := TRUE;
			END;
		END;
	END;
END; (* CheckEsc *)

BEGIN (* FCP *)
	Initialize;													(* Initialisierungen			*)
	ParamCheck;													(* Parameter ÅberprÅfen		*)
	CreateRing(FileTable);									(* Tabelle aller Dateien	*)

	IF Pos(',', SourceName) = 0 THEN
		SourceName := FExpand(SourceName);	  			(* Quelle voller Pfadname 	*)

	TargetName := FExpand(TargetName);  				(* Ziel voller Pfadname 	*)
	CutBackslash(SourceName);								(* öberflÅssiges '\' weg	*)
	CutBackslash(TargetName);								(* öberflÅssiges '\' weg	*)
	FilesOk := LookForFiles(FileTable, NrOfFiles);	(* Namen der Quelldateien	*)

	IF NOT FilesOk THEN										(* Zu viele DateieintrÑge	*)
		WriteLn('Too Many Files - ' + SourceName)
	ELSE IF NrOfFiles = 0 THEN			 					(* Keine Dateien vorhanden	*)
		WriteLn('Nothing To Copy - ' + SourceName)
	ELSE IF GetFileType(TargetName) = MultFiles THEN
		WriteLn('Illegal Target File - ' + TargetName)
	ELSE 			 			  									(* Bis jetzt keine Fehler 	*)
	BEGIN
		TypeOfFile := GetFileType(TargetName);			(* Typ der Zieldatei			*)
		ProceedCopy := TRUE;						  			(* Kopieren fortsetzen		*)

		IF TypeOfFile = NoFile THEN	 				  	(* Neue Datei, Verzeichnis	*)
			MakeNew(ProceedCopy, CopyToAFile, TargetFile)
		ELSE IF TypeOfFile <> DirFile THEN				(* Zieldatei existiert 		*)
			FileExists(ProceedCopy, CopyToAFile, TargetFile)
		ELSE CopyToAFile := FALSE;	 			  			(* In Verzeichnis kopieren	*)

		IF ProceedCopy THEN 			 						(* Kopieren fortsetzen		*)
			ProceedCopy := EnoughDiskSpace(FileTable, NrOfFiles);

		IF ProceedCopy THEN	  				 				(* Kopieren fortsetzen		*)
		BEGIN
			i := 1;											 	(* Erste Datei zu kopieren	*)

			WHILE ProceedCopy AND (i <= NrOfFiles) DO (* Alle Dateien durchgehen	*)
			BEGIN
				Pop(FileTable, POINTER(Item));			(* NÑchste Datei aus Liste	*)

				ProceedCopy := MakePath(i, Item, FileTable, CopyToAFile, CopySource,
												CopyTarget);	(* Quell-, Zielpfad Text	*)

				IF ProceedCopy THEN							(* Kopieren fortsetzen		*)
				BEGIN
					IF (InterOn IN ParamStatus) AND (i > 1) THEN WriteLn;

					IF Item^.FileItem.Name = '..' THEN	(* Verzeichnis erzeugen		*)
					BEGIN
						IF NOT CopyToAFile THEN				(* Nicht in Datei kopiert	*)
						BEGIN
							Dec(CopyTarget[0], 3);			(* Zeichen '\..' sind weg	*)
							Write(i : 4, '> ', CopyTarget);
							Inc(CopyTarget[0], 3);			(* Zeichen '\..' wieder da	*)

							IF InterOn IN ParamStatus THEN(* Interaktiv erzeugen		*)
								ProceedCopy := InteractiveEmptyTree(CopyTarget)
							ELSE ProceedCopy := MakeEmptyTree(CopyTarget);
						END
						ELSE WriteLn('Cannot Create Target Directory');
					END
					ELSE											(* Normale Datei kopieren	*)
					BEGIN
						Write(i : 4, '> ', CopySource, ' ', Chr(26), ' ', CopyTarget);

						IF InterOn IN ParamStatus THEN  	(* Interaktiv kopieren		*)
							ProceedCopy :=
							InteractiveCopy(Item, CopyToAFile, CopySource, CopyTarget)
						ELSE ProceedCopy :=					(* Ohne RÅckfrage kopieren	*)
							CopyOneFile(CopyToAFile, CopySource, CopyTarget);
					END;
				END;

				Dispose(Item);	  								(* Speicher freigeben		*)
				Inc(i);			  								(* NÑchste Datei				*)

				IF ProceedCopy THEN 							(* Unterbrechung durch ESC	*)
					ProceedCopy := NOT CheckEsc(CopyToAFile);
			END;
		END;
	END;

	WHILE NOT RingIsEmpty(FileTable) DO 				(* Alle EintrÑge lîschen	*)
	BEGIN
		Pop(FileTable, POINTER(Item));					(* Dateiname aus Liste		*)
		Dispose(Item);											(* Speicher freigeben		*)
	END;

	DeleteRing(FileTable);									(* Listenkopf lîschen		*)

	IF FilesOk AND CopyToAFile THEN						(* Daten in Datei kopiert	*)
	BEGIN
		Close(TargetFile);									(* Zieldatei schlie·en		*)

		IF NOT ProceedCopy THEN								(* Bei Fehler lîschen		*)
		BEGIN
			WriteLn('Nothing Copied, Target File Removed');
			Erase(TargetFile);
		END
		ELSE IF CopiedFiles = 0 THEN						(* Keine Dateien kopiert	*)
			Erase(TargetFile);
	END;

	IF FilesOk AND ProceedCopy THEN						(* Kopiervorgang war Ok		*)
	BEGIN
		WriteLn;
		WriteLn(CopiedFiles, ' File(s) Copied');		(* Anzahl kopierter Files	*)
	END;
END; (* DoFileCopy *)

BEGIN               											(* Hauptprogramm				*)
	CheckBreak := FALSE;										(* Kein Ctrl + C zulassen	*)
	DoFileCopy;													(* Kopiervorgang starten	*)
END. (* FCP *)
