(**************************************************************)
(* Programmname    : TOOLCOPY.PAS V2.1                        *)
(* Programmautor   : Michael Rippl             		           *)
(* Compiler        : Quick Pascal V1.0    	                 *)
(* Inhalt          : Dateikopierprogramm fÅr Venus-Shell V2.1 *)
(* Bemerkung       : Dient als Include-Datei fÅr ToolMenu.Pas *)
(* Letzte énderung : 22-Jul-1991                              *)
(**************************************************************)

(* Diese Prozedur stellt ein komplettes Dateikopierprogramm dar *)
PROCEDURE DoCopy;
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
	 FilesOk,													(* Zu viele DateieintrÑge	*)
	 ProceedCopy,												(* Kopieren fortsetzen		*)
	 CopyToAFile : BOOLEAN;		  							(* Daten in Datei kopieren	*)
	 TypeOfFile  : FileType;								(* Typ einer Datei			*)
	 Item  		 : pNameRec;  	  							(* Dateieintrag in Tabelle	*)
	 TextStr		 : STRING[5];								(* Zahl in Text umwandeln	*)
	 TargetFile  : FILE;			  							(* Typenlose Zieldatei		*)

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

(* Diese Funktion ÅberprÅft die Åbergebenen Parameter *)
FUNCTION ParamCheck : BOOLEAN;
VAR i 			: BYTE;	 									(* Dient nur als ZÑhler		*)
	 TextString	: PathStr;									(* Allgemeiner Text			*)

(* Diese Prozedur gibt eine Nachricht aus und beendet dann das Programm *)
PROCEDURE Quit(ErrorCode : BYTE);
BEGIN
	CASE ErrorCode OF											(* Fehler unterscheiden		*)
		1 :
		BEGIN
			WriteString('Usage : Copy [/i] [/s] [/e] [/q] [/c]', cWhite, cBlue);
			WriteString(' [/m] ', cWhite, cBlue);
			WriteString('<source>[[,<source>],..] [<target>]', cWhite, cBlue);
		END;

		2 : WriteLnString('Illegal Option - ' + TextString, cWhite, cBlue);
		3 : WriteLnString('Too Much Parameters - ' + TextString, cWhite, cBlue);
		4 : WriteLnString('Missing Source File', cWhite, cBlue);

		5 : WriteLnString('Cannot Copy Multiple Hierarchies - ' +
								SourceName, cWhite, cBlue);
	END;

	WriteLnString('', cWhite, cBlue);
END; (* Quit *)

BEGIN (* ParamCheck *)
	IF (ParamCount < 1) OR (ParamCount > 7) THEN		(* Parameteranzahl falsch	*)
	BEGIN
		Quit(1);   											 	(* Information ausgeben		*)
		ParamCheck := FALSE;									(* Fehler in Parametern		*)
		Exit;														(* Prozedur vorzeitig Ende	*)
	END;

	i := 1;														(* ZÑhler auf Anfang			*)

	WHILE (i <= ParamCount) AND 							(* Alle Parameter beachten	*)
		([IllegalOpt, TooMuchPars] * ParamStatus = [ ]) DO
	BEGIN
		TextString := ParamStr(i);							(* i-ten Parameter merken	*)

		IF TextString[1] = '/' THEN						(* Option gefunden			*)
		BEGIN
			IF TextString = '/S' THEN 						(* Unterverzeichnisse an	*)
				ParamStatus := ParamStatus + [SubDirOn]
			ELSE IF TextString = '/I' THEN				(* Interaktiv kopieren		*)
				ParamStatus := ParamStatus + [InterOn]
			ELSE IF TextString = '/E' THEN				(* Leere Verzeichnisse an	*)
				ParamStatus := ParamStatus + [EmptyDirOn]
			ELSE IF TextString = '/Q' THEN				(* Keine Abfrage zu Beginn	*)
				ParamStatus := ParamStatus + [CopyQuiet]
			ELSE IF TextString = '/C' THEN				(* Zielspeicher prÅfen		*)
				ParamStatus := ParamStatus + [CheckTarget]
			ELSE IF TextString = '/M' THEN				(* Nur Daten mit Archive	*)
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

	IF IllegalOpt IN ParamStatus THEN  					(* UnzulÑssige Optionen		*)
	BEGIN
		Quit(2);													(* Fehlermeldung ausgeben	*)
		ParamCheck := FALSE;									(* Fehler in Parametern		*)
		Exit;														(* Prozedur vorzeitig Ende	*)
	END
	ELSE IF TooMuchPars IN ParamStatus THEN			(* Zu viele Parameter		*)
	BEGIN
		Quit(3);	 												(* Fehlermeldung ausgeben	*)
		ParamCheck := FALSE;									(* Fehler in Parametern		*)
		Exit;														(* Prozedur vorzeitig Ende	*)
	END
	ELSE IF Length(SourceName) = 0 THEN					(* Quelldatei fehlt			*)
	BEGIN
		Quit(4);  												(* Fehlermeldung ausgeben	*)
		ParamCheck := FALSE;									(* Fehler in Parametern		*)
		Exit;														(* Prozedur vorzeitig Ende	*)
	END
	ELSE IF Length(TargetName) = 0 THEN					(* Zieldatei fehlt			*)
		GetDir(0, TargetName)	  		 					(* Ziel ist aktuelle Dir	*)
	ELSE IF (Pos(',', SourceName) <> 0) AND
		([SubDirOn, EmptyDirOn] * ParamStatus <> [ ]) THEN
	BEGIN
		Quit(5);  												(* Fehlermeldung ausgeben	*)
		ParamCheck := FALSE;									(* Fehler in Parametern		*)
		Exit;														(* Prozedur vorzeitig Ende	*)
	END;

	ParamCheck := TRUE;										(* Parameter sind alle Ok	*)
END; (* ParamCheck *)

(* Diese Prozedur holt die durch eine Maske spezifizierten Dateien *)
FUNCTION LookForFiles(FileTable : pRing; VAR NrOfFiles : WORD) : BOOLEAN;
VAR i, 		 				  									(* Dient nur als ZÑhler		*)
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
			BEGIN       										(* Kein Hidden, System		*)
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
VAR Answer 	  : STRING[4];									(* Nimmt Antwort auf			*)
	 Direc     : DirStr;	  									(* EnthÑlt Verzeichnistext	*)
	 FileName  : NameStr;									(* EnthÑlt Dateinamen		*)
	 Extension : ExtStr;	  									(* Erweiterung von Namen 	*)
	 Drive     : DriveStr;									(* Text eines Laufwerks		*)
	 FilesStr  : STRING[5];									(* Anzahl Dateien als Text	*)
BEGIN
	WriteString('Does Target Specify A File Or A Directory (F,D,Quit) ? ',
					cWhite, cBlue);

	ReadLnString(Answer, cWhite, cBlue);				(* Auf Antwort warten		*)

	IF UpCase(Answer[1]) = 'F' THEN	 		  			(* Neue Datei anlegen		*)
	BEGIN
		CopyToAFile := TRUE;
		FSplit(TargetName, Direc, FileName, Extension);
		CutBackslash(Direc);	 			  					(* öberflÅssiges '\' weg	*)

		IF GetFileType(Direc) = NoFile THEN    		(* Verzeichnisse anlegen	*)
		BEGIN
			DriveSplit(Direc, Drive, Direc);

			IF NOT MakeTree(Drive, Direc) THEN
			BEGIN 												(* Fehler beim Anlegen		*)
				WriteLnString('Cannot Create Target Directory - ' + Drive + Direc,
								  cWhite, cBlue);

				ProceedCopy := FALSE;
			END;
		END;

		IF ProceedCopy THEN	  	 			  	 			(* Keine Fehler vorhanden	*)
		BEGIN
			Assign(TargetFile, TargetName);
			ReWrite(TargetFile, 1);			 			  	(* Zieldatei îffnen			*)

			IF IOResult <> 0 THEN							(* Fehler aufgetreten		*)
			BEGIN
				WriteLnString('Cannot Create Target File - ' + TargetName,
								  cWhite, cBlue);

				ProceedCopy := FALSE;
			END
			ELSE WriteLnString('', cWhite, cBlue);
		END;
	END
	ELSE IF UpCase(Answer[1]) = 'D' THEN  		  		(* Verzeichnis anlegen	  	*)
	BEGIN
		CopyToAFile := FALSE;
		DriveSplit(TargetName, Drive, Direc);

		IF NOT MakeTree(Drive, Direc) THEN 				(* Fehler beim Anlegen		*)
		BEGIN
			WriteLnString('Cannot Create Target Directory - ' + Drive + Direc,
							  cWhite, cBlue);

			ProceedCopy := FALSE;
		END
		ELSE WriteLnString('', cWhite, cBlue);
	END
	ELSE       					                      	(* Kopiervorgang abbrechen	*)
	BEGIN
		Str(CopiedFiles, FilesStr);						(* Anzahl Dateien als Text	*)

		WriteLnString('Copy Aborted, ' + FilesStr + ' File(s) Copied',
						  cWhite, cBlue);

		ProceedCopy := FALSE;
	END;
END; (* MakeNew *)

(* Diese Prozedur prÅft, ob eine existierende Datei Åberschrieben werden soll *)
PROCEDURE FileExists(VAR ProceedCopy, CopyToAFile : BOOLEAN;
							VAR TargetFile : FILE);
VAR Answer   : STRING[4];  								(* Nimmt Antwort auf			*)
	 FilesStr : STRING[5];									(* Anzahl Dateien als Text	*)
BEGIN
	WriteString('Do You Want To Overwrite Existing File (Y,N) ? ',
					cWhite, cBlue);

	ReadLnString(Answer, cWhite, cBlue);  				(* Auf Antwort warten		*)

	IF UpCase(Answer[1]) = 'Y' THEN	  					(* Datei Åberschreiben		*)
	BEGIN
		Assign(TargetFile, TargetName);
		Erase(TargetFile);									(* Zieldatei lîschen			*)

		IF IOResult <> 0 THEN								(* Fehler aufgetreten		*)
		BEGIN
			WriteLnString('Cannot Delete Target File - ' + TargetName,
							  cWhite, cBlue);

			ProceedCopy := FALSE;
		END
		ELSE MakeNew(ProceedCopy, CopyToAFile, TargetFile);
	END
	ELSE   														(* Kopieren abbrechen		*)
	BEGIN
		Str(CopiedFiles, FilesStr);						(* Anzahl als Text			*)

		WriteLnString('Copy Aborted, ' + FilesStr + ' File(s) Copied',
						  cWhite, cBlue);

		ProceedCopy := FALSE;
	END;
END; (* FileExists *)

(* Diese Funktion prÅft, ob genug Speicherplatz auf dem Ziellaufwerk ist *)
FUNCTION EnoughDiskSpace(FileTable : pRing; NrOfFiles : WORD) : BOOLEAN;
VAR Answer 	 	: STRING[4]; 								(* Nimmt Antwort auf			*)
	 TextString : STRING[10];								(* FÅr allgemeinen Text		*)
	 Direc  	 	: DirStr;	  								(* EnthÑlt Verzechnistext	*)
	 Drive  	 	: DriveStr;	  								(* Text eines Laufwerks		*)
	 FileSize,					  		 						(* Grî·er aller Dateien		*)
	 TargetFree : LONGINT;								  	(* Freier Platz auf Ziel	*)
BEGIN
	EnoughDiskSpace := TRUE;								(* Vorgabewert					*)
	DriveSplit(TargetName, Drive, Direc);				(* Laufwerksname abtrennen	*)
	FileSize := GetFileSize(FileTable, NrOfFiles);	(* Grî·e aller Dateien		*)
	TargetFree := DiskFree(Ord(Drive[1]) - Ord('A') + 1);

	IF NrOfFiles = 1 THEN
		WriteLnString('Copying 1 File Or Directory', cWhite, cBlue)
	ELSE
	BEGIN
		Str(NrOfFiles, TextString);						(* Zahl in Text umwandeln	*)

		WriteLnString('Copying ' + TextString + ' Files Or Directories',
						  cWhite, cBlue);
	END;

	Str(FileSize, TextString);								(* Zahl in Text umwandeln	*)
	WriteString('Copying ' + TextString + ' Bytes On Source To ', cWhite, cBlue);

	Str(TargetFree, TextString);							(* Zahl in Text umwandeln	*)
	WriteLnString(TextString + ' Free Bytes On Target', cWhite, cBlue);

	IF (TargetFree < FileSize) AND (CheckTarget IN ParamStatus) THEN
	BEGIN                            					(* Kein Speicher auf Ziel	*)
		EnoughDiskSpace := FALSE;
		WriteLnString('', cWhite, cBlue);
		WriteLnString('Not Enough Free Memory On Target', cWhite, cBlue);
	END
	ELSE IF NOT (CopyQuiet IN ParamStatus) THEN 		(* Genug Zielspeicher da	*)
	BEGIN
		WriteLnString('', cWhite, cBlue);
		WriteString('Do You Want To Start Copying (Y,N) ? ', cWhite, cBlue);
		ReadLnString(Answer, cWhite, cBlue); 			(* Auf Antwort warten		*)

		IF UpCase(Answer[1]) <> 'Y' THEN	  				(* Kopiervorgang abbrechen	*)
		BEGIN
			Str(CopiedFiles, TextString);	 				(* Zahl in Text umwandeln	*)

			WriteLnString('Copy Aborted, ' + TextString + ' File(s) Copied',
							  cWhite, cBlue);

			EnoughDiskSpace := FALSE;
		END
		ELSE WriteLnString('', cWhite, cBlue);
	END
	ELSE WriteLnString('', cWhite, cBlue);
END; (* EnoughDiskSpace  *)

(* Diese Funktion konstruiert den Quell- und den Zielpfad fÅr eine Datei *)
FUNCTION MakePath(FileNr : WORD; Item : pNameRec; FileTable : pRing;
						CopyToAFile : BOOLEAN; VAR CopySource,
						CopyTarget : PathStr) : BOOLEAN;
VAR i	   		: BYTE; 										(* Dient nur als ZÑhler		*)
	 TextString	: PathStr;									(* Allgemeiner Text			*)
	 FilesStr   : STRING[5];								(* Anzahl Dateien als Text	*)
BEGIN
	MakePath := TRUE;											(* Vorgabewert					*)

	WITH Item^ DO
	BEGIN
		IF (Dir[Length(Dir)] <> ':') AND	(Dir[Length(Dir)] <> '\') THEN
			CopySource := Dir + '\' + FileItem.Name
		ELSE CopySource := Dir + FileItem.Name;

		IF Pos(',', SourceName) = 0 THEN					(* Keine Liste von Namen	*)
		BEGIN
			i := 0;				 		  						(* Erster Buchstabe - 1		*)

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
			IF FileNr > 1 THEN WriteLnString('', cWhite, cBlue);
			Str(CopiedFiles, FilesStr);					(* Zahl in Text umwandeln	*)

			WriteLnString('File Cannot Be Copied Onto Itself - ' + CopySource,
							  cWhite, cBlue);

			WriteLnString('Copy Aborted, ' + FilesStr + ' File(s) Copied',
							  cWhite, cBlue);

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
	 FilesStr   : STRING[5];								(* Anzahl Dateien als Text	*)
BEGIN
	CopyOneFile := TRUE;										(* Vorgabewert					*)

	IF CopyToAFile THEN										(* Alles in Datei kopieren	*)
	BEGIN
		CASE CopyToFile(CopySource, TargetFile, BufferSize) OF
			0 : 													(* Datei wurde kopiert		*)
			BEGIN
				Inc(CopiedFiles);								(* Eine Datei mehr kopiert	*)
				SetVirtualXY(70, WhereVirtualY);			(* Cursor rechter Rand		*)
				WriteLnString(' Copied ', cWhite, cBlue);
			END;

			8 : 													(* Diskette ist voll			*)
			BEGIN
				WriteLnString('', cWhite, cBlue);
				WriteLnString('', cWhite, cBlue);
				Str(CopiedFiles, FilesStr);  				(* Zahl in Text umwandeln	*)

				WriteLnString('Insufficient Disk Space - ' + CopySource,
								  cWhite, cBlue);

				WriteLnString('Copy Aborted, ' + FilesStr + ' File(s) Copied',
								  cWhite, cBlue);

				CopyOneFile := FALSE;
			END;

		ELSE														(* Fehler ist aufgetreten	*)
			WriteLnString('', cWhite, cBlue);
			WriteLnString('', cWhite, cBlue);
			Str(CopiedFiles, FilesStr);					(* Zahl in Text umwandeln	*)
			WriteLnString('Error While Copying - ' + CopySource, cWhite, cBlue);

			WriteLnString('Copy Aborted, ' + FilesStr + ' File(s) Copied',
							  cWhite, cBlue);

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
				WriteLnString('', cWhite, cBlue);
				WriteLnString('', cWhite, cBlue);
				Str(CopiedFiles, FilesStr);  				(* Zahl in Text umwandeln	*)

				WriteLnString('Cannot Create Target Directory - ' + Drive + Direc,
								  cWhite, cBlue);

				WriteLnString('Copy Aborted, ' + FilesStr + ' File(s) Copied',
								  cWhite, cBlue);

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
					SetVirtualXY(70, WhereVirtualY);		(* Cursor rechter Rand		*)
					WriteLnString(' Copied ', cWhite, cBlue);
				END;

				8 : 												(* Diskette ist voll			*)
				BEGIN
					WriteLnString('', cWhite, cBlue);
					WriteLnString('', cWhite, cBlue);
					Str(CopiedFiles, FilesStr);	  		(* Zahl in Text umwandeln	*)

					WriteLnString('Insufficient Disk Space - ' + CopySource,
									  cWhite, cBlue);

					WriteLnString('Copy Aborted, ' + FilesStr +
									  ' File(s) Copied', cWhite, cBlue);

					IF GetFileType(CopyTarget) <> NoFile THEN
					BEGIN
						Assign(TargetFile, CopyTarget);
						Erase(TargetFile);
					END;

					CopyOneFile := FALSE;
				END;

				150 :	  								 			(* Schreibschutz ist an		*)
				BEGIN
					WriteLnString('', cWhite, cBlue);
					WriteLnString('', cWhite, cBlue);
					Str(CopiedFiles, FilesStr); 			(* Zahl in Text umwandeln	*)

					WriteLnString('Write Protect Error - ' + CopySource,
									  cWhite, cBlue);

					WriteLnString('Copy Aborted, ' + FilesStr +
									  ' File(s) Copied', cWhite, cBlue);

					CopyOneFile := FALSE;
				END;

			ELSE 								   				(* Fehler ist aufgetreten	*)
				WriteLnString('', cWhite, cBlue);
				WriteLnString('', cWhite, cBlue);
				Str(CopiedFiles, FilesStr);				(* Zahl in Text umwandeln	*)
				WriteLnString('Error While Copying - ' + CopySource, cWhite, cBlue);

				WriteLnString('Copy Aborted, ' + FilesStr + ' File(s) Copied',
								  cWhite, cBlue);

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
VAR Direc   : DirStr;	  									(* EnthÑlt Verzechnistext	*)
	 Drive   : DriveStr;	 		  							(* Text eines Laufwerks		*)
	 Answer  : STRING[4];		  							(* Nimmt Antwort auf			*)
	 TextStr : STRING[10];  								(* Zahl in Text umwandeln	*)
BEGIN
	InteractiveCopy := TRUE;								(* Vorgabewert					*)
	DriveSplit(CopyTarget, Drive, Direc);				(* Laufwerk abspalten		*)

	WriteLnString('', cWhite, cBlue);

	Str(DiskFree(Ord(Drive[1]) - Ord('A') + 1), TextStr);
	WriteString('Disk Free : ' + TextStr, cWhite, cBlue);

	Str(Item^.FileItem.Size, TextStr);

	WriteString('   File Size : ' + TextStr + '   Copy (Y,N,Quit) ? ',
					cWhite, cBlue);

	ReadLnString(Answer, cWhite, cBlue);  				(* Antwort abwarten			*)
	SetVirtualXY(70, WhereVirtualY - 1);	 			(* Cursor hinter Antwort	*)

	IF UpCase(Answer[1]) = 'Q' THEN	  					(* Kopieren abbrechen		*)
	BEGIN
		WriteLnString('', cWhite, cBlue);

		Str(CopiedFiles, TextStr);

		WriteLnString('Copy Aborted, ' + TextStr + ' File(s) Copied',
						  cWhite, cBlue);

		InteractiveCopy := FALSE;
	END
	ELSE IF UpCase(Answer[1]) = 'Y' THEN				(* Datei wird kopiert		*)
		InteractiveCopy := CopyOneFile(CopyToAFile, CopySource, CopyTarget)
	ELSE
	BEGIN
		SetVirtualXY(66, WhereVirtualY);  			(* Cursor hinter Antwort	*)
		WriteLnString(' Not Copied ', cWhite, cBlue);
	END;
END; (* InteractiveCopy *)

(* Diese Funktion legt ein leeres Verzeichnis an *)
FUNCTION MakeEmptyTree(CopyTarget : PathStr) : BOOLEAN;
VAR Direc 	 : DirStr;	  	 								(* EnthÑlt Verzechnistext	*)
	 Drive 	 : DriveStr;	 	  							(* Text eines Laufwerks		*)
	 FilesStr : STRING[5];   								(* Anzahl Dateien als Text	*)
BEGIN
	MakeEmptyTree := TRUE;									(* Vorgabewert					*)
	Dec(CopyTarget[0], 3);									(* Entferne Zeichen '\..'	*)

	IF GetFileType(CopyTarget) = NoFile THEN			(* Verzeichnisse anlegen	*)
	BEGIN
		DriveSplit(CopyTarget, Drive, Direc);			(* Laufwerk abtrennen		*)

		IF NOT MakeTree(Drive, Direc) THEN				(* Fehler beim Anlegen		*)
		BEGIN
			WriteLnString('', cWhite, cBlue);
			WriteLnString('', cWhite, cBlue);
			Str(CopiedFiles, FilesStr);					(* Zahl in Text umwandeln	*)

			WriteLnString('Cannot Create Target Directory - ' + Drive + Direc,
							  cWhite, cBlue);

			WriteLnString('Copy Aborted, ' + FilesStr + ' File(s) Copied',
							  cWhite, cBlue);

			MakeEmptyTree := FALSE;
		END
		ELSE
		BEGIN
			SetVirtualXY(69, WhereVirtualY);	 			(* Cursor rechter Rand		*)
			WriteLnString(' Created ', cWhite, cBlue);(* Verzeichnis erzeugt		*)
		END;
	END
	ELSE
	BEGIN                               				(* Ist schon vorhanden		*)
		SetVirtualXY(62, WhereVirtualY);	  				(* Cursor rechter Rand		*)
		WriteLnString(' Already Exists ', cWhite, cBlue);
	END;
END; (* MakeEmptyTree *)

(* Diese Funktion legt interaktiv ein leeres Verzeichnis an *)
FUNCTION InteractiveEmptyTree(CopyTarget : PathStr) : BOOLEAN;
VAR Direc   : DirStr;	  									(* EnthÑlt Verzechnistext	*)
	 Drive   : DriveStr;	 		  							(* Text eines Laufwerks		*)
	 Answer  : STRING[4];  		  							(* Nimmt Antwort auf			*)
	 TextStr : STRING[10]; 									(* Zahl in Text umwandeln	*)
BEGIN
	InteractiveEmptyTree := TRUE;							(* Vorgabewert					*)
	DriveSplit(CopyTarget, Drive, Direc);				(* Laufwerk abspalten		*)
	WriteLnString('', cWhite, cBlue);

	Str(DiskFree(Ord(Drive[1]) - Ord('A') + 1), TextStr);
	WriteString('Disk Free : ' + TextStr, cWhite, cBlue);
	WriteString('   Create (Y,N,Quit) ? ', cWhite, cBlue);

	ReadLnString(Answer, cWhite, cBlue);  				(* Antwort abwarten			*)
	SetVirtualXY(66, WhereVirtualY - 1); 				(* Cursor hinter Antwort	*)

	IF UpCase(Answer[1]) = 'Q' THEN						(* Kopieren abbrechen		*)
	BEGIN
		WriteLnString('', cWhite, cBlue);
		Str(CopiedFiles, TextStr);               		(* Anzahl Dateien als Text	*)

		WriteLnString('Copy Aborted, ' + TextStr + ' File(s) Copied',
						  cWhite, cBlue);

		InteractiveEmptyTree := FALSE;
	END
	ELSE IF UpCase(Answer[1]) = 'Y' THEN  				(* Verzeichnis angelegen	*)
		InteractiveEmptyTree := MakeEmptyTree(CopyTarget)
	ELSE
	BEGIN
		SetVirtualXY(65, WhereVirtualY);					(* Cursor rechter Rand		*)
		WriteLnString(' Not Created ', cWhite, cBlue);
	END;
END; (* InteractiveEmptyTree *)

(* Diese Funktion prÅft, ob eine Unterbrechung durch ESC vorgenommen wurde *)
FUNCTION CheckEsc(CopyToAFile : BOOLEAN) : BOOLEAN;
VAR Answer   : STRING[4];	  								(* Nimmt Antwort auf			*)
	 FilesStr : STRING[5];   								(* Anzahl Dateien als Text	*)
BEGIN
	CheckEsc := FALSE;										(* Vorgabewert					*)

	IF KeyPressed THEN  							 			(* Taste wurde gedrÅckt		*)
	BEGIN
		Answer[1] := ReadKey;	  							(* Tastencode einlesen		*)

		IF Answer[1] = Chr(0) THEN							(* Taste liefert ScanCode	*)
			Answer[1] := ReadKey								(* Tastendruck ignorieren	*)
		ELSE IF Answer[1] = Chr(27) THEN   				(* ESC Taste gedrÅckt		*)
		BEGIN
			WriteLnString('', cWhite, cBlue);
			WriteString('Do You Want To Abort Copy (Y,N) ? ', cWhite, cBlue);
			ReadLnString(Answer, cWhite, cBlue); 		(* Auf Anwort warten			*)

			IF UpCase(Answer[1]) = 'Y' THEN  			(* Kopieren abbrechen		*)
			BEGIN
				Str(CopiedFiles, FilesStr);				(* Anzahl Dateien als Zahl	*)

				WriteLnString('Copy Aborted, ' + FilesStr + ' File(s) Copied',
								  cWhite, cBlue);

				CheckEsc := TRUE;
			END;
		END;
	END;
END; (* CheckEsc *)

BEGIN (* DoCopy *)
	Initialize;													(* Initialisierungen			*)
	IF NOT ParamCheck THEN Exit; 							(* Parameter ÅberprÅfen		*)

	CreateRing(FileTable);									(* Tabelle aller Dateien	*)

	IF Pos(',', SourceName) = 0 THEN
		SourceName := FExpand(SourceName);  			(* Quelle voller Pfadname 	*)

	TargetName := FExpand(TargetName);  				(* Ziel voller Pfadname 	*)
	CutBackslash(SourceName);								(* öberflÅssiges '\' weg	*)
	CutBackslash(TargetName);								(* öberflÅssiges '\' weg	*)
	FilesOk := LookForFiles(FileTable, NrOfFiles);	(* Namen der Quelldateien	*)

	IF NOT FilesOk THEN										(* Zu viele DateieintrÑge	*)
		WriteLnString('Too Many Files - ' + SourceName, cWhite, cBlue)
	ELSE IF NrOfFiles = 0 THEN	  		 					(* Keine Dateien vorhanden	*)
		WriteLnString('Nothing To Copy - ' + SourceName, cWhite, cBlue)
	ELSE IF GetFileType(TargetName) = MultFiles THEN
		WriteLnString('Illegal Target File - ' + TargetName, cWhite, cBlue)
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
					IF (InterOn IN ParamStatus) AND (i > 1) THEN
						WriteLnString('', cWhite, cBlue);

					IF Item^.FileItem.Name = '..' THEN	(* Verzeichnis erzeugen		*)
					BEGIN
						IF NOT CopyToAFile THEN				(* Nicht in Datei kopiert	*)
						BEGIN
							Dec(CopyTarget[0], 3);			(* Zeichen '\..' sind weg	*)
							Str(i : 4, TextStr);  			(* Zahl in Text umwandeln	*)
							WriteString(TextStr + '> ' + CopyTarget, cWhite, cBlue);
							Inc(CopyTarget[0], 3);			(* Zeichen '\..' wieder da	*)

							IF InterOn IN ParamStatus THEN(* Interaktiv erzeugen		*)
								ProceedCopy := InteractiveEmptyTree(CopyTarget)
							ELSE ProceedCopy := MakeEmptyTree(CopyTarget);
						END
						ELSE
						BEGIN
							WriteLnString('Cannot Create Target Directory',
											  cWhite, cBlue);
						END;
					END
					ELSE											(* Normale Datei kopieren	*)
					BEGIN
						Str(i : 4, TextStr);  				(* Zahl in Text umwandeln	*)

						WriteString(TextStr + '> ' + CopySource + ' ' +
										Chr(26) + ' ' + CopyTarget, cWhite, cBlue);

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
			WriteLnString('Nothing Copied, Target File Removed', cWhite, cBlue);
			Erase(TargetFile);
		END
		ELSE IF CopiedFiles = 0 THEN						(* Keine Dateien kopiert	*)
			Erase(TargetFile);
	END;

	IF FilesOk AND ProceedCopy THEN						(* Kopiervorgang war Ok		*)
	BEGIN
		WriteLnString('', cWhite, cBlue);
		Str(CopiedFiles, TextStr);  						(* Zahl in Text umwandeln	*)
		WriteLnString(TextStr + ' File(s) Copied', cWhite, cBlue);
	END;

	WriteLnString('', cWhite, cBlue);
END; (* DoCopy *)
