(****************************************************************)
(* Programmname    : EXTENDED.PAS V1.0                          *)
(* Programmautor   : Michael Rippl                              *)
(* Compiler        : Quick Pascal V1.0                          *)
(* Inhalt          : Routinen fÅr Zugriff auf Extended Memory   *)
(* Bemerkung       : -                                          *)
(* Letzte énderung : 13-Jun-1990                                *)
(****************************************************************)

UNIT Extended;

INTERFACE

CONST ExtMemoryOk 	 	= 0;	  							(* Speicher in Ordnung		*)
		ExtParityError  	= 1;	  							(* ParitÑtsfehler				*)
		ExtGDTError		   = 2;	  							(* GDT nicht in Ordnung		*)
		ExtProtectedError = 3; 								(* Fehler Protected Mode	*)

VAR ExtMemAvail  : BOOLEAN;                        (* Extended Memory da      *)
	 ExtMemStart  : LONGINT;                        (* Startadresse als 24 Bit *)
	 ExtMemSize   : INTEGER;                        (* Speichergrî·e in KB     *)
	 ExtMemStatus : BYTE;									(* Status des Speichers		*)

(* Dies Prozedur wandelt Segment und Offset in 24 Bit Adresse um *)
FUNCTION AddressConvert(Address : POINTER) : LONGINT;

(* Diese Prozedur liest einen Speicherblock vom Extended Memory *)
PROCEDURE MemoryRead(Source : LONGINT; Target : POINTER; Length : WORD);

(* Diese Prozedur schreibt einen Speicherblock in das Extended Memory *)
PROCEDURE MemoryWrite(Source : POINTER; Target : LONGINT; Length : WORD);

IMPLEMENTATION

USES Dos;														(* Units einbinden			*)

TYPE SegmentDescriptor     = RECORD                (* Segment Beschreiber     *)
										  Length,            (* Grî·e des Segments      *)
										  AddressLow  : WORD;(* Bit 0 bis 15 Adresse    *)
										  AddressHigh,       (* Bit 16 bis 23 Adresse   *)
										  Flag        : BYTE;(* Zugriffscode            *)
										  Reserved    : WORD;(* Reserviert fÅr 80386    *)
									  END;

	  GlobalDescriptorTable = RECORD                (* Globale Tabelle fÅr 286 *)
										  Dummy,
										  GDT,
										  Start,
										  Stop,
										  BiosCS,
										  Stack : SegmentDescriptor;
									  END;

	  LinearAddress         = RECORD                (* Zugriff auf 24 Adresse  *)
										  Low   : WORD;      (* Bit 0 bis 15            *)
										  High,              (* Bit 16 bis 23           *)
										  Dummy : BYTE;      (* Platzhalter fÅr 32 Bit  *)
									  END;

VAR BootSector : RECORD										(* Boot Sektor von VDISK	*)
						  Dummy1 		  : ARRAY [1..3] OF BYTE;
						  Name   		  : ARRAY [1..8] OF CHAR;
						  BytesPerSector : WORD;
						  Dummy2			  : ARRAY [1..6] OF BYTE;
						  NrOfSectors	  : WORD;
						  Dummy3         : BYTE;			(* Gerade LÑnge von Record	*)
					  END;

	 Regs       : REGISTERS;
	 DoLoop		: BOOLEAN;

(* Dies Prozedur wandelt Segment und Offset in 24 Bit Adresse um *)
FUNCTION AddressConvert(Address : POINTER) : LONGINT;
BEGIN
	AddressConvert := LONGINT(Seg(Address^)) SHL 4 + Ofs(Address^);
END; (* AddressConvert *)

(* Diese Prozedur kopiert Speicherbereiche innerhalb der 16 MB des 80286 *)
FUNCTION MemoryCopy(Source, Target : LONGINT; Size : WORD) : BYTE;
VAR GDT  : GlobalDescriptorTable;
	 Regs : REGISTERS;
BEGIN
	FillChar(GDT, SizeOf(GDT), 0);  						(* Alle Werte auf Null		*)

	WITH GDT.Start DO											(* Quelle initialisieren	*)
	BEGIN
		Length := Size;										(* Grî·e vom Speicherblock	*)
		AddressLow := LinearAddress(Source).Low;		(* Bit 0 - 15 der Adresse	*)
		AddressHigh := LinearAddress(Source).High;	(* Bit 16 - 23 der Adresse	*)
		Flag := $92;											(* Zugriff Lesen/Schreiben	*)
	END;

	WITH GDT.Stop DO											(* Ziel initialisieren		*)
	BEGIN
		Length := Size;										(* Grî·e vom Speicherblock	*)
		AddressLow := LinearAddress(Target).Low;		(* Bit 0 - 15 der Adresse	*)
		AddressHigh := LinearAddress(Target).High;	(* Bit 16 - 23 der Adresse	*)
		Flag := $92;											(* Zugriff Lesen/Schreiben	*)
	END;

	Regs.AH := $87;											(* Speicher kopieren			*)
	Regs.ES := Seg(GDT);										(* Segmentadresse von GDT	*)
	Regs.SI := Ofs(GDT);								 		(* Offsetadresse von GDT	*)
	Regs.CX := Size SHR 1;									(* Zu kopierende Worte		*)
	Intr($15, Regs);											(* Kassetten Interrupt		*)

	MemoryCopy := Regs.AH;									(* Statuscode					*)
END; (* MemoryCopy *)

(* Diese Prozedur liest einen Speicherblock vom Extended Memory *)
PROCEDURE MemoryRead(Source : LONGINT; Target : POINTER; Length : WORD);
BEGIN
	ExtMemStatus := MemoryCopy(Source, AddressConvert(Target), Length);
END; (* MemoryRead *)

(* Diese Prozedur schreibt einen Speicherblock in das Extended Memory *)
PROCEDURE MemoryWrite(Source : POINTER; Target : LONGINT; Length : WORD);
BEGIN
	ExtMemStatus := MemoryCopy(AddressConvert(Source), Target, Length);
END; (* MemoryWrite *)

BEGIN					   										(* Initialisierung			*)
	ExtMemStatus := ExtMemoryOk;							(* Speicherstatus ist Ok	*)

	Regs.AH := $88;											(* Grî·e vom Extended Mem	*)
	Intr($15, Regs);											(* Kassetten Interrupt		*)

	IF (Regs.Flags AND FCarry = FCarry) OR (Regs.AX = 0) THEN
	BEGIN	  	  													(* Kein Extended Memory		*)
		ExtMemAvail := FALSE;
		ExtMemSize := 0;
		ExtMemStart := 0;
	END
	ELSE															(* Extended Mem vorhanden	*)
	BEGIN
		ExtMemAvail := TRUE;
		ExtMemSize := Regs.AX;								(* Grî·e des Speichers		*)
		ExtMemStart := 1048576;								(* Start bei 1 MB				*)
		DoLoop := TRUE;										(* Schleife durchlaufen		*)

		REPEAT                                     	(* VDISK's suchen				*)
			MemoryRead(ExtMemStart, Addr(BootSector), SizeOf(BootSector));

			WITH BootSector DO
			BEGIN
				IF (Name[1] = 'V') AND (Name[2] = 'D') AND (Name[3] = 'I') AND
					(Name[4] = 'S') AND (Name[5] = 'K') THEN
					Inc(ExtMemStart, LONGINT(BytesPerSector) * NrOfSectors)
				ELSE DoLoop := FALSE;
			END;
		UNTIL NOT DoLoop;

		Dec(ExtMemSize, INTEGER((ExtMemStart - 1048576) DIV LONGINT(1024)));
	END;
END. (* Extended *)
