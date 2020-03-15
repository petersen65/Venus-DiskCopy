(******************************************************************)
(* Programmname     : FIFO.PAS V1.0                               *)
(* Programmautor    : Michael Rippl                               *)
(* Compiler         : Quick Pascal V1.0                           *)
(* Inhalt           : Routinen zur Verwaltung eines Ringes (FIFO) *)
(* Bemerkung        : -                                           *)
(* Letzte énderung  : 03-May-1990                                 *)
(******************************************************************)

UNIT Fifo;

INTERFACE

TYPE pRing = ^Ring;                                (* Zeiger auf Ringelement  *)

	  Ring  = RECORD                                (* Ringelement             *)
					 Content : POINTER;                 (* Inhalt vom Ringelement  *)
					 Next,                              (* NÑchstes Ringelement    *)
					 Prev    : pRing;                   (* Vorheriges Ringelement  *)
				 END;

(* Erzeugen eines Ringes *)
PROCEDURE CreateRing(VAR Head : pRing);

(* Ring wird ÅberprÅft, ob er leer ist *)
FUNCTION RingIsEmpty(Head : pRing) : BOOLEAN;

(* Ein Element wird in den Ring eingefÅgt *)
PROCEDURE Push(Head : pRing; ItemContent : POINTER);

(* Ein Element wird aus dem Ring entfernt *)
PROCEDURE Pop(Head : pRing; VAR ItemContent : POINTER);

(* Der komplette Ring wird gelîscht *)
PROCEDURE DeleteRing(VAR Head : pRing);

(* Durch Inhalt bestimmtes Objekt suchen und lîschen *)
PROCEDURE DeleteElement(Head : pRing; Content : POINTER);

IMPLEMENTATION

(* Erzeugen eines Ringes *)
PROCEDURE CreateRing(VAR Head : pRing);
BEGIN
	New(Head);

	Head^.Next := Head;                             (* Leerer Ring zeigt auf   *)
	Head^.Prev := Head;                             (* sich selbst             *)
END; (* CreateRing *)

(* Ring wird ÅberprÅft, ob er leer ist *)
FUNCTION RingIsEmpty(Head : pRing) : BOOLEAN;
BEGIN
	RingIsEmpty := Head = Head^.Next;
END; (* RingIsEmpty *)

(* Ein Element wird in den Ring eingefÅgt *)
PROCEDURE Push(Head : pRing; ItemContent : POINTER);
VAR Item : pRing;
BEGIN
	New(Item);

	WITH Item^ DO                                   (* Neues Element           *)
	BEGIN
		Content := ItemContent;                      (* Inhalt eintragen        *)
		Next := Head;                                (* Nachfolger des Elements *)
		Prev := Head^.Prev;                          (* VorgÑnger des Elements  *)
	END;

	WITH Head^ DO                                   (* Listenkopf              *)
	BEGIN
		Prev^.Next := Item;                          (* VorgÑngers Nachfolger   *)
		Prev := Item;                                (* VorgÑnger               *)
	END;
END; (* Push *)

(* Ein Element wird aus dem Ring entfernt *)
PROCEDURE Pop(Head : pRing; VAR ItemContent : POINTER);
VAR Item : pRing;
BEGIN
	IF NOT RingIsEmpty(Head) THEN                   (* Ring nicht leer         *)
	BEGIN
		Item := Head^.Next;                          (* Zu entfernendes Element *)
		ItemContent := Item^.Content;                (* Inhalt auslesen         *)

		WITH Head^ DO
		BEGIN
			Next := Item^.Next;                       (* Neuer Nachfolger        *)
			Next^.Prev := Head;                       (* Nachfolgers VorgÑnger   *)
		END;

		Dispose(Item);                               (* Element lîschen         *)
	END;
END; (* Pop *)

(* Der komplette Ring wird gelîscht *)
PROCEDURE DeleteRing(VAR Head : pRing);
VAR Content : POINTER;
BEGIN
	WHILE NOT RingIsEmpty(Head) DO
		Pop(Head, Content);                          (* Ring leeren             *)

	Dispose(Head);                                  (* Kopf des Ringes lîschen *)
	Head := NIL;
END; (* DeleteRing *)

(* Durch Inhalt bestimmtes Objekt suchen und lîschen *)
PROCEDURE DeleteElement(Head : pRing; Content : POINTER);
VAR Item : pRing;                                  (* Hilfszeiger             *)
BEGIN
	IF NOT RingIsEmpty(Head) THEN                   (* Ring nicht leer         *)
	BEGIN
		Item := Head^.Next;

		WHILE Item <> Head DO                        (* Ring durchlaufen        *)
		BEGIN
			IF Item^.Content = Content THEN           (* Gesuchtes Element       *)
			BEGIN
				Item^.Prev^.Next := Item^.Next;        (* VorgÑngers Nachfolger   *)
				Item^.Next^.Prev := Item^.Prev;        (* Nachfolgers VorgÑnger   *)
				Dispose(Item);                         (* Element lîschen         *)
				Item := Head;
			END
			ELSE Item := Item^.Next;                  (* NÑchstes Element        *)
		END;
	END;
END; (* DeleteElement *)

END. (* Fifo *)
