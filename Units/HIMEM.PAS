(***************************************************************************)
(* Programmname    : HIMEM.PAS V1.1   	                	         			*)
(* Programmautor   : Michael Rippl                                			*)
(* Compiler        : Quick Pascal V1.0                            			*)
(* Inhalt          : Routinen fÅr Zugriff auf XMS V2.0 Memory 					*)
(* Bemerkung       : Mu· wegen EMS Konflikten manuell initialisiert werden *)
(* Letzte énderung : 05-Sep-1990                              					*)
(***************************************************************************)

UNIT HiMem;

INTERFACE

TYPE LongWord = RECORD										(* Typ eines 32-Bit Wortes	*)
						 LowWord,								(* Bits 0 bis 15				*)
						 HighWord : WORD;						(* Bits 16 bis 31				*)
					 END;

	  XmsMove  = RECORD 										(* Typ der Move-Struktur 	*)
						 Length 	  : LONGINT;  				(* BlocklÑnge in Bytes		*)
						 SrcHandle : WORD;     				(* Handle vom Quellblock	*)
						 SrcOffset : LONGINT;  	         (* 32-Bit Quelladresse		*)
						 TarHandle : WORD;	  				(* Handle vom Zielblock		*)
						 TarOffset : LONGINT;  				(* 32-Bit Zieladresse		*)
					 END;

CONST XmsMemOk 	  		 = $00; 							(* Status alles in Ordnung	*)
		FctNotImplemented  = $80; 							(* Funktion nicht da			*)
		VDiskDetected 		 = $81;							(* RamDisk vorhanden			*)
		A20ErrorOccured	 = $82;							(* A20 Fehler aufgetreten	*)
		HmaDoesNotExist	 = $90;							(* Kein HMA vorhanden		*)
		HmaAlreadyInUse    = $91;							(* HMA schon in Benutzung	*)
		DXLessThanHmaMin   = $92;							(* DX-Grî·e kleiner HMAMIN	*)
		HmaNotAllocated	 = $93;							(* HMA war nicht belegt		*)
		A20IsStillEnabled  = $94;							(* A20 Line ist noch an		*)
		AllXmsAllocated    = $A0;							(* XMS Speicher belegt		*)
		AllXmsHandlesUsed	 = $A1;							(* Alle XMS Handles weg	 	*)
		HandleIsInvalid	 = $A2;							(* UnzulÑssiges Handle		*)
		InvalidSrcHandle   = $A3;                    (* Quell-Handle unzulÑssig	*)
		InvalidSrcOffset   = $A4;							(* Quell-Offset unzulÑssig	*)
		InvalidTarHandle   = $A5;							(* Ziel-Handle unzulÑssig	*)
		InvalidTarOffset   = $A6;							(* Ziel-Offset unzulÑssig	*)
		InvalidLength		 = $A7;							(* UnzulÑssige BlocklÑnge	*)
		InvalidMoveOverlap = $A8;							(* Move-öberlappung falsch	*)
		ParityErrorOccured = $A9;							(* Parity Fehler 				*)
		BlockIsNotLocked	 = $AA;							(* Block nicht gelock't 	*)
		HandleIsLocked 	 = $AB;							(* Handle ist geschÅtzt		*)
		LockCountOverflow  = $AC;							(* Lock-ZÑhler öberlauf		*)
		LockFailed			 = $AD;							(* Lock fehlgeschlagen		*)
		SmallerUmbAvail	 = $B0;							(* Kleinerer UMB vorhanden	*)
		NoUmbAvail			 = $B1;							(* Kein UMB vorhanden		*)
		InvalidUmbSegment	 = $B2;							(* Falsches UMB Segment		*)

VAR XmsMemAvail  : BOOLEAN;                        (* XMS Speicher da      	*)
	 XmsMemSize   : WORD;									(* Grî·e vom XMS Speicher	*)
	 XmsMemStatus : BYTE;									(* Status des Speichers		*)

(* Diese Prozedur initialisiert die HiMem Unit *)
PROCEDURE InitXms;

(* Diese Prozedur ermittelt die Versionsnummer des XMS Treibers *)
PROCEDURE GetXmsVersion(VAR VerHigh, VerLow : BYTE);

(* Diese Prozedur ermittelt die interne Revision des XMS Treibers *)
PROCEDURE GetInternRevision(VAR RevHigh, RevLow : BYTE);

(* Diese Prozedur versucht den HiMem-Bereich zu reservieren *)
PROCEDURE RequestHighMemArea(Size : WORD);

(* Diese Prozedur gibt den HiMem-Bereich wieder frei *)
PROCEDURE ReleaseHighMemArea;

(* Diese Prozedur schaltet die A20 Line an *)
PROCEDURE GlobalEnableA20;

(* Diese Prozedur schaltet die A20 Line aus *)
PROCEDURE GlobalDisableA20;

(* Diese Prozedur schaltet die A20 Line an (lokal) *)
PROCEDURE LocalEnableA20;

(* Diese Prozedur schaltet die A20 Line aus (lokal) *)
PROCEDURE LocalDisableA20;

(* Diese Funktion prÅft, ob die A20 Line physikalisch angeschaltet ist *)
FUNCTION QueryA20 : BOOLEAN;

(* Diese Prozedur holt Informationen Åber den verfÅgbaren XMS-Speicher *)
PROCEDURE QueryFreeXms(VAR LargestFree, TotalAmount : WORD);

(* Diese Prozedur belegt einen XMS Speicherblock *)
PROCEDURE AllocXmsBlock(Size : WORD; VAR Handle : WORD);

(* Diese Prozedur gibt einen XMS Speicherblock wieder frei *)
PROCEDURE FreeXmsBlock(Handle : WORD);

(* Diese Prozedur verschiebt einen Speicherblock *)
PROCEDURE MoveXmsBlock(MemBlock : XmsMove);

(* Diese Prozedur lock't einen Speicherblock *)
PROCEDURE LockXmsBlock(Handle : WORD; VAR BaseAddress : LONGINT);

(* Diese Prozedur entfernt einen Lock von einem Speicherblock *)
PROCEDURE UnlockXmsBlock(Handle : WORD);

(* Diese Prozedur holt erweiterte Informationen Åber ein Handle *)
PROCEDURE GetHandleInfo(Handle : WORD; VAR LockCount, FreeHandles : BYTE;
								VAR BlockLength : WORD);

(* Diese Prozedur Ñndert die Grî·e eines Speicherblocks *)
PROCEDURE ReAllocXmsBlock(Handle, NewSize : WORD);

(* Diese Prozedur belegt einen Upper Memory Block fÅr den Aufrufer *)
PROCEDURE RequestUpperMemBlock(Paragraphs : WORD; VAR Segment, Size : WORD);

(* Diese Prozedur gibt einen Upper Memory Block wieder frei *)
PROCEDURE ReleaseUpperMemBlock(Segment : WORD);

IMPLEMENTATION

USES Dos;														(* Units einbinden			*)

TYPE Address = RECORD										(* Far-Adresse					*)
						Offset,									(* Offsetanteil 				*)
						Segment : WORD;						(* Segmentanteil				*)
					END;

VAR XmsControl  : Address;									(* XMS Basisadresse			*)
	 XmsRegs     : REGISTERS; 								(* RegisterÅbergabe an XMS	*)
	 LargestFree : WORD;  									(* Grî·ter freier Block		*)

(*$F+ Diese Prozedur ruft die Basisfunktion des XMS-Treibers auf *)
PROCEDURE CallXMS; EXTERNAL; (*$F-*)
(*$L HiMem.Obj *)

(* Diese Prozedur ermittelt die Versionsnummer des XMS Treibers *)
PROCEDURE GetXmsVersion(VAR VerHigh, VerLow : BYTE);
BEGIN
	XmsRegs.AH := $00;  										(* XMS Version ermitteln	*)
	CallXMS;														(* XMS Treiber aufrufen		*)

	VerHigh := XmsRegs.AH;	  								(* Stellen vor dem Punkt	*)
	VerLow := XmsRegs.AL;	  								(* Stellen nach dem Punkt	*)
END; (* GetXmsVersion *)

(* Diese Prozedur ermittelt die interne Revision des XMS Treibers *)
PROCEDURE GetInternRevision(VAR RevHigh, RevLow : BYTE);
BEGIN
	XmsRegs.AH := $00;  										(* XMS Version ermitteln	*)
	CallXMS;														(* XMS Treiber aufrufen		*)

	RevHigh := XmsRegs.BH;	  								(* Stellen vor dem Punkt	*)
	RevLow := XmsRegs.BL;	  								(* Stellen nach dem Punkt	*)
END; (* GetInternRevision *)

(* Diese Prozedur versucht den HiMem-Bereich zu reservieren *)
PROCEDURE RequestHighMemArea(Size : WORD);
BEGIN
	XmsRegs.AH := $01;										(* HiMem-Bereich belegen	*)
	XmsRegs.DX := Size;										(* Grî·e des Bereichs		*)
	CallXMS;														(* XMS Treiber aufrufen		*)

	IF XmsRegs.AX = $0001 THEN XmsMemStatus := XmsMemOk
	ELSE XmsMemStatus := XmsRegs.BL;						(* Fehlerstatus vermerken 	*)
END; (* RequestHighMemArea *)

(* Diese Prozedur gibt den HiMem-Bereich wieder frei *)
PROCEDURE ReleaseHighMemArea;
BEGIN
	XmsRegs.AH := $02;										(* HiMem-Bereich freigeben	*)
	CallXMS;														(* XMS Treiber aufrufen		*)

	IF XmsRegs.AX = $0001 THEN XmsMemStatus := XmsMemOk
	ELSE XmsMemStatus := XmsRegs.BL;						(* Fehlerstatus vermerken 	*)
END; (* ReleaseHighMemArea *)

(* Diese Prozedur schaltet die A20 Line an *)
PROCEDURE GlobalEnableA20;
BEGIN
	XmsRegs.AH := $03;										(* A20 Line ermîglichen		*)
	CallXMS;														(* XMS Treiber aufrufen		*)

	IF XmsRegs.AX = $0001 THEN XmsMemStatus := XmsMemOk
	ELSE XmsMemStatus := XmsRegs.BL;						(* Fehlerstatus vermerken 	*)
END; (* GlobalEnableA20 *)

(* Diese Prozedur schaltet die A20 Line aus *)
PROCEDURE GlobalDisableA20;
BEGIN
	XmsRegs.AH := $04;										(* A20 Line ausschalten		*)
	CallXMS;														(* XMS Treiber aufrufen		*)

	IF XmsRegs.AX = $0001 THEN XmsMemStatus := XmsMemOk
	ELSE XmsMemStatus := XmsRegs.BL;						(* Fehlerstatus vermerken 	*)
END; (* GlobalDisableA20 *)

(* Diese Prozedur schaltet die A20 Line an (lokal) *)
PROCEDURE LocalEnableA20;
BEGIN
	XmsRegs.AH := $05;										(* A20 Line ermîglichen		*)
	CallXMS;														(* XMS Treiber aufrufen		*)

	IF XmsRegs.AX = $0001 THEN XmsMemStatus := XmsMemOk
	ELSE XmsMemStatus := XmsRegs.BL;						(* Fehlerstatus vermerken 	*)
END; (* LocalEnableA20 *)

(* Diese Prozedur schaltet die A20 Line aus (lokal) *)
PROCEDURE LocalDisableA20;
BEGIN
	XmsRegs.AH := $06;										(* A20 Line ausschalten		*)
	CallXMS;														(* XMS Treiber aufrufen		*)

	IF XmsRegs.AX = $0001 THEN XmsMemStatus := XmsMemOk
	ELSE XmsMemStatus := XmsRegs.BL;						(* Fehlerstatus vermerken 	*)
END; (* LocalDisableA20 *)

(* Diese Funktion prÅft, ob die A20 Line physikalisch angeschaltet ist *)
FUNCTION QueryA20 : BOOLEAN;
BEGIN
	XmsRegs.AH := $07;										(* A20 Line ÅberprÅfen		*)
	CallXMS;														(* XMS Treiber aufrufen		*)

	QueryA20 := XmsRegs.AX = $0001;						(* Status zurÅckgeben		*)
	XmsMemStatus := XmsRegs.BL;							(* Fehlerstatus vermerken 	*)
END; (* QueryA20 *)

(* Diese Prozedur holt Informationen Åber den verfÅgbaren XMS-Speicher *)
PROCEDURE QueryFreeXms(VAR LargestFree, TotalAmount : WORD);
BEGIN
	XmsRegs.AH := $08;										(* XMS Speicherinformation	*)
	CallXMS;														(* XMS Treiber aufrufen		*)

	LargestFree := XmsRegs.AX;								(* Grî·ter freier Block		*)
	TotalAmount := XmsRegs.DX;								(* Gesamtspeicher frei		*)
	XmsMemStatus := XmsRegs.BL;							(* Fehlerstatus vermerken 	*)
END; (* QueryFreeXms *)

(* Diese Prozedur belegt einen XMS Speicherblock *)
PROCEDURE AllocXmsBlock(Size : WORD; VAR Handle : WORD);
BEGIN
	XmsRegs.AH := $09;										(* XMS Speicher belegen		*)
	XmsRegs.DX := Size;										(* Grî·e vom Speicherblock	*)
	CallXMS;														(* XMS Treiber aufrufen		*)

	Handle := XmsRegs.DX;									(* Nummer des Handles		*)

	IF XmsRegs.AX = $0001 THEN XmsMemStatus := XmsMemOk
	ELSE XmsMemStatus := XmsRegs.BL;						(* Fehlerstatus vermerken 	*)
END; (* AllocXmsBlock *)

(* Diese Prozedur gibt einen XMS Speicherblock wieder frei *)
PROCEDURE FreeXmsBlock(Handle : WORD);
BEGIN
	XmsRegs.AH := $0A;										(* XMS Speicher freigeben 	*)
	XmsRegs.DX := Handle;									(* Handle des Blocks			*)
	CallXMS;														(* XMS Treiber aufrufen		*)

	IF XmsRegs.AX = $0001 THEN XmsMemStatus := XmsMemOk
	ELSE XmsMemStatus := XmsRegs.BL;						(* Fehlerstatus vermerken 	*)
END; (* FreeXmsBlock *)

(* Diese Prozedur verschiebt einen Speicherblock *)
PROCEDURE MoveXmsBlock(MemBlock : XmsMove);
BEGIN
	XmsRegs.AH := $0B;										(* XMS Block kopieren	 	*)
	XmsRegs.DS := Seg(MemBlock);							(* Block-Segmentadresse 	*)
	XmsRegs.SI := Ofs(MemBlock);							(* Block-Offsetadresse		*)
	CallXMS;														(* XMS Treiber aufrufen		*)

	IF XmsRegs.AX = $0001 THEN XmsMemStatus := XmsMemOk
	ELSE XmsMemStatus := XmsRegs.BL;						(* Fehlerstatus vermerken 	*)
END; (* MoveXmsBlock *)

(* Diese Prozedur lock't einen Speicherblock *)
PROCEDURE LockXmsBlock(Handle : WORD; VAR BaseAddress : LONGINT);
BEGIN
	XmsRegs.AH := $0C;										(* XMS Block festmachen 	*)
	XmsRegs.DX := Handle;									(* Handle des Blocks			*)
	CallXMS;														(* XMS Treiber aufrufen		*)

	LongWord(BaseAddress).LowWord := XmsRegs.DX;		(* Bits 0-15 der Adresse	*)
	LongWord(BaseAddress).HighWord := XmsRegs.BX;	(* Bits 16-31 der Adresse	*)

	IF XmsRegs.AX = $0001 THEN XmsMemStatus := XmsMemOk
	ELSE XmsMemStatus := XmsRegs.BL;						(* Fehlerstatus vermerken 	*)
END; (* LockXmsBlock *)

(* Diese Prozedur entfernt einen Lock von einem Speicherblock *)
PROCEDURE UnlockXmsBlock(Handle : WORD);
BEGIN
	XmsRegs.AH := $0D;										(* XMS Block freimachen 	*)
	XmsRegs.DX := Handle;									(* Handle des Blocks			*)
	CallXMS;														(* XMS Treiber aufrufen		*)

	IF XmsRegs.AX = $0001 THEN XmsMemStatus := XmsMemOk
	ELSE XmsMemStatus := XmsRegs.BL;						(* Fehlerstatus vermerken 	*)
END; (* UnlockXmsBlock *)

(* Diese Prozedur holt erweiterte Informationen Åber ein Handle *)
PROCEDURE GetHandleInfo(Handle : WORD; VAR LockCount, FreeHandles : BYTE;
								VAR BlockLength : WORD);
BEGIN
	XmsRegs.AH := $0E;										(* XMS Blockinfo holen 		*)
	XmsRegs.DX := Handle;									(* Handle des Blocks			*)
	CallXMS;														(* XMS Treiber aufrufen		*)

	LockCount := XmsRegs.BH;  								(* Lock's auf dem Block		*)
	FreeHandles := XmsRegs.BL;								(* Freie Handles im System	*)
	BlockLength := XmsRegs.DX;								(* BlocklÑnge in KB			*)

	IF XmsRegs.AX = $0001 THEN XmsMemStatus := XmsMemOk
	ELSE XmsMemStatus := XmsRegs.BL;						(* Fehlerstatus vermerken 	*)
END; (* GetHandleInfo *)

(* Diese Prozedur Ñndert die Grî·e eines Speicherblocks *)
PROCEDURE ReAllocXmsBlock(Handle, NewSize : WORD);
BEGIN
	XmsRegs.AH := $0F;										(* XMS Blockgrî·e Ñndern 	*)
	XmsRegs.DX := Handle;									(* Handle des Blocks			*)
	XmsRegs.BX := NewSize;									(* Neue Grî·e des Blocks	*)
	CallXMS;														(* XMS Treiber aufrufen		*)

	IF XmsRegs.AX = $0001 THEN XmsMemStatus := XmsMemOk
	ELSE XmsMemStatus := XmsRegs.BL;						(* Fehlerstatus vermerken 	*)
END; (* ReAllocXmsBlock *)

(* Diese Prozedur belegt einen Upper Memory Block fÅr den Aufrufer *)
PROCEDURE RequestUpperMemBlock(Paragraphs : WORD; VAR Segment, Size : WORD);
BEGIN
	XmsRegs.AH := $10;										(* UMB belegen					*)
	XmsRegs.DX := Paragraphs; 								(* Grî·e des Blocks			*)
	CallXMS;														(* XMS Treiber aufrufen		*)

	Segment := XmsRegs.BX;									(* Segment des UMB's			*)
	Size := XmsRegs.DX;										(* Bei Fehler freie Par's	*)

	IF XmsRegs.AX = $0001 THEN XmsMemStatus := XmsMemOk
	ELSE XmsMemStatus := XmsRegs.BL;						(* Fehlerstatus vermerken 	*)
END; (* RequestUpperMemBlock *)

(* Diese Prozedur gibt einen Upper Memory Block wieder frei *)
PROCEDURE ReleaseUpperMemBlock(Segment : WORD);
BEGIN
	XmsRegs.AH := $11;										(* UMB freigeben		  		*)
	XmsRegs.DX := Segment; 	  		 						(* Segment des Blocks  		*)
	CallXMS;														(* XMS Treiber aufrufen		*)

	IF XmsRegs.AX = $0001 THEN XmsMemStatus := XmsMemOk
	ELSE XmsMemStatus := XmsRegs.BL;						(* Fehlerstatus vermerken 	*)
END; (* ReleaseUpperMemBlock *)

(* Diese Prozedur initialisiert die HiMem Unit *)
PROCEDURE InitXms;
VAR Regs : REGISTERS;
BEGIN
	Regs.AX := $4300;											(* XMS Speicher vorhanden	*)
	Intr($2F, Regs);   										(* Multiplex Interrupt		*)
	XmsMemAvail := Regs.AL = $80;

	IF XmsMemAvail THEN										(* XMS Speicher vorhanden	*)
	BEGIN
		Regs.AX := $4310;										(* XMS Funktionsadresse   	*)
		Intr($2F, Regs);  									(* Multiplex Interrupt		*)

		XmsControl.Offset := Regs.BX; 					(* Offset der Funktion		*)
		XmsControl.Segment := Regs.ES;  		 			(* Segment der Funktion		*)

		QueryFreeXms(LargestFree, XmsMemSize);			(* Speichergrî·en holen		*)
		XmsMemStatus := XmsMemOk;							(* Status ist in Ordnung	*)
	END;
END; (* InitXms *)

BEGIN           												(* Initialisierung			*)
	XmsMemAvail := FALSE;            					(* Kein XMS Speicher da		*)
	XmsMemStatus := XmsMemOk;	 		  					(* Status ist in Ordnung	*)
	XmsMemSize := 0;											(* Grî·e des XMS Speichers	*)
END. (* HiMem *)
