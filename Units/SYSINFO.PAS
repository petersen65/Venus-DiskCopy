(****************************************************************)
(* Programmname    : SYSINFO.PAS V1.1          						 *)
(* Programmautor   : Michael Rippl 						             *)
(* Compiler        : Quick Pascal V1.0    	  						 *)
(* Inhalt          : Routinen zum Holen von Systeminformationen *)
(* Bemerkung       : -                    	  						 *)
(* Letzte Žnderung : 05-Okt-1990            	  						 *)
(****************************************************************)

UNIT SysInfo;

INTERFACE

USES Dos, Crt;	  												(* Units einbinden			*)

TYPE CPU = (Intel8088, Intel8086, NecV20, NecV30, Intel80188, Intel80186,
				Intel80286, Intel80386);

(* Diese Funktion ermittelt den in einem Rechner befindlichen Prozessor *)
FUNCTION GetCPUType : CPU;

(* Diese Funktion ermittelt die Anzahl vorhandener serieller Ports *)
FUNCTION SerialPorts : BYTE;

(* Diese Funktion ermittelt die Anzahl vorhandener paralleler Ports *)
FUNCTION ParallelPorts : BYTE;

(* Diese Prozedur ermittelt die MS DOS Version des Systems *)
PROCEDURE MsDosVersion(VAR VerHigh, VerLow : BYTE);

(* Diese Funktion ermittelt die Hauptspeichergr”áe in Bytes *)
FUNCTION MainMemSize : LONGINT;

(* Diese Prozedur liest ein Byte aus dem CMOS-Speicher *)
PROCEDURE ReadCMos(Offset : BYTE; VAR Value : BYTE);

(* Diese Prozedur schreibt ein Byte in den CMOS-Speicher *)
PROCEDURE WriteCMos(Offset, Value : BYTE);

IMPLEMENTATION

(* Diese Prozedur ermittelt den in einem Rechner befindlichen Prozessor *)
FUNCTION GetCPUType : CPU;
BEGIN
	INLINE ( $9C/$51/$52/$57/$56/$06/$33/$C0/$50/$9D/$9C/$58/$25/$00/
				$F0/$3D/$00/$F0/$74/$13/$B2/$06/$B8/$00/$70/$50/$9D/$9C/
				$58/$25/$00/$70/$74/$36/$FE/$C2/$EB/$32/$90/$B2/$04/$B0/
				$FF/$B1/$21/$D2/$E8/$75/$12/$B2/$02/$FB/$BE/$00/$00/$B9/
				$FF/$FF/$F3/$26/$AC/$0B/$C9/$74/$02/$B2/$00/$0E/$07/$FD/
				$B0/$FB/$B9/$03/$00/$E8/$16/$00/$FA/$F3/$AA/$FC/$90/$90/
				$90/$42/$90/$FB/$88/$56/$FF/$07/$5E/$5F/$5A/$59/$9D/$EB/
				$07/$90/$5F/$83/$C7/$09/$EB/$E4);
END; (* GetCPUType *)

(* Diese Funktion ermittelt die Anzahl vorhandener serieller Ports *)
FUNCTION SerialPorts : BYTE;
VAR Regs : REGISTERS;
BEGIN
	Intr($11, Regs);											(* Konfiguration ermitteln	*)
	SerialPorts := (Regs.AX SHR 9) AND 7;
END; (* SerialPorts *)

(* Diese Funktion ermittelt die Anzahl vorhandener paralleler Ports *)
FUNCTION ParallelPorts : BYTE;
VAR Regs : REGISTERS;
BEGIN
	Intr($11, Regs);											(* Konfiguration ermitteln	*)
	ParallelPorts := (Regs.AX SHR 14) AND 3;
END; (* ParallelPorts *)

(* Diese Prozedur ermittelt die MS DOS Version des Systems *)
PROCEDURE MsDosVersion(VAR VerHigh, VerLow : BYTE);
VAR Regs : REGISTERS;
BEGIN
	Regs.AH := $30;											(* Dos Version ermitteln	*)
	MsDos(Regs);												(* Dos Interrupt				*)

	VerLow := Regs.AH; 									   (* Zahl hinter dem Punkt	*)
	VerHigh := Regs.AL;                             (* Zahl vor dem Punkt		*)
END; (* MsDosVersion *)

(* Diese Funktion ermittelt die Hauptspeichergr”áe in Bytes *)
FUNCTION MainMemSize : LONGINT;
VAR Regs : REGISTERS;
BEGIN
	Intr($12, Regs);											(* Gr”áe vom Hauptspeicher	*)
	MainMemSize := LONGINT(Regs.AX) * 1024;
END; (* MainMemSize *)

(* Diese Prozedur liest ein Byte aus dem CMOS-Speicher *)
PROCEDURE ReadCMos(Offset : BYTE; VAR Value : BYTE);
VAR Regs : REGISTERS;
BEGIN
	Port[$70] := Offset;
	Value := Port[$71];
END; (* ReadCMos *)

(* Diese Prozedur schreibt ein Byte in den CMOS-Speicher *)
PROCEDURE WriteCMos(Offset, Value : BYTE);
BEGIN
	Port[$70] := Offset;
	Port[$71] := Value;
END; (* WriteCMos *)

END. (* SysInfo *)
