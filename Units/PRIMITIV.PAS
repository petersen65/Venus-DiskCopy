(****************************************************************)
(* Programmname	 : PRIMITIV.PAS V1.5 								 *)
(* Programmautor	 : Michael Rippl										 *)
(* Compiler 		 : Quick Pascal V1.0 								 *)
(* Inhalt			 : Primitive Routinen fr den Videospeicher	 *)
(* Bemerkung		 : Erkennt automatisch vorhandene Grafikkarte *)
(* Letzte Žnderung : 10-Sep-1990 										 *)
(****************************************************************)

UNIT Primitiv;

INTERFACE

USES Dos, Crt; 												(* Units einbinden			*)

TYPE Keys		 = (EndPageUp, EndPageDown, EndEscape, EndTabulator,
						 EndShiftTabulator, EndReturn, EndCursUp, EndCursDown);

	  Colors 	 = (Black, Blue, Green, Cyan, Red, Magenta, Brown, LightGrey,
						 DarkGrey, LightBlue, LightGreen, LightCyan, LightRed,
						 LightMagenta, Yellow, White);

	  VideoModes = (MDA, CGA, EGA, mEGA, VGA, mVGA, MCGA, mMCGA);
	  Direction  = (Horizontal, Vertical);
	  Scrolling  = (Up, Down, Left, Right);
	  Borders	 = (bSingle, bDouble, bDithering, bFull);
	  KeySet 	 = SET OF Keys;

	  pVideo 	 = ^Video;									(* Zeigt auf Videospeicher *)

	  Video		 = RECORD									(* Ein Videospeicherplatz	*)
							Character : CHAR; 				(* Ein Buchstabe				*)
							Attribute : BYTE; 				(* Sein Attribut				*)
						END;

VAR NrOfLines, 												(* Anzahl der Zeilen 		*)
	 NrOfColumns  : BYTE;									(* Anzahl der Spalten		*)
	 VideoMode	  : VideoModes;							(* Aktive Grafikkarte		*)
	 VideoSegment, 											(* Segment des Video-Rams	*)
	 VideoOffset  : WORD;									(* Offset des Video-Rams	*)
	 ColorGraphic : BOOLEAN;								(* Farbgrafik oder nicht	*)

(* Berechnet Zeiger in den Videospeicher *)
FUNCTION VideoPointer(Line, Column : BYTE) : pVideo;

(* Ein Teil des Videospeichers wird in einen Puffer gesichert *)
PROCEDURE VideoSave(LeftEdge, TopEdge, Width, Height : BYTE; Target : POINTER);

(* Ein Datenpuffer wird in den Videospeicher kopiert *)
PROCEDURE VideoLoad(LeftEdge, TopEdge, Width, Height : BYTE; Source : POINTER);

(* Erkennt automatisch eine vorhandene Grafikkarte im Rechner *)
PROCEDURE GetVideoMode(VAR VideoAdapter : VideoModes; VAR Color : BOOLEAN;
							  VAR Lines, Columns : BYTE; VAR VideoAddress : WORD);

(* Den echten Cursor setzen *)
PROCEDURE SetXY(X, Y : BYTE);

(* Berechnet die Position X des echten Cursors *)
FUNCTION GetX : BYTE;

(* Berechnet die Position Y des echten Cursors *)
FUNCTION GetY : BYTE;

(* Ein Teilbereich des Videospeichers wird mit einem Zeichen aufgefllt *)
PROCEDURE VideoFill(LeftEdge, TopEdge, Width, Height : BYTE; Character : CHAR;
						  DetailPen, BlockPen : Colors);

(* Ein Teilbereich des Bildschirms wird gescrollt *)
PROCEDURE VideoScroll(LeftEdge, TopEdge, Width, Height, Delta : BYTE;
							 DoScroll : Scrolling; DetailPen, BlockPen : Colors);

(* Es wird eine horizontale oder vertikale Line gezeichnet *)
PROCEDURE DrawLine(LeftEdge, TopEdge, LineLength : BYTE; Line : Direction;
						 Character : CHAR; DetailPen, BlockPen : Colors);

(* Es wird ein rechteckiger Rahmen auf den Bildschirm gezeichnet *)
PROCEDURE DrawBorder(LeftEdge, TopEdge, Width, Height : BYTE; Border : Borders;
							DetailPen, BlockPen : Colors);

(* Ein einzelnes Zeichen wird auf dem Bildschirm ausgegeben *)
PROCEDURE PutChar(LeftEdge, TopEdge : BYTE; Character : CHAR; DetailPen,
						BlockPen : Colors);

(* Ein Zeichenkette wird auf dem Bildschirm ausgegeben *)
PROCEDURE PutString(LeftEdge, TopEdge : BYTE; TextString : STRING; DetailPen,
						  BlockPen : Colors);

(* Fllt einen Bereich des Videospeichers mit einem Attribut *)
PROCEDURE PutAttributes(LeftEdge, TopEdge, Width, Height, Attribute : BYTE);

(* Fllt einen Bereich mit einem Zeichen auf ohne deren Attribute zu „ndern *)
PROCEDURE PutCharacters(LeftEdge, TopEdge, Width, Height : BYTE;
								Character : CHAR);

(* Zeichen an einer bestimmten Bildschirmposition zurckgeben *)
FUNCTION GetCharacter(LeftEdge, TopEdge : BYTE) : CHAR;

(* Attribut an einer bestimmten Bildschirmposition zurckgeben *)
FUNCTION GetAttribute(LeftEdge, TopEdge : BYTE) : BYTE;

(* Es wird der gesamte Bildschirm gel”scht *)
PROCEDURE ClearScreen;

(* Die Gestalt des Cursors wird definiert *)
PROCEDURE CursorDefine(Start, Stop : BYTE);

(* Der Cursor wird vom Bildschirm entfernt *)
PROCEDURE CursorOff;

(* Der Cursor erh„lt die Gestalt eines vollen Blocks *)
PROCEDURE CursorBlock;

(* Der Cursor erh„lt die Gestalt einer Linie *)
PROCEDURE CursorLine;

(* Es wird eine Zeichenkette vom Bildschirm eingelesen *)
PROCEDURE VideoRead(LeftEdge, TopEdge, Width : BYTE; VAR TextString : STRING;
						  DetailPen, BlockPen : Colors; VAR EndKeys : KeySet;
						  FillWidth, TextOutput : BOOLEAN);

IMPLEMENTATION

TYPE Address = RECORD										(* Zugriff auf Zeiger		*)
						Offset,
						Segment : WORD;
					END;

(* Berechnet Zeiger in den Videospeicher *)
FUNCTION VideoPointer(Line, Column : BYTE) : pVideo;
BEGIN
	VideoPointer := Ptr(VideoSegment, VideoOffset +
							  ((NrOfColumns * Line + Column) SHL 1));
END; (* VideoPointer *)

(* Ein Teil des Videospeichers wird in einen Puffer gesichert *)
PROCEDURE VideoSave(LeftEdge, TopEdge, Width, Height : BYTE; Target : POINTER);
VAR NrOfBytes : INTEGER;
	 k 		  : BYTE;
	 Source	  : pVideo;
BEGIN
	NrOfBytes := Width SHL 1;								(* Zu kopierende Bytes		*)

	FOR k := 1 TO Height DO
	BEGIN
		Source := VideoPointer(TopEdge, LeftEdge);	(* Quelladresse				*)
		Move(Source^, Target^, NrOfBytes);				(* Eine Zeile kopieren		*)
		Inc(Address(Target).Offset, NrOfBytes);		(* Neue Zieladresse			*)
		Inc(TopEdge);											(* Neue Zeile					*)
	END;
END; (* VideoSave *)

(* Ein Datenpuffer wird in den Videospeicher kopiert *)
PROCEDURE VideoLoad(LeftEdge, TopEdge, Width, Height : BYTE; Source : POINTER);
VAR NrOfBytes : INTEGER;
	 k 		  : BYTE;
	 Target	  : pVideo;
BEGIN
	NrOfBytes := Width SHL 1;								(* Zu kopierende Bytes		*)

	FOR k := 1 TO Height DO
	BEGIN
		Target := VideoPointer(TopEdge, LeftEdge);	(* Zieladresse 				*)
		Move(Source^, Target^, NrOfBytes);				(* Eine Zeile kopieren		*)
		Inc(Address(Source).Offset, NrOfBytes);		(* Neue Zieladresse			*)
		Inc(TopEdge);											(* Neue Zeile					*)
	END;
END; (* VideoLoad *)

(* Den echten Cursor setzen *)
PROCEDURE SetXY(X, Y : BYTE);
VAR Regs : REGISTERS;
BEGIN
	Regs.AH := $2; 											(* Funktion 2					*)
	Regs.BH := 0;												(* Bildschirmseite 0 		*)
	Regs.DH := Y;												(* Zeile setzen				*)
	Regs.DL := X;												(* Spalte setzen				*)
	Intr($10, Regs);											(* Video Interrupt			*)
END; (* SetXY *)

(* Berechnet die Position X des echten Cursors *)
FUNCTION GetX : BYTE;
BEGIN
	GetX := WhereX - 1;
END; (* GetX *)

(* Berechnet die Position Y des echten Cursors *)
FUNCTION GetY : BYTE;
BEGIN
	GetY := WhereY - 1;
END; (* GetY *)

(* Ein einzelnes Zeichen wird ausgegeben *)
PROCEDURE PutChar(LeftEdge, TopEdge : BYTE; Character : CHAR; DetailPen,
						BlockPen : Colors);
VAR Target : pVideo;
BEGIN
	Target := VideoPointer(TopEdge, LeftEdge);

	Target^.Character := Character;						(* Zeichen eintragen 		*)
	Target^.Attribute := (Ord(BlockPen) SHL 4) OR Ord(DetailPen);
END; (* PutChar *)

(* Ein Zeichenkette wird auf dem Bildschirm ausgegeben *)
PROCEDURE PutString(LeftEdge, TopEdge : BYTE; TextString : STRING; DetailPen,
						  BlockPen : Colors);
VAR k,
	 Attribute : BYTE;
	 Target	  : pVideo;
BEGIN
	Attribute := (Ord(BlockPen) SHL 4) OR Ord(DetailPen);
	Target := VideoPointer(TopEdge, LeftEdge);

	FOR k := 1 TO Ord(TextString[0]) DO 				(* Text ausgeben				*)
	BEGIN
		Target^.Character := TextString[k];
		Target^.Attribute := Attribute;

		Inc(Address(Target).Offset, 2);					(* N„chstes Zeichen			*)
	END;
END; (* PutString *)

(* Fllt einen Bereich des Videospeichers mit einem Attribut *)
PROCEDURE PutAttributes(LeftEdge, TopEdge, Width, Height, Attribute : BYTE);
VAR i,
	 k 	  : BYTE;
	 Target : pVideo;
BEGIN
	FOR k := 1 TO Height DO
	BEGIN
		Target := VideoPointer(TopEdge, LeftEdge);

		FOR i := 1 TO Width DO
		BEGIN
			Target^.Attribute := Attribute;				(* Attribut eintragen		*)
			Inc(Address(Target).Offset, 2);				(* N„chstes Attribut 		*)
		END;

		Inc(TopEdge);											(* N„chste Zeile				*)
	END;
END; (* PutAttributes *)

(* Fllt einen Bereich mit einem Zeichen auf ohne deren Attribute zu „ndern *)
PROCEDURE PutCharacters(LeftEdge, TopEdge, Width, Height : BYTE;
								Character : CHAR);
VAR i,
	 k 	  : BYTE;
	 Target : pVideo;
BEGIN
	FOR k := 1 TO Height DO
	BEGIN
		Target := VideoPointer(TopEdge, LeftEdge);

		FOR i := 1 TO Width DO
		BEGIN
			Target^.Character := Character;				(* Zeichen eintragen 		*)
			Inc(Address(Target).Offset, 2);				(* N„chstes Zeichen			*)
		END;

		Inc(TopEdge);											(* N„chste Zeile				*)
	END;
END; (* PutCharacters *)

(* Zeichen an einer bestimmten Bildschirmposition zurckgeben *)
FUNCTION GetCharacter(LeftEdge, TopEdge : BYTE) : CHAR;
VAR Target : pVideo;
BEGIN
	Target := VideoPointer(TopEdge, LeftEdge);
	GetCharacter := Target^.Character;					(* Zeichen auslesen			*)
END; (* GetCharacter *)

(* Attribut an einer bestimmten Bildschirmposition zurckgeben *)
FUNCTION GetAttribute(LeftEdge, TopEdge : BYTE) : BYTE;
VAR Target : pVideo;
BEGIN
	Target := VideoPointer(TopEdge, LeftEdge);
	GetAttribute := Target^.Attribute;					(* Attribut auslesen 		*)
END; (* GetAttribute *)

(* Es wird der gesamte Bildschirm gel”scht *)
PROCEDURE ClearScreen;
BEGIN
	PutCharacters(0, 0, NrOfColumns, NrOfLines, ' ');
END; (* ClearScreen *)

(* Der Cursor wird vom Bildschirm entfernt *)
PROCEDURE CursorOff;
VAR Regs : REGISTERS;
BEGIN
	SetXY(0, NrOfLines + 1);								(* Auáerhalb des Bildes 	*)
END; (* CursorOff *)

(* Die Gestalt des Cursors wird definiert *)
PROCEDURE CursorDefine(Start, Stop : BYTE);
VAR Regs : REGISTERS;
BEGIN
	Regs.AH := $1; 											(* Funktion 1					*)
	Regs.CH := Start; 										(* Video Scan-Zeile Beginn *)
	Regs.CL := Stop;											(* Video Scan-Zeile Ende	*)
	Intr($10, Regs);											(* Video Interrupt			*)
END; (* CursorDefine *)

(* Der Cursor erh„lt die Gestalt eines vollen Blocks *)
PROCEDURE CursorBlock;
BEGIN
	IF ColorGraphic THEN 									(* Color Modus 				*)
		CursorDefine(0, 7)
	ELSE CursorDefine(0, 13);								(* Monochrom Modus			*)
END; (* CursorBlock *)

(* Der Cursor erh„lt die Gestalt einer Linie *)
PROCEDURE CursorLine;
BEGIN
	IF ColorGraphic THEN 									(* Color Modus 				*)
		CursorDefine(6, 7)
	ELSE CursorDefine(12, 13); 							(* Monochrom Modus			*)
END; (* CursorLine *)

(* Es wird eine horizontale oder vertikale Linie gezeichnet *)
PROCEDURE DrawLine(LeftEdge, TopEdge, LineLength : BYTE; Line : Direction;
						 Character : CHAR; DetailPen, BlockPen : Colors);
VAR k 		  : BYTE;
	 Target	  : pVideo;
	 Attribute : BYTE;
BEGIN
	Attribute := (Ord(BlockPen) SHL 4) OR Ord(DetailPen);

	IF Line = Horizontal THEN								(* Horizontale Linie 		*)
	BEGIN
		Target := VideoPointer(TopEdge, LeftEdge);

		FOR k := 1 TO LineLength DO						(* Linie zeichnen 			*)
		BEGIN
			Target^.Character := Character;				(* Zeichen eintragen 		*)
			Target^.Attribute := Attribute;

			Inc(Address(Target).Offset, 2);				(* N„chstes Zeichen			*)
		END;
	END
	ELSE															(* Vertikale Linie			*)
	BEGIN
		FOR k := 1 TO LineLength DO						(* Linie zeichnen 			*)
		BEGIN
			Target := VideoPointer(TopEdge, LeftEdge);

			Target^.Character := Character;				(* Zeichen eintragen 		*)
			Target^.Attribute := Attribute;

			Inc(TopEdge);										(* N„chstes Zeichen			*)
		END;
	END;
END; (* DrawLine *)

(* Es wird ein rechteckiger Rahmen auf den Bildschirm gezeichnet *)
PROCEDURE DrawBorder(LeftEdge, TopEdge, Width, Height : BYTE; Border : Borders;
							DetailPen, BlockPen : Colors);
VAR Character : CHAR;
BEGIN
	CASE Border OF 											(* Horizontale Linien		*)
		bSingle	  : Character := Chr(196);
		bDouble	  : Character := Chr(205);
		bDithering : Character := Chr(177);
		bFull 	  : Character := Chr(219);
	END;

	DrawLine(LeftEdge, TopEdge, Width, Horizontal, Character, DetailPen,
				BlockPen);

	DrawLine(LeftEdge, TopEdge + Height - 1, Width, Horizontal, Character,
				DetailPen, BlockPen);

	IF Border = bSingle THEN Character := Chr(179)	(* Vertikale Linien			*)
	ELSE IF Border = bDouble THEN Character := Chr(186);

	DrawLine(LeftEdge, TopEdge, Height, Vertical, Character, DetailPen,
				BlockPen);

	DrawLine(LeftEdge + Width - 1, TopEdge, Height, Vertical, Character,
				DetailPen, BlockPen);

	IF Border = bSingle THEN								(* Eckpunkte zeichnen		*)
	BEGIN
		PutChar(LeftEdge, TopEdge, Chr(218), DetailPen, BlockPen);
		PutChar(LeftEdge + Width - 1, TopEdge, Chr(191), DetailPen, BlockPen);
		PutChar(LeftEdge, TopEdge + Height - 1, Chr(192), DetailPen, BlockPen);

		PutChar(LeftEdge + Width - 1, TopEdge + Height - 1, Chr(217), DetailPen,
				  BlockPen);
	END
	ELSE IF Border = bDouble THEN 					(* Eckpunkte zeichnen		*)
	BEGIN
		PutChar(LeftEdge, TopEdge, Chr(201), DetailPen, BlockPen);
		PutChar(LeftEdge + Width - 1, TopEdge, Chr(187), DetailPen, BlockPen);
		PutChar(LeftEdge, TopEdge + Height - 1, Chr(200), DetailPen, BlockPen);

		PutChar(LeftEdge + Width - 1, TopEdge + Height - 1, Chr(188), DetailPen,
				  BlockPen);
	END;
END; (* DrawBorder *)

(* Ein Teilbereich des Videospeichers wird mit einem Zeichen aufgefllt *)
PROCEDURE VideoFill(LeftEdge, TopEdge, Width, Height : BYTE; Character : CHAR;
						  DetailPen, BlockPen : Colors);
VAR i,
	 k,
	 Attribute : BYTE;
	 Target	  : pVideo;
BEGIN
	Attribute := (Ord(BlockPen) SHL 4) OR Ord(DetailPen);

	FOR k := 1 TO Height DO
	BEGIN
		Target := VideoPointer(TopEdge, LeftEdge);

		FOR i := 1 TO Width DO
		BEGIN
			Target^.Character := Character;				(* Zeichen eintragen 		*)
			Target^.Attribute := Attribute;

			Inc(Address(Target).Offset, 2);				(* N„chstes Zeichen			*)
		END;

		Inc(TopEdge);											(* N„chste Zeile				*)
	END;
END; (* VideoFill *)

(* Ein Teilbereich des Bildschirms wird gescrollt *)
PROCEDURE VideoScroll(LeftEdge, TopEdge, Width, Height, Delta : BYTE;
							 DoScroll : Scrolling; DetailPen, BlockPen : Colors);
VAR NrOfBytes,
	 LineOffset : INTEGER;
	 k 			: BYTE;
	 Source,
	 Target		: pVideo;
BEGIN
	LineOffset := NrOfColumns SHL 1; 					(* Anzahl der Zeilen * 2	*)
	NrOfBytes := Width SHL 1;								(* Breite * 2					*)

	CASE DoScroll OF
		Up :														(* Nach oben scrollen		*)
		BEGIN
			Target := VideoPointer(TopEdge, LeftEdge);
			Source := VideoPointer(TopEdge + Delta, LeftEdge);

			FOR k := 1 TO Height - Delta DO				(* Zeilen kopieren			*)
			BEGIN
				Move(Source^, Target^, NrOfBytes);
				Inc(Address(Source).Offset, LineOffset);
				Inc(Address(Target).Offset, LineOffset);
			END;

			VideoFill(LeftEdge, TopEdge + Height - Delta, Width, Delta, ' ',
						 DetailPen, BlockPen);
		END;

		Down :													(* Nach unten scrollen		*)
		BEGIN
			Target := VideoPointer(TopEdge + Height - 1, LeftEdge);
			Source := VideoPointer(TopEdge + Height - 1 - Delta, LeftEdge);

			FOR k := 1 TO Height - Delta DO				(* Zeilen kopieren			*)
			BEGIN
				Move(Source^, Target^, NrOfBytes);
				Dec(Address(Source).Offset, LineOffset);
				Dec(Address(Target).Offset, LineOffset);
			END;

			VideoFill(LeftEdge, TopEdge, Width, Delta, ' ', DetailPen, BlockPen);
		END;

		Left :													(* Nach links scrollen		*)
		BEGIN
			Target := VideoPointer(TopEdge, LeftEdge);
			Source := VideoPointer(TopEdge, LeftEdge + Delta);

			FOR k := 1 TO Height DO 						(* Zeilen kopieren			*)
			BEGIN
				Move(Source^, Target^, NrOfBytes - (Delta SHL 1));
				Inc(Address(Source).Offset, LineOffset);
				Inc(Address(Target).Offset, LineOffset);
			END;

			VideoFill(LeftEdge + Width - Delta, TopEdge, Delta, Height, ' ',
						 DetailPen, BlockPen);
		END;

		Right :													(* Nach rechts scrollen 	*)
		BEGIN
			Target := VideoPointer(TopEdge, LeftEdge + Delta);
			Source := VideoPointer(TopEdge, LeftEdge);

			FOR k := 1 TO Height DO 						(* Zeilen kopieren			*)
			BEGIN
				Move(Source^, Target^, NrOfBytes - (Delta SHL 1));
				Inc(Address(Source).Offset, LineOffset);
				Inc(Address(Target).Offset, LineOffset);
			END;

			VideoFill(LeftEdge, TopEdge, Delta, Height, ' ', DetailPen, BlockPen);
		END;
	END;
END; (* VideoScroll *)

(* Es wird eine Zeichenkette vom Bildschirm eingelesen *)
PROCEDURE VideoRead(LeftEdge, TopEdge, Width : BYTE; VAR TextString : STRING;
						  DetailPen, BlockPen : Colors; VAR EndKeys : KeySet;
						  FillWidth, TextOutput : BOOLEAN);
CONST CR 		= 13; 										(* Carriage Return			*)
		BS 		= 8;											(* Back Space					*)
		ESC		= 27; 										(* Escape						*)
		TAB		= 9;											(* Tabulator					*)
		ShiftTab = 15; 										(* Shift Tabulator			*)
		Pos1Key  = 71;											(* Pos1 Taste					*)
		EndKey   = 79;											(* Ende Taste					*)
		CurUp 	= 72; 										(* Cursor Up					*)
		CurDown	= 80; 										(* Cursor Down 				*)
		CurLeft	= 75; 										(* Cursor Left 				*)
		CurRight = 77; 										(* Cursor Right				*)
		PgDn		= 81; 										(* Page Down					*)
		PgUp		= 73; 										(* Page Up						*)
		Insert	= 82; 										(* Insert Taste				*)
		Delete	= 83; 										(* Delete Taste				*)
		ScanCode = 0;											(* Taste liefert Scan Code *)
VAR DoLoop,
	 DoInsert  : BOOLEAN;
	 k,
	 CursorX,													(* Position des Cursors 	*)
	 NrOfChars : BYTE;										(* Eingegebene Buchstaben	*)
	 Character : CHAR;
	 NrOfBytes : INTEGER;
	 Source,
	 Target	  : pVideo;
BEGIN
	CursorLine; 												(* Cursor definieren 		*)
	SetXY(LeftEdge, TopEdge);

	IF FillWidth THEN 										(* Textbereich einf„rben	*)
		PutAttributes(LeftEdge, TopEdge, Width, 1,
						  (Ord(BlockPen) SHL 4) OR Ord(DetailPen));

	NrOfChars := 0;											(* Noch nichts eingegeben	*)
	CursorX := 0;												(* Cursor ganz links 		*)
	DoInsert := FALSE;										(* Texte berschreiben		*)
	DoLoop := TRUE;											(* Eingaben entgegennehmen *)

	IF TextOutput THEN										(* Defaulttext ausgeben 	*)
	BEGIN
		IF Ord(TextString[0]) > Width THEN TextString[0] := Chr(Width);

		NrOfChars := Ord(TextString[0]); 				(* Text bereits vorhanden	*)
		PutString(LeftEdge, TopEdge, TextString, DetailPen, BlockPen);
	END;

	REPEAT
		REPEAT UNTIL KeyPressed;							(* Warten auf Tastendruck	*)
		Character := ReadKey;								(* Zeichen einlesen			*)

		IF Character = Chr(ScanCode) THEN				(* Taste liefert Scan Code *)
		BEGIN
			Character := ReadKey;							(* Tastencode einlesen		*)

			CASE Ord(Character) OF
				CurLeft :										(* Cursor nach links 		*)
				BEGIN
					IF CursorX > 0 THEN						(* Kein linker Rand			*)
					BEGIN
						SetXY(GetX - 1, GetY);				(* Cursor setzen				*)
						Dec(CursorX);
					END
					ELSE Write(Chr(7));						(* Unerlaubt = Piepston 	*)
				END;

				CurRight :										(* Cursor nach rechts		*)
				BEGIN
					IF (CursorX < NrOfChars) AND (CursorX < Width - 1) THEN
					BEGIN
						SetXY(GetX + 1, GetY);				(* Cursor setzen				*)
						Inc(CursorX);
					END
					ELSE Write(Chr(7));						(* Unerlaubt = Piepston 	*)
				END;

				Pos1Key :										(* Cursor erste Position	*)
				BEGIN
					SetXY(GetX - CursorX, GetY);			(* Anfang Eingabefeld		*)
					CursorX := 0;								(* Cursor am Feldanfang		*)
				END;

				EndKey :											(* Cursor letzte Position	*)
				BEGIN
					SetXY(GetX - CursorX + NrOfChars, GetY);
					CursorX := NrOfChars;  					(* Cursor am Feldende		*)
				END;

				Insert : 										(* šberschreiben/Einfgen	*)
				BEGIN
					DoInsert := NOT DoInsert;

					IF DoInsert THEN CursorBlock			(* Block = Einfgen			*)
					ELSE CursorLine;							(* Line = šberschreiben 	*)
				END;

				Delete : 										(* Buchstabe l”schen 		*)
				BEGIN
					IF (NrOfChars = 0) OR (CursorX >= NrOfChars) THEN
						Write(Chr(7))							(* Nichts mehr zu l”schen	*)
					ELSE
					BEGIN 										(* Buchstabe l”schen 		*)
						NrOfBytes := NrOfChars - CursorX;

						IF NrOfBytes > 0 THEN				(* Text zu kopieren			*)
						BEGIN
							Source := VideoPointer(TopEdge, LeftEdge + CursorX + 1);
							Target := VideoPointer(TopEdge, LeftEdge + CursorX);

							Move(Source^, Target^, NrOfBytes SHL 1);

							Move(TextString[CursorX + 2], TextString[CursorX + 1],
								  NrOfBytes);
						END;

						PutChar(LeftEdge + NrOfChars - 1, TopEdge, ' ', DetailPen,
								  BlockPen);

						Dec(NrOfChars);
					END;
				END;

				PgDn :											(* Page Down Taste			*)
				BEGIN
					IF EndPageDown IN EndKeys THEN		(* PageDown = Ende			  *)
					BEGIN
						TextString[0] := Chr(NrOfChars); (* Textl„nge eintragen		*)
						CursorLine;
						EndKeys := [EndPageDown];			(* Mit PageDown beendet 	  *)
						DoLoop := FALSE;
					END
					ELSE Write(Chr(7));						(* Taste unzul„ssig			*)
				END;

				PgUp :											(* Page Up Taste				*)
				BEGIN
					IF EndPageUp IN EndKeys THEN			(* PageUp = Ende				*)
					BEGIN
						TextString[0] := Chr(NrOfChars); (* Textl„nge eintragen		*)
						CursorLine;
						EndKeys := [EndPageUp];   			(* Mit PageUp beendet		*)
						DoLoop := FALSE;
					END
					ELSE Write(Chr(7));						(* Taste unzul„ssig			*)
				END;

				ShiftTab :										(* Shift TAB Taste			*)
				BEGIN
					IF EndShiftTabulator IN EndKeys THEN(* ShiftTabulator = Ende	*)
					BEGIN
						TextString[0] := Chr(NrOfChars); (* Textl„nge eintragen		*)
						CursorLine;
						EndKeys := [EndShiftTabulator];	(* Mit ShiftTab beendet 	*)
						DoLoop := FALSE;
					END
					ELSE Write(Chr(7));						(* Taste unzul„ssig			*)
				END;

				CurUp :											(* Cursor Up Taste			*)
				BEGIN
					IF EndCursUp IN EndKeys THEN			(* CursorUp = Ende			*)
					BEGIN
						TextString[0] := Chr(NrOfChars); (* Textl„nge eintragen		*)
						CursorLine;
						EndKeys := [EndCursUp];		  		(* Mit CursorUp beendet 	*)
						DoLoop := FALSE;
					END
					ELSE Write(Chr(7));						(* Taste unzul„ssig			*)
				END;

				CurDown :										(* Cursor Down Taste 		*)
				BEGIN
					IF EndCursDown IN EndKeys THEN 		(* CursorDown = Ende 		*)
					BEGIN
						TextString[0] := Chr(NrOfChars); (* Textl„nge eintragen		*)
						CursorLine;
						EndKeys := [EndCursDown];	  		(* Mit CursorDown beendet	*)
						DoLoop := FALSE;
					END
					ELSE Write(Chr(7));						(* Taste unzul„ssig			*)
				END;
			ELSE
				Write(Chr(7)); 								(* Fremde Taste = Piepston *)
			END;
		END
		ELSE														(* Normales Zeichen			*)
		BEGIN
			CASE Ord(Character) OF
				BS :												(* Back Space Taste			*)
				BEGIN
					IF (CursorX = 0) OR (NrOfChars = 0) THEN
						Write(Chr(7))							(* Nichts mehr zu l”schen	*)
					ELSE
					BEGIN 										(* Buchstabe l”schen 		*)
						NrOfBytes := NrOfChars - CursorX;

						IF NrOfBytes > 0 THEN				(* Text zu kopieren			*)
						BEGIN
							Source := VideoPointer(TopEdge, LeftEdge + CursorX);
							Target := VideoPointer(TopEdge, LeftEdge + CursorX - 1);

							Move(Source^, Target^, NrOfBytes SHL 1);

							Move(TextString[CursorX + 1], TextString[CursorX],
								  NrOfBytes);
						END;

						PutChar(LeftEdge + NrOfChars - 1, TopEdge, ' ', DetailPen,
								  BlockPen);

						Dec(CursorX);							(* Cursor setzen				*)
						SetXY(GetX - 1, GetY);
						Dec(NrOfChars);
					END;
				END;

				CR :												(* Carriage Return Taste	*)
				BEGIN
					IF EndReturn IN EndKeys THEN			(* Return = Ende				*)
					BEGIN
						TextString[0] := Chr(NrOfChars); (* Textl„nge eintragen		*)
						CursorLine;
						EndKeys := [EndReturn]; 			(* Mit Return beendet		*)
						DoLoop := FALSE;
					END
					ELSE Write(Chr(7));						(* Taste unzul„ssig			*)
				END;

				ESC : 											(* Escape Taste				*)
				BEGIN
					IF EndEscape IN EndKeys THEN			(* Escape = Ende				*)
					BEGIN
						TextString[0] := Chr(NrOfChars); (* Textl„nge eintragen		*)
						CursorLine;
						EndKeys := [EndEscape]; 			(* Mit Escape beendet		*)
						DoLoop := FALSE;
					END
					ELSE Write(Chr(7));						(* Taste unzul„ssig			*)
				END;

				TAB : 											(* Tabulator Taste			*)
				BEGIN
					IF EndTabulator IN EndKeys THEN		(* Tabulator = Ende				*)
					BEGIN
						TextString[0] := Chr(NrOfChars); (* Textl„nge eintragen		*)
						CursorLine;
						EndKeys := [EndTabulator];   		(* Mit Tabulator beendet		*)
						DoLoop := FALSE;
					END
					ELSE Write(Chr(7));						(* Taste unzul„ssig			*)
				END;
			ELSE													(* Keine besondere Taste	*)
				IF DoInsert THEN								(* Text einfgen				*)
				BEGIN
					IF NrOfChars = Width THEN				(* Einfgen nicht m”glich	*)
						Write(Chr(7))							(* Piepston 					*)
					ELSE
					BEGIN 										(* Einfgen m”glich			*)
						NrOfBytes := NrOfChars - CursorX;

						IF NrOfBytes > 0 THEN				(* Text zu kopieren			*)
						BEGIN
							Source := VideoPointer(TopEdge, LeftEdge + CursorX);
							Target := VideoPointer(TopEdge, LeftEdge + CursorX + 1);

							Move(Source^, Target^, NrOfBytes SHL 1);

							Move(TextString[CursorX + 1], TextString[CursorX + 2],
								  NrOfBytes);
						END;

						PutChar(LeftEdge + CursorX, TopEdge, Character, DetailPen,
								  BlockPen);

						TextString[CursorX + 1] := Character;

						IF CursorX < Width - 1 THEN		(* Noch kein rechter Rand	*)
						BEGIN
							Inc(CursorX);
							SetXY(GetX + 1, GetY);
						END;

						Inc(NrOfChars);
					END;
				END
				ELSE												(* Text berschreiben		*)
				BEGIN
					PutChar(LeftEdge + CursorX, TopEdge, Character, DetailPen,
							  BlockPen);

					TextString[CursorX + 1] := Character;

					IF (Width > 1) AND (CursorX = Width - 2) AND
						(CursorX = NrOfChars - 1) THEN 	(* Leider ein Spezialfall	*)
					BEGIN
						Inc(CursorX);
						SetXY(GetX + 1, GetY);
					END
					ELSE											(* šbliche Behandlung		*)
					BEGIN
						IF CursorX < Width - 1 THEN		(* Noch kein rechter Rand	*)
						BEGIN
							Inc(CursorX);
							SetXY(GetX + 1, GetY);
						END;

						IF NrOfChars < CursorX THEN	  	(* Platz zum Schreiben		*)
							Inc(NrOfChars)
						ELSE IF NrOfChars = CursorX THEN	(* Alles beschrieben 		*)
						BEGIN
							IF (CursorX = Width - 1) AND (NrOfChars < Width) THEN
								Inc(NrOfChars);
						END;
					END;
				END;
			END;
		END;
	UNTIL NOT DoLoop;
END; (* VideoRead *)

(* Erkennt automatisch eine vorhandene Grafikkarte im Rechner *)
PROCEDURE GetVideoMode(VAR VideoAdapter : VideoModes; VAR Color : BOOLEAN;
							  VAR Lines, Columns : BYTE; VAR VideoAddress : WORD);
TYPE pByte = ^BYTE;
VAR Regs 	: REGISTERS;
	 Adapter : BYTE;
BEGIN
	Adapter := $FF;											(* Noch kein Videoadapter	*)

	Regs.AX := $1A00; 										(* Test auf VGA oder MCGA	*)
	Intr($10, Regs);											(* Video Interrupt			*)

	IF Regs.AL = $1A THEN									(* VGA oder MCGA				*)
	BEGIN
		Adapter := Regs.BL;

		CASE Adapter OF										(* Aktiver Modus der VGA	*)
			1	: VideoAdapter := MDA;
			2	: VideoAdapter := CGA;
			4	: VideoAdapter := EGA;
			5	: VideoAdapter := mEGA;
			7	: VideoAdapter := mVGA;
			8	: VideoAdapter := VGA;
			10 : VideoAdapter := MCGA;
			11 : VideoAdapter := mMCGA;
			12 : VideoAdapter := MCGA;
		END;

		Color := NOT ((VideoAdapter = MDA) OR (VideoAdapter = mEGA));
	END
	ELSE															(* Keine VGA oder MCGA		*)
	BEGIN
		Regs.AH := $12;										(* Test auf EGA				*)
		Regs.BL := $10;
		Intr($10, Regs);										(* Video Interrupt			*)

		IF Regs.BL <> $10 THEN								(* EGA Karte installiert	*)
		BEGIN
			Adapter := (Regs.CL SHR 1) DIV 3;

			CASE Adapter OF									(* Modus der EGA				*)
				0	: VideoAdapter := EGA;
				1	: VideoAdapter := EGA;
				2	: VideoAdapter := mEGA;
			END;

			Color := VideoAdapter <> mEGA;
		END;
	END;

	Regs.AH := $F; 											(* Aktueller Videomodus 	*)
	Intr($10, Regs);											(* Video Interrupt			*)

	IF Regs.AL = 7 THEN VideoAddress := $B000 		(* Monochrom Modus			*)
	ELSE VideoAddress := $B800;							(* Color Modus 				*)

	IF Adapter = $FF THEN									(* Keine VGA, EGA, MCGA 	*)
	BEGIN
		IF Regs.AL = 7 THEN VideoAdapter := MDA
		ELSE VideoAdapter := CGA;

		NrOfLines := 25;										(* 25 Zeilen Modus			*)

		Color := NOT ((Regs.AL = 0) OR (Regs.AL = 2) OR (Regs.AL = 7));
	END
	ELSE NrOfLines := pBYTE(Ptr($40, $84))^ + 1; 	(* Anzahl der Zeilen 		*)

	NrOfColumns := pBYTE(Ptr($40, $4A))^;				(* Anzahl der Spalten		*)

	Regs.AH := $5; 											(* Bildschirmseite Null 	*)
	Regs.AL := $0;
	Intr($10, Regs);											(* Video Interrupt			*)
END; (* GetVideoMode *)

BEGIN (* Primitiv *)
	GetVideoMode(VideoMode, ColorGraphic, NrOfLines, NrOfColumns, VideoSegment);
	VideoOffset := $0000;									(* Anfang des Video-Rams	*)
END. (* Primitiv *)
