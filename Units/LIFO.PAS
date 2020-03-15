(*******************************************************************)
(* Programmname     : LIFO.PAS V1.0                                *)
(* Programmautor    : Michael Rippl                                *)
(* Compiler         : Quick Pascal V1.0                            *)
(* Inhalt           : Routinen zur Verwaltung eines Stapels (LIFO) *)
(* Bemerkung        : -                                            *)
(* Letzte énderung  : 25-May-1990                                  *)
(*******************************************************************)

UNIT Lifo;

INTERFACE

TYPE pStack = ^Stack;                     	      (* Zeigt auf Stackelement  *)

	  Stack  = RECORD                   	         (* Stackelement            *)
					  Content : POINTER; 	            (* Inhalt vom Stackelement *)
					  Next,                           	(* NÑchstes Stackelement   *)
					  Prev    : pStack;               	(* Vorheriges Stackelement *)
				  END;

(* Erzeugen eines Stapels *)
PROCEDURE CreateStack(VAR Top : pStack);

(* Stack wird ÅberprÅft, ob er leer ist *)
FUNCTION StackIsEmpty(Top : pStack) : BOOLEAN;

(* Element auf dem Stapel ablegen *)
PROCEDURE Push(VAR Top : pStack; ItemContent : POINTER);

(* Element vom Stapel nehmen *)
PROCEDURE Pop(VAR Top : pStack; VAR ItemContent : POINTER);

(* Der komplette Stapel wird gelîscht *)
PROCEDURE DeleteStack(VAR Top : pStack);

(* Durch Inhalt bestimmtes Objekt suchen und lîschen *)
PROCEDURE DeleteElement(VAR Top : pStack; Content : POINTER);

IMPLEMENTATION

(* Erzeugen eines Stapels *)
PROCEDURE CreateStack(VAR Top : pStack);
BEGIN
	Top := NIL;
END; (* CreateStack *)

(* Stack wird ÅberprÅft, ob er leer ist *)
FUNCTION StackIsEmpty(Top : pStack) : BOOLEAN;
BEGIN
	StackIsEmpty := Top = NIL;
END; (* StackIsEmpty *)

(* Element auf dem Stapel ablegen *)
PROCEDURE Push(VAR Top : pStack; ItemContent : POINTER);
VAR Item : pStack;
BEGIN
	New(Item);                                      (* Neues Stackelement      *)

	WITH Item^ DO
	BEGIN
		Content := ItemContent;                     	(* Inhalt eintragen        *)
		Next := Top;
		Prev := NIL;
	END;

	IF NOT StackIsEmpty(Top) THEN                   (* Schon Element auf Stack *)
		Top^.Prev := Item;                           (* VorgÑnger eintragen     *)

	Top := Item;                                    (* Neue Stackspitze        *)
END; (* Push *)

(* Element vom Stapel nehmen *)
PROCEDURE Pop(VAR Top : pStack; VAR ItemContent : POINTER);
VAR Item : pStack;
BEGIN
	IF StackIsEmpty(Top) THEN ItemContent := NIL
	ELSE
	BEGIN
		ItemContent := Top^.Content;                 (* Inhalt zuweisen         *)
		Item := Top;
		Top := Top^.Next;                            (* Neue Stackspitze        *)
		Dispose(Item);                               (* Stackspitze lîschen     *)

		IF NOT StackIsEmpty(Top) THEN                (* Noch Element auf Stack  *)
			Top^.Prev := NIL;                         (* Kein VorgÑnger mehr     *)
	END;
END; (* Pop *)

(* Der komplette Stapel wird gelîscht *)
PROCEDURE DeleteStack(VAR Top : pStack);
VAR Content : POINTER;
BEGIN
	WHILE NOT StackIsEmpty(Top) DO
		Pop(Top, Content);                           (* Stapel leeren           *)

	Dispose(Top);                                   (* Kopf vom Stapel lîschen	*)
	Top := NIL;
END; (* DeleteStack *)

(* Durch Inhalt bestimmtes Objekt suchen und lîschen *)
PROCEDURE DeleteElement(VAR Top : pStack; Content : POINTER);
VAR Item : pStack;                                 (* Hilfszeiger             *)
BEGIN
	IF NOT StackIsEmpty(Top) THEN                   (* Stapel nicht leer       *)
	BEGIN
		Item := Top;

		REPEAT                                       (* Stapel durchlaufen      *)
			IF Item^.Content = Content THEN           (* Gesuchtes Element       *)
			BEGIN
				IF Item^.Next <> NIL THEN					(* Nachfolger betrachten	*)
					Item^.Next^.Prev := Item^.Prev;		(* Nachfolgers VorgÑnger	*)

				IF Item^.Prev <> NIL THEN					(* VorgÑnger betrachten		*)
					Item^.Prev^.Next := Item^.Next;		(* VorgÑngers Nachfolger	*)

				IF Item = Top THEN Top := Item^.Next;	(* Neue Stapelspitze			*)
				Dispose(Item);
				Item := NIL;
			END
			ELSE Item := Item^.Next;                  (* NÑchstes Element        *)
		UNTIL Item = NIL;
	END;
END; (* DeleteElement *)

END. (* Lifo *)
