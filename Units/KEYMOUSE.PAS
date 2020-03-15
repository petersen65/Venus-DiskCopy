(****************************************************************)
(* Programmname    : KEYMOUSE.PAS V1.7             	          *)
(* Programmautor   : Michael Rippl              	             *)
(* Compiler        : Quick Pascal V1.0        	                *)
(* Inhalt          : Routinen fÅr Abfrage von Maus und Tastatur *)
(* Bemerkung       : Erkennt automatisch, ob Maus vorhanden     *)
(* Letzte énderung : 13-Jul-1990                         	    *)
(****************************************************************)

UNIT KeyMouse;

INTERFACE

USES Dos;       												(* Units einbinden			*)

CONST	EventMouseMove	   = 1;		  						(* Bewegung der Maus			*)
		EventLeftDown     = 2;		  						(* Linke Taste drÅcken		*)
		EventLeftUp       = 4;   	  						(* Linke Taste loslassen	*)
		EventRightDown    = 8;		  						(* Rechte Taste drÅcken		*)
		EventRightUp      = 16;  	  						(* Rechte Taste loslassen	*)
		EventMiddleDown   = 32;  	  						(* Mittlere Taste drÅcken	*)
		EventMiddleUp     = 64;  	  						(* Mittlere Taste loslass.	*)

		EventASCIICode    = 1;		  						(* Taste liefert ASCII	   *)
		EventStatusChange = 2;		  						(* Neuer Tastaturstatus		*)
		EventMakeCode     = 4;		  						(* Make Code von Port 60h  *)
		EventReleaseCode  = 8;		  						(* Release Code Port 60h  	*)

CONST NoUserId      = 0;		 							(* Keine Benutzernummer		*)

CONST LeftButton    = 1; 									(* Linke Maustaste 			*)
		RightButton   = 2;                           (* Rechte Maustaste 			*)
		MiddleButton  = 4;                           (* Mittlere Maustaste  		*)

		RightShiftKey = 1;  							  		(* Rechte Shift Taste		*)
		LeftShiftKey  = 2;                           (* Linke Shift Taste			*)
		CtrlKey		  = 4;                           (* Control (Strg) Taste		*)
		AltKey		  = 8;                           (* Alternate Taste			*)
		ScrollLockKey = 16;                          (* Scroll Lock Taste			*)
		NumLockKey    = 32;                          (* Number Lock Taste			*)
		CapsLockKey   = 64;                          (* Caps Lock Taste			*)
		InsertKey     = 128;                         (* Insert (Einfg) Taste		*)

CONST ShiftTab 		 = 15;	AltQ 			   = 16; (* Erweiterte Tastencodes	*)
		AltW		  		 = 17;	AltE 			   = 18;
		AltR       		 = 19;   AltT 			   = 20;
		AltY       		 = 21;	AltU 			   = 22;
		AltI       		 = 23;	AltO 			   = 24;
		AltP		  		 = 25;	AltA 			   = 30;
		AltS       		 = 31;	AltD 			   = 32;
		AltF 		  		 = 33;	AltG 			   = 34;
		AltH		  		 = 35;	AltJ 			   = 36;
		AltK		  		 = 37;	AltL 			   = 38;
		AltZ		  		 = 44;	AltX 			   = 45;
		AltC		  		 = 46;	AltV 			   = 47;
		AltB 		  		 = 48;	AltN 			   = 49;
		AltM       		 = 50;	F1             = 59;
		F2        		 = 60;	F3				   = 61;
		F4        		 = 62;	F5				   = 63;
		F6        		 = 64;	F7				   = 65;
		F8        		 = 66;	F9				   = 67;
		F10        		 = 68;	Home 			   = 71;
		CursorUp   		 = 72;	PageUp      	= 73;
		CursorLeft 		 = 75;	CursorRight 	= 77;
		EndKey          = 79;	CursorDown 	   = 80;
		PageDown   		 = 81;	Insert     	   = 82;
		DelKey     		 = 83;	ShiftF1   	   = 84;
		ShiftF2    		 = 85;	ShiftF3    	   = 86;
		ShiftF4    		 = 87;	ShiftF5    	   = 88;
		ShiftF6     	 = 89;	ShiftF7    	   = 90;
		ShiftF8    		 = 91;	ShiftF9    	   = 92;
		ShiftF10   	 	 = 93;	CtrlF1	  		= 94;
		CtrlF2	  		 = 95;	CtrlF3	  		= 96;
		CtrlF4	  		 = 97;	CtrlF5	  		= 98;
		CtrlF6			 = 99;	CtrlF7	  	   = 100;
		CtrlF8	  		 = 101;  CtrlF9	  	   = 102;
		CtrlF10			 = 103;  AltF1      	   = 104;
		AltF2				 = 105;  AltF3      	   = 106;
		AltF4				 = 107;  AltF5      	   = 108;
		AltF6				 = 109;  AltF7      	   = 110;
		AltF8				 = 111;  AltF9       	= 112;
		AltF10		  	 = 113;  CtrlCursorLeft = 115;
		CtrlCursorRight = 116;	CtrlEnd		   = 117;
		CtrlPageDown    = 118;	CtrlHome			= 119;
		Alt1		     	 = 120;	Alt2				= 121;
		Alt3				 = 122;	Alt4				= 123;
		Alt5				 = 124;	Alt6				= 125;
		Alt7				 = 126;	Alt8				= 127;
		Alt9				 = 128;	Alt0				= 129;
		CtrlPageUp		 = 132;

CONST Bel   			= 7;     BackSpace = 8;			(* Normale Tastaturcodes	*)
		Tab  			   = 9;	   LineFeed  = 10;
		CarriageReturn = 13;    Esc		 = 27;
		Space          = 32;    CtrlA     = 1;
		CtrlB				= 2;	   CtrlC		 = 3;
		CtrlD				= 4;	   CtrlE		 = 5;
		CtrlF				= 6;	   CtrlG		 = 7;
		CtrlH				= 8;	   CtrlI		 = 9;
		CtrlJ				= 10;    CtrlK		 = 11;
		CtrlL				= 12;	   CtrlM		 = 13;
		CtrlN				= 14;	   CtrlO		 = 15;
		CtrlP				= 16;	   CtrlQ		 = 17;
		CtrlR				= 18;	   CtrlS		 = 19;
		CtrlT				= 20;	   CtrlU		 = 21;
		CtrlV				= 22;	   CtrlW		 = 23;
		CtrlX				= 24;	   CtrlY		 = 25;
		CtrlZ				= 26;

TYPE Event = RECORD						  					(* Maus, Tasten Ereignis 	*)
					BiosTick : LONGINT;  					(* Zeitpunkt vom Ereignis	*)

					CASE Mouse : BOOLEAN OF	  				(* Maus oder Tastatur		*)
						TRUE :     				  				(* Maus Ereignis				*)
							(mEvent,    			         (* Grund des Ereignisses	*)
							 Buttons  : WORD; 	  			(* Status der Mausknîpfe	*)
							 Column,			      			(* Mausposition Spalte		*)
							 Line, 		 		   			(* Mausposition Zeile		*)
							 AreaId,         	  				(* Nummer eines Bereichs	*)
							 RelativX,           			(* Relativ X zum Bereich	*)
							 RelativY : BYTE);    			(* Relativ Y zum Bereich	*)
						FALSE :					  				(* Tastatur Ereignis			*)
							(tEvent,								(* Grund des Ereignisses	*)
							 KeyCode,							(* ASCII Code der Taste		*)
							 ExtCode,							(* Erweiterter Tastencode	*)
							 ScanCode : BYTE);    			(* Scan Code der Taste		*)
				 END;

TYPE UserId 		= 1..128;  								(* Identifikation Bereich	*)
	  MouseType    = (Bus, Serial, InPort, PS2, HP);(* Typ der Maus				*)
	  EventHandler = PROCEDURE (NewEvent : Event);  (* Handler fÅr Ereignis		*)

	  Handlers     = (HandlerMouseMove, HandlerLeftDown, HandlerLeftUp,
							HandlerRightDown, HandlerRightUp, HandlerMiddleDown,
							HandlerMiddleUp, HandlerASCIICode, HandlerStatusChange,
							HandlerMakeCode, HandlerReleaseCode);
																	(* Mîgliche Handlertypen	*)
	  HandlerSet 	= SET OF Handlers;					(* Menge von Handlern		*)

VAR MouseAvail  : BOOLEAN;									(* Maus vorhanden          *)
	 MouseX,      												(* Aktuelle X Position		*)
	 MouseY,  													(* Aktuelle Y Position		*)
	 NrOfButtons : BYTE;										(* Anzahl der Mausknîpfe	*)

(* Diese Prozedur ermittelt den Maustyp und die Versionsnummer der Maus *)
PROCEDURE GetMouseType(VAR VerHigh, VerLow : BYTE; VAR MouseTyp : MouseType);

(* Diese Prozedur schaltet den Cursor der Maus an *)
PROCEDURE MouseOn;

(* Diese Prozedur schaltet den Cursor der Maus aus *)
PROCEDURE MouseOff;

(* Diese Prozedur legt das Erscheinungsbild des Maus-Cursors fest *)
PROCEDURE DefineMouseCursor(ScreenMask, CursorMask : WORD);

(* Es wird die Geschwindigkeit der Maus in Mickeys = 1/200 Zoll festgelegt *)
PROCEDURE SetMouseSpeed(Horizontal, Vertical : WORD);

(* Diese Prozedur holt ein Ereignis von den Warteschlangen *)
PROCEDURE GetEvent(VAR NewEvent : Event);

(* NÑchstes Ereignis holen ohne es aus der Warteschlange zu nehmen *)
PROCEDURE LookEvent(VAR NewEvent : Event);

(* Diese Prozedur prÅft ob ein Maus Ereignis vorliegt *)
FUNCTION IsMouseEvent : BOOLEAN;

(* Diese Prozedur prÅft ob ein Tastatur Ereignis vorliegt *)
FUNCTION IsKeyEvent : BOOLEAN;

(* Diese Prozedur prÅft ob ein Tastatur oder Maus Ereignis vorliegt *)
FUNCTION IsEvent : BOOLEAN;

(* Diese Prozedur setzt den Maus Cursor an eine bestimmte Position *)
PROCEDURE SetMouseXY(LeftEdge, TopEdge : WORD);

(* Diese Prozedur schrÑnkt den Bewegungsbereich des Maus Cursors ein *)
PROCEDURE SetMouseArea(LeftEdge, TopEdge, Width, Height : WORD);

(* Diese Prozedur ordnet einem Bildschirmbereich eine Benutzernummer zu *)
PROCEDURE CreateArea(LeftEdge, TopEdge, Width, Height : BYTE; AreaNr : UserId);

(* Diese Prozedur entfernt die Zuordnung zu einem Bildschirmbereich *)
PROCEDURE DeleteArea(AreaNr : UserId);

(* Diese Prozedur installiert einen Handler fÅr ein bestimmtes Ereignis *)
PROCEDURE InstallHandler(HandlerProc : EventHandler; OneEvent : Handlers);

(* Diese Prozedur entfernt einen Handler fÅr ein bestimmtes Ereignis *)
PROCEDURE RemoveHandler(OneEvent : Handlers);

(* Diese Prozedur wartet auf ein Ereignis und ruft dessen Handler auf *)
PROCEDURE WaitEvent(StopEvents : HandlerSet);

(* FÅr den Release Code der Tasten wird ein Ereignis erzeugt *)
PROCEDURE ReleaseCodeOn;

(* FÅr den Release Code der Tasten wird kein Ereignis erzeugt *)
PROCEDURE ReleaseCodeOff;

(* FÅr den Make Code der Tasten wird ein Ereignis erzeugt *)
PROCEDURE MakeCodeOn;

(* FÅr den Make Code der Tasten wird kein Ereignis erzeugt *)
PROCEDURE MakeCodeOff;

(* Diese Funktion liefert den Tastaturstatus *)
FUNCTION GetKeyStatus : BYTE;

(* Diese Prozedur legt den Tastaturstatus fest *)
PROCEDURE SetKeyStatus(Status : BYTE);

(* Diese Prozedur lîscht Statusinformationen *)
PROCEDURE DelKeyStatus(Status : BYTE);

(* Diese Prozedur setzt die Typematic-Rate und die Delay-Rate der Tastatur *)
PROCEDURE SetKeySpeed(DelayRate, TypematicRate : BYTE);

(* Diese Prozedur entfernt die Interrupt Routine fÅr die Tastatur *)
PROCEDURE ReInstallKeyInterrupt;

(* Diese Prozedur installiert die Interrupt Routine fÅr die Tastatur *)
PROCEDURE InstallKeyInterrupt;

IMPLEMENTATION

CONST AllMouseEvents = 127;								(* Alle Maus-Ereignisse		*)
		MaxEvents		= 100;								(* Maximale Event-Anzahl	*)

TYPE Area		  = ARRAY [0..24768] OF BYTE;			(* Typ vom Benutzerbereich	*)
	  pEventTable = ^EventTable;							(* Zeiger auf Eventtabelle	*)

	  Handler	  = RECORD									(* Typ eines Handlers		*)
							 Call 	 : BOOLEAN;      		(* Handler installiert		*)
							 CallProc : EventHandler;		(* Prozedur fÅr Handler		*)
						 END;

	  Coordinates = RECORD									(* Koordinaten vom Bereich	*)
							 Column,         					(* Linke Spalte				*)
							 Line,                        (* Obere Zeile					*)
							 SizeX,								(* Anzahl der Spalten		*)
							 SizeY : BYTE;                (* Anzahl der Zeilen			*)
						 END;

	  EventTable  = RECORD									(* Tabelle der Ereignisse	*)
							 Last,                        (* Letztes Ereignis		 	*)
							 Next : 0..MaxEvents;		 	(* NÑchstes Ereignis			*)
							 Fifo : ARRAY [0..MaxEvents] OF Event;
						 END;										(* Ereignisse, Fifo-Liste	*)

VAR NrOfLines,                                     (* Anzahl der Zeilen       *)
	 NrOfColumns,			                           (* Anzahl der Spalten      *)
	 OldMouseX,          								  	(* Alte Maus X Position		*)
	 OldMouseY    : BYTE;                           (* Alte Maus Y Position		*)
	 Interrupt09,     	  		 							(* Interrupt $09 Routine 	*)
	 OldExitProc  : POINTER;                        (* Alte Exit-Prozedur		*)
	 MakeKey,													(* Make Code erzeugen		*)
	 ReleaseKey   : BOOLEAN;								(* Release Code erzeugen	*)
	 MouseRing,            	                        (* Warteschlange fÅr Maus	*)
	 KeyRing		  : pEventTable; 							(* Warteschlange fÅr Taste	*)
	 UserArea     : ^Area;									(* Benutzer	Bereiche			*)
	 Time			  : LONGINT ABSOLUTE $40:$6C;			(* Tick-ZÑhler vom BIOS		*)
	 KeyStatus    : BYTE ABSOLUTE $40:$17;				(* Statusbyte vom BIOS		*)
	 ActKeyStatus : BYTE;									(* Aktueller Tastenstatus	*)
	 DefinedId    : ARRAY [UserId] OF Coordinates;	(* Definierte Nummern		*)
	 HandlerTable : ARRAY [Handlers] OF Handler;		(* Tabelle aller Handler	*)

(*$F+ Diese Assembler-Prozedur dient als Handler fÅr den Maustreiber *)
PROCEDURE MouseHandler; EXTERNAL; (*$F-*)
(*$L Mouse.Obj *)

(*$F+ Diese Assembler-Prozedur dient als ErgÑnzung fÅr den Interrupt $09 *)
PROCEDURE KeyboardHandler; EXTERNAL; (*$F-*)
(*$L Keyboard.Obj *)

(* Diese Prozedur fÅgt ein Event in eine Liste ein *)
PROCEDURE Push(EventQueue : pEventTable; Item : Event);
BEGIN
	WITH EventQueue^ DO
	BEGIN
		IF Last + 1 <> Next THEN							(* Ring ist nicht voll		*)
		BEGIN
			Fifo[Last] := Item;								(* Ereignis eintragen		*)
			Last := (Last + 1) MOD (MaxEvents + 1);	(* Falls Ende, dann Anfang *)
		END;
	END;
END; (* Push *)

(* Diese Prozedur entfernt ein Element aus einer Liste *)
PROCEDURE Pop(EventQueue : pEventTable; VAR Item : Event);
BEGIN
	WITH EventQueue^ DO
	BEGIN
		IF Last <> Next THEN									(* Ring ist nicht leer		*)
		BEGIN
			Item := Fifo[Next];
			Next := (Next + 1) MOD (MaxEvents + 1);	(* Falls Ende, dann Anfang *)
		END
		ELSE Item.BiosTick := MaxLongInt;				(* Ring ist leer				*)
	END;
END; (* Pop *)

(* Diese Prozedur wird vom Handler des Maustreibers aufgerufen *)
PROCEDURE MouseEvent(MouseEvents, MouseButtons : WORD);
VAR ActualTime : LONGINT;
	 Item 		: Event;
	 EventMask  : WORD;
	 i				: BYTE;
BEGIN
	ActualTime := Time;										(* Zeitpunkt merken			*)
	EventMask := 1;											(* Zum Auslesen von Bits	*)

	FOR i := 1 TO 7 DO										(* Alle Events durchgehen	*)
	BEGIN
		IF (MouseEvents AND EventMask) = EventMask THEN
		BEGIN
			IF NOT ((EventMask = EventMouseMove) AND (OldMouseX = MouseX) AND
				(OldMouseY = MouseY)) THEN					(* Position nicht doppelt	*)
			BEGIN
				WITH Item DO
				BEGIN
					BiosTick := ActualTime;	 			  	(* Zeitpunkt eintragen		*)
					Mouse := TRUE;   	 		 	  	   	(* Ereignis von der Maus	*)
					Buttons := MouseButtons;
					Line := MouseY;
					Column := MouseX;
					OldMouseY := Line;						(* Doppeleintrag vermeiden	*)
					OldMouseX := Column;
					AreaId := UserArea^[Line * NrOfColumns + Column];
					mEvent := EventMask;

					IF AreaId = NoUserId THEN 				(* Auf keinem Bereich	 	*)
					BEGIN
						RelativX := Column;
						RelativY := Line;
					END
					ELSE 									  		(* Ereignis auf Bereich		*)
					BEGIN
						RelativX := Column - DefinedId[AreaId].Column;
						RelativY := Line - DefinedId[AreaId].Line;
					END;
				END;

				Push(MouseRing, Item);	  	  	  	  	 	(* In Warteschlange setzen *)
			END;
		END;

		EventMask := EventMask SHL 1;						(* NÑchstes Event-Bit		*)
	END;
END; (* MouseEvent *)

(* Diese Prozedur wird vom neuen Interrupt $09 Handler aufgerufen *)
PROCEDURE KeyboardEvent(KeyPort : BYTE);
VAR ActualTime   : LONGINT;
	 Item 		  : Event;
	 Regs         : REGISTERS;
	 NewKeyStatus : BYTE;
BEGIN
	ActualTime := Time;										(* Zeitpunkt merken			*)
	NewKeyStatus := KeyStatus;								(* Neuen Status merken		*)
	Item.BiosTick := MaxLongInt; 							(* Kein Ereignis vorhanden	*)

	Regs.AH := $01;											(* Tastaturpuffer prÅfen	*)
	Intr($16, Regs); 											(* Tasten Interrupt			*)

	IF (Regs.Flags AND FZero) = 0 THEN			 	   (* Code im Tastaturpuffer	*)
	BEGIN
		WITH Item DO
		BEGIN
			tEvent := EventASCIICode; 					   (* Taste liefert ASCII	   *)
			BiosTick := ActualTime;							(* Zeitpunkt vom Ereignis	*)

			Regs.AH := $00;									(* Code aus Puffer lesen	*)
			Intr($16, Regs);									(* Tasten Interrupt			*)

			KeyCode := Regs.AL;     					   (* ASCII Code der Taste		*)
			ExtCode := Regs.AH;								(* Erweiterter Tastencode	*)
		END;
	END
	ELSE	 		  												(* Kein Tastencode erzeugt	*)
	BEGIN
		IF ActKeyStatus <> NewKeyStatus THEN			(* StatusÑnderung				*)
		BEGIN
			IF NewKeyStatus > ActKeyStatus THEN			(* Ein Bit wurde gesetzt	*)
			BEGIN
				IF (NewKeyStatus XOR ActKeyStatus) <> InsertKey THEN
				BEGIN												(* Keine Insert Taste		*)
					WITH Item DO
					BEGIN
						tEvent := EventStatusChange;
						BiosTick := ActualTime;				(* Zeitpunkt vom Ereignis	*)
						KeyCode := NewKeyStatus XOR ActKeyStatus;
					END;
				END;
			END
			ELSE IF ReleaseKey THEN							(* Release Code der Taste	*)
			BEGIN
				Item.tEvent := EventReleaseCode;
				Item.BiosTick := ActualTime;				(* Zeitpunkt vom Ereignis	*)
			END;

			ActKeyStatus := NewKeyStatus;
		END
		ELSE IF KeyPort < 128 THEN	  		 				(* Make Code der Taste		*)
		BEGIN
			IF MakeKey THEN									(* Make Code erzeugen		*)
			BEGIN
				Item.tEvent := EventMakeCode;
				Item.BiosTick := ActualTime;				(* Zeitpunkt vom Ereignis	*)
			END;
		END
		ELSE IF ReleaseKey THEN                      (* Release Code der Taste	*)
		BEGIN
			Item.tEvent := EventReleaseCode;
			Item.BiosTick := ActualTime;					(* Zeitpunkt vom Ereignis	*)
		END;
	END;

	IF Item.BiosTick <> MaxLongInt THEN	  				(* Ereignis vorhanden		*)
	BEGIN
		Item.Mouse := FALSE;  	  		  	   			(* Ereignis von Tastatur	*)
		Item.ScanCode := KeyPort;							(* Scan Code der Taste	  	*)

		Push(KeyRing, Item);			 		  	  	  	 	(* In Warteschlange setzen *)
	END;
END; (* KeyboardEvent *)

(* Diese Prozedur ermittelt den Maustyp und die Versionsnummer der Maus *)
PROCEDURE GetMouseType(VAR VerHigh, VerLow : BYTE; VAR MouseTyp : MouseType);
VAR Regs : REGISTERS;
BEGIN
	Regs.AX := $0024;											(* Maustyp ermitteln			*)
	Intr($33, Regs);											(* Maus Interrupt				*)
	VerHigh := Regs.BH;
	VerLow := Regs.BL;

	CASE Regs.CH OF											(* Unterschiedliche Typen	*)
		1 : MouseTyp := Bus;
		2 : MouseTyp := Serial;
		3 : MouseTyp := InPort;
		4 : MouseTyp := PS2;
		5 : MouseTyp := HP;
	END;
END; (* GetMouseType *)

(* Diese Prozedur schaltet den Cursor der Maus an *)
PROCEDURE MouseOn;
VAR Regs : REGISTERS;
BEGIN
	Regs.AX := $0001;											(* Maus Cursor anschalten	*)
	Intr($33, Regs);											(* Maus Interrupt				*)
END; (* MouseOn *)

(* Diese Prozedur schaltet den Cursor der Maus aus *)
PROCEDURE MouseOff;
VAR Regs : REGISTERS;
BEGIN
	Regs.AX := $0002;											(* Maus Cursor ausschalten	*)
	Intr($33, Regs);											(* Maus Interrupt				*)
END; (* MouseOff *)

(* Diese Prozedur legt das Erscheinungsbild des Maus-Cursors fest *)
PROCEDURE DefineMouseCursor(ScreenMask, CursorMask : WORD);
VAR Regs : REGISTERS;
BEGIN
	Regs.AX := $000A;											(* Maus Cursor definieren	*)
	Regs.BX := $0000;											(* Software Cursor			*)
	Regs.CX := ScreenMask;
	Regs.DX := CursorMask;
	Intr($33, Regs);											(* Maus Interrupt				*)
END; (* DefineMouseCursor *)

(* Es wird die Geschwindigkeit der Maus in Mickeys = 1/200 Zoll festgelegt *)
PROCEDURE SetMouseSpeed(Horizontal, Vertical : WORD);
VAR Regs : REGISTERS;
BEGIN
	Regs.AX := $000F;											(* Maus Geschwindigkeit		*)
	Regs.CX := Horizontal;
	Regs.DX := Vertical;
	Intr($33, Regs);											(* Maus Interrupt				*)
END; (* SetMouseSpeed *)

(* Diese Prozedur prÅft ob ein Maus Ereignis vorliegt *)
FUNCTION IsMouseEvent : BOOLEAN;
BEGIN
	IsMouseEvent := MouseRing^.Last <> MouseRing^.Next;
END; (* IsMouseEvent *)

(* Diese Prozedur prÅft ob ein Tastatur Ereignis vorliegt *)
FUNCTION IsKeyEvent : BOOLEAN;
BEGIN
	IsKeyEvent := KeyRing^.Last <> KeyRing^.Next;
END; (* IsKeyEvent *)

(* Diese Prozedur prÅft ob ein Tastatur oder Maus Ereignis vorliegt *)
FUNCTION IsEvent : BOOLEAN;
BEGIN
	IsEvent := (KeyRing^.Last <> KeyRing^.Next) OR
				  (MouseRing^.Last <> MouseRing^.Next);
END; (* IsEvent *)

(* Diese Prozedur setzt den Maus Cursor an eine bestimmte Position *)
PROCEDURE SetMouseXY(LeftEdge, TopEdge : WORD);
VAR Regs : REGISTERS;
BEGIN
	MouseX := LeftEdge; 										(* Neue Positionen merken	*)
	MouseY := TopEdge;

	Regs.AX := $0004;											(* Maus Cursor setzen		*)
	Regs.CX := LeftEdge SHL 3;
	Regs.DX := TopEdge SHL 3;
	Intr($33, Regs);											(* Maus Interrupt				*)
END; (* SetMouseXY *)

(* Diese Prozedur schrÑnkt den Bewegungsbereich des Maus Cursors ein *)
PROCEDURE SetMouseArea(LeftEdge, TopEdge, Width, Height : WORD);
VAR Regs : REGISTERS;
BEGIN
	Regs.AX := $0007;											(* Horizontale Grenzen		*)
	Regs.CX := LeftEdge SHL 3;
	Regs.DX := (LeftEdge + Width - 1) SHL 3;
	Intr($33, Regs);											(* Maus Interrupt				*)

	Regs.AX := $0008;											(* Vertikale Grenzen			*)
	Regs.CX := TopEdge SHL 3;
	Regs.DX := (TopEdge + Height - 1) SHL 3;
	Intr($33, Regs);
END; (* SetMouseArea *)

(* Diese Prozedur ordnet einem Bildschirmbereich eine Benutzernummer zu *)
PROCEDURE CreateArea(LeftEdge, TopEdge, Width, Height : BYTE; AreaNr : UserId);
VAR i : BYTE;
BEGIN
	IF (Width > 0) AND (Height > 0) AND  				(* BereichsprÅfung			*)
		(LeftEdge + Width <= NrOfColumns) AND
		(TopEdge + Height <= NrOfLines) AND
		(DefinedId[AreaNr].SizeX = 0) THEN 				(* Bereich nicht belegt		*)
	BEGIN
		FOR i := 0 TO Height - 1 DO						(* Bereich erzeugen			*)
			FillChar(UserArea^[(TopEdge + i) * NrOfColumns + LeftEdge], Width,
						AreaNr);

		WITH DefinedId[AreaNr] DO        				(* Bereichsdaten merken		*)
		BEGIN
			Column := LeftEdge;
			Line := TopEdge;
			SizeX := Width;
			SizeY := Height;
		END;
	END;
END; (* CreateArea *)

(* Diese Prozedur entfernt die Zuordnung zu einem Bildschirmbereich *)
PROCEDURE DeleteArea(AreaNr : UserId);
VAR i : BYTE;
BEGIN
	WITH DefinedId[AreaNr] DO    		    				(* Bereichsdaten berechnen	*)
	BEGIN
		IF SizeX > 0 THEN										(* GÅltige Benutzernummer	*)
		BEGIN
			FOR i := 0 TO SizeY - 1 DO  					(* Bereich lîschen 			*)
				FillChar(UserArea^[(Line + i) * NrOfColumns + Column], SizeX,
							NoUserId);

			Line := 0; 											(* Defaultwerte eintragen	*)
			Column := 0;
			SizeX := 0;
			SizeY := 0;
		END;
	END;
END; (* DeleteArea *)

(* Diese Prozedur holt ein Ereignis von den Warteschlangen *)
PROCEDURE GetEvent(VAR NewEvent : Event);
BEGIN
	REPEAT UNTIL IsEvent;									(* Warte auf Ereignis		*)

	IF IsMouseEvent AND IsKeyEvent THEN   				(* Tastatur, Maus Ereignis	*)
	BEGIN
		IF KeyRing^.Fifo[KeyRing^.Next].BiosTick < 	(* Zeiten vergleichen		*)
			MouseRing^.Fifo[MouseRing^.Next].BiosTick THEN
			Pop(KeyRing, NewEvent)     					(* Tastatur Ereignis			*)
		ELSE Pop(MouseRing, NewEvent);					(* Maus Ereignis				*)
	END
	ELSE IF IsKeyEvent THEN Pop(KeyRing, NewEvent)	(* Tastatur Ereignis	 		*)
	ELSE Pop(MouseRing, NewEvent);						(* Maus Ereignis				*)
END; (* GetEvent *)

(* NÑchstes Ereignis holen ohne es aus der Warteschlange zu nehmen *)
PROCEDURE LookEvent(VAR NewEvent : Event);
BEGIN
	IF NOT IsEvent THEN										(* Kein Ereignis vorhanden	*)
		NewEvent.BiosTick := MaxLongInt
	ELSE IF IsMouseEvent AND IsKeyEvent THEN  		(* Tastatur, Maus Ereignis	*)
	BEGIN
		IF KeyRing^.Fifo[KeyRing^.Next].BiosTick < 	(* Zeiten vergleichen		*)
			MouseRing^.Fifo[MouseRing^.Next].BiosTick THEN
			NewEvent := KeyRing^.Fifo[KeyRing^.Next]	(* Tastatur Ereignis			*)
		ELSE NewEvent := MouseRing^.Fifo[MouseRing^.Next];	(* Maus Ereignis 		*)
	END
	ELSE IF IsKeyEvent THEN 								(* Tastatur Ereignis	 		*)
		NewEvent := KeyRing^.Fifo[KeyRing^.Next]
	ELSE NewEvent := MouseRing^.Fifo[MouseRing^.Next];	(* Maus Ereignis 			*)
END; (* LookEvent *)

(* Diese Prozedur installiert einen Handler fÅr ein bestimmtes Ereignis *)
PROCEDURE InstallHandler(HandlerProc : EventHandler; OneEvent : Handlers);
BEGIN
	HandlerTable[OneEvent].Call := TRUE;				(* Handler ist installiert	*)
	HandlerTable[OneEvent].CallProc := HandlerProc;	(* Prozedur fÅr Ereignis	*)
END; (* InstallHandler *)

(* Diese Prozedur entfernt einen Handler fÅr ein bestimmtes Ereignis *)
PROCEDURE RemoveHandler(OneEvent : Handlers);
BEGIN
	HandlerTable[OneEvent].Call := FALSE;				(* Handler nicht vorhanden	*)
END; (* RemoveHandler *)

(* Diese Prozedur wartet auf ein Ereignis und ruft dessen Handler auf *)
PROCEDURE WaitEvent(StopEvents : HandlerSet);
VAR NewEvent 	 : Event;
	 CallHandler : Handlers;
BEGIN
	REPEAT                            					(* Schleife bis Stop Event	*)
		GetEvent(NewEvent);									(* Warte auf Ereignis		*)

		IF NewEvent.Mouse THEN								(* Maus Ereignis				*)
		BEGIN
			CASE NewEvent.mEvent OF
				EventMouseMove  : CallHandler := HandlerMouseMove;
				EventLeftDown   : CallHandler := HandlerLeftDown;
				EventLeftUp  	 : CallHandler := HandlerLeftUp;
				EventMiddleDown : CallHandler := HandlerMiddleDown;
				EventMiddleUp   : CallHandler := HandlerMiddleUp;
				EventRightDown  : CallHandler := HandlerRightDown;
				EventRightUp    : CallHandler := HandlerRightUp;
			END;
		END
		ELSE														(* Tastatur Ereignis			*)
		BEGIN
			CASE NewEvent.tEvent OF
				EventASCIICode 	: CallHandler := HandlerASCIICode;
				EventStatusChange : CallHandler := HandlerStatusChange;
				EventMakeCode     : CallHandler := HandlerMakeCode;
				EventReleaseCode	: CallHandler := HandlerReleaseCode;
			END;
		END;

		IF HandlerTable[CallHandler].Call THEN			(* Handler ist installiert	*)
			HandlerTable[CallHandler].CallProc(NewEvent);
	UNTIL CallHandler IN StopEvents;
END; (* WaitEvent *)

(* Es wird auch beim Loslassen einer Taste ein Ereignis erzeugt *)
PROCEDURE ReleaseCodeOn;
BEGIN
	ReleaseKey := TRUE;										(* Release Code erzeugen	*)
END; (* ReleaseCodeOn *)

(* Beim Loslassen einer Taste wird kein Ereignis erzeugt *)
PROCEDURE ReleaseCodeOff;
BEGIN
	ReleaseKey := FALSE;										(* Release Code ignorieren *)
END; (* ReleaseCodeOff *)

(* FÅr den Make Code der Tasten wird ein Ereignis erzeugt *)
PROCEDURE MakeCodeOn;
BEGIN
	MakeKey := TRUE;											(* Make Code erzeugen		*)
END; (* MakeCodeOn *)

(* FÅr den Make Code der Tasten wird kein Ereignis erzeugt *)
PROCEDURE MakeCodeOff;
BEGIN
	MakeKey := FALSE;	  		 								(* Make Code ignorieren 	*)
END; (* MakeCodeOff *)

(* Diese Funktion liefert den Tastaturstatus *)
FUNCTION GetKeyStatus : BYTE;
BEGIN
	GetKeyStatus := KeyStatus;								(* Status auslesen			*)
END; (* GetKeyStatus *)

(* Diese Prozedur entfernt die Interrupt Routine fÅr die Tastatur *)
PROCEDURE ReInstallKeyInterrupt;
BEGIN
	SetIntVec($09, Interrupt09);							(* Interrupt $09 setzen		*)
END; (* ReInstallKeyInterrupt *)

(* Diese Prozedur installiert die Interrupt Routine fÅr die Tastatur *)
PROCEDURE InstallKeyInterrupt;
BEGIN
	SetIntVec($09, Addr(KeyboardHandler));				(* Neuer Tastaturhandler	*)
END; (* InstallKeyInterrupt *)

(* Diese Prozedur legt den Tastaturstatus fest *)
PROCEDURE SetKeyStatus(Status : BYTE);
VAR Regs : REGISTERS;
BEGIN
	KeyStatus := KeyStatus OR Status;					(* Statusbits setzen			*)
	ActKeyStatus := KeyStatus;								(* Status aktualisieren		*)
	Regs.AH := $02;											(* Bios informieren			*)
	Intr($16, Regs); 											(* Tastatur Interrupt		*)

	Regs.AH := $01;											(* LED's anschalten			*)
	Intr($16, Regs); 											(* Tastatur Interrupt		*)
END; (* SetKeyStatus *)

(* Diese Prozedur lîscht Statusinformationen *)
PROCEDURE DelKeyStatus(Status : BYTE);
VAR Regs : REGISTERS;
BEGIN
	KeyStatus := KeyStatus AND (Status XOR $FF);		(* Statusbits lîschen		*)
	ActKeyStatus := KeyStatus;								(* Status aktualisieren		*)
	Regs.AH := $02;											(* Bios informieren			*)
	Intr($16, Regs); 											(* Tastatur Interrupt		*)

	Regs.AH := $01;											(* LED's ausschalten			*)
	Intr($16, Regs); 											(* Tastatur Interrupt		*)
END; (* DelKeyStatus *)

(* Diese Prozedur setzt die Typematic-Rate und die Delay-Rate der Tastatur *)
PROCEDURE SetKeySpeed(DelayRate, TypematicRate : BYTE);
VAR Regs : REGISTERS;
BEGIN
	Regs.AX := $0305;											(* Tastengeschwindigkeit	*)
	Regs.BH := DelayRate AND $03;							(* Nur Bits 0, 1 belassen	*)
	Regs.BL := TypematicRate AND $1F;					(* Nur Bits 0 - 4 belassen	*)
	Intr($16, Regs);      									(* Tastatur Interrupt		*)
END;

(*$F+ Diese Prozedur beendet die Arbeit mit der KeyMouse Unit *)
PROCEDURE DelKeyMouse;
VAR Regs : REGISTERS;
BEGIN
	SetIntVec($09, Interrupt09);							(* Interrupt $09 setzen		*)

	IF MouseAvail THEN										(* Maus vorhanden				*)
	BEGIN
		MouseOff;												(* Maus Cursor ausschalten	*)
		Regs.AX := $0000;										(* Reset des Maustreibers	*)
		Intr($33, Regs);								      (* Maus Interrupt				*)
	END;

	Dispose(KeyRing);                               (* Speicher freigeben   	*)
	Dispose(MouseRing);
	FreeMem(UserArea, NrOfLines * NrOfColumns);

	ExitProc := OldExitProc;								(* Mehrere Exit-Prozeduren	*)
END; (*$F- DelKeyMouse *)

(* Diese Prozedur initialisiert die KeyMouse Unit *)
PROCEDURE InitKeyMouse;
TYPE pBYTE = ^BYTE;											(* Zeiger auf ein Byte		*)
VAR Regs : REGISTERS;
BEGIN
	NrOfLines := pBYTE(Ptr($40, $84))^ + 1;    		(* Anzahl der Zeilen       *)
	NrOfColumns := pBYTE(Ptr($40, $4A))^;           (* Anzahl der Spalten      *)
	ActKeyStatus := KeyStatus;							  	(* Aktueller Tastenstatus	*)
	ReleaseCodeOff;											(* Release Code ignorieren	*)
	MakeCodeOff;												(* Make Code ignorieren		*)

	GetIntVec($09, Interrupt09);							(* Tastaturinterrupt			*)
	SetIntVec($09, Addr(KeyboardHandler));				(* Neuer Tastaturhandler	*)

	OldExitProc := ExitProc;								(* Exit-Prozedur merken		*)
	ExitProc := Addr(DelKeyMouse);						(* Neue Exit-Prozedur		*)

	New(KeyRing);	 	  										(* Speicher fÅr Ereignisse	*)
	KeyRing^.Last := 0;										(* Kein Ereignis enthalten	*)
	KeyRing^.Next := 0;										(* Kein Ereignis enthalten	*)

	New(MouseRing); 	 										(* Speicher fÅr Ereignisse	*)
	MouseRing^.Last := 0;									(* Kein Ereignis enthalten	*)
	MouseRing^.Next := 0;									(* Kein Ereignis enthalten	*)

	GetMem(UserArea, NrOfLines * NrOfColumns);		(* Speicher fÅr Bereiche	*)
	FillChar(UserArea^, NrOfLines * NrOfColumns, NoUserId);
	FillChar(DefinedId, SizeOf(DefinedId), 0);  		(* Kein Bereich definiert	*)
	FillChar(HandlerTable, SizeOf(HandlerTable), 0);(* Kein Handler vorhanden  *)

	Regs.AX := $0000;											(* Reset des Maustreibers	*)
	Intr($33, Regs);									      (* Maus Interrupt				*)
	MouseAvail := Regs.AX = $FFFF;

	IF MouseAvail THEN										(* Maus vorhanden				*)
	BEGIN
		NrOfButtons := Regs.BL;								(* Anzahl der Mausknîpfe	*)

		Regs.AX := $000C;										(* Maus-Handler festlegen  *)
		Regs.ES := Seg(MouseHandler);						(* Adresse als Far-Call		*)
		Regs.DX := Ofs(MouseHandler);
		Regs.CX := AllMouseEvents;							(* Alle Events erkennen		*)
		Intr($33, Regs);										(* Maus Interrupt				*)

		OldMouseX := 0;										(* Defaultwerte				*)
		OldMouseY := 0;
	END
	ELSE NrOfButtons := 0;		  							(* Maus nicht vorhanden		*)
END; (* InitKeyMouse *)

BEGIN 															(* Initialisierung			*)
	InitKeyMouse;
END. (* KeyMouse *)
