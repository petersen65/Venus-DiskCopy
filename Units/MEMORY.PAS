(**********************************************************************)
(* Programmname    : MEMORY.PAS V1.9  	               	             *)
(* Programmautor   : Michael Rippl               		                *)
(* Compiler        : Quick Pascal V1.0      		                      *)
(* Inhalt          : Routinen fÅr Speicherverwaltung von Datenblîcken *)
(* Bemerkung       : Verwendet fÅr Speicher auch EMS und Festplatte	 *)
(* Letzte énderung : 04-Sep-1990                                		 *)
(**********************************************************************)

UNIT Memory;

INTERFACE

CONST MemoryStatusOk   	   = 0;  	 					(* Alles in Ordnung			*)
		NotEnoughMemory  	   = 1;  	 					(* Nicht genug Speicher		*)
		IllegalBlockSize 	   = 2; 	 						(* UnzulÑssige Blockgrî·e	*)
		NoMemBlockAvailable  = 3; 							(* Kein Speicherblock da	*)
		MemoryExtError       = 4;    						(* Fehler vom EXT Speicher	*)
		MemoryEmsError		   = 5;							(* Fehler vom EMS Speicher	*)
		CannotWriteAfterRead = 6;      					(* Schreiben danach Lesen 	*)
		RamDiskIOError       = 7;							(* Fehler in der RAM Disk	*)
		HardDiskIOError      = 8;							(* Fehler bei der HardDisk	*)
		MemoryXmsError			= 9;							(* Fehler vom XMS Speicher	*)
		TempFilename 			= '~(C)_MR~.TMP';	 		(* TemporÑrer Dateiname		*)

TYPE UsedMemory = (UsingMainMem, UsingXmsMem, UsingExtMem, UsingEmsMem,
						 UsingRamDiskMem, UsingHardDiskMem);

VAR MemoryStatus   : BYTE;									(* Status der Memory Unit	*)
	 UsingMemory    : UsedMemory;							(* Nun benutzter Speicher	*)
	 UsedPartition  : CHAR;									(* Verwendete Partition		*)
	 RamDiskAvail,            								(* RAM Disk verfÅgbar		*)
	 HardDiskAvail	 : BOOLEAN; 			  				(* Festplatte verfÅgbar		*)

(* Diese Prozedur initialisiert die Memory Unit *)
PROCEDURE InitMemory(SetMainMem, SetXmsMem, SetExtMem, SetEmsMem, SetRamDisk,
							SetHardDisk, DeleteTemp : BOOLEAN; Partition : CHAR);

(* Diese Prozedur lîscht alle SpeichereintrÑge und initialisiert die Unit *)
PROCEDURE FreeMemory;

(* Diese Prozedur beendet die Arbeit mit der Memory Unit *)
PROCEDURE DelMemory;

(* Diese Prozedur bewahrt einen Speicherblock auf *)
PROCEDURE WriteToMemory(Buffer : POINTER; Size : WORD);

(* Diese Prozedur holt einen Speicherblock zurÅck *)
PROCEDURE ReadFromMemory(Buffer : POINTER);

IMPLEMENTATION

USES Dos, HiMem, Extended, Expanded, Disk, Fifo;	(* Units einbinden			*)

CONST MemoryMin 	 = 24576;  								(* Minimaler Hauptspeicher	*)

TYPE MemoryType  = (MainMem, XmsMem, ExtMem, EmsMem, RamDiskMem,
						  HardDiskMem);						(* Verschiedene Speicher	*)

	  MemoryBlock = RECORD									(* Typ vom Speicherblock	*)
							 MemSize : WORD; 					(* Grî·e vom Speicherblock	*)

							 CASE Typ : MemoryType OF 	  	(* Speicher unterscheiden	*)
								 MainMem :						(* Typ Hauptspeicher			*)
									 (MemBuffer : POINTER);	(* Zeiger Speicherblock		*)
								 XmsMem : 						(* Typ XMS Speicher			*)
									 (XmsOffset : LONGINT);	(* Offset im XMS Speicher	*)
								 ExtMem : 						(* Typ Extended Speicher 	*)
									 (ExtBuffer : LONGINT);	(* Adresse Speicherblock	*)
								 EmsMem, 						(* Typ Expanded Speicher 	*)
								 RamDiskMem,					(* Typ RAM Disk				*)
								 HardDiskMem : 		  		(* Typ Festplattenspeicher	*)
									 (ItemNr : WORD);			(* Nummer des Eintrags		*)
						 END;

VAR UseMainMem,												(* Verwende Hauptspeicher	*)
	 UseXmsMem,													(* Verwende XMS Speicher	*)
	 UseExtMem,													(* Verwende EXT Speicher	*)
	 UseEmsMem,													(* Verwende EMS Speicher	*)
	 UseHardDisk,												(* Verwende Festplatte		*)
	 UseRamDisk,												(* Verwende RAM Disk			*)
	 DeleteTmpFile, 											(* TemporÑre Datei lîschen	*)
	 WriteMemory   : BOOLEAN;								(* In Speicher schreiben	*)
	 MemoryHead    : pRing;									(* Fifo Liste vom Speicher	*)
	 HardDiskDrive,											(* Laufwerksnummer der HD 	*)
	 RamDiskDrive  : BYTE;									(* Laufwerksnummer der RD	*)
	 ActualExtMem,												(* Aktuelle Adresse im EXT	*)
	 ActualXmsOfs,												(* Aktueller Offset im XMS	*)
	 FrameMax,													(* Hîchste Frame-Adresse	*)
	 FrameOffset   : LONGINT;								(* Offset im EMS Frame		*)
	 XmsLargestMem,   										(* Grî·ter freier Block		*)
	 XmsTotalMem,												(* Totales freies XMS Mem	*)
	 XmsHandle,													(* Handle fÅr XMS Speicher	*)
	 EmsMemNr,  												(* Anzahl der EMS EintrÑge	*)
	 RamDiskNr,													(* Anzahl der RD EintrÑge	*)
	 HardDiskNr,												(* Anzahl der HD EintrÑge	*)
	 FrameSegment,        									(* Segment vom Frame			*)
	 AvailPages,												(* Anzahl gegebener Seiten	*)
	 ActualPages,          								  	(* Anzahl aktueller Seiten	*)
	 EmsHandle 		: WORD; 									(* Handle fÅr EMS Speicher	*)
	 HardDiskFile,        									(* Datei auf Festplatte		*)
	 RamDiskFile   : FILE;									(* Datei in RAM Disk			*)

(* Diese Prozedur initialisiert die Memory Unit *)
PROCEDURE InitMemory(SetMainMem, SetXmsMem, SetExtMem, SetEmsMem, SetRamDisk,
							SetHardDisk, DeleteTemp : BOOLEAN; Partition : CHAR);
VAR Drive        : CHAR;    							  	(* Laufwerksbuchstabe		*)
	 OneDiskType  : DiskType;								(* Typ eines Laufwerks		*)
	 LastHDSize,												(* Letzte Partitionsgrî·e	*)
	 LastRDSize   : LONGINT;  								(* Letzte RAM Disk Grî·e	*)
	 FramePointer : POINTER;								(* Zeiger auf EMS-Frame		*)
BEGIN
	RamDiskAvail := FALSE; 									(* Startwerte					*)
	HardDiskAvail := FALSE;
	EmsMemNr := 0;  											(* Keine EMS EintrÑge		*)
	RamDiskNr := 0;                                 (* Keine RD EintrÑge			*)
	HardDiskNr := 0;                                (* Keine HD EintrÑge			*)
	RamDiskDrive := 26;									  	(* Laufwerksbuchstabe 'Z'	*)
	HardDiskDrive := 26;                            (* Laufwerksbuchstabe 'Z'	*)
	ActualXmsOfs := 0;										(* Anfang eines XMS Blocks	*)
	UseMainMem := SetMainMem;
	UseXmsMem := SetXmsMem;
	UseExtMem := SetExtMem;
	UseEmsMem := SetEmsMem;
	UseRamDisk := SetRamDisk;
	UseHardDisk := SetHardDisk;
	DeleteTmpFile := DeleteTemp;							(* TemporÑre Datei lîschen	*)
	WriteMemory := TRUE;										(* Speicher schreiben Ok	*)

	IF UseRamDisk OR UseHardDisk THEN
	BEGIN
		LastRDSize := 0;
		LastHDSize := 0;
		Drive := 'C';	  										(* Ab Laufwerk C suchen		*)

		REPEAT 											  		(* Laufwerke durchsuchen	*)
			IF IsHardDisk(Drive) THEN						(* Harddisk oder Ramdisk	*)
			BEGIN
				OneDiskType := GetDiskType(Drive); 		(* Typ des Laufwerks			*)

				IF OneDiskType = HardDisk THEN  		  	(* Festplatte gefunden		*)
				BEGIN
					IF DiskFree(Ord(Drive) - Ord('A') + 1) > LastHDSize THEN
					BEGIN
						LastHDSize := DiskFree(Ord(Drive) - Ord('A') + 1);
						HardDiskDrive := Ord(Drive) - Ord('A') + 1;
						HardDiskAvail := TRUE;	 			(* Festplatte vorhanden		*)
					END;
				END
				ELSE 												(* RAM Disk gefunden			*)
				BEGIN
					IF DiskFree(Ord(Drive) - Ord('A') + 1) > LastRDSize THEN
					BEGIN
						LastRDSize := DiskFree(Ord(Drive) - Ord('A') + 1);
						RamDiskDrive := Ord(Drive) - Ord('A') + 1;
						RamDiskAvail := TRUE;	  			(* Festplatte vorhanden		*)
					END;
				END;
			END;

			Inc(Drive);											(* NÑchstes Laufwerk			*)
		UNTIL NOT DriveExist(Drive);						(* Keine Laufwerke mehr		*)

		IF Partition <> ' ' THEN	  		 				(* Partition vorgegeben		*)
		BEGIN
			IF IsHardDisk(Partition) THEN	 				(* Vorgabe ist Festplatte	*)
				HardDiskDrive := Ord(Partition) - Ord('A') + 1;
		END;
	END;

	IF EmsMemAvail AND UseEmsMem THEN 					(* EMS Speicher verwenden	*)
	BEGIN
		FramePointer := GetPageOfFrame(0);				(* Zeiger auf EMS-Frame		*)
		FrameOffset := 0;										(* Anfang des EMS-Frames	*)
		FrameSegment := Seg(FramePointer^); 			(* Segment des EMS-Frames	*)
		FrameMax := 0;											(* Startwert					*)
		AvailPages := NrOfAvailablePages;				(* VerfÅgbare EMS Seiten	*)
		ActualPages := AvailPages;

		IF AvailPages > 0 THEN    							(* Seiten sind vorhanden	*)
			AllocPages(AvailPages, EmsHandle); 		  	(* Alle EMS Seiten belegen	*)
	END;

	IF XmsMemAvail AND UseXmsMem THEN					(* XMS Speicher verwenden	*)
	BEGIN
		QueryFreeXms(XmsLargestMem, XmsTotalMem);		(* Freier XMS Speicher		*)

		IF XmsLargestMem > 0 THEN							(* Noch XMS Speicher da		*)
			AllocXmsBlock(XmsLargestMem, XmsHandle);
	END;

	IF HardDiskAvail AND UseHardDisk THEN				(* Festplatte verwenden		*)
		Assign(HardDiskFile, Chr(HardDiskDrive + 64) + ':\' + TempFilename);

	IF RamDiskAvail AND UseRamDisk THEN	  		 		(* RAM Disk verwenden		*)
		Assign(RamDiskFile, Chr(RamDiskDrive + 64) + ':\' + TempFilename);

	ActualExtMem := ExtMemStart;							(* Start vom EXT Speicher	*)
	MemoryStatus := MemoryStatusOk;					  	(* Alles in Ordnung			*)
	UsingMemory := UsingMainMem;							(* Benutze Hauptspeicher	*)
	UsedPartition := Chr(HardDiskDrive + ORD('A') - 1);
	CreateRing(MemoryHead);									(* Fifo Liste erzeugen		*)
END; (* InitMemory *)

(* Diese Prozedur lîscht alle SpeichereintrÑge und initialisiert die Unit *)
PROCEDURE FreeMemory;
VAR NewBlock : ^MemoryBlock;
BEGIN
	WHILE NOT RingIsEmpty(MemoryHead) DO				(* Speicherblock freigeben	*)
	BEGIN
		Pop(MemoryHead, POINTER(NewBlock));				(* Element aus Fifo Liste	*)

		WITH NewBlock^ DO
		BEGIN
			IF Typ = MainMem THEN	 			 			(* Block aus Hauptspeicher	*)
				FreeMem(MemBuffer, MemSize);	  			(* Hauptspeicher freigeben	*)
		END;

		Dispose(NewBlock);  		 							(* Speichereintrag lîschen	*)
	END;

	IF RamDiskNr > 0 THEN									(* Datei in RD verwendet	*)
	BEGIN
		Close(RamDiskFile);									(* Datei schlie·en			*)
		IF DeleteTmpFile THEN Erase(RamDiskFile);		(* Datei wieder lîschen		*)
	END;

	IF HardDiskNr > 0 THEN									(* Datei in HD verwendet	*)
	BEGIN
		Close(HardDiskFile);									(* Datei schlie·en			*)
		IF DeleteTmpFile THEN Erase(HardDiskFile);	(* Datei wieder lîschen		*)
	END;

	EmsMemNr := 0;  											(* Keine EMS EintrÑge		*)
	RamDiskNr := 0;                                 (* Keine RD EintrÑge			*)
	HardDiskNr := 0;                                (* Keine HD EintrÑge			*)
	WriteMemory := TRUE;										(* Speicher schreiben Ok	*)

	FrameOffset := 0;	 		  								(* Anfang des EMS-Frames	*)
	FrameMax := 0;	  	     									(* Startwert					*)
	ActualPages := AvailPages;

	ActualExtMem := ExtMemStart;							(* Start vom EXT Speicher	*)
	ActualXmsOfs := 0;										(* Anfang eines XMS Blocks	*)
	UsingMemory := UsingMainMem;							(* Benutze Hauptspeicher	*)
	MemoryStatus := MemoryStatusOk;					  	(* Alles in Ordnung			*)
END; (* FreeMemory *)

(* Diese Prozedur beendet die Arbeit mit der Memory Unit *)
PROCEDURE DelMemory;
BEGIN
	FreeMemory;													(* Speicher freigeben		*)
	DeleteRing(MemoryHead);	  		 				  		(* Fifo Liste lîschen		*)

	IF EmsMemAvail AND UseEmsMem AND (AvailPages > 0) THEN
		FreePages(EmsHandle);				 				(* EMS Speicher verwendet	*)

	IF XmsMemAvail AND UseXmsMem AND (XmsLargestMem > 0) THEN
		FreeXmsBlock(XmsHandle);							(* XMS Speicher verwendet	*)
END; (* DelMemory *)

(* Diese Prozedur bewahrt einen Speicherblock auf *)
PROCEDURE WriteToMemory(Buffer : POINTER; Size : WORD);
TYPE BufferArray = ARRAY [1..65520] OF BYTE;			(* Einfacher Pufferzugriff	*)
VAR NrOfDiskBytes,											(* öbertragene Bytes			*)
	 Counter        : WORD;
	 FrameFreeBytes : LONGINT;								(* Freie Bytes im Frame		*)
	 NewBlock    	 : ^MemoryBlock;
	 PtrToFrame     : POINTER; 							(* Zeiger in Frame hinein	*)
	 XmsMoveMem		 : XmsMove;								(* XMS Speicher kopieren	*)
BEGIN
	IF (Size > 65520) OR (Size = 0) THEN 				(* UnzulÑssige Blockgrî·e	*)
		MemoryStatus := IllegalBlockSize
	ELSE IF NOT WriteMemory THEN                    (* Schreiben nach lesen		*)
		MemoryStatus := CannotWriteAfterRead
	ELSE															(* Speicherblock Ok 			*)
	BEGIN
		IF UseMainMem AND (Size < MaxAvail - MemoryMin) THEN
		BEGIN														(* Dos-Speicher verwendbar	*)
			New(NewBlock);	  			 		  				(* Neuer Speichereintrag	*)

			WITH NewBlock^ DO
			BEGIN
				MemSize := Size;					  		 	(* Grî·e vom Speicherblock	*)
				Typ := MainMem;								(* Typ Hauptspeicher			*)
				GetMem(MemBuffer, Size);					(* Speicher reservieren		*)
				Move(Buffer^, MemBuffer^, Size);			(* Speicherblock kopieren	*)
			END;

			Push(MemoryHead, NewBlock);					(* In Fifo Liste merken		*)
			MemoryStatus := MemoryStatusOk; 				(* Alles in Ordnung			*)
			UsingMemory := UsingMainMem;					(* Benutze Hauptspeicher	*)
		END
		ELSE IF XmsMemAvail AND UseXmsMem AND			(* XMS Speicher verwendbar	*)
			(XmsLargestMem > 0) AND
			((LONGINT(XmsLargestMem) SHL 10) - ActualXmsOfs >= Size) THEN
		BEGIN
			WITH XmsMoveMem DO								(* XMS Struktur ausfÅllen	*)
			BEGIN
				Length := Size;								(* Grî·e des Quellpuffers 	*)
				SrcHandle := $0000;							(* Quelle Segment:Offset	*)
				LongWord(SrcOffset).LowWord := Ofs(Buffer^);
				LongWord(SrcOffset).HighWord := Seg(Buffer^);

				TarHandle := XmsHandle;						(* XMS Speicherhandle		*)
				TarOffset := ActualXmsOfs;					(* Offset in Zielspeicher	*)
			END;

			MoveXmsBlock(XmsMoveMem);						(* Im XMS Speicher ablegen	*)

			IF XmsMemStatus <> XmsMemOk THEN				(* Fehler im XMS Speicher	*)
				MemoryStatus := MemoryXmsError
			ELSE
			BEGIN
				New(NewBlock);	  		 		  				(* Neuer Speichereintrag	*)

				WITH NewBlock^ DO
				BEGIN
					MemSize := Size;		  		  		 	(* Grî·e vom Speicherblock	*)
					Typ := XmsMem;			  					(* Typ XMS Speicher			*)
					XmsOffset := ActualXmsOfs;				(* Speicherblock im XMS		*)
				END;

				Inc(ActualXmsOfs, Size);					(* Zeigt auf neuen Bereich	*)
				Push(MemoryHead, NewBlock);	 			(* In Fifo Liste merken		*)
				MemoryStatus := MemoryStatusOk;			(* Alles in Ordnung			*)
			END;

			UsingMemory := UsingXmsMem;  			 		(* Benutze XMS Speicher		*)
		END
		ELSE IF EmsMemAvail AND UseEmsMem AND			(* EMS Speicher verwendbar	*)
			(AvailPages > 0) AND   							(* Seiten sind vorhanden	*)
			(Size <= (LONGINT(ActualPages) SHL 14) + FrameMax - FrameOffset) THEN
		BEGIN
			New(NewBlock);										(* Neuer Speichereintrag	*)

			WITH NewBlock^ DO
			BEGIN
				MemSize := Size;	  							(* Grî·e vom Speicherblock	*)
				Typ := EmsMem;	  			  					(* Typ EMS Speicher			*)
				ItemNr := EmsMemNr + 1;	 					(* Nummer des Eintrages		*)
			END;

			FrameFreeBytes := FrameMax - FrameOffset;	(* Freie Bytes im Frame		*)
			PtrToFrame := Ptr(FrameSegment, FrameOffset);

			IF Size <= FrameFreeBytes THEN				(* Bereich pa·t auf Frame	*)
			BEGIN
				Move(Buffer^, PtrToFrame^, Size); 	 	(* Block in Frame kopieren	*)
				Inc(FrameOffset, Size);						(* Neuer Block im Frame		*)
			END
			ELSE													(* Neue Seiten anfordern	*)
			BEGIN
				Move(Buffer^, PtrToFrame^, FrameFreeBytes);
				Dec(Size, FrameFreeBytes);					(* Zu kopierender Rest		*)

				IF ActualPages < 4 THEN						(* VerfÅgbare Seiten			*)
					Counter := ActualPages
				ELSE Counter := 4;

				FrameMax := LONGINT(Counter) SHL 14; 	(* Neue Frame-Obergrenze	*)

				REPEAT            							(* Neue Seiten reservieren	*)
					Dec(ActualPages);
					Dec(Counter);
					SetMapping(EmsHandle, ActualPages, Counter);
				UNTIL Counter = 0;

				PtrToFrame := Ptr(FrameSegment, 0);
				Move(BufferArray(Buffer^)[FrameFreeBytes + 1], PtrToFrame^, Size);
				FrameOffset := Size;							(* Belegter Teil im Frame	*)
			END;

			IF EmsMemStatus <> EmsMemoryOk THEN      	(* Fehler beim EMS			*)
			BEGIN
				Dispose(NewBlock);							(* Eintrag ÅberflÅssig		*)
				MemoryStatus := MemoryEmsError			(* Fehler vom EMS Speicher	*)
			END
			ELSE 													(* Alles in Ordnung			*)
			BEGIN
				MemoryStatus := MemoryStatusOk;		  	(* Alles in Ordnung			*)
				Inc(EmsMemNr);						  			(* Neuer EMS Eintrag			*)
				Push(MemoryHead, NewBlock);	  			(* In Fifo Liste merken		*)
			END;

			UsingMemory := UsingEmsMem;  			 		(* Benutze EMS Speicher		*)
		END
		ELSE IF ExtMemAvail AND UseExtMem AND			(* EXT Speicher verwendbar	*)
			(Size <= ExtMemStart + (LONGINT(ExtMemSize) SHL 10) -
			ActualExtMem) THEN
		BEGIN
			MemoryWrite(Buffer, ActualExtMem, Size);	(* Speicherblock kopieren	*)

			IF ExtMemStatus <> ExtMemoryOk THEN			(* Fehler im EXT Speicher	*)
				MemoryStatus := MemoryExtError
			ELSE
			BEGIN
				New(NewBlock);	  		 		  				(* Neuer Speichereintrag	*)

				WITH NewBlock^ DO
				BEGIN
					MemSize := Size;		  		  		 	(* Grî·e vom Speicherblock	*)
					Typ := ExtMem;			  					(* Typ Extended Speicher	*)
					ExtBuffer := ActualExtMem;				(* Speicherblock im EXT		*)
				END;

				Inc(ActualExtMem, Size);					(* Zeigt auf neuen Bereich	*)
				Push(MemoryHead, NewBlock);	 			(* In Fifo Liste merken		*)
				MemoryStatus := MemoryStatusOk;			(* Alles in Ordnung			*)
			END;

			UsingMemory := UsingExtMem;  			 		(* Benutze EXT Speicher		*)
		END
		ELSE IF RamDiskAvail AND UseRamDisk AND 	   (* Ram Disk verwendbar		*)
			(DiskFree(RamDiskDrive) > LONGINT(Size) + 1024) THEN
		BEGIN
			(*$I-*)												(* I/O öberprÅfung aus		*)
			IF RamDiskNr = 0 THEN							(* Erster Eintrag fÅr RD	*)
				Rewrite(RamDiskFile, 1);					(* Datei îffnen 				*)

			BlockWrite(RamDiskFile, Buffer^, Size, NrOfDiskBytes);
			(*$I+*)												(* I/O öberprÅfung an		*)

			IF (IOResult <> 0) OR (Size <> NrOfDiskBytes) THEN
				MemoryStatus := RamDiskIOError			(* Fehler bei RD I/O			*)
			ELSE													(* Alles in Ordnung			*)
			BEGIN
				Inc(RamDiskNr);								(* Neuer RD Eintrag			*)
				New(NewBlock);	  		 						(* Neuer Speichereintrag	*)

				WITH NewBlock^ DO
				BEGIN
					MemSize := Size;	  		 				(* Grî·e vom Speicherblock	*)
					Typ := RamDiskMem; 		 				(* Typ RAM Disk Speicher	*)
					ItemNr := RamDiskNr;		  				(* Nummer des Eintrages		*)
				END;

				Push(MemoryHead, NewBlock); 				(* In Fifo Liste merken		*)
				MemoryStatus := MemoryStatusOk		  	(* Alles in Ordnung			*)
			END;

			UsingMemory := UsingRamDiskMem; 	 		  	(* Benutze RAM Disk			*)
		END
		ELSE IF HardDiskAvail AND UseHardDisk AND    (* Festplatte verwendbar	*)
			(DiskFree(HardDiskDrive) > LONGINT(Size) + 1024) THEN
		BEGIN
			(*$I-*)												(* I/O öberprÅfung aus		*)
			IF HardDiskNr = 0 THEN							(* Erster Eintrag fÅr HD	*)
				Rewrite(HardDiskFile, 1);					(* Datei îffnen 				*)

			BlockWrite(HardDiskFile, Buffer^, Size, NrOfDiskBytes);
			(*$I+*)												(* I/O öberprÅfung an		*)

			IF (IOResult <> 0) OR (Size <> NrOfDiskBytes) THEN
				MemoryStatus := HardDiskIOError			(* Fehler bei HD I/O			*)
			ELSE													(* Alles in Ordnung			*)
			BEGIN
				Inc(HardDiskNr);								(* Neuer HD Eintrag			*)
				New(NewBlock);	  		 						(* Neuer Speichereintrag	*)

				WITH NewBlock^ DO
				BEGIN
					MemSize := Size;	  		 				(* Grî·e vom Speicherblock	*)
					Typ := HardDiskMem; 		 				(* Typ HardDisk Speicher	*)
					ItemNr := HardDiskNr;  	  				(* Nummer des Eintrages		*)
				END;

				Push(MemoryHead, NewBlock); 				(* In Fifo Liste merken		*)
				MemoryStatus := MemoryStatusOk		  	(* Alles in Ordnung			*)
			END;

			UsingMemory := UsingHardDiskMem;   		 	(* Benutze Festplatte		*)
		END
		ELSE MemoryStatus := NotEnoughMemory; 			(* Alle Speicher sind voll	*)
	END;
END; (* WriteToMemory *)

(* Diese Prozedur holt einen Speicherblock zurÅck *)
PROCEDURE ReadFromMemory(Buffer : POINTER);
TYPE BufferArray = ARRAY [1..65520] OF BYTE;			(* Einfacher Pufferzugriff	*)
VAR NrOfDiskBytes,											(* öbertragene Bytes			*)
	 Size,														(* Grî·e vom Speicherblock	*)
	 Counter        : WORD;
	 FrameFreeBytes : LONGINT;								(* Freie Bytes im Frame		*)
	 OldBlock 		 : ^MemoryBlock;
	 PtrToFrame     : POINTER; 							(* Zeiger in Frame hinein	*)
	 XmsMoveMem		 : XmsMove;								(* XMS Speicher kopieren	*)
BEGIN
	IF NOT RingIsEmpty(MemoryHead) THEN					(* Speicherblock vorhanden	*)
	BEGIN
		WriteMemory := FALSE;								(* Schreiben nicht erlaubt *)
		Pop(MemoryHead, POINTER(OldBlock));				(* Aus Fifo Liste holen		*)

		WITH OldBlock^ DO
		BEGIN
			CASE Typ OF	  				 						(* Typen unterscheiden		*)
				MainMem :										(* Hauptspeicher				*)
				BEGIN
					Move(MemBuffer^, Buffer^, MemSize);	(* Speicherblock kopieren	*)
					MemoryStatus := MemoryStatusOk;		(* Alles in Ordnung			*)
					UsingMemory := UsingMainMem;			(* Benutze Hauptspeicher	*)
				END;

				XmsMem : 										(* XMS Speicher 				*)
				BEGIN
					WITH XmsMoveMem DO				  		(* XMS Struktur ausfÅllen	*)
					BEGIN
						Length := MemSize;  			  		(* Grî·e des XMS Blocks 	*)
						SrcHandle := XmsHandle;		  		(* XMS Speicherhandle		*)
						SrcOffset := XmsOffset;	 	 		(* Offset in Quellspeicher	*)

						TarHandle := $0000;					(* Ziel Segment:Offset		*)
						LongWord(TarOffset).LowWord := Ofs(Buffer^);
						LongWord(TarOffset).HighWord := Seg(Buffer^);
					END;

					MoveXmsBlock(XmsMoveMem);		  		(* Im XMS Speicher ablegen	*)

					IF XmsMemStatus <> XmsMemOk THEN		(* Fehler im XMS Speicher	*)
						MemoryStatus := MemoryXmsError
					ELSE MemoryStatus := MemoryStatusOk;(* Alles in Ordnung			*)

					UsingMemory := UsingXmsMem;  	 		(* Benutze XMS Speicher		*)
				END;

				ExtMem :											(* Extended Speicher			*)
				BEGIN
					MemoryRead(ExtBuffer, Buffer, MemSize);

					IF ExtMemStatus <> ExtMemoryOk THEN	(* Fehler im EXT Speicher	*)
						MemoryStatus := MemoryExtError
					ELSE MemoryStatus := MemoryStatusOk;(* Alles in Ordnung			*)

					UsingMemory := UsingExtMem;  	 		(* Benutze EXT Speicher		*)
				END;

				EmsMem : 										(* LIM EMS Speicher			*)
				BEGIN
					IF ItemNr = 1 THEN						(* Erster EMS Eintrag		*)
					BEGIN
						FrameOffset := 0;						(* Anfang vom EMS-Frame		*)
						FrameMax := 0;							(* Startwert					*)
						ActualPages := AvailPages;			(* Jetzt von vorn anfangen	*)
					END;

					FrameFreeBytes := FrameMax - FrameOffset;
					PtrToFrame := Ptr(FrameSegment, FrameOffset);
					Size := MemSize;							(* Grî·e vom Speicherblock	*)

					IF Size <= FrameFreeBytes THEN		(* Ganzer Block im Frame	*)
					BEGIN
						Move(PtrToFrame^, Buffer^, Size);(* Block kopieren				*)
						Inc(FrameOffset, Size);				(* NÑchster Block im Frame	*)
					END
					ELSE	 										(* Belegte Seiten holen		*)
					BEGIN
						Move(PtrToFrame^, Buffer^, FrameFreeBytes);
						Dec(Size, FrameFreeBytes);	 		(* Zu kopierender Rest		*)

						IF ActualPages < 4 THEN	 			(* Belegte Seiten	 		  	*)
							Counter := ActualPages
						ELSE Counter := 4;
																	(* Neue Frame-Obergrenze	*)
						FrameMax := LONGINT(Counter) SHL 14;

						REPEAT        							(* Belegte Seiten holen		*)
							Dec(ActualPages);
							Dec(Counter);
							SetMapping(EmsHandle, ActualPages, Counter);
						UNTIL Counter = 0;

						PtrToFrame := Ptr(FrameSegment, 0);

						Move(PtrToFrame^, BufferArray(Buffer^)[FrameFreeBytes + 1],
							  Size);								(* Rest vom Block kopieren	*)

						FrameOffset := Size;					(* Belegter Teil im Frame	*)
					END;

					IF EmsMemStatus = EmsMemoryOk THEN  (* EMS Status in Ordnung	*)
						MemoryStatus := MemoryStatusOk	(* Alles in Ordnung			*)
					ELSE MemoryStatus := MemoryEmsError;(* Fehler vom EMS Speicher	*)

					UsingMemory := UsingEmsMem;			(* Benutze EMS Speicher		*)
				END;

				RamDiskMem : 									(* RAM Disk Speicher  		*)
				BEGIN
					(*$I-*)	  									(* I/O öberprÅfung aus		*)
					IF ItemNr = 1 THEN						(* Erster RD Eintrag	 	   *)
						Reset(RamDiskFile, 1);				(* Datei zurÅcksetzen    	*)

					BlockRead(RamDiskFile, Buffer^, MemSize, NrOfDiskBytes);
					(*$I+*)	  									(* I/O öberprÅfung an		*)

					IF (IOResult <> 0) OR (MemSize <> NrOfDiskBytes) THEN
						MemoryStatus := RamDiskIOError 	(* Fehler bei RD I/O			*)
					ELSE MemoryStatus := MemoryStatusOk;(* Alles in Ordnung			*)

					UsingMemory := UsingRamDiskMem;		(* Benutze RAM Disk			*)
				END;

				HardDiskMem : 									(* Festplattenspeicher		*)
				BEGIN
					(*$I-*)	  									(* I/O öberprÅfung aus		*)
					IF ItemNr = 1 THEN						(* Erster HD Eintrag	 	   *)
						Reset(HardDiskFile, 1);				(* Datei zurÅcksetzen    	*)

					BlockRead(HardDiskFile, Buffer^, MemSize, NrOfDiskBytes);
					(*$I+*)	  									(* I/O öberprÅfung an		*)

					IF (IOResult <> 0) OR (MemSize <> NrOfDiskBytes) THEN
						MemoryStatus := HardDiskIOError 	(* Fehler bei HD I/O			*)
					ELSE MemoryStatus := MemoryStatusOk;(* Alles in Ordnung			*)

					UsingMemory := UsingHardDiskMem;		(* Benutze Festplatte		*)
				END;
			END;
		END;

		Push(MemoryHead, OldBlock);						(* An Listenende anfÅgen	*)
	END
	ELSE MemoryStatus := NoMemBlockAvailable;	  		(* Kein Speicherblock da	*)
END; (* ReadFromMemory *)

END. (* Memory *)
