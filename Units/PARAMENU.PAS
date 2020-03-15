(*******************************************************************)
(* Programmname	 : PARAMENU.PAS V1.8 									 *)
(* Programmautor	 : Michael Rippl											 *)
(* Compiler 		 : Quick Pascal V1.0 									 *)
(* Inhalt			 : MenÅ Parameter des Kopierprogramms Venus V2.1 *)
(* Bemerkung		 : -															 *)
(* Letzte énderung : 01-Sep-1991 											 *)
(*******************************************************************)

UNIT ParaMenu;

INTERFACE

(* Diese Prozedur stellt die Parameter fÅr die Speicherverwaltung ein *)
PROCEDURE DoMemoryUsage(VAR EmsUsage, XmsUsage, ExtUsage, RamDiskUsage,
								HardDiskUsage : BOOLEAN);

(* Diese Prozedur stellt die Anzahl von Wiederholungen bei Fehlern ein *)
PROCEDURE DoErrorTrials(VAR NrOfErrorTrials : BYTE);

(* Diese Prozedur stellt ein, ob Disketten formatiert, verifiziert werden *)
PROCEDURE DoAdjustDisk(VAR VerifyTarget, FormatTarget : BOOLEAN);

IMPLEMENTATION

USES Intuitiv, KeyMouse, VenColor, HiMem;				(* Units einbinden			*)

(* Diese Prozedur stellt die Parameter fÅr die Speicherverwaltung ein *)
PROCEDURE DoMemoryUsage(VAR EmsUsage, XmsUsage, ExtUsage, RamDiskUsage,
								HardDiskUsage : BOOLEAN);
VAR TxtOk,                   								(* Text des Ok-Gadgets		*)
	 TxtExit,					                        (* Text des Exit-Gadgets	*)
	 TxtXms,														(* Text XMS Memory			*)
	 TxtExt,														(* Text Extended Memory		*)
	 TxtEms,														(* Text Expanded Memory		*)
	 TxtRd, 	 													(* Text fÅr Ramdisk	   	*)
	 TxtHd	  : pIntuiText;  								(* Text fÅr Harddisk			*)
	 GadOk,             									 	(* Ok-Gadget					*)
	 GadExit,                                       (* Exit-Gadget					*)
	 GadXms,														(* Gadget XMS Memory			*)
	 GadExt,														(* Gadget Extended Memory	*)
	 GadEms,														(* Gadget Expanded Memory	*)
	 GadRd,														(* Gadget fÅr Ramdisk		*)
	 GadHd  	  : pGadget;                  		  	(* Gadget fÅr Harddisk		*)
	 Status 	  : BOOLEAN;									(* Status des Requesters	*)
	 MemoryReq : pRequester;								(* Requester fÅr Speicher	*)
BEGIN
	InitIntuiText(TxtExit, 3, 8, cBlack, cMagenta, '', NIL);
	InitIntuiText(TxtOk, 23, 8, cBlack, cMagenta, '', NIL);
	InitIntuiText(TxtExt, 8, 2, cBlack, cMagenta, 'Use Extended Memory', NIL);
	InitIntuiText(TxtEms, 8, 3, cBlack, cMagenta, 'Use Expanded Memory', NIL);
	InitIntuiText(TxtRd, 8, 4, cBlack, cMagenta, 'Use Ramdisk As Memory', NIL);
	InitIntuiText(TxtHd, 8, 5, cBlack, cMagenta, 'Use Harddisk As Memory', NIL);
	InitIntuiText(TxtXms, 8, 6, cBlack, cMagenta, 'Use XMS Memory', NIL);

	InitGadget(GadExit, 3, 8, 8, 3, TxtExit, cWhite, cMagenta, NIL, ExitGadget);

	InitGadget(GadXms, 8, 6, 14, 1, TxtXms, cWhite, cMagenta, GadExit,
				  OnOffGadget);

	InitGadget(GadHd, 8, 5, 22, 1, TxtHd, cWhite, cMagenta, GadXms,
				  OnOffGadget);

	InitGadget(GadRd, 8, 4, 21, 1, TxtRd, cWhite, cMagenta, GadHd,
				  OnOffGadget);

	InitGadget(GadEms, 8, 3, 19, 1, TxtEms, cWhite, cMagenta, GadRd,
				  OnOffGadget);

	InitGadget(GadExt, 8, 2, 19, 1, TxtExt, cWhite, cMagenta, GadEms,
				  OnOffGadget);

	InitGadget(GadOk, 23, 8, 8, 3, TxtOk, cWhite, cMagenta, GadExt, OkGadget);

	GadXms^.On := XmsUsage;
	GadExt^.On := ExtUsage;
	GadEms^.On := EmsUsage;
	GadRd^.On := RamDiskUsage;
	GadHd^.On := HardDiskUsage;

	InitRequester(MemoryReq, 22, 6, 34, 12, cYellow, cMagenta,
					  ' Define Memory Usage ',
					  [rClose, rMove, rShadow, rTitle, rDouble], GadOk, NIL);

	Status := OpenRequester(MemoryReq);   				(* Requester îffnen			*)

	IF GetEndGadget(GadOk) = GadOk THEN	  		 		(* Parameter Åbernehmen		*)
	BEGIN
		XmsUsage := GadXms^.On;
		ExtUsage := GadExt^.On;
		EmsUsage := GadEms^.On;
		RamDiskUsage := GadRd^.On;
		HardDiskUsage := GadHd^.On;

		IF XmsUsage THEN InitXms; 	 						(* Verwende XMS Speicher	*)
	END;

	IF Status THEN
		Status := CloseRequester(MemoryReq);			(* Requester schlie·en		*)
END; (* DoMemoryUsage *)

(* Diese Prozedur stellt die Anzahl von Wiederholungen bei Fehlern ein *)
PROCEDURE DoErrorTrials(VAR NrOfErrorTrials : BYTE);
VAR TxtOk,                   								(* Text des Ok-Gadgets		*)
	 TxtExit,					                        (* Text des Exit-Gadgets	*)
	 TxtTrial : pIntuiText;									(* Text fÅr Fehlerversuche	*)
	 GadOk,             									 	(* Ok-Gadget					*)
	 GadExit,                                       (* Exit-Gadget					*)
	 GadTrial : pGadget;                            (* Gadget fÅr Versuche		*)
	 Status 	 : BOOLEAN;										(* Status des Requesters	*)
	 TrialReq : pRequester;									(* Requester fÅr Versuche	*)
	 Dummy    : INTEGER;										(* Nur Platzhalter			*)
BEGIN
	InitIntuiText(TxtExit, 3, 4, cBlack, cMagenta, '', NIL);
	InitIntuiText(TxtOk, 24, 4, cBlack, cMagenta, '', NIL);

	InitIntuiText(TxtTrial, 4, 2, cBlack, cMagenta, 'Number Of Error Trials',
					  NIL);

	InitGadget(GadExit, 3, 4, 8, 3, TxtExit, cWhite, cMagenta, NIL, ExitGadget);

	InitGadget(GadTrial, 4, 2, 22, 1, TxtTrial, cWhite, cMagenta, GadExit,
				  TextGadget);

	WITH GadTrial^ DO											(* Textpufferdaten 			*)
	BEGIN
		Str(NrOfErrorTrials, Buffer);
		Size := 2;
		Mask := ['0'..'9'];
	END;

	InitGadget(GadOk, 24, 4, 8, 3, TxtOk, cWhite, cMagenta, GadTrial, OkGadget);

	InitRequester(TrialReq, 20, 7, 35, 8, cYellow, cMagenta,
					  ' Set Error Trials ',
					  [rClose, rMove, rShadow, rTitle, rDouble], GadOk, NIL);

	Status := OpenRequester(TrialReq); 					(* Requester îffnen			*)

	IF GetEndGadget(GadOk) = GadOk THEN	  		 		(* Fehlerversuche zuweisen	*)
	BEGIN
		Val(GadTrial^.Buffer, NrOfErrorTrials, Dummy);
		IF NrOfErrorTrials < 5 THEN NrOfErrorTrials := 5;
	END;

	IF Status THEN
		Status := CloseRequester(TrialReq);				(* Requester schlie·en		*)
END; (* DoErrorTrials *)

(* Diese Prozedur stellt ein, ob Disketten formatiert, verifiziert werden *)
PROCEDURE DoAdjustDisk(VAR VerifyTarget, FormatTarget : BOOLEAN);
VAR TxtOk,                   								(* Text des Ok-Gadgets		*)
	 TxtExit,					                        (* Text des Exit-Gadgets	*)
	 TxtVer,														(* Text Verify Diskette		*)
	 TxtFor	  : pIntuiText; 								(* Text Format Diskette		*)
	 GadOk,             									 	(* Ok-Gadget					*)
	 GadExit,                                       (* Exit-Gadget					*)
	 GadVer,														(* Gadget Verify Diskette	*)
	 GadFor	  : pGadget; 									(* Gadget Format Diskette	*)
	 Status 	  : BOOLEAN;									(* Status des Requesters	*)
	 AdjustReq : pRequester;								(* Requester fÅr Diskette	*)
BEGIN
	InitIntuiText(TxtExit, 3, 5, cBlack, cMagenta, '', NIL);
	InitIntuiText(TxtOk, 21, 5, cBlack, cMagenta, '', NIL);
	InitIntuiText(TxtVer, 9, 2, cBlack, cMagenta, 'Verify Target Disk', NIL);
	InitIntuiText(TxtFor, 9, 3, cBlack, cMagenta, 'Format Target Disk', NIL);

	InitGadget(GadExit, 3, 5, 8, 3, TxtExit, cWhite, cMagenta, NIL, ExitGadget);

	InitGadget(GadFor, 9, 3, 18, 1, TxtFor, cWhite, cMagenta, GadExit,
				  OnOffGadget);

	InitGadget(GadVer, 9, 2, 18, 1, TxtVer, cWhite, cMagenta, GadFor,
				  OnOffGadget);

	InitGadget(GadOk, 21, 5, 8, 3, TxtOk, cWhite, cMagenta, GadVer, OkGadget);

	GadVer^.On := VerifyTarget;
	GadFor^.On := FormatTarget;

	InitRequester(AdjustReq, 22, 6, 32, 9, cYellow, cMagenta,
					  ' Adjust Target Disk ',
					  [rClose, rMove, rShadow, rTitle, rDouble], GadOk, NIL);

	Status := OpenRequester(AdjustReq);   				(* Requester îffnen			*)

	IF GetEndGadget(GadOk) = GadOk THEN	  		 		(* Parameter Åbernehmen		*)
	BEGIN
		VerifyTarget := GadVer^.On;
		FormatTarget := GadFor^.On;
	END;

	IF Status THEN
		Status := CloseRequester(AdjustReq);			(* Requester schlie·en		*)
END; (* DoAdjustDisk *)

END. (* ParaMenu *)
