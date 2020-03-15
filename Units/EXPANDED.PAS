(******************************************************************)
(* Programmname    : EXPANDED.PAS V1.0                            *)
(* Programmautor   : Michael Rippl                                *)
(* Compiler        : Quick Pascal V1.0                            *)
(* Inhalt          : Routinen fÅr Zugriff auf LIM EMS V3.2 Memory *)
(* Bemerkung       : -                                       	   *)
(* Letzte énderung : 29-May-1990                              		*)
(******************************************************************)

UNIT Expanded;

INTERFACE

CONST EmsMemoryOk 	 	  = $00; 						(* Speicher in Ordnung		*)
		EmsSoftwareError    = $80; 						(* EMS Software Fehler		*)
		EmsHardwareError    = $81; 						(* EMS Hardware Fehler		*)
		EmsInvalidHandle    = $83; 						(* UngÅltiges EMS Handle  	*)
		EmsIllegalFunction  = $84;							(* UngÅltige EMS Funktion	*)
		EmsNoMoreHandles	  = $85;							(* Keine Handles mehr frei	*)
		EmsSaveRestoreError = $86;							(* Fehler in Save, Restore	*)
		EmsToManyPages      = $87;							(* Zu viele Pages verlangt	*)
		EmsNotEnoughPages	  = $88;							(* Nicht genug Seiten frei	*)
		EmsWantZeroPages	  = $89;							(* Null Seiten angefordert	*)
		EmsIllegalLogicPage = $8A;							(* Falsche logische Seite	*)
		EmsIllegalPhysPage  = $8B;							(* Physikalische Nr falsch	*)
		EmsMapMemIsFull	  = $8C;							(* Mapping Speicher voll	*)
		EmsMapAlreadySaved  = $8D;							(* Map bereits gespeichert	*)
		EmsMapNotSaved		  = $8E;						 	(* Map nicht gespeichert	*)

VAR EmsMemAvail  : BOOLEAN;                        (* Expanded Memory da      *)
	 EmsNrOfPages : INTEGER;                        (* Speichergrî·e in Seiten	*)
	 EmsMemStatus : BYTE;									(* Status des Speichers		*)

(* Diese Prozedur ermittelt die Versionsnummer des EMS Speichers *)
PROCEDURE GetEmsVersion(VAR VerHigh, VerLow : BYTE);

(* Es wird ein Zeiger auf eine der physikalischen Pages im Frame berechnet *)
FUNCTION GetPageOfFrame(PageNumber : BYTE) : POINTER;

(* Diese Funktion ermittelt die Anzahl der noch verfÅgbaren logischen Pages *)
FUNCTION NrOfAvailablePages : WORD;

(* Diese Prozedur reserviert eine bestimmte Anzahl von logischen Pages *)
PROCEDURE AllocPages(NrOfPages : WORD; VAR Handle : WORD);

(* Diese Prozedur gibt die logischen Pages eines Handles wieder frei *)
PROCEDURE FreePages(Handle : WORD);

(* Es wird eine logische Page auf eine der vier physikalischen abgebildet *)
PROCEDURE SetMapping(Handle, LogicPage : WORD; PhysicPage : BYTE);

(* Es wird der EMS Frame und die Abbildung der logischen Pages gespeichert *)
PROCEDURE SaveMapping(Handle : WORD);

(* Es wird der EMS Frame und die Abbildung der logischen Pages geladen *)
PROCEDURE LoadMapping(Handle : WORD);

(* Diese Funktion ermittelt die Anzahl der vergebenen Handles *)
FUNCTION NrOfReservedHandles : WORD;

(* Diese Prozedur ermittelt die Anzahl der belegten Pages eines Handles *)
FUNCTION NrOfReservedPages(Handle : WORD) : WORD;

(* Alle aktiven Handles und die Anzahl ihrer aktiven Pages werden ermittelt *)
PROCEDURE AllHandles(HandleData : POINTER; VAR NrOfDatas : WORD);

IMPLEMENTATION

USES Dos;														(* Units einbinden			*)

CONST EmsDriverName = 'EMMXXXX0';						(* Name des EMS Treibers	*)

TYPE EmmName  = ARRAY [1..8] OF CHAR;					(* Datentyp vom EMM Name 	*)
	  pEmmName = ^EmmName;									(* Zeiger auf EMM Name  	*)

VAR FrameSegment : WORD;									(* Segment vom EMS Frame	*)
	 Regs			  : REGISTERS;

(* Diese Prozedur ermittelt die Versionsnummer des EMS Speichers *)
PROCEDURE GetEmsVersion(VAR VerHigh, VerLow : BYTE);
VAR Regs : REGISTERS;
BEGIN
	Regs.AH := $46;											(* EMS Version emitteln		*)
	Intr($67, Regs);											(* EMS Interrupt				*)

	VerHigh := (Regs.AL AND $F0) SHR 4;					(* Version vor dem Punkt	*)
	VerLow := Regs.AL AND $0F;								(* Version nach dem Punkt	*)
END; (* GetEmsVersion *)

(* Es wird ein Zeiger auf eine der physikalischen Pages im Frame berechnet *)
FUNCTION GetPageOfFrame(PageNumber : BYTE) : POINTER;
BEGIN
	GetPageOfFrame := Ptr(FrameSegment, PageNumber * 16384);
END; (* GetPageOfFrame *)

(* Diese Prozedur ermittelt die Anzahl der noch verfÅgbaren logischen Pages *)
FUNCTION NrOfAvailablePages : WORD;
VAR Regs : REGISTERS;
BEGIN
	Regs.AH := $42;		  		 							(* Anzahl der EMS Pages		*)
	Intr($67, Regs);											(* EMS Interrupt				*)
	NrOfAvailablePages := Regs.BX;						(* Noch verfÅgbare Pages	*)
END; (* NrOfAvailablePages *)

(* Diese Prozedur reserviert eine bestimmte Anzahl von logischen Pages *)
PROCEDURE AllocPages(NrOfPages : WORD; VAR Handle : WORD);
VAR Regs : REGISTERS;
BEGIN
	Regs.AH := $43;											(* Logische Pages belegen	*)
	Regs.BX := NrOfPages;									(* Anzahl der Seiten			*)
	Intr($67, Regs);											(* EMS Interrupt				*)
	Handle := Regs.DX;										(* Handle fÅr belegte Page	*)
	EmsMemStatus := Regs.AH;	 		  					(* Status vom EMS Speicher	*)
END; (* AllocPages *)

(* Diese Prozedur gibt die logischen Pages eines Handles wieder frei *)
PROCEDURE FreePages(Handle : WORD);
VAR Regs : REGISTERS;
BEGIN
	Regs.AH := $45;											(* Logische Pages Freigabe	*)
	Regs.DX := Handle;										(* Handle der Pages			*)
	Intr($67, Regs);											(* EMS Interrupt				*)
	EmsMemStatus := Regs.AH;	 		  					(* Status vom EMS Speicher	*)
END; (* FreePages *)

(* Es wird eine logische Page auf eine der vier physikalischen abgebildet *)
PROCEDURE SetMapping(Handle, LogicPage : WORD; PhysicPage : BYTE);
VAR Regs : REGISTERS;
BEGIN
	Regs.AH := $44;											(* Abbildung herstellen		*)
	Regs.DX := Handle;										(* Handle der Pages			*)
	Regs.BX := LogicPage;									(* Logische Seitennummer	*)
	Regs.AL := PhysicPage;									(* Physikalische SeitenNr	*)
	Intr($67, Regs);											(* EMS Interrupt				*)
	EmsMemStatus := Regs.AH;	 		  					(* Status vom EMS Speicher	*)
END; (* SetMapping *)

(* Es wird der EMS Frame und die Abbildung der logischen Pages gespeichert *)
PROCEDURE SaveMapping(Handle : WORD);
VAR Regs : REGISTERS;
BEGIN
	Regs.AH := $47;											(* Mapping fÅr TSR sichern	*)
	Regs.DX := Handle;										(* Handle der Pages			*)
	Intr($67, Regs);											(* EMS Interrupt				*)
	EmsMemStatus := Regs.AH;	 		  					(* Status vom EMS Speicher	*)
END; (* SaveMapping *)

(* Es wird der EMS Frame und die Abbildung der logischen Pages geladen *)
PROCEDURE LoadMapping(Handle : WORD);
VAR Regs : REGISTERS;
BEGIN
	Regs.AH := $48;											(* Mapping fÅr TSR laden  	*)
	Regs.DX := Handle;										(* Handle der Pages			*)
	Intr($67, Regs);											(* EMS Interrupt				*)
	EmsMemStatus := Regs.AH;	 		  					(* Status vom EMS Speicher	*)
END; (* LoadMapping *)

(* Diese Funktion ermittelt die Anzahl der vergebenen Handles *)
FUNCTION NrOfReservedHandles : WORD;
VAR Regs : REGISTERS;
BEGIN
	Regs.AH := $4B;											(* Vergebene Handles			*)
	Intr($67, Regs);											(* EMS Interrupt				*)
	NrOfReservedHandles := Regs.BX;						(* Anzahl belegter Handles	*)
	EmsMemStatus := Regs.AH;	 		  					(* Status vom EMS Speicher	*)
END; (* NrOfReservedHandles *)

(* Diese Prozedur ermittelt die Anzahl der belegten Pages eines Handles *)
FUNCTION NrOfReservedPages(Handle : WORD) : WORD;
VAR Regs : REGISTERS;
BEGIN
	Regs.AH := $4C;											(* Belegte Pages ermitteln *)
	Regs.DX := Handle;										(* Handle der Pages			*)
	Intr($67, Regs);											(* EMS Interrupt				*)
	NrOfReservedPages := Regs.BX;	  		 				(* Anzahl belegter Pages  	*)
	EmsMemStatus := Regs.AH;	 		  					(* Status vom EMS Speicher	*)
END; (* NrOfReservedPages *)

(* Alle aktiven Handles und die Anzahl ihrer aktiven Pages werden ermittelt *)
PROCEDURE AllHandles(HandleData : POINTER; VAR NrOfDatas : WORD);
TYPE Address = RECORD                     			(* Bestandteile von Zeiger	*)
						Offset,
						Segment : WORD;
					END;
BEGIN
	Regs.AH := $4D;											(* Alle Handles ermitteln	*)
	Regs.ES := Address(HandleData).Segment;			(* Segment des Datenfeldes	*)
	Regs.DI := Address(HandleData).Offset;          (* Offset des Datenfeldes	*)
	Intr($67, Regs);											(* EMS Interrupt				*)
	NrOfDatas := Regs.BX;									(* Anzahl der Daten			*)
	EmsMemStatus := Regs.AH;	 		  					(* Status vom EMS Speicher	*)
END; (* AllHandles *)

BEGIN	  				   										(* Initialisierung			*)
	EmsMemStatus := EmsMemoryOk;							(* Speicherstatus ist Ok	*)

	Regs.AH := $35;											(* Hole Interrupt Vektor	*)
	Regs.AL := $67;											(* EMS Interrupt Nummer		*)
	MsDos(Regs);												(* DOS Interrupt				*)

	EmsMemAvail := pEmmName(Ptr(Regs.ES, $0A))^ = EmsDriverName;

	IF EmsMemAvail THEN										(* EMS Speicher vorhanden	*)
	BEGIN
		Regs.AH := $42;										(* Anzahl der EMS Pages		*)
		Intr($67, Regs);										(* EMS Interrupt				*)
		EmsNrOfPages := Regs.DX;							(* Vorhandene Pages			*)

		Regs.AH := $41;										(* Segment vom Page Frame	*)
		Intr($67, Regs);										(* EMS Interrupt				*)
		FrameSegment := Regs.BX;							(* Adresse des Page Frame	*)
	END
	ELSE EmsNrOfPages := 0;									(* Keine Pages vorhanden	*)
END. (* Expanded *)
