(****************************************************************)
(* Programmname    : WINDOWS.PAS V2.7                           *)
(* Programmautor   : Michael Rippl                              *)
(* Compiler        : Quick Pascal V1.0                          *)
(* Inhalt          : Routinen f�r Fensterverwaltung             *)
(* Bemerkung       : -														 *)
(* Letzte �nderung : 20-Sep-1990                                *)
(****************************************************************)

UNIT Windows;

INTERFACE

USES Crt, Primitiv, Lifo;                         	(* Units einbinden         *)

TYPE WindowFlags = (Single, Double, Dithering, Full, Shadow, Title, Cursor,
						  Simple);

	  WinFlagSet  = SET OF WindowFlags;
	  pWindow     = ^Window;                        (* Zeiger auf Fenster      *)

	  Window      = RECORD                          (* Definition des Fensters *)
							 LeftEdge,                    (* Linke Spalte            *)
							 TopEdge,                     (* Obere Zeile             *)
							 Width,                       (* Breite des Fensters     *)
							 Height       : BYTE;         (* H�he des Fensters       *)
							 DetailPen,                   (* Farbe des Rahmens       *)
							 BlockPen     : Colors;       (* Farbe des Fensters      *)
							 Flags        : WinFlagSet;   (* Attribute des Fensters  *)
							 WinTitle     : STRING[64];   (* Fenstertitel            *)
							 CursorX,                     (* Aktuelle Cursorposition *)
							 CursorY,
							 VirtualX,                    (* Virtueller Cursor       *)
							 VirtualY     : BYTE;
							 Buffer,                      (* Fensterpuffer           *)
							 ForeGround,                  (* Kopie von Fensterinhalt *)
							 ShadowBuffer : ^BYTE;        (* Puffer f�r Schatten     *)
						 END;

(* Es wird ein neues Fenster ge�ffnet *)
FUNCTION OpenWindow(NewWindow : Window) : pWindow;

(* Das aktive Fenster wird geschlossen *)
FUNCTION CloseWindow : BOOLEAN;

(* Das im Handle angegebene Fenster wird in den Vordergrund geholt *)
FUNCTION ActivateWindow(Handle : pWindow) : BOOLEAN;

(* Das aktive Fenster wird in seiner Gr��e ver�ndert *)
FUNCTION SizeWindow(DeltaX, DeltaY : INTEGER) : BOOLEAN;

(* Das aktive Fenster wird an eine bestimmte Position verschoben *)
FUNCTION MoveWindow(X, Y : BYTE) : BOOLEAN;

(* Es wird der Titel des aktiven Fensters gezeichnet *)
PROCEDURE DrawTitle(TitleText : STRING; Column : BYTE; DetailPen,
						  BlockPen : Colors);

(* Zeichnet f�r das aktive Fenster, falls m�glich, einen Schatten *)
PROCEDURE AddShadow;

(* Entfernt vom aktiven Fenster, falls m�glich, den Schatten *)
PROCEDURE DelShadow;

(* Der Inhalt des aktiven Fensters wird nach oben gescrollt *)
PROCEDURE ScrollUp(Delta : BYTE);

(* Der Inhalt des aktiven Fensters wird nach unten gescrollt *)
PROCEDURE ScrollDown(Delta : BYTE);

(* Der Inhalt des aktiven Fensters wird nach links gescrollt *)
PROCEDURE ScrollLeft(Delta : BYTE);

(* Der Inhalt des aktiven Fensters wird nach rechts gescrollt *)
PROCEDURE ScrollRight(Delta : BYTE);

(* Virtuelle Cursorposition setzen *)
PROCEDURE SetVirtualXY(X, Y : BYTE);

(* Berechnet die virtuelle Position X des Cursors *)
FUNCTION WhereVirtualX : BYTE;

(* Berechnet die virtuelle Position Y des Cursors *)
FUNCTION WhereVirtualY : BYTE;

(* Es wird der Inhalt des aktiven Fensters gel�scht *)
PROCEDURE ClearWindow;

(* Es wird ein Textstring im aktiven Fenster ausgegeben *)
PROCEDURE WriteString(TextString : STRING; DetailPen, BlockPen : Colors);

(* Es wird ein Textstring und anschlie�end ein Carriage Return ausgegeben *)
PROCEDURE WriteLnString(TextString : STRING; DetailPen, BlockPen : Colors);

(* Es wird ein Textstring im aktiven Fenster eingelesen *)
PROCEDURE ReadString(VAR TextString : STRING; DetailPen, BlockPen : Colors);

(* Es wird ein Textstring eingelesen und anschlie�end ein Return ausgegeben *)
PROCEDURE ReadLnString(VAR TextString : STRING; DetailPen, BlockPen : Colors);

IMPLEMENTATION

TYPE Address = RECORD                              (* Zugriff auf Zeiger      *)
						Offset,
						Segment : WORD;
					END;

VAR ActiveWindow   : pWindow;                      (* Aktives Fenster         *)
	 WindowStack    : pStack;                       (* Stack der Fenster       *)
	 ComplexWindows : BOOLEAN;                      (* Status f�r Aktivierung  *)

(* F�r das aktive Fenster wird ein Schatten gezeichnet *)
PROCEDURE SetShadow;
VAR Y,
	 k,
	 i,
	 Attribute : BYTE;
	 sBuffer   : POINTER;
	 Target    : pVideo;
BEGIN
	WITH ActiveWindow^ DO
	BEGIN
		sBuffer := ShadowBuffer;
		Y := TopEdge;                                (* Wird sp�ter ver�ndert   *)

		VideoSave(LeftEdge + 2, TopEdge + Height, Width, 1, sBuffer);
		Inc(Address(sBuffer).Offset, Width SHL 1);
		VideoSave(LeftEdge + Width, TopEdge + 1, 2, Height - 1, sBuffer);

		IF ColorGraphic THEN                         (* Color Modus             *)
		BEGIN
			Target := VideoPointer(TopEdge + Height, LeftEdge + 2);

			FOR k := 1 TO Width DO
			BEGIN
				Attribute := Target^.Attribute;        (* Attribut auslesen       *)

				IF Attribute AND $08 <> 0 THEN         (* Heller Vordergrund      *)
					Attribute := Attribute AND $07      (* Bits 3 bis 7 l�schen    *)
				ELSE Attribute := Ord(LightGrey);   	(* Hellgrau/Schwarz			*)

				Target^.Attribute := Attribute;        (* Attribute eintragen     *)
				Inc(Address(Target).Offset, 2);        (* N�chstes Zeichen        *)
			END;

			FOR k := 1 TO Height - 1 DO
			BEGIN
				Target := VideoPointer(Y + 1, LeftEdge + Width);

				FOR i := 1 TO 2 DO
				BEGIN
					Attribute := Target^.Attribute;     (* Attribut auslesen       *)

					IF Attribute AND $08 <> 0 THEN      (* Heller Vordergrund      *)
						Attribute := Attribute AND $07   (* Bits 3 bis 7 l�schen    *)
					ELSE Attribute := Ord(LightGrey);   (* Hellgrau/Schwarz			*)

					Target^.Attribute := Attribute;     (* Attribute eintragen     *)
					Inc(Address(Target).Offset, 2);     (* N�chstes Zeichen        *)
				END;

				Inc(Y);                                (* N�chste Zeile           *)
			END;
		END
		ELSE                                         (* Monochrom Modus         *)
		BEGIN
			PutCharacters(LeftEdge + 2, TopEdge + Height, Width, 1, Chr(177));
			PutCharacters(LeftEdge + Width, TopEdge + 1, 2, Height - 1, Chr(177));
		END;
	END;
END; (* SetShadow *)

(* Vom aktiven Fenster wird der Schatten entfernt *)
PROCEDURE RemoveShadow;
VAR sBuffer : POINTER;
BEGIN
	WITH ActiveWindow^ DO
	BEGIN
		sBuffer := ShadowBuffer;

		VideoLoad(LeftEdge + 2, TopEdge + Height, Width, 1, sBuffer);
		Inc(Address(sBuffer).Offset, Width SHL 1);
		VideoLoad(LeftEdge + Width, TopEdge + 1, 2, Height - 1, sBuffer);
	END;
END; (* RemoveShadow *)

(* Zeichnet f�r das aktive Fenster, falls m�glich, einen Schatten *)
PROCEDURE AddShadow;
BEGIN
	IF NOT StackIsEmpty(WindowStack) THEN
	BEGIN
		WITH ActiveWindow^ DO
		BEGIN
			IF NOT (Shadow IN Flags) THEN             (* Kein Schatten vorhanden *)
			BEGIN
				IF (LeftEdge + Width < NrOfColumns - 1) AND
					(TopEdge + Height < NrOfLines) THEN
				BEGIN
					SetShadow;                          (* Fenster hat Schatten    *)
					Flags := Flags + [Shadow];
				END;
			END;
		END;
	END;
END; (* AddShadow *)

(* Entfernt vom aktiven Fenster, falls m�glich, den Schatten *)
PROCEDURE DelShadow;
BEGIN
	IF NOT StackIsEmpty(WindowStack) THEN
	BEGIN
		WITH ActiveWindow^ DO
		BEGIN
			IF Shadow IN Flags THEN                   (* Fenster hat Schatten    *)
			BEGIN
				RemoveShadow;                          (* Kein Schatten vorhanden *)
				Flags := Flags - [Shadow];
			END;
		END;
	END;
END; (* DelShadow *)

(* Virtuelle Cursorposition setzen *)
PROCEDURE SetVirtualXY(X, Y : BYTE);
BEGIN
	IF NOT StackIsEmpty(WindowStack) THEN
	BEGIN
		WITH ActiveWindow^ DO
		BEGIN
			IF (X > 0) AND (Y > 0) AND (X < Width - 1) AND (Y < Height - 1) THEN
			BEGIN
				VirtualX := X;                         (* Virtuell X und Y setzen *)
				VirtualY := Y;
			END;

			IF Cursor IN Flags THEN
				SetXY(LeftEdge + VirtualX, TopEdge + VirtualY);
		END;
	END;
END; (* SetVirtualXY *)

(* Berechnet die virtuelle Position X des Cursors *)
FUNCTION WhereVirtualX : BYTE;
BEGIN
	IF NOT StackIsEmpty(WindowStack) THEN
		WhereVirtualX := ActiveWindow^.VirtualX;
END; (* WhereVirtualX *)

(* Berechnet die virtuelle Position Y des Cursors *)
FUNCTION WhereVirtualY : BYTE;
BEGIN
	IF NOT StackIsEmpty(WindowStack) THEN
		WhereVirtualY := ActiveWindow^.VirtualY;
END; (* WhereVirtualY *)

(* Es wird der Titel des aktiven Fensters gezeichnet *)
PROCEDURE DrawTitle(TitleText : STRING; Column : BYTE; DetailPen,
						  BlockPen : Colors);
VAR k : BYTE;
BEGIN
	IF NOT StackIsEmpty(WindowStack) AND (Column > 0) THEN
	BEGIN
		WITH ActiveWindow^ DO
		BEGIN
			IF Single IN Flags THEN
				DrawLine(LeftEdge + 1, TopEdge, Width - 2, Horizontal, Chr(196),
							DetailPen, BlockPen)
			ELSE IF Double IN Flags THEN
				DrawLine(LeftEdge + 1, TopEdge, Width - 2, Horizontal, Chr(205),
							DetailPen, BlockPen)
			ELSE IF Dithering IN Flags THEN
				DrawLine(LeftEdge + 1, TopEdge, Width - 2, Horizontal, Chr(177),
							DetailPen, BlockPen)
			ELSE IF Full IN Flags THEN
				DrawLine(LeftEdge + 1, TopEdge, Width - 2, Horizontal, Chr(219),
							DetailPen, BlockPen);

			k := 1;												(* Buchstabenz�hler			*)

			WHILE (k <= Length(TitleText)) AND (Column < Width - 1) DO
			BEGIN
				PutChar(LeftEdge + Column, TopEdge, TitleText[k],
						  DetailPen, BlockPen);

				Inc(k);
				Inc(Column);
			END;

			Flags := Flags + [Title]; 						(* Fenster hat Titel			*)
		END;
	END;
END; (* DrawTitle *)

(* Neues Fenster �ffnen *)
FUNCTION OpenWindow(NewWindow : Window) : pWindow;
VAR TitleFront,												(* Zeichen vor dem Titel	*)
	 TitleBack : CHAR;										(* Zeichen nach dem Titel	*)
BEGIN
	WITH NewWindow DO
	BEGIN
		IF (Width < 3) OR (Height < 3) OR            (* Bereichspr�fungen       *)
			(LeftEdge + Width > NrOfColumns) OR
			(TopEdge + Height > NrOfLines) OR
			(MaxAvail < Width * Height * 4 + SizeOf(Window) +
							(Width + (Height - 1) * 2) * 2) THEN OpenWindow := NIL
		ELSE
		BEGIN
			GetMem(Buffer, Width * Height * 2);       (* Speicher f�r Puffer     *)
			GetMem(ShadowBuffer, (Width + (Height - 1) * 2) * 2);

			IF NOT (Simple IN Flags) THEN             (* Aktivierung m�glich     *)
				GetMem(ForeGround, Width * Height * 2)
			ELSE ComplexWindows := FALSE;             (* Keine Aktivierung mehr  *)

			IF ComplexWindows AND NOT StackIsEmpty(WindowStack) THEN
			BEGIN                                     (* Komplexe Fenster offen  *)
				WITH ActiveWindow^ DO                  (* Noch aktives Fenster    *)
					VideoSave(LeftEdge, TopEdge, Width, Height, ForeGround);
			END;                                      (* Vordergrund gespeichert *)

			VideoSave(LeftEdge, TopEdge, Width, Height, Buffer);
			VideoFill(LeftEdge, TopEdge, Width, Height, ' ', DetailPen, BlockPen);

			IF Single IN Flags THEN
			BEGIN
				DrawBorder(LeftEdge, TopEdge, Width, Height, bSingle, DetailPen,
							  BlockPen);

				TitleFront := Chr(180);
				TitleBack := Chr(195);
			END
			ELSE IF Double IN Flags THEN
			BEGIN
				DrawBorder(LeftEdge, TopEdge, Width, Height, bDouble, DetailPen,
							  BlockPen);

				TitleFront := Chr(181);
				TitleBack := Chr(198);
			END
			ELSE IF Dithering IN Flags THEN
			BEGIN
				DrawBorder(LeftEdge, TopEdge, Width, Height, bDithering, DetailPen,
							  BlockPen);

				TitleFront := ' ';
				TitleBack := ' ';
			END
			ELSE IF Full IN Flags THEN
			BEGIN
				DrawBorder(LeftEdge, TopEdge, Width, Height, bFull, DetailPen,
							  BlockPen);

				TitleFront := ' ';
				TitleBack := ' ';
			END;

			VirtualX := 1;                            (* Innerhalb des Fensters  *)
			VirtualY := 1;                            (* Virtueller Cursor       *)

			CursorX := GetX;                          (* Alte Cursorposition     *)
			CursorY := GetY;

			New(ActiveWindow);                        (* Neues aktives Fenster   *)
			ActiveWindow^ := NewWindow;
			Push(WindowStack, ActiveWindow);          (* Neues Fenster auf Stack *)

			IF Title IN Flags THEN							(* Fenstertitel zeichnen	*)
				DrawTitle(TitleFront + WinTitle + TitleBack, 2, DetailPen,
							 BlockPen);

			IF Cursor IN Flags THEN                   (* Virtueller Cursor       *)
				SetVirtualXY(VirtualX, VirtualY);

			IF Shadow IN Flags THEN                   (* Fenster hat Schatten    *)
			BEGIN
				IF (LeftEdge + Width < NrOfColumns - 1) AND
					(TopEdge + Height < NrOfLines) THEN SetShadow
				ELSE Flags := Flags - [Shadow];        (* Kein Schatten m�glich   *)
			END;

			OpenWindow := ActiveWindow;               (* Alles in Ordnung        *)
		END;
	END;
END; (* OpenWindow *)

(* Aktives Fenster entfernen *)
FUNCTION CloseWindow : BOOLEAN;
BEGIN
	IF StackIsEmpty(WindowStack) THEN CloseWindow := FALSE
	ELSE
	BEGIN
		WITH ActiveWindow^ DO
		BEGIN
			IF Shadow IN Flags THEN RemoveShadow;     (* Fenster hat Schatten    *)
			VideoLoad(LeftEdge, TopEdge, Width, Height, Buffer);

			FreeMem(Buffer, Width * Height * 2);      (* Speicher freigeben      *)
			FreeMem(ShadowBuffer, (Width + (Height - 1) * 2) * 2);

			IF NOT (Simple IN Flags) THEN             (* Komplexes Fenster       *)
				FreeMem(ForeGround, Width * Height * 2);

			SetXY(CursorX, CursorY);                  (* Cursor setzen           *)
		END;

		Pop(WindowStack, POINTER(ActiveWindow));     (* Aktives Fenster weg     *)
		Dispose(ActiveWindow);

		IF NOT StackIsEmpty(WindowStack) THEN        (* Noch ein Fenster offen  *)
		BEGIN
			Pop(WindowStack, POINTER(ActiveWindow));  (* Neues aktives Fenster   *)
			Push(WindowStack, ActiveWindow);          (* Wieder zur�ck auf Stack *)

			WITH ActiveWindow^ DO                     (* Virtueller Cursor       *)
				IF Cursor IN Flags THEN SetVirtualXY(VirtualX, VirtualY);
		END;

		CloseWindow := TRUE;                         (* Alles in Ordnung        *)
	END;
END; (* CloseWindow *)

(* Das im Handle angegebene Fenster wird in den Vordergrund geholt *)
FUNCTION ActivateWindow(Handle : pWindow) : BOOLEAN;
VAR OneElement,
	 HandleElement : pStack;                        (* Zugriff auf Handle      *)
	 VideoBuffer   : ^BYTE;                         (* Kopie vom Videospeicher *)
	 VideoSeg,                                      (* VideoSegment merken     *)
	 VideoOfs      : WORD;                          (* VideoOffset merken      *)
	 SizeOfVideo   : INTEGER;                       (* Gr��e vom Videospeicher *)
BEGIN
	IF (MaxAvail < NrOfLines * NrOfColumns * 2) OR  (* Nicht genug Speicher    *)
		(Handle = NIL) OR                            (* Unzul�ssigs Handle      *)
		(NOT ComplexWindows) OR                      (* Aktivierung unm�glich   *)
		(StackIsEmpty(WindowStack)) THEN             (* Keine Fenster ge�ffnet  *)
		ActivateWindow := FALSE
	ELSE IF Handle = ActiveWindow THEN              (* Handle ist schon aktiv  *)
		ActivateWindow := TRUE
	ELSE                                            (* Handle im Hintergrund   *)
	BEGIN
		OneElement := WindowStack;                   (* Spitze des Stapels      *)

		WHILE (OneElement^.Next <> NIL) AND          (* Handle im Stapel suchen *)
				(OneElement^.Content <> Handle) DO
					OneElement := OneElement^.Next;

		IF OneElement^.Content <> Handle THEN        (* Fataler Stapelfehler    *)
			ActivateWindow := FALSE
		ELSE                                         (* Handle gefunden         *)
		BEGIN
			VideoSeg := VideoSegment;                 (* VideoSegment merken     *)
			VideoOfs := VideoOffset;                  (* VideoOffset merken      *)
			HandleElement := OneElement;              (* Handle im Stapel merken *)
			SizeOfVideo := NrOfColumns * NrOfLines * 2;

			WITH ActiveWindow^ DO                     (* Vordergrund gespeichert *)
				VideoSave(LeftEdge, TopEdge, Width, Height, ForeGround);

			GetMem(VideoBuffer, SizeOfVideo);         (* Bildschirm kopieren     *)
			Move(Ptr(VideoSegment, VideoOffset)^, VideoBuffer^, SizeOfVideo);

			VideoSegment := Address(VideoBuffer).Segment;
			VideoOffset := Address(VideoBuffer).Offset;
			OneElement := WindowStack;                (* Oberstes Fenster        *)

			REPEAT                                    (* Fenster �ber Handle     *)
				WITH pWindow(OneElement^.Content)^ DO
				BEGIN
					VideoLoad(LeftEdge, TopEdge, Width, Height, Buffer);

					IF Shadow IN Flags THEN             (* Fenster hat Schatten    *)
					BEGIN
						ActiveWindow := OneElement^.Content;
						RemoveShadow;                    (* Schatten entfernen      *)
					END;
				END;

				OneElement := OneElement^.Next;        (* N�chstes Fenster        *)
			UNTIL OneElement = HandleElement^.Next;   (* Fenster bis zum Handle  *)

			WITH HandleElement^ DO                    (* Handle an Stapelspitze  *)
			BEGIN
				OneElement := Prev;                    (* Vorg�nger vom Handle    *)
				OneElement^.Next := Next;              (* Nachfolger vom Handle   *)

				IF Next <> NIL THEN                    (* Nachfolger vorhanden    *)
					Next^.Prev := OneElement;           (* Zeigt auf Vorg�nger     *)

				Next := WindowStack;                   (* Handle an Stapelspitze  *)
				Prev := NIL;
				WindowStack^.Prev := HandleElement;
				WindowStack := HandleElement;          (* Neue Stapelspitze       *)
			END;

			WHILE OneElement <> NIL DO                (* Fenster wieder in neuer *)
			BEGIN                                     (* Reihenfolge �ffnen      *)
				WITH pWindow(OneElement^.Content)^ DO
				BEGIN
					VideoSave(LeftEdge, TopEdge, Width, Height, Buffer);
					VideoLoad(LeftEdge, TopEdge, Width, Height, ForeGround);

					IF Shadow IN Flags THEN             (* Fenster hat Schatten    *)
					BEGIN
						ActiveWindow := OneElement^.Content;
						SetShadow;                       (* Schatten zeichnen       *)
					END;
				END;

				OneElement := OneElement^.Prev;        (* Vorheriges Fenster      *)
			END;

			ActiveWindow := WindowStack^.Content;     (* Neues aktives Fenster   *)

			WITH ActiveWindow^ DO                     (* Virtueller Cursor       *)
				IF Cursor IN Flags THEN SetVirtualXY(VirtualX, VirtualY);

			VideoSegment := VideoSeg;                 (* VideoSegment herstellen *)
			VideoOffset := VideoOfs;                  (* VideoOffset herstellen  *)
			Move(VideoBuffer^, Ptr(VideoSegment, VideoOffset)^, SizeOfVideo);
			FreeMem(VideoBuffer, SizeOfVideo);        (* Speicher freigeben      *)
			ActivateWindow := TRUE;
		END;
	END;
END; (* ActivateWindow *)

(* Das aktive Fenster wird in seiner Gr��e ver�ndert *)
FUNCTION SizeWindow(DeltaX, DeltaY : INTEGER) : BOOLEAN;
VAR TempBuffer,												(* Tempor�rer Puffer			*)
	 VideoBuffer : ^BYTE;       	                  (* Kopie vom Videospeicher *)
	 SaveX,														(* Gespeicherte Spalten		*)
	 SaveY,             										(* Gespeicherter Zeilen		*)
	 MaxSizeX,													(* Maximale Spaltenanzahl	*)
	 MaxSizeY    : BYTE; 									(* Maximale Zeilenanzahl	*)
	 VideoSeg,                                      (* VideoSegment merken     *)
	 VideoOfs    : WORD;                            (* VideoOffset merken      *)
	 SizeOfVideo : INTEGER;         	               (* Gr��e vom Videospeicher *)
	 TempWindow,												(* Tempor�re Fensterdaten	*)
	 OneWindow   : pWindow;    							(* Aktuelles Fenster			*)
	 NewWindow	 : Window;									(* Neu ge�ffnetes Fenster	*)
	 Status      : BOOLEAN;		      					(* Fensterstatus				*)
BEGIN
	IF (MaxAvail < NrOfLines * NrOfColumns * 4) OR 	(* Nicht genug Speicher    *)
		(StackIsEmpty(WindowStack)) THEN             (* Keine Fenster ge�ffnet  *)
			SizeWindow := FALSE
	ELSE IF (DeltaX = 0) AND (DeltaY = 0) THEN		(* Keine Gr��en�nderung		*)
		SizeWindow := TRUE
	ELSE															(* Fenstergr��e �ndern		*)
	BEGIN
		IF Shadow IN ActiveWindow^.Flags THEN			(* Fenster hat Schatten		*)
		BEGIN
			MaxSizeX := NrOfColumns - 1;
			MaxSizeY := NrOfLines - 1;
		END
		ELSE														(* Fenster hat Schatten		*)
		BEGIN
			MaxSizeX := NrOfColumns;
			MaxSizeY := NrOfLines;
		END;

		IF (ActiveWindow^.Width + DeltaX < 3) OR		(* Bereichs�berpr�fung		*)
			(ActiveWindow^.Height + DeltaY < 3) OR
			(ActiveWindow^.LeftEdge + ActiveWindow^.Width +
			 DeltaX > MaxSizeX) OR
			(ActiveWindow^.TopEdge + ActiveWindow^.Height +
			 DeltaY > MaxSizeY) THEN
			SizeWindow := FALSE
		ELSE
		BEGIN
			VideoSeg := VideoSegment;              	(* VideoSegment merken     *)
			VideoOfs := VideoOffset;     	         	(* VideoOffset merken      *)
			SizeOfVideo := NrOfColumns * NrOfLines * 2;

			WITH ActiveWindow^ DO
			BEGIN
				IF DeltaX < 0 THEN SaveX := Width - 2 + DeltaX
				ELSE SaveX := Width - 2;

				IF DeltaY < 0 THEN SaveY := Height - 2 + DeltaY
				ELSE SaveY := Height - 2;

				GetMem(VideoBuffer, SizeOfVideo);     	(* Bildschirm kopieren     *)
				GetMem(TempBuffer, SaveX * SaveY * 2);

				Move(Ptr(VideoSegment, VideoOffset)^, VideoBuffer^, SizeOfVideo);
				VideoSave(LeftEdge + 1, TopEdge + 1, SaveX, SaveY, TempBuffer);
				VideoSegment := Address(VideoBuffer).Segment;
				VideoOffset := Address(VideoBuffer).Offset;
			END;

			Pop(WindowStack, POINTER(OneWindow));		(* Fenster vom Stack weg	*)
			New(TempWindow);									(* Tempor�re Fensterdaten	*)
			TempWindow^ := OneWindow^;						(* Duplikat anfertigen		*)
			ActiveWindow := TempWindow;					(* Neues aktives Fenster	*)
			Push(WindowStack, TempWindow);				(* Neues Fenster auf Stack	*)
			Status := CloseWindow;							(* Aktives Fenster ist zu	*)

			NewWindow := OneWindow^;						(* Neues Fenster				*)
			Inc(NewWindow.Width, DeltaX); 				(* Neue Spaltenanzahl	 	*)
			Inc(NewWindow.Height, DeltaY);            (* Neue Zeilenanzahl			*)
			TempWindow := OpenWindow(NewWindow);		(* Neues Fenster �ffnen		*)

			OneWindow^ := TempWindow^;						(* Benutzer Handle  			*)
			WindowStack^.Content := OneWindow;			(* Handle = neues Fenster  *)
			ActiveWindow := OneWindow;						(* Neues aktives Fenster	*)
			Dispose(TempWindow);								(* Tempor�res Fenster weg	*)

			WITH ActiveWindow^ DO
				VideoLoad(LeftEdge + 1, TopEdge + 1, SaveX, SaveY, TempBuffer);

			VideoSegment := VideoSeg;                 (* VideoSegment herstellen *)
			VideoOffset := VideoOfs;                  (* VideoOffset herstellen  *)
			Move(VideoBuffer^, Ptr(VideoSegment, VideoOffset)^, SizeOfVideo);

			FreeMem(VideoBuffer, SizeOfVideo);        (* Speicher freigeben      *)
			FreeMem(TempBuffer, SaveX * SaveY * 2);

			SizeWindow := TRUE;								(* Alles in Ordnung			*)
		END;
	END;
END; (* SizeWindow *)

(* Das aktive Fenster wird an eine bestimmte Position verschoben *)
FUNCTION MoveWindow(X, Y : BYTE) : BOOLEAN;
VAR TempBuffer,	 											(* Tempor�rer Puffer			*)
	 VideoBuffer : ^BYTE;       	                  (* Kopie vom Videospeicher *)
	 VideoSeg,                                      (* VideoSegment merken     *)
	 VideoOfs    : WORD;                            (* VideoOffset merken      *)
	 SizeOfVideo : INTEGER;         	               (* Gr��e vom Videospeicher *)
BEGIN
	IF (MaxAvail < NrOfLines * NrOfColumns * 4) OR 	(* Nicht genug Speicher    *)
		(StackIsEmpty(WindowStack)) THEN             (* Keine Fenster ge�ffnet  *)
			MoveWindow := FALSE
	ELSE 															(* Fenster verschieben		*)
	BEGIN
		WITH ActiveWindow^ DO
		BEGIN
			VideoSeg := VideoSegment;    	         	(* VideoSegment merken     *)
			VideoOfs := VideoOffset;     	         	(* VideoOffset merken      *)
			SizeOfVideo := NrOfColumns * NrOfLines * 2;

			GetMem(VideoBuffer, SizeOfVideo);	     	(* Bildschirm kopieren     *)
			GetMem(TempBuffer, Width * Height * 2);

			Move(Ptr(VideoSegment, VideoOffset)^, VideoBuffer^, SizeOfVideo);
			VideoSegment := Address(VideoBuffer).Segment;
			VideoOffset := Address(VideoBuffer).Offset;

			IF Shadow IN Flags THEN                   (* Fenster hat Schatten    *)
			BEGIN
				IF (X + Width < NrOfColumns - 1) AND   (* Bereichspr�fungen       *)
					(Y + Height < NrOfLines) THEN
				BEGIN
					IF (GetX >= LeftEdge) AND (GetX < LeftEdge + Width) AND
						(GetY >= TopEdge) AND (GetY < TopEdge + Height) THEN
							SetXY(GetX - LeftEdge + X, GetY - TopEdge + Y);

					RemoveShadow;
					VideoSave(LeftEdge, TopEdge, Width, Height, TempBuffer);
					VideoLoad(LeftEdge, TopEdge, Width, Height, Buffer);
					VideoSave(X, Y, Width, Height, Buffer);
					VideoLoad(X, Y, Width, Height, TempBuffer);

					LeftEdge := X;                      (* Neue Werte eintragen    *)
					TopEdge := Y;
					SetShadow;
				END;
			END
			ELSE                                      (* Kein Schatten           *)
			BEGIN
				IF (X + Width <= NrOfColumns) AND      (* Bereichspr�fungen       *)
					(Y + Height <= NrOfLines) THEN
				BEGIN
					IF (GetX >= LeftEdge) AND (GetX < LeftEdge + Width) AND
						(GetY >= TopEdge) AND (GetY < TopEdge + Height) THEN
							SetXY(GetX - LeftEdge + X, GetY - TopEdge + Y);

					VideoSave(LeftEdge, TopEdge, Width, Height, TempBuffer);
					VideoLoad(LeftEdge, TopEdge, Width, Height, Buffer);
					VideoSave(X, Y, Width, Height, Buffer);
					VideoLoad(X, Y, Width, Height, TempBuffer);

					LeftEdge := X;                      (* Neue Werte eintragen    *)
					TopEdge := Y;
				END;
			END;

			VideoSegment := VideoSeg;                 (* VideoSegment herstellen *)
			VideoOffset := VideoOfs;                  (* VideoOffset herstellen  *)
			Move(VideoBuffer^, Ptr(VideoSegment, VideoOffset)^, SizeOfVideo);

			FreeMem(VideoBuffer, SizeOfVideo);	  		(* Speicher freigeben		*)
			FreeMem(TempBuffer, Width * Height * 2);

			MoveWindow := TRUE;								(* Alles in Ordnung			*)
		END;
	END;
END; (* MoveWindow *)

(* Der Inhalt des aktiven Fensters wird nach oben gescrollt *)
PROCEDURE ScrollUp(Delta : BYTE);
BEGIN
	IF NOT StackIsEmpty(WindowStack) THEN
	BEGIN
		WITH ActiveWindow^ DO
		BEGIN
			VideoScroll(LeftEdge + 1, TopEdge + 1, Width - 2, Height - 2, Delta,
							Up, DetailPen, BlockPen);
		END;
	END;
END; (* ScrollUp *)

(* Der Inhalt des aktiven Fensters wird nach unten gescrollt *)
PROCEDURE ScrollDown(Delta : BYTE);
BEGIN
	IF NOT StackIsEmpty(WindowStack) THEN
	BEGIN
		WITH ActiveWindow^ DO
		BEGIN
			VideoScroll(LeftEdge + 1, TopEdge + 1, Width - 2, Height - 2, Delta,
							Down, DetailPen, BlockPen);
		END;
	END;
END; (* ScrollDown *)

(* Der Inhalt des aktiven Fensters wird nach links gescrollt *)
PROCEDURE ScrollLeft(Delta : BYTE);
BEGIN
	IF NOT StackIsEmpty(WindowStack) THEN
	BEGIN
		WITH ActiveWindow^ DO
		BEGIN
			VideoScroll(LeftEdge + 1, TopEdge + 1, Width - 2, Height - 2, Delta,
							Left, DetailPen, BlockPen);
		END;
	END;
END; (* ScrollLeft *)

(* Der Inhalt des aktiven Fensters wird nach rechts gescrollt *)
PROCEDURE ScrollRight(Delta : BYTE);
BEGIN
	IF NOT StackIsEmpty(WindowStack) THEN
	BEGIN
		WITH ActiveWindow^ DO
		BEGIN
			VideoScroll(LeftEdge + 1, TopEdge + 1, Width - 2, Height - 2, Delta,
							Right, DetailPen, BlockPen);
		END;
	END;
END; (* ScrollRight *)

(* Es wird der Inhalt des aktiven Fensters gel�scht *)
PROCEDURE ClearWindow;
BEGIN
	IF NOT StackIsEmpty(WindowStack) THEN
	BEGIN
		WITH ActiveWindow^ DO
		BEGIN
			VideoFill(LeftEdge + 1, TopEdge + 1, Width - 2, Height - 2, ' ',
						 DetailPen, BlockPen);

			SetVirtualXY(1, 1);                       (* Cursor Home             *)

			IF Cursor IN Flags THEN
				SetXY(LeftEdge + VirtualX, TopEdge + VirtualY);
		END;
	END;
END; (* ClearWindow *)

(* Es wird ein Textstring im aktiven Fenster ausgegeben *)
PROCEDURE WriteString(TextString : STRING; DetailPen, BlockPen : Colors);
VAR Target    : pVideo;
	 k,
	 Attribute : BYTE;
BEGIN
	IF NOT StackIsEmpty(WindowStack) THEN
	BEGIN
		Attribute := (Ord(BlockPen) SHL 4) + Ord(DetailPen);

		WITH ActiveWindow^ DO
		BEGIN
			FOR k := 1 TO Ord(TextString[0]) DO
			BEGIN
				Target := VideoPointer(TopEdge + VirtualY, LeftEdge + VirtualX);

				Target^.Character := TextString[k];    (* Buchstabe ausgeben      *)
				Target^.Attribute := Attribute;
				Inc(VirtualX);                         (* Virtuell 1 nach rechts  *)

				IF VirtualX > Width - 2 THEN           (* Rechter Fensterrand     *)
				BEGIN
					VirtualX := 1;                      (* Zeilenanfang            *)
					Inc(VirtualY);                      (* Neue Zeile              *)
				END;

				IF VirtualY > Height - 2 THEN          (* Unterer Fensterrand     *)
				BEGIN
					VideoScroll(LeftEdge + 1, TopEdge + 1, Width - 2, Height - 2,
									1, Up, DetailPen, BlockPen);

					Dec(VirtualY);                      (* Unterste Fensterzeile   *)
				END;
			END;

			IF Cursor IN Flags THEN
				SetXY(LeftEdge + VirtualX, TopEdge + VirtualY);
		END;
	END;
END; (* WriteString *)

(* Es wird ein Textstring und anschlie�end ein Carriage Return ausgegeben *)
PROCEDURE WriteLnString(TextString : STRING; DetailPen, BlockPen : Colors);
BEGIN
	IF NOT StackIsEmpty(WindowStack) THEN
	BEGIN
		WriteString(TextString, DetailPen, BlockPen);

		WITH ActiveWindow^ DO
		BEGIN
			VirtualX := 1;                            (* Zeilenanfang            *)
			Inc(VirtualY);                            (* Neue Zeile              *)

			IF VirtualY > Height - 2 THEN             (* Unterer Fensterrand     *)
			BEGIN
				VideoScroll(LeftEdge + 1, TopEdge + 1, Width - 2, Height - 2,
								1, Up, DetailPen, BlockPen);

				Dec(VirtualY);                         (* Unterste Fensterzeile   *)
			END;

			IF Cursor IN Flags THEN
				SetXY(LeftEdge + VirtualX, TopEdge + VirtualY);
		END;
	END;
END; (* WriteLnString *)

(* Es wird ein Textstring im aktiven Fenster eingelesen *)
PROCEDURE ReadString(VAR TextString : STRING; DetailPen, BlockPen : Colors);
CONST BS       = 8;                                (* Back Space Taste        *)
		CR       = 13;                               (* Carriage Return Taste   *)
		ScanCode = 0;                                (* Taste liefert ScanCode  *)
VAR NrOfChars : BYTE;
	 Character : CHAR;
BEGIN
	IF NOT StackIsEmpty(WindowStack) THEN
	BEGIN
		NrOfChars := 0;                              (* Noch nichts eingegeben  *)

		REPEAT
			REPEAT UNTIL KeyPressed;                  (* Warten auf Tastendruck  *)
			Character := ReadKey;                     (* Zeichen einlesen        *)

			CASE Ord(Character) OF
				ScanCode : Character := ReadKey;       (* Keine Sondertasten      *)

				BS :                                   (* Back Space Taste        *)
				BEGIN
					IF NrOfChars > 0 THEN               (* Buchstaben vorhanden    *)
					BEGIN
						WITH ActiveWindow^ DO
						BEGIN
							IF VirtualX = 1 THEN
							BEGIN
								IF VirtualY > 1 THEN
								BEGIN
									VirtualX := Width - 2;
									Dec(VirtualY);          (* Eine Zeile zur�ck       *)
									Dec(NrOfChars);         (* Ein Buchstabe weniger   *)
								END;
							END
							ELSE
							BEGIN
								Dec(VirtualX);             (* Ein Zeichen nach links  *)
								Dec(NrOfChars);            (* Ein Buchstabe weniger   *)
							END;

							PutChar(LeftEdge + VirtualX, TopEdge + VirtualY, ' ',
									  DetailPen, BlockPen);

							IF Cursor IN Flags THEN
								SetXY(LeftEdge + VirtualX, TopEdge + VirtualY);
						END;
					END;
				END;

				CR : TextString[0] := Chr(NrOfChars);  (* Ende der Texteingabe    *)
			ELSE                                      (* Normaler Buchstabe      *)
				IF NrOfChars < 127 THEN                (* Eingabe noch m�glich    *)
				BEGIN
					Inc(NrOfChars);                     (* Neues Zeichen           *)
					TextString[NrOfChars] := Character;
					WriteString(Character, DetailPen, BlockPen);
				END
				ELSE Write(Chr(7));                    (* Fehler bei Eingabe      *)
			END;
		UNTIL Character = Chr(CR);                   (* Einlesen bis Return     *)
	END;
END; (* ReadString *)

(* Es wird ein Textstring eingelesen und anschlie�end ein Return ausgegeben *)
PROCEDURE ReadLnString(VAR TextString : STRING; DetailPen, BlockPen : Colors);
BEGIN
	IF NOT StackIsEmpty(WindowStack) THEN
	BEGIN
		ReadString(TextString, DetailPen, BlockPen);

		WITH ActiveWindow^ DO
			WriteLnString('', DetailPen, BlockPen);   (* Bewirkt nur Return      *)
	END;
END; (* ReadLnString *)

BEGIN (* Windows *)
	CreateStack(WindowStack);
	ComplexWindows := TRUE;                         (* Aktivierung m�glich     *)
END. (* Windows *)
