(**************************************************************)
(* Programmname	 : MAINMENU.PAS V1.8 							  *)
(* Programmautor	 : Michael Rippl									  *)
(* Compiler 		 : Quick Pascal V1.0 							  *)
(* Inhalt			 : HauptmenÅ des Kopierprogramms Venus V2.1 *)
(* Bemerkung		 : -													  *)
(* Letzte énderung : 08-Mar-1991 									  *)
(**************************************************************)

UNIT MainMenu;

INTERFACE

TYPE MenuSelections = (SingleDrive, CylinderCopy, DualDrive, MultipleCopy,
							  ImageToHd, RestoreImage, QuitVenus, MemoryUsage,
							  ErrorTrials, AdjustDisk, SystemInfo, MemorySizes,
							  DiskInfo, VenusInfo, DosShell, ChangeColor, SaveConfig);

(* Diese Funktion ist verantwortlich fÅr das HauptmenÅ von Venus *)
FUNCTION DoMainMenu : MenuSelections;

IMPLEMENTATION

USES KeyMouse, Primitiv, Windows, VenColor;			(* Units einbinden			*)

(* Diese Funktion ist verantwortlich fÅr das HauptmenÅ von Venus *)
FUNCTION DoMainMenu : MenuSelections;
CONST NoMenu			  = 0; 								(* Kein MenÅ ist aktiv		*)
		NoMenuPoint 	  = 1; 								(* Kein MenÅpunkt aktiv 	*)
		MenuDiskCopy	  = 8; 								(* MenÅ DiskCopy				*)
		MenuParameter	  = 9; 								(* MenÅ Parameter 			*)
		MenuInformation  = 10;								(* MenÅ Information			*)
		MenuTools		  = 11;								(* MenÅ Tools					*)
		CopySingleDrive  = 20;								(* MenÅpunkte DiskCopy		*)
		CopyMultiple	  = 21;
		CopyDualDrive	  = 22;
		CopyExitVenus	  = 23;
		CopyImageToHd    = 24;
		CopyRestoreImage = 25;
		CopyCylinder     = 26;
		ParamMemory 	  = 30;								(* MenÅpunkte Parameter 	*)
		ParamErrTrials   = 31;
		ParamTarget 	  = 32;
		InfoSystem		  = 40;								(* MenÅpunkte Information	*)
		InfoMemorySizes  = 41;
		InfoVenusCopy	  = 42;
		InfoDiskette	  = 43;
		ToolsDosShell    = 50;								(* MenÅpunkte Tools			*)
		ToolsChangeColor = 51;
		ToolsSaveConfig  = 52;

VAR QuitMenu,													(* MenÅauswahl ist zu Ende *)
	 AltKeyDown,												(* Alt Taste ist gedrÅckt	*)
	 ClickLeftDown   : BOOLEAN;							(* Linke Maustaste unten	*)
	 KindOfChoice	  : MenuSelections;					(* Punkt der MenÅauswahl	*)
	 NewEvent		  : Event;								(* Ereignis eingetroffen	*)
	 ActualMenuId, 											(* Aktuelles Auswahlfeld	*)
	 ActualMenuPoint : BYTE;								(* Aktueller MenÅpunkt		*)
	 HotKeyRed		  : Colors; 							(* Rote HotKey Tasten		*)

(* Diese Prozedur zeichnet das MenÅ DiskCopy *)
PROCEDURE DrawDiskCopy;
VAR DiskCopyMenu : Window;
	 WindowHandle : pWindow;
BEGIN
	IF MouseAvail THEN MouseOff;							(* Maus ausschalten			*)
	PutString(16, 0, ' DISKCOPY ', cCyan, cBlack);
	PutChar(17, 0, 'D', HotKeyRed, cBlack);

	WITH DiskCopyMenu DO 									(* Fensterdaten eintragen	*)
	BEGIN
		LeftEdge := 15;
		TopEdge := 1;
		Width := 27;
		Height := 10;
		DetailPen := cBlack;
		BlockPen := cCyan;
		Flags := [Single, Shadow, Simple];
	END;

	WindowHandle := OpenWindow(DiskCopyMenu); 		(* MenÅfenster îffnen		*)

	PutString(17, 2, 'Single Drive Copy    F2', cBlack, cCyan);
	PutString(17, 3, 'Multiple Copy        F3', cBlack, cCyan);
	PutString(17, 4, 'Cylinder Copy        F4', cBlack, cCyan);
	PutString(17, 5, 'Image To Harddisk    F5', cBlack, cCyan);
	PutString(17, 6, 'Restore Disk Image   F6', cBlack, cCyan);
	PutString(17, 7, 'Dual Drive Copy      F7', cBlack, cCyan);
	PutString(17, 9, 'Exit Venus Program  ESC', cBlack, cCyan);

	PutChar(17, 2, 'S', cYellow, cCyan);
	PutChar(17, 3, 'M', cYellow, cCyan);
	PutChar(17, 4, 'C', cYellow, cCyan);
	PutChar(17, 5, 'I', cYellow, cCyan);
	PutChar(17, 6, 'R', cYellow, cCyan);
	PutChar(17, 7, 'D', cYellow, cCyan);
	PutString(15, 8, '√ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¥', cBlack, cCyan);
	PutChar(17, 9, 'E', cYellow, cCyan);

	CreateArea(16, 2, 25, 1, CopySingleDrive);		(* MenÅpunktfelder anlegen *)
	CreateArea(16, 3, 25, 1, CopyMultiple);
	CreateArea(16, 4, 25, 1, CopyCylinder);
	CreateArea(16, 5, 25, 1, CopyImageToHd);
	CreateArea(16, 6, 25, 1, CopyRestoreImage);
	CreateArea(16, 7, 25, 1, CopyDualDrive);
	CreateArea(16, 9, 25, 1, CopyExitVenus);

	ActualMenuId := MenuDiskCopy; 						(* Auswahlfeld DiskCopy 	*)
	IF MouseAvail THEN MouseOn;							(* Maus anschalten			*)
END; (* DrawDiskCopy *)

(* Diese Prozedur zeichnet das MenÅ Parameter *)
PROCEDURE DrawParameter;
VAR ParameterMenu : Window;
	 WindowHandle	: pWindow;
BEGIN
	IF MouseAvail THEN MouseOff;							(* Maus ausschalten			*)
	PutString(28, 0, ' PARAMETER ', cCyan, cBlack);
	PutChar(29, 0, 'P', HotKeyRed, cBlack);

	WITH ParameterMenu DO									(* Fensterdaten eintragen	*)
	BEGIN
		LeftEdge := 27;
		TopEdge := 1;
		Width := 27;
		Height := 5;
		DetailPen := cBlack;
		BlockPen := cCyan;
		Flags := [Single, Shadow, Simple];
	END;

	WindowHandle := OpenWindow(ParameterMenu);		(* MenÅfenster îffnen		*)

	PutString(29, 2, 'Define Memory Usage  F9', cBlack, cCyan);
	PutString(29, 3, 'Set Error Trials', cBlack, cCyan);
	PutString(29, 4, 'Adjust Target Disk   F8', cBlack, cCyan);

	PutChar(29, 2, 'D', cYellow, cCyan);
	PutChar(29, 3, 'S', cYellow, cCyan);
	PutChar(29, 4, 'A', cYellow, cCyan);

	CreateArea(28, 2, 25, 1, ParamMemory); 			(* MenÅpunktfelder anlegen *)
	CreateArea(28, 3, 25, 1, ParamErrTrials);
	CreateArea(28, 4, 25, 1, ParamTarget);

	ActualMenuId := MenuParameter;						(* Auswahlfeld Parameter	*)
	IF MouseAvail THEN MouseOn;							(* Maus anschalten			*)
END; (* DrawParameter *)

(* Diese Prozedur zeichnet das MenÅ Information *)
PROCEDURE DrawInformation;
VAR InformationMenu : Window;
	 WindowHandle	  : pWindow;
BEGIN
	IF MouseAvail THEN MouseOff;							(* Maus ausschalten			*)
	PutString(41, 0, ' INFORMATION ', cCyan, cBlack);
	PutChar(42, 0, 'I', HotKeyRed, cBlack);

	WITH InformationMenu DO 								(* Fensterdaten eintragen	*)
	BEGIN
		LeftEdge := 40;
		TopEdge := 1;
		Width := 27;
		Height := 7;
		DetailPen := cBlack;
		BlockPen := cCyan;
		Flags := [Single, Shadow, Simple];
	END;

	WindowHandle := OpenWindow(InformationMenu); 	(* MenÅfenster îffnen		*)

	PutString(42, 2, 'System Information', cBlack, cCyan);
	PutString(42, 3, 'Memory Sizes        F11', cBlack, cCyan);
	PutString(42, 4, 'Disk Information    F12', cBlack, cCyan);
	PutString(42, 6, 'Venus DiskCopy V2.1', cBlack, cCyan);

	PutChar(42, 2, 'S', cYellow, cCyan);
	PutChar(42, 3, 'M', cYellow, cCyan);
	PutChar(42, 4, 'D', cYellow, cCyan);
	PutString(40, 5, '√ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¥', cBlack, cCyan);
	PutChar(42, 6, 'V', cYellow, cCyan);

	CreateArea(41, 2, 25, 1, InfoSystem);				(* MenÅpunktfelder anlegen *)
	CreateArea(41, 3, 25, 1, InfoMemorySizes);
	CreateArea(41, 4, 25, 1, InfoDiskette);
	CreateArea(41, 6, 25, 1, InfoVenusCopy);

	ActualMenuId := MenuInformation; 					(* Auswahlfeld Information *)
	IF MouseAvail THEN MouseOn;							(* Maus anschalten			*)
END; (* DrawInformation *)

(* Diese Prozedur zeichnet das MenÅ Tools *)
PROCEDURE DrawTools;
VAR ToolMenu     : Window;
	 WindowHandle : pWindow;
BEGIN
	IF MouseAvail THEN MouseOff;							(* Maus ausschalten			*)
	PutString(56, 0, ' TOOLS ', cCyan, cBlack);
	PutChar(57, 0, 'T', HotKeyRed, cBlack);

	WITH ToolMenu DO 											(* Fensterdaten eintragen	*)
	BEGIN
		LeftEdge := 52;
		TopEdge := 1;
		Width := 25;
		Height := 6;
		DetailPen := cBlack;
		BlockPen := cCyan;
		Flags := [Single, Shadow, Simple];
	END;

	WindowHandle := OpenWindow(ToolMenu); 				(* MenÅfenster îffnen		*)

	PutString(54, 2, 'Virtual Dos Shell  F1', cBlack, cCyan);
	PutString(54, 3, 'Change Colors', cBlack, cCyan);
	PutString(54, 5, 'Save Configuration', cBlack, cCyan);

	PutChar(54, 2, 'V', cYellow, cCyan);
	PutChar(54, 3, 'C', cYellow, cCyan);
	PutString(52, 4, '√ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¥', cBlack, cCyan);
	PutChar(54, 5, 'S', cYellow, cCyan);

	CreateArea(53, 2, 23, 1, ToolsDosShell); 			(* MenÅpunktfelder anlegen *)
	CreateArea(53, 3, 23, 1, ToolsChangeColor);
	CreateArea(53, 5, 23, 1, ToolsSaveConfig);

	ActualMenuId := MenuTools; 							(* Auswahlfeld Tools 		*)
	IF MouseAvail THEN MouseOn;							(* Maus anschalten			*)
END; (* DrawTools *)

(* Diese Prozedur schlie·t ein bestimmtes MenÅfenster *)
PROCEDURE CloseMenu;
VAR WindowStatus : BOOLEAN;
BEGIN
	IF MouseAvail THEN MouseOff;							(* Maus ausschalten			*)
	WindowStatus := CloseWindow;							(* MenÅfenster schlie·en	*)

	CASE ActualMenuId OF
		MenuDiskCopy : 										(* Auswahlfeld DiskCopy 	*)
		BEGIN
			PutString(16, 0, ' DISKCOPY ', cBlack, cCyan);

			DeleteArea(CopySingleDrive);					(* MenÅpunktfelder lîschen *)
			DeleteArea(CopyMultiple);
			DeleteArea(CopyCylinder);
			DeleteArea(CopyImageToHd);
			DeleteArea(CopyRestoreImage);
			DeleteArea(CopyDualDrive);
			DeleteArea(CopyExitVenus);
		END;

		MenuParameter :										(* Auswahlfeld Parameter	*)
		BEGIN
			PutString(28, 0, ' PARAMETER ', cBlack, cCyan);

			DeleteArea(ParamMemory);						(* MenÅpunktfelder lîschen *)
			DeleteArea(ParamErrTrials);
			DeleteArea(ParamTarget);
		END;

		MenuInformation : 									(* Auswahlfeld Information *)
		BEGIN
			PutString(41, 0, ' INFORMATION ', cBlack, cCyan);

			DeleteArea(InfoSystem); 						(* MenÅpunktfelder lîschen *)
			DeleteArea(InfoMemorySizes);
			DeleteArea(InfoDiskette);
			DeleteArea(InfoVenusCopy);
		END;

		MenuTools : 											(* Auswahlfeld Tools 		*)
		BEGIN
			PutString(56, 0, ' TOOLS ', cBlack, cCyan);

			DeleteArea(ToolsDosShell);						(* MenÅpunktfelder lîschen *)
			DeleteArea(ToolsChangeColor);
			DeleteArea(ToolsSaveConfig);
		END;
	END;

	ActualMenuId := NoMenu; 								(* Kein MenÅ ist aktiv		*)
	ActualMenuPoint := NoMenuPoint;						(* Kein MenÅpunkt aktiv 	*)
	IF MouseAvail THEN MouseOn;							(* Maus anschalten			*)
END; (* CloseMenu *)

(* Diese Prozedur markiert einen MenÅpunkt als aktiv *)
PROCEDURE ActiveMenuPoint(MenuPointId : BYTE);
VAR ActiveColor,												(* Buchstabe hervorgehoben *)
	 NormalColor : BYTE; 									(* Normale Buchstabenfarbe *)
BEGIN
	IF MouseAvail THEN MouseOff;							(* Maus ausschalten			*)
	ActiveColor := Ord(cBlack) SHL 4 OR Ord(HotKeyRed);
	NormalColor := Ord(cBlack) SHL 4 OR Ord(cCyan);

	CASE MenuPointId OF
		CopySingleDrive :
		BEGIN
			PutAttributes(16, 2, 25, 1, NormalColor);
			PutAttributes(17, 2, 1, 1, ActiveColor);
		END;

		CopyMultiple :
		BEGIN
			PutAttributes(16, 3, 25, 1, NormalColor);
			PutAttributes(17, 3, 1, 1, ActiveColor);
		END;

		CopyCylinder :
		BEGIN
			PutAttributes(16, 4, 25, 1, NormalColor);
			PutAttributes(17, 4, 1, 1, ActiveColor);
		END;

		CopyImageToHd :
		BEGIN
			PutAttributes(16, 5, 25, 1, NormalColor);
			PutAttributes(17, 5, 1, 1, ActiveColor);
		END;

		CopyRestoreImage :
		BEGIN
			PutAttributes(16, 6, 25, 1, NormalColor);
			PutAttributes(17, 6, 1, 1, ActiveColor);
		END;

		CopyDualDrive :
		BEGIN
			PutAttributes(16, 7, 25, 1, NormalColor);
			PutAttributes(17, 7, 1, 1, ActiveColor);
		END;

		CopyExitVenus :
		BEGIN
			PutAttributes(16, 9, 25, 1, NormalColor);
			PutAttributes(17, 9, 1, 1, ActiveColor);
		END;

		ParamMemory :
		BEGIN
			PutAttributes(28, 2, 25, 1, NormalColor);
			PutAttributes(29, 2, 1, 1, ActiveColor);
		END;

		ParamErrTrials :
		BEGIN
			PutAttributes(28, 3, 25, 1, NormalColor);
			PutAttributes(29, 3, 1, 1, ActiveColor);
		END;

		ParamTarget :
		BEGIN
			PutAttributes(28, 4, 25, 1, NormalColor);
			PutAttributes(29, 4, 1, 1, ActiveColor);
		END;

		InfoSystem :
		BEGIN
			PutAttributes(41, 2, 25, 1, NormalColor);
			PutAttributes(42, 2, 1, 1, ActiveColor);
		END;

		InfoMemorySizes :
		BEGIN
			PutAttributes(41, 3, 25, 1, NormalColor);
			PutAttributes(42, 3, 1, 1, ActiveColor);
		END;

		InfoDiskette :
		BEGIN
			PutAttributes(41, 4, 25, 1, NormalColor);
			PutAttributes(42, 4, 1, 1, ActiveColor);
		END;

		InfoVenusCopy :
		BEGIN
			PutAttributes(41, 6, 25, 1, NormalColor);
			PutAttributes(42, 6, 1, 1, ActiveColor);
		END;

		ToolsDosShell :
		BEGIN
			PutAttributes(53, 2, 23, 1, NormalColor);
			PutAttributes(54, 2, 1, 1, ActiveColor);
		END;

		ToolsChangeColor :
		BEGIN
			PutAttributes(53, 3, 23, 1, NormalColor);
			PutAttributes(54, 3, 1, 1, ActiveColor);
		END;

		ToolsSaveConfig :
		BEGIN
			PutAttributes(53, 5, 23, 1, NormalColor);
			PutAttributes(54, 5, 1, 1, ActiveColor);
		END;
	END;

	ActualMenuPoint := MenuPointId;						(* Aktueller MenÅpunkt		*)
	IF MouseAvail THEN MouseOn;							(* Maus anschalten			*)
END; (* ActiveMenuPoint *)

(* Diese Prozedur markiert einen MenÅpunkt als nicht aktiv *)
PROCEDURE ReActiveMenuPoint;
VAR ActiveColor,												(* Buchstabe hervorgehoben *)
	 NormalColor : BYTE; 									(* Normale Buchstabenfarbe *)
BEGIN
	IF MouseAvail THEN MouseOff;							(* Maus ausschalten			*)
	ActiveColor := Ord(cCyan) SHL 4 OR Ord(cYellow);
	NormalColor := Ord(cCyan) SHL 4 OR Ord(cBlack);

	CASE ActualMenuPoint OF
		CopySingleDrive :
		BEGIN
			PutAttributes(16, 2, 25, 1, NormalColor);
			PutAttributes(17, 2, 1, 1, ActiveColor);
		END;

		CopyMultiple :
		BEGIN
			PutAttributes(16, 3, 25, 1, NormalColor);
			PutAttributes(17, 3, 1, 1, ActiveColor);
		END;

		CopyCylinder :
		BEGIN
			PutAttributes(16, 4, 25, 1, NormalColor);
			PutAttributes(17, 4, 1, 1, ActiveColor);
		END;

		CopyImageToHd :
		BEGIN
			PutAttributes(16, 5, 25, 1, NormalColor);
			PutAttributes(17, 5, 1, 1, ActiveColor);
		END;

		CopyRestoreImage :
		BEGIN
			PutAttributes(16, 6, 25, 1, NormalColor);
			PutAttributes(17, 6, 1, 1, ActiveColor);
		END;

		CopyDualDrive :
		BEGIN
			PutAttributes(16, 7, 25, 1, NormalColor);
			PutAttributes(17, 7, 1, 1, ActiveColor);
		END;

		CopyExitVenus :
		BEGIN
			PutAttributes(16, 9, 25, 1, NormalColor);
			PutAttributes(17, 9, 1, 1, ActiveColor);
		END;

		ParamMemory :
		BEGIN
			PutAttributes(28, 2, 25, 1, NormalColor);
			PutAttributes(29, 2, 1, 1, ActiveColor);
		END;

		ParamErrTrials :
		BEGIN
			PutAttributes(28, 3, 25, 1, NormalColor);
			PutAttributes(29, 3, 1, 1, ActiveColor);
		END;

		ParamTarget :
		BEGIN
			PutAttributes(28, 4, 25, 1, NormalColor);
			PutAttributes(29, 4, 1, 1, ActiveColor);
		END;

		InfoSystem :
		BEGIN
			PutAttributes(41, 2, 25, 1, NormalColor);
			PutAttributes(42, 2, 1, 1, ActiveColor);
		END;

		InfoMemorySizes :
		BEGIN
			PutAttributes(41, 3, 25, 1, NormalColor);
			PutAttributes(42, 3, 1, 1, ActiveColor);
		END;

		InfoDiskette :
		BEGIN
			PutAttributes(41, 4, 25, 1, NormalColor);
			PutAttributes(42, 4, 1, 1, ActiveColor);
		END;

		InfoVenusCopy :
		BEGIN
			PutAttributes(41, 6, 25, 1, NormalColor);
			PutAttributes(42, 6, 1, 1, ActiveColor);
		END;

		ToolsDosShell :
		BEGIN
			PutAttributes(53, 2, 23, 1, NormalColor);
			PutAttributes(54, 2, 1, 1, ActiveColor);
		END;

		ToolsChangeColor :
		BEGIN
			PutAttributes(53, 3, 23, 1, NormalColor);
			PutAttributes(54, 3, 1, 1, ActiveColor);
		END;

		ToolsSaveConfig :
		BEGIN
			PutAttributes(53, 5, 23, 1, NormalColor);
			PutAttributes(54, 5, 1, 1, ActiveColor);
		END;
	END;

	ActualMenuPoint := NoMenuPoint;						(* Kein MenÅpunkt aktiv 	*)
	IF MouseAvail THEN MouseOn;							(* Maus anschalten			*)
END; (* ReActiveMenuPoint *)

(* Diese Prozedur wird aufgerufen, falls die linke Maustaste gedrÅckt wird *)
PROCEDURE MouseLeftDown(NewEvent : Event);
BEGIN
	IF NOT AltKeyDown THEN									(* Kein Alt gedrÅckt 		*)
	BEGIN
		ClickLeftDown := TRUE;								(* Linke Taste gedrÅckt 	*)

		CASE NewEvent.AreaId OF
			MenuDiskCopy : 									(* Auswahlfeld DiskCopy 	*)
			BEGIN
				IF (ActualMenuId <> NoMenu) AND
					(ActualMenuId <> MenuDiskCopy) THEN
					CloseMenu;									(* Aktuelles Menufenster	*)

				IF ActualMenuId = NoMenu THEN
					DrawDiskCopy;								(* Neues Menu zeichnen		*)
			END;

			MenuParameter :									(* Auswahlfeld Parameter	*)
			BEGIN
				IF (ActualMenuId <> NoMenu) AND
					(ActualMenuId <> MenuParameter) THEN
					CloseMenu;									(* Aktuelles MenÅfenster	*)

				IF ActualMenuId = NoMenu THEN
					DrawParameter; 							(* Neues Menu zeichnen		*)
			END;

			MenuInformation : 								(* Auswahlfeld Information *)
			BEGIN
				IF (ActualMenuId <> NoMenu) AND
					(ActualMenuId <> MenuInformation) THEN
					CloseMenu;									(* Aktuelles MenÅfenster	*)

				IF ActualMenuId = NoMenu THEN
					DrawInformation;							(* Neues Menu zeichnen		*)
			END;

			MenuTools : 										(* Auswahlfeld Tools 		*)
			BEGIN
				IF (ActualMenuId <> NoMenu) AND
					(ActualMenuId <> MenuTools) THEN
					CloseMenu;									(* Aktuelles MenÅfenster	*)

				IF ActualMenuId = NoMenu THEN
					DrawTools;									(* Neues Menu zeichnen		*)
			END;

			CopySingleDrive, CopyMultiple, CopyCylinder, CopyImageToHd,
			CopyRestoreImage,	CopyDualDrive, CopyExitVenus, ParamMemory,
			ParamErrTrials, ParamTarget, InfoSystem, InfoMemorySizes,
			InfoDiskette, InfoVenusCopy, ToolsDosShell, ToolsChangeColor,
			ToolsSaveConfig :
			BEGIN
				ReActiveMenuPoint;							(* MenÅpunkt reaktivieren	*)
				ActiveMenuPoint(NewEvent.AreaId);		(* Neuer aktiver MenÅpunkt *)
			END;

			ELSE													(* Kein sinnvoller Click	*)
				ClickLeftDown := FALSE;

				IF ActualMenuId <> NoMenu THEN
					CloseMenu;									(* Aktuelles MenÅfenster	*)
		END;
	END;
END; (* MouseLeftDown *)

(* Diese Prozedur wird aufgerufen, falls die linke Maustaste losgelassen wird *)
PROCEDURE MouseLeftUp(NewEvent : Event);
BEGIN
	IF ClickLeftDown THEN									(* Sinnvoller Maus-Click	*)
	BEGIN
		ClickLeftDown := FALSE; 							(* Linke Maustaste oben 	*)

		CASE NewEvent.AreaId OF
			MenuDiskCopy : 									(* Auswahlfeld DiskCopy 	*)
			BEGIN
				IF ActualMenuPoint = NoMenuPoint THEN	(* Kein MenÅpunkt aktiv 	*)
					ActiveMenuPoint(CopySingleDrive);	(* MenÅpunkt aktivieren 	*)
			END;

			MenuParameter :									(* Auswahlfeld Parameter	*)
			BEGIN
				IF ActualMenuPoint = NoMenuPoint THEN	(* Kein MenÅpunkt aktiv 	*)
					ActiveMenuPoint(ParamMemory); 		(* MenÅpunkt aktivieren 	*)
			END;

			MenuInformation : 								(* Auswahlfeld Information *)
			BEGIN
				IF ActualMenuPoint = NoMenuPoint THEN	(* Kein MenÅpunkt aktiv 	*)
					ActiveMenuPoint(InfoSystem);			(* MenÅpunkt aktivieren 	*)
			END;

			MenuTools : 										(* Auswahlfeld Tools 		*)
			BEGIN
				IF ActualMenuPoint = NoMenuPoint THEN	(* Kein MenÅpunkt aktiv 	*)
					ActiveMenuPoint(ToolsDosShell);		(* MenÅpunkt aktivieren 	*)
			END;

			CopySingleDrive :
			BEGIN
				CloseMenu;										(* Aktuelles MenÅfenster	*)
				KindOfChoice := SingleDrive;
				QuitMenu := TRUE;
			END;

			CopyMultiple :
			BEGIN
				CloseMenu;										(* Aktuelles MenÅfenster	*)
				KindOfChoice := MultipleCopy;
				QuitMenu := TRUE;
			END;

			CopyCylinder :
			BEGIN
				CloseMenu;										(* Aktuelles MenÅfenster	*)
				KindOfChoice := CylinderCopy;
				QuitMenu := TRUE;
			END;

			CopyImageToHd :
			BEGIN
				CloseMenu;										(* Aktuelles MenÅfenster	*)
				KindOfChoice := ImageToHd;
				QuitMenu := TRUE;
			END;

			CopyRestoreImage :
			BEGIN
				CloseMenu;										(* Aktuelles MenÅfenster	*)
				KindOfChoice := RestoreImage;
				QuitMenu := TRUE;
			END;

			CopyDualDrive :
			BEGIN
				CloseMenu;										(* Aktuelles MenÅfenster	*)
				KindOfChoice := DualDrive;
				QuitMenu := TRUE;
			END;

			CopyExitVenus :
			BEGIN
				CloseMenu;										(* Aktuelles MenÅfenster	*)
				KindOfChoice := QuitVenus;
				QuitMenu := TRUE;
			END;

			ParamMemory :
			BEGIN
				CloseMenu;										(* Aktuelles MenÅfenster	*)
				KindOfChoice := MemoryUsage;
				QuitMenu := TRUE;
			END;

			ParamErrTrials :
			BEGIN
				CloseMenu;										(* Aktuelles MenÅfenster	*)
				KindOfChoice := ErrorTrials;
				QuitMenu := TRUE;
			END;

			ParamTarget :
			BEGIN
				CloseMenu;										(* Aktuelles MenÅfenster	*)
				KindOfChoice := AdjustDisk;
				QuitMenu := TRUE;
			END;

			InfoSystem :
			BEGIN
				CloseMenu;										(* Aktuelles MenÅfenster	*)
				KindOfChoice := SystemInfo;
				QuitMenu := TRUE;
			END;

			InfoMemorySizes :
			BEGIN
				CloseMenu;										(* Aktuelles MenÅfenster	*)
				KindOfChoice := MemorySizes;
				QuitMenu := TRUE;
			END;

			InfoDiskette :
			BEGIN
				CloseMenu;										(* Aktuelles MenÅfenster	*)
				KindOfChoice := DiskInfo;
				QuitMenu := TRUE;
			END;

			InfoVenusCopy :
			BEGIN
				CloseMenu;										(* Aktuelles MenÅfenster	*)
				KindOfChoice := VenusInfo;
				QuitMenu := TRUE;
			END;

			ToolsDosShell :
			BEGIN
				CloseMenu;										(* Aktuelles MenÅfenster	*)
				KindOfChoice := DosShell;
				QuitMenu := TRUE;
			END;

			ToolsChangeColor :
			BEGIN
				CloseMenu;										(* Aktuelles MenÅfenster	*)
				KindOfChoice := ChangeColor;
				QuitMenu := TRUE;
			END;

			ToolsSaveConfig :
			BEGIN
				CloseMenu;										(* Aktuelles MenÅfenster	*)
				KindOfChoice := SaveConfig;
				QuitMenu := TRUE;
			END;

			ELSE													(* Kein sinnvoller Click	*)
				IF ActualMenuId <> NoMenu THEN
					CloseMenu;									(* Aktuelles MenÅfenster	*)
		END;
	END;
END; (* MouseLeftUp *)

(* Diese Prozedur wird aufgerufen, falls die Maus bewegt wird *)
PROCEDURE MouseMove(NewEvent : Event);
BEGIN
	IF ClickLeftDown THEN									(* Linke Taste gedrÅckt 	*)
	BEGIN
		CASE NewEvent.AreaId OF
			MenuDiskCopy :
			BEGIN
				IF ActualMenuId <> MenuDiskCopy THEN	(* Neuer MenÅpunkt ist da	*)
				BEGIN
					CloseMenu;									(* Altes MenÅfenster zu 	*)
					DrawDiskCopy;								(* Neues MenÅfenster offen *)
				END;
			END;

			MenuParameter :
			BEGIN
				IF ActualMenuId <> MenuParameter THEN	(* Neuer MenÅpunkt ist da	*)
				BEGIN
					CloseMenu;									(* Altes MenÅfenster zu 	*)
					DrawParameter; 							(* Neues MenÅfenster offen *)
				END;
			END;

			MenuInformation :
			BEGIN
				IF ActualMenuId <> MenuInformation THEN(* Neuer MenÅpunkt ist da	*)
				BEGIN
					CloseMenu;									(* Altes MenÅfenster zu 	*)
					DrawInformation;							(* Neues MenÅfenster offen *)
				END;
			END;

			MenuTools :
			BEGIN
				IF ActualMenuId <> MenuTools THEN		(* Neuer MenÅpunkt ist da	*)
				BEGIN
					CloseMenu;									(* Altes MenÅfenster zu 	*)
					DrawTools;									(* Neues MenÅfenster offen *)
				END;
			END;

			CopySingleDrive, CopyMultiple, CopyCylinder, CopyImageToHd,
			CopyRestoreImage,	CopyDualDrive, CopyExitVenus, ParamMemory,
			ParamErrTrials, ParamTarget, InfoSystem, InfoMemorySizes,
			InfoDiskette, InfoVenusCopy, ToolsDosShell, ToolsChangeColor,
			ToolsSaveConfig :
			BEGIN
				IF ActualMenuPoint <> NoMenuPoint THEN
					ReActiveMenuPoint;						(* Aktueller MenÅpunkt		*)

				ActiveMenuPoint(NewEvent.AreaId);
			END;

			ELSE													(* Kein sinnvoller Move 	*)
				IF ActualMenuPoint <> NoMenuPoint THEN
					ReActiveMenuPoint;						(* Aktueller MenÅpunkt		*)
		END;
	END;
END; (* MouseMove *)

(* Diese Prozedur wird aufgerufen, wenn die ALT Taste betÑtigt wird *)
PROCEDURE DoAltKey(NewEvent : Event);
BEGIN
	IF MouseAvail THEN MouseOff;							(* Maus ausschalten			*)

	IF NewEvent.ScanCode = 56 THEN						(* Alt niedergedrÅckt		*)
	BEGIN
		IF ActualMenuId = NoMenu THEN 					(* Es ist kein MenÅ aktiv	*)
		BEGIN
			AltKeyDown := TRUE;								(* Alt Taste ist gedrÅckt	*)
			PutChar(17, 0, 'D', HotKeyRed, cCyan);
			PutChar(29, 0, 'P', HotKeyRed, cCyan);
			PutChar(42, 0, 'I', HotKeyRed, cCyan);
			PutChar(57, 0, 'T', HotKeyRed, cCyan);
		END;
	END
	ELSE															(* Alt losgelassen			*)
	BEGIN
		IF AltKeyDown THEN									(* Alt Taste war gedrÅckt	*)
		BEGIN
			AltKeyDown := FALSE; 							(* Alt nicht gedrÅckt		*)

			IF ActualMenuId <> MenuDiskCopy THEN
				PutChar(17, 0, 'D', cBlack, cCyan);

			IF ActualMenuId <> MenuParameter THEN
				PutChar(29, 0, 'P', cBlack, cCyan);

			IF ActualMenuId <> MenuInformation THEN
				PutChar(42, 0, 'I', cBlack, cCyan);

			IF ActualMenuId <> MenuTools THEN
				PutChar(57, 0, 'T', cBlack, cCyan);
		END;
	END;

	IF MouseAvail THEN MouseOn;							(* Maus anschalten			*)
END; (* DoAltKey *)

(* Diese Prozedur wird aufgerufen, wenn ALT + D, P, I oder T gedrÅckt wurde *)
PROCEDURE DoAltDPITKey(NewEvent : Event);
BEGIN
	CASE NewEvent.ScanCode OF								(* Eingabe unterscheiden	*)
		32 :														(* ScanCode der Taste D 	*)
		BEGIN
			DrawDiskCopy;										(* Auswahlfeld DiskCopy 	*)
			ActiveMenuPoint(CopySingleDrive);			(* MenÅpunkt aktivieren 	*)
		END;

		25 :														(* ScanCode der Taste P 	*)
		BEGIN
			DrawParameter; 									(* Auswahlfeld Parameter	*)
			ActiveMenuPoint(ParamMemory); 				(* MenÅpunkt aktivieren 	*)
		END;

		23 :														(* ScanCode der Taste I 	*)
		BEGIN
			DrawInformation;									(* Auswahlfeld Information *)
			ActiveMenuPoint(InfoSystem);					(* MenÅpunkt aktivieren 	*)
		END;

		20 :														(* ScanCode der Taste T 	*)
		BEGIN
			DrawTools;											(* Auswahlfeld Tools 		*)
			ActiveMenuPoint(ToolsDosShell);				(* MenÅpunkt aktivieren 	*)
		END;
	END;
END; (* DoAltDPITKey *)

(* Diese Prozedur wird aufgerufen, wenn per Taste ein MenÅpunkt gewÑhlt wird *)
PROCEDURE DoMenuKey(NewEvent : Event);
BEGIN
	CASE ActualMenuId OF 									(* MenÅ unterscheiden		*)
		MenuDiskCopy : 										(* Auswahlfeld DiskCopy 	*)
		BEGIN
			CASE NewEvent.ScanCode OF						(* Taste unterscheiden		*)
				31 :												(* ScanCode der Taste S 	*)
				BEGIN
					CloseMenu;									(* Aktuelles MenÅfenster	*)
					KindOfChoice := SingleDrive;
					QuitMenu := TRUE;
				END;

				50 :												(* ScanCode der Taste M 	*)
				BEGIN
					CloseMenu;									(* Aktuelles MenÅfenster	*)
					KindOfChoice := MultipleCopy;
					QuitMenu := TRUE;
				END;

				23 :												(* ScanCode der Taste I 	*)
				BEGIN
					CloseMenu;									(* Aktuelles MenÅfenster	*)
					KindOfChoice := ImageToHd;
					QuitMenu := TRUE;
				END;

				46 :												(* ScanCode der Taste C 	*)
				BEGIN
					CloseMenu;									(* Aktuelles MenÅfenster	*)
					KindOfChoice := CylinderCopy;
					QuitMenu := TRUE;
				END;

				19 :												(* ScanCode der Taste R 	*)
				BEGIN
					CloseMenu;									(* Aktuelles MenÅfenster	*)
					KindOfChoice := RestoreImage;
					QuitMenu := TRUE;
				END;

				32 :												(* ScanCode der Taste D 	*)
				BEGIN
					CloseMenu;									(* Aktuelles MenÅfenster	*)
					KindOfChoice := DualDrive;
					QuitMenu := TRUE;
				END;

				18 :												(* ScanCode der Taste E 	*)
				BEGIN
					CloseMenu;									(* Aktuelles MenÅfenster	*)
					KindOfChoice := QuitVenus;
					QuitMenu := TRUE;
				END;

				ELSE ;											(* Eingabe ignorieren		*)
			END;
		END;

		MenuParameter :										(* Auswahlfeld Parameter	*)
		BEGIN
			CASE NewEvent.ScanCode OF						(* Taste unterscheiden		*)
				32 :												(* ScanCode der Taste D 	*)
				BEGIN
					CloseMenu;									(* Aktuelles MenÅfenster	*)
					KindOfChoice := MemoryUsage;
					QuitMenu := TRUE;
				END;

				31 :												(* ScanCode der Taste S 	*)
				BEGIN
					CloseMenu;									(* Aktuelles MenÅfenster	*)
					KindOfChoice := ErrorTrials;
					QuitMenu := TRUE;
				END;

				30 :												(* ScanCode der Taste A 	*)
				BEGIN
					CloseMenu;									(* Aktuelles MenÅfenster	*)
					KindOfChoice := AdjustDisk;
					QuitMenu := TRUE;
				END;

				ELSE ;											(* Eingabe ignorieren		*)
			END;
		END;

		MenuInformation : 									(* Auswahlfeld Information *)
		BEGIN
			CASE NewEvent.ScanCode OF						(* Taste unterscheiden		*)
				31 :												(* ScanCode der Taste S 	*)
				BEGIN
					CloseMenu;									(* Aktuelles MenÅfenster	*)
					KindOfChoice := SystemInfo;
					QuitMenu := TRUE;
				END;

				50 :												(* ScanCode der Taste M 	*)
				BEGIN
					CloseMenu;									(* Aktuelles MenÅfenster	*)
					KindOfChoice := MemorySizes;
					QuitMenu := TRUE;
				END;

				32 :												(* ScanCode der Taste D 	*)
				BEGIN
					CloseMenu;	  								(* Aktuelles MenÅfenster	*)
					KindOfChoice := DiskInfo;
					QuitMenu := TRUE;
				END;

				47 :												(* ScanCode der Taste V 	*)
				BEGIN
					CloseMenu;									(* Aktuelles MenÅfenster	*)
					KindOfChoice := VenusInfo;
					QuitMenu := TRUE;
				END;

				ELSE ;											(* Eingabe ignorieren		*)
			END;
		END;

		MenuTools : 											(* Auswahlfeld Tools 		*)
		BEGIN
			CASE NewEvent.ScanCode OF						(* Taste unterscheiden		*)
				47 :												(* ScanCode der Taste V 	*)
				BEGIN
					CloseMenu;									(* Aktuelles MenÅfenster	*)
					KindOfChoice := DosShell;
					QuitMenu := TRUE;
				END;

				46 :												(* ScanCode der Taste C 	*)
				BEGIN
					CloseMenu;									(* Aktuelles MenÅfenster	*)
					KindOfChoice := ChangeColor;
					QuitMenu := TRUE;
				END;

				31 :												(* ScanCode der Taste S 	*)
				BEGIN
					CloseMenu;	  								(* Aktuelles MenÅfenster	*)
					KindOfChoice := SaveConfig;
					QuitMenu := TRUE;
				END;

				ELSE ;											(* Eingabe ignorieren		*)
			END;
		END;
	END;
END; (* DoMenuKey *)

(* Diese Prozedur wird aufgerufen, wenn Cursor Left oder Right gedrÅckt wird *)
PROCEDURE DoLeftRightKey(NewEvent : Event);
VAR RememberMenuId : BYTE; 								(* Aktives MenÅ merken		*)
BEGIN
	RememberMenuId := ActualMenuId;
	CloseMenu;													(* Aktuelles MenÅfenster	*)

	IF NewEvent.ScanCode = 75 THEN						(* ScanCode Cursor Left 	*)
	BEGIN
		CASE RememberMenuId OF								(* MenÅ unterscheiden		*)
			MenuDiskCopy : 									(* Auswahlfeld DiskCopy 	*)
			BEGIN
				DrawTools;										(* Auswahlfeld Tools			*)
				ActiveMenuPoint(ToolsDosShell);			(* MenÅpunkt aktivieren 	*)
			END;

			MenuParameter :									(* Auswahlfeld Parameter	*)
			BEGIN
				DrawDiskCopy;									(* Auswahlfeld DiskCopy 	*)
				ActiveMenuPoint(CopySingleDrive);		(* MenÅpunkt aktivieren 	*)
			END;

			MenuInformation : 								(* Auswahlfeld Information *)
			BEGIN
				DrawParameter; 								(* Auswahlfeld Parameter	*)
				ActiveMenuPoint(ParamMemory); 			(* MenÅpunkt aktivieren 	*)
			END;

			MenuTools : 										(* Auswahlfeld Tools 		*)
			BEGIN
				DrawInformation; 								(* Auswahlfeld Information	*)
				ActiveMenuPoint(InfoSystem);				(* MenÅpunkt aktivieren 	*)
			END;
		END;
	END
	ELSE															(* ScanCode Cursor Right	*)
	BEGIN
		CASE RememberMenuId OF								(* MenÅ unterscheiden		*)
			MenuDiskCopy : 									(* Auswahlfeld DiskCopy 	*)
			BEGIN
				DrawParameter; 								(* Auswahlfeld Parameter	*)
				ActiveMenuPoint(ParamMemory); 			(* MenÅpunkt aktivieren 	*)
			END;

			MenuParameter :									(* Auswahlfeld Parameter	*)
			BEGIN
				DrawInformation;								(* Auswahlfeld Information *)
				ActiveMenuPoint(InfoSystem);				(* MenÅpunkt aktivieren 	*)
			END;

			MenuInformation : 								(* Auswahlfeld Information *)
			BEGIN
				DrawTools;										(* Auswahlfeld Tools 		*)
				ActiveMenuPoint(ToolsDosShell);			(* MenÅpunkt aktivieren 	*)
			END;

			MenuTools : 										(* Auswahlfeld Tools 		*)
			BEGIN
				DrawDiskCopy; 									(* Auswahlfeld DiskCopy		*)
				ActiveMenuPoint(CopySingleDrive);		(* MenÅpunkt aktivieren 	*)
			END;
		END;
	END;
END; (* DoLeftRightKey *)

(* Diese Prozedur wird aufgerufen, wenn Cursor Up oder Down gedrÅckt wird *)
PROCEDURE DoUpDownKey(NewEvent : Event);
VAR RememberMenuPoint : BYTE; 							(* MenÅpunkt merken			*)
BEGIN
	RememberMenuPoint := ActualMenuPoint;				(* Aktiver MenÅpunkt 		*)
	ReActiveMenuPoint;										(* Alter MenÅpunkt weg		*)

	IF NewEvent.ScanCode = 72 THEN						(* ScanCode Cursor Up		*)
	BEGIN
		CASE RememberMenuPoint OF							(* MenÅpunkt unterscheiden *)
			CopySingleDrive  : ActiveMenuPoint(CopyExitVenus);
			CopyMultiple	  : ActiveMenuPoint(CopySingleDrive);
			CopyCylinder     : ActiveMenuPoint(CopyMultiple);
			CopyImageToHd	  : ActiveMenuPoint(CopyCylinder);
			CopyRestoreImage : ActiveMenuPoint(CopyImageToHd);
			CopyDualDrive	  : ActiveMenuPoint(CopyRestoreImage);
			CopyExitVenus	  : ActiveMenuPoint(CopyDualDrive);
			ParamMemory 	  : ActiveMenuPoint(ParamTarget);
			ParamErrTrials   : ActiveMenuPoint(ParamMemory);
			ParamTarget 	  : ActiveMenuPoint(ParamErrTrials);
			InfoSystem		  : ActiveMenuPoint(InfoVenusCopy);
			InfoMemorySizes  : ActiveMenuPoint(InfoSystem);
			InfoDiskette  	  : ActiveMenuPoint(InfoMemorySizes);
			InfoVenusCopy	  : ActiveMenuPoint(InfoDiskette);
			ToolsDosShell    : ActiveMenuPoint(ToolsSaveConfig);
			ToolsChangeColor : ActiveMenuPoint(ToolsDosShell);
			ToolsSaveConfig  : ActiveMenuPoint(ToolsChangeColor);
		END;
	END
	ELSE															(* ScanCode Cursor Down 	*)
	BEGIN
		CASE RememberMenuPoint OF							(* MenÅpunkt unterscheiden *)
			CopySingleDrive  : ActiveMenuPoint(CopyMultiple);
			CopyMultiple	  : ActiveMenuPoint(CopyCylinder);
			CopyCylinder  	  : ActiveMenuPoint(CopyImageToHd);
			CopyImageToHd	  : ActiveMenuPoint(CopyRestoreImage);
			CopyRestoreImage : ActiveMenuPoint(CopyDualDrive);
			CopyDualDrive	  : ActiveMenuPoint(CopyExitVenus);
			CopyExitVenus	  : ActiveMenuPoint(CopySingleDrive);
			ParamMemory 	  : ActiveMenuPoint(ParamErrTrials);
			ParamErrTrials   : ActiveMenuPoint(ParamTarget);
			ParamTarget 	  : ActiveMenuPoint(ParamMemory);
			InfoSystem		  : ActiveMenuPoint(InfoMemorySizes);
			InfoMemorySizes  : ActiveMenuPoint(InfoDiskette);
			InfoDiskette  	  : ActiveMenuPoint(InfoVenusCopy);
			InfoVenusCopy	  : ActiveMenuPoint(InfoSystem);
			ToolsDosShell    : ActiveMenuPoint(ToolsChangeColor);
			ToolsChangeColor : ActiveMenuPoint(ToolsSaveConfig);
			ToolsSaveConfig  : ActiveMenuPoint(ToolsDosShell);
		END;
	END;
END; (* DoUpDownKey *)

(* Diese Prozedur wird aufgerufen, wenn die RETURN Taste betÑtigt wird *)
PROCEDURE DoReturnKey;
VAR RememberMenuPoint : BYTE; 							(* MenÅpunkt merken			*)
BEGIN
	RememberMenuPoint := ActualMenuPoint;				(* Aktiver MenÅpunkt 		*)
	CloseMenu;													(* Aktuelles MenÅfenster	*)
	QuitMenu := TRUE;

	CASE RememberMenuPoint OF								(* MenÅpunkt unterscheiden *)
		CopySingleDrive  : KindOfChoice := SingleDrive;
		CopyMultiple	  : KindOfChoice := MultipleCopy;
		CopyCylinder  	  : KindOfChoice := CylinderCopy;
		CopyImageToHd 	  : KindOfChoice := ImageToHd;
		CopyRestoreImage : KindOfChoice := RestoreImage;
		CopyDualDrive	  : KindOfChoice := DualDrive;
		CopyExitVenus	  : KindOfChoice := QuitVenus;
		ParamMemory 	  : KindOfChoice := MemoryUsage;
		ParamErrTrials   : KindOfChoice := ErrorTrials;
		ParamTarget 	  : KindOfChoice := AdjustDisk;
		InfoSystem		  : KindOfChoice := SystemInfo;
		InfoMemorySizes  : KindOfChoice := MemorySizes;
		InfoDiskette  	  : KindOfChoice := DiskInfo;
		InfoVenusCopy	  : KindOfChoice := VenusInfo;
		ToolsDosShell    : KindOfChoice := DosShell;
		ToolsChangeColor : KindOfChoice := ChangeColor;
		ToolsSaveConfig  : KindOfChoice := SaveConfig;
	END;
END; (* DoReturnKey *)

BEGIN (* DoMainMenu *)
	QuitMenu := FALSE;										(* Kein MenÅpunkt gewÑhlt	*)
	AltKeyDown := FALSE; 									(* Alt nicht gedrÅckt		*)
	ClickLeftDown := FALSE; 								(* Linke Maustaste oben 	*)
	ActualMenuId := NoMenu; 								(* Kein MenÅ ist aktiv		*)
	ActualMenuPoint := NoMenuPoint;						(* Kein MenÅpunkt aktiv 	*)

	IF ColorGraphic THEN HotKeyRed := cLightRed		(* Farbgrafikkarte			*)
	ELSE HotKeyRed := cYellow; 							(* Monochromgrafikkarte 	*)

	IF MouseAvail THEN MouseOff;							(* Maus ausschalten			*)

	VideoFill(0, 0, 80, 1, ' ', cBlack, cCyan);
	PutString(0, 0, ' SINGLE DRIVE ', cYellow, cRed);

	PutString(17, 0, 'DISKCOPY    PARAMETER    INFORMATION    TOOLS',
				 cBlack, cCyan);

	IF MouseAvail THEN MouseOn;							(* Maus anschalten			*)

	CreateArea(16, 0, 10, 1, MenuDiskCopy);			(* Auswahlfeld DiskCopy 	*)
	CreateArea(28, 0, 11, 1, MenuParameter);			(* Auswahlfeld Parameter	*)
	CreateArea(41, 0, 13, 1, MenuInformation);		(* Auswahlfeld Information *)
	CreateArea(56, 0, 7, 1, MenuTools);					(* Auswahlfeld Tools 		*)

	REPEAT
		GetEvent(NewEvent);									(* Auf ein Ereignis warten *)

		IF NewEvent.Mouse THEN								(* Die Maus wurde benutzt	*)
		BEGIN
			CASE NewEvent.mEvent OF 						(* Ereignis unterscheiden	*)
				EventMouseMove : MouseMove(NewEvent);
				EventLeftDown	: MouseLeftDown(NewEvent);
				EventLeftUp 	: MouseLeftUp(NewEvent);

				ELSE ;											(* Ereignis ignorieren		*)
			END;
		END
		ELSE														(* Taste wurde gedrÅckt 	*)
		BEGIN
			CASE NewEvent.ScanCode OF						(* ScanCode unterscheiden	*)
				56, 184 : DoAltKey(NewEvent); 			(* Alt Taste betÑtigt		*)

				32, 25, 23, 31, 50, 18, 30, 47, 19, 46, 20 :
				BEGIN                                  (* D P I S M E A V R C T 	*)
					IF AltKeyDown AND (ActualMenuId = NoMenu) THEN
						DoAltDPITKey(NewEvent)
					ELSE IF NOT AltKeyDown AND NOT ClickLeftDown AND
						(ActualMenuId <> NoMenu) THEN
						DoMenuKey(NewEvent);
				END;

				1 :												(* ScanCode der Taste ESC	*)
				BEGIN
					IF NOT AltKeyDown AND NOT ClickLeftDown AND
						(ActualMenuId <> NoMenu) THEN CloseMenu
					ELSE IF ActualMenuId = NoMenu THEN	(* MenÅ abbrechen 			*)
					BEGIN
						KindOfChoice := QuitVenus;
						QuitMenu := TRUE;
					END;
				END;

				59 :												(* ScanCode der Taste F1	*)
				BEGIN
					IF NOT AltKeyDown AND NOT ClickLeftDown THEN
					BEGIN
						IF ActualMenuId <> NoMenu THEN
							CloseMenu;

						KindOfChoice := DosShell;
						QuitMenu := TRUE;
					END;
				END;

				60 :												(* ScanCode der Taste F2	*)
				BEGIN
					IF NOT AltKeyDown AND NOT ClickLeftDown THEN
					BEGIN
						IF ActualMenuId <> NoMenu THEN
							CloseMenu;

						KindOfChoice := SingleDrive;
						QuitMenu := TRUE;
					END;
				END;

				61 :												(* ScanCode der Taste F3	*)
				BEGIN
					IF NOT AltKeyDown AND NOT ClickLeftDown THEN
					BEGIN
						IF ActualMenuId <> NoMenu THEN
							CloseMenu;

						KindOfChoice := MultipleCopy;
						QuitMenu := TRUE;
					END;
				END;

				62 :												(* ScanCode der Taste F4	*)
				BEGIN
					IF NOT AltKeyDown AND NOT ClickLeftDown THEN
					BEGIN
						IF ActualMenuId <> NoMenu THEN
							CloseMenu;

						KindOfChoice := CylinderCopy;
						QuitMenu := TRUE;
					END;
				END;

				63 :												(* ScanCode der Taste F5	*)
				BEGIN
					IF NOT AltKeyDown AND NOT ClickLeftDown THEN
					BEGIN
						IF ActualMenuId <> NoMenu THEN
							CloseMenu;

						KindOfChoice := ImageToHd;
						QuitMenu := TRUE;
					END;
				END;

				64 :												(* ScanCode der Taste F6	*)
				BEGIN
					IF NOT AltKeyDown AND NOT ClickLeftDown THEN
					BEGIN
						IF ActualMenuId <> NoMenu THEN
							CloseMenu;

						KindOfChoice := RestoreImage;
						QuitMenu := TRUE;
					END;
				END;

				65 :												(* ScanCode der Taste F7	*)
				BEGIN
					IF NOT AltKeyDown AND NOT ClickLeftDown THEN
					BEGIN
						IF ActualMenuId <> NoMenu THEN
							CloseMenu;

						KindOfChoice := DualDrive;
						QuitMenu := TRUE;
					END;
				END;

				66 :												(* ScanCode der Taste F8	*)
				BEGIN
					IF NOT AltKeyDown AND NOT ClickLeftDown THEN
					BEGIN
						IF ActualMenuId <> NoMenu THEN
							CloseMenu;

						KindOfChoice := AdjustDisk;
						QuitMenu := TRUE;
					END;
				END;

				67 :												(* ScanCode der Taste F9	*)
				BEGIN
					IF NOT AltKeyDown AND NOT ClickLeftDown THEN
					BEGIN
						IF ActualMenuId <> NoMenu THEN
							CloseMenu;

						KindOfChoice := MemoryUsage;
						QuitMenu := TRUE;
					END;
				END;

				68 :												(* ScanCode der Taste F10	*)
				BEGIN
					IF NOT AltKeyDown AND NOT ClickLeftDown AND
						(ActualMenuId = NoMenu) THEN 		(* Kein MenÅ ist aktiv		*)
					BEGIN
						DrawDiskCopy;
						ActiveMenuPoint(CopySingleDrive);
					END;
				END;

				215 :												(* ScanCode der Taste F11	*)
				BEGIN
					IF NOT AltKeyDown AND NOT ClickLeftDown THEN
					BEGIN
						IF ActualMenuId <> NoMenu THEN
							CloseMenu;

						KindOfChoice := MemorySizes;
						QuitMenu := TRUE;
					END;
				END;

				216 :												(* ScanCode der Taste F12	*)
				BEGIN
					IF NOT AltKeyDown AND NOT ClickLeftDown THEN
					BEGIN
						IF ActualMenuId <> NoMenu THEN
							CloseMenu;

						KindOfChoice := DiskInfo;
						QuitMenu := TRUE;
					END;
				END;

				75, 77 : 										(* Curs Left, Curs Right	*)
				BEGIN
					IF NOT AltKeyDown AND NOT ClickLeftDown AND
						(ActualMenuId <> NoMenu) THEN
						DoLeftRightKey(NewEvent);
				END;

				72, 80 : 										(* Curs Up, Curs Down		*)
				BEGIN
					IF NOT AltKeyDown AND NOT ClickLeftDown AND
						(ActualMenuId <> NoMenu) THEN
						DoUpDownKey(NewEvent);
				END;

				28 :												(* ScanCode der Taste RET	*)
				BEGIN
					IF NOT AltKeyDown AND NOT ClickLeftDown AND
						(ActualMenuPoint <> NoMenuPoint) THEN
						DoReturnKey;
				END;

				ELSE ;											(* Eingabe ignorieren		*)
			END;
		END;
	UNTIL QuitMenu;											(* Benutzer hat gewÑhlt 	*)

	DeleteArea(MenuDiskCopy);								(* Gadgets entfernen 		*)
	DeleteArea(MenuParameter);
	DeleteArea(MenuInformation);
	DeleteArea(MenuTools);

	DoMainMenu := KindOfChoice;							(* Art der MenÅauswahl		*)
END; (* DoMainMenu *)

END. (* MainMenu *)
