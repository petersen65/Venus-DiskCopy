(****************************************************************)
(* Programmname    : TOOLMENU.PAS V2.4                          *)
(* Programmautor   : Michael Rippl             		             *)
(* Compiler        : Quick Pascal V1.0    	                   *)
(* Inhalt          : MenÅ Tools des Kopierprogramms Venus V2.1  *)
(* Bemerkung       : EnthÑlt ein komplettes Dateikopierprogramm *)
(* Letzte énderung : 07-Mar-1991                                *)
(****************************************************************)

UNIT ToolMenu;         										(*$V- Kein String Checking	*)
																	(*$I- Kein I/O Checking		*)
INTERFACE

USES Crt, Dos, Fifo, Windows, Primitiv, Intuitiv,
	  FileInfo, KeyMouse, VenColor, CopyMenu;       (* Units einbinden			*)

(* Diese Prozedur aktiviert eine virtuelle Dos Shell *)
PROCEDURE DoDosShell(WinLeft, WinTop, WinWidth, WinHeight : BYTE);

(* Diese Prozedur ermîglicht eine Farbmodifikation von Venus *)
PROCEDURE DoChangeColors(VAR ColBlack, ColBlue, ColCyan, ColRed, ColMag,
								 ColLiGrey, ColLiGrn, ColLiCyan, ColYel, ColWh,
								 ColLiRed, ColLiMag : Colors; VAR DoChange : BOOLEAN);

(* Diese Prozedur speichert die Konfigurationsdatei von Venus *)
PROCEDURE DoSaveConfig(SourceDrive, TargetDrive : CHAR; XmsUsage, EmsUsage,
							  ExtUsage, RamDiskUsage, HardDiskUsage : BOOLEAN;
							  NrOfErrorTrials : BYTE;
							  VerifyTarget, FormatTarget : BOOLEAN;
							  ToHd, FromHd : STRING);

IMPLEMENTATION

TYPE ColStr = STRING[13];									(* Typ eines Farbbegriffes	*)

(* Diese Prozedur wandelt eine Farbe in deren Wort um *)
FUNCTION ColToStr(Col : Colors) : ColStr;
BEGIN
	CASE Col OF													(* Farbe unterscheiden		*)
		Black 		 : ColToStr := 'BLACK        ';
		Blue  		 : ColToStr := 'BLUE         ';
		Green			 : ColToStr := 'GREEN        ';
		Cyan			 : ColToStr := 'CYAN         ';
		Red   		 : ColToStr := 'RED          ';
		Magenta 		 : ColToStr := 'MAGENTA      ';
		Brown			 : ColToStr := 'BROWN        ';
		LightGrey 	 : ColToStr := 'LIGHT GREY   ';
		DarkGrey 	 : ColToStr := 'DARK GREY    ';
		LightBlue 	 : ColToStr := 'LIGHT BLUE   ';
		LightGreen 	 : ColToStr := 'LIGHT GREEN  ';
		LightCyan 	 : ColToStr := 'LIGHT CYAN   ';
		LightRed 	 : ColToStr := 'LIGHT RED    ';
		LightMagenta : ColToStr := 'LIGHT MAGENTA';
		Yellow 		 : ColToStr := 'YELLOW       ';
		White 		 : ColToStr := 'WHITE        ';
	END;
END; (* ColToStr *)

(*$F+ Diese Prozedur dient als Aktionsprozedur fÅr die Farbgadgets *)
PROCEDURE NewColor(GadgetPtr : pGadget);
BEGIN
	WITH GadgetPtr^ DO
	BEGIN
		Inc(UserWord);
		UserWord := UserWord MOD (Ord(White) + 1);  	(* Wei· hat hîchste Zahl	*)

		OneText^.Buffer[0] := Chr(25);					(* Alte Farbe abtrennen		*)
		OneText^.Buffer := OneText^.Buffer + ColToStr(Colors(UserWord));
		SetVirtualXY(OneText^.LeftEdge, OneText^.TopEdge);

		IF MouseAvail THEN MouseOff;						(* Maus ausschalten			*)
		WriteString(OneText^.Buffer, ActDetail, ActBlock);
		IF MouseAvail THEN MouseOn;						(* Maus anschalten			*)
	END;
END; (*$F- NewColor *)

(* Diese Prozedur ermîglicht eine Farbmodifikation von Venus *)
PROCEDURE DoChangeColors(VAR ColBlack, ColBlue, ColCyan, ColRed, ColMag,
								 ColLiGrey, ColLiGrn, ColLiCyan, ColYel, ColWh,
								 ColLiRed, ColLiMag : Colors; VAR DoChange : BOOLEAN);
VAR TxtOk,                   								(* Text des Ok-Gadgets		*)
	 TxtExit,  	                        				(* Text des Exit-Gadgets	*)
	 TxtBlack,                								(* Text Farbe Schwarz	  	*)
	 TxtBlue, 													(* Text Farbe Blau		  	*)
	 TxtCyan,                                       (* Text Farbe Cyan		  	*)
	 TxtRed,                                        (* Text Farbe Rot			  	*)
	 TxtMagenta,                                    (* Text Farbe Magenta	  	*)
	 TxtLiGrey,                                     (* Text Farbe Hell-Grau	  	*)
	 TxtLiGreen,                                    (* Text Farbe Hell-GrÅn	  	*)
	 TxtLiCyan,                                     (* Text Farbe Hell-Cyan   	*)
	 TxtYellow,                                     (* Text Farbe Gelb		  	*)
	 TxtWhite,  												(* Text Farbe Wei·		  	*)
	 TxtLiRed,                                      (* Text Farbe Hell-Rot   	*)
	 TxtLiMag   : pIntuiText;                       (* Text Farbe Hell-Magenta	*)
	 GadOk,             									 	(* Ok-Gadget					*)
	 GadBlack,                								(* Gadget Farbe Schwarz	  	*)
	 GadBlue, 													(* Gadget Farbe Blau		  	*)
	 GadCyan,                                       (* Gadget Farbe Cyan		  	*)
	 GadRed,                                        (* Gadget Farbe Rot		  	*)
	 GadMagenta,                                    (* Gadget Farbe Magenta	  	*)
	 GadLiGrey,                                     (* Gadget Farbe Hell-Grau 	*)
	 GadLiGreen,                                    (* Gadget Farbe Hell-GrÅn 	*)
	 GadLiCyan,                                     (* Gadget Farbe Hell-Cyan 	*)
	 GadYellow,                                     (* Gadget Farbe Gelb		  	*)
	 GadWhite,  												(* Gadget Farbe Wei·		  	*)
	 GadLiRed,                                      (* Gadget Farbe Hell-Rot  	*)
	 GadLiMag,   				                        (* Gadget Farbe Hell-Mag	*)
	 GadExit    : pGadget;                          (* Exit-Gadget					*)
	 Status 	   : BOOLEAN;	  		 						(* Status des Requesters	*)
	 ColorReq   : pRequester;								(* Requester fÅr Farben		*)
BEGIN
	InitIntuiText(TxtExit, 3, 15, cBlack, cCyan, '', NIL);
	InitIntuiText(TxtOk, 33, 15, cBlack, cCyan, '', NIL);

	InitIntuiText(TxtLiMag, 3, 13, cBlack, cCyan,
					  'Change ' + ColToStr(LightMagenta) +
					  '  To ' + ColToStr(ColLiMag), NIL);

	InitIntuiText(TxtLiRed, 3, 12, cBlack, cCyan,
					  'Change ' + ColToStr(LightRed) +
					  '  To ' + ColToStr(ColLiRed), NIL);

	InitIntuiText(TxtWhite, 3, 11, cBlack, cCyan,
					  'Change ' + ColToStr(White) +
					  '  To ' + ColToStr(ColWh), NIL);

	InitIntuiText(TxtYellow, 3, 10, cBlack, cCyan,
					  'Change ' + ColToStr(Yellow) +
					  '  To ' + ColToStr(ColYel), NIL);

	InitIntuiText(TxtLiCyan, 3, 9, cBlack, cCyan,
					  'Change ' + ColToStr(LightCyan) +
					  '  To ' + ColToStr(ColLiCyan), NIL);

	InitIntuiText(TxtLiGreen, 3, 8, cBlack, cCyan,
					  'Change ' + ColToStr(LightGreen) +
					  '  To ' + ColToStr(ColLiGrn), NIL);

	InitIntuiText(TxtLiGrey, 3, 7, cBlack, cCyan,
					  'Change ' + ColToStr(LightGrey) +
					  '  To ' + ColToStr(ColLiGrey), NIL);

	InitIntuiText(TxtMagenta, 3, 6, cBlack, cCyan,
					  'Change ' + ColToStr(Magenta) +
					  '  To ' + ColToStr(ColMag), NIL);

	InitIntuiText(TxtRed, 3, 5, cBlack, cCyan,
					  'Change ' + ColToStr(Red) +
					  '  To ' + ColToStr(ColRed), NIL);

	InitIntuiText(TxtCyan, 3, 4, cBlack, cCyan,
					  'Change ' + ColToStr(Cyan) +
					  '  To ' + ColToStr(ColCyan), NIL);

	InitIntuiText(TxtBlue, 3, 3, cBlack, cCyan,
					  'Change ' + ColToStr(Blue) +
					  '  To ' + ColToStr(ColBlue), NIL);

	InitIntuiText(TxtBlack, 3, 2, cBlack, cCyan,
					  'Change ' + ColToStr(Black) +
					  '  To ' + ColToStr(ColBlack), NIL);

	InitGadget(GadExit, 3, 15, 8, 3, TxtExit, cWhite, cCyan, NIL, ExitGadget);

	InitGadget(GadLiMag, 3, 13, 38, 1, TxtLiMag, cWhite, cCyan, GadExit,
				  UserGadget);

	InitGadget(GadLiRed, 3, 12, 38, 1, TxtLiRed, cWhite, cCyan, GadLiMag,
				  UserGadget);

	InitGadget(GadWhite, 3, 11, 38, 1, TxtWhite, cWhite, cCyan, GadLiRed,
				  UserGadget);

	InitGadget(GadYellow, 3, 10, 38, 1, TxtYellow, cWhite, cCyan, GadWhite,
				  UserGadget);

	InitGadget(GadLiCyan, 3, 9, 38, 1, TxtLiCyan, cWhite, cCyan, GadYellow,
				  UserGadget);

	InitGadget(GadLiGreen, 3, 8, 38, 1, TxtLiGreen, cWhite, cCyan, GadLiCyan,
				  UserGadget);

	InitGadget(GadLiGrey, 3, 7, 38, 1, TxtLiGrey, cWhite, cCyan, GadLiGreen,
				  UserGadget);

	InitGadget(GadMagenta, 3, 6, 38, 1, TxtMagenta, cWhite, cCyan, GadLiGrey,
				  UserGadget);

	InitGadget(GadRed, 3, 5, 38, 1, TxtRed, cWhite, cCyan, GadMagenta,
				  UserGadget);

	InitGadget(GadCyan, 3, 4, 38, 1, TxtCyan, cWhite, cCyan, GadRed,
				  UserGadget);

	InitGadget(GadBlue, 3, 3, 38, 1, TxtBlue, cWhite, cCyan, GadCyan,
				  UserGadget);

	InitGadget(GadBlack, 3, 2, 38, 1, TxtBlack, cWhite, cCyan, GadBlue,
				  UserGadget);

	InitGadget(GadOk, 33, 15, 8, 3, TxtOk, cWhite, cCyan, GadBlack, OkGadget);

	WITH GadBlack^ DO  										(* ZusÑtzliche Gadgetdaten	*)
	BEGIN
		ColOfs := 0;											(* Kein Cursor sichtbar		*)
		DoAction := TRUE;										(* Aktion soll stattfinden	*)
		Action := NewColor;									(* Aktionsprozedur			*)
		UserWord := Ord(ColBlack);							(* Wert der Farbe zuweisen	*)
	END;

	WITH GadBlue^ DO  										(* ZusÑtzliche Gadgetdaten	*)
	BEGIN
		ColOfs := 0;											(* Kein Cursor sichtbar		*)
		DoAction := TRUE;										(* Aktion soll stattfinden	*)
		Action := NewColor;									(* Aktionsprozedur			*)
		UserWord := Ord(ColBlue);							(* Wert der Farbe zuweisen	*)
	END;

	WITH GadCyan^ DO  										(* ZusÑtzliche Gadgetdaten	*)
	BEGIN
		ColOfs := 0;											(* Kein Cursor sichtbar		*)
		DoAction := TRUE;										(* Aktion soll stattfinden	*)
		Action := NewColor;									(* Aktionsprozedur			*)
		UserWord := Ord(ColCyan);							(* Wert der Farbe zuweisen	*)
	END;

	WITH GadRed^ DO  											(* ZusÑtzliche Gadgetdaten	*)
	BEGIN
		ColOfs := 0;											(* Kein Cursor sichtbar		*)
		DoAction := TRUE;										(* Aktion soll stattfinden	*)
		Action := NewColor;									(* Aktionsprozedur			*)
		UserWord := Ord(ColRed);							(* Wert der Farbe zuweisen	*)
	END;

	WITH GadMagenta^ DO  									(* ZusÑtzliche Gadgetdaten	*)
	BEGIN
		ColOfs := 0;											(* Kein Cursor sichtbar		*)
		DoAction := TRUE;										(* Aktion soll stattfinden	*)
		Action := NewColor;									(* Aktionsprozedur			*)
		UserWord := Ord(ColMag);	 						(* Wert der Farbe zuweisen	*)
	END;

	WITH GadLiGrey^ DO  										(* ZusÑtzliche Gadgetdaten	*)
	BEGIN
		ColOfs := 0;											(* Kein Cursor sichtbar		*)
		DoAction := TRUE;										(* Aktion soll stattfinden	*)
		Action := NewColor;									(* Aktionsprozedur			*)
		UserWord := Ord(ColLiGrey); 						(* Wert der Farbe zuweisen	*)
	END;

	WITH GadLiGreen^ DO  										(* ZusÑtzliche Gadgetdaten	*)
	BEGIN
		ColOfs := 0;											(* Kein Cursor sichtbar		*)
		DoAction := TRUE;										(* Aktion soll stattfinden	*)
		Action := NewColor;									(* Aktionsprozedur			*)
		UserWord := Ord(ColLiGrn); 						(* Wert der Farbe zuweisen	*)
	END;

	WITH GadLiCyan^ DO  										(* ZusÑtzliche Gadgetdaten	*)
	BEGIN
		ColOfs := 0;											(* Kein Cursor sichtbar		*)
		DoAction := TRUE;										(* Aktion soll stattfinden	*)
		Action := NewColor;									(* Aktionsprozedur			*)
		UserWord := Ord(ColLiCyan); 						(* Wert der Farbe zuweisen	*)
	END;

	WITH GadYellow^ DO  										(* ZusÑtzliche Gadgetdaten	*)
	BEGIN
		ColOfs := 0;											(* Kein Cursor sichtbar		*)
		DoAction := TRUE;										(* Aktion soll stattfinden	*)
		Action := NewColor;									(* Aktionsprozedur			*)
		UserWord := Ord(ColYel);  		 					(* Wert der Farbe zuweisen	*)
	END;

	WITH GadWhite^ DO  										(* ZusÑtzliche Gadgetdaten	*)
	BEGIN
		ColOfs := 0;											(* Kein Cursor sichtbar		*)
		DoAction := TRUE;										(* Aktion soll stattfinden	*)
		Action := NewColor;									(* Aktionsprozedur			*)
		UserWord := Ord(ColWh); 							(* Wert der Farbe zuweisen	*)
	END;

	WITH GadLiMag^ DO  										(* ZusÑtzliche Gadgetdaten	*)
	BEGIN
		ColOfs := 0;											(* Kein Cursor sichtbar		*)
		DoAction := TRUE;										(* Aktion soll stattfinden	*)
		Action := NewColor;									(* Aktionsprozedur			*)
		UserWord := Ord(ColLiMag); 						(* Wert der Farbe zuweisen	*)
	END;

	WITH GadLiRed^ DO  										(* ZusÑtzliche Gadgetdaten	*)
	BEGIN
		ColOfs := 0;											(* Kein Cursor sichtbar		*)
		DoAction := TRUE;										(* Aktion soll stattfinden	*)
		Action := NewColor;									(* Aktionsprozedur			*)
		UserWord := Ord(ColLiRed); 						(* Wert der Farbe zuweisen	*)
	END;

	GadBlue^.ColOfs := 0;
	GadRed^.ColOfs := 0;
	GadCyan^.ColOfs := 0;
	GadMagenta^.ColOfs := 0;
	GadLiGrey^.ColOfs := 0;
	GadLiGreen^.ColOfs := 0;
	GadLiCyan^.ColOfs := 0;
	GadYellow^.ColOfs := 0;
	GadWhite^.ColOfs := 0;
	GadLiRed^.ColOfs := 0;
	GadLiMag^.ColOfs := 0;

	InitRequester(ColorReq, 16, 3, 44, 19, cBlack, cCyan,
					  ' Change Colors ',
					  [rClose, rMove, rShadow, rTitle, rDouble], GadOk, NIL);

	Status := OpenRequester(ColorReq);   				(* Requester îffnen			*)

	IF GetEndGadget(GadOk) = GadOk THEN	  		 		(* Parameter Åbernehmen		*)
	BEGIN
		ColBlack := Colors(GadBlack^.UserWord);
		ColBlue := Colors(GadBlue^.UserWord);
		ColCyan := Colors(GadCyan^.UserWord);
		ColRed := Colors(GadRed^.UserWord);
		ColMag := Colors(GadMagenta^.UserWord);
		ColLiGrey := Colors(GadLiGrey^.UserWord);
		ColLiGrn := Colors(GadLiGreen^.UserWord);
		ColLiCyan := Colors(GadLiCyan^.UserWord);
		ColYel := Colors(GadYellow^.UserWord);
		ColWh := Colors(GadWhite^.UserWord);
		ColLiRed := Colors(GadLiRed^.UserWord);
		ColLiMag := Colors(GadLiMag^.UserWord);
		DoChange := TRUE;										(* Farben verÑndern			*)
	END
	ELSE DoChange := FALSE;									(* Farben nicht verÑndern	*)

	IF Status THEN
		Status := CloseRequester(ColorReq);				(* Requester schlie·en		*)
END; (* DoChangeColors *)

(* Diese Prozedur aktiviert eine virtuelle Dos Shell *)
PROCEDURE DoDosShell(WinLeft, WinTop, WinWidth, WinHeight : BYTE);

CONST LineLength = 78;										(* LÑnge der Eingabezeile	*)
		HistoryMax = 16;	 	  								(* LÑnge Befehlshistory		*)

TYPE CommandStr = STRING[LineLength];					(* Typ einer Eingabezeile	*)

VAR DosWindow    : Window; 								(* Ein-/Ausgabefenster		*)
	 WindowHandle : pWindow; 								(* Handle fÅr Fenster		*)
	 UseText,  													(* Nutze alten Eingabetext	*)
	 WindowStatus : BOOLEAN;								(* Status vom Fenster		*)
	 ActualDir	  : PathStr;								(* Aktuelles Verzeichnis	*)
	 Command      : CommandStr; 							(* Eingegebenes Kommando  	*)
	 i				  : BYTE;									(* Dient nur als ZÑhler		*)
	 EndKeys 	  : KeySet;									(* Endetasten fÅr Eingabe	*)
	 CursorIndex,												(* Index fÅr Cursorsuche	*)
	 HistoryIndex : 1..HistoryMax;						(* Index Historytabelle		*)
	 History      : ARRAY [1..HistoryMax] OF	  		(* Texte Befehlshistory		*)
							CommandStr;

(* Diese Funktion prÅft, ob eine Unterbrechung durch ESC vorgenommen wurde *)
FUNCTION CheckEsc(Activity : CommandStr) : BOOLEAN;
VAR Answer : STRING;	 										(* Nimmt Antwort auf			*)
BEGIN
	CheckEsc := FALSE;										(* Vorgabewert					*)

	IF KeyPressed THEN  							 			(* Taste wurde gedrÅckt		*)
	BEGIN
		Answer[1] := ReadKey;  								(* Tastencode einlesen		*)

		IF Answer[1] = Chr(0) THEN							(* Taste liefert ScanCode	*)
			Answer[1] := ReadKey								(* Tastencode ignorieren	*)
		ELSE IF Answer[1] = Chr(27) THEN   				(* ESC Taste gedrÅckt		*)
		BEGIN
			WriteLnString('', cWhite, cBlue);
			WriteString('Do You Want To Abort ', cWhite, cBlue);
			WriteString(Activity + ' (Y,N) ? ', cWhite, cBlue);
			ReadLnString(Answer, cWhite, cBlue);  		(* Text von Tastatur	holen	*)

			IF UpCase(Answer[1]) = 'Y' THEN  			(* Vorgang abbrechen			*)
			BEGIN
				WriteLnString(Activity + ' Aborted', cWhite, cBlue);
				WriteLnString('', cWhite, cBlue);
				CheckEsc := TRUE;
			END;
		END;
	END;
END; (* CheckEsc *)

(* Diese Funktion gibt die Anzahl von Parametern eines Kommandos zurÅck *)
FUNCTION ParamCount : BYTE;
VAR i,															(* Dient nur als ZÑhler		*)
	 Count,														(* Anzahl der Parameter		*)
	 Start,														(* Echter Kommandoanfang	*)
	 CommandLen : BYTE;										(* LÑnge des Kommandos	  	*)
BEGIN
	CommandLen := Length(Command);						(* LÑnge der Eingabezeile	*)
	Count := 0;													(* Anzahl der Parameter		*)
	Start := 1;													(* Anfang des Textes			*)

	IF CommandLen > 0 THEN									(* Keine leerer Text			*)
		WHILE (Command[Start] = ' ') AND (Start <= CommandLen) DO Inc(Start);

	FOR i := Start TO CommandLen - 1 DO					(* Eingabetext durchgehen	*)
	BEGIN
		IF i < CommandLen THEN
		BEGIN
			IF (Command[i] = ' ') AND (Command[i + 1] <> ' ') THEN
				Inc(Count);										(* Parameter gefunden		*)
		END;
	END;

	ParamCount := Count;										(* Anzahl der Parameter		*)
END; (* ParamCount *)

(* Diese Funktion gibt einen bestimmten Parameter eines Kommandos zurÅck *)
FUNCTION ParamStr(Index : BYTE) : PathStr;
VAR i,                                             (* Dient nur als ZÑhler		*)
	 j,															(* ZÑhler String kopieren	*)
	 Count : INTEGER; 										(* Anzahl der Parameter		*)
	 Space : BOOLEAN;											(* Leerzeichen gefunden		*)
BEGIN
	ParamStr := '';											(* Defaultwert					*)

	IF Index <= ParamCount THEN							(* Parameter existiert		*)
	BEGIN
		Space := TRUE;
		Count := -1;

		FOR i := 1 TO Length(Command) DO					(* Textstring durchgehen	*)
		BEGIN
			IF Command[i] = ' ' THEN Space := TRUE
			ELSE IF Space THEN								(* Parameter gefunden  		*)
			BEGIN
				Space := FALSE;
				Inc(Count);										(* Neuer Parameter			*)

				IF Index = Count THEN  						(* Parameter gefunden		*)
				BEGIN
					j := i;										(* Anfang des Parameters	*)

					WHILE (j <= Length(Command)) AND (Command[j] <> ' ') DO
					BEGIN                      			(* Parametertext kopieren	*)
						ParamStr[j - i + 1] := _UpCase(Command[j]);
						Inc(j);									(* NÑchster Buchstabe		*)
					END;

					ParamStr[0] := Chr(j - i);				(* LÑnge des Strings			*)
					Exit;											(* Funktion verlassen		*)
				END;
			END;
		END;
	END;
END; (* ParamStr *)

(* Diese Prozedur zeigt ein Inhaltsverzeichnis an *)
PROCEDURE DoDir;
TYPE Status   = (IllegalOpt, TooMuchPars, SubDirOn, PauseOn, HelpOn, WidthOn);
	  ParamSet = SET OF Status;							(* Statusmenge Parameter	*)

VAR ParamStatus : ParamSet;								(* Status der Parameter		*)
	 i, 		 													(* Dient nur als ZÑhler		*)
	 DirIndex    : INTEGER;									(* Index Verzeichnisname	*)
	 NrFiles,													(* Kopie von 'NrOfFiles'	*)
	 NrOfFiles   : WORD;										(* Anzahl aller Dateien		*)
	 FileSize	 : LONGINT;									(* Grî·e aller Dateien		*)
	 TextString  : PathStr;						  			(* Aufnahme von Texten		*)
	 ComplName   : CompleteStr;	  						(* Kompletter Dateiname		*)
	 pFile    	 : ^NameRec;					  			(* Eine gefundene Datei		*)
	 TimeInfo	 : DateTime;								(* Zeit und Datum 			*)
	 Drive,														(* Laufwerksbuchstabe		*)
	 Dummy	    : CHAR;							  			(* Nur Platzhalter			*)
	 Volume		 : DirStr;		 		  					(* Name einer Diskette		*)
	 Files       : pRing;									(* Liste fÅr alle Dateien	*)
	 FilesOk		 : BOOLEAN;									(* Zu viele DateieintrÑge	*)
BEGIN
	IF ParamCount > 4 THEN									(* Zu viele Parameter		*)
		WriteLnString('Too Much Parameters - ' + ParamStr(5), cWhite, cBlue)
	ELSE
	BEGIN
		ParamStatus := [ ];									(* Leerer Parameterstatus	*)
		DirIndex := 0;
		i := 1; 													(* Erster Parameter			*)

		WHILE (i <= ParamCount) AND  						(* Alle Parameter beachten	*)
			([IllegalOpt, TooMuchPars] * ParamStatus = [ ]) DO
		BEGIN
			TextString := ParamStr(i);	 					(* Parameter merken			*)

			IF TextString[1] = '/' THEN  					(* Option gefunden			*)
			BEGIN
				IF TextString = '/P' THEN					(* Ausgabe Seitenweise		*)
					ParamStatus := ParamStatus + [PauseOn]
				ELSE IF TextString = '/W' THEN        	(* Ausgabe in die Breite	*)
					ParamStatus := ParamStatus + [WidthOn]
				ELSE IF TextString = '/S' THEN        	(* Unterverzeichnisse an	*)
					ParamStatus := ParamStatus + [SubDirOn]
				ELSE IF TextString = '/H' THEN        	(* Ausgabe einer Info		*)
					ParamStatus := ParamStatus + [HelpOn]
				ELSE ParamStatus := ParamStatus + [IllegalOpt];
			END
			ELSE													(* Verzeichnisname 			*)
			BEGIN
				IF DirIndex > 0 THEN                 	(* Zu viele Parameter		*)
					ParamStatus := ParamStatus + [TooMuchPars]
				ELSE DirIndex := i;
			END;

			Inc(i);												(* NÑchster Parameter		*)
		END;

		IF TooMuchPars IN ParamStatus THEN				(* Zu viele Parameter		*)
			WriteLnString('Too Much Parameters - ' + TextString, cWhite, cBlue)
		ELSE IF HelpOn IN ParamStatus THEN				(* Information ausgeben		*)
		BEGIN
			WriteString('Usage : Dir <directory path>[[,<direc', cWhite, cBlue);
			WriteLnString('tory path>],...] [/h] [/s] [/p] [/w]', cWhite, cBlue);
		END
		ELSE IF IllegalOpt IN ParamStatus THEN			(* UnzulÑssige Option		*)
			WriteLnString('Illegal Option - ' + TextString, cWhite, cBlue)
		ELSE														(* Kein Parameterfehler		*)
		BEGIN
			IF DirIndex = 0 THEN								(* Aktuelles Verzeichnis	*)
				TextString := ActualDir
			ELSE TextString := ParamStr(DirIndex);	  	(* Verzeichnisname			*)

			IF Pos(',', TextString) = 0 THEN				(* Keine Liste von Namen	*)
			BEGIN
				TextString := FExpand(TextString); 		(* Name auf volle LÑnge		*)
				Drive := TextString[1];						(* Laufwerksbuchstabe		*)
				Volume := GetVolume(Drive);				(* Name der Diskette			*)
			END
			ELSE
			BEGIN
				Drive := '?';									(* Kein Laufwerk				*)
				Volume := '';
			END;

			CutBackslash(TextString);						(* öberflÅssiges '\' weg	*)
			CreateRing(Files);								(* Fifo-Liste anlegen		*)

			FilesOk := GetFiles(TextString, Files, SubDirOn IN ParamStatus,
									  NrOfFiles);

			FileSize := GetFileSize(Files, NrOfFiles);
			NrFiles := NrOfFiles;							(* Inhalt fÅr FOR merken	*)
			WriteLnString('', cWhite, cBlue);

			IF Length(Volume) = 0 THEN						(* Kein Diskettenname da  	*)
			BEGIN
				WriteLnString(' Disk In Drive ' + Drive + ': Has No Volume Id',
								  cWhite, cBlue);
			END
			ELSE
			BEGIN
				WriteLnString(' Disk In Drive '  + Drive + ': Has Volume Id ' +
								  Volume, cWhite, cBlue);
			END;

			WriteLnString(' Directory Of ' + TextString, cWhite, cBlue);
			WriteLnString('', cWhite, cBlue);

			IF NOT FilesOk THEN								(* Zu viele DateieintrÑge	*)
				WriteLnString('Too Many Files - ' + TextString, cWhite, cBlue)
			ELSE IF NrOfFiles = 0 THEN	 					(* Verzeichnis nicht da		*)
			BEGIN
				WriteString('Directory Not Found', cWhite, cBlue);

				IF DirIndex <> 0 THEN 						(* Parameter keine Option	*)
					WriteLnString(' - ' + ParamStr(DirIndex), cWhite, cBlue);
			END
			ELSE													(* Verzeichnis durchgehen	*)
			BEGIN
				IF (SubDirOn IN ParamStatus) AND (WidthOn IN ParamStatus) THEN
				BEGIN
					FOR i := 1 TO NrFiles DO			  	(* Alle Dateien durchgehen	*)
					BEGIN
						Pop(Files, POINTER(pFile));	  	(* Datei aus Liste holen	*)

						WITH pFile^.FileItem DO				(* '.' und '..' entfernen	*)
						BEGIN
							IF (Name = '.') OR (Name = '..') THEN
							BEGIN
								Dec(NrOfFiles);				(* Eine Datei weniger		*)
								Dispose(pFile);				(* Speicher freigeben		*)
							END
							ELSE Push(Files, pFile);	  	(* Datei wieder in Liste  	*)
						END;
					END;
				END;

				FOR i := 1 TO NrOfFiles DO					(* Alle Dateien ausgeben	*)
				BEGIN
					IF CheckEsc('Directory') THEN			(* Ausgabe abgebrochen		*)
					BEGIN
						WHILE NOT RingIsEmpty(Files) DO	(* Dateiliste leeren			*)
						BEGIN
							Pop(Files, POINTER(pFile));  	(* Datei aus Liste holen	*)
							Dispose(pFile);					(* Speicher freigeben		*)
						END;

						DeleteRing(Files); 					(* Fifo-Liste lîschen		*)
						Exit;										(* Prozedur vorzeitig Ende	*)
					END
					ELSE IF WidthOn IN ParamStatus THEN	(* In die Breite ausgeben	*)
					BEGIN
						IF ((i MOD ((WinWidth DIV 15) * (WinHeight - 3))) = 0) AND
							(PauseOn IN ParamStatus) THEN	(* Ausgabe anhalten			*)
						BEGIN
							IF WhereVirtualX > 1 THEN
								WriteLnString('', cWhite, cBlue);

							WriteString('Press Any Key To Continue ...',
											cWhite, cBlue);

							REPEAT UNTIL KeyPressed;		(* Auf Tastendruck warten	*)
							Dummy := ReadKey;					(* Tastendruck einlesen		*)

							WriteLnString('', cWhite, cBlue);
						END;

						Pop(Files, POINTER(pFile));		(* Datei aus Liste holen	*)

						WITH pFile^.FileItem DO  			(* Dateiname ausgeben 		*)
						BEGIN
							IF Name = '.' THEN ComplName := '.           '
							ELSE IF Name = '..' THEN ComplName := '..          '
							ELSE
							BEGIN
								ComplName := ExpandName(Name);
								ComplName[9] := ' ';			(* Punkt im Namen lîschen	*)
							END;

							WriteString(ComplName + '   ', cWhite, cBlue);
						END;

						IF WhereVirtualX > WinWidth - 15 THEN
							WriteLnString('', cWhite, cBlue);

						Dispose(pFile);						(* Listeneintrag lîschen	*)
					END
					ELSE											(* Untereinander ausgeben	*)
					BEGIN
						IF ((i MOD (WinHeight - 3)) = 0)	AND
							(PauseOn IN ParamStatus) THEN	(* Ausgabe anhalten			*)
						BEGIN
							WriteString('Press Any Key To Continue ...',
											cWhite, cBlue);

							REPEAT UNTIL KeyPressed;		(* Auf Tastendruck warten	*)
							Dummy := ReadKey;					(* Tastendruck einlesen		*)
							WriteLnString('', cWhite, cBlue);
						END;

						Pop(Files, POINTER(pFile));		(* Datei aus Liste holen	*)

						WITH pFile^.FileItem DO   			(* Dateiname ausgeben 		*)
						BEGIN
							IF Name = '.' THEN ComplName := '.           '
							ELSE IF Name = '..' THEN ComplName := '..          '
							ELSE
							BEGIN
								ComplName := ExpandName(Name);
								ComplName[9] := ' ';			(* Punkt im Namen lîschen	*)
							END;

							WriteString(ComplName, cWhite, cBlue);

							Str(Size : 9, TextString); 	(* Dateigrî·e als Text		*)
							SetVirtualXY(14, WhereVirtualY);

							IF Attr AND Directory = Directory THEN
								WriteString('<DIR>    ', cWhite, cBlue)
							ELSE WriteString(TextString, cWhite, cBlue);

																	(* Attribute ausgeben		*)
							SetVirtualXY(25, WhereVirtualY);
							WriteString(GetAttribChar(Attr, Hidden), cWhite, cBlue);
							WriteString(GetAttribChar(Attr, SysFile), cWhite, cBlue);
							WriteString(GetAttribChar(Attr, ReadOnly), cWhite, cBlue);
							WriteString(GetAttribChar(Attr, Archive), cWhite, cBlue);
							SetVirtualXY(31, WhereVirtualY);

							IF SubDirOn IN ParamStatus THEN
								WriteLnString(pFile^.Dir, cWhite, cBlue)
							ELSE									(* Unterverzeichnisse aus	*)
							BEGIN
								UnpackTime(Time, TimeInfo);(* Zeitformat umwandeln		*)

								WITH TimeInfo DO 	  			(* Zeit, Datum ausgeben		*)
								BEGIN
									Str(Day : 2, TextString);
									IF Day < 10 THEN TextString[1] := '0';
									WriteString(TextString, cWhite, cBlue);
									WriteString('/', cWhite, cBlue);

									Str(Month : 2, TextString);
									IF Month < 10 THEN TextString[1] := '0';
									WriteString(TextString, cWhite, cBlue);
									WriteString('/', cWhite, cBlue);

									Str(Year : 2, TextString);
									IF Year < 10 THEN TextString[1] := '0';
									WriteString(TextString, cWhite, cBlue);

									SetVirtualXY(43, WhereVirtualY);

									Str(Hour : 2, TextString);
									WriteString(TextString, cWhite, cBlue);
									WriteString(':', cWhite, cBlue);

									Str(Min : 2, TextString);
									IF Min < 10 THEN TextString[1] := '0';
									WriteString(TextString, cWhite, cBlue);
									WriteString(':', cWhite, cBlue);

									Str(Sec : 2, TextString);
									IF Sec < 10 THEN TextString[1] := '0';
									WriteLnString(TextString, cWhite, cBlue);
								END;
							END;
						END;

						Dispose(pFile);   					(* Listeneintrag lîschen	*)
					END;
				END;

				IF WidthOn IN ParamStatus THEN WriteLnString('', cWhite, cBlue);

				Str(NrOfFiles : 10, TextString); 	 	(* Anzahl Dateien als Text	*)
				WriteString(TextString + ' File(s)', cWhite, cBlue);

				Str(FileSize : 11, TextString);
				WriteLnString(TextString + ' Bytes', cWhite, cBlue);

				IF Drive <> '?' THEN							(* Keine Liste von Namen	*)
				BEGIN
					Str(DiskFree(Ord(Drive) - 64) : 29, TextString);
					WriteLnString(TextString + ' Bytes Free', cWhite, cBlue);
				END;
			END;

			DeleteRing(Files);								(* Fifo-Liste lîschen		*)
		END;
	END;

	WriteLnString('', cWhite, cBlue);
END; (* DoDir *)

(* Diese Prozedur wechselt das aktuelle Verzeichnis *)
PROCEDURE DoCd;
BEGIN
	IF ParamCount > 1 THEN									(* Zu viele Parameter		*)
		WriteLnString('Too Much Parameters - ' + ParamStr(2), cWhite, cBlue)
	ELSE IF ParamCount = 0 THEN							(* Aktuelles Verzeichnis	*)
		WriteLnString('Usage : Cd <directory path>', cWhite, cBlue)
	ELSE  														(* Verzeichnis wechseln		*)
	BEGIN
		ChDir(ParamStr(1));

		IF IOResult <> 0 THEN								(* Fehler aufgetreten		*)
			WriteLnString('Unknown Path - ' + ParamStr(1), cWhite, cBlue);
	END;

	WriteLnString('', cWhite, cBlue);
END; (* DoCd *)

(* Diese Prozedur entfernt ein leeres Verzeichnis *)
PROCEDURE DoRmDir;
VAR IOStatus : BYTE;											(* Status I/O Operation		*)
BEGIN
	IF ParamCount > 1 THEN									(* Zu viele Parameter		*)
		WriteLnString('Too Much Parameters - ' + ParamStr(2), cWhite, cBlue)
	ELSE IF ParamCount = 0 THEN  							(* Zu wenig Parameter		*)
		WriteLnString('Usage : RmDir <directory name>', cWhite, cBlue)
	ELSE			 			  									(* Verzeichnis entfernen	*)
	BEGIN
		RmDir(ParamStr(1));
		IOStatus := IOResult;								(* IOResult nur einmal		*)

		IF IOStatus = 150 THEN								(* Schreibschutzfehler		*)
			WriteLnString('Write Protect Error - ' + ParamStr(1), cWhite, cBlue)
		ELSE IF IOStatus <> 0 THEN	 	  					(* Fehler aufgetreten		*)
		BEGIN
			WriteString('Unknown Path Or Directory Not Empty - ', cWhite, cBlue);
			WriteLnString(ParamStr(1), cWhite, cBlue);
		END;
	END;

	WriteLnString('', cWhite, cBlue);
END; (* DoRmDir *)

(* Diese Prozedur legt ein neues Verzeichnis an *)
PROCEDURE DoMkDir;
VAR IOStatus : BYTE;											(* Status I/O Operation		*)
BEGIN
	IF ParamCount > 1 THEN									(* Zu viele Parameter		*)
		WriteLnString('Too Much Parameters - ' + ParamStr(2), cWhite, cBlue)
	ELSE IF ParamCount = 0 THEN  							(* Zu wenig Parameter		*)
		WriteLnString('Usage : MkDir <directory name>', cWhite, cBlue)
	ELSE                       							(* Verzeichnis anlegen  	*)
	BEGIN
		MkDir(ParamStr(1));
		IOStatus := IOResult;								(* IOResult nur einmal		*)

		IF IOStatus = 150 THEN								(* Schreibschutzfehler		*)
			WriteLnString('Write Protect Error - ' + ParamStr(1), cWhite, cBlue)
		ELSE IF IOStatus <> 0 THEN	 	  					(* Fehler aufgetreten		*)
		BEGIN
			WriteString('Cannot Make New Directory - ', cWhite, cBlue);
			WriteLnString(ParamStr(1), cWhite, cBlue);
		END;
	END;

	WriteLnString('', cWhite, cBlue);
END; (* DoMkDir *)

(* Diese Prozedur lîscht Dateien *)
PROCEDURE DoDel(Path : PathStr);
VAR Files 	  : pRing;										(* Liste aller Dateien		*)
	 i,															(* Dient nur als ZÑhler		*)
	 NrFiles,													(* Kopie von 'NrOfFiles'	*)
	 NrOfFiles : WORD;										(* Anzahl aller Dateien		*)
	 pFile     : ^NameRec;	 		  						(* Zeiger auf Suchverbund	*)
	 Target    : FILE;										(* Zu lîschende Dateien		*)
	 Answer    : CommandStr;								(* Antwort auf Abfrage		*)
	 FileTyp   : FileType;									(* Typ einer Datei			*)
	 IOStatus  : BYTE;      								(* Status I/O Operation		*)
	 FilesOk   : BOOLEAN;									(* Zu viele DateieintrÑge	*)
	 DelFiles  : STRING[10];								(* Anzahl gelîschte Files	*)
BEGIN
	FileTyp := GetFileType(Path);							(* Typ der Datei(en) holen	*)

	IF ParamCount = 0 THEN    								(* Zu wenig Parameter		*)
	BEGIN
		WriteString('Usage : Del <file name>', cWhite, cBlue);
		WriteLnString('[[,<file name>],...]', cWhite, cBlue);
	END
	ELSE IF FileTyp IN [NoFile, SystemFile, HiddenFile] THEN
		WriteLnString('File Not Found - ' + Path, cWhite, cBlue)
	ELSE IF FileTyp = RdOnlyFile THEN					(* Nur lesbare Datei			*)
		WriteLnString('File Is Read Only - ' + Path, cWhite, cBlue)
	ELSE
	BEGIN
		CreateRing(Files);  		 		  					(* Fifo-Liste anlegen		*)

		IF FileTyp = OneFile THEN						 	(* Einzelne Datei lîschen	*)
		BEGIN
			FilesOk := GetFiles(Path,	Files, FALSE, NrOfFiles);
			Pop(Files, POINTER(pFile));  					(* Eintrag aus Liste			*)

			WITH pFile^ DO
			BEGIN
				IF Dir[Length(Dir)] <> '\' THEN Dir := Dir + '\';

				Assign(Target, Dir + FileItem.Name);
				Erase(Target);									(* Datei lîschen				*)
				IOStatus := IOResult;  						(* IOResult nur einmal		*)

				IF IOStatus = 150 THEN						(* Schreibschutzfehler		*)
				BEGIN
					WriteString('Write Protect Error - ', cWhite, cBlue);
					WriteLnString(Dir + FileItem.Name, cWhite, cBlue);
				END
				ELSE IF IOStatus <> 0 THEN					(* Fehler aufgetreten		*)
				BEGIN
					WriteString('Not Deleted - ', cWhite, cBlue);
					WriteLnString(Dir + FileItem.Name, cWhite, cBlue);
				END
				ELSE
				BEGIN
					WriteString('Deleted - ', cWhite, cBlue);
					WriteLnString(Dir + FileItem.Name, cWhite, cBlue);
					WriteLnString('         1 File Deleted', cWhite, cBlue);
				END;
			END;

			Dispose(pFile);  									(* Eintrag entfernen			*)
		END
		ELSE 								                  (* Mehere Dateien lîschen	*)
		BEGIN
			IF FileTyp = DirFile THEN						(* Verzeichnis zu lîschen	*)
			BEGIN
				WriteLnString('Delete Files In Directory - ' + Path, cWhite, cBlue);
				WriteString('Are You Sure ? (Y,N) : ', cWhite,	cBlue);
				ReadLnString(Answer, cWhite, cBlue);  	(* Text von Tastatur	holen	*)

				IF Path[Length(Path)] <> '\' THEN Path := Path + '\';
				Path := Path + '*.*';
			END
			ELSE													(* Mehrere Dateien lîschen	*)
			BEGIN
				WriteLnString('Delete Several Files - ' + Path, cWhite,	cBlue);
				WriteString('Are You Sure ? (Y,N) : ', cWhite,	cBlue);
				ReadLnString(Answer, cWhite, cBlue);  	(* Text von Tastatur	holen	*)
			END;

			IF (Answer = 'y') OR (Answer = 'Y') THEN	(* Es soll gelîscht werden	*)
			BEGIN
				FilesOk := GetFiles(Path, Files, FALSE, NrOfFiles);

				IF Pos(',', Path) = 0 THEN					(* Keine Liste von Namen	*)
					Path := FExpand(Path);					(* Pfad auf volle LÑnge		*)

				NrFiles := NrOfFiles;						(* In FOR nicht geÑndert  	*)

				FOR i := 1 TO NrFiles DO					(* Verzeichnisse weg			*)
				BEGIN
					Pop(Files, POINTER(pFile));			(* Datei aus Liste holen	*)

					IF pFile^.FileItem.Attr AND Directory = Directory THEN
					BEGIN
						Dec(NrOfFiles);						(* Eine Datei weniger		*)
						Dispose(pFile);						(* Speicher freigeben		*)
					END
					ELSE Push(Files, pFile);				(* Datei in Liste behalten	*)
				END;

				IF NOT FilesOk THEN							(* Zu viele DateieintrÑge	*)
					WriteLnString('Too Many Files - ' + Path, cWhite, cBlue)
				ELSE IF NrOfFiles = 0 THEN					(* Keine Dateien vorhanden	*)
					WriteLnString('Nothing To Delete - ' + Path, cWhite,	cBlue);

				NrFiles := NrOfFiles;						(* Anzahl Dateien merken	*)

				FOR i := 1 TO NrOfFiles DO	 				(* Alle Dateien durchgehen	*)
				BEGIN
					IF CheckEsc('Delete') THEN				(* Lîschen abgebrochen		*)
					BEGIN
						WHILE NOT RingIsEmpty(Files) DO	(* Dateiliste leeren			*)
						BEGIN
							Pop(Files, POINTER(pFile));  	(* Datei aus Liste holen	*)
							Dispose(pFile);					(* Speicher freigeben		*)
						END;

						DeleteRing(Files); 					(* Fifo-Liste lîschen		*)
						Exit;										(* Prozedur vorzeitig Ende	*)
					END
					ELSE											(* Lîschen fortsetzen  		*)
					BEGIN
						Pop(Files, POINTER(pFile)); 		(* Eintrag aus Liste			*)

						WITH pFile^ DO
						BEGIN
							IF Dir[Length(Dir)] <> '\' THEN Dir := Dir + '\';

							IF FileItem.Attr AND ReadOnly = ReadOnly THEN
							BEGIN
								WriteString('File Is Read Only - ', cWhite, cBlue);
								WriteLnString(Dir + FileItem.Name, cWhite, cBlue);
								Dec(NrFiles);
							END
							ELSE IF FileItem.Attr AND (Hidden OR SysFile) = 0 THEN
							BEGIN									(* Keine versteckte Datei	*)
								Assign(Target, Dir + FileItem.Name);
								Erase(Target);	  		 		(* Datei lîschen				*)
								IOStatus := IOResult; 		(* IOResult nur einmal		*)

								IF IOStatus = 150 THEN 		(* Schreibschutzfehler		*)
								BEGIN
									WriteString('Write Protect Error - ', cWhite, cBlue);
									WriteLnString(Dir + FileItem.Name, cWhite, cBlue);
									Dec(NrFiles);
								END
								ELSE IF IOStatus <> 0 THEN	(* Fehler aufgetreten		*)
								BEGIN
									WriteString('Not Deleted - ', cWhite, cBlue);
									WriteLnString(Dir + FileItem.Name, cWhite, cBlue);
									Dec(NrFiles);
								END
								ELSE
								BEGIN
									WriteString('Deleted - ', cWhite, cBlue);
									WriteLnString(Dir + FileItem.Name, cWhite, cBlue);
								END;
							END
							ELSE Dec(NrFiles);				(* Hidden und SysFile		*)
						END;

						Dispose(pFile);  	  					(* Eintrag entfernen			*)
					END;
				END;

				IF FilesOk AND (NrFiles > 0) THEN		(* Anzahl Dateien ausgeben	*)
				BEGIN
					Str(NrFiles : 10, DelFiles);
					WriteLnString(DelFiles + ' File(s) Deleted', cWhite, cBlue);
				END;
			END;
		END;

		DeleteRing(Files);
	END;

	WriteLnString('', cWhite, cBlue);
END; (* DoDel *)

(* Diese Prozedur lîscht ganze VerzeichnisbÑume *)
PROCEDURE DoErase(Path : PathStr);
VAR FileTyp   : FileType;									(* Typ einer Datei			*)
	 DirPtr,														(* Zeiger auf Dir-Inhalt	*)
	 Files     : pRing;										(* Liste aller Dateien		*)
	 i,															(* Dient nur als ZÑhler		*)
	 NrDirs,														(* Kopie von 'NrOfDirs'		*)
	 NrOfDirs,													(* Anzahl Verzeichnisse		*)
	 NrFiles,													(* Kopie von 'NrOfFiles'	*)
	 NrOfFiles : WORD;										(* Anzahl aller Dateien		*)
	 pFile     : ^NameRec;									(* Zeiger auf Suchverbund	*)
	 Answer    : CommandStr;  								(* Antwort auf Abfrage		*)
	 FilePath  : PathStr;									(* Pfad zu einer Datei		*)
	 TextStr	  : STRING[10];								(* Anzahl Dateien/Dir's		*)
	 IOStatus  : BYTE;										(* Status I/O Operation		*)
	 Target    : FILE;										(* Zu lîschende Dateien		*)
	 FilesOk   : BOOLEAN;									(* Zu viele DateieintrÑge	*)
BEGIN
	IF ParamCount > 1 THEN	  								(* Zu viele Parameter		*)
		WriteLnString('Too Much Parameters - ' + ParamStr(2), cWhite, cBlue)
	ELSE IF ParamCount = 0 THEN  	  						(* Zu wenig Parameter		*)
		WriteLnString('Usage : Erase <directory path>', cWhite, cBlue)
	ELSE	                                          (* Verzeichnis lîschen		*)
	BEGIN
		FileTyp := GetFileType(Path);						(* Typ der Datei(en) holen	*)

		IF FileTyp IN [NoFile, SystemFile, HiddenFile] THEN
			WriteLnString('Directory Not Found - ' + Path, cWhite, cBlue)
		ELSE IF FileTyp = RdOnlyFile THEN				(* Nur lesbare Datei			*)
			WriteLnString('File Is Read Only - ' + Path, cWhite, cBlue)
		ELSE IF (FileTyp = OneFile) OR (FileTyp = MultFiles) THEN
			WriteLnString('Directory Expected - ' + Path, cWhite, cBlue)
		ELSE
		BEGIN        						  					(* Verzeichnis angegeben	*)
			WriteLnString('Delete Complete Directory - ' + Path, cWhite, cBlue);
			WriteString('Are You Sure ? (Y,N) : ', cWhite,	cBlue);
			ReadLnString(Answer, cWhite, cBlue);		(* Text von Tastatur	holen	*)

			IF (Answer = 'y') OR (Answer = 'Y') THEN	(* Es soll gelîscht werden	*)
			BEGIN
				CreateRing(Files);	  						(* Fifo-Liste anlegen		*)
				FilesOk := GetFiles(Path, Files, TRUE, NrOfFiles);
				NrFiles := NrOfFiles;  						(* Inhalt fÅr FOR merken	*)

				FOR i := 1 TO NrFiles DO					(* Alle Dateien durchgehen	*)
				BEGIN
					Pop(Files, POINTER(pFile));			(* Datei aus Liste holen	*)

					WITH pFile^.FileItem DO
					BEGIN
						IF	Attr AND (SysFile OR Hidden	(* Datei nicht lîschen		*)
							OR ReadOnly OR Directory) <> 0 THEN
						BEGIN
							Dec(NrOfFiles);					(* Eine Datei weniger		*)
							Dispose(pFile);					(* Speicher freigeben		*)
						END
						ELSE Push(Files, pFile);			(* Datei spÑter lîschen		*)
					END;
				END;

				NrFiles := NrOfFiles;						(* Anzahl Dateien merken	*)

				FOR i := 1 TO NrOfFiles DO					(* Alle Dateien lîschen		*)
				BEGIN
					IF CheckEsc('Erase') THEN				(* Lîschen abgebrochen		*)
					BEGIN
						WHILE NOT RingIsEmpty(Files) DO	(* Dateiliste leeren			*)
						BEGIN
							Pop(Files, POINTER(pFile));  	(* Datei aus Liste holen	*)
							Dispose(pFile);					(* Speicher freigeben		*)
						END;

						DeleteRing(Files); 					(* Fifo-Liste lîschen		*)
						Exit;										(* Prozedur vorzeitig Ende	*)
					END
					ELSE											(* Lîschen fortsetzen  		*)
					BEGIN
						Pop(Files, POINTER(pFile));  		(* Datei aus Liste holen	*)

						WITH pFile^.FileItem DO 			(* Datei wird gelîscht		*)
						BEGIN
							FilePath := pFile^.Dir; 		(* Pfad erstellen				*)

							IF FilePath[Length(FilePath)] <> '\' THEN
								FilePath := FilePath + '\';

							FilePath := FilePath + Name;	(* Pfad ist komplett			*)
							Assign(Target, FilePath); 		(* Name an Datei zuweisen	*)
							Erase(Target);	  					(* Datei lîschen				*)
							IOStatus := IOResult; 			(* IOResult nur einmal		*)

							IF IOStatus = 150 THEN	 		(* Schreibschutzfehler		*)
							BEGIN
								WriteString('Write Protect Error - ', cWhite, cBlue);
								WriteLnString(FilePath, cWhite, cBlue);
								Dec(NrFiles);
							END
							ELSE IF IOStatus <> 0 THEN	  	(* Fehler aufgetreten		*)
							BEGIN
								WriteLnString('Not Deleted - ' + FilePath,
												  cWhite, cBlue);
								Dec(NrFiles);
							END
							ELSE WriteLnString('Deleted - ' + FilePath, cWhite, cBlue);
						END;

						Dispose(pFile);						(* Speicher freigeben		*)
					END;
				END;

				IF NOT FilesOk THEN							(* Zu viele DateieintrÑge	*)
				BEGIN
					NrOfDirs := 0;
					WriteLnString('Too Many Files - ' + Path, cWhite, cBlue);
				END
				ELSE												(* DateieintrÑge sind Ok	*)
				BEGIN
					FilesOk := GetTree(Path, Files, NrOfDirs);
					NrDirs := NrOfDirs;						(* Anzahl Verzeichnisse		*)
					DirPtr := Files;							(* Zeigt auf Listenkopf		*)
				END;

				FOR i := 1 TO NrOfDirs DO					(* Alle Dirs durchgehen		*)
				BEGIN
					IF CheckEsc('Erase') THEN				(* Lîschen abgebrochen		*)
					BEGIN
						WHILE NOT RingIsEmpty(Files) DO	(* Liste wird geleert		*)
						BEGIN
							Pop(Files, POINTER(pFile));  	(* Eintrag aus Liste holen	*)
							Dispose(pFile);					(* Speicher freigeben		*)
						END;

						DeleteRing(Files); 					(* Fifo-Liste lîschen		*)
						Exit;										(* Prozedur vorzeitig Ende	*)
					END
					ELSE											(* Lîschen fortsetzen  		*)
					BEGIN
						DirPtr := DirPtr^.Prev;				(* Liste rÅckwÑrts gehen	*)
						pFile := DirPtr^.Content;			(* Zeiger auf Dateieintrag	*)

						RmDir(pFile^.Dir); 					(* Verzeichnis lîschen		*)
						IOStatus := IOResult;  				(* IOResult nur einmal		*)

						IF IOStatus = 150 THEN				(* Schreibschutzfehler		*)
						BEGIN
							WriteLnString('Write Protect Error - ' + pFile^.Dir,
											  cWhite, cBlue);
							Dec(NrDirs);
						END
						ELSE IF IOStatus <> 0 THEN	 		(* Fehler aufgetreten		*)
						BEGIN
							WriteLnString('Not Removed - ' + pFile^.Dir,
											  cWhite, cBlue);
							Dec(NrDirs);
						END
						ELSE WriteLnString('Removed - ' + pFile^.Dir, cWhite, cBlue);
					END;
				END;

				WHILE NOT RingIsEmpty(Files) DO			(* Liste wird geleert		*)
				BEGIN
					Pop(Files, POINTER(pFile));			(* Eintrag aus Liste	holen	*)
					Dispose(pFile);							(* Speicher freigeben		*)
				END;

				DeleteRing(Files);

				IF NrOfDirs > 0 THEN							(* Es wurde auch gelîscht	*)
				BEGIN
					Str(NrFiles : 10, TextStr);
					WriteLnString(TextStr + ' File(s) Deleted', cWhite, cBlue);

					Str(NrDirs : 10, TextStr);

					IF NrDirs > 1 THEN
						WriteLnString(TextStr + ' Directories Removed', cWhite, cBlue)
					ELSE
						WriteLnString(TextStr + ' Directory Removed', cWhite, cBlue);
				END;
			END;
		END;
	END;

	WriteLnString('', cWhite, cBlue);
END; (* DoErase *)

(* Diese Prozedur setzt oder lîscht ein Attribut von Dateien *)
PROCEDURE DoAttrib;
VAR FileTyp   : FileType;	  								(* Typ einer Datei			*)
	 Param,														(* Zweiter Parameter			*)
	 Path      : PathStr;									(* Erster Parameter			*)
	 AttrFiles : STRING[10];								(* Anzahl geÑnderter Files	*)
	 Files 	  : pRing;										(* Liste aller Dateien		*)
	 i,               										(* Dient nur als ZÑhler		*)
	 NrFiles,													(* Kopie von 'NrOfFiles'	*)
	 NrOfFiles : WORD;										(* Anzahl aller Dateien		*)
	 pFile     : ^NameRec;									(* Zeiger auf Suchverbund	*)
	 Target    : FILE;										(* Zu lîschende Dateien		*)
	 FilesOk   : BOOLEAN;									(* Zu viele DateieintrÑge	*)

(* Diese Prozedur ergÑnzt die Attribute einer Datei *)
PROCEDURE SetAttrib(VAR NrFiles : WORD);
VAR Attr : WORD;
BEGIN
	GetFAttr(Target, Attr);									(* Dateiattribute holen   	*)

	IF Param[1] = '+' THEN								 	(* Dateiattribut setzen	  	*)
	BEGIN
		CASE Param[2] OF 			 							(* Attribute unterscheiden	*)
			'H' :	Attr := Attr OR Hidden;					(* Versteckte Datei        *)
			'S' : Attr := Attr OR SysFile;				(* Systemdatei             *)
			'R' : Attr := Attr OR ReadOnly; 				(* Nur lesbare Datei       *)
			'A' : Attr := Attr OR Archive;  				(* Archivierte Datei			*)
		END;
	END
	ELSE															(* Dateiattribut lîschen  	*)
	BEGIN
		CASE Param[2] OF 			 							(* Attribute unterscheiden	*)
			'H' :	Attr := Attr AND NOT Hidden;			(* Versteckte Datei        *)
			'S' : Attr := Attr AND NOT SysFile;			(* Systemdatei             *)
			'R' : Attr := Attr AND NOT ReadOnly; 		(* Nur lesbare Datei       *)
			'A' : Attr := Attr AND NOT Archive;  		(* Archivierte Datei			*)
		END;
	END;

	SetFAttr(Target, Attr);									(* Dateiattribute setzen  	*)

	IF DosError = 150 THEN 									(* Schreibschutzfehler		*)
	BEGIN
		WriteLnString('Write Protect Error - ' + pFile^.Dir +
						  pFile^.FileItem.Name, cWhite, cBlue);
		Dec(NrFiles);
	END
	ELSE
	BEGIN
		WriteString('Attribute Changed - ', cWhite, cBlue);
		WriteLnString(pFile^.Dir + pFile^.FileItem.Name, cWhite, cBlue);
	END;
END; (* SetAttrib *)

BEGIN (* DoAttrib *)
	IF ParamCount = 0 THEN									(* Informationen ausgeben	*)
	BEGIN
		WriteLnString('Usage : Attrib <path name>[[,<path name>],...] ' +
						  '<+|- <h|s|r|a>>', cWhite, cBlue);
	END
	ELSE IF ParamCount = 1 THEN  	  						(* Zu wenig Parameter		*)
		WriteLnString('Missing Parameter', cWhite, cBlue)
	ELSE IF ParamCount > 2 THEN							(* Zu viele Parameter		*)
		WriteLnString('Too Much Parameters - ' + ParamStr(3), cWhite, cBlue)
	ELSE	                                          (* Attribut Ñndern			*)
	BEGIN
		Path := ParamStr(1);									(* Pfad merken					*)
		Param := ParamStr(2);								(* Zweiter Parameter			*)

		IF Length(Param) < 2 THEN Param := Param + ' ';

		FileTyp := GetFileType(Path);						(* Typ der Datei(en) holen	*)

		IF FileTyp = DirFile THEN							(* Komplettes Verzeichnis	*)
			Path := Path + '\*.*';

		IF FileTyp = NoFile THEN
			WriteLnString('File Not Found - ' + Path, cWhite, cBlue)
		ELSE IF (Length(Param) > 2) OR
			((Param[1] <> '+') AND (Param[1] <> '-'))	OR
			NOT (Param[2] IN ['H', 'S', 'R', 'A']) THEN
			WriteLnString('Illegal Parameter - ' + Param, cWhite, cBlue)
		ELSE
		BEGIN
			CreateRing(Files);  	 		  					(* Fifo-Liste anlegen		*)

			IF FileTyp IN [OneFile, SystemFile, HiddenFile, RdOnlyFile] THEN
			BEGIN									 			 	(* Einzelne Datei Ñndern	*)
				FilesOk := GetFiles(Path, Files, FALSE, NrOfFiles);
				Pop(Files, POINTER(pFile));  				(* Eintrag aus Liste			*)

				WITH pFile^ DO									(* Dateiname zurechtmachen	*)
				BEGIN
					IF Dir[Length(Dir)] <> '\' THEN Dir := Dir + '\';
					Assign(Target, Dir + FileItem.Name);
				END;

				SetAttrib(NrOfFiles);						(* Dateiattribut Ñndern		*)
				Dispose(pFile);  								(* Eintrag entfernen			*)
			END
			ELSE	 												(* Mehrere Dateien Ñndern	*)
			BEGIN
				FilesOk := GetFiles(Path, Files, FALSE, NrOfFiles);
				NrFiles := NrOfFiles;

				IF Pos(',', Path) = 0 THEN					(* Keine Liste von Namen	*)
					Path := FExpand(Path);					(* Pfad auf volle LÑnge		*)

				FOR i := 1 TO NrFiles DO					(* Verzeichnisse weg			*)
				BEGIN
					Pop(Files, POINTER(pFile));			(* Datei aus Liste holen	*)

					IF pFile^.FileItem.Attr AND Directory = Directory THEN
					BEGIN
						Dec(NrOfFiles);						(* Eine Datei weniger		*)
						Dispose(pFile);						(* Speicher freigeben		*)
					END
					ELSE Push(Files, pFile);				(* Datei in Liste behalten	*)
				END;

				NrFiles := NrOfFiles;						(* Anzahl Dateien merken	*)

				IF NOT FilesOk THEN							(* Zu viele DateieintrÑge	*)
					WriteLnString('To Many Files - ' + Path, cWhite, cBlue)
				ELSE IF NrOfFiles = 0 THEN					(* Keine Dateien vorhanden	*)
					WriteLnString('Nothing To Change - ' + Path, cWhite,	cBlue);

				FOR i := 1 TO NrOfFiles DO	 				(* Alle Dateien durchgehen	*)
				BEGIN
					IF CheckEsc('Attrib') THEN				(* Ausgabe abgebrochen		*)
					BEGIN
						WHILE NOT RingIsEmpty(Files) DO	(* Dateiliste leeren			*)
						BEGIN
							Pop(Files, POINTER(pFile));  	(* Datei aus Liste holen	*)
							Dispose(pFile);					(* Speicher freigeben		*)
						END;

						DeleteRing(Files); 					(* Fifo-Liste lîschen		*)
						Exit;										(* Prozedur vorzeitig Ende	*)
					END;

					Pop(Files, POINTER(pFile)); 			(* Eintrag aus Liste			*)

					WITH pFile^ DO	  							(* Dateiname zurechtmachen	*)
					BEGIN
						IF Dir[Length(Dir)] <> '\' THEN Dir := Dir + '\';
						Assign(Target, Dir + FileItem.Name);
					END;

					SetAttrib(NrFiles); 				  		(* Dateiattribut Ñndern		*)
					Dispose(pFile);  							(* Eintrag entfernen			*)
				END;
			END;

			IF FilesOk AND (NrFiles > 0) THEN			(* Es wurde auch verÑndert	*)
			BEGIN
				Str(NrFiles : 10, AttrFiles);
				WriteLnString(AttrFiles + ' File(s) Changed', cWhite, cBlue);
			END;

			DeleteRing(Files);
		END;
	END;

	WriteLnString('', cWhite, cBlue);
END; (* DoAttrib *)

(* Diese Prozedur Ñndert den Namen einer Datei *)
PROCEDURE DoRename;
VAR Target   : FILE;											(* FÅr Zieldatei 				*)
	 IOStatus : BYTE;											(* Status I/O Operation		*)
BEGIN
	IF ParamCount = 0 THEN									(* Informationen ausgeben	*)
		WriteLnString('Usage : Rename <old path> <new path>', cWhite, cBlue)
	ELSE IF ParamCount = 1 THEN  							(* Zu wenig Parameter		*)
		WriteLnString('Missing Parameter', cWhite, cBlue)
	ELSE IF ParamCount > 2 THEN	  						(* Zu viele Parameter		*)
		WriteLnString('Too Much Parameters - ' + ParamStr(3), cWhite, cBlue)
	ELSE                       							(* Dateiname Ñndern		 	*)
	BEGIN
		Assign(Target, ParamStr(1));						(* UrsprÅnglicher Name		*)
		Rename(Target, ParamStr(2));						(* Neuen Namen zuweisen		*)
		IOStatus := IOResult;								(* IOResult nur einmal		*)

		IF IOStatus = 150 THEN								(* Schreibschutzfehler		*)
			WriteLnString('Write Protect Error', cWhite, cBlue)
		ELSE IF IOStatus <> 0 THEN	 	  					(* Fehler aufgetreten		*)
			WriteLnString('Cannot Rename File - ' + ParamStr(1), cWhite, cBlue);
	END;

	WriteLnString('', cWhite, cBlue);
END; (* DoRename *)

(* Diese Prozedur gibt den Inhalt einer Datei auf dem Bildschirm aus *)
PROCEDURE DoType;
TYPE Status   = (IllegalOpt, TooMuchPars, PauseOn, HexDumpOn);
	  ParamSet = SET OF Status;							(* Statusmenge Parameter	*)

VAR ParamStatus : ParamSet;								(* Status der Parameter		*)
	 i, 		 													(* Dient nur als ZÑhler		*)
	 NameIndex   : INTEGER;			  						(* Index fÅr Dateiname		*)
	 TextString  : PathStr;  					  			(* Aufnahme von Texten		*)
	 Source		 : FILE OF BYTE;							(* Zu betrachtende Datei	*)
	 NrOfLines,   												(* Ausgegebene Zeilen		*)
	 NrOfColumns : WORD;										(* Ausgegebene Spalten		*)
	 ByteValue   : BYTE;										(* Byte aus Datei lesen		*)
	 Dummy		 : CHAR;										(* Dient als Platzhalter	*)

(* Diese Funktion gibt das untere Nibble eines Bytes als Hex-Ziffer zurÅck *)
FUNCTION HexChar(Value : BYTE) : CHAR;
BEGIN
	Value := Value AND $0F;									(* Bits 4 bis 7 ausblenden	*)
	Value := Value + Ord('0');								(* 0..9 -> ASCII '0'..'9'	*)
	IF Value > Ord('9') THEN Inc(Value, 7); 			(* A..F -> ASCII 'A'..'F'	*)

	HexChar := Chr(Value);									(* Buchstabe zurÅckgeben	*)
END; (* HexChar *)

BEGIN (* DoType *)
	IF ParamCount = 0 THEN									(* Informationen ausgeben	*)
		WriteLnString('Usage : Type <file name> [/h] [/p]', cWhite, cBlue)
	ELSE IF ParamCount > 3 THEN	 						(* Zu viele Parameter		*)
		WriteLnString('Too Much Parameters - ' + ParamStr(4), cWhite, cBlue)
	ELSE
	BEGIN
		ParamStatus := [ ];									(* Leerer Parameterstatus	*)
		NameIndex := 0;
		i := 1; 													(* Erster Parameter			*)

		WHILE (i <= ParamCount) AND  						(* Alle Parameter beachten	*)
			([IllegalOpt, TooMuchPars] * ParamStatus = [ ]) DO
		BEGIN
			TextString := ParamStr(i);	 					(* Parameter merken			*)

			IF TextString[1] = '/' THEN  					(* Option gefunden			*)
			BEGIN
				IF TextString = '/P' THEN					(* Ausgabe Seitenweise		*)
					ParamStatus := ParamStatus + [PauseOn]
				ELSE IF TextString = '/H' THEN        	(* Ausgabe in die Breite	*)
					ParamStatus := ParamStatus + [HexDumpOn]
				ELSE ParamStatus := ParamStatus + [IllegalOpt];
			END
			ELSE													(* Verzeichnisname 			*)
			BEGIN
				IF NameIndex > 0 THEN                 	(* Zu viele Parameter		*)
					ParamStatus := ParamStatus + [TooMuchPars]
				ELSE NameIndex := i;
			END;

			Inc(i);												(* NÑchster Parameter		*)
		END;

		IF TooMuchPars IN ParamStatus THEN				(* Zu viele Parameter		*)
			WriteLnString('Too Much Parameters - ' + TextString, cWhite, cBlue)
		ELSE IF IllegalOpt IN ParamStatus THEN			(* UnzulÑssige Option		*)
			WriteLnString('Illegal Option - ' + TextString, cWhite, cBlue)
		ELSE														(* Kein Parameterfehler		*)
		BEGIN
			Assign(Source, ParamStr(NameIndex));		(* Name an Datei zuweisen	*)
			Reset(Source);										(* Datei zum Lesen îffnen	*)

			IF IOResult <> 0 THEN							(* Fehler ist aufgetreten	*)
			BEGIN
				WriteLnString('File Not Found - ' + ParamStr(NameIndex),
								  cWhite, cBlue);
			END
			ELSE													(* Datei ist in Ordnung		*)
			BEGIN
				NrOfLines := 0;								(* Keine Zeile ausgegeben	*)
				NrOfColumns := 0;   							(* Keine Spalte ausgegeben	*)

				IF HexDumpOn IN ParamStatus THEN			(* Datei als Hex Dump		*)
				BEGIN
					WHILE NOT Eof(Source) DO				(* Komplette Datei lesen	*)
					BEGIN
						IF CheckEsc('Type') THEN			(* Ausgabe abgebrochen		*)
							Exit;	  								(* Prozedur vorzeitig Ende	*)

						FOR i := 1 TO 16 DO					(* 16 Hex-Zahlen ausgeben	*)
						BEGIN
							IF NOT Eof(Source) THEN			(* Datei nicht zu Ende		*)
							BEGIN
								Read(Source, ByteValue);	(* Wert von Datei lesen		*)
								SetVirtualXY(i * 3, WhereVirtualY);

								WriteString(HexChar(ByteValue SHR 4) +
												HexChar(ByteValue), cWhite, cBlue);

								SetVirtualXY(60 + i, WhereVirtualY);
								WriteString(Chr(ByteValue), cWhite, cBlue);
							END;
						END;

						Inc(NrOfLines);						(* Neue Zeile ausgegeben	*)
						WriteLnString('', cWhite, cBlue);

						IF (NrOfLines = WinHeight - 3) AND
							(PauseOn IN ParamStatus) THEN (* Ausgabe wird angehalten	*)
						BEGIN
							IF WhereVirtualX > 1 THEN
								WriteLnString('', cWhite, cBlue);

							WriteString('Press Any Key To Continue ...',
											cWhite, cBlue);

							REPEAT UNTIL KeyPressed;		(* Auf Tastendruck warten	*)
							Dummy := ReadKey;					(* Tastendruck einlesen		*)

							WriteLnString('', cWhite, cBlue);
							NrOfLines := 0;					(* Neuer Bildschirm			*)
						END;
					END;
				END
				ELSE												(* Datei als Text ausgeben	*)
				BEGIN
					WHILE NOT Eof(Source) DO				(* Komplette Datei lesen	*)
					BEGIN
						IF CheckEsc('Type') THEN			(* Ausgabe abgebrochen		*)
							Exit;	  								(* Prozedur vorzeitig Ende	*)

						Read(Source, ByteValue);			(* Ein Zeichen einlesen		*)

						IF ByteValue = Tab THEN				(* Tab sind 8 Leerzeichen	*)
						BEGIN
							WriteString('        ', cWhite, cBlue);
							Inc(NrOfColumns, 8);				(* Acht Spalten ausgegeben	*)
						END
						ELSE IF (ByteValue <> LineFeed) AND
							(ByteValue <> CtrlZ) AND
							(ByteValue <> CarriageReturn) THEN
						BEGIN
							WriteString(Chr(ByteValue), cWhite, cBlue);
							Inc(NrOfColumns);	  				(* NÑchste Spalte				*)
						END;

						IF NrOfColumns = 78 THEN			(* Rechten Rand erreicht	*)
						BEGIN
							Inc(NrOfLines);					(* Eine Zeile ausgegeben	*)
							NrOfColumns := 0;					(* Linker Rand					*)
						END
						ELSE IF ByteValue = CarriageReturn THEN
						BEGIN                         	(* Neue Zeile					*)
							Read(Source, ByteValue);  		(* Line Feed Åberlesen		*)
							WriteLnString('', cWhite, cBlue);

							Inc(NrOfLines);					(* Eine Zeile ausgegeben	*)
							NrOfColumns := 0;					(* Linker Rand					*)
						END;

						IF (NrOfLines = WinHeight - 3) AND
							(PauseOn IN ParamStatus) THEN (* Ausgabe wird angehalten	*)
						BEGIN
							IF WhereVirtualX > 1 THEN
								WriteLnString('', cWhite, cBlue);

							WriteString('Press Any Key To Continue ...',
											cWhite, cBlue);

							REPEAT UNTIL KeyPressed;		(* Auf Tastendruck warten	*)
							Dummy := ReadKey;					(* Tastendruck einlesen		*)

							WriteLnString('', cWhite, cBlue);
							NrOfLines := 0;					(* Neuer Bildschirm			*)
						END;
					END;
				END;

				Close(Source);	  								(* Datei schlie·en			*)
			END;
		END;
	END;

	WriteLnString('', cWhite, cBlue);
END; (* DoType *)

(*$I ToolCopy.Pas  Das Dateikopierprogramm ist als Include-Datei vorhanden *)

BEGIN (* DoDosShell *)
	ReInstallKeyInterrupt;									(* Dos Tastaturroutine		*)
	IF MouseAvail THEN MouseOff;							(* Maus ausschalten			*)
	SetKeySpeed(0, 0);										(* Tastaturgeschwindigkeit	*)
	SetKeyStatus(NumLockKey);								(* Num Lock anschalten		*)
	CursorIndex := 1;	 		  								(* Anfang Historytabelle	*)
	HistoryIndex := 1;										(* Anfang Historytabelle	*)

	WITH DosWindow DO  										(* Fensterdaten eintragen	*)
	BEGIN
		LeftEdge := WinLeft;
		TopEdge := WinTop;
		Width := WinWidth;
		Height := WinHeight;
		DetailPen := cWhite;
		BlockPen := cBlue;
		Flags := [Cursor, Double, Simple, Title];
		WinTitle := ' Virtual Dos Shell ';
	END;

	WindowHandle := OpenWindow(DosWindow);	  			(* Dos Fenster îffnen		*)

	SetVirtualXY(1, 2);
	WriteString('Type Exit To Return To Venus ...', cWhite, cBlue);
	SetVirtualXY(1, 4);

	REPEAT														(* Schleife der Eingaben	*)
		ActualDir := FExpand('');							(* Aktuelles Verzeichnis	*)

		IF ActualDir[Length(ActualDir) - 1] <> ':' THEN
			ActualDir[0] := Chr(Length(ActualDir) - 1);

		WriteString(ActualDir + '>', cWhite, cBlue);
		UseText := FALSE;										(* Vorgabetext ist leer		*)

		REPEAT
			EndKeys := [EndReturn, EndCursUp, EndCursDown, EndEscape];

			VideoFill(WinLeft + WhereVirtualX, WinTop + WhereVirtualY,
						 WinWidth - (WinLeft + WhereVirtualX) - 1, 1, ' ',
						 cWhite, cBlue); 	 					(* Zeile wird gelîscht		*)

			VideoRead(WinLeft + WhereVirtualX, WinTop + WhereVirtualY,
						 WinWidth - (WinLeft + WhereVirtualX) - 1, Command,
						 cWhite, cBlue, EndKeys, FALSE, UseText);

			IF EndEscape IN EndKeys THEN					(* ESC lîscht Eingabezeile	*)
			BEGIN
				VideoFill(WinLeft + 1, WinTop + WhereVirtualY, WinWidth - 2, 1,
							 ' ', cWhite, cBlue); 	 		(* Zeile wird gelîscht		*)

				SetVirtualXY(1, WhereVirtualY);			(* Anfang aktuelle Zeile	*)
				WriteString(ActualDir + '>', cWhite, cBlue);

				UseText := FALSE;
			END
			ELSE IF EndCursUp IN EndKeys THEN			(* In History zurÅckgehen 	*)
			BEGIN
				IF CursorIndex > 1 THEN 					(* Keine Tabellenanfang		*)
				BEGIN
					Dec(CursorIndex);							(* Vorheriges Kommando		*)
					Command := History[CursorIndex];		(* Kommando aus Tabelle		*)
					UseText := TRUE;
				END;
			END
			ELSE IF EndCursDown IN EndKeys THEN			(* In History vorgehen		*)
			BEGIN
				IF CursorIndex < HistoryIndex - 1 THEN	(* Keine Tabellenende		*)
				BEGIN
					Inc(CursorIndex);							(* Nachfolgendes Kommando	*)
					Command := History[CursorIndex];		(* Kommando aus Tabelle		*)
					UseText := TRUE;
				END;
			END;
		UNTIL EndReturn IN EndKeys;						(* Ende der Eingabe			*)

		IF HistoryIndex <= HistoryMax THEN				(* Noch Platz in Tabelle	*)
		BEGIN
			IF Length(Command) > 2 THEN					(* Kommando lang genug		*)
			BEGIN
				History[HistoryIndex] := Command;		(* Befehl in Tabelle	rein	*)
				Inc(HistoryIndex);							(* NÑchster Eintrag			*)
			END;
		END
		ELSE IF Length(Command) > 2 THEN	 				(* Historytabelle ist voll	*)
		BEGIN
			FOR i := 1 TO HistoryMax - 1 DO				(* Tabelle verschieben		*)
				History[i] := History[i + 1];

			History[HistoryMax] := Command;				(* Befehl in Tabelle	rein	*)
		END;

		CursorIndex := HistoryIndex; 		 				(* Aktueller Tabellenplatz	*)
		WriteLnString('', cWhite, cBlue);			  	(* Leerzeile nach Eingabe	*)

		IF ParamStr(0) = 'DIR' THEN DoDir				(* Befehle unterscheiden	*)
		ELSE IF ParamStr(0) = 'CD' THEN DoCd
		ELSE IF ParamStr(0) = 'CLS' THEN ClearWindow
		ELSE IF (ParamStr(0) = 'REN') OR (ParamStr(0) = 'RENAME') THEN DoRename
		ELSE IF ParamStr(0) = 'COPY' THEN DoCopy
		ELSE IF (ParamStr(0) = 'RD') OR (ParamStr(0) = 'RMDIR') THEN DoRmDir
		ELSE IF (ParamStr(0) = 'MD') OR (ParamStr(0) = 'MKDIR') THEN DoMkDir
		ELSE IF ParamStr(0) = 'ATTRIB' THEN DoAttrib
		ELSE IF ParamStr(0) = 'TYPE' THEN DoType
		ELSE IF ParamStr(0) = 'DEL' THEN DoDel(ParamStr(1))
		ELSE IF ParamStr(0) = 'ERASE' THEN DoErase(ParamStr(1))
		ELSE IF (ParamStr(0) <> 'EXIT') AND (ParamStr(0) <> '') THEN
		BEGIN 													(* Befehl nicht bekannt		*)
			WriteLnString('Unknown Command', cWhite, cBlue);
			WriteLnString('', cWhite, cBlue);
		END;
	UNTIL ParamStr(0) = 'EXIT';

	DelKeyStatus(NumLockKey);								(* Num Lock ausschalten		*)
	WindowStatus := CloseWindow;							(* Dos Fenster schlei·en	*)

	IF MouseAvail THEN MouseOn;							(* Maus anschalten			*)
	InstallKeyInterrupt;										(* Eigene Tastaturroutine	*)
END; (* DoDosShell *)

(* Diese Prozedur speichert die Konfigurationsdatei von Venus *)
PROCEDURE DoSaveConfig(SourceDrive, TargetDrive : CHAR; XmsUsage, EmsUsage,
							  ExtUsage, RamDiskUsage, HardDiskUsage : BOOLEAN;
							  NrOfErrorTrials : BYTE;
							  VerifyTarget, FormatTarget : BOOLEAN;
							  ToHd, FromHd : STRING);
VAR DoCont 		: BOOLEAN;	  								(* Speichern fortsetzen		*)
	 ConfigPath : PathStr;     							(* Pfad zur Config-Datei	*)
	 ConfigFile : FILE;										(* Dateivariable Config		*)
	 Result		: WORD;										(* Resultat vom Schreiben	*)
BEGIN
	DoMessage('Do You Want To Save Venus Config ?', TRUE, DoCont);

	IF DoCont THEN												(* Speichern fortsetzen		*)
	BEGIN
		ConfigPath := FSearch('VENUS.EXE', GetEnv('PATH'));

		IF Length(ConfigPath) = 0 THEN  					(* Venus nicht gefunden		*)
			DoMessage(' Error - File Venus.Exe Not Found', FALSE, DoCont)
		ELSE                                         (* Venus im Pfad gefunden	*)
		BEGIN
			ConfigPath[0] := Chr(Length(ConfigPath) - 3);
			ConfigPath := ConfigPath + 'CFG';			(* Neue Namenserweiterung	*)

			Assign(ConfigFile, ConfigPath);				(* Name fÅr Dateivariable	*)
			ReWrite(ConfigFile, 1);							(* Config-Datei îffnen		*)

			IF IOResult <> 0 THEN							(* Fehler beim Dateiîffnen	*)
				DoMessage('Error - Cannot Create Config File', FALSE, DoCont)
			ELSE													(* Datei wurde geîffnet		*)
			BEGIN                                     (* Farbwerte schreiben		*)
				BlockWrite(ConfigFile, cBlack, 1, Result);
				BlockWrite(ConfigFile, cBlue, 1, Result);
				BlockWrite(ConfigFile, cCyan, 1, Result);
				BlockWrite(ConfigFile, cRed, 1, Result);
				BlockWrite(ConfigFile, cMagenta, 1, Result);
				BlockWrite(ConfigFile, cLightGrey, 1, Result);
				BlockWrite(ConfigFile, cLightGreen, 1, Result);
				BlockWrite(ConfigFile, cLightCyan, 1, Result);
				BlockWrite(ConfigFile, cLightMagenta, 1, Result);
				BlockWrite(ConfigFile, cLightRed, 1, Result);
				BlockWrite(ConfigFile, cYellow, 1, Result);
				BlockWrite(ConfigFile, cWhite, 1, Result);
				BlockWrite(ConfigFile, SourceDrive, 1, Result);
				BlockWrite(ConfigFile, TargetDrive, 1, Result);
				BlockWrite(ConfigFile, XmsUsage, 1, Result);
				BlockWrite(ConfigFile, EmsUsage, 1, Result);
				BlockWrite(ConfigFile, ExtUsage, 1, Result);
				BlockWrite(ConfigFile, RamDiskUsage, 1, Result);
				BlockWrite(ConfigFile, HardDiskUsage, 1, Result);
				BlockWrite(ConfigFile, NrOfErrorTrials, 1, Result);
				BlockWrite(ConfigFile, VerifyTarget, 1, Result);
				BlockWrite(ConfigFile, FormatTarget, 1, Result);
				BlockWrite(ConfigFile, ToHd, 31, Result);
				BlockWrite(ConfigFile, FromHd, 31, Result);

				Close(ConfigFile);							(* Config-Datei schlie·en	*)
			END;
		END;
	END;
END; (* DoSaveConfig *)

END. (* ToolMenu *)
