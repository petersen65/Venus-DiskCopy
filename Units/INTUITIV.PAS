(*************************************************************)
(* Programmname	 : INTUITIV.PAS V2.1 							 *)
(* Programmautor	 : Michael Rippl									 *)
(* Compiler 		 : Quick Pascal V1.0 							 *)
(* Inhalt			 : Routinen fÅr die Programmierung von SAA *)
(* Bemerkung		 : -													 *)
(* Letzte énderung : 11-Sep-1990 									 *)
(*************************************************************)

UNIT Intuitiv; 												(*$V- Kein String Checking *)

INTERFACE

USES Primitiv, Windows, KeyMouse;						(* Units einbinden			*)

CONST TextLen		 = 80;									(* Maximale TextlÑnge		*)
		MoveGadget	 = 121;									(* Requester verschieben	*)
		CloseGadget  = 122;									(* Schlie·gadget Nummer 	*)
		LowestGadget = 1; 									(* Niedrigste Gadgetnummer *)

TYPE EndRead = (rMouse, rPageUp, rPageDown, rEscape, rTabulator,
					 rShiftTabulator, rReturn, rCursorUp, rCursorDown);

	  EndSet  = SET OF EndRead;							(* Ende fÅr RequesterRead	*)
	  CharSet = SET OF CHAR;								(* Menge aller Zeichen		*)

TYPE TextStr	 = STRING[TextLen];						(* Typ eines Textpuffers	*)
	  pIntuiText = ^IntuiText; 							(* Zeiger auf Text			*)

	  IntuiText  = RECORD									(* Datentyp eines Textes	*)
							LeftEdge,							(* Spaltenposition			*)
							TopEdge	 : BYTE; 				(* Zeilenposition 			*)
							DetailPen,							(* Vordergrundfarbe			*)
							BlockPen  : Colors;				(* Hintergrundfarbe			*)
							Buffer	 : TextStr; 			(* Eigentlicher Text 		*)
							Next		 : pIntuiText; 		(* NÑchster Text				*)
						END;

TYPE GadgetType	= (TextGadget, OnOffGadget, OkGadget, ExitGadget, YesGadget,
							NoGadget, UserGadget);

	  pGadget		= ^Gadget;								(* Zeiger auf Gadget 		*)
	  GadgetAction = PROCEDURE (GadgetPtr : pGadget);

	  Gadget 		= RECORD 								(* Datentyp eines Gadgets	*)
							  LeftEdge, 						(* Spaltenposition			*)
							  TopEdge,							(* Zeilenposition 			*)
							  Width, 							(* Breite des Gadgets		*)
							  Height 	: BYTE;				(* Hîhe des Gadgets			*)
							  DoAction	: BOOLEAN;			(* Prozedur aufrufen 		*)
							  Action 	: GadgetAction;	(* Aufruf einer Prozedur	*)
							  OneText	: pIntuiText;		(* Text des Gadgets			*)
							  ActDetail,						(* Aktive Vordergrundfarbe *)
							  ActBlock	: Colors;			(* Aktive Hintergrundfarbe *)
							  UserWord  : WORD;				(* Nur fÅr den Benutzer		*)
							  ReqEnd 	: BOOLEAN;			(* Ende des Requesters		*)
							  GadgetId	: UserId;			(* Interne Nummerierung 	*)
							  Next		: pGadget;			(* NÑchstes Gadget			*)

							  CASE Typ : GadgetType OF 	(* Typ des Gadgets			*)
								  TextGadget : 				(* Gadget fÅr Texteingabe	*)
									  (Buffer : TextStr; 	(* Puffer fÅr Textaufnahme *)
										Size	 : 1..TextLen; (* Grî·e des Puffers 		*)
										Mask	 : CharSet);	(* Maske fÅr Tasteneingabe *)
								  OnOffGadget :				(* Gadget als Schalter		*)
									  (On : BOOLEAN); 		(* Gadget ist angeschaltet *)
								  OkGadget, ExitGadget, YesGadget, NoGadget :
									  ();
								  UserGadget : 				(* Gadget fÅr Benutzer		*)
									  (ColOfs : BYTE);		(* Offset fÅr Cursorspalte *)
						  END;

TYPE RequesterFlags = (rClose, rMove, rSingle, rDouble, rShadow, rTitle);
	  ReqFlagSet	  = SET OF RequesterFlags;
	  ReqInitProc	  = PROCEDURE ;						(* Initialisierungsroutine *)
	  pRequester	  = ^Requester;						(* Zeiger auf Requester 	*)

	  Requester 	  = RECORD								(* Datentyp des Requesters *)
								 LeftEdge,						(* Spaltenposition			*)
								 TopEdge,						(* Zeilenposition 			*)
								 Width,							(* Breite des Requesters	*)
								 Height		: BYTE;			(* Hîhe des Requesters		*)
								 DetailPen, 					(* Vordergrundfarbe			*)
								 BlockPen	: Colors;		(* Hintergrundfarbe			*)
								 ReqTitle	: TextStr;		(* Titel des Requesters 	*)
								 Flags		: ReqFlagSet;	(* Attribute vom Requester *)
								 DoInit		: BOOLEAN;		(* Init Prozedur aufrufen	*)
								 InitProc	: ReqInitProc; (* Aufruf nach Req offen	*)
								 GadgetList : pGadget;		(* Liste aller Gadgets		*)
								 TextList	: pIntuiText;	(* Liste aller Texte 		*)
							 END;

(* Diese Prozedur legt ein IntuiText-Element an und initialisiert es *)
PROCEDURE InitIntuiText(VAR IntuiItem : pIntuiText; Left, Top : BYTE; Detail,
								Block : Colors; Buf : TextStr; Nxt : pIntuiText);

(* Diese Prozedur legt ein Gadget-Element an und initialisiert es *)
PROCEDURE InitGadget(VAR GadgetItem : pGadget; Left, Top, Cols, Lines : BYTE;
							OneTxt : pIntuiText; Detail, Block : Colors;
							Nxt : pGadget; GadgetTyp : GadgetType);

(* Diese Prozedur legt ein Requester-Element an und initialisiert es *)
PROCEDURE InitRequester(VAR RequesterItem : pRequester; Left, Top, Cols,
								Lines : BYTE; Detail, Block : Colors; Title : TextStr;
								ReqFlags : ReqFlagSet; GadgetLst : pGadget;
								TextLst : pIntuiText);

(* Diese Prozedur gibt eine komplette IntuiText-Liste frei *)
PROCEDURE DelIntuiTextList(VAR IntuiList : pIntuiText);

(* Diese Prozedur gibt eine komplette Gadget-Liste frei *)
PROCEDURE DelGadgetList(VAR GadgetList : pGadget);

(* Diese Prozedur gibt den kompletten Speicher eines Requesters frei *)
PROCEDURE DelRequester(VAR RequesterItem : pRequester);

(* Diese Prozedur zeichnet eine IntuiText-Liste in das aktive Fenster *)
PROCEDURE DrawIntuiText(IntuiList : pIntuiText);

(* Diese Prozedur zeichnet ein Gadget normal oder aktiv in das aktive Fenster *)
PROCEDURE DrawGadget(GadgetPtr : pGadget; Active : BOOLEAN);

(* Diese Prozedur zeichnet eine Gadget-Liste in das aktive Fenster *)
PROCEDURE DrawGadgetList(GadgetList : pGadget);

(* Diese Prozedur nummeriert eine Gadget-Liste durch *)
PROCEDURE SetGadgetId(GadgetList : pGadget; StartNumber : BYTE);

(* Diese Funktion zÑhlt die Anzahl der Gadgets in einer Liste *)
FUNCTION GetNrOfGadgets(GadgetList : pGadget) : BYTE;

(* Diese Prozedur zeichnet die BerÅhrungsfelder der Gadgets *)
PROCEDURE DrawGadgetAreas(GadgetList : pGadget; LeftOffset, TopOffset : BYTE);

(* Diese Prozedur lîscht alle BerÅhrungsfelder der Gadgets *)
PROCEDURE DelGadgetAreas(GadgetList : pGadget);

(* Diese Funktion sucht fÅr eine Gadget-Id das passende Gadget *)
FUNCTION SearchGadget(GadgetList : pGadget; GadgetNr : UserId) : pGadget;

(* Diese Prozedur sucht ein Gadget eines bestimmten Typs *)
FUNCTION SearchGadgetTyp(GadgetList : pGadget; Typ : GadgetType) : pGadget;

(* Diese Funktion ermittelt das Gadget, mit dem ein Requester beendet wurde *)
FUNCTION GetEndGadget(GadgetList : pGadget) : pGadget;

(* Es wird eine Zeichenkette fÅr ein Textgadget eingelesen *)
PROCEDURE RequesterRead(LeftEdge, TopEdge, Width : BYTE; KeyMask : CharSet;
								VAR TextString : STRING; DetailPen, BlockPen : Colors;
								VAR EndEvents : EndSet; FillWidth, TextOut : BOOLEAN);

(* Diese Funktion îffnet einen Requester und nimmt dessen Abfragen vor *)
FUNCTION OpenRequester(ReqItem : pRequester) : BOOLEAN;

(* Diese Funktion schlie·t einen Requester und gibt seinen Speicher frei *)
FUNCTION CloseRequester(VAR ReqItem : pRequester) : BOOLEAN;

IMPLEMENTATION

(* Diese Prozedur legt ein IntuiText-Element an und initialisiert es *)
PROCEDURE InitIntuiText(VAR IntuiItem : pIntuiText; Left, Top : BYTE; Detail,
								Block : Colors; Buf : TextStr; Nxt : pIntuiText);
BEGIN
	New(IntuiItem);											(* Speicher reservieren 	*)

	WITH IntuiItem^ DO										(* Alle Werte eintragen 	*)
	BEGIN
		LeftEdge := Left;
		TopEdge := Top;
		DetailPen := Detail;
		BlockPen := Block;
		Buffer := Buf;
		Next := Nxt;
	END;
END; (* InitIntuiText *)

(* Diese Prozedur legt ein Gadget-Element an und initialisiert es *)
PROCEDURE InitGadget(VAR GadgetItem : pGadget; Left, Top, Cols, Lines : BYTE;
							OneTxt : pIntuiText; Detail, Block : Colors;
							Nxt : pGadget; GadgetTyp : GadgetType);
BEGIN
	New(GadgetItem);											(* Speicher reservieren 	*)

	WITH GadgetItem^ DO										(* Alle Werte eintragen 	*)
	BEGIN
		LeftEdge := Left;
		TopEdge := Top;
		Width := Cols;
		Height := Lines;
		DoAction := FALSE;
		OneText := OneTxt;
		ActDetail := Detail;
		ActBlock := Block;
		ReqEnd := FALSE;
		Next := Nxt;
		Typ := GadgetTyp;

		IF Typ = TextGadget THEN
		BEGIN
			Buffer := ' ';
			Size := 1;
		END
		ELSE IF Typ = OnOffGadget THEN On := FALSE;
	END;
END; (* InitGadget *)

(* Diese Prozedur legt ein Requester-Element an und initialisiert es *)
PROCEDURE InitRequester(VAR RequesterItem : pRequester; Left, Top, Cols,
								Lines : BYTE; Detail, Block : Colors; Title : TextStr;
								ReqFlags : ReqFlagSet; GadgetLst : pGadget;
								TextLst : pIntuiText);
BEGIN
	New(RequesterItem);										(* Speicher reservieren 	*)

	WITH RequesterItem^ DO									(* Alle Werte eintragen 	*)
	BEGIN
		LeftEdge := Left;
		TopEdge := Top;
		Width := Cols;
		Height := Lines;
		DetailPen := Detail;
		BlockPen := Block;
		ReqTitle := Title;
		Flags := ReqFlags;
		DoInit := FALSE;
		GadgetList := GadgetLst;
		TextList := TextLst;
	END;
END; (* InitRequester *)

(* Diese Prozedur gibt eine komplette IntuiText-Liste frei *)
PROCEDURE DelIntuiTextList(VAR IntuiList : pIntuiText);
VAR Item : pIntuiText;
BEGIN
	WHILE IntuiList <> NIL DO								(* Komplette Liste			*)
	BEGIN
		Item := IntuiList;									(* Aktuelles Element 		*)
		IntuiList := IntuiList^.Next; 					(* NÑchstes Element			*)
		Dispose(Item); 										(* Speicher freigeben		*)
	END;
END; (* DelIntuiTextList *)

(* Diese Prozedur gibt eine komplette Gadget-Liste frei *)
PROCEDURE DelGadgetList(VAR GadgetList : pGadget);
VAR Item : pGadget;
BEGIN
	WHILE GadgetList <> NIL DO 							(* Komplette Liste			*)
	BEGIN
		Item := GadgetList;									(* Aktuelles Element 		*)
		GadgetList := GadgetList^.Next;					(* NÑchstes Element			*)
		DelIntuiTextList(Item^.OneText); 				(* Speicher des Textes		*)
		Dispose(Item); 										(* Speicher freigeben		*)
	END;
END; (* DelGadgetList *)

(* Diese Prozedur gibt den kompletten Speicher eines Requesters frei *)
PROCEDURE DelRequester(VAR RequesterItem : pRequester);
BEGIN
	DelIntuiTextList(RequesterItem^.TextList);		(* Texte freigeben			*)
	DelGadgetList(RequesterItem^.GadgetList); 		(* Gadgets freigeben 		*)
	Dispose(RequesterItem); 								(* Speicher freigeben		*)
	RequesterItem := NIL;									(* Nur zur Sicherheit		*)
END; (* DelRequester *)

(* Diese Prozedur zeichnet eine IntuiText-Liste in das aktive Fenster *)
PROCEDURE DrawIntuiText(IntuiList : pIntuiText);
BEGIN
	IF MouseAvail THEN MouseOff;							(* Maus ausschalten			*)

	WHILE IntuiList <> NIL DO								(* Komplette Liste			*)
	BEGIN
		WITH IntuiList^ DO
		BEGIN
			SetVirtualXY(LeftEdge, TopEdge);
			WriteString(Buffer, DetailPen, BlockPen);
		END;

		IntuiList := IntuiList^.Next; 					(* NÑchster Text der Liste *)
	END;

	IF MouseAvail THEN MouseOn;							(* Maus anschalten			*)
END; (* DrawIntuiText *)

(* Diese Prozedur zeichnet ein Gadget normal oder aktiv in das aktive Fenster *)
PROCEDURE DrawGadget(GadgetPtr : pGadget; Active : BOOLEAN);
VAR Detail, 													(* Vordergrundfarbe			*)
	 Block		: Colors;									(* Hintergrundfarbe			*)
	 GadgetText : IntuiText;								(* Text des Gadgets			*)
	 i,															(* ZÑhler fÅr Textausgabe	*)
	 ColBegin,													(* Spaltenbeginn Text		*)
	 ColEnd		: BYTE;										(* Spaltenende 				*)
BEGIN
	IF MouseAvail THEN MouseOff;							(* Maus ausschalten			*)
	GadgetText := GadgetPtr^.OneText^;					(* Ersten Text merken		*)

	IF Active THEN 											(* Gadget aktiv zeichnen	*)
	BEGIN
		Detail := GadgetPtr^.ActDetail;
		Block := GadgetPtr^.ActBlock;
		GadgetText.DetailPen := Detail;
		GadgetText.BlockPen := Block;
	END
	ELSE															(* Gadget normal zeichnen	*)
	BEGIN
		Detail := GadgetText.DetailPen;
		Block := GadgetText.BlockPen;
	END;

	DrawIntuiText(Addr(GadgetText)); 					(* Gadget-Text ausgeben 	*)

	WITH GadgetText DO
	BEGIN
		CASE GadgetPtr^.Typ OF								(* Gadgettyp unterscheiden *)
			OnOffGadget :										(* Gadget als Schalter		*)
			BEGIN
				IF LeftEdge - 4 > 0 THEN SetVirtualXY(LeftEdge - 4, TopEdge)
				ELSE SetVirtualXY(1, TopEdge);

				IF GadgetPtr^.On THEN WriteString('[X] ', Detail, Block)
				ELSE WriteString('[ ] ', Detail, Block);
			END;

			TextGadget :										(* Gadget fÅr Texteingabe	*)
			BEGIN
				ColBegin := LeftEdge + Length(Buffer) + 2;
				ColEnd := ColBegin + GadgetPtr^.Size - 1;

				SetVirtualXY(ColEnd + 1, TopEdge);
				WriteString(']', Detail, Block);

				SetVirtualXY(ColBegin - 2, TopEdge);
				WriteString(' [', Detail, Block);

				FOR i := ColBegin TO ColEnd DO
					WriteString(' ', Detail, Block);

				SetVirtualXY(ColBegin, TopEdge);
				WriteString(GadgetPtr^.Buffer, Detail, Block);
			END;

			OkGadget :											(* Gadget Ok und Ende		*)
			BEGIN
				SetVirtualXY(LeftEdge, TopEdge);
				WriteString('…ÕÕÕÕÕÕª', Detail, Block);
				SetVirtualXY(LeftEdge, TopEdge + 1);
				WriteString('∫  OK  ∫', Detail, Block);
				SetVirtualXY(LeftEdge, TopEdge + 2);
				WriteString('»ÕÕÕÕÕÕº', Detail, Block);

				SetVirtualXY(LeftEdge + 3, TopEdge + 1);

				WITH GadgetPtr^ DO
					WriteString('O', ActDetail, ActBlock);

				SetVirtualXY(LeftEdge + 4, TopEdge + 1);

				WITH GadgetPtr^.OneText^ DO
					WriteString('K', DetailPen, BlockPen);
			END;

			ExitGadget :										(* Gadget Exit und Ende 	*)
			BEGIN
				SetVirtualXY(LeftEdge, TopEdge);
				WriteString('…ÕÕÕÕÕÕª', Detail, Block);
				SetVirtualXY(LeftEdge, TopEdge + 1);
				WriteString('∫ EXIT ∫', Detail, Block);
				SetVirtualXY(LeftEdge, TopEdge + 2);
				WriteString('»ÕÕÕÕÕÕº', Detail, Block);

				SetVirtualXY(LeftEdge + 2, TopEdge + 1);

				WITH GadgetPtr^ DO
					WriteString('E', ActDetail, ActBlock);

				SetVirtualXY(LeftEdge + 3, TopEdge + 1);

				WITH GadgetPtr^.OneText^ DO
					WriteString('XIT', DetailPen, BlockPen);
			END;

			YesGadget : 										(* Gadget Yes und Ende		*)
			BEGIN
				SetVirtualXY(LeftEdge, TopEdge);
				WriteString('…ÕÕÕÕÕÕª', Detail, Block);
				SetVirtualXY(LeftEdge, TopEdge + 1);
				WriteString('∫ YES  ∫', Detail, Block);
				SetVirtualXY(LeftEdge, TopEdge + 2);
				WriteString('»ÕÕÕÕÕÕº', Detail, Block);

				SetVirtualXY(LeftEdge + 2, TopEdge + 1);

				WITH GadgetPtr^ DO
					WriteString('Y', ActDetail, ActBlock);

				SetVirtualXY(LeftEdge + 3, TopEdge + 1);

				WITH GadgetPtr^.OneText^ DO
					WriteString('ES', DetailPen, BlockPen);
			END;

			NoGadget :											(* Gadget No und Ende		*)
			BEGIN
				SetVirtualXY(LeftEdge, TopEdge);
				WriteString('…ÕÕÕÕÕÕª', Detail, Block);
				SetVirtualXY(LeftEdge, TopEdge + 1);
				WriteString('∫  NO  ∫', Detail, Block);
				SetVirtualXY(LeftEdge, TopEdge + 2);
				WriteString('»ÕÕÕÕÕÕº', Detail, Block);

				SetVirtualXY(LeftEdge + 3, TopEdge + 1);

				WITH GadgetPtr^ DO
					WriteString('N', ActDetail, ActBlock);

				SetVirtualXY(LeftEdge + 4, TopEdge + 1);

				WITH GadgetPtr^.OneText^ DO
					WriteString('O', DetailPen, BlockPen);
			END;

			ELSE ;												(* Restliche Gadgettypen	*)
		END;
	END;

	IF MouseAvail THEN MouseOn;							(* Maus anschalten			*)
END; (* DrawGadget *)

(* Diese Prozedur zeichnet eine Gadget-Liste in das aktive Fenster *)
PROCEDURE DrawGadgetList(GadgetList : pGadget);
BEGIN
	WHILE GadgetList <> NIL DO 							(* Komplette Liste			*)
	BEGIN
		DrawGadget(GadgetList, FALSE);					(* Ein Gadget zeichnen		*)
		GadgetList := GadgetList^.Next;					(* NÑchstes Element			*)
	END;
END; (* DrawGadgetList *)

(* Diese Prozedur nummeriert eine Gadget-Liste durch *)
PROCEDURE SetGadgetId(GadgetList : pGadget; StartNumber : BYTE);
VAR Id : UserId;												(* ZÑhler fÅr die Gadgets	*)
BEGIN
	Id := StartNumber;										(* Startwert					*)

	WHILE GadgetList <> NIL DO 							(* Komplette Liste			*)
	BEGIN
		GadgetList^.GadgetId := Id;
		Inc(Id);
		GadgetList := GadgetList^.Next;
	END;
END; (* SetGadgetId *)

(* Diese Funktion zÑhlt die Anzahl der Gadgets in einer Liste *)
FUNCTION GetNrOfGadgets(GadgetList : pGadget) : BYTE;
VAR NrOfGadgets : BYTE;
BEGIN
	NrOfGadgets := 0; 										(* Startwert					*)

	WHILE GadgetList <> NIL DO 							(* Komplette Liste			*)
	BEGIN
		Inc(NrOfGadgets);
		GadgetList := GadgetList^.Next;
	END;

	GetNrOfGadgets := NrOfGadgets;						(* Anzahl zurÅckgeben		*)
END; (* GetNrOfGadgets *)

(* Diese Prozedur zeichnet die BerÅhrungsfelder der Gadgets *)
PROCEDURE DrawGadgetAreas(GadgetList : pGadget; LeftOffset, TopOffset : BYTE);
BEGIN
	WHILE GadgetList <> NIL DO 							(* Komplette Liste			*)
	BEGIN
		WITH GadgetList^ DO
			CreateArea(LeftOffset + LeftEdge, TopOffset + TopEdge, Width,
						  Height, GadgetId); 				(* Mausfeld einrichten		*)

		GadgetList := GadgetList^.Next;
	END;
END; (* DrawGadgetAreas *)

(* Diese Prozedur lîscht alle BerÅhrungsfelder der Gadgets *)
PROCEDURE DelGadgetAreas(GadgetList : pGadget);
BEGIN
	WHILE GadgetList <> NIL DO 							(* Komplette Liste			*)
	BEGIN
		DeleteArea(GadgetList^.GadgetId);				(* Mausfeld lîschen			*)
		GadgetList := GadgetList^.Next;
	END;
END; (* DelGadgetAreas *)

(* Diese Funktion sucht fÅr eine Gadget-Id das passende Gadget *)
FUNCTION SearchGadget(GadgetList : pGadget; GadgetNr : UserId) : pGadget;
BEGIN
	WHILE GadgetList <> NIL DO 							(* Komplette Liste			*)
	BEGIN
		IF GadgetList^.GadgetId = GadgetNr THEN		(* Gadget gefunden			*)
		BEGIN
			SearchGadget := GadgetList;
			Exit;
		END;

		GadgetList := GadgetList^.Next;
	END;

	SearchGadget := NIL; 									(* Nichts gefunden			*)
END; (* SearchGadget *)

(* Diese Prozedur sucht ein Gadget eines bestimmten Typs *)
FUNCTION SearchGadgetTyp(GadgetList : pGadget; Typ : GadgetType) : pGadget;
BEGIN
	WHILE GadgetList <> NIL DO 							(* Komplette Liste			*)
	BEGIN
		IF GadgetList^.Typ = Typ THEN 					(* Gadget gefunden			*)
		BEGIN
			SearchGadgetTyp := GadgetList;
			Exit;
		END;

		GadgetList := GadgetList^.Next;
	END;

	SearchGadgetTyp := NIL; 								(* Nichts gefunden			*)
END; (* SearchGadgetTyp *)

(* Diese Funktion ermittelt das Gadget, mit dem ein Requester beendet wurde *)
FUNCTION GetEndGadget(GadgetList : pGadget) : pGadget;
BEGIN
	WHILE GadgetList <> NIL DO 							(* Komplette Liste			*)
	BEGIN
		IF GadgetList^.ReqEnd THEN 						(* Gadget gefunden			*)
		BEGIN
			GetEndGadget := GadgetList;
			Exit;
		END;

		GadgetList := GadgetList^.Next;
	END;

	GetEndGadget := NIL; 									(* Nichts gefunden			*)
END; (* GetEndGadget *)

(* Es wird eine Zeichenkette vom Bildschirm eingelesen *)
PROCEDURE RequesterRead(LeftEdge, TopEdge, Width : BYTE; KeyMask : CharSet;
								VAR TextString : STRING; DetailPen, BlockPen : Colors;
								VAR EndEvents : EndSet; FillWidth, TextOut : BOOLEAN);
CONST ScanCode = 0;											(* Taste liefert Scan Code *)
VAR DoLoop,
	 DoInsert  : BOOLEAN;
	 k,
	 CursorX,													(* Position des Cursors 	*)
	 NrOfChars : BYTE;										(* Eingegebene Buchstaben	*)
	 Character : CHAR;
	 NrOfBytes : INTEGER;
	 Source,
	 Target	  : pVideo;
	 NewEvent  : Event;										(* NÑchstes Ereignis 		*)
BEGIN
	CursorLine; 												(* Cursor definieren 		*)
	SetXY(LeftEdge, TopEdge);

	IF FillWidth THEN 										(* Textbereich einfÑrben	*)
		PutAttributes(LeftEdge, TopEdge, Width, 1,
						  (Ord(BlockPen) SHL 4) OR Ord(DetailPen));

	NrOfChars := 0;											(* Noch nichts eingegeben	*)
	CursorX := 0;												(* Cursor ganz links 		*)
	DoInsert := FALSE;										(* Texte Åberschreiben		*)
	DoLoop := TRUE;											(* Eingaben entgegennehmen *)

	IF TextOut THEN											(* Defaulttext ausgeben 	*)
	BEGIN
		IF Ord(TextString[0]) > Width THEN TextString[0] := Chr(Width);

		NrOfChars := Ord(TextString[0]); 				(* Text bereits vorhanden	*)
		PutString(LeftEdge, TopEdge, TextString, DetailPen, BlockPen);
	END;

	REPEAT
		REPEAT UNTIL IsEvent;								(* Warten auf ein Ereignis *)
		LookEvent(NewEvent); 								(* Ereignis zum Testen		*)

		IF NewEvent.Mouse THEN								(* Ereignis von der Maus	*)
		BEGIN
			IF rMouse IN EndEvents THEN					(* Mausklick = Ende			*)
			BEGIN
				IF (NewEvent.mEvent = EventLeftDown) AND
					(NewEvent.AreaId <> NoUserId) THEN
				BEGIN
					TextString[0] := Chr(NrOfChars); 	(* TextlÑnge eintragen		*)
					CursorLine;
					EndEvents := [rMouse];					(* Mit MouseClick beendet	*)
					DoLoop := FALSE;
				END;
			END;
		END
		ELSE IF NOT (NewEvent.ScanCode IN [42, 54, 250, 56, 29]) THEN
		BEGIN														(* Ereignis der Tastatur	*)
			Character := Chr(NewEvent.KeyCode);
			IF MouseAvail THEN MouseOff;					(* Maus ausschalten			*)

			IF Character = Chr(ScanCode) THEN			(* Taste liefert Scan Code *)
			BEGIN
				Character := Chr(NewEvent.ExtCode); 	(* Tastencode einlesen		*)

				CASE Ord(Character) OF
					CursorLeft :								(* Cursor nach links 		*)
					BEGIN
						IF CursorX > 0 THEN					(* Kein linker Rand			*)
						BEGIN
							SetXY(GetX - 1, GetY);			(* Cursor setzen				*)
							Dec(CursorX);
						END
						ELSE Write(Chr(7));					(* Unerlaubt = Piepston 	*)
					END;

					CursorRight :								(* Cursor nach rechts		*)
					BEGIN
						IF (CursorX < NrOfChars) AND (CursorX < Width - 1) THEN
						BEGIN
							SetXY(GetX + 1, GetY);			(* Cursor setzen				*)
							Inc(CursorX);
						END
						ELSE Write(Chr(7));					(* Unerlaubt = Piepston 	*)
					END;

					Home :								  		(* Cursor erste Position	*)
					BEGIN
						SetXY(GetX - CursorX, GetY); 		(* Anfang Eingabefeld		*)
						CursorX := 0;							(* Cursor am Feldanfang		*)
					END;

					EndKey :										(* Cursor letzte Position	*)
					BEGIN
						SetXY(GetX - CursorX + NrOfChars, GetY);
						CursorX := NrOfChars;  				(* Cursor am Feldende		*)
					END;

					Insert : 									(* öberschreiben/EinfÅgen	*)
					BEGIN
						DoInsert := NOT DoInsert;

						IF DoInsert THEN CursorBlock		(* Block = EinfÅgen			*)
						ELSE CursorLine;						(* Line = öberschreiben 	*)
					END;

					DelKey : 									(* Buchstabe lîschen 		*)
					BEGIN
						IF (NrOfChars = 0) OR (CursorX >= NrOfChars) THEN
							Write(Chr(7))						(* Nichts mehr zu lîschen	*)
						ELSE
						BEGIN 									(* Buchstabe lîschen 		*)
							NrOfBytes := NrOfChars - CursorX;

							IF NrOfBytes > 0 THEN			(* Text zu kopieren			*)
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

					PageDown :									(* Page Down Taste			*)
					BEGIN
						IF rPageDown IN EndEvents THEN	(* PageDown = Ende			*)
						BEGIN 									(* TextlÑnge eintragen		*)
							TextString[0] := Chr(NrOfChars);
							CursorLine;
							EndEvents := [rPageDown];		(* Mit PageDown beendet 	*)
							DoLoop := FALSE;
						END
						ELSE Write(Chr(7));					(* Taste unzulÑssig			*)
					END;

					PageUp : 									(* Page Up Taste				*)
					BEGIN
						IF rPageUp IN EndEvents THEN		(* PageUp = Ende				*)
						BEGIN 									(* TextlÑnge eintragen		*)
							TextString[0] := Chr(NrOfChars);
							CursorLine;
							EndEvents := [rPageUp]; 		(* Mit PageUp beendet		*)
							DoLoop := FALSE;
						END
						ELSE Write(Chr(7));					(* Taste unzulÑssig			*)
					END;

					ShiftTab :									(* Shift TAB Taste			*)
					BEGIN
						IF rShiftTabulator IN EndEvents THEN
						BEGIN 									(* ShiftTabulator = Ende	*)
							TextString[0] := Chr(NrOfChars); (* TextlÑnge eintragen	*)
							CursorLine;
							EndEvents := [rShiftTabulator];
							DoLoop := FALSE;
						END
						ELSE Write(Chr(7));					(* Taste unzulÑssig			*)
					END;

					CursorUp :									(* Cursor Up Taste			*)
					BEGIN
						IF rCursorUp IN EndEvents THEN	(* CursorUp = Ende			*)
						BEGIN
							TextString[0] := Chr(NrOfChars); (* TextlÑnge eintragen	*)
							CursorLine;
							EndEvents := [rCursorUp];		(* Mit CursorUp beendet 	*)
							DoLoop := FALSE;
						END
						ELSE Write(Chr(7));					(* Taste unzulÑssig			*)
					END;

					CursorDown :								(* Cursor Down Taste 		*)
					BEGIN
						IF rCursorDown IN EndEvents THEN (* CursorDown = Ende 		*)
						BEGIN
							TextString[0] := Chr(NrOfChars); (* TextlÑnge eintragen	*)
							CursorLine;
							EndEvents := [rCursorDown];	(* Mit CursorDown beendet	*)
							DoLoop := FALSE;
						END
						ELSE Write(Chr(7));					(* Taste unzulÑssig			*)
					END;
				ELSE
					Write(Chr(7)); 							(* Fremde Taste = Piepston *)
				END;
			END
			ELSE													(* Normales Zeichen			*)
			BEGIN
				CASE Ord(Character) OF
					BackSpace : 								(* Back Space Taste			*)
					BEGIN
						IF (CursorX = 0) OR (NrOfChars = 0) THEN
							Write(Chr(7))						(* Nichts mehr zu lîschen	*)
						ELSE
						BEGIN 									(* Buchstabe lîschen 		*)
							NrOfBytes := NrOfChars - CursorX;

							IF NrOfBytes > 0 THEN			(* Text zu kopieren			*)
							BEGIN
								Source := VideoPointer(TopEdge, LeftEdge + CursorX);
								Target := VideoPointer(TopEdge, LeftEdge + CursorX - 1);

								Move(Source^, Target^, NrOfBytes SHL 1);

								Move(TextString[CursorX + 1], TextString[CursorX],
									  NrOfBytes);
							END;

							PutChar(LeftEdge + NrOfChars - 1, TopEdge, ' ', DetailPen,
									  BlockPen);

							Dec(CursorX);						(* Cursor setzen				*)
							SetXY(GetX - 1, GetY);
							Dec(NrOfChars);
						END;
					END;

					CarriageReturn :							(* Carriage Return Taste	*)
					BEGIN
						IF rReturn IN EndEvents THEN		(* Return = Ende				*)
						BEGIN
							TextString[0] := Chr(NrOfChars); (* TextlÑnge eintragen	*)
							CursorLine;
							EndEvents := [rReturn]; 		(* Mit Return beendet		*)
							DoLoop := FALSE;
						END
						ELSE Write(Chr(7));					(* Taste unzulÑssig			*)
					END;

					Esc : 										(* Escape Taste				*)
					BEGIN
						IF rEscape IN EndEvents THEN		(* Escape = Ende				*)
						BEGIN
							TextString[0] := Chr(NrOfChars); (* TextlÑnge eintragen	*)
							CursorLine;
							EndEvents := [rEscape]; 		(* Mit Escape beendet		*)
							DoLoop := FALSE;
						END
						ELSE Write(Chr(7));					(* Taste unzulÑssig			*)
					END;

					Tab : 										(* Tabulator Taste			*)
					BEGIN
						IF rTabulator IN EndEvents THEN	(* Tabulator = Ende			*)
						BEGIN
							TextString[0] := Chr(NrOfChars); (* TextlÑnge eintragen	*)
							CursorLine;
							EndEvents := [rTabulator]; 	(* Mit Tabulator beendet	*)
							DoLoop := FALSE;
						END
						ELSE Write(Chr(7));					(* Taste unzulÑssig			*)
					END;
				ELSE												(* Normale Taste gedrÅckt	*)
					IF Character IN KeyMask THEN			(* Tastendruck verwenden	*)
					BEGIN
						IF DoInsert THEN						(* Text einfÅgen				*)
						BEGIN
							IF NrOfChars = Width THEN		(* EinfÅgen nicht mîglich	*)
								Write(Chr(7))					(* Piepston 					*)
							ELSE
							BEGIN 								(* EinfÅgen mîglich			*)
								NrOfBytes := NrOfChars - CursorX;

								IF NrOfBytes > 0 THEN		(* Text zu kopieren			*)
								BEGIN
									Source := VideoPointer(TopEdge, LeftEdge + CursorX);

									Target := VideoPointer(TopEdge, LeftEdge +
																  CursorX + 1);

									Move(Source^, Target^, NrOfBytes SHL 1);

									Move(TextString[CursorX + 1],
										  TextString[CursorX + 2], NrOfBytes);
								END;

								PutChar(LeftEdge + CursorX, TopEdge, Character,
										  DetailPen, BlockPen);

								TextString[CursorX + 1] := Character;

								IF CursorX < Width - 1 THEN
								BEGIN 							(* Noch kein rechter Rand	*)
									Inc(CursorX);
									SetXY(GetX + 1, GetY);
								END;

								Inc(NrOfChars);
							END;
						END
						ELSE										(* Text Åberschreiben		*)
						BEGIN
							PutChar(LeftEdge + CursorX, TopEdge, Character, DetailPen,
									  BlockPen);

							TextString[CursorX + 1] := Character;

							IF (Width > 1) AND (CursorX = Width - 2) AND
								(CursorX = NrOfChars - 1) THEN
							BEGIN									(* Leider ein Spezialfall	*)
								Inc(CursorX);
								SetXY(GetX + 1, GetY);
							END
							ELSE			 						(* öbliche Behandlung		*)
							BEGIN
								IF CursorX < Width - 1 THEN(* Noch kein rechter Rand	*)
								BEGIN
									Inc(CursorX);
									SetXY(GetX + 1, GetY);
								END;

								IF NrOfChars < CursorX THEN(* Platz zum Schreiben		*)
									Inc(NrOfChars)
								ELSE IF NrOfChars = CursorX THEN
								BEGIN 							(* Alles beschrieben 		*)
									IF (CursorX = Width - 1) AND (NrOfChars < Width) THEN
										Inc(NrOfChars);
								END;
							END;
						END;
					END
					ELSE Write(Chr(7));						(* Falsche Taste, Piepston *)
				END;
			END;

			IF MouseAvail THEN MouseOn;					(* Maus anschalten			*)
		END;

		IF DoLoop THEN GetEvent(NewEvent);				(* Ereignis beseitigen		*)
	UNTIL NOT DoLoop;
END; (* RequesterRead *)

(* Diese Funktion îffnet einen Requester und nimmt dessen Abfragen vor *)
FUNCTION OpenRequester(ReqItem : pRequester) : BOOLEAN;
VAR WindowHandle	: pWindow;								(* Handle des Fensters		*)
	 ReqWindow		: Window;								(* Fenster des Requesters	*)
	 NewEvent		: Event; 								(* Ereignis aufnehmen		*)
	 ActiveGadget	: pGadget;								(* Zeiger aktives Gadget	*)
	 MouseDeltaX,												(* Maus relativ zu ReqLeft *)
	 NrOfGadgets	: BYTE;									(* Anzahl der Gadgets		*)
	 QuitRequester,											(* Requester beenden 		*)
	 RequesterMove,											(* Requester wird bewegt	*)
	 ClickLeftDown : BOOLEAN;								(* Linke Maustaste unten	*)

(* Diese Prozedur ruft eine benutzerdefinierte Gadget-Aktion auf *)
PROCEDURE CallGadgetAction(UserGadgetAction : GadgetAction);
BEGIN
	WITH ReqItem^ DO
	BEGIN
		IF rClose IN ReqItem^.Flags THEN 				(* Schlie·gadget vorhanden *)
			DeleteArea(CloseGadget);

		IF rMove IN ReqItem^.Flags THEN					(* Movegadget vorhanden 	*)
			DeleteArea(MoveGadget);

		DelGadgetAreas(GadgetList);						(* BerÅhrungsfelder weg 	*)
		UserGadgetAction(ActiveGadget);					(* Prozedur aufrufen 		*)

		IF rClose IN Flags THEN 							(* Schlie·gadget vorhanden *)
			CreateArea(LeftEdge, TopEdge, 1, 1, CloseGadget);

		IF rMove IN Flags THEN								(* Movegadget vorhanden 	*)
			CreateArea(LeftEdge + 1, TopEdge, Width - 1, 1, MoveGadget);

		DrawGadgetAreas(GadgetList, LeftEdge, TopEdge);
	END;
END; (* CallGadgetAction *)

(* Diese Prozedur verschiebt einen Requester auf dem Bildschirm *)
PROCEDURE MoveRequester;
VAR WinStatus : BOOLEAN;									(* Status beim Verschieben *)
BEGIN
	IF MouseAvail THEN MouseOff;							(* Maus ausschalten			*)

	WITH ReqItem^ DO
	BEGIN
		IF rClose IN ReqItem^.Flags THEN 				(* Schlie·gadget vorhanden *)
			DeleteArea(CloseGadget);

		IF rMove IN ReqItem^.Flags THEN					(* Movegadget vorhanden 	*)
			DeleteArea(MoveGadget);

		DelGadgetAreas(GadgetList);						(* BerÅhrungsfelder weg 	*)

		IF (LeftEdge <> MouseX - MouseDeltaX) OR (TopEdge <> MouseY) THEN
		BEGIN
			IF rShadow IN Flags THEN						(* Requester hat Schatten	*)
			BEGIN
				IF (MouseX - MouseDeltaX + Width > NrOfColumns - 2) OR
					(MouseX < MouseDeltaX) OR
					(MouseY + Height > NrOfLines - 1) THEN
					SetMouseXY(LeftEdge + MouseDeltaX, TopEdge)
				ELSE WinStatus := MoveWindow(MouseX - MouseDeltaX, MouseY);
			END
			ELSE													(* Requester ohne Schatten	*)
			BEGIN
				IF (MouseX - MouseDeltaX + Width > NrOfColumns) OR
					(MouseX < MouseDeltaX) OR
					(MouseY + Height > NrOfLines) THEN
					SetMouseXY(LeftEdge + MouseDeltaX, TopEdge)
				ELSE WinStatus := MoveWindow(MouseX - MouseDeltaX, MouseY);
			END;
		END;

		LeftEdge := WindowHandle^.LeftEdge; 			(* Requester X nachtragen	*)
		TopEdge := WindowHandle^.TopEdge;				(* Requester Y nachtragen	*)

		IF rClose IN Flags THEN 							(* Schlie·gadget vorhanden *)
			CreateArea(LeftEdge, TopEdge, 1, 1, CloseGadget);

		IF rMove IN Flags THEN								(* Movegadget vorhanden 	*)
			CreateArea(LeftEdge + 1, TopEdge, Width - 1, 1, MoveGadget);

		DrawGadgetAreas(GadgetList, LeftEdge, TopEdge);
	END;

	IF MouseAvail THEN MouseOn;							(* Maus anschalten			*)
END; (* MoveRequester *)

(* Diese Prozedur aktiviert ein Gadget in der Liste *)
PROCEDURE ActivateGadget(NewGadget : pGadget; Reaction : BOOLEAN);
VAR Top, 														(* Neue Cursor Y Position	*)
	 Left 	 : BYTE; 										(* Neue Cursor X Position	*)
	 EndEvent : EndSet;										(* Menge der Endereignisse *)
BEGIN
	DrawGadget(ActiveGadget, FALSE); 					(* Gadget nicht mehr aktiv *)
	ActiveGadget := NewGadget;

	WITH ActiveGadget^ DO
	BEGIN
		CASE Typ OF 											(* Gadgettyp unterscheiden *)
			TextGadget :							  			(* Gadget fÅr Texteingabe	*)
			BEGIN
				DrawGadget(ActiveGadget, TRUE);			(* Neues Gadget ist aktiv	*)

				Left := ReqItem^.LeftEdge + OneText^.LeftEdge +
						  Length(OneText^.Buffer) + 2;

				Top := ReqItem^.TopEdge + OneText^.TopEdge;
				EndEvent := [rMouse, rEscape, rTabulator, rShiftTabulator];

				RequesterRead(Left, Top, Size, Mask, Buffer, ActDetail, ActBlock,
								  EndEvent, FALSE, TRUE);

				ClickLeftDown := FALSE;						(* LeftUp wird verschluckt	*)
			END;

			OnOffGadget :							  			(* Gadget als Schalter		*)
			BEGIN
				IF Reaction THEN On := NOT On;  			(* Schalter umstellen		*)
				DrawGadget(ActiveGadget, TRUE); 			(* Neues Gadget ist aktiv	*)

				WITH OneText^ DO								(* Cursor an neue Position *)
				BEGIN
					Top := ReqItem^.TopEdge + TopEdge;

					IF LeftEdge - 4 > 0 THEN
						Left := ReqItem^.LeftEdge + LeftEdge - 3
					ELSE Left := ReqItem^.LeftEdge + 2;
				END;

				SetXY(Left, Top);   							(* Echten Cursor setzen 	*)
			END;

			OkGadget, ExitGadget, YesGadget, NoGadget :
			BEGIN 												(* Ende-Gadgets				*)
				DrawGadget(ActiveGadget, TRUE);			(* Neues Gadget ist aktiv	*)

				IF Reaction THEN
				BEGIN
					ActiveGadget^.ReqEnd := TRUE;
					QuitRequester := TRUE;
				END;

				WITH OneText^ DO								(* Cursor an neue Position *)
				BEGIN
					Top := ReqItem^.TopEdge + TopEdge + 1;
					Left := ReqItem^.LeftEdge + LeftEdge + 2;
					IF (Typ = OkGadget) OR (Typ = NoGadget) THEN Inc(Left);
				END;

				SetXY(Left, Top); 							(* Echten Cursor setzen 	*)
			END;

			UserGadget :								  		(* Gadget fÅr Benutzer		*)
			BEGIN
				DrawGadget(ActiveGadget, TRUE);	  		(* Neues Gadget ist aktiv	*)

				WITH OneText^ DO						  		(* Cursor an neue Position *)
				BEGIN
					IF ColOfs = 0 THEN CursorOff	  		(* Cursor ausschalten		*)
					ELSE
					BEGIN
						Top := ReqItem^.TopEdge + TopEdge;
						Left := ColOfs + ReqItem^.LeftEdge + LeftEdge;
						SetXY(Left, Top); 					(* Echten Cursor setzen 	*)
					END;
				END;
			END;
		END;

		IF DoAction AND (Typ = TextGadget) THEN  	 	(* Textgadget immer Aktion	*)
			CallGadgetAction(Action)
		ELSE IF DoAction AND Reaction THEN	 			(* Gadgetaktion ausfÅhren	*)
			CallGadgetAction(Action);
	END;
END; (* ActivateGadget *)

(* Diese Prozedur wird aufgerufen, wenn die Maus benutzt wurde *)
PROCEDURE DoMouse(NewEvent : Event);
VAR GadgetItem : pGadget;
BEGIN
	WITH NewEvent DO
	BEGIN
		CASE mEvent OF 										(* Ereignis unterscheiden	*)
			EventLeftDown :									(* Maus links gedrÅckt		*)
			BEGIN
				IF AreaId = CloseGadget THEN				(* Schlie·gadget gedrÅckt	*)
					QuitRequester := TRUE
				ELSE IF AreaId = MoveGadget THEN 		(* Movegadget gedrÅckt		*)
				BEGIN
					RequesterMove := TRUE;
					MouseDeltaX := MouseX - ReqItem^.LeftEdge;
				END
				ELSE IF AreaId <> NoUserId THEN
				BEGIN
					ClickLeftDown := TRUE;					(* Maus links gedrÅckt		*)
					GadgetItem := SearchGadget(ReqItem^.GadgetList, AreaId);

					IF GadgetItem^.Typ IN [TextGadget, OnOffGadget] THEN
						ActivateGadget(GadgetItem, TRUE) (* Maus links drÅcken		*)
					ELSE											(* Maus links loslassen 	*)
						ActivateGadget(GadgetItem, FALSE);
				END;
			END;

			EventLeftUp :										(* Maus links losgelassen	*)
			BEGIN
				IF ClickLeftDown THEN
				BEGIN
					ClickLeftDown := FALSE; 				(* Maus links losgelassen	*)

					IF AreaId <> NoUserId THEN
					BEGIN
						GadgetItem := SearchGadget(ReqItem^.GadgetList, AreaId);

						IF GadgetItem^.Typ IN [OkGadget, ExitGadget, YesGadget,
							NoGadget, UserGadget] THEN 	(* Maus links loslassen 	*)
							ActivateGadget(GadgetItem, TRUE);
					END
				END
				ELSE IF RequesterMove THEN					(* Requester bewegen Ende	*)
				BEGIN
					RequesterMove := FALSE;
																	(* Textgadget wieder aktiv	*)
					IF ActiveGadget^.Typ = TextGadget THEN
						ActivateGadget(ActiveGadget, TRUE);
				END;
			END;

			EventMouseMove :									(* Maus wurde bewegt 		*)
			BEGIN
				IF ClickLeftDown AND (AreaId <> NoUserId) AND
					(AreaId <> CloseGadget) AND (AreaId <> MoveGadget) THEN
				BEGIN
					GadgetItem := SearchGadget(ReqItem^.GadgetList, AreaId);

					IF GadgetItem <> ActiveGadget THEN
						ActivateGadget(GadgetItem, FALSE);
				END
				ELSE IF RequesterMove THEN	MoveRequester;
			END;

			ELSE ;												(* Mausereignis ignorieren *)
		END;
	END;
END; (* DoMouse *)

(* Diese Prozedur wird aufgerufen, wenn eine Taste gedrÅckt wurde *)
PROCEDURE DoKey(NewEvent : Event);
VAR GadgetItem : pGadget;
BEGIN
	IF NewEvent.KeyCode = 0 THEN							(* Erweiteter Tastencode	*)
	BEGIN
		IF NewEvent.ExtCode = ShiftTab THEN 			(* Shift und Tabulator		*)
		BEGIN
			IF ActiveGadget^.GadgetId = LowestGadget THEN
				GadgetItem := SearchGadget(ReqItem^.GadgetList, NrOfGadgets)
			ELSE
			BEGIN
				GadgetItem := SearchGadget(ReqItem^.GadgetList,
													ActiveGadget^.GadgetId - 1);
			END;

			ActivateGadget(GadgetItem, FALSE);			(* Gadget aktivieren 		*)
		END;
	END
	ELSE															(* Normaler Tastencode		*)
	BEGIN
		CASE NewEvent.KeyCode OF							(* Taste unterscheiden		*)
			Esc : 												(* ESC Taste gedrÅckt		*)
				QuitRequester := TRUE;						(* Ende der Auswahl			*)

			69, 101 :											(* Taste E, Taste e			*)
			BEGIN
				GadgetItem := SearchGadgetTyp(ReqItem^.GadgetList, ExitGadget);

				IF GadgetItem <> NIL THEN					(* Exit-Gadget vorhanden	*)
					ActivateGadget(GadgetItem, TRUE);	(* Neues Gadget aktivieren *)
			END;

			79, 111 :											(* Taste O, Taste o			*)
			BEGIN
				GadgetItem := SearchGadgetTyp(ReqItem^.GadgetList, OkGadget);

				IF GadgetItem <> NIL THEN					(* Exit-Gadget vorhanden	*)
					ActivateGadget(GadgetItem, TRUE);	(* Neues Gadget aktivieren *)
			END;

			78, 110 :											(* Taste N, Taste n			*)
			BEGIN
				GadgetItem := SearchGadgetTyp(ReqItem^.GadgetList, NoGadget);

				IF GadgetItem <> NIL THEN					(* Exit-Gadget vorhanden	*)
					ActivateGadget(GadgetItem, TRUE);	(* Neues Gadget aktivieren *)
			END;

			89, 121 :											(* Taste Y, Taste y			*)
			BEGIN
				GadgetItem := SearchGadgetTyp(ReqItem^.GadgetList, YesGadget);

				IF GadgetItem <> NIL THEN					(* Exit-Gadget vorhanden	*)
					ActivateGadget(GadgetItem, TRUE);	(* Neues Gadget aktivieren *)
			END;

			Tab : 												(* Tastencode Tabulator 	*)
			BEGIN
				IF ActiveGadget^.GadgetId = NrOfGadgets THEN
					GadgetItem := SearchGadget(ReqItem^.GadgetList, LowestGadget)
				ELSE
				BEGIN
					GadgetItem := SearchGadget(ReqItem^.GadgetList,
														ActiveGadget^.GadgetId + 1);
				END;

				ActivateGadget(GadgetItem, FALSE);		(* Gadget aktivieren 		*)
			END;

			CarriageReturn, Space : 						(* Taste Return oder Space *)
				ActivateGadget(ActiveGadget, TRUE); 	(* Neues Gadget aktivieren *)

			ELSE ;												(* Tastendruck ignorieren	*)
		END;
	END;
END; (* DoKey *)

BEGIN (* OpenRequester *)
	ReleaseCodeOff;											(* Keine Release Codes		*)
	IF MouseAvail THEN MouseOff;							(* Maus ausschalten			*)

	WITH ReqWindow DO 										(* Fensterdaten eintragen	*)
	BEGIN
		LeftEdge := ReqItem^.LeftEdge;
		TopEdge := ReqItem^.TopEdge;
		Width := ReqItem^.Width;
		Height := ReqItem^.Height;
		DetailPen := ReqItem^.DetailPen;
		BlockPen := ReqItem^.BlockPen;
		Flags := [Simple];

		IF rSingle IN ReqItem^.Flags THEN Flags := Flags + [Single]
		ELSE IF rDouble IN ReqItem^.Flags THEN Flags := Flags + [Double];

		IF rShadow IN ReqItem^.Flags THEN Flags := Flags + [Shadow];

		IF rTitle IN ReqItem^.Flags THEN
		BEGIN
			Flags := Flags + [Title];
			WinTitle := ReqItem^.ReqTitle;
		END;
	END;

	WindowHandle := OpenWindow(ReqWindow); 			(* Requesterfenster îffnen *)

	IF WindowHandle = NIL THEN 							(* Fehler vorhanden			*)
	BEGIN
		OpenRequester := FALSE;
		IF MouseAvail THEN MouseOn;						(* Maus anschalten			*)
	END
	ELSE															(* Alles in Ordnung			*)
	BEGIN
		WITH ReqItem^ DO
		BEGIN
			DrawIntuiText(TextList);						(* Alle Texte ausgeben		*)
			SetGadgetId(GadgetList, LowestGadget); 	(* Gadgets nummerieren		*)
			NrOfGadgets := GetNrOfGadgets(GadgetList);(* Anzahl aller Gadgets 	*)
			DrawGadgetList(GadgetList);					(* Gadgets zeichnen			*)
			ActiveGadget := GadgetList;					(* Erstes Gadget ist aktiv *)
			ClickLeftDown := FALSE; 						(* Maus nicht gedrÅckt		*)
			QuitRequester := FALSE;
			RequesterMove := FALSE;

			IF rClose IN Flags THEN 						(* Schlie·gadget vorhanden *)
				PutChar(LeftEdge, TopEdge, '˛', DetailPen, BlockPen);

			IF DoInit THEN InitProc;						(* Benutzerprozedur			*)

			IF rClose IN Flags THEN 						(* Schlie·gadget vorhanden *)
				CreateArea(LeftEdge, TopEdge, 1, 1, CloseGadget);

			IF rMove IN Flags THEN							(* Movegadget vorhanden 	*)
				CreateArea(LeftEdge + 1, TopEdge, Width - 1, 1, MoveGadget);

			DrawGadgetAreas(GadgetList, LeftEdge, TopEdge);
		END;

		IF MouseAvail THEN MouseOn;						(* Maus anschalten			*)
		WHILE IsEvent DO GetEvent(NewEvent);			(* Ereignisse lîschen		*)

		ActivateGadget(ActiveGadget, FALSE);			(* Gadget aktivieren 		*)

		REPEAT
			GetEvent(NewEvent);								(* Auf ein Ereignis warten *)

			IF NewEvent.Mouse THEN DoMouse(NewEvent)	(* Die Maus wurde benutzt	*)
			ELSE
			BEGIN                  	     					(* Taste wurde gedrÅckt 	*)
				IF NOT ClickLeftDown AND NOT RequesterMove THEN
					DoKey(NewEvent);
			END;
		UNTIL QuitRequester; 								(* Benutzer hat gewÑhlt 	*)

		OpenRequester := TRUE;								(* Alles in Ordnung			*)
	END;

	ReleaseCodeOn; 											(* Tasten Release Codes 	*)
END; (* OpenRequester *)

(* Diese Funktion schlie·t einen Requester und gibt seinen Speicher frei *)
FUNCTION CloseRequester(VAR ReqItem : pRequester) : BOOLEAN;
VAR WindowStatus : BOOLEAN;								(* Status beim Schlie·en	*)
BEGIN
	IF MouseAvail THEN MouseOff;							(* Maus ausschalten			*)

	IF rClose IN ReqItem^.Flags THEN 					(* Schlie·gadget vorhanden *)
		DeleteArea(CloseGadget);

	IF rMove IN ReqItem^.Flags THEN						(* Movegadget vorhanden 	*)
		DeleteArea(MoveGadget);

	DelGadgetAreas(ReqItem^.GadgetList);				(* BerÅhrungsfelder weg 	*)
	CloseRequester := CloseWindow;						(* Fenster schlie·en 		*)

	DelRequester(ReqItem);									(* Speicher freigeben		*)
	IF MouseAvail THEN MouseOn;							(* Maus anschalten			*)
END; (* CloseRequester *)

END. (* Intuitiv *)
