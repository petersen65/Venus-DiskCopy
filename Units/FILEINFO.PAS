(*****************************************************************)
(* Programmname    : FILEINFO.PAS V3.1         						  *)
(* Programmautor   : Michael Rippl             						  *)
(* Compiler        : Quick Pascal V1.0    	  						  *)
(* Inhalt          : Routinen fÅr die Arbeit mit dem Dateisystem *)
(* Bemerkung       : -                    	 						  *)
(* Letzte énderung : 25-Apr-1991           	  						  *)
(*****************************************************************)

UNIT FileInfo;													(*$I- Kein I/O Checking		*)
																	(*$V- Kein String Checking	*)
INTERFACE

USES Fifo, Dos; 	 											(* Units einbinden			*)

CONST FileMemMin : WORD = 32768;							(* Minimaler DOS Speicher	*)
		MaxFiles	  : WORD = 2500;							(* Maximal 2000 Dateien		*)

CONST CompleteLen = 12;										(* Komplette NamenslÑnge	*)
		NameLen 	   = 8;										(* Nur die NamenslÑnge		*)
		ExtLen  	   = 3;										(* Nur ErweiterungslÑnge	*)

TYPE FileType 	  = (NoFile, RdOnlyFile, DirFile, HiddenFile, SystemFile,
						  OneFile, MultFiles);				(* Alle Dateitypen			*)

	  CompleteStr = STRING[CompleteLen];		  		(* Typ eines Dateinamens	*)
	  DriveStr    = STRING[3];	  							(* Nimmt Laufwerk	auf 		*)
	  pNameRec 	  = ^NameRec;  					  		(* Zeiger auf Dateieintrag	*)

	  NameRec  	  = RECORD   						  		(* Eintrag einer Datei		*)
							 Dir 		 : DirStr;	  			(* Pfad zur Datei hin		*)
							 FileItem : SearchRec;	  		(* Daten Åber Dateieintrag	*)
						 END;

(* Diese Prozedur entfernt ein ÅberflÅssiges Backslash bei Verzeichnisnamen *)
PROCEDURE CutBackslash(VAR Path : PathStr);

(* Diese Funktion liefert fÅr ein Dateiattribut einen bestimmten Buchstaben *)
FUNCTION GetAttribChar(AttribWord, AttribBit : WORD) : CHAR;

(* Diese Funktion erweitert einen Dateinamen auf seine volle Form *)
FUNCTION ExpandName(SrcStr : CompleteStr) : CompleteStr;

(* Diese Funktion prÅft, ob ein Dateiname zu einem Zeichenmuster pa·t *)
FUNCTION MatchName(Pattern, FileName : CompleteStr) : BOOLEAN;

(* Buchstaben, auch deutsche Umlaute, werden in Gro·buchstaben umgewandelt *)
FUNCTION _UpCase(Ch : CHAR) : CHAR;

(* Es wird eine Liste mit allen Dateien einer vorgegebenen Maske erzeugt *)
FUNCTION GetFiles(Dir : DirStr; Files : pRing; SubDirs : BOOLEAN;
						VAR NrOfFiles : WORD) : BOOLEAN;

(* Diese Prozedur ermittelt den Baum eines Verzeichnisses *)
FUNCTION GetTree(Dir : DirStr; Files : pRing; VAR NrOfFiles : WORD) : BOOLEAN;

(* Diese Funktion liefert den Namen einer Diskette *)
FUNCTION GetVolume(Drive : CHAR) : DirStr;

(* Diese Funktion liefert den Typ von einer Datei, deren Name angegeben wird *)
FUNCTION GetFileType(Path : PathStr) : FileType;

(* Diese Funktion legt einen kompletten Verzeichnisbaum an *)
FUNCTION MakeTree(Target, Tree : PathStr) : BOOLEAN;

(* Diese Prozedur trennt ein Laufwerk von einem Verzeichnispfad *)
PROCEDURE DriveSplit(Path : PathStr; VAR Drive : DriveStr; VAR Direc : DirStr);

(* Diese Funktion ermittelt die Gesamtgrî·e aller Dateien in einer Liste *)
FUNCTION GetFileSize(Files : pRing; NrOfFiles : WORD) : LONGINT;

(* Diese Funktion kopiert eine Datei von einer Quelle zu einem Ziel *)
FUNCTION CopyFile(Source, Target : PathStr; BufferSize : WORD) : BYTE;

(* Diese Funktion kopiert eine Datei in eine schon geîffnete Zieldatei *)
FUNCTION CopyToFile(Source : PathStr; VAR TargetFile : FILE;
						  BufferSize : WORD) : BYTE;

IMPLEMENTATION

(* Diese Prozedur entfernt ein ÅberflÅssiges Backslash bei Verzeichnisnamen *)
PROCEDURE CutBackslash(VAR Path : PathStr);
BEGIN
	IF Length(Path) > 0 THEN								(* Name nicht leer			*)
	BEGIN
		IF (Path[Length(Path) - 1] <> ':') AND (Path[Length(Path)] = '\') THEN
			Dec(Path[0]);										(* Zeichen '\' entfernt		*)
	END;
END; (* CutBackslash *)

(* Diese Funktion liefert fÅr ein Dateiattribut einen bestimmten Buchstaben *)
FUNCTION GetAttribChar(AttribWord, AttribBit : WORD) : CHAR;
BEGIN
	IF AttribWord AND AttribBit = AttribBit THEN
	BEGIN
		CASE AttribBit OF										(* Attribute unterscheiden	*)
			ReadOnly  : GetAttribChar := 'R';
			Hidden    : GetAttribChar := 'H';
			SysFile   : GetAttribChar := 'S';
			VolumeID  : GetAttribChar := 'V';
			Directory : GetAttribChar := 'D';
			Archive   : GetAttribChar := 'A';
		END;
	END
	ELSE GetAttribChar := '.';
END; (* GetAttribChar *)

(* Diese Funktion erweitert einen Dateinamen auf seine volle Form *)
FUNCTION ExpandName(SrcStr : CompleteStr) : CompleteStr;
CONST NameSet : SET OF CHAR =                      (* FÅr Dateiname zulÑssig	*)
			[Chr(0)..Chr(255)] - ['*', '?', ' ', ',', '.'];
VAR TarStr 	 : CompleteStr;								(* Kompletter Dateiname		*)
	 SrcIndex,													(* ZÑhler fÅr Quelle			*)
	 TarIndex : BYTE;											(* ZÑhler fÅr Ziel			*)
BEGIN
	SrcIndex := 1;												(* Startwerte setzen			*)
	TarIndex := 1;

	WHILE TarIndex <= NameLen DO							(* Name vor dem Punkt		*)
	BEGIN
		IF (SrcIndex > Length(SrcStr)) OR (SrcStr[SrcIndex] = '.') THEN
			TarStr[TarIndex] := ' '
		ELSE IF SrcStr[SrcIndex] IN (['?', ' '] + NameSet) THEN
		BEGIN
			TarStr[TarIndex] := _UpCase(SrcStr[SrcIndex]);
			Inc(SrcIndex);
		END
		ELSE IF SrcStr[SrcIndex] = '*' THEN TarStr[TarIndex] := '?';

		Inc(TarIndex);											(* NÑchstes Zeichen			*)
	END;

	TarStr[0] := Chr(NameLen);								(* LÑnge des Namens 			*)
	TarStr := TarStr + ' ';									(* Trennt Erweiterung ab	*)
	TarIndex := NameLen + 2;								(* Hinter der Erweiterung	*)
	SrcIndex := Pos('.', SrcStr) + 1;					(* Erweiterung in Quelle	*)

	IF SrcIndex = 1 THEN TarStr := TarStr + '   '	(* Keine Erweiterung da		*)
	ELSE
	BEGIN
		WHILE TarIndex <= CompleteLen DO   				(* Erweiterung nach Punkt	*)
		BEGIN
			IF SrcIndex > Length(SrcStr) THEN TarStr[TarIndex] := ' '
			ELSE IF SrcStr[SrcIndex] IN (['?', ' '] + NameSet) THEN
			BEGIN
				TarStr[TarIndex] := _UpCase(SrcStr[SrcIndex]);
				Inc(SrcIndex);
			END
			ELSE IF SrcStr[SrcIndex] = '*' THEN TarStr[TarIndex] := '?';

			Inc(TarIndex);										(* NÑchstes Zeichen			*)
		END;
	END;

	TarStr[0] := Chr(CompleteLen);						(* LÑnge nachtragen			*)
	ExpandName := TarStr;									(* Funktionswert zurÅck		*)
END; (* ExpandName *)

(* Diese Funktion prÅft, ob ein Dateiname zu einem Zeichenmuster pa·t *)
FUNCTION MatchName(Pattern, FileName : CompleteStr) : BOOLEAN;
VAR i : WORD;													(* Dient nur als ZÑhler		*)
BEGIN
	FOR i := 1 TO CompleteLen DO							(* Kompletten Namen prÅfen	*)
	BEGIN
		IF Pattern[i] <> '?' THEN                 	(* '?' fÅr alle Zeichen		*)
		BEGIN
			IF Pattern[i] <> FileName[i] THEN 			(* Muster pa·t nicht			*)
			BEGIN
				MatchName := FALSE;							(* Muster ungleich Name		*)
				Exit;												(* Prozedur vorzeitig Ende	*)
			END;
		END;
	END;

	MatchName := TRUE;										(* Muster und Name passen	*)
END; (* MatchName *)

(* Buchstaben, auch deutsche Umlaute, werden in Gro·buchstaben umgewandelt *)
FUNCTION _UpCase(Ch : CHAR) : CHAR;
BEGIN
	CASE Ch OF
		'î' : _UpCase := 'ô';
		'Å' : _UpCase := 'ö';
		'Ñ' : _UpCase := 'é';
	ELSE
		_UpCase := UpCase(Ch);
	END;
END; (* _UpCase *)

(* Es wird eine Liste mit allen Dateien einer vorgegebenen Maske erzeugt *)
FUNCTION GetFiles(Dir : DirStr; Files : pRing; SubDirs : BOOLEAN;
						VAR NrOfFiles : WORD) : BOOLEAN;
CONST ListMax = 64;											(* Anzahl Verzeichnisse		*)

TYPE TList = RECORD											(* Verzeichnislisten			*)
					 NrOfFiles : WORD;						(* Anzahl Dateien in Liste	*)
					 FileList  : pRing;						(* Liste aller Dateien		*)
				 END;

VAR ThatDir : DirStr;										(* Verzeichnis aus Liste	*)
	 Item 	: pNameRec;   									(* Dateieintrag in Liste	*)
	 Status  : BOOLEAN;										(* Status der Prozedur		*)
	 List	   : ARRAY [1..ListMax] OF TList;			(* Liste der Verzeichnisse	*)
	 k,															(* Dient nur als ZÑhler		*)
	 ListCnt : 0..ListMax;									(* ZÑhler Verzeichnisse		*)

(* Diese Prozedur durchsucht rekursiv einen Dateibaum *)
FUNCTION SubDirectory(SubDir : DirStr) : BOOLEAN;
VAR Result    : SearchRec;  								(* Resultat einer Suche		*)
	 NewItem   : pNameRec;   								(* Neue Datei gefunden		*)
	 FileVar   : FILE;		  								(* Dateivariable fÅr Test	*)
	 i,															(* Dient nur als ZÑhler		*)
	 NrFiles,          										(* Kopie von 'NrOfFiles'	*)
	 Attrib    : WORD;		  								(* Attribute einer Datei	*)
	 SubStatus : BOOLEAN;									(* Speicherstatus				*)
	 Direc     : DirStr;										(* EnthÑlt Verzechnistext	*)
	 FileName  : NameStr;									(* EnthÑlt Dateinamen		*)
	 Extension : ExtStr;										(* Erweiterung von Namen 	*)
	 FindFile,													(* Kompletten Namen suchen	*)
	 ComplFile : CompleteStr;								(* Kompletter Dateiname		*)
BEGIN
	SubStatus := TRUE;										(* Wert dient als Vorgabe	*)
	ComplFile := '';											(* Defaultwert leerer Text	*)
	CutBackslash(SubDir);                        	(* öberlÅssiges '\' weg		*)

	IF (SubDir[Length(SubDir) - 1] = ':') AND			(* Ganzes Laufwerk gegeben	*)
		(SubDir[Length(SubDir)] = '\') THEN
		SubDir := SubDir + '*.*'							(* Alle Dateien anhÑngen	*)
	ELSE
	BEGIN
		Assign(FileVar, SubDir);
		GetFAttr(FileVar, Attrib);							(* Dateiattribute holen		*)

		IF (IOResult <> 0) OR (Attrib AND Directory = 0) THEN
		BEGIN
			FSplit(SubDir, Direc, FileName, Extension);
			SubDir := Direc;	  								(* Verzeichnis isoliert		*)
			ComplFile := ExpandName(FileName + Extension);
			CutBackslash(SubDir);                    	(* öberlÅssiges '\' weg		*)

			IF (SubDir[Length(SubDir) - 1] = ':') AND	(* Ganzes Laufwerk gegeben	*)
				(SubDir[Length(SubDir)] = '\') THEN
				SubDir := SubDir + '*.*'				  	(* Alle Dateien anhÑngen	*)
		END;
	END;

	FindFirst(SubDir, AnyFile AND NOT VolumeId, Result);

	IF DosError = 0 THEN  									(* Kein Fehler aufgetreten	*)
	BEGIN
		IF (Result.Attr AND Directory = Directory) AND
			(SubDir[Length(SubDir)] <> '*') THEN     	(* Verzeichnis gefunden		*)
		BEGIN
			SubDir := SubDir + '\*.*';						(* Alle Dateien anhÑngen	*)
			FindFirst(SubDir, AnyFile AND NOT VolumeId, Result);
		END;

		WHILE SubDir[Length(SubDir)] <> '\' DO			(* Verzeichnis darÅber 		*)
			Dec(SubDir[0]);									(* LÑnge um eins kÅrzen		*)

		IF SubDir[Length(SubDir) - 1] <> ':' THEN		(* Kein ganzes Laufwerk		*)
			Dec(SubDir[0]);									(* LÑnge um eins kÅrzen		*)

		WHILE SubStatus AND (DosError = 0) DO			(* Verzeichnis durchgehen	*)
		BEGIN
			IF Result.Attr AND Directory = Directory THEN
			BEGIN                                     (* Verzeichnis gefunden		*)
				IF SubDirs AND (Result.Name <> '.') AND
					(Result.Name <> '..') THEN          (* Verzeichnis auswerten	*)
				BEGIN
					IF SubDir[Length(SubDir)] <> '\' THEN
						SubStatus := SubDirectory(FExpand(SubDir + '\' + Result.Name))
					ELSE SubStatus := SubDirectory(FExpand(SubDir + Result.Name));
				END
				ELSE	  											(* Nur Eintrag zurÅckgeben	*)
				BEGIN
					IF MemAvail >= FileMemMin THEN		(* Speicher vorhanden		*)
					BEGIN
						New(NewItem);						 	(* Neuen Eintrag anlegen	*)
						NewItem^.FileItem := Result;   	(* Dateieintrag merken		*)
						NewItem^.Dir := SubDir;			 	(* Seinen Pfad eintragen	*)
						Inc(List[ListCnt].NrOfFiles);	 	(* Eine Datei mehr			*)
						Push(List[ListCnt].FileList, NewItem);	
					END
					ELSE SubStatus := FALSE;				(* Zu wenig Speicher da		*)
				END;
			END
			ELSE											  		(* Datei gefunden				*)
			BEGIN
				IF MemAvail >= FileMemMin THEN			(* Speicher vorhanden		*)
				BEGIN
					New(NewItem);							 	(* Neuen Eintrag anlegen	*)
					NewItem^.FileItem := Result;  	 	(* Dateieintrag merken		*)
					NewItem^.Dir := SubDir;				 	(* Seinen Pfad eintragen	*)
					Inc(List[ListCnt].NrOfFiles);		 	(* Eine Datei mehr			*)
					Push(List[ListCnt].FileList, NewItem);
				END
				ELSE SubStatus := FALSE;					(* Zu wenig Speicher da		*)
			END;

			IF List[ListCnt].NrOfFiles + NrOfFiles > MaxFiles THEN
				SubStatus := FALSE;							(* Zu viele DateieintrÑge	*)

			FindNext(Result);	  								(* NÑchsten Eintrag suchen	*)
		END;

		IF SubStatus AND (Length(ComplFile) > 0) THEN(* Dateiname vorhanden		*)
		BEGIN
			NrFiles := List[ListCnt].NrOfFiles;			(* Obergrenze nicht Ñndern	*)

			FOR i := 1 TO NrFiles DO 						(* Alle EintrÑge prÅfen		*)
			BEGIN
				Pop(List[ListCnt].FileList, POINTER(NewItem));

				IF (NewItem^.FileItem.Name <> '.') AND	(* '.' und '..' wegnehmen	*)
					(NewItem^.FileItem.Name <> '..')	THEN
				BEGIN
					FindFile := ExpandName(NewItem^.FileItem.Name);

					IF MatchName(ComplFile, FindFile) THEN
						Push(List[ListCnt].FileList, NewItem)
					ELSE						  					(* Eintrag entfernen			*)
					BEGIN
						Dispose(NewItem);	  					(* Speicher freigeben		*)
						Dec(List[ListCnt].NrOfFiles);		(* Ein Eintrag weniger		*)
					END;
				END
				ELSE 		 					  					(* '.' und '..' entfernen 	*)
				BEGIN
					Dispose(NewItem);		  					(* Speicher freigeben		*)
					Dec(List[ListCnt].NrOfFiles);			(* Ein Eintrag weniger		*)
				END;
			END;
		END;
	END;

	IF NOT SubStatus THEN									(* Fehler ist aufgetreten	*)
	BEGIN
		WHILE NOT RingIsEmpty(List[ListCnt].FileList) DO	
		BEGIN
			Pop(List[ListCnt].FileList, POINTER(NewItem));
			Dispose(NewItem);
		END;

		List[ListCnt].NrOfFiles := 0;						(* Keine Dateien vorhanden	*)
	END;

	SubDirectory := SubStatus;								(* Status zurÅckgeben		*)
END; (* SubDirectory *)

BEGIN (* GetFiles *)
	NrOfFiles := 0;											(* Keine Dateien gefunden	*)
	ListCnt := 0;												(* Erste Verzeichnisliste	*)

	IF MemAvail >= FileMemMin THEN						(* Genug Speicher ist da	*)
	BEGIN
		FOR k := 1 TO ListMax DO							(* Alle Listen anlegen		*)
		BEGIN
			CreateRing(List[k].FileList);
			List[k].NrOfFiles := 0;
		END;

		IF Dir[Length(Dir)] <> ',' THEN              (* Komma fÅr Listenende		*)
			Dir := Dir + ',';

		WHILE Pos(',', Dir) <> 0 DO						(* Verzeichnisliste 			*)
		BEGIN
			Inc(ListCnt);										(* Neue Verzeichnisliste	*)
			ThatDir := Copy(Dir, 1, Pos(',', Dir));	(* Verzeichnis isolieren	*)
			Dec(ThatDir[0]);									(* Komma entfernen			*)
			Delete(Dir, 1, Pos(',', Dir));

			IF ThatDir <> '' THEN
			BEGIN
				Status := SubDirectory(FExpand(ThatDir));
				Inc(NrOfFiles, List[ListCnt].NrOfFiles);
			END;

			IF NOT Status THEN
			BEGIN
				FOR k := 1 TO ListMax DO					(* Listen wieder lîschen	*)
				BEGIN
					WHILE NOT RingIsEmpty(List[k].FileList) DO
					BEGIN
						Pop(List[k].FileList, POINTER(Item));
						Dispose(Item);
					END;

					DeleteRing(List[k].FileList);
				END;

				NrOfFiles := 0;
				GetFiles := FALSE;
				Exit;												(* Funktion vorzeitig Ende	*)
			END;
		END;

		FOR k := 1 TO ListMax DO							(* Alle Listen durchgehen	*)
		BEGIN
			WHILE NOT RingIsEmpty(List[k].FileList) DO
			BEGIN                   						(* Alles zusammenkopieren	*)
				Pop(List[k].FileList, POINTER(Item));
				Push(Files, Item);	
			END;

			DeleteRing(List[k].FileList);
		END;

		GetFiles := TRUE;										(* Listen alle in Ordnung	*)
	END
	ELSE GetFiles := FALSE;									(* Kein Speicher vorhanden	*)
END; (* GetFiles *)

(* Diese Prozedur ermittelt den Baum eines Verzeichnisses *)
FUNCTION GetTree(Dir : DirStr; Files : pRing; VAR NrOfFiles : WORD) : BOOLEAN;

(* Diese Prozedur durchsucht rekursiv einen Dateibaum *)
FUNCTION SubDirectory(SubDir : DirStr; Level : BYTE) : BOOLEAN;
VAR Result    : SearchRec;  								(* Resultat einer Suche		*)
	 NewItem   : pNameRec;  								(* Neue Datei gefunden		*)
	 NewDir    : DirStr;										(* Neues Verzeichnis			*)
	 SubStatus : BOOLEAN;
BEGIN
	SubStatus := TRUE;										(* Wert dient als Vorgabe	*)

	IF SubDir[Length(SubDir)] = '\' THEN				(* '\' ist schon vorhanden *)
		NewDir := SubDir + '*.*'							(* Alle Dateien anhÑngen	*)
	ELSE NewDir := SubDir + '\*.*';

	FindFirst(NewDir, Directory, Result); 				(* Verzeichnisse suchen		*)

	IF DosError = 0 THEN  									(* Kein Fehler aufgetreten	*)
	BEGIN
		IF MemAvail >= FileMemMin THEN					(* Speicher vorhanden		*)
		BEGIN
			New(NewItem);						  				(* Neuen Eintrag anlegen	*)
			NewItem^.FileItem.Size := Level;				(* Verzeichnistiefe merken	*)
			CutBackslash(SubDir);							(* öberflÅssiges '\' weg	*)
			NewItem^.Dir := SubDir;			  				(* Seinen Pfad eintragen	*)
			Inc(NrOfFiles);					  				(* Eine Datei mehr			*)
			Push(Files, NewItem);							(* Eintrag in Liste merken	*)

			IF NrOfFiles > MaxFiles THEN					(* Zu viele DateieintrÑge	*)
				SubStatus := FALSE;

			WHILE SubStatus AND (DosError = 0) DO		(* Verzeichnis durchgehen	*)
			BEGIN
				IF (Result.Name <> '.') AND (Result.Name <> '..') THEN
				BEGIN
					IF SubDir[Length(SubDir)] = '\' THEN(* Neuer Verzeichnisname	*)
						NewDir := SubDir + Result.Name
					ELSE NewDir := SubDir + '\' + Result.Name;

					SubStatus :=
						SubDirectory(NewDir, Level + 1);	(* Ins Verzeichnis gehen	*)
				END;

				FindNext(Result);								(* NÑchstes Verzeichnis		*)
			END;
		END
		ELSE SubStatus := FALSE;							(* Zu wenig Speicher da		*)
	END;

	IF NOT SubStatus THEN									(* Fehler ist aufgetreten	*)
	BEGIN
		WHILE NOT RingIsEmpty(Files) DO					(* Gesamte Liste freigeben	*)
		BEGIN
			Pop(Files, POINTER(NewItem));					(* Dateiname aus Liste		*)
			Dispose(NewItem);
		END;

		NrOfFiles := 0;										(* Keine Dateien vorhanden	*)
	END;

	SubDirectory := SubStatus;								(* Status zurÅckgeben		*)
END; (* SubDirectory *)

BEGIN (* GetTree *)
	NrOfFiles := 0;											(* Keine Verzeichnisse		*)
	GetTree := SubDirectory(FExpand(Dir), 1); 		(* Vollen Pfad erweitern	*)
END; (* GetTree *)

(* Diese Funktion liefert den Namen einer Diskette *)
FUNCTION GetVolume(Drive : CHAR) : DirStr;
VAR OneFile : SearchRec; 									(* Informationen von Datei	*)
	 Volume  : DirStr;  										(* Name einer Diskette		*)
	 i       : BYTE;											(* Dient nur als ZÑhler		*)
BEGIN
	FindFirst(Drive + ':\*.*', VolumeId, OneFile); 	(* Volume Id suchen			*)

	IF DosError = 0 THEN Volume := OneFile.Name
	ELSE Volume := '';									 	(* Bei Fehler leerer Text	*)

	IF Length(Volume) > 8 THEN        					(* Punkt im Name entfernen	*)
	BEGIN
		FOR i := 9 TO Length(Volume) - 1 DO				(* Text zusammenschieben	*)
			Volume[i] := Volume[i + 1];

		Dec(Volume[0]);										(* LÑnge um eins kÅrzen		*)
	END;

	GetVolume := Volume;										(* Text zurÅckgeben			*)
END; (* GetVolume *)

(* Diese Funktion liefert den Typ einer Datei, deren Name angegeben wird *)
FUNCTION GetFileType(Path : PathStr) : FileType;
VAR Target : FILE;											(* FÅr Zieldatei anwenden	*)
	 Attr   : WORD;											(* Attribute einer Datei	*)
BEGIN
	IF (Pos('?', Path) <> 0) OR (Pos('*', Path) <> 0) OR
		(Pos(',', Path) <> 0) THEN
		GetFileType := MultFiles							(* Mehrere Dateien			*)
	ELSE IF ((Path[Length(Path) - 1] = ':') AND (Path[Length(Path)] = '\')) OR
		(Path[Length(Path)] = ':') THEN         		(* Datei ist Verzeichnis	*)
		GetFileType := DirFile
	ELSE
	BEGIN
		Assign(Target, Path);
		GetFAttr(Target, Attr);								(* Attribute der Datei		*)

		IF (DosError <> 0) OR (Attr AND VolumeId = VolumeId) THEN
			GetFileType := NoFile							(* Datei wird ignoriert		*)
		ELSE IF Attr AND ReadOnly = ReadOnly THEN
			GetFileType := RdOnlyFile		 				(* Nur lesbare Datei			*)
		ELSE IF Attr AND Directory = Directory THEN
			GetFileType := DirFile							(* Datei ist Verzeichnis	*)
		ELSE IF Attr AND Hidden = Hidden THEN
			GetFileType := HiddenFile						(* Versteckte Datei			*)
		ELSE IF Attr AND SysFile = SysFile THEN
			GetFileType := SystemFile						(* Systemdatei					*)
		ELSE GetFileType := OneFile;						(* Eine einzige Datei		*)
	END;
END; (* GetFileType *)

(* Diese Prozedur trennt ein Laufwerk von einem Verzeichnispfad *)
PROCEDURE DriveSplit(Path : PathStr; VAR Drive : DriveStr; VAR Direc : DirStr);
VAR i : BYTE;													(* Dient nur als ZÑhler		*)
BEGIN
	FOR i := 1 TO Length(Path) DO							(* Nur Gro·buchstaben		*)
		Path[i] := _UpCase(Path[i]);

	IF Length(Path) > 1 THEN								(* Kleinste PfadlÑnge		*)
	BEGIN
		IF Path[2] <> ':' THEN								(* Kein Laufwerk vorhanden	*)
		BEGIN
			Drive := '';
			Direc := Path;	  									(* Pfad ist Verzeichnis		*)
		END
		ELSE IF Length(Path) > 2 THEN						(* Laufwerk gefunden			*)
		BEGIN
			Drive[1] := Path[1];								(* Laufwerksbuchstabe		*)
			Drive[2] := ':';

			IF Path[3] = '\' THEN							(* Laufwerk mit '\'			*)
			BEGIN
				Drive[3] := '\';
				Drive[0] := Chr(3);							(* LÑnge des Textes 'X:\'	*)

				IF Length(Path) > 3 THEN					(* Pfad und Laufwerk			*)
					Direc := Copy(Path, 4, Length(Path) - 3)
				ELSE Direc := '';								(* Kein Pfad vorhanden		*)
			END
			ELSE													(* Laufwerk ohne '\'			*)
			BEGIN
				Drive[0] := Chr(2);							(* LÑnge des Textes 'X:'	*)
				Direc := Copy(Path, 3, Length(Path) - 2);
			END;
		END
		ELSE														(* Pfad ist nur Laufwerk	*)
		BEGIN
			Drive := Path;
			Direc := '';
		END;
	END
	ELSE 															(* PfadlÑnge kleiner zwei	*)
	BEGIN
		Drive := '';											(* Kein Laufwerk vorhanden	*)
		Direc := Path;											(* Pfad ist Verzeichnis		*)
	END;
END; (* DriveSplit *)

(* Diese Funktion legt einen kompletten Verzeichnisbaum an *)
FUNCTION MakeTree(Target, Tree : PathStr) : BOOLEAN;
VAR ActualPath : PathStr;									(* Aktueller Pfad			 	*)
	 ActualDir,													(* Aktuelles Verzeichnis	*)
	 Direc	   : DirStr;									(* Zielverzeichnis 			*)
	 Drive 	   : DriveStr;									(* Ziellaufwerk als Text	*)
	 i,															(* Dient nur als ZÑhler		*)
	 Status,														(* Nur Platzhalter			*)
	 TreeLen    : BYTE;  									(* LÑnge des Baumnamens		*)
BEGIN
	TreeLen := Length(Tree);								(* LÑnge des Namens merken	*)
	GetDir(0, ActualPath);									(* Aktuellen Pfad merken	*)
	DriveSplit(Target, Drive, Direc);					(* Laufwerk abspalten		*)

	IF Length(Drive) = 0 THEN GetDir(0, ActualDir)	(* Aktuelle Dir Zieldrive	*)
	ELSE GetDir(Ord(Drive[1]) - Ord('A') + 1, ActualDir);

	ChDir(Target);												(* Ins Zielverzeichnis		*)

	IF IOResult <> 0 THEN MakeTree := FALSE 			(* Fehler ist aufgetreten 	*)
	ELSE
	BEGIN
		i := 1; 													(* Anfang des Baumnamens	*)

		REPEAT               								(* Baumname durchgehen		*)
			IF Tree[i] = '\' THEN Inc(i);
			WHILE (i < TreeLen) AND (Tree[i] <> '\') DO Inc(i);

			Tree[0] := Chr(i);								(* Neue LÑnge eintragen		*)
			IF Tree[i] = '\' THEN Dec(Tree[0]);

			MkDir(Tree);										(* Verzeichnis anlegen		*)
			Status := IOResult;								(* Status I/O Operation		*)

			IF (Status <> 0) AND (Status <> 5) THEN	(* Fehler fÅr Abbruch		*)
			BEGIN
				MakeTree := FALSE;  							(* Fehler ist aufgetreten	*)
				ChDir(ActualDir);								(* Aktuelle Dir Zieldrive	*)
				ChDir(ActualPath);  							(* Aktueller Pfad				*)
				Status := IOResult;							(* Compilerfehler QP V1.0	*)
				Exit;												(* Vorzeitig Funktion Ende	*)
			END;
		UNTIL i = TreeLen;									(* Ende des Baumnamens		*)

		MakeTree := TRUE;										(* Verzeichnisse korrekt	*)
	END;

	ChDir(ActualDir);											(* Aktuelle Dir Zieldrive	*)
	ChDir(ActualPath);  										(* Aktueller Pfad				*)
	Status := IOResult;										(* Compilerfehler QP V1.0	*)
END; (* MakeTree *)

(* Diese Funktion ermittelt die Gesamtgrî·e aller Dateien in einer Liste *)
FUNCTION GetFileSize(Files : pRing; NrOfFiles : WORD) : LONGINT;
VAR i   	: WORD;												(* Dient nur als ZÑhler		*)
	 Size	: LONGINT;  										(* Grî·e aller Dateien		*)
	 Item : pNameRec;											(* Element aus der Liste	*)
BEGIN
	Size := 0;													(* Startwert					*)

	FOR i := 1 TO NrOfFiles DO								(* Alle Dateien durchgehen	*)
	BEGIN
		Pop(Files, POINTER(Item));							(* Element aus Liste holen	*)
		Inc(Size, Item^.FileItem.Size);  		  		(* Zu Gesamtsumme addieren	*)
		Push(Files, Item);									(* Element wieder in Liste	*)
	END;

	GetFileSize := Size;										(* Gesamtgrî·e zurÅckgeben	*)
END; (* GetFileSize *)

(* Diese Funktion kopiert eine Datei von einer Quelle zu einem Ziel *)
FUNCTION CopyFile(Source, Target : PathStr; BufferSize : WORD) : BYTE;
VAR SourceFile,       										(* Quelldatei					*)
	 TargetFile   : FILE;									(* Zieldatei					*)
	 FileTime	  : LONGINT;								(* Zeit der Quelle merken	*)
	 Buffer		  : POINTER;								(* Puffer nimmt Daten auf	*)
	 Status		  : BYTE;									(* Status einer Operation	*)
	 NewResult,													(* Resultat von BlockWrite	*)
	 Attrib,														(* Attribute einer Datei	*)
	 Result		  : WORD;									(* Resultat von I/O			*)
	 ProceedCopy, 												(* Kopieren fortsetzen		*)
	 ReadOnlyFile : BOOLEAN;								(* Quelldatei nur lesbar	*)
BEGIN
	GetMem(Buffer, BufferSize);							(* Speicher fÅr Puffer		*)
	Assign(SourceFile, Source);							(* Quelldateiname zuweisen	*)

	IF GetFileType(Source) = RdOnlyFile THEN			(* Datei nur zum lesen		*)
	BEGIN
		ReadOnlyFile := TRUE;
		GetFAttr(SourceFile, Attrib);						(* Dateiattribute holen		*)
		SetFAttr(SourceFile, Attrib AND NOT ReadOnly);
	END
	ELSE ReadOnlyFile := FALSE;							(* Datei auch beschreibbar	*)

	Reset(SourceFile, 1);  									(* Datei zum Lesen îffnen	*)
	Status := IOResult;										(* I/O Status merken			*)

	IF Status = 0 THEN										(* Datei îffnen ist Ok		*)
	BEGIN
		Assign(TargetFile, Target);						(* Zieldateiname zuweisen	*)
		ReWrite(TargetFile, 1);								(* Datei zum Schreiben		*)
		Status := IOResult;									(* I/O Status merken			*)

		IF Status <> 0 THEN Close(SourceFile)		  	(* Fehler beim îffnen		*)
		ELSE														(* Datei îffnen ist Ok		*)
		BEGIN
			ProceedCopy := TRUE;								(* Weiterkopieren ist Ok	*)
			GetFTime(SourceFile, FileTime);				(* Zeit der Quelle merken	*)

			WHILE ProceedCopy AND NOT Eof(SourceFile) DO
			BEGIN                                    	(* Bis zum Dateiende lesen	*)
				BlockRead(SourceFile, Buffer^, BufferSize, Result);
				Status := IOResult;					  		(* I/O Status merken			*)

				IF Status <> 0 THEN 							(* Fehler ist aufgetreten	*)
					ProceedCopy := FALSE
				ELSE                 						(* Kein Fehler aufgetreten	*)
				BEGIN
					BlockWrite(TargetFile, Buffer^, Result, NewResult);
					Status := IOResult; 				  		(* I/O Status merken			*)

					IF NewResult <> Result THEN  			(* Annahme Diskette voll	*)
					BEGIN
						Status := 8;				  			(* Insufficient Memory		*)
						ProceedCopy := FALSE;
					END
					ELSE IF Status <> 0 THEN  	  			(* Fehler ist aufgetreten	*)
						ProceedCopy := FALSE;
				END;
			END;

			IF Status = 0 THEN								(* Alles ist in Ordnung		*)
				SetFTime(TargetFile, FileTime);			(* Zeit des Ziels setzen	*)

			Close(SourceFile);								(* Dateien schlie·en			*)
			Close(TargetFile);
		END;
	END;

	IF ReadOnlyFile THEN										(* Quelle war nur lesbar	*)
		SetFAttr(SourceFile, Attrib OR ReadOnly);

	CopyFile := Status;										(* Status zurÅckgeben		*)
	FreeMem(Buffer, BufferSize);							(* Speicher freigeben		*)
END; (* CopyFile *)

(* Diese Funktion kopiert eine Datei in eine schon geîffnete Zieldatei *)
FUNCTION CopyToFile(Source : PathStr; VAR TargetFile : FILE;
						  BufferSize : WORD) : BYTE;
VAR SourceFile   : FILE;   	  							(* Quelldatei					*)
	 Buffer		  : POINTER;	  							(* Puffer nimmt Daten auf	*)
	 Status		  : BYTE;		  							(* Status einer Operation	*)
	 NewResult,													(* Resultat von BlockWrite	*)
	 Attrib,														(* Attribute einer Datei	*)
	 Result		  : WORD;		  							(* Resultat von I/O			*)
	 ProceedCopy,					  							(* Kopieren fortsetzen		*)
	 ReadOnlyFile : BOOLEAN;								(* Quelldatei nur lesbar	*)
BEGIN
	GetMem(Buffer, BufferSize);							(* Speicher fÅr Puffer		*)
	Assign(SourceFile, Source);							(* Quelldateiname zuweisen	*)

	IF GetFileType(Source) = RdOnlyFile THEN			(* Datei nur zum lesen		*)
	BEGIN
		ReadOnlyFile := TRUE;
		GetFAttr(SourceFile, Attrib);						(* Dateiattribute holen		*)
		SetFAttr(SourceFile, Attrib AND NOT ReadOnly);
	END
	ELSE ReadOnlyFile := FALSE;							(* Datei auch beschreibbar	*)

	Reset(SourceFile, 1);  									(* Datei zum Lesen îffnen	*)
	Status := IOResult;										(* I/O Status merken			*)

	IF Status = 0 THEN										(* Datei îffnen ist Ok		*)
	BEGIN
		ProceedCopy := TRUE;	  		 						(* Weiterkopieren ist Ok	*)

		WHILE ProceedCopy AND NOT Eof(SourceFile) DO (* Bis zum Dateiende lesen	*)
		BEGIN
			BlockRead(SourceFile, Buffer^, BufferSize, Result);
			Status := IOResult;	 		  			  		(* I/O Status merken			*)

			IF Status <> 0 THEN ProceedCopy := FALSE	(* Fehler ist aufgetreten	*)
			ELSE                 							(* Kein Fehler aufgetreten	*)
			BEGIN
				BlockWrite(TargetFile, Buffer^, Result, NewResult);
				Status := IOResult; 	  		 		  		(* I/O Status merken			*)

				IF NewResult <> Result THEN				(* Annahme Diskette voll	*)
				BEGIN
					Status := 8;								(* Insufficient Memory		*)
					ProceedCopy := FALSE;
				END
				ELSE IF Status <> 0 THEN  	  				(* Fehler ist aufgetreten	*)
					ProceedCopy := FALSE;
			END;
		END;

		Close(SourceFile);									(* Datei schlie·en			*)
	END;

	IF ReadOnlyFile THEN										(* Quelle war nur lesbar	*)
		SetFAttr(SourceFile, Attrib OR ReadOnly);

	CopyToFile := Status;  									(* Status zurÅckgeben		*)
	FreeMem(Buffer, BufferSize);							(* Speicher freigeben		*)
END; (* CopyToFile *)

END. (* FileInfo *)
